require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")
require("scripts/autotracking/setting_mapping")
require("scripts/autotracking/connection_mapping")

CUR_INDEX = -1

ALL_LOCATIONS = {}
SLOT_DATA = {}

ENTRANCE_INDEX = 1
FOUND_REGIONS = {}
TRANSITIONS = {}

if Highlight then
    HIGHLIGHT_LEVEL= {
        [0] = Highlight.Unspecified,
        [10] = Highlight.NoPriority,
        [20] = Highlight.Avoid,
        [30] = Highlight.Priority,
        [40] = Highlight.None,
        [100] = Highlight.Unspecified, -- Filler
        [101] = Highlight.Priority,    -- Progression
        [102] = Highlight.NoPriority,  -- Useful
        [103] = Highlight.Priority,    -- Prog + Useful
        [104] = Highlight.Avoid,       -- Trap
        [105] = Highlight.Priority,    -- Prog + Trap
        [106] = Highlight.NoPriority,  -- Useful + Trap
        [107] = Highlight.Priority,    -- Prog + Useful + Trap
    }
end

---Returns a pretty-printable representation of the provided table.
---@param o table
---@param depth? integer
---@return string
function DumpTable(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('  '):rep(depth)
        local tabs2 = ('  '):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. DumpTable(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

---Returns whether an item is a value in the provided table.
---@param item any
---@param o table
---@return boolean
function IsInTable(item, o)
    for _, value in ipairs(o) do
        if item == value then
            return true
        end
    end
    return false
end

---Function that gets called when the pack connects to an AP server.
---@param slot_data? table Slot data from the AP server for the specific user/slot.
function OnClear(slot_data)
    SLOT_DATA = slot_data or {}
    print(string.format("onClear: Reading slot data:\n%s", DumpTable(SLOT_DATA)))
    CUR_INDEX = -1

    -- Reset locations.
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local location_obj = Tracker:FindObjectForCode(location)
                if location_obj then
                    if location:sub(1, 1) == "@" then
                        location_obj.AvailableChestCount = location_obj.ChestCount
                        if Highlight then
                            location_obj.Highlight = Highlight.None
                        end
                    else
                        location_obj.Active = false
                    end
                else
                    print(string.format("onClear: could not find location for code %s", location))
                end
            end
        end
    end

    -- Reset items.
    for _, item_array in pairs(ITEM_MAPPING) do
        for _, item_pair in pairs(item_array) do
            item_code = item_pair[1]
            item_type = item_pair[2]
            local item_obj = Tracker:FindObjectForCode(item_code)
            if item_obj then
                if item_obj.Type == "toggle" then
                    item_obj.Active = false
                elseif item_obj.Type == "progressive" then
                    item_obj.CurrentStage = 0
                elseif item_obj.Type == "consumable" then
                    if item_obj.MinCount then
                        item_obj.AcquiredCount = item_obj.MinCount
                    else
                        item_obj.AcquiredCount = 0
                    end
                elseif item_obj.Type == "progressive_toggle" then
                    item_obj.CurrentStage = 0
                    item_obj.Active = false
                end
            else
                print(string.format("onClear: could not find item for code %s", item_code))
            end
        end
    end

    -- Read settings from slot data.
    for key, value in pairs(SLOT_DATA) do
        if key == "options" then
            for option_key, option_value in pairs(value) do
                if SETTING_MAPPING[option_key] then
                    local setting_obj = Tracker:FindObjectForCode(SETTING_MAPPING[option_key].code)
                    if setting_obj then
                        if setting_obj.Type == "toggle" then
                            setting_obj.Active = SETTING_MAPPING[option_key].mapping[option_value] --[[@as boolean]]
                        elseif setting_obj.Type == "consumable" then
                            setting_obj.AcquiredCount = option_value
                        elseif setting_obj.Type == "progressive" then
                            setting_obj.CurrentStage = SETTING_MAPPING[option_key].mapping[option_value] --[[@as integer]]
                        end
                    else
                        print(string.format("onClear: could not find setting for code %s", SETTING_MAPPING[option_key].code))
                    end
                end
            end
        end
        if key == "transitions" then
            ENTRANCE_INDEX = 1
            FOUND_REGIONS = {}
            TRANSITIONS = value
        end
        -- TODO: also cap out stamp number to required number
    end

    -- Subscribe to data storage changes.
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    if Archipelago.PlayerNumber > -1 then
        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        CLIENT_STATUS_ID = "_read_client_status_"..TEAM_NUMBER.."_"..PLAYER_ID
        FOUND_ENTRANCES_ID = "Slot:"..PLAYER_ID..":TraversedEntrances"
        Archipelago:SetNotify({HINTS_ID, CLIENT_STATUS_ID, FOUND_ENTRANCES_ID})
        Archipelago:Get({HINTS_ID, CLIENT_STATUS_ID, FOUND_ENTRANCES_ID})
    end
end

---Handler called when an item is sent to the connected slot.
---@param index integer for the items the connected slot has received so far.
---@param item_id integer of the received item, matching the game's datapackage ID.
---@param item_name string from the datapackage for the given item ID.
---@param player_number integer slot number of the player who sent the item.
function OnItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        return
    end
    for _, item_pair in pairs(item) do
        local item_code = item_pair[1]
        local item_type = item_pair[2]
        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            if item_obj.Type == "toggle" then
                item_obj.Active = true
            elseif item_obj.Type == "progressive" then
                if item_obj.Active == true then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            elseif item_obj.Type == "consumable" then
                item_obj.AcquiredCount = item_obj.AcquiredCount + item_obj.Increment
            elseif item_obj.Type == "progressive_toggle" then
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            end
        else
            print(string.format("OnItem: could not find object for code %s", item_code))
        end
    end
end

---Handler called when a location is cleared.
---@param location_id integer of the cleared location from the datapackage.
---@param location_name string of the cleared location from the datapackage.
function OnLocation(location_id, location_name)
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("OnLocation: could not find location mapping for id %s", location_id))
        return
    end

    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        if location_obj then
            if location:sub(1, 1) == "@" then
                (location_obj --[[@as LocationSection]]).AvailableChestCount = location_obj.AvailableChestCount - 1
            else
                (location_obj --[[@as JsonItem]]).Active = true
            end
        else
            print(string.format("OnLocation: could not find location_object for code %s", location))
        end
    end
end

--Update location logic calculations by toggling a hidden item's state.
function ForceUpdate()
    local update = Tracker:FindObjectForCode("update")
    if update == nil then
        return
    end
    update.Active = not update.Active
end

---@class APHintMessage
---@field receiving_player integer
---@field finding_player integer
---@field location integer
---@field item integer
---@field found boolean
---@field entrance string
---@field item_flags 0|1|2|3|4|5|6|7
---@field status 0|10|20|30|40

---Handler called when AP sends live updates from the server using a given key subscribed to in Archipelago:SetNotify.
---@param key string that was used to send the message.
---@param value table<integer, APHintMessage, table<integer>>
---@param old_value table<integer, APHintMessage, table<integer>>
function OnNotify(key, value, old_value)
    if value ~= old_value and key == HINTS_ID then
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
    elseif key == CLIENT_STATUS_ID then
        UpdateStatus(value --[[@as integer]])
    elseif key == FOUND_ENTRANCES_ID then
        UpdateConnections(value --[[@as table<integer>]])
    end
end

---Handler called when connecting to AP after providing a given key in Archipelago:Get.
---@param key string that was used to send the message.
---@param value table<integer, APHintMessage>
function OnNotifyLaunch(key, value)
    if key == HINTS_ID then
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
    elseif key == CLIENT_STATUS_ID then
        UpdateStatus(value --[[@as integer]])
    elseif key == FOUND_ENTRANCES_ID then
        UpdateConnections(value --[[@as table<integer>]])
    end
end

---Updates the Highlight of a LocationSection to represent the status of the hint.
---@param locationID integer of the location that was hinted.
---@param status 0|10|20|30|40|100|101|102|103|104|105|106|107 to determine the color of the hint glow.
function UpdateHints(locationID, status) -->
    if Highlight then
        local location_table = LOCATION_MAPPING[locationID]
        for _, location in ipairs(location_table) do
            if location:sub(1, 1) == "@" then
                local obj = Tracker:FindObjectForCode(location)

                if obj then
                    obj.Highlight = HIGHLIGHT_LEVEL[status]
                else
                    print(string.format("UpdateHints: No object found for code: %s", location))
                end
            end
        end
    end
end

---Updates the goal location if the player has goaled.
---@param status 0|10|20|30|40 of the  player's slot.
function UpdateStatus(status)
    if status == Archipelago.ClientStatus.GOAL then
        print("UpdateStatus: goal achieved")
        --OnLocation(10000, "Goal")
    end
end

---Updates the entrances found by the player.
---@param found_entrances table<integer>
function UpdateConnections(found_entrances)
    for i=ENTRANCE_INDEX,#found_entrances do
        -- TODO: clean up logging and variable names after confirming things work.
        local transition = TRANSITIONS[tostring(found_entrances[i])]
        local connection = CONNECTION_MAPPING[transition]
        print(string.format("UpdateConnections: Found entrance id %d replaced with transition %d: %s -> %s", found_entrances[i], transition, connection[1], connection[2]))
        FOUND_REGIONS[connection[1]] = true
        -- TODO: what about excluded connections? How to add their destinations?
    end
    ENTRANCE_INDEX = #found_entrances + 1

    -- Update all location logic to include new found regions.
    ForceUpdate()
end