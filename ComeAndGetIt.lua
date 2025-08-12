local addonName, addonTable = ...

-- Constants
local ANNOUNCE_COOLDOWN = 5
local ERROR_LOCKED_CHEST = 268

-- Cache frequently used functions
local GetTime, IsInInstance = GetTime, IsInInstance
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local GetMapInfo = C_Map.GetMapInfo
local OpenChat = ChatFrame_OpenChat
local format = string.format
local match = string.match

-- State
local lastAnnounce = 0

-- Error message mappings
local errorMapping = {
    [ERROR_LOCKED_CHEST] = {role = "Rogues", prefix = "a locked", defaultNode = "TREASURE CHEST", action = "open"},
    ["Herbalism"] = {role = "Herbalists", prefix = "some", defaultNode = "HERB NAME", action = "pick"},
    ["Mining"] = {role = "Miners", prefix = "a", defaultNode = "MINERAL VEIN", action = "mine"}
}

-- Helper function to get tooltip text
local function GetNodeName()
    local fs = _G.GameTooltipTextLeft1
    return fs and fs:GetText() or nil
end

-- Get current layer from channel list
local function GetCurrentLayer()
    local list = {GetChannelList()}
    for i = 2, #list, 3 do -- Start at 2 since channel names are at indices 2, 5, 8, etc.
        local layer = match(list[i], "Layer (%d+)")
        if layer then
            return tonumber(layer)
        end
    end
    return nil
end

-- Build and send announcement message
local function AnnounceResource(mapping)
    -- Early exit conditions
    if IsInInstance() then
        return
    end

    local now = GetTime()
    if (now - lastAnnounce) < ANNOUNCE_COOLDOWN then
        return
    end

    -- Get map and position data
    local mapID = GetBestMapForUnit("player")
    if not mapID then
        return
    end

    local pos = GetPlayerMapPosition(mapID, "player")
    if not pos then
        return
    end

    local mapInfo = GetMapInfo(mapID)
    if not mapInfo then
        return
    end

    -- Get node name
    local node = GetNodeName() or mapping.defaultNode
    if not node or node == "" then
        return
    end

    -- Format coordinates
    local x = format("%.1f", pos.x * 100)
    local y = format("%.1f", pos.y * 100)

    -- Build message components
    local zoneName = mapInfo.name or "Unknown Zone"
    local layer = GetCurrentLayer()
    local layerText = layer and format(" (Layer %d)", layer) or ""

    -- Build and send message
    local msg =
        format(
        "{rt7} Come & Get It : Hey %s, I came across %s %s that I can't %s at %s, %s in %s%s!",
        mapping.role,
        mapping.prefix,
        node,
        mapping.action,
        x,
        y,
        zoneName,
        layerText
    )

    OpenChat("/1 " .. msg, ChatFrame1)
    lastAnnounce = now
end

-- Look up error mapping based on message ID or content
local function GetErrorMapping(messageID, message)
    -- Direct lookup by message ID
    local mapping = errorMapping[messageID]
    if mapping then
        return mapping
    end

    -- Extract skill requirement from message
    if not message then
        return nil
    end

    -- Try both patterns for skill extraction
    local skill = match(message, "Requires%s+([%a ]+)") or match(message, "Requires(%a+)")

    if skill then
        -- Trim whitespace
        skill = skill:match("^%s*(.-)%s*$")
        return errorMapping[skill]
    end

    return nil
end

-- Event handler frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:SetScript(
    "OnEvent",
    function(_, _, messageID, message)
        local mapping = GetErrorMapping(messageID, message)
        if mapping then
            AnnounceResource(mapping)
        end
    end
)
