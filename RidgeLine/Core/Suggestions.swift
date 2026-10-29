import Foundation

struct GearSuggestion: Identifiable, Hashable {
    var name: String
    var detail: String
    var category: String
    var id: String { name }
}

struct FoodSuggestion: Identifiable, Hashable {
    var name: String
    var detail: String
    var cost: Double
    var category: String
    var id: String { name }
}

/// Tap-to-add ideas so nobody has to type a packing or shopping list from scratch.
enum Suggestions {
    static let gearCategories = [
        "Clothing & Layers", "Sleep & Comfort", "Safety & Navigation", "Camp & Truck Tools",
        "Hygiene & Health", "Electronics & Photo", "Kitchen Extras", "Weather Gear",
        "Documents & Money", "Games & Fun"
    ]

    static let foodCategories = [
        "Breakfast", "Lunch & Trail", "Dinner", "Snacks & Sweets", "Drinks", "Camp Supplies"
    ]

    /// The one-tap "game kit" — everything the games in the Games tab need.
    static let gameKitNames = [
        "Playing Cards (2 Decks, Plastic)", "Cribbage Board + Pegs", "Dice Set (6 Dice) + Cup",
        "Score Pad & Pencils", "Dominoes (Double-Six)"
    ]

    static var gameKit: [GearSuggestion] { gear.filter { gameKitNames.contains($0.name) } }

    private static func g(_ name: String, _ detail: String, _ category: String) -> GearSuggestion {
        GearSuggestion(name: name, detail: detail, category: category)
    }

    private static func f(_ name: String, _ detail: String, _ cost: Double, _ category: String) -> FoodSuggestion {
        FoodSuggestion(name: name, detail: detail, cost: cost, category: category)
    }

    static let gear: [GearSuggestion] = {
        let cl = "Clothing & Layers", sl = "Sleep & Comfort", sf = "Safety & Navigation", tl = "Camp & Truck Tools"
        let hy = "Hygiene & Health", el = "Electronics & Photo", kt = "Kitchen Extras", wx = "Weather Gear"
        let dc = "Documents & Money", gm = "Games & Fun"
        return [
            // Clothing
            g("Warm Beanie", "Cold mornings and summit wind.", cl),
            g("Light Gloves", "Thin liners for the summit and early starts.", cl),
            g("Extra Wool Socks (2 Pairs)", "Dry socks are the best morale boost on the trail.", cl),
            g("Merino Base Layers", "Top and bottom — sleep in them on 30s°F nights.", cl),
            g("Puffy Insulated Jacket", "Packs small, warms up camp evenings.", cl),
            g("Camp Shoes / Sandals", "Let your boots dry out and your feet breathe.", cl),
            g("Hiking Boots or Trail Shoes", "Broken in — not new out of the box.", cl),
            g("Moisture-Wicking Shirts (2)", "Cotton stays wet and gets cold.", cl),
            g("Hiking Pants or Convertibles", "Brush, ticks and wind protection.", cl),
            g("Sun Hat or Visor", "Summit sun is strong.", cl),
            g("Sunglasses", "Polarized if you have them.", cl),
            g("Neck Gaiter / Buff", "Wind, dust, sun, or a quick ear warmer.", cl),
            g("Spare Dry Clothes Set", "Leave it in the cab for after the hike.", cl),
            g("Sleep Clothes", "Dedicated dry layers for the tent only.", cl),
            // Sleep
            g("Folding Camp Chairs (2)", "Tailgate dinners are better sitting down.", sl),
            g("Folding Camp Table", "Stove, cooler lid and cards all need a surface.", sl),
            g("Earplugs & Eye Mask", "Forest roads aren't as quiet as you'd think.", sl),
            g("Sleeping Bag Liners", "Adds warmth and keeps bags clean.", sl),
            g("Extra Pillows", "Bed-tent comfort is mostly about the pillows.", sl),
            g("Tarp Over the Bed Tent", "Extra rain and dew protection.", sl),
            g("Hand Warmers", "Toss one in each sleeping bag foot.", sl),
            g("Hot-Water Bottle (Nalgene)", "Fill with hot water before bed — a bag warmer that doubles as a bottle.", sl),
            g("Outdoor Rug / Mat", "Keeps dirt out of the bed tent.", sl),
            g("Tent Footprint / Bed Liner", "Protects the tent floor from truck-bed grit.", sl),
            // Safety
            g("Paper Map & Compass", "Phones die. Learn the junction names before you go.", sf),
            g("Emergency Whistle", "Three blasts means help. Clip it to your pack.", sf),
            g("Emergency Blankets (2)", "Tiny, light, genuinely life-saving.", sf),
            g("Multi-Tool or Knife", "Gear repairs, food prep, first aid.", sf),
            g("Lighter + Waterproof Matches", "Redundant fire starters in a dry case.", sf),
            g("Satellite Messenger", "Garmin inReach or similar — text with zero signal.", sf),
            g("Spare Flashlight + Batteries", "A backup for the headlamps.", sf),
            g("Duct Tape & Paracord", "Fixes almost everything, including tent poles.", sf),
            g("Trip Plan Left With a Friend", "Where you're parked, when you'll be back.", sf),
            g("Tick Remover / Tweezers", "Check yourselves every evening.", sf),
            // Tools
            g("Folding Shovel / Trowel", "Cat holes and fire-pit safety.", tl),
            g("Hatchet or Folding Saw", "For firewood and kindling.", tl),
            g("Work Gloves", "Hot cookware and firewood handling.", tl),
            g("Bungee Cords & Rope", "Securing tarps and gear in the bed.", tl),
            g("Zip Ties", "Cheap, tiny, endlessly useful.", tl),
            g("Tire Plug Kit + Compressor", "Gravel roads eat tires.", tl),
            g("Fire Starters / Kindling", "Dry kindling beats wet wood every time.", tl),
            g("Full-Size Spare + Jack Check", "Confirm the spare is inflated and the jack is in the truck.", tl),
            g("Tent Stakes & Mallet", "If your bed tent has guy-out points.", tl),
            g("Headlamp Spare Batteries", "AAA/CR123 as your lamps require.", tl),
            // Hygiene
            g("Toilet Paper + Trowel", "Pack out used paper in a bag.", hy),
            g("Hand Sanitizer", "Before eating and after cat holes.", hy),
            g("Wet Wipes", "Cheap shower substitute.", hy),
            g("Toothbrush & Toothpaste", "Spit well away from camp.", hy),
            g("Sunscreen (SPF 30+)", "Reapply on the summit.", hy),
            g("Bug Spray", "Ticks and mosquitoes are active into fall.", hy),
            g("Lip Balm (SPF)", "Wind chaps fast.", hy),
            g("Quick-Dry Towel", "Dries overnight on the tailgate.", hy),
            g("Personal Medications", "Plus an allergy pill and pain reliever.", hy),
            g("Foot Care (Powder / Body Glide)", "Stops blisters before they start.", hy),
            // Electronics
            g("Camera + Spare Battery", "Golden-hour summit photos.", el),
            g("Solar Panel Charger", "Backup power if the truck battery needs saving.", el),
            g("Extra Charging Cables", "Always the one thing someone forgets.", el),
            g("Binoculars", "Birds, ridgelines and the stars.", el),
            g("Weather Radio", "NOAA alerts when phones have no signal.", el),
            g("Portable Speaker", "Low volume — it's a forest, not a party.", el),
            g("Tripod / Phone Mount", "Group shots and night sky.", el),
            // Kitchen extras
            g("Dish Tub + Scrubber", "Wash 200 ft from water, pour gray water on soil.", kt),
            g("Camp Mugs (2)", "Insulated mugs keep coffee hot.", kt),
            g("Plates, Bowls & Utensils", "Reusable beats disposable.", kt),
            g("Spatula & Tongs", "Skillet and foil-packet duty.", kt),
            g("Can Opener", "Always the one thing you forget.", kt),
            g("Cutting Board & Knife", "Sheath the knife.", kt),
            g("Heavy-Duty Aluminum Foil", "Foil-packet dinners and fire-pit baking.", kt),
            g("Reusable Water Bottles (2)", "On top of the water bladders.", kt),
            g("Paper Towels", "Mess control.", kt),
            g("Zip-Top Bags", "Leftovers, trash, wet gear.", kt),
            g("Spice Kit & Cooking Oil", "Salt, pepper, oil — makes camp food taste like food.", kt),
            g("Marshmallow Roasting Sticks", "S'mores are mandatory.", kt),
            g("Fire-Ring Grill Grate", "Cook over the coals.", kt),
            g("Thermos", "Hot drinks on the summit.", kt),
            // Weather
            g("Extra Rain Poncho", "Cheap insurance for the second night.", wx),
            g("Dry Bags", "Keep sleeping bags dry if the tent leaks.", wx),
            g("Pack Rain Covers", "Or trash compactor bags as liners.", wx),
            g("Cooking Tarp & Cord", "Rain shelter over the tailgate kitchen.", wx),
            // Documents
            g("Driver's License & Insurance", "Plus registration in the glovebox.", dc),
            g("Cash for Fees", "DeSoto Falls charges a small day-use fee; some lots take cash only.", dc),
            g("Roadside Assistance Card", "Know the number before you lose signal.", dc),
            g("Printed Itinerary", "Addresses and phone numbers, in case phones die.", dc),
            // Games
            g("Playing Cards (2 Decks, Plastic)", "Plastic decks survive dew and spills.", gm),
            g("Cribbage Board + Pegs", "Travel boards fit in a pocket.", gm),
            g("Dice Set (6 Dice) + Cup", "For Farkle and a hundred other games.", gm),
            g("Score Pad & Pencils", "Pencils write when it's damp.", gm),
            g("Dominoes (Double-Six)", "28 tiles, great on a tailgate.", gm),
            g("Paperback or E-Reader", "Quiet time in the tent.", gm),
            g("Star Chart or Sky App", "Great dark skies away from town.", gm)
        ]
    }()

    static let food: [FoodSuggestion] = {
        let bf = "Breakfast", ln = "Lunch & Trail", dn = "Dinner", sn = "Snacks & Sweets", dr = "Drinks", cs = "Camp Supplies"
        return [
            // Breakfast
            f("Instant Oatmeal Packets", "Add hot water, done.", 5, bf),
            f("Pancake Mix (Just Add Water)", "Cast iron skillet pancakes.", 4, bf),
            f("Frozen Breakfast Burritos", "Wrap in foil and warm on the stove.", 9, bf),
            f("Yogurt Cups", "Eat the first morning.", 5, bf),
            f("Granola + Shelf-Stable Milk", "No cooler space needed.", 8, bf),
            f("Breakfast Sausage", "Keep it in the bottom of the cooler.", 6, bf),
            f("Bananas", "Perfect trail fuel.", 3, bf),
            f("Hash Browns (Frozen)", "Skillet them with the eggs.", 4, bf),
            f("Maple Syrup (Small Bottle)", "For pancakes and oatmeal.", 5, bf),
            f("Coffee Creamer", "Shelf-stable singles travel well.", 4, bf),
            f("Hot Chocolate Packets", "For chilly mountain mornings.", 4, bf),
            f("Tea Bags", "Easy hot drink on the summit with a thermos.", 4, bf),
            // Lunch
            f("Tortillas + Tuna or Chicken Packets", "Wraps without a cooler.", 9, ln),
            f("Deli Meat & Cheese", "Summit sandwiches.", 12, ln),
            f("String Cheese / Babybel", "Protein that survives the pack.", 6, ln),
            f("Crackers + Summer Sausage", "Classic trail lunch.", 10, ln),
            f("Hummus + Pita", "Eat it early on.", 7, ln),
            f("Instant Ramen Cups", "Add boiling water.", 5, ln),
            f("Dried Fruit / Fruit Leather", "Light, sweet, no mess.", 7, ln),
            f("Nut Butter Squeeze Packs", "Calories per ounce champion.", 9, ln),
            f("Peanut Butter Crackers", "Hand-sized snack.", 5, ln),
            f("Carrots / Snap Peas", "Crunchy and fresh.", 5, ln),
            // Dinner
            f("Hot Dogs + Buns", "Fire-roasted and easy.", 8, dn),
            f("Bratwurst (Pre-Cooked)", "A nod to Helen's Bavarian village.", 9, dn),
            f("Canned Chili", "One pot, zero effort.", 6, dn),
            f("Mac & Cheese Boxes", "Cook it in the kettle.", 4, dn),
            f("Pasta + Jarred Sauce", "Pre-cook at home if you want fewer dishes.", 7, dn),
            f("Taco Kit (Ground Beef, Shells, Cheese)", "Tailgate tacos.", 14, dn),
            f("Chicken Fajita Kit", "Skillet on the 2-burner stove.", 14, dn),
            f("Corn on the Cob", "Foil it in the coals.", 5, dn),
            f("Baked Potatoes", "Wrap in foil and bury in the embers.", 5, dn),
            f("Veggies for Foil Packets", "Peppers, onions, zucchini.", 7, dn),
            f("Dehydrated Backpacking Meals (2)", "No-fuss backup dinners.", 22, dn),
            f("Microwave Rice Cups", "Heat in boiling water.", 5, dn),
            f("Smoked Sausage", "Slice into skillet meals.", 7, dn),
            f("Canned Soup", "Warm and quick on cold nights.", 6, dn),
            // Snacks
            f("S'mores Kit", "Graham crackers, chocolate, marshmallows.", 9, sn),
            f("Chips + Salsa", "Tailgate happy hour.", 7, sn),
            f("Popcorn Kernels", "Foil-pouch popcorn over the fire.", 4, sn),
            f("Cookies", "Morale.", 5, sn),
            f("Gummy Candy", "Quick sugar on the climb.", 4, sn),
            f("Fig Bars", "Sturdy, not crushed by the pack.", 5, sn),
            f("Granola Bars", "Backup trail bars.", 6, sn),
            f("Dried Mango", "Sweet without the sticky.", 7, sn),
            f("Summit Chocolate Bar", "Earned at 4,458 ft.", 4, sn),
            f("Pretzels", "Salty and crunchy.", 4, sn),
            // Drinks
            f("Electrolyte Drink Mix", "Powder is lighter than bottles.", 9, dr),
            f("Sparkling Water", "A tailgate treat.", 6, dr),
            f("Beer or Hard Seltzer (21+)", "Cans only; no glass in the forest.", 12, dr),
            f("Juice Boxes", "Shelf-stable.", 5, dr),
            f("Apple Cider", "Perfect in fall.", 5, dr),
            f("Powdered Drink Mix", "Flavor for the water jugs.", 5, dr),
            f("Cold Brew", "A bottle for the first morning.", 6, dr),
            // Supplies
            f("Ketchup & Mustard Packets", "Grab handfuls.", 4, cs),
            f("Cooking Oil Spray", "Skillet non-stick.", 6, cs),
            f("Salt, Pepper & Spice Kit", "A small shaker set.", 5, cs),
            f("Butter", "Keeps cold in the cooler.", 4, cs),
            f("Extra Bagged Ice", "Top off on day two.", 3, cs),
            f("Fire Starters", "Wax cubes or fatwood.", 5, cs),
            f("Dish Soap (Biodegradable)", "Tiny bottle is enough.", 4, cs),
            f("Trash Bags (Heavy Duty)", "Pack it out.", 4, cs),
            f("Paper Towels", "Camp kitchen essential.", 3, cs)
        ]
    }()
}
