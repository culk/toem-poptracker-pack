-- Boolean functions, all return a boolean.

function has_required_stamps_for(level_name)
    local is_progressive_stamps = Tracker:FindObjectForCode("progressive_stamps").CurrentStage == 1
    if not is_progressive_stamps then
        -- Check for the correct number of stamps for the specific level.
        local required_stamps = Tracker:FindObjectForCode("stamp_requirement_"..level_name).AcquiredCount
        local found_stamps = Tracker:FindObjectForCode(level_name.."_stamp").AcquiredCount
        return found_stamps >= required_stamps
    end

    -- Sum up the stamp requirements for all earlier levels.
    local all_levels = {"homelanda", "oaklaville", "stanhamn", "logcity", "kiiruberg", "basto"}
    local required_stamps = 0
    for _, earlier_level in ipairs(all_levels) do
        required_stamps = required_stamps + Tracker:FindObjectForCode("stamp_requirement_"..earlier_level).AcquiredCount
        if level_name == earlier_level then break end
    end
    local found_stamps = Tracker:FindObjectForCode("progressive_stamp").AcquiredCount
    return found_stamps >= required_stamps
end

-- Access functions, all return an AccessibilityLevel.

function can_reach(region_name)
    -- If entrances are randomized then check if the region has been found.
    if Tracker:FindObjectForCode("entrance_randomization").CurrentStage ~= 0 then
        local max_access = AccessibilityLevel.None
        for _, connection_name in ipairs(CONNECTIONS_BY_REGION[region_name]) do
            local source_connection = CONNECTION_BY_NAME[connection_name].Destination
            if source_connection then
                local location = Tracker:FindObjectForCode(source_connection.LocationRef)
                if location then
                    local connection_access = ALL(connection_name, location.AccessibilityLevel)
                    if connection_access == AccessibilityLevel.Normal then
                        return connection_access
                    elseif connection_access > max_access then
                        max_access = connection_access
                    end
                else
                    print("ERROR: can_reach: failed to find connection for ref", source_connection.LocationRef)
                end
            end
        end
        return max_access
    end

    -- Otherwise, default logic required for each region that has restricted access.
    -- Check for stamp/basto ticket requirements.
    local level_name = region_name:sub(1, region_name:find("_") - 1)
    if level_name == "oaklaville" then
       if ALL("@Oaklaville") == AccessibilityLevel.None then return AccessibilityLevel.None end
    elseif level_name == "stanhamn" then
       if ALL("@Stanhamn") == AccessibilityLevel.None then return AccessibilityLevel.None end
    elseif level_name == "logcity" then
       if ALL("@Logcity") == AccessibilityLevel.None then return AccessibilityLevel.None end
    elseif level_name == "kiiruberg" then
       if ALL("@Kiiruberg") == AccessibilityLevel.None then return AccessibilityLevel.None end
    elseif level_name == "mountain" then
       if ALL("@Mountain Top") == AccessibilityLevel.None then return AccessibilityLevel.None end
    elseif level_name == "basto" then
       if ALL("@Basto") == AccessibilityLevel.None then return AccessibilityLevel.None end
    end

    -- Check for required key items.
    if region_name == "oaklaville_rave" then
        return HAS("ghost_glasses")
    elseif IsInTable(region_name, {
        "stanhamn_outside_hydroplant",
        "stanhamn_ghost_drawbridge_top",
        "stanhamn_ghost_drawbridge_bottom",
        "stanhamn_fishing_tower",
        "stanhamn_hydroplant",
        "stanhamn_docks_right",
        "stanhamn_king_fish_beach",
    }) then
        return HAS("honk_attachment")
    elseif region_name == "stanhamn_underwater" then
        return ALL("honk_attachment", "diving_helmet")
    elseif IsInTable(region_name, {
        "logcity_fashion_show_top",
        "logcity_fashion_show_backstage",
    }) then
        return HAS("reporter_hat")
    elseif IsInTable(region_name, {
        "kiiruberg_birthday_party_top",
        "kiiruberg_snowman_square_bottom",
        "kiiruberg_snowman_square_top",
        "kiiruberg_military_base",
        "kiiruberg_mecks_house",
        "kiiruberg_outside_wizard_tower",
        "kiiruberg_wizard_tower",
        "kiiruberg_cliffs_bottom",
        "kiiruberg_cliffs_middle",
        "kiiruberg_outside_observ_top",
        "kiiruberg_observatory",
        "kiiruberg_birthday_party_top",
        "kiiruberg_snowman_square_bottom",
        "kiiruberg_snowman_square_top",
        "kiiruberg_military_base",
        "kiiruberg_mecks_house",
        "kiiruberg_outside_wizard_tower",
        "kiiruberg_wizard_tower",
        "kiiruberg_cliffs_bottom",
        "kiiruberg_cliffs_middle",
        "kiiruberg_outside_observ_top",
        "kiiruberg_observatory",
    }) then
        return HAS("climbing_boots")
    elseif IsInTable(region_name, {
        "kiiruberg_blizzard_bridge_dl",
        "kiiruberg_blizzard_bridge_ul",
        "kiiruberg_blizzard_bridge_right",
        "kiiruberg_blizzard_monster",
    }) then
        return ALL("honk_attachment", has_warm_clothing)
    elseif region_name == "kiiruberg_cosmo_garden" then
        return ALL("@Can Access/Quest - Ice wizards research")
    elseif IsInTable(region_name, {
        "kiiruberg_man_cave",
        "mountain_top_toem"
    }) then
        return ALL("@Can Access/Achievement - Experience TOEM")
    elseif region_name == "basto_secret_cave" then
        return ALL("watergun", "pickaxe")
    elseif region_name:sub(1, 5) == "basto" and region_name ~= "basto_bus_stop_bottom" then
        return HAS("watergun")
    end

    return AccessibilityLevel.Normal
end

function can_reach_all(...)
    local args = { ... }
    local min = AccessibilityLevel.Normal
    for _, v in ipairs(args) do
        local access = can_reach(v)
        if access == AccessibilityLevel.None then
            return AccessibilityLevel.None
        elseif access < min then
            min = access
        end
    end
    return min
end

function can_reach_any(...)
    local args = { ... }
    local max = AccessibilityLevel.None
    for _, v in ipairs(args) do
        local access = can_reach(v)
        if access == AccessibilityLevel.Normal then
            return AccessibilityLevel.Normal
        elseif access > max then
            max = access
        end
    end
    return max
end

-- "Quest - Monster spotting"
function can_access_monsters()
    return (
        ALL(
            ANY(
                ALL("tripod", "honk_attachment"),
                AccessibilityLevel.SequenceBreak
            ),
            can_reach_all(
                "oaklaville_playground",
                "stanhamn_hippo_beach",
                "logcity_skate_park",
                "kiiruberg_blizzard_monster"
            )
        )
    )
end

-- "Achievement - Strong as an oak"
function can_access_all_oaklaville_quests()
    return ALL(
        "@Can Access/Quest - Suspicious activity - forest",
        "@Can Access/Quest - Monster spotting",
        "@Can Access/Quest - Missing socks",
        "@Can Access/Quest - Become a scout",
        "@Can Access/Quest - Hide-and-seek",
        "@Can Access/Quest - Log blocking a path",
        "@Can Access/Quest - Photo challenge #1",
        "@Can Access/Quest - Photo challenge #2",
        "@Can Access/Quest - Become a paparazzi",
        "@Can Access/Quest - Capture the hotels beauty",
        "@Can Access/Quest - Hotel chef",
        "@Can Access/Quest - A courageous stallion",
        "@Can Access/Quest - Ghost helper!",
        "@Can Access/Quest - Cup champion",
        "@Can Access/Quest - Become a flower"
    )
end

-- "Achievement - Seaworthy"
function can_access_all_stanhamn_quests()
    return ALL(
        "@Can Access/Quest - The king of fishes",
        "@Can Access/Quest - A good spot with no sun",
        "@Can Access/Quest - Suspicious activity - harbor",
        "@Can Access/Quest - Queen of paper hats",
        "@Can Access/Quest - Photo challenge #3",
        "@Can Access/Quest - Photo challenge #4",
        "@Can Access/Quest - Frames & filters!",
        "@Can Access/Quest - Make someone take a bath",
        "@Can Access/Quest - A lost dog",
        "@Can Access/Quest - Power shortage!",
        "@Can Access/Quest - Solve the chaos",
        "@Can Access/Quest - Scorching flame",
        "@Can Access/Quest - Supreme deluxe sandwich!",
        "@Can Access/Quest - Ocean garbage",
        "@Can Access/Quest - A whistling dilemma",
        "@Can Access/Quest - A layered melody"
    )
end

-- "Achievement - Business executed"
function can_access_all_logcity_quests()
    return ALL(
        "@Can Access/Quest - Suspicious activity - city",
        "@Can Access/Quest - Ratskullz crew",
        "@Can Access/Quest - Punk rocker bread crumbs",
        "@Can Access/Quest - Photo challenge #5",
        "@Can Access/Quest - Photo challenge #6",
        "@Can Access/Quest - Press-ing news",
        "@Can Access/Quest - Sewer stumble!",
        "@Can Access/Quest - Super Hotbean Bros.",
        "@Can Access/Quest - Hang in there buddy",
        "@Can Access/Quest - Spooky scary city",
        "@Can Access/Quest - A ghostly date",
        "@Can Access/Quest - Art exhibition",
        "@Can Access/Quest - Young and inspiring!",
        "@Can Access/Quest - A design problem",
        "@Can Access/Quest - Cleaning away the stress",
        "@Can Access/Quest - Always tumbled granny",
        "@Can Access/Quest - A mouse bakery",
        "@Can Access/Quest - A thieving crow"
    )
end

-- "Achievement - Ice fighter"
function can_access_all_kiiruberg_quests()
    return ALL(
        "@Can Access/Quest - Yeti cuteness",
        "@Can Access/Quest - Ice wizards research",
        "@Can Access/Quest - Military suspicions",
        "@Can Access/Quest - Play astronaut",
        "@Can Access/Quest - Photo challenge #7",
        "@Can Access/Quest - Photo challenge #8",
        "@Can Access/Quest - Locating an asteroid",
        "@Can Access/Quest - Listen to the goat choir",
        "@Can Access/Quest - Snowball memories",
        "@Can Access/Quest - Birthday in distress",
        "@Can Access/Quest - Ancient paintings",
        "@Can Access/Quest - Become a yeti",
        "@Can Access/Quest - Assemble a snowman"
    )
end

-- "Achievement - A Viking's holiday"
function can_access_all_basto_quests()
    return ALL(
        "@Can Access/Quest - Basto's hidden balloons",
        "@Can Access/Quest - Arthur hunter",
        "@Can Access/Quest - Bad hair day",
        "@Can Access/Quest - Take a nap!",
        "@Can Access/Quest - Spooky stories",
        "@Can Access/Quest - Painterly portrait",
        "@Can Access/Quest - Night-time cinema",
        "@Can Access/Quest - Night lights",
        "@Can Access/Quest - Jet-ski tricks",
        "@Can Access/Quest - Fruit shortage",
        "@Can Access/Quest - Brain freeze",
        "@Can Access/Quest - Sweet tooth",
        "@Can Access/Quest - In your face",
        "@Can Access/Quest - Broken dreams",
        "@Can Access/Quest - Dry season",
        "@Can Access/Quest - Dehydrated muscles",
        "@Can Access/Quest - Sand castle competition",
        "@Can Access/Quest - Play a carnival game",
        "@Can Access/Quest - Book of bats",
        "@Can Access/Quest - Bitling collector"
    )
end

-- "Item - Photo challenger flag"
function can_access_all_photo_challenges()
    return ALL(
        "@Can Access/Quest - Photo challenge #1",
        "@Can Access/Quest - Photo challenge #2",
        "@Can Access/Quest - Photo challenge #3",
        "@Can Access/Quest - Photo challenge #4",
        "@Can Access/Quest - Photo challenge #5",
        "@Can Access/Quest - Photo challenge #6",
        "@Can Access/Quest - Photo challenge #7",
        "@Can Access/Quest - Photo challenge #8"
    )
end

-- "Achievement - Who's a good boy!"
function can_pet()
    return can_reach_any(
        "oaklaville_outside_hotel",
        "oaklaville_hotel",
        "oaklaville_graveyard",
        "oaklaville_camp",
        "stanhamn_docks_right",
        "stanhamn_docks_left",
        "stanhamn_king_fish_beach",
        "logcity_outside_cafe",
        "kiiruberg_balloon_house",
        "kiiruberg_mecks_house"
    )
end

-- "Quest - Ratskullz crew"
function can_access_graffiti()
    local ratskullz_regions = {
        "logcity_clock_tower",
        "logcity_crosswalk",
        "logcity_outside_fashion_show",
        "logcity_skate_park",
        "logcity_ratskullz_alley",
        "logcity_overpass",
        "logcity_outside_cafe",
        "logcity_outside_gallery",
        "logcity_outside_gallery",
        "logcity_bus_stop",
    }
    local num_reachable = 0
    for _, region in ipairs(ratskullz_regions) do
        if can_reach(region) == AccessibilityLevel.Normal then
            num_reachable = num_reachable + 1
        end
    end
    return num_reachable >= 5
end

-- "Quest - A design problem"
function has_fashion()
    return ANY(
        ANY("fjallbjorn_hat", "cowboy_hat", "fishing_hat", "hard_hat", "pirate_hat", "paper_hat", "hotbean_hat", "puffer_hat"),
        ALL(
            "include_basto_on",
            ANY("sun_hat", "sun_cap", "beret", "royal_crown", "viking_helmet")
        )
    )
end

function has_warm_clothing()
    return ALL("climbing_boots", "puffer_hat", "scarf", "ski_goggles")
end

-- "Quest - Ancient paintings"
function can_access_all_ancient_paintings()
    return ALL(
        can_reach("kiiruberg_frozen_pond"),
        can_reach_any("kiiruberg_outside_observ_top","kiiruberg_outside_observ_bottom"),
        can_reach_any("kiiruberg_snowman_square_top","kiiruberg_snowman_square_bottom"),
        can_reach("mountain_top_toem")
    )
end

-- "Quest - Ice wizards research"
function can_access_all_cosmic_cubes()
    return can_reach_all(
        "kiiruberg_blizzard_bridge_right",
        "oaklaville_ghost_cup_game",
        "oaklaville_camp",
        "stanhamn_hippo_beach",
        "logcity_outside_fashion_show",
        "logcity_outside_gallery"
    )
end

-- "Quest - Listen to the goat choir"
function can_access_all_goats()
    return ALL(
        can_reach_any("kiiruberg_birthday_party_bottom", "kiiruberg_birthday_party_top"),
        ANY(
            can_reach_any("kiiruberg_cliffs_top", "kiiruberg_cliffs_middle"),
            ALL("climbing_boots", can_reach("kiiruberg_cliffs_bottom"))
        ),
        can_reach("kiiruberg_ski_mountain_top")
    )
end

-- Can reach a region with a hammock.
function can_make_night()
    return can_reach_any(
        "basto_lily_pad_pond_right",
        "basto_outside_castle",
        "basto_bonfire_top",
        "basto_ghost_hangout",
        "basto_jungle",
        "basto_tent"
    )
end

-- "Quest - Basto's hidden balloons"
function can_access_all_balloons()
    return can_reach_all(
        "basto_lily_pad_pond_left",
        "basto_lily_pad_pond_right",
        "basto_camp",
        "basto_outside_castle",
        "basto_bonfire_top",
        "basto_carnival",
        "basto_jungle",
        "basto_ghost_hangout",
        "basto_castle"
    )
end

-- "Item - Beret"
function can_access_all_portraits()
    return ALL(
	    "@Can Access/Achievement - Calmed down",
	    "@Can Access/Achievement - Just a sock",
	    "@Can Access/Achievement - A sparkling jump",
	    "@Can Access/Achievement - Flight ready",
	    "@Can Access/Achievement - 100 followers!",
	    "@Can Access/Achievement - A new job",
	    "@Can Access/Achievement - Happy youth",
	    "@Can Access/Achievement - A great story",
	    "@Can Access/Achievement - Kings new shirt",
	    "@Can Access/Achievement - Moonlit beauty"
    )
end

-- "Quest - Dry season"
function can_access_all_plants()
    return ALL(
        can_reach_all(
            "basto_camp",
            "basto_carnival",
            "basto_jungle",
            "basto_cave",
            "basto_ghost_hangout",
            "basto_castle",
            "basto_gym_house"
        ),
        ANY(
            can_reach("basto_bonfire_top"),
            can_reach("basto_bonfire_bottom")
        )
    )
end

-- "Quest - "Achievement - And some more"
function can_access_all_basto_animals()
    return ALL(
	    "@Can Access/Compendium - Bat",
	    "@Can Access/Compendium - Beach snake",
	    "@Can Access/Compendium - Beak bird",
	    "@Can Access/Compendium - Bitling frog",
	    "@Can Access/Compendium - Bitling mouse",
	    "@Can Access/Compendium - Bitling snail",
	    "@Can Access/Compendium - Bitling tato",
	    "@Can Access/Compendium - Coco crab",
	    "@Can Access/Compendium - Day lizard",
	    "@Can Access/Compendium - Drill mole",
	    "@Can Access/Compendium - Eggert",
	    "@Can Access/Compendium - Fire fly",
	    "@Can Access/Compendium - Glow worm",
	    "@Can Access/Compendium - Itsy bitsy",
	    "@Can Access/Compendium - Mud frog",
	    "@Can Access/Compendium - Night lizard",
	    "@Can Access/Compendium - Snout bug",
	    "@Can Access/Compendium - Tato coco",
	    "@Can Access/Compendium - Tato king",
	    "@Can Access/Compendium - Water strider"
    )
end

-- "Achievement - Look at those cuties"
function can_access_all_dev_animals()
    return ALL(
	    "@Can Access/Compendium - Oskar",
	    "@Can Access/Compendium - Sero",
	    "@Can Access/Compendium - Pet rock",
	    "@Can Access/Compendium - Fia",
	    "@Can Access/Compendium - Fräs",
	    "@Can Access/Compendium - Willemijn",
	    "@Can Access/Compendium - Portillo",
	    "@Can Access/Compendium - Mikée",
	    "@Can Access/Compendium - Nariko",
	    "@Can Access/Compendium - Teddy"
    )
end

-- "Achievement - Collect them all"
function can_access_all_base_animals()
    return ALL(
	    "@Can Access/Compendium - Cow",
	    "@Can Access/Compendium - Flies",
	    "@Can Access/Compendium - Home bird",
	    "@Can Access/Compendium - Tato",
	    "@Can Access/Compendium - Ant",
	    "@Can Access/Compendium - Beehive",
	    "@Can Access/Compendium - Butterfly",
	    "@Can Access/Compendium - Oskar",
	    "@Can Access/Compendium - Sero",
	    "@Can Access/Compendium - Forest bird",
	    "@Can Access/Compendium - Ladybug",
	    "@Can Access/Compendium - Tom",
	    "@Can Access/Compendium - Nestworm",
	    "@Can Access/Compendium - Pet rock",
	    "@Can Access/Compendium - Snail",
	    "@Can Access/Compendium - Squirrel",
	    "@Can Access/Compendium - Stag beetle",
	    "@Can Access/Compendium - Tato bug",
	    "@Can Access/Compendium - Tato fly",
	    "@Can Access/Compendium - Bubble fly",
	    "@Can Access/Compendium - Fia",
	    "@Can Access/Compendium - Fräs",
	    "@Can Access/Compendium - Willemijn",
	    "@Can Access/Compendium - Crab",
	    "@Can Access/Compendium - Dragonfly",
	    "@Can Access/Compendium - Happy carp",
	    "@Can Access/Compendium - Jellyfish",
	    "@Can Access/Compendium - King fish",
	    "@Can Access/Compendium - Seagull",
	    "@Can Access/Compendium - Seahorse",
	    "@Can Access/Compendium - Sunday swan",
	    "@Can Access/Compendium - Tato scuba",
	    "@Can Access/Compendium - Tato swim",
	    "@Can Access/Compendium - Toad",
	    "@Can Access/Compendium - Business pigeon",
	    "@Can Access/Compendium - Portillo",
	    "@Can Access/Compendium - Mouse",
	    "@Can Access/Compendium - Pigeon",
	    "@Can Access/Compendium - Punky parrot",
	    "@Can Access/Compendium - Tato skateboard",
	    "@Can Access/Compendium - Tato tourist",
	    "@Can Access/Compendium - Turtle",
	    "@Can Access/Compendium - Mikée",
	    "@Can Access/Compendium - Nariko",
	    "@Can Access/Compendium - Cosmo deer",
	    "@Can Access/Compendium - Teddy",
	    "@Can Access/Compendium - Fluff ball",
	    "@Can Access/Compendium - Hedgehog",
	    "@Can Access/Compendium - Meteopal",
	    "@Can Access/Compendium - Mountain goat",
	    "@Can Access/Compendium - Owl",
	    "@Can Access/Compendium - Snow bird",
	    "@Can Access/Compendium - Tato alien",
	    "@Can Access/Compendium - Tato ski"
    )
end

-- "Achievement - Cosplayer"
function has_all_clothing()
    return ALL(
        "clogs",
        "finger",
        "ghost_glasses",
        "soaked_sock",
        "fjallbjorn_hat",
        "cowboy_hat",
        "fishing_hat",
        "umbrella",
        "hard_hat",
        "diving_helmet",
        "pirate_hat",
        "paper_hat",
        "rubber_boots",
        "hotbean_hat",
        "reporter_hat",
        "sneakers",
        "climbing_boots",
        "scarf",
        "puffer_hat",
        "ski_goggles",
        "monster_mask",
        "flag",
        "space_helmet"
    )
end

-- "Achievement - A true completionist"
function can_access_all_base_quests()
    return ALL(
	    "@Can Access/Quest - Take a photo of Nana!",
	    "@Can Access/Quest - A hidden gift",
	    "@Can Access/Quest - Experience TOEM",
	    "@Can Access/Achievement - Strong as an oak",
	    "@Can Access/Achievement - Seaworthy",
	    "@Can Access/Achievement - Business executed",
	    "@Can Access/Achievement - Ice fighter"
    )
end