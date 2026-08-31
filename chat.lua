-------------------------------------------------------------------------------
--  HideRating -- chat.lua
--
--  Whisper filtering and hiding the chat windows.
--
--  Copyright (C) 2026 Cody Young (codyy).
--  Licensed under the GNU General Public License v3 or later.
--  See LICENSE, or <https://www.gnu.org/licenses/gpl-3.0.html>.
-------------------------------------------------------------------------------

local addonName, HR = ...

--------------------------------------------------------------------------
-- Whispers from people you don't know
--------------------------------------------------------------------------

-- A sender counts as known if they are on the character friends list or are
-- one of your Battle.net friends. With "whisperAllowKnown" on, guildmates and
-- anyone currently in your party or raid pass as well -- that keeps arena and
-- key partners audible while strangers stay quiet.
local function IsKnownSender(guid, name)
    if guid then
        if C_FriendList and C_FriendList.IsFriend and C_FriendList.IsFriend(guid) then
            return true
        end
        if C_BattleNet and C_BattleNet.GetAccountInfoByGUID and C_BattleNet.GetAccountInfoByGUID(guid) then
            return true
        end
    end

    if not HR.Get("whisperAllowKnown") then
        return false
    end

    if name and name ~= "" then
        if UnitInParty(name) or UnitInRaid(name) then
            return true
        end
    end

    if guid and type(IsGuildMember) == "function" then
        local ok, isGuildMember = pcall(IsGuildMember, guid)
        if ok and isGuildMember then
            return true
        end
    end

    return false
end

-- Chat filter signature: (chatFrame, event, then the event's own arguments).
-- For CHAT_MSG_WHISPER those are text, playerName, ... , lineID, guid, bnSenderID.
local function WhisperFilter(_, _, _, playerName, _, _, _, _, _, _, _, _, _, guid, bnSenderID)
    if not HR.Get("friendsOnlyWhispers") then
        return false
    end

    -- Battle.net whispers can only come from Battle.net friends.
    if bnSenderID and bnSenderID ~= 0 then
        return false
    end

    if IsKnownSender(guid, playerName) then
        return false
    end

    return true
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", WhisperFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_AFK", WhisperFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_DND", WhisperFilter)

--------------------------------------------------------------------------
-- Hiding the chat windows
--------------------------------------------------------------------------

local EXTRA_FRAMES = {
    "GeneralDockManager",
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton",
    "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
}

local hiddenByUs = {}
local reparented = {}
local applying = false

local function ForEachChatElement(callback)
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            callback(chatFrame)
            for _, suffix in ipairs({ "Tab", "ButtonFrame" }) do
                local child = _G["ChatFrame" .. i .. suffix]
                if child then callback(child) end
            end
        end
    end

    for _, name in ipairs(EXTRA_FRAMES) do
        local frame = _G[name]
        if frame then callback(frame) end
    end
end

-- The edit box lives inside the chat frame, so hiding the frame would also
-- swallow anything you type -- including slash commands. Parking it on
-- UIParent for the duration keeps typing visible and working; its anchors are
-- untouched, so it still sits where it always did.
local function ForEachEditBox(callback)
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then callback(editBox) end
    end
end

local function ShouldHideChat()
    if not HR.Get("hideChat") then
        return false
    end
    if not HR.Get("chatOnlyInPvP") then
        return true
    end

    local _, instanceType = IsInInstance()
    return instanceType == "arena" or instanceType == "pvp"
end

local function ApplyChatVisibility()
    if applying then return end
    applying = true

    local hide = ShouldHideChat()

    ForEachChatElement(function(frame)
        if hide then
            if frame:IsShown() then
                hiddenByUs[frame] = true
                frame:Hide()
            end
        elseif hiddenByUs[frame] then
            hiddenByUs[frame] = nil
            frame:Show()
        end
    end)

    ForEachEditBox(function(editBox)
        if hide then
            if not reparented[editBox] then
                reparented[editBox] = editBox:GetParent() or UIParent
                pcall(editBox.SetParent, editBox, UIParent)
            end
        elseif reparented[editBox] then
            pcall(editBox.SetParent, editBox, reparented[editBox])
            reparented[editBox] = nil
        end
    end)

    applying = false
end

HR.ApplyChatVisibility = ApplyChatVisibility

-- Blizzard re-shows chat windows on its own when you dock a tab, pop a
-- temporary whisper window, or finish loading a zone.
local function Reassert()
    if applying then return end
    if HR.Get("hideChat") then ApplyChatVisibility() end
end

if type(FCF_SelectDockFrame) == "function" then
    hooksecurefunc("FCF_SelectDockFrame", Reassert)
end
if type(FCF_OpenTemporaryWindow) == "function" then
    hooksecurefunc("FCF_OpenTemporaryWindow", Reassert)
end
if type(FCF_OpenNewWindow) == "function" then
    hooksecurefunc("FCF_OpenNewWindow", Reassert)
end

HR.Subscribe(function(key)
    if key == nil or key == "hideChat" or key == "chatOnlyInPvP" then
        ApplyChatVisibility()
    end
end)
