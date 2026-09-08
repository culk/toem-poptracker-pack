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
    clogs = "@Can Access/Item - Clogs",
    finger = "@Can Access/Item - Foam finger",
    tripod = "@Can Access/Item - Tripod",
    cowboy_hat = "@Can Access/Item - Cowboy hat",
    wet_socks = "@Can Access/Item - Pair of wet socks",
    fjallbjorn_hat = "@Can Access/Item - Fjällbjörn hat",
    ghost_glasses = "@Can Access/Item - Ghost glasses",
    soaked_sock = "@Can Access/Item - Soaked sock",
    monster_mask = "@Can Access/Item - Monster mask",
    frames_filters = "@Can Access/Item - Frames & filters",
    fishing_hat = "@Can Access/Item - Fishing hat",
    honk_attachment = "@Can Access/Item - Honk attachment",
    umbrella = "@Can Access/Item - Umbrella",
    old_key = "@Can Access/Item - Old key",
    hard_hat = "@Can Access/Item - Hard hat",
    diving_helmet = "@Can Access/Item - Diving helmet",
    rubber_boots = "@Can Access/Item - Rubber boots",
    sandwich = "@Can Access/Item - Supreme deluxe sandwich",
    pirate_hat = "@Can Access/Item - Pirate hat",
    paper_hat = "@Can Access/Item - Paper hat",
    flag = "@Can Access/Item - Photo challenger flag",
    hotbean_hat = "@Can Access/Item - Hotbean hat",
    reporter_hat = "@Can Access/Item - Reporter hat",
    sneakers = "@Can Access/Item - Sneakers",
    cinnamon_bun = "@Can Access/Item - Cinnamon bun",
    frisbee = "@Can Access/Item - Frisbee",
    climbing_boots = "@Can Access/Item - Climbing boots",
    puffer_hat = "@Can Access/Item - Puffer hat",
    scarf = "@Can Access/Item - Scarf",
    ski_goggles = "@Can Access/Item - Ski goggles",
    space_helmet = "@Can Access/Item - Space helmet",
    basto_ticket = "@Can Access/Item - Viking Express Ticket",
    watergun = "@Can Access/Item - Water popper attachment",
    sun_hat = "@Can Access/Item - Sun hat",
    melonear = "@Can Access/Item - Melonear",
    banakin = "@Can Access/Item - Banakin",
    oranganas = "@Can Access/Item - Oranganas",
    beanut = "@Can Access/Item - Beanut",
    pickaxe = "@Can Access/Item - Pickaxe",
    sun_cap = "@Can Access/Item - Sun cap",
    flip_flops = "@Can Access/Item - Flip-flops",
    ice_cream = "@Can Access/Item - Ice cream (Banakin)",
    royal_cape = "@Can Access/Item - Royal cape",
    minigame_ticket = "@Can Access/Item - Minigame ticket",
    vacation_shirt = "@Can Access/Item - Vacation shirt",
    empty_bottle = "@Can Access/Item - Empty bottle",
    viking_helmet = "@Can Access/Item - Viking helmet",
    beret = "@Can Access/Item - Beret",
    royal_crown = "@Can Access/Item - Royal crown",
}

function HAS(item, amount_required)
    if Tracker:FindObjectForCode("include_cassettes").CurrentStage == 0 and item == "fishermans_whistle_tape" then
        -- Cassette not randomized, check accessibility for vanilla location.
        return Tracker:FindObjectForCode("@Can Access/Cassette - Fisherman's Whistle").AccessibilityLevel
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