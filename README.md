# RidgeLine Overland

A warm-daylight, national-park-style iOS 18+ SwiftUI app for truck-bed camping and hiking trips.
It ships pre-loaded for a 2-person trip from **Legacy at Fort Clarke (Gainesville, FL)** to
**Blood Mountain & Helen, GA** in a **2013 RAM 1500 Crew Cab**, and supports any number of future trips.

## Tabs

| Tab | What it does |
| --- | --- |
| **Trip Hub** | Route legs with one-tap Apple Maps / Google Maps directions, live sunrise/sunset/golden hour + 16-day forecast (Open-Meteo), and a must-see sights checklist. |
| **Trail Map** | MapKit with four free USGS layers (Topo, Aerial, Aerial + Topo, Shaded Relief) plus Apple Satellite/Hybrid, live GPS blue dot, full-screen mode, trail lines with start points, distance and estimated time, the four free dispersed camps, GPX import, **Find Trails Near Here** (OpenStreetMap), and offline map saving by screen, trail corridor, all trails, or whole trip area. |
| **Fuel** | Sliders for miles, MPG and gas price → gallons, tank fill-ups, total cost, per-person split, and a planned pit-stop timeline. |
| **Checklists** | Pre-loaded gear (3-stage At Home → Driveway Staged → In RAM/Pack pill), a food/buy list with estimated costs, 80+ gear and 60+ food suggestions you add with a plus button (and remove again), and a Games tab with card/dice/domino games, what to bring, and how to play. |

## Build

The project is described by [`project.yml`](project.yml) and generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open RidgeLineOverland.xcodeproj
```

Then pick your Team under *Signing & Capabilities* and run on a device or simulator (iOS 18+, iPhone).
Tests: `xcodebuild test -scheme RidgeLineOverland -destination 'platform=iOS Simulator,name=iPhone 16'`.

## Architecture

```
RidgeLine/
  App/        App entry point
  Core/       Foundation-only models, solar math, GPX parser, tile math, Open-Meteo decoding, trip templates
  Services/   TripStore (JSON persistence), WeatherModel, LocationService, offline tile cache, Maps deep links
  Theme/      Colors, fonts, card and button styles (light-only palette)
  Views/      SwiftUI screens
  Resources/  Asset catalog, privacy manifest
RidgeLineTests/   Unit tests for everything in Core
```

* **No API keys.** Weather and elevation are [Open-Meteo](https://open-meteo.com/); map tiles are
  [USGS The National Map](https://basemap.nationalmap.gov/); nearby trails come from
  [OpenStreetMap](https://www.openstreetmap.org/) via the Overpass API; everything else is on-device.
* **Offline.** GPS needs no cell service. Use the download button on the map to save the visible area's topo tiles.
  Sunrise/sunset fall back to an on-device NOAA solar calculation, and the last forecast is cached.
* **Multiple trips.** Everything lives in a `Trip` value saved to `Application Support/RidgeLine/trips.json`.
  *Manage Trips* can start a new trip from the starter checklists or copy the Blood Mountain trip.
* **Privacy.** Location is used on-device only; the app has no accounts, analytics or tracking
  (see `RidgeLine/Resources/PrivacyInfo.xcprivacy`).

## Things to verify before you rely on them

* Trail lines for the four hikes are **hand-placed sketches** between known waypoints, flagged as such in the UI.
  Import surveyed `.gpx` files from AllTrails, Gaia, USFS or the Appalachian Trail Conservancy for navigation.
* The four free camps use the coordinates and road numbers from the trip brief. Confirm each road is open and
  legal to camp on with the Chattahoochee-Oconee National Forest (Blue Ridge Ranger District) before driving up.
* Mileage, drive times and fuel-stop mile markers are planning estimates.
