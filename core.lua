-------------------------------------------------------------------------------
--  HideRating -- core.lua
--
--  Settings storage, change broadcast, slash commands.
--
--  Copyright (C) 2026 Cody Young (codyy).
--  Licensed under the GNU General Public License v3 or later.
--  See LICENSE, or <https://www.gnu.org/licenses/gpl-3.0.html>.
-------------------------------------------------------------------------------

local addonName, HR = ...

HR.addonName = addonName
-- The packager rewrites the .toc Version at release time; running straight
-- from the repo leaves the placeholder in place.
local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
if not version or version:find("@project", 1, true) then
    version = "dev"
end
HR.version = version

local CHAT_PREFIX = "|cff66ccffHideRating|r: "

-- Every setting lives here, and every setting is a boolean. Adding one means
-- adding a default, a checkbox in options.lua, and a listener that reacts.
HR.defaults = {
    hideRating          = true,  -- mask ratings everywhere we know about
    friendsOnlyWhispers = false, -- drop whispers from anyone not a friend
    whisperAllowKnown   = true,  -- ...but still let guild/group members through
    hideChat            = false, -- hide the chat windows entirely
    chatOnlyInPvP       = true,  -- ...only inside arenas and battlegrounds
}

local listeners = {}

function HR.Print(msg)
    print(CHAT_PREFIX .. msg)
end

function HR.Get(key)
    if HR.db == nil then return HR.defaults[key] end
    return HR.db[key]
end

-- Notify every subscriber that settings changed. `key` is nil for a bulk
-- refresh (login, zone change), otherwise the single setting that moved.
function HR.Refresh(key)
    for _, listener in ipairs(listeners) do
        local ok, err = pcall(listener, key)
        if not ok then
            HR.Print("|cffff4040error|r while applying settings: " .. tostring(err))
        end
    end
end

function HR.Set(key, value)
    if HR.db then HR.db[key] = value end
    HR.Refresh(key)
end

function HR.Toggle(key)
    HR.Set(key, not HR.Get(key))
    return HR.Get(key)
end

function HR.Subscribe(listener)
    listeners[#listeners + 1] = listener
end

local function LoadSettings()
    HideRatingDB = HideRatingDB or {}
    for key, value in pairs(HR.defaults) do
        if type(HideRatingDB[key]) ~= "boolean" then
            HideRatingDB[key] = value
        end
    end
    HR.db = HideRatingDB
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        LoadSettings()
        if HR.BuildOptions then HR.BuildOptions() end
        self:UnregisterEvent("ADDON_LOADED")
    else
        -- Zoning rebuilds a lot of the UI, so re-assert everything, and give
        -- Blizzard's own post-load layout a moment to finish first.
        HR.Refresh()
        C_Timer.After(0.5, function() HR.Refresh() end)
    end
end)

local ON, OFF = "|cff40ff40on|r", "|cffff4040off|r"

local function StateText(key)
    return HR.Get(key) and ON or OFF
end

local function Usage()
    HR.Print("v" .. tostring(HR.version) .. " — commands:")
    print("  /hiderating rating   — hide PvP ratings (" .. StateText("hideRating") .. ")")
    print("  /hiderating whispers — only show whispers from friends (" .. StateText("friendsOnlyWhispers") .. ")")
    print("  /hiderating known    — treat guild/group members as friends (" .. StateText("whisperAllowKnown") .. ")")
    print("  /hiderating chat     — hide the chat windows (" .. StateText("hideChat") .. ")")
    print("  /hiderating pvponly  — hide chat only in arenas/BGs (" .. StateText("chatOnlyInPvP") .. ")")
    print("  /hiderating config   — open the options panel")
end

local commands = {
    rating   = "hideRating",
    ratings  = "hideRating",
    whispers = "friendsOnlyWhispers",
    whisper  = "friendsOnlyWhispers",
    known    = "whisperAllowKnown",
    chat     = "hideChat",
    pvponly  = "chatOnlyInPvP",
}

local labels = {
    hideRating          = "Hiding ratings",
    friendsOnlyWhispers = "Friends-only whispers",
    whisperAllowKnown   = "Guild and group members count as friends",
    hideChat            = "Hiding chat",
    chatOnlyInPvP       = "Hiding chat only in arenas and battlegrounds",
}

SLASH_HIDERATING1 = "/hiderating"
SLASH_HIDERATING2 = "/hr"
SlashCmdList["HIDERATING"] = function(input)
    local cmd = (input or ""):match("^%s*(%S*)"):lower()
    local key = commands[cmd]

    if key then
        HR.Toggle(key)
        HR.Print(labels[key] .. " is now " .. StateText(key) .. ".")
    elseif cmd == "config" or cmd == "options" then
        if HR.OpenOptions then HR.OpenOptions() end
    else
        Usage()
    end
end
