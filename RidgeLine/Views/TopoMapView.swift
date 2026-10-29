import SwiftUI
import MapKit

enum MapLayer: String, CaseIterable, Identifiable {
    case topo, aerial, aerialTopo, relief, appleSatellite, appleHybrid

    var id: String { rawValue }

    /// The USGS tile source behind this layer, if any. Those layers can be saved for offline use.
    var tileSource: TileSource? {
        switch self {
        case .topo: return .topo
        case .aerial: return .aerial
        case .aerialTopo: return .aerialTopo
        case .relief: return .relief
        case .appleSatellite, .appleHybrid: return nil
        }
    }

    var title: String {
        switch self {
        case .appleSatellite: return "Apple Satellite"
        case .appleHybrid: return "Apple Hybrid"
        default: return tileSource?.title ?? rawValue
        }
    }

    var symbol: String {
        switch self {
        case .appleSatellite: return "globe.americas.fill"
        case .appleHybrid: return "globe.americas"
        default: return tileSource?.symbol ?? "map"
        }
    }

    var worksOffline: Bool { tileSource != nil }
}

/// Imperative handle so SwiftUI buttons can drive the UIKit map (recenter, fit, read visible region).
final class MapProxy {
    fileprivate weak var mapView: MKMapView?

    var visibleRegion: MKCoordinateRegion? { mapView?.region }

    func followUser() {
        mapView?.setUserTrackingMode(.follow, animated: true)
    }

    func focus(on coord: Coord, meters: Double = 4000) {
        mapView?.setUserTrackingMode(.none, animated: false)
        mapView?.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lon),
                                              latitudinalMeters: meters, longitudinalMeters: meters), animated: true)
    }

    func fit(_ coords: [Coord], padding: Double = 1.4) {
        guard let mapView, !coords.isEmpty else { return }
        mapView.setUserTrackingMode(.none, animated: false)
        let lats = coords.map(\.lat), lons = coords.map(\.lon)
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2,
                                            longitude: (lons.min()! + lons.max()!) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((lats.max()! - lats.min()!) * padding, 0.01),
                                    longitudeDelta: max((lons.max()! - lons.min()!) * padding, 0.01))
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
}

private final class PlaceAnnotation: NSObject, MKAnnotation {
    let place: Place
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: place.coord.lat, longitude: place.coord.lon) }
    var title: String? { place.name }
    var subtitle: String? { place.subtitle }
    init(_ place: Place) { self.place = place }
}

private final class RoutePolyline: MKPolyline {
    var routeID = ""
}

struct TopoMapView: UIViewRepresentable {
    let layer: MapLayer
    let places: [Place]
    let routes: [HikeRoute]
    let activeRouteID: String?
    let initialCenter: Coord
    let proxy: MapProxy
    var onSelectPlace: (Place) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true          // live GPS blue dot — works with no cell service
        map.showsCompass = true
        map.showsScale = true
        map.pointOfInterestFilter = .excludingAll
        map.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: initialCenter.lat, longitude: initialCenter.lon),
                                         latitudinalMeters: 12000, longitudinalMeters: 12000), animated: false)
        proxy.mapView = map
        context.coordinator.parent = self
        context.coordinator.sync(map, force: true)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        proxy.mapView = map
        context.coordinator.parent = self
        context.coordinator.sync(map, force: false)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TopoMapView
        private var lastLayer: MapLayer?
        private var lastPlaceIDs: [String] = []
        private var lastRouteSignature = ""

        init(_ parent: TopoMapView) { self.parent = parent }

        func sync(_ map: MKMapView, force: Bool) {
            let layerChanged = force || lastLayer != parent.layer
            let placeIDs = parent.places.map(\.id)
            let routeSig = parent.routes.map { "\($0.id):\($0.path.count)" }.joined(separator: "|") + "@" + (parent.activeRouteID ?? "")

            if layerChanged {
                switch parent.layer {
                case .appleSatellite: map.mapType = .satellite
                case .appleHybrid: map.mapType = .hybrid
                default: map.mapType = .mutedStandard   // shown while USGS tiles load
                }
                lastLayer = parent.layer
            }

            if force || placeIDs != lastPlaceIDs {
                map.removeAnnotations(map.annotations.filter { $0 is PlaceAnnotation })
                map.addAnnotations(parent.places.map(PlaceAnnotation.init))
                lastPlaceIDs = placeIDs
            }

            if layerChanged || routeSig != lastRouteSignature {
                // Rebuild in z-order: the topo tile layer first, then trail lines on top of it.
                map.removeOverlays(map.overlays)
                if let source = parent.layer.tileSource {
                    map.addOverlay(CachedTileOverlay(source: source), level: .aboveLabels)
                }
                // Inactive routes first so the active one draws on top.
                let ordered = parent.routes.sorted { ($0.id == parent.activeRouteID ? 1 : 0) < ($1.id == parent.activeRouteID ? 1 : 0) }
                for r in ordered where r.path.count >= 2 {
                    var coords = r.path.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
                    let line = RoutePolyline(coordinates: &coords, count: coords.count)
                    line.routeID = r.id
                    map.addOverlay(line, level: .aboveLabels)
                }
                lastRouteSignature = routeSig
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tiles = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tiles)
            }
            if let line = overlay as? RoutePolyline {
                let r = MKPolylineRenderer(polyline: line)
                let active = line.routeID == parent.activeRouteID
                r.strokeColor = UIColor(active ? RL.blaze : RL.pine).withAlphaComponent(active ? 1 : 0.6)
                r.lineWidth = active ? 5 : 3
                r.lineCap = .round
                r.lineJoin = .round
                if !active { r.lineDashPattern = [6, 5] }
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let a = annotation as? PlaceAnnotation else { return nil }   // keeps the default blue dot
            let id = "place"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: a, reuseIdentifier: id)
            view.annotation = a
            view.canShowCallout = true
            view.markerTintColor = UIColor(RL.color(for: a.place.kind))
            view.glyphImage = UIImage(systemName: a.place.kind.symbol)
            view.glyphTintColor = .white
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            if let a = view.annotation as? PlaceAnnotation { parent.onSelectPlace(a.place) }
        }
    }
}
