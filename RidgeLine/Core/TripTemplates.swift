import Foundation

// MARK: - Starter checklists (shared by every trip)

enum Starter {
    static func gear(vehicleShort v: String, hike: String) -> [GearItem] {
        let bed = "\(v) Bed Tent Setup"
        let pack = "\(hike) Daypack (10 Essentials)"
        let kitchen = "Tailgate Kitchen"

        func g(_ name: String, _ detail: String, _ cat: String) -> GearItem {
            GearItem(name: name, detail: detail, category: cat)
        }

        return [
            // Bed tent setup
            g("Truck-Bed Tent + Poles/Straps", "Do a dry-fit in the driveway; check every pole section and strap.", bed),
            g("Air Mattress or Foam Pad", "Bed-width pad; wheel wells make a full-size mattress awkward.", bed),
            g("12V Inverter / Pump", "Plugs into the truck's 12V socket to inflate the mattress.", bed),
            g("2× 20°F Sleeping Bags", "Mountain nights drop into the 30s°F — don't bring summer bags.", bed),
            g("Heavy Flannel Blankets & Pillows", "Extra insulation under and over the bags.", bed),
            g("Tailgate Lantern & String Lights", "Warm-white LED, charged or with fresh batteries.", bed),
            g("Wheel Chocks / Leveling Blocks", "Forest Service pull-offs are often sloped — level before you sleep.", bed),
            g("Tow Strap", "Rated recovery strap for soft shoulders and muddy pull-offs.", bed),
            g("Tire Deflator / Inflator", "Air down a few PSI on washboard gravel; re-inflate before pavement.", bed),
            g("Jumper Cables", "Lantern + 12V charging + cold nights = dead-battery risk.", bed),
            // Daypack
            g("2× Daypacks", "Roughly 20–30 L each.", pack),
            g("2× 2L Water Bladders", "Fill at camp; no tap water at dispersed sites.", pack),
            g("Sawyer Squeeze Filter", "Backup if you run low and need creek water.", pack),
            g("2× USB-C Headlamps (charged)", "Charge the night before; spare batteries or a short cable.", pack),
            g("Bear Spray / Bear Hang Rope", "Spray goes on your hip belt, not buried in the pack.", pack),
            g("First Aid & Blister Kit", "Moleskin, ibuprofen, tape, tweezers, antiseptic wipes.", pack),
            g("Windproof Fleece + Rain Shells", "Summit wind chill is real — one of each per person.", pack),
            g("Power Bank (20,000 mAh)", "Fully charged, with the right cables.", pack),
            g("12V Truck Charger", "Keeps phones and the power bank topped up on the drive.", pack),
            g("Trekking Poles", "Your knees will thank you on the descent.", pack),
            // Kitchen
            g("Hard Cooler + Ice Packs", "Pre-chill the night before; pack frozen items on the bottom.", kitchen),
            g("2-Burner Tailgate Stove", "Propane/butane camp stove with wind guards.", kitchen),
            g("Fuel Canisters", "Match the stove's fuel type; bring a spare.", kitchen),
            g("Cast Iron Skillet / Kettle", "Skillet for dinner, kettle for coffee.", kitchen),
            g("French Press", "Plus a mug each.", kitchen),
            g("Biodegradable Soap", "Wash dishes 200 ft from water (Leave No Trace).", kitchen),
            g("Trash Bags", "Pack out everything, including food scraps.", kitchen),
            // Housekeeping
            g("Trail Map Downloaded Offline", "Map tab → Save Area Offline while you still have signal.", "Before You Roll"),
            g("Sunscreen, Hat & Sunglasses", "UV is strongest on the open summit.", "Before You Roll"),
            // Games
            g("Playing Cards (2 Decks, Plastic)", "Plastic decks survive dew and spills.", "Games & Fun"),
            g("Cribbage Board + Pegs", "Travel boards fit in a pocket.", "Games & Fun"),
            g("Dice Set (6 Dice) + Cup", "For Farkle and a hundred other games.", "Games & Fun"),
            g("Score Pad & Pencils", "Pencils write when it's damp.", "Games & Fun")
        ]
    }

    static func food() -> [FoodItem] {
        func f(_ n: String, _ d: String, _ c: Double, _ cat: String) -> FoodItem {
            FoodItem(name: n, detail: d, estCost: c, category: cat)
        }
        let must = "Essentials"
        return [
            f("5-Gal Drinking Water Jugs (×2)", "No tap water at dispersed sites — about a gallon per person per day plus cooking.", 16, must),
            f("Trail Mix / Almonds / M&Ms", "The classic summit fuel.", 14, must),
            f("Beef Jerky & Protein Bars", "Shelf-stable and bear-resistant when stored in the cab.", 18, must),
            f("Honey Stinger Waffles", "Easy quick-carb snack for the climb.", 12, must),
            f("Electrolyte Packets", "Mix into the water bladders.", 10, must),
            f("Bagels", "Breakfast and trail lunch.", 4, must),
            f("Peanut Butter / Honey", "Bagel topper and emergency calories.", 8, must),
            f("Steak / Burgers / Foil-Packet Dinners", "Tailgate dinner for two — foil packets mean zero dishes.", 35, must),
            f("Eggs", "For chilly mountain mornings; pack in a crush-proof carton.", 5, must),
            f("Precooked Bacon", "Heats in minutes on the stove.", 7, must),
            f("Coffee", "Ground for the French press.", 9, must),
            f("Firewood Bundles", "Buy locally in Blairsville/Helen — don't move firewood between regions.", 21, must),
            f("Bagged Ice", "Top up the cooler on the way in.", 6, must),
            f("Coleman Green Propane Cylinders (2-pack)", "Fuel for the tailgate stove.", 10, must),
            f("Apples / Oranges", "Fresh fruit that survives the pack.", 6, must)
        ]
    }
}

// MARK: - Fuel stop plan (Gainesville → Byron Reece)

extension FuelPlan {
    static func ramBloodMountain() -> FuelPlan {
        FuelPlan(
            miles: 910, mpg: 16.0, price: 3.15, tankGallons: 26, travelers: 2,
            stops: [
                PitStop(id: "stop-gnv", name: "Depart Gainesville, FL",
                        detail: "Leave with a full 26-gal tank, ice and water in the cooler.", mile: 0),
                PitStop(id: "stop-bucees", name: "Buc-ee's Warner Robins (I-75 Exit 144)",
                        detail: "Roughly the halfway point — fuel, restrooms, snacks, ice.", mile: 229),
                PitStop(id: "stop-dahlonega", name: "Dahlonega / Cleveland, GA — final top-off",
                        detail: "Fill up before the mountains; forest roads burn more fuel and gas is scarce up high.", mile: 382),
                PitStop(id: "stop-arrive", name: "Arrive Byron Reece Trailhead",
                        detail: "US-19/129 at Neels Gap.", mile: 412)
            ],
            breakdownNote: "824 mi highway round trip + 86 mi mountain & forest roads")
    }
}

// MARK: - Default trip

extension Trip {
    static func bloodMountain() -> Trip {
        let origin = Place(id: "legacy-fort-clarke", name: "Legacy at Fort Clarke",
                           subtitle: "1505 Fort Clarke Blvd, Gainesville, FL",
                           kind: .origin, coord: Coord(29.6677, -82.4336))
        let summit = Place(id: "blood-summit", name: "Blood Mountain Summit & CCC Stone Shelter",
                           subtitle: "4,458 ft — highest point on the Georgia AT",
                           kind: .summit, coord: Coord(34.7398, -83.9378),
                           notes: "Historic 1930s CCC stone shelter with 360° views.")
        let reece = Place(id: "byron-reece-th", name: "Byron Herbert Reece Trailhead",
                          subtitle: "US-19/129, Blairsville, GA",
                          kind: .trailhead, coord: Coord(34.7422, -83.9226),
                          notes: "Day-use lot for the Freeman Trail and Blood Mountain.")
        let neels = Place(id: "neels-gap", name: "Mountain Crossings at Neels Gap",
                          subtitle: "The Appalachian Trail passes through the building",
                          kind: .landmark, coord: Coord(34.7351, -83.9179),
                          notes: "Outfitter and hostel; famous shoe tree out front.")
        let slaughter = Place(id: "slaughter-creek-th", name: "Slaughter Creek Trailhead",
                              subtitle: "Quieter creek-valley approach",
                              kind: .trailhead, coord: Coord(34.7501, -83.9642))
        let raven = Place(id: "raven-cliff-th", name: "Raven Cliff Falls Trailhead",
                          subtitle: "Richard B. Russell Scenic Hwy",
                          kind: .trailhead, coord: Coord(34.7069, -83.7885))
        let ravenFalls = Place(id: "raven-cliff-falls", name: "Raven Cliff Falls",
                               subtitle: "Slot-canyon waterfall, ~2.5 mi in",
                               kind: .landmark, coord: Coord(34.7220, -83.8170),
                               notes: "Falls position is approximate — follow the trail, not the pin.")
        let desoto = Place(id: "desoto-th", name: "DeSoto Falls Trailhead",
                           subtitle: "US-129, DeSoto Falls Recreation Area",
                           kind: .trailhead, coord: Coord(34.7069, -83.9154),
                           notes: "Recreation area charges a small day-use fee.")
        let vogel = Place(id: "vogel", name: "Vogel State Park & Lake Trahlyta",
                          subtitle: "Easy lakeside loop",
                          kind: .landmark, coord: Coord(34.7652, -83.9222))
        let helen = Place(id: "alpine-helen", name: "Alpine Helen Bavarian Village",
                          subtitle: "Post-hike schnitzel & brats",
                          kind: .town, coord: Coord(34.7014, -83.7338))

        let camp1 = Place(id: "camp-tray", name: "FREE Camp #1 — Tray Mountain Rd (FS 79) / Indian Grave Gap",
                          subtitle: "Dispersed USFS pull-offs",
                          kind: .camp, coord: Coord(34.7735, -83.7132),
                          notes: "Graded forest road with scattered pull-offs. Expect washboard and ruts after rain; scout narrow pull-offs on foot before backing in. Higher elevation means colder nights.")
        let camp2 = Place(id: "camp-corbin", name: "FREE Camp #2 — Corbin Creek Rd (FS 698)",
                          subtitle: "Creekside dispersed camping",
                          kind: .camp, coord: Coord(34.8124, -83.6940),
                          notes: "Creekside sites are tempting but low and damp — camp on the flattest, highest durable spot and keep well back from the water.")
        let camp3 = Place(id: "camp-wildcat", name: "FREE Camp #3 — Wildcat Creek Rd (FS 26-1)",
                          subtitle: "Forested stream pull-offs",
                          kind: .camp, coord: Coord(34.7621, -83.6025),
                          notes: "Forest-road spur; check the road number and condition at the junction before committing a full-size crew cab.")
        let camp4 = Place(id: "camp-chatt", name: "FREE Camp #4 — Upper Chattahoochee River Rd (FS 44)",
                          subtitle: "Just north of Helen, GA",
                          kind: .camp, coord: Coord(34.7695, -83.7810),
                          notes: "Closest to Helen and the easiest drive of the four. It's popular: arrive early on weekends and use only established sites.")

        let places = [origin, reece, summit, neels, slaughter, raven, ravenFalls, desoto, vogel, helen,
                      camp1, camp2, camp3, camp4]

        // Hand-placed sketches between known waypoints. Replace with surveyed GPX via the Map tab.
        let freemanUp: [Coord] = [
            Coord(34.7422, -83.9226), Coord(34.7425, -83.9262), Coord(34.7418, -83.9298),
            Coord(34.7410, -83.9331), Coord(34.7402, -83.9358), Coord(34.7398, -83.9378)
        ]
        let atDownToNeels: [Coord] = [
            Coord(34.7398, -83.9378), Coord(34.7385, -83.9340), Coord(34.7372, -83.9290),
            Coord(34.7362, -83.9240), Coord(34.7351, -83.9179), Coord(34.7422, -83.9226)
        ]
        let slaughterPath: [Coord] = [
            Coord(34.7501, -83.9642), Coord(34.7478, -83.9570), Coord(34.7450, -83.9510),
            Coord(34.7425, -83.9450), Coord(34.7405, -83.9400), Coord(34.7398, -83.9378)
        ]
        let ravenPath: [Coord] = [
            Coord(34.7069, -83.7885), Coord(34.7110, -83.7940), Coord(34.7150, -83.8030),
            Coord(34.7186, -83.8092), Coord(34.7220, -83.8170)
        ]

        let routes = [
            HikeRoute(id: "blood-loop", name: "Blood Mountain Loop (Byron Reece + AT + Freeman Trail)",
                      miles: 6.0, gainFt: 1460, difficulty: "Moderate–Strenuous", style: "Loop",
                      blurb: "Up the Freeman Trail to the CCC shelter, then down the Appalachian Trail past Neels Gap.",
                      trailheadID: "byron-reece-th", path: freemanUp + atDownToNeels.dropFirst().map { $0 }),
            HikeRoute(id: "blood-oab", name: "Blood Mountain Summit Out-and-Back",
                      miles: 4.3, gainFt: 1460, difficulty: "Moderate–Strenuous", style: "Out & back",
                      blurb: "The shortest way to the summit and its 360° views.",
                      trailheadID: "byron-reece-th", path: freemanUp),
            HikeRoute(id: "slaughter", name: "Slaughter Creek to Blood Mountain",
                      miles: 5.6, gainFt: 1460, difficulty: "Moderate–Strenuous", style: "Out & back",
                      blurb: "A quieter creek-valley approach with far fewer people on the trail.",
                      trailheadID: "slaughter-creek-th", path: slaughterPath),
            HikeRoute(id: "raven-cliff", name: "Raven Cliff Falls Trail",
                      miles: 5.0, gainFt: 0, difficulty: "Easy", style: "Out & back",
                      blurb: "A gentle creekside walk into a waterfall canyon — a good rest-day hike.",
                      trailheadID: "raven-cliff-th", path: ravenPath)
        ]

        let legs = [
            RouteLeg(id: "leg-1", title: "Gainesville → Macon area", roads: "I-75 N",
                     miles: 229, minutes: 205,
                     from: Endpoint(title: "Legacy at Fort Clarke",
                                    query: "1505 Fort Clarke Blvd, Gainesville, FL 32606", coord: origin.coord),
                     to: Endpoint(title: "Buc-ee's Warner Robins (Exit 144)",
                                  query: "Buc-ee's, Warner Robins, GA", coord: nil)),
            RouteLeg(id: "leg-2", title: "Macon → Dahlonega", roads: "I-75 N → GA-400 N",
                     miles: 153, minutes: 137,
                     from: Endpoint(title: "Buc-ee's Warner Robins (Exit 144)",
                                    query: "Buc-ee's, Warner Robins, GA", coord: nil),
                     to: Endpoint(title: "Dahlonega, GA", query: "Dahlonega, GA", coord: Coord(34.5326, -83.9849))),
            RouteLeg(id: "leg-3", title: "Dahlonega → Blood Mountain", roads: "GA-115 → US-19/129 N",
                     miles: 30, minutes: 50,
                     from: Endpoint(title: "Dahlonega, GA", query: "Dahlonega, GA", coord: Coord(34.5326, -83.9849)),
                     to: Endpoint(title: "Byron Herbert Reece Trailhead", query: nil, coord: reece.coord))
        ]

        let sights = [
            Sight(id: "s-ccc", placeID: "blood-summit", name: "Blood Mountain CCC Stone Shelter",
                  blurb: "1930s stone shelter on the 4,458 ft summit.", symbol: "mountain.2.fill"),
            Sight(id: "s-neels", placeID: "neels-gap", name: "Mountain Crossings at Neels Gap",
                  blurb: "The AT walks right through the building.", symbol: "shoeprints.fill"),
            Sight(id: "s-raven", placeID: "raven-cliff-falls", name: "Raven Cliff Falls",
                  blurb: "Waterfall pouring through a rock cleft.", symbol: "drop.fill"),
            Sight(id: "s-desoto", placeID: "desoto-th", name: "DeSoto Falls",
                  blurb: "Tiered falls on a short, easy trail.", symbol: "drop.fill"),
            Sight(id: "s-vogel", placeID: "vogel", name: "Vogel State Park — Lake Trahlyta",
                  blurb: "Easy lake loop with a mountain backdrop.", symbol: "water.waves"),
            Sight(id: "s-helen", placeID: "alpine-helen", name: "Alpine Helen Bavarian Village",
                  blurb: "Schnitzel and brats after the hike.", symbol: "fork.knife")
        ]

        return Trip(
            name: "Blood Mountain & Helen",
            subtitle: "2-person truck-bed camping + hiking",
            vehicle: "2013 RAM 1500 Crew Cab",
            vehicleShort: "RAM",
            timeZoneID: "America/New_York",
            origin: origin, destination: summit,
            places: places, routes: routes, activeRouteID: "blood-oab",
            legs: legs, sights: sights,
            gear: Starter.gear(vehicleShort: "RAM", hike: "Blood Mountain"),
            food: Starter.food(),
            fuel: .ramBloodMountain(),
            games: Starter.games())
    }

    /// A fresh copy of this trip (new id, checklist progress reset) for planning a repeat or similar trip.
    func duplicated(as newName: String) -> Trip {
        var t = self
        t.id = UUID()
        t.name = newName
        t.gear = gear.map { var g = $0; g.id = UUID(); g.stage = .atHome; return g }
        t.food = food.map { var f = $0; f.id = UUID(); f.bought = false; return f }
        t.sights = sights.map { var s = $0; s.visited = false; return s }
        t.tripDate = Date()
        return t
    }

    /// A blank trip that still comes with the full starter checklists.
    static func starter(name: String, vehicle: String = "Truck", vehicleShort: String = "Truck") -> Trip {
        Trip(name: name, subtitle: "New trip", vehicle: vehicle, vehicleShort: vehicleShort,
             gear: Starter.gear(vehicleShort: vehicleShort, hike: "Trail"),
             food: Starter.food(),
             fuel: FuelPlan(),
             games: Starter.games())
    }
}
