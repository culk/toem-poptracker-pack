require("scripts/connections")

---Creates a LuaItem for the connection.
---@param connection Connection
---@return LuaItem
function CreateConnectionItem(connection)
    local connection_item = ScriptHost:CreateLuaItem()
    connection_item.Name = connection.Name
    connection_item.Icon = ImageReference:FromPackRelativePath(connection.Icon)
    connection_item.ItemState = {
        DestinationName = nil,
    }
    connection_item:SetOverlayAlign("left")

    connection_item.CanProvideCodeFunc = function(self, code)
        return code == self.Name
    end

    connection_item.ProvidesCodeFunc = function(self, code)
        if self:CanProvideCodeFunc(code) and connection.Destination then
            return true
        end
        return false
    end

    connection_item.OnLeftClickFunc = function(self)
        if connection.Destination then
            -- Already assigned a destination, assignment can be cleared with right click.
            return
        elseif connection:IsSelected() then
            -- Deselect the connection because it was left clicked twice.
            Connection.Select(nil)
        else
            local destination = Connection.SelectedConnection
            if destination then
                -- Assign the selected destination to the left clicked connection.
                connection:Assign(destination)
            else
                -- Select the left clicked connection.
                Connection.Select(connection)
            end
        end
    end

    connection_item.OnRightClickFunc = function(self)
        if connection.Destination then
            -- Unassign the connection and its destination.
            connection:Assign(nil)
        elseif connection:IsSelected() then
            -- Deselect the connection.
            Connection.Select(nil)
        end
    end

    connection_item.SaveFunc = function(self)
        return {
            DestinationName = self.ItemState.DestinationName,
        }
    end

    connection_item.LoadFunc = function(self, data)
        if data.DestinationName then
            print(string.format("ConnectionLuaItem.LoadFunc: loading connection '%s' with saved destination '%s'", self.Name, data.DestinationName))
            self.ItemState.DestinationName = data.DestinationName
            connection.DestinationName = data.DestinationName
            connection:Assign(CONNECTION_BY_NAME[data.DestinationName])
        end
    end

    return connection_item
end

local function createLuaItems()
    for _, connection in pairs(CONNECTION_BY_NAME) do
        CreateConnectionItem(connection)
    end
end

createLuaItems()

EXCLUDED_CONNECTION_MAPPING = {
    ["Oaklaville trail log from top"] = "Oaklaville trail log from bottom",
    ["Rave bouncer from top"] = "Rave bouncer from bottom",
    ["Docks drawbridge from left"] = "Docks drawbridge from right",
    ["Ghost drawbridge from top"] = "Ghost drawbridge from bottom",
    ["Fashion show security from top"] = "Fashion show security from bottom",
    ["Birthday party rope from bottom"] = "Birthday party rope from top",
    ["Snowman square rope from bottom"] = "Snowman square rope from top",
    ["Cliffs bottom rope from bottom"] = "Cliffs bottom rope from middle",
    ["Cliffs top rope from middle"] = "Cliffs top rope from top",
    ["Blizzard bridge rope from lower left"] = "Blizzard bridge rope from lower right",
    ["Blizzard bridge break ice from bottom"] = "Blizzard bridge break ice from top",
    ["Blizzard bridge rope from upper left"] = "Blizzard bridge rope from upper right",
    ["Outside observatory rope from top"] = "Outside observatory rope from bottom",
    ["Basto harbor gate from top"] = "Basto harbor gate from bottom",
    ["Viking express Basto stop"] = "Viking express Stanhamn stop",
    ["Lily pad pond night bridge from left"] = "Lily pad pond night bridge from right",
    ["Bonfire day bridge from top"] = "Bonfire day bridge from bottom",
}

-- Assign connections that are excluded from randomization.
for source, destination in pairs(EXCLUDED_CONNECTION_MAPPING) do
    CONNECTION_BY_NAME[source]:Assign(CONNECTION_BY_NAME[destination])
end