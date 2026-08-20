Archipelago:AddClearHandler("clear handler", OnClear)
Archipelago:AddItemHandler("item handler", OnItem)
Archipelago:AddLocationHandler("location handler", OnLocation)

Archipelago:AddSetReplyHandler("notify handler", OnNotify)
Archipelago:AddRetrievedHandler("notify launch handler", OnNotifyLaunch)

-- Code watches for settings to show/hide portions of the item tracker layout
ScriptHost:AddWatchForCode("progressive_stamps", "progressive_stamps", ToggleItems)
ScriptHost:AddWatchForCode("include_basto", "include_basto", ToggleItems)
ScriptHost:AddWatchForCode("include_items", "include_items", ToggleItems)
ScriptHost:AddWatchForCode("include_cassettes", "include_cassettes", ToggleItems)

ScriptHost:AddOnFrameHandler("tracker_layout_update", UpdateLayout)