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
    if Tracker:FindObjectForCode("entrance_randomization").CurrentStage == 1 and FOUND_REGIONS[region_name] then
        return AccessibilityLevel.Normal
    end

    -- Otherwise, default logic required for each region that has restricted access.
    if region_name == "oaklaville_bus_stop" then
        return ALL(has_required_stamps_for("homelanda"))
    elseif region_name == "stanhamn_bus_stop" then
        return ALL(has_required_stamps_for("oaklaville"), can_reach("oaklaville_bus_stop"))
    elseif region_name == "logcity_bus_stop" then
        return ALL(has_required_stamps_for("stanhamn"), can_reach("stanhamn_bus_stop"))
    elseif region_name == "kiiruberg_bus_stop" then
        return ALL(has_required_stamps_for("logcity"), can_reach("logcity_bus_stop"))
    elseif region_name == "oaklaville_rave" then
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
        return ALL(has_warm_clothing(), "honk_attachment")
    elseif region_name == "kiiruberg_cosmo_garden" then
        return ALL("@Kiiruberg/Wizard Tower/Quest - Ice wizards research")
    elseif region_name == "kiiruberg_man_cave" then
        return ALL("@Mountain Top/Achievement - Experience TOEM/")
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
            HAS("tripod"),
            ANY("honk_attachment", AccessibilityLevel.SequenceBreak),
            can_reach_all(
                "oaklaville_playground",
                "stanhamn_hippo_beach",
                "logcity_skate_park",
                "kiiruberg_blizzard_monster"
            )
        )
    )
end

function can_access_all_quests(level_name)
    local quests_by_level = {
        oaklaville = {
	        "@Oaklaville/Trail Bottom/Quest - Suspicious activity - forest/",
	        "@Oaklaville/Hotel/Quest - Monster spotting",
	        "@Oaklaville/Outside Hotel/Sock Man/Quest - Missing socks",
	        "@Oaklaville/Camp/Scout Leader/Quest - Become a scout",
	        "@Oaklaville/Hide and Seek/Quest - Hide-and-seek/",
	        "@Oaklaville/Trail Bottom/Quest - Log blocking a path/",
	        "@Oaklaville/Trail Bottom/Quest - Photo challenge #1/",
	        "@Oaklaville/Outside Hotel/Quest - Photo challenge #2/",
	        "@Oaklaville/Rave/Quest - Become a paparazzi/",
	        "@Oaklaville/Hotel/Quest - Capture the hotels beauty",
	        "@Oaklaville/Hotel/Quest - Hotel chef",
	        "@Oaklaville/Graveyard/Quest - A courageous stallion",
	        "@Oaklaville/Skeleton House/Quest - Ghost helper!/",
	        "@Oaklaville/Ghost Cup Game/Quest - Cup champion",
	        "@Oaklaville/Playground/Quest - Become a flower/",
        },
        stanhamn = {
	        "@Stanhamn/Bus Stop/Quest - The king of fishes/",
	        "@Stanhamn/Hippo Beach/Quest - A good spot with no sun/",
	        "@Stanhamn/Ghost Drawbridge Bottom/Quest - Suspicious activity - harbor/",
	        "@Stanhamn/Pirate Drawbridge/Pirate/Quest - Queen of paper hats",
	        "@Stanhamn/Pirate Drawbridge/Quest - Photo challenge #3/",
	        "@Stanhamn/Ghost Drawbridge Top/Quest - Photo challenge #4/",
	        "@Stanhamn/Photo Guild Hut/Quest - Frames & filters!",
	        "@Stanhamn/Outside Hydroplant/Quest - Make someone take a bath/",
	        "@Stanhamn/Docks Right/Quest - A lost dog/",
	        "@Stanhamn/Hydroplant/Quest - Power shortage!",
	        "@Stanhamn/Lighthouse Roof/Quest - Solve the chaos",
	        "@Stanhamn/Ghost Drawbridge Bottom/Quest - Scorching flame/",
	        "@Stanhamn/Outside Hydroplant/Quest - Supreme deluxe sandwich!/",
	        "@Stanhamn/Fishing Tower/Quest - Ocean garbage/",
	        "@Stanhamn/Snowman/Quest - A whistling dilemma",
	        "@Stanhamn/King Fish Beach/Wizard/Quest - A layered melody",
        },
        logcity = {
	        "@Logcity/Outside Fashion Show/Quest - Suspicious activity - city/",
	        "@Logcity/Ratskullz Alley/Quest - Ratskullz crew",
	        "@Logcity/Clock Tower/Punk Rocker/Quest - Punk rocker bread crumbs",
	        "@Logcity/Overpass/Quest - Photo challenge #5/",
	        "@Logcity/Outside Gallery/Quest - Photo challenge #6/",
	        "@Logcity/News House/Quest - Press-ing news",
	        "@Logcity/Outside Gallery/Quest - Sewer stumble!/",
	        "@Logcity/Clock Tower/Hotbean Stand/Quest - Super Hotbean Bros.",
	        "@Logcity/Clock Tower/Quest - Hang in there, buddy/",
	        "@Logcity/Crosswalk/Quest - Spooky scary city/",
	        "@Logcity/Outside Fashion Show/Quest - A ghostly date/",
	        "@Logcity/Gallery/Quest - Art exhibition/",
	        "@Logcity/Clock Tower/Influencer/Quest - Young and inspiring!",
	        "@Logcity/Fashion Show Backstage/Quest - A design problem",
	        "@Logcity/Bus Stop Cleaner/Quest - Cleaning away the stress",
	        "@Logcity/Outside Fashion Show/Quest - Always tumbled granny/",
	        "@Logcity/Cafe/Quest - A mouse bakery",
	        "@Logcity/Outside Cafe/Quest - A thieving crow/",
        },
        kiiruberg = {
	        "@Kiiruberg/Cliffs Middle/Quest - Yeti cuteness/",
	        "@Kiiruberg/Wizard Tower/Quest - Ice wizards research",
	        "@Kiiruberg/Military Base/Quest - Military suspicions",
	        "@Kiiruberg/Observatory/Quest - Play astronaut",
	        "@Kiiruberg/Snowman Square Bottom/Quest - Photo challenge #7/",
	        "@Kiiruberg/Cliffs Top/Quest - Photo challenge #8",
	        "@Kiiruberg/Observatory/Quest - Locating an asteroid",
	        "@Kiiruberg/Frozen Pond/Quest - Listen to the goat choir/",
	        "@Kiiruberg/Frozen Pond/Old Man/Quest - Snowball memories",
	        "@Kiiruberg/Birthday Party Bottom/Quest - Birthday in distress",
	        "@Kiiruberg/Cliffs Middle/Scientist/Quest - Ancient paintings",
	        "@Kiiruberg/Ski Lift Base/Quest - Become a yeti/",
	        "@Kiiruberg/Snowman Square Bottom/Quest - Assemble a snowman/",
        },
        basto = {
	        "@Basto/Bus Stop Bottom/Information Booth/Quest - Bastos hidden balloons",
	        "@Basto/Bonfire Top/Arthur/Quest - Arthur hunter",
	        "@Basto/Bad Hair Day/Quest - Bad hair day",
	        "@Basto/Tent/Quest - Take a nap!",
	        "@Basto/Bonfire Top/Quest - Spooky stories/",
	        "@Basto/Outside Castle/Painter/Quest - Painterly portrait",
	        "@Basto/Bonfire Top/Quest - Night-time cinema/",
	        "@Basto/Bonfire Top/Quest - Night lights/",
	        "@Basto/Lily Pad Pond Left/Quest - Jet-ski tricks/",
	        "@Basto/Outside Castle/Ice Cream Vendor/Quest - Fruit shortage",
	        "@Basto/Bonfire Top/Viking/Quest - Brain freeze",
	        "@Basto/Cave/Quest - Sweet tooth/",
	        "@Basto/Castle/Quest - In your face",
	        "@Basto/Lily Pad Pond Left/Injured Monkey/Quest - Broken dreams",
	        "@Basto/Lily Pad Pond Left/Quest - Dry season/",
	        "@Basto/Gym House/Quest - Dehydrated muscles",
	        "@Basto/Castle/Quest - Sand castle competition",
	        "@Basto/Carnival/Quest - Play a carnival game",
	        "@Basto/Cave/Quest - Book of bats/",
	        "@Basto/Jungle/Quest - Bitling collector/",
        },
    }
    return ALL(table.unpack(quests_by_level[level_name]))
end

-- "Item - Photo challenger flag"
function can_access_all_photo_challenges()
    return ALL(
        "@Oaklaville/Trail Bottom/Quest - Photo challenge #1/",
        "@Oaklaville/Outside Hotel/Quest - Photo challenge #2/",
        "@Stanhamn/Pirate Drawbridge/Quest - Photo challenge #3/",
        "@Stanhamn/Ghost Drawbridge Top/Quest - Photo challenge #4/",
        "@Logcity/Overpass/Quest - Photo challenge #5/",
        "@Logcity/Outside Gallery/Quest - Photo challenge #6/",
        "@Kiiruberg/Snowman Square Bottom/Quest - Photo challenge #7/",
        "@Kiiruberg/Cliffs Top/Quest - Photo challenge #8"
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
        can_reach_any("kiiruberg_cliffs_top", "kiiruberg_cliffs_middle"),
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

-- "Quest - Bastos hidden balloons"
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
	    "@Oaklaville/Skeleton/Achievement - Calmed down",
	    "@Oaklaville/Outside Hotel/Sock Man/Achievement - Just a sock",
	    "@Stanhamn/Bus Stop/Achievement - A sparkling jump/",
	    "@Stanhamn/Fishing Tower/Achievement - Flight ready/",
	    "@Logcity/Clock Tower/Influencer/Achievement - 100 followers!",
	    "@Logcity/Bus Stop Cleaner/Achievement - A new job",
	    "@Kiiruberg/Old Man's House/Achievement - Happy youth",
	    "@Kiiruberg/Cliffs Middle/Scientist/Achievement - A great story",
	    "@Basto/Castle/Achievement - Kings new shirt",
	    "@Basto/Bad Hair Day/Achievement - Moonlit beauty"
    )
end

-- "Quest - Dry season"
function can_access_all_plants()
    return ALL(
        ANY(
            can_reach("basto_bus_stop_bottom"),
            ALL(can_reach("basto_bus_stop_top"), "hard_logic")
        ),
        can_reach_all(
            "basto_camp",
            "basto_bonfire_top",
            "basto_carnival",
            "basto_jungle",
            "basto_cave",
            "basto_ghost_hangout",
            "basto_castle",
            "basto_gym_house"
        )
    )
end

-- "Quest - "Achievement - And some more"
function can_access_all_basto_animals()
    return ALL(
	    "@Basto/Bat/Compendium - Bat (Cave)/",
	    "@Basto/Camp/Compendium - Beach snake/",
	    "@Basto/Beak Bird/Compendium - Beak bird/",
	    "@Basto/Bonfire Bottom/Compendium - Bitling frog",
	    "@Basto/Castle/Compendium - Bitling mouse",
	    "@Basto/Jungle/Compendium - Bitling snail/",
	    "@Basto/Bitling Tato/Compendium - Bitling tato",
	    "@Basto/Jungle/Compendium - Coco crab/",
	    "@Basto/Bonfire Top/Compendium - Day lizard/",
	    "@Basto/Drill Mole/Compendium - Drill mole",
	    "@Basto/Bonfire Top/Compendium - Eggert/",
	    "@Basto/Ghost Hangout/Compendium - Fire fly/",
	    "@Basto/Cave/Compendium - Glow worm/",
	    "@Basto/Secret Cave/Compendium - Itsy bitsy",
	    "@Basto/Camp/Compendium - Mud frog/",
	    "@Basto/Night Lizard/Compendium - Night lizard",
	    "@Basto/Jungle/Compendium - Snout bug/",
	    "@Basto/Outside Castle/Compendium - Tato coco/",
	    "@Basto/Secret Cave/Compendium - Tato king",
	    "@Basto/Water Strider/Compendium - Water strider (Outside Castle)/"
    )
end

-- "Achievement - Look at those cuties"
function can_access_all_dev_animals()
    return ALL(
	    "@Oaklaville/Hotel/Compendium - Oskar",
	    "@Oaklaville/Sero/Compendium - Sero/",
	    "@Oaklaville/Camp/Compendium - Pet rock/",
	    "@Stanhamn/Fia/Compendium - Fia/",
	    "@Stanhamn/Fräs/Compendium - Fräs/",
	    "@Stanhamn/King Fish Beach/Compendium - Willemijn/",
	    "@Logcity/Outside Cafe/Compendium - Portillo/",
	    "@Kiiruberg/Balloon House/Compendium - Mikée",
	    "@Kiiruberg/Balloon House/Compendium - Nariko",
	    "@Kiiruberg/Mecks House/Compendium - Teddy"
    )
end

-- "Achievement - Collect them all"
function can_access_all_base_animals()
    return ALL(
	    "@Homelanda/Bus Stop/Compendium - Cow/",
	    "@Homelanda/Bus Stop/Compendium - Flies/",
	    "@Homelanda/Bus Stop/Compendium - Home bird/",
	    "@Homelanda/Bus Stop/Compendium - Tato/",
	    "@Oaklaville/Trail Bottom/Compendium - Ant/",
	    "@Oaklaville/Playground/Compendium - Beehive/",
	    "@Oaklaville/Bus Stop/Compendium - Butterfly/",
	    "@Oaklaville/Hotel/Compendium - Oskar",
	    "@Oaklaville/Sero/Compendium - Sero/",
	    "@Oaklaville/Outside Hotel/Compendium - Forest bird/",
	    "@Oaklaville/Camp/Compendium - Ladybug/",
	    "@Oaklaville/Outside Hotel/Compendium - Tom/",
	    "@Oaklaville/Outside Hotel/Compendium - Nestworm/",
	    "@Oaklaville/Camp/Compendium - Pet rock/",
	    "@Oaklaville/Outside Hotel/Snail/Compendium - Snail",
	    "@Oaklaville/Ghost Cup Game/Compendium - Squirrel (Ghost Cup Game)",
	    "@Oaklaville/Outside Hotel/Compendium - Stag beetle/",
	    "@Oaklaville/Mushroom House/Compendium - Tato bug",
	    "@Oaklaville/Tato Fly/Compendium - Tato fly/",
	    "@Stanhamn/Pirate Drawbridge/Compendium - Bubble fly/",
	    "@Stanhamn/Fia/Compendium - Fia/",
	    "@Stanhamn/Fräs/Compendium - Fräs/",
	    "@Stanhamn/King Fish Beach/Compendium - Willemijn/",
	    "@Stanhamn/Hippo Beach/Compendium - Crab/",
	    "@Stanhamn/Outside Hydroplant/Compendium - Dragonfly/",
	    "@Stanhamn/Underwater/Compendium - Happy carp",
	    "@Stanhamn/Underwater/Compendium - Jellyfish",
	    "@Stanhamn/King Fish Beach/Compendium - King fish/",
	    "@Stanhamn/Seagulls/Compendium - Seagull/",
	    "@Stanhamn/Underwater/Compendium - Seahorse",
	    "@Stanhamn/Sunday Swan/Compendium - Sunday swan/",
	    "@Stanhamn/Underwater/Compendium - Tato scuba",
	    "@Stanhamn/Bus Stop/Compendium - Tato swim/",
	    "@Stanhamn/Pirate Drawbridge/Compendium - Toad/",
	    "@Logcity/Outside Gallery/Compendium - Business pigeon/",
	    "@Logcity/Outside Cafe/Compendium - Portillo/",
	    "@Logcity/Overpass/Compendium - Mouse (Overpass)/",
	    "@Logcity/Pigeon/Compendium - Pigeon (Clock Tower)/",
	    "@Logcity/Clock Tower/Punk Rocker/Compendium - Punky parrot",
	    "@Logcity/Skate Park/Compendium - Tato skateboard/",
	    "@Logcity/Outside Fashion Show/Compendium - Tato tourist/",
	    "@Logcity/Crosswalk/Compendium - Turtle/",
	    "@Kiiruberg/Balloon House/Compendium - Mikée",
	    "@Kiiruberg/Balloon House/Compendium - Nariko",
	    "@Kiiruberg/Cosmo Garden/Compendium - Cosmo deer",
	    "@Kiiruberg/Mecks House/Compendium - Teddy",
	    "@Kiiruberg/Fluff/Compendium - Fluff ball",
	    "@Kiiruberg/Hedgehog/Compendium - Hedgehog",
	    "@Kiiruberg/Meteopal/Compendium - Meteopal",
	    "@Kiiruberg/Goat/Compendium - Mountain goat/",
	    "@Kiiruberg/Owl/Compendium - Owl",
	    "@Kiiruberg/Ski Lift Base/Compendium - Snow bird/",
	    "@Kiiruberg/Observatory/Compendium - Tato alien",
	    "@Kiiruberg/Ski Mountain Top/Compendium - Tato ski/"
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
function can_access_all_quests()
    return ALL(
	    "@Homelanda/Bus Stop/Quest - Take a photo of Nana!/",
	    "@Homelanda/Bus Stop/Quest - A hidden gift/",
	    "@Homelanda/Living Room/Quest - Experience TOEM",
	    "@Oaklaville/Oaklaville/Achievement - Strong as an oak",
	    "@Stanhamn/Stanhamn/Achievement - Seaworthy",
	    "@Logcity/Logcity/Achievement - Business executed",
	    "@Kiiruberg/Kiiruberg/Achievement - Ice fighter"
    )
end