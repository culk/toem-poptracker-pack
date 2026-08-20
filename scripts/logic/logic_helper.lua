local access_for_bool = {
    [true] = AccessibilityLevel.Normal,
    [false] = AccessibilityLevel.None
}

function ALL(...)
    local args = { ... }
    local min = AccessibilityLevel.Normal
    for _, v in ipairs(args) do
        if type(v) == "function" then
            v = v()
        elseif type(v) == "string" then
            if v:sub(1, 1) == "@" then
                v = Tracker:FindObjectForCode(v).AccessibilityLevel
            else
                v = HAS(v)
            end
        end
        if type(v) == "boolean" then
            v = access_for_bool[v]
        end
        if v == AccessibilityLevel.None then
            return AccessibilityLevel.None
        elseif v < min then
            min = v
        end
    end
    return min
end

function ANY(...)
    local args = { ... }
    local max = AccessibilityLevel.None
    for _, v in ipairs(args) do
        if type(v) == "function" then
            v = v()
        elseif type(v) == "string" then
            if v:sub(1, 1) == "@" then
                v = Tracker:FindObjectForCode(v).AccessibilityLevel
            else
                v = HAS(v)
            end
        end
        if type(v) == "boolean" then
            v = access_for_bool[v]
        end
        if v == AccessibilityLevel.Normal then
            return AccessibilityLevel.Normal
        elseif v > max then
            max = v
        end
    end
    return max
end

-- Vanilla location for items used for logic when items are not randomized.
local location_by_item = {
    clogs = "@Homelanda/Bus Stop/Item - Clogs/",
    finger = "@Oaklaville/Outside Hotel/Item - Foam finger/",
    tripod = "@Start Menu/Item - Tripod/",
    cowboy_hat = "@Oaklaville/Mushroom House/Item - Cowboy hat",
    wet_socks = "@Oaklaville/Ghost Cup Game/Item - Pair of wet socks",
    fjallbjorn_hat = "@Oaklaville/Camp/Scout Leader/Item - Fjällbjörn hat",
    ghost_glasses = "@Oaklaville/Skeleton/Item - Ghost glasses",
    soaked_sock = "@Oaklaville/Outside Hotel/Sock Man/Item - Soaked sock",
    monster_mask = "@Oaklaville/Hotel/Item - Monster mask",
    frames_filters = "@Stanhamn/Photo Guild Hut/Item - Frames & filters",
    fishing_hat = "@Stanhamn/Lighthouse/Item - Fishing hat/",
    honk_attachment = "@Stanhamn/Lighthouse Roof/Item - Honk attachment",
    umbrella = "@Stanhamn/King Fish Beach/Item - Umbrella/",
    old_key = "@Stanhamn/Pirate Drawbridge/Pirate/Item - Old key",
    hard_hat = "@Stanhamn/Hydroplant/Item - Hard hat",
    diving_helmet = "@Stanhamn/Fishing Tower/Item - Diving helmet/",
    rubber_boots = "@Stanhamn/Docks Right/Item - Rubber boots/",
    sandwich = "@Stanhamn/Pirate Drawbridge/Item - Supreme deluxe sandwich/",
    pirate_hat = "@Stanhamn/Underwater/Item - Pirate hat",
    paper_hat = "@Stanhamn/Pirate Drawbridge/Pirate/Item - Paper hat",
    flag = "@Stanhamn/Photo Guild Hut/Item - Photo challenger flag",
    hotbean_hat = "@Logcity/Clock Tower/Hotbean Stand/Item - Hotbean hat",
    reporter_hat = "@Logcity/News House/Item - Reporter hat",
    sneakers = "@Logcity/Outside Fashion Show/Item - Sneakers/",
    cinnamon_bun = "@Logcity/Cafe/Item - Cinnamon bun",
    frisbee = "@Logcity/Crosswalk/Item - Frisbee/",
    climbing_boots = "@Kiiruberg/Frozen Pond/Old Man/Item - Climbing boots",
    puffer_hat = "@Kiiruberg/Frozen Pond/Old Man/Item - Puffer hat",
    scarf = "@Kiiruberg/Ski Lodge/Item - Scarf",
    ski_goggles = "@Kiiruberg/Ski Mountain Top/Item - Ski goggles/",
    space_helmet = "@Kiiruberg/Outside Observatory Bottom/Item - Space helmet",
    basto_ticket = "@Homelanda/Living Room/Item - Viking Express Ticket",
    watergun = "@Basto/Bus Stop Bottom/Information Booth/Item - Water popper attachment",
    sun_hat = "@Basto/Tent/Item - Sun hat",
    melonear = "@Basto/Lily Pad Pond Right/Item - Melonear",
    banakin = "@Basto/Outside Castle/Item - Banakin/",
    oranganas = "@Basto/Bonfire Top/Item - Oranganas/",
    beanut = "@Basto/Camp/Item - Beanut/",
    pickaxe = "@Basto/Bonfire Top/Arthur/Item - Pickaxe",
    sun_cap = "@Basto/Cave/Item - Sun cap/",
    flip_flops = "@Basto/Ghost Hangout/Item - Flip-flops/",
    ice_cream = "@Basto/Outside Castle/Ice Cream Vendor/Item - Ice cream (Banakin)",
    royal_cape = "@Basto/Castle/Item - Royal cape",
    minigame_ticket = "@Basto/Carnival/Item - Minigame ticket",
    vacation_shirt = "@Basto/Carnival/Item - Vacation shirt",
    empty_bottle = "@Basto/Ghost Hangout/Item - Empty bottle/",
    viking_helmet = "@Basto/Bonfire Top/Viking/Item - Viking helmet",
    beret = "@Basto/Outside Castle/Painter/Item - Beret",
    royal_crown = "@Basto/Castle/Item - Royal crown",
}

function HAS(item, amount_required)
    if Tracker:FindObjectForCode("include_cassettes").CurrentStage == 0 and item == "fishermans_whistle_tape" then
        -- Cassette not randomized, check accessibility for vanilla location.
        return Tracker:FindObjectForCode("@Stanhamn/Snowman/Cassette - Fisherman's Whistle").AccessibilityLevel
    elseif Tracker:FindObjectForCode("include_items").CurrentStage == 0 and location_by_item[item] then
        -- Item not randomized, check accessibility for the item's vanilla location instead.
        local location = location_by_item[item]
        return Tracker:FindObjectForCode(location).AccessibilityLevel
    end

    -- Item is randomized, check for item.
    local count = Tracker:ProviderCountForCode(item)
    if not amount_required and count > 0 then
        return AccessibilityLevel.Normal
    elseif amount_required and count >= amount_required then
        return AccessibilityLevel.Normal
    end
    return AccessibilityLevel.None
end