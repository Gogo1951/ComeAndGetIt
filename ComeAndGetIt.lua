local addonName, addonTable = ...

local lastAnnounce = 0
local ANNOUNCE_COOLDOWN = 5

local gsub, format, tonumber = string.gsub, string.format, tonumber
local GetTime, IsInInstance = GetTime, IsInInstance
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local GetMapInfo = C_Map.GetMapInfo
local OpenChat = ChatFrame_OpenChat

local function GetNodeName()
    local fs = _G.GameTooltipTextLeft1
    return fs and fs:GetText() or nil
end

local function GetCurrentLayer()
    local list = {GetChannelList()}
    for i = 1, #list, 3 do
        local name = list[i + 1]
        local layer = name and name:match("Layer (%d+)")
        if layer then
            return tonumber(layer)
        end
    end
    return nil
end

local function AnnounceResource(role, prefix, nodeName, defaultNode, action)
    if IsInInstance() then
        return
    end
    local now = GetTime()
    if (now - lastAnnounce) < ANNOUNCE_COOLDOWN then
        return
    end

    local mapID = GetBestMapForUnit("player")
    if not mapID then
        return
    end

    local pos = GetPlayerMapPosition(mapID, "player")
    local mapInfo = GetMapInfo(mapID)
    if not pos or not mapInfo then
        return
    end

    local x, y = format("%.1f", pos.x * 100), format("%.1f", pos.y * 100)
    local zoneName = mapInfo.name or "Unknown Zone"
    local node = nodeName or defaultNode
    if not node or node == "" then
        return
    end

    local layer = GetCurrentLayer()
    local layerText = layer and format(" (Layer %d)", layer) or ""

    local msg =
        format(
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

    OpenChat("/1 " .. msg, ChatFrame1)
    lastAnnounce = now
end

local errorMapping = {
    [268] = {role = "Rogues", prefix = "a locked", defaultNode = "TREASURE CHEST", action = "open"},
    Herbalism = {role = "Herbalists", prefix = "some", defaultNode = "HERB NAME", action = "pick"},
    Mining = {role = "Miners", prefix = "a", defaultNode = "MINERAL VEIN", action = "mine"}
}

local function lookupMapping(messageID, message)
    local m = errorMapping[messageID]
    if m then
        return m
    end
    local skill = message and message:match("Requires%s+([%a ]+)")
    if not skill then
        skill = message and message:match("Requires(%a+)")
    end
    if skill then
        skill = gsub(skill, "^%s*(.-)%s*$", "%1")
        return errorMapping[skill]
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:SetScript(
    "OnEvent",
    function(_, _, messageID, message)
        local mapping = lookupMapping(messageID, message)
        if mapping then
            AnnounceResource(mapping.role, mapping.prefix, GetNodeName(), mapping.defaultNode, mapping.action)
        end
    end
)
