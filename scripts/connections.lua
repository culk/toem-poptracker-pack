require("scripts/autotracking/connection_mapping")

---@class Connection
Connection = {}
Connection.__index = Connection

---Creates a new Connection object
---@param name string
---@param icon string
---@return table
function Connection.New(name, icon)
    ---@class Connection
    local o = setmetatable({}, Connection)
    o.Name = name
    o.LocationRef = "@Connections/" .. name
    o.Icon = icon
    ---@type string
    o.DestinationName = nil
    ---@type Connection
    o.Destination = nil
    return o
end

---Returns whether the connection is selected.
---@return boolean
function Connection:IsSelected()
    return Connection.SelectedConnection == self
end

---Update img_mods to indicate the new connection is currently selected.
---@param connection Connection?
function Connection.Select(connection)
    local previous_selected = Connection.SelectedConnection
    Connection.SelectedConnection = connection

    if previous_selected then
        previous_selected:UpdateIconMods()
    end

    if connection then
        connection:UpdateIconMods()
    end
end

---Connects the connection to the destination, deselects both, and updates their appearance and location information.
---@param destination Connection?
function Connection:Assign(destination)
    is_randomized = is_randomized or false
    local previous_destination = self.Destination
    self.Destination = destination
    local new_destination_name = "nil"
    if destination then
        new_destination_name = destination.Name
        destination.Destination = self
        destination.DestinationName = self.Name
        self.DestinationName = new_destination_name
    else
        self.DestinationName = nil
    end
    if previous_destination and previous_destination ~= destination then
        previous_destination.Destination = nil
        previous_destination.DestinationName = nil
    end
    print(string.format("Connection.Assign: Connecting '%s' to '%s'", self.Name, new_destination_name))

    Connection.Select(nil)

    self:UpdateItem()
    if destination then
        destination:UpdateItem()
    end
    if previous_destination and previous_destination ~= destination then
        previous_destination:UpdateItem()
    end
end

---Returns the LuaItem for the connection.
---@return LuaItem?
function Connection:GetItem()
    return Tracker:FindObjectForCode(self.Name) --[[@as LuaItem]]
end

---Updates the LuaItem's state to save Level assignment information.
---@param item LuaItem?
function Connection:UpdateItemState(item)
    item = item or self:GetItem()
    if not item then
        return
    end

    -- Update item state with the destination name so that loading a saved pack state preserves assignments.
    item.ItemState.DestinationName = self.DestinationName
end

---Returns the img_mods to apply to the connection's hosted LuaItem to indicate if it is selected or assigned a destination.
---@return string
function Connection:GetIconMods()
    if self.Destination then
        if self:IsSelected() then
            return "@disabled,overlay|images/items/overlay_cursor.png"
        else
            return "@disabled"
        end
    else
        if self:IsSelected() then
            return "brightness|1.5,overlay|images/items/overlay_cursor.png"
        else
            return "none"
        end
    end
end

---Updates the img_mods for the connection's hosted LuaItem.
---@param item LuaItem?
function Connection:UpdateIconMods(item)
    item = item or self:GetItem()
    if not item then
        return
    end
    local new_icon_mods = self:GetIconMods()
    if item.IconMods ~= new_icon_mods then
        item.IconMods = new_icon_mods
    end
end

---Updates the name and text overlay for the connection's hosted LuaItem.
---@param item LuaItem?
function Connection:UpdateNameAndOverlay(item)
    item = item or self:GetItem()
    if not item then
        return
    end
    local destination = self.Destination
    local new_name
    local new_text_overlay
    if destination then
        new_name = self.Name .. " -> " .. destination.Name
        new_text_overlay = "to " .. destination.Name
    else
        new_name = "Left click to assign " .. self.Name .. " to a destination"
        new_text_overlay = ""
    end
    item:SetOverlay(new_text_overlay)
end

---Updates the visual parts of the exit's hosted LuaItem including its name, icon and text overlay.
---@param item LuaItem?
function Connection:UpdateItem(item)
    item = item or self:GetItem()
    self:UpdateItemState(item)
    self:UpdateIconMods(item)
    self:UpdateNameAndOverlay(item)
end

CONNECTION_BY_NAME = {}
CONNECTIONS_BY_REGION = {}
for _, connection_info in ipairs(CONNECTION_MAPPING) do
    -- Create the connection.
    local name = connection_info[1]
    CONNECTION_BY_NAME[name] = Connection.New(name, "images/items/connection.png")

    -- Add connection to mapping by region name for its source region. This is used to lookup possible entrances for region access logic.
    local region = connection_info[2]
    if CONNECTIONS_BY_REGION[region] == nil then
        CONNECTIONS_BY_REGION[region] = {}
    end
    table.insert(CONNECTIONS_BY_REGION[region], name)
end