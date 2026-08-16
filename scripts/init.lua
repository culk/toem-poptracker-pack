ENABLE_DEBUG_LOG = true

-- Items
require("scripts/items_import")

-- Logic
require("scripts/logic/logic_helper")
require("scripts/logic/base_logic")

-- Maps
Tracker:AddMaps("maps/maps.json")

-- Layout
require("scripts/layouts_import")

-- Locations
require("scripts/locations_import")

-- AutoTracking
require("scripts/autotracking")
require("scripts/watches")