-- // Typing Tracker
-- // Written by SnowVersio

-- // This addon was written for RP purposes to track when people are typing. It's designed to work in groups at this point.
-- // This is very roughly put together and realistically will need rewriting using something like AceComm
-- // For now I wanted to test the theory and effectiveness, and it works well even with blizz frames (unmoveable)
-- // This will be re-written eventually, after Midnight has dropped and I have focus again.

local PREFIX = "TypingTracker"
local TYPING_TIMEOUT = 3

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local typingPlayers = {}
local lastSent = false

local frame = CreateFrame("Frame", "TypingTrackerFrame", UIParent, "BackdropTemplate")
frame:SetSize(260, 32)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:Hide()

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.text:SetPoint("CENTER")

local function UpdateFrame()
    local names = {}
    for name in pairs(typingPlayers) do
        table.insert(names, name)
    end

    if #names == 0 then
        frame:Hide()
        return
    end

    if #names == 1 then
        frame.text:SetText(names[1] .. " is typing...")
    else
        frame.text:SetText("Several people are typing...")
    end

    frame:Show()
end

local function SendTyping(isTyping)
    if lastSent == isTyping then return end
    lastSent = isTyping

    local msg = isTyping and "1" or "0"

    local channel
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        return
    end

    C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
end

local function OnEditBoxUpdate(self)
    local text = self:GetText()
    local chatType = self:GetAttribute("chatType")

    if chatType ~= "SAY" and chatType ~= "PARTY" and chatType ~= "RAID" then
        SendTyping(false)
        return
    end

    if text and text ~= "" then
        SendTyping(true)
    else
        SendTyping(false)
    end
end

local function HookEditBoxes()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox and not editBox.TypingTrackerHooked then
            editBox:HookScript("OnTextChanged", OnEditBoxUpdate)
            editBox:HookScript("OnEditFocusLost", function()
                SendTyping(false)
            end)
            editBox.TypingTrackerHooked = true
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        HookEditBoxes()
        return
    end

    if event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...

        if prefix ~= PREFIX then return end
        if sender == UnitName("player") then return end

        if msg == "1" then
            typingPlayers[sender] = GetTime()
        else
            typingPlayers[sender] = nil
        end

        UpdateFrame()
    end
end)

C_Timer.NewTicker(1, function()
    local now = GetTime()
    for name, timeStamp in pairs(typingPlayers) do
        if now - timeStamp > TYPING_TIMEOUT then
            typingPlayers[name] = nil
        end
    end
    UpdateFrame()
end)

