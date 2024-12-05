local addonName, addonTable = ...

local lastAnnounce = 0
local announceCooldown = 5 -- seconds

-- Create a hidden tooltip for node scanning
local tooltip = CreateFrame("GameTooltip", "NodeScanTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Function to get node or resource name from the tooltip
local function GetNodeName()
    tooltip:ClearLines()
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetUnit("mouseover") -- Triggers tooltip for the mouseovered object
    return GameTooltipTextLeft1:GetText() or nil
end

-- Function to announce the location of nodes/resources
local function AnnounceResource(role, prefix, nodeName, defaultNode, action)
    if IsInInstance() then
        return
    end

    local currentTime = GetTime()
    if currentTime - lastAnnounce < announceCooldown then
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local mapPosition = C_Map.GetPlayerMapPosition(mapID, "player")
    if not mapPosition then
        return
    end

    local x = string.format("%.1f", mapPosition.x * 100)
    local y = string.format("%.1f", mapPosition.y * 100)
    local node = nodeName or defaultNode
    local message =
        string.format(
        "{rt7} Come & Get It : Hey %s, I came across %s %s that I can't %s at %s, %s!",
        role,
        prefix,
        node,
        action,
        x,
        y
    )

    ChatFrame_OpenChat("/1 " .. message, ChatFrame1)
    lastAnnounce = currentTime
end

-- Mapping error IDs and roles
local errorMapping = {
    [268] = {role = "Rogues", prefix = "a locked", defaultNode = "TREASURE CHEST", action = "open"}, -- "Item is locked"
    ["Herbalism"] = {role = "Herbalists", prefix = "some", defaultNode = "HERB NAME", action = "pick"},
    ["Mining"] = {role = "Miners", prefix = "a", defaultNode = "MINERAL VEIN", action = "mine"}
}

-- Create a frame to handle events
local frame = CreateFrame("Frame")

-- Register the UI_ERROR_MESSAGE event
frame:RegisterEvent("UI_ERROR_MESSAGE")

-- Event handler function
frame:SetScript(
    "OnEvent",
    function(_, _, messageID, message)
        local mapping = errorMapping[messageID] or errorMapping[message:match("Requires (%w+)")]
        if mapping then
            local nodeName = GetNodeName()
            AnnounceResource(mapping.role, mapping.prefix, nodeName, mapping.defaultNode, mapping.action)
        end
    end
)
