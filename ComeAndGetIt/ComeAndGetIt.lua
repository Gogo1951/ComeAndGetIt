local addonName, addonTable = ...

local lastAnnounce = 0
local announceCooldown = 10 -- seconds

-- Create a hidden tooltip for node scanning
local tooltip = CreateFrame("GameTooltip", "NodeScanTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Function to get node or herb name from the tooltip
local function GetNodeName()
    -- Clear the tooltip
    tooltip:ClearLines()

    -- Set the tooltip to the object under the cursor
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetUnit("mouseover")  -- Triggers tooltip for the mouseovered object

    -- Get the first line of the tooltip (usually the name of the node or herb)
    local nodeName = GameTooltipTextLeft1:GetText()

    -- Return the node name if found
    if nodeName then
        return nodeName
    else
        return nil
    end
end

-- Function to check if the player can mine
local function CanMine()
    return IsSpellKnown(2575) or IsSpellKnown(2580) -- Example spell IDs for mining
end

-- Function to check if the player can herb
local function CanHerb()
    return IsSpellKnown(2366) -- Example spell ID for herbalism
end

-- Function to announce the location of nodes/herbs
local function AnnounceNodeOrHerb(message)
    if IsInInstance() then return end

    local currentTime = GetTime()
    if currentTime - lastAnnounce >= announceCooldown then
        local mapID = C_Map.GetBestMapForUnit("player")
        local mapPosition = C_Map.GetPlayerMapPosition(mapID, "player")

        if mapPosition then
            -- Round coordinates to 1 decimal place
            local x = string.format("%.1f", mapPosition.x * 100)
            local y = string.format("%.1f", mapPosition.y * 100)

            -- Format the message with coordinates
            local fullMessage = message .. " at " .. x .. " , " .. y .. "!"

            -- Pre-fill the message in the chat input for /1 General
            ChatFrame_OpenChat("/1 " .. fullMessage, ChatFrame1)

            -- Update the last announce time
            lastAnnounce = currentTime
        end
    end
end

-- Create a frame to handle events
local frame = CreateFrame("Frame")

-- Register the UI_ERROR_MESSAGE event
frame:RegisterEvent("UI_ERROR_MESSAGE")

-- Event handler function
frame:SetScript("OnEvent", function(_, event, messageID, message)
    -- Check the text of the error message instead of relying on the message ID
    if message == "Requires Herbalism" and not CanHerb() then
        -- Get the herb name from the tooltip
        local herbName = GetNodeName() or "an herb"

        -- Format the announcement with the herb name
        local announceMessage = "{rt7} Come & Get It : Hey Herbalists, I found " .. herbName
        AnnounceNodeOrHerb(announceMessage)
    elseif message == "Requires Mining" and not CanMine() then
        -- Get the node name from the tooltip
        local nodeName = GetNodeName() or "some ore"

        -- Format the announcement with the node name
        local announceMessage = "{rt7} Come & Get It : Hey Miners, I found " .. nodeName
        AnnounceNodeOrHerb(announceMessage)
    end
end)

-- Function to send a message to the General channel manually
local function SendMessageToGeneral(message)
    local channelID = GetChannelName("General")
    if channelID and channelID > 0 then
        -- This message will only be sent when right-clicking manually
        SendChatMessage(message, "CHANNEL", nil, channelID)
    else
        print("General channel not found.")
    end
end

-- Right-click binding to send the message
frame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        -- Manually trigger the message
        local message = "{rt7} Come & Get It : Check the zone for resources!"
        SendMessageToGeneral(message) -- This call is safe because it's bound to a mouse click
    end
end)

-- Make the frame clickable
frame:EnableMouse(true)

-- Event Frame to handle right-click detection and node name parsing
local eventFrame = CreateFrame("Frame")

-- Function to detect when a right-click happens
local function OnRightClick(self, button)
    if button == "RightButton" then
        GetNodeName()
    end
end

-- Register the event for mouse click
eventFrame:SetScript("OnMouseUp", OnRightClick)

-- Register the event for mouse over unit change (detecting nodes under the mouse)
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

-- Ensure the event frame is active when the UI is loaded
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Enable mouse interaction
    self:EnableMouse(true)
end)
