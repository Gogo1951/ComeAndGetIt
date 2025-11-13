local addonName, addonTable = ...

local ANNOUNCE_COOLDOWN = 5
local ERROR_LOCKED_CHEST = 268

local GetTime = GetTime
local IsInInstance = IsInInstance
local GetBestMapForUnit = C_Map and C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map and C_Map.GetPlayerMapPosition
local GetMapInfo = C_Map and C_Map.GetMapInfo
local OpenChat = ChatFrame_OpenChat
local format = string.format
local GetChannelList = GetChannelList
local GetChannelInfo = C_ChatInfo and C_ChatInfo.GetChannelInfo
local ERR_SKILL_REQUIRES = _G.ERR_SKILL_REQUIRES or "Requires %s"

local lastAnnounce = 0
local layerIndexByZoneAndInstance = {}
local nextLayerIndexByZone = {}

local errorMapping = {
    [ERROR_LOCKED_CHEST] = {role = "Rogues", prefix = "a locked", defaultNode = "TREASURE CHEST", action = "open"},
    Herbalism = {role = "Herbalists", prefix = "some", defaultNode = "HERB NAME", action = "pick"},
    Mining = {role = "Miners", prefix = "a", defaultNode = "MINERAL VEIN", action = "mine"}
}

local requiresPattern
do
    local p = ERR_SKILL_REQUIRES:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    requiresPattern = p:gsub("%%s", "(.+)")
end

local function NormalizeSkillName(skill)
    if not skill then
        return nil
    end
    skill = skill:gsub("%b()", "")
    skill = skill:match("^%s*(.-)%s*$")
    return skill
end

local function GetNodeName()
    local f = _G.GameTooltipTextLeft1
    return f and f:GetText()
end

local function ResolveGeneralLayer(zoneName)
    if not GetChannelInfo then
        return nil
    end
    local list = {GetChannelList()}
    for i = 1, #list, 3 do
        local id = list[i]
        local name = list[i + 1]
        if id and name and name:match("^General %- ") and name:find(zoneName, 1, true) then
            local info = GetChannelInfo(id)
            if info and info.instanceID and info.instanceID > 0 then
                local inst = tostring(info.instanceID)
                local key = zoneName .. ":" .. inst
                local idx = layerIndexByZoneAndInstance[key]
                if not idx then
                    local n = nextLayerIndexByZone[zoneName] or 1
                    idx = n
                    layerIndexByZoneAndInstance[key] = idx
                    nextLayerIndexByZone[zoneName] = n + 1
                end
                return idx
            end
        end
    end
end

local function Announce(mapping)
    if IsInInstance() then
        return
    end
    local now = GetTime()
    if now - lastAnnounce < ANNOUNCE_COOLDOWN then
        return
    end
    if not GetBestMapForUnit or not GetPlayerMapPosition or not GetMapInfo then
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
    if not mapInfo or not mapInfo.name then
        return
    end

    local node = GetNodeName() or mapping.defaultNode
    if not node or node == "" then
        return
    end

    local x = format("%.0f", pos.x * 100)
    local y = format("%.0f", pos.y * 100)

    local zone = mapInfo.name
    local layer = ResolveGeneralLayer(zone)
    local layerText = layer and format(" (Layer %d)", layer) or ""

    local msg =
        format(
        "{rt7} Come & Get It // Hey %s, I came across %s %s that I can't %s at %s, %s in %s%s!",
        mapping.role,
        mapping.prefix,
        node,
        mapping.action,
        x,
        y,
        zone,
        layerText
    )

    OpenChat("/1 " .. msg, ChatFrame1)
    lastAnnounce = now
end

local function MatchError(messageID, message)
    local m = errorMapping[messageID]
    if m then
        return m
    end
    if not message then
        return nil
    end

    local skill = message:match(requiresPattern)
    if not skill then
        skill = message:match("Requires%s+([%a ]+)")
    end

    skill = NormalizeSkillName(skill)
    if not skill or skill == "" then
        return nil
    end

    return errorMapping[skill]
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:SetScript(
    "OnEvent",
    function(_, _, messageID, message)
        local map = MatchError(messageID, message)
        if map then
            Announce(map)
        end
    end
)
