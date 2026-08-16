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

function HAS(item, amount_required)
    local count = Tracker:ProviderCountForCode(item)
    if not amount_required and count > 0 then
        return AccessibilityLevel.Normal
    elseif amount_required and count >= amount_required then
        return AccessibilityLevel.Normal
    end
    return AccessibilityLevel.None
end