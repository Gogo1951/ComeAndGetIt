local addonName, addonTable = ...

local ANNOUNCE_COOLDOWN = 5
local ERROR_LOCKED_CHEST = 268

local GetTime, IsInInstance = GetTime, IsInInstance
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local GetMapInfo = C_Map.GetMapInfo
local OpenChat = ChatFrame_OpenChat
local format = string.format
local match = string.match
local GetChannelList = GetChannelList
local GetChannelInfo = C_ChatInfo and C_ChatInfo.GetChannelInfo

local lastAnnounce = 0
local layerIndexByZoneAndInstance = {}
local nextLayerIndexByZone = {}

local errorMapping = {
    [ERROR_LOCKED_CHEST] = {role = "Rogues", prefix = "a locked", defaultNode = "TREASURE CHEST", action = "open"},
    ["Herbalism"] = {role = "Herbalists", prefix = "some", defaultNode = "HERB NAME", action = "pick"},
    ["Mining"] = {role = "Miners", prefix = "a", defaultNode = "MINERAL VEIN", action = "mine"}
}

local function GetNodeName()
    local fs = _G.GameTooltipTextLeft1
    return fs and fs:GetText() or nil
end

local function GetCurrentLayer()
    local mapID = GetBestMapForUnit("player")
    if not mapID then
        return nil
    end
    local mapInfo = GetMapInfo(mapID)
    local zoneName = mapInfo and mapInfo.name
    if not zoneName or zoneName == "" then
        return nil
    end
    if not GetChannelInfo then
        return nil
    end
    local list = {GetChannelList()}
    for i = 1, #list, 3 do
        local id = list[i]
        local name = list[i + 1]
        if id and name and name:match("^General %- ") and name:find(zoneName, 1, true) then
            local info = GetChannelInfo(id)
            local instanceID = info and info.instanceID
            if instanceID and instanceID > 0 then
                local key = zoneName .. ":" .. tostring(instanceID)
                local idx = layerIndexByZoneAndInstance[key]
                if not idx then
                    local nextIdx = nextLayerIndexByZone[zoneName] or 1
                    idx = nextIdx
                    layerIndexByZoneAndInstance[key] = idx
                    nextLayerIndexByZone[zoneName] = nextIdx + 1
                end
                return idx
            end
        end
    end
    return nil
end

local function AnnounceResource(mapping)
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
    if not pos then
        return
    end
    local mapInfo = GetMapInfo(mapID)
    if not mapInfo then
        return
    end
    local node = GetNodeName() or mapping.defaultNode
    if not node or node == "" then
        return
    end
    local x = format("%.1f", pos.x * 100)
    local y = format("%.1f", pos.y * 100)
    local zoneName = mapInfo.name or "Unknown Zone"
    local layer = GetCurrentLayer()
    local layerText = layer and format(" (Layer %d)", layer) or ""
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

local function GetErrorMapping(messageID, message)
    local mapping = errorMapping[messageID]
    if mapping then
        return mapping
    end
    if not message then
        return nil
    end
    local skill = match(message, "Requires%s+([%a ]+)") or match(message, "Requires(%a+)")
    if skill then
        skill = skill:match("^%s*(.-)%s*$")
        return errorMapping[skill]
    end
    return nil
end

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
