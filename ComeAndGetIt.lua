local addonName, addonTable = ...

local lastAnnounce = 0
local ANNOUNCE_COOLDOWN = 5 -- seconds

local parentFrame = UIParent -- Cache UIParent reference

-- Create a hidden tooltip for node scanning
local tooltip = CreateFrame("GameTooltip", "NodeScanTooltip", parentFrame, "GameTooltipTemplate")
tooltip:SetOwner(parentFrame, "ANCHOR_NONE")

-- Retrieves the name of the resource from the tooltip
local function GetNodeName()
    tooltip:ClearLines()
    tooltip:SetUnit("mouseover") -- Triggers tooltip for the hovered object
    return GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText() or nil
end

-- Function to retrieve current layer (returns nil if not detectable)
local function GetCurrentLayer()
    local channelList = {GetChannelList()}
    for i = 1, #channelList, 3 do
        local name = channelList[i + 1]
        local layer = name and name:match("Layer (%d+)")
        if layer then
            return tonumber(layer)
        end
    end
    return nil -- No layer detected
end

-- Announces the location of nodes/resources if conditions are met
local function AnnounceResource(role, prefix, nodeName, defaultNode, action)
    if IsInInstance() then
        return
    end

    local currentTime = GetTime()
    if (currentTime - lastAnnounce) < ANNOUNCE_COOLDOWN then
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return
    end

    local mapPosition = C_Map.GetPlayerMapPosition(mapID, "player")
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapPosition or not mapInfo then
        return
    end

    local x, y = string.format("%.1f", mapPosition.x * 100), string.format("%.1f", mapPosition.y * 100)
    local zoneName = mapInfo.name or "Unknown Zone"
    local node = nodeName or defaultNode

    if not node then
        return
    end -- Ensure node is valid

    local layer = GetCurrentLayer()
    local layerText = layer and string.format(" (Layer %d)", layer) or ""

    local message =
        string.format(
        "{rt7} Come & Get It : Hey %s, I came across %s %s that I can't %s at %s, %s in %s%s!",
        role,
        prefix,
        node,
        action,
        x,
        y,
        zoneName,
        layerText
    )

    ChatFrame_OpenChat("/1 " .. message, ChatFrame1)
    lastAnnounce = currentTime
end

-- Error message mapping for resource gathering roles
local errorMapping = {
    [268] = {role = "Rogues", prefix = "a locked", defaultNode = "TREASURE CHEST", action = "open"}, -- "Item is locked"
    ["Herbalism"] = {role = "Herbalists", prefix = "some", defaultNode = "HERB NAME", action = "pick"},
    ["Mining"] = {role = "Miners", prefix = "a", defaultNode = "MINERAL VEIN", action = "mine"}
}

-- Create event handling frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_ERROR_MESSAGE")

-- Handles error messages and triggers announcements
frame:SetScript(
    "OnEvent",
    function(_, _, messageID, message)
        local mapping = errorMapping[messageID] or errorMapping[message:match("Requires (%w+)")]
        if mapping then
            AnnounceResource(mapping.role, mapping.prefix, GetNodeName(), mapping.defaultNode, mapping.action)
        end
    end
)
