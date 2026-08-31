-------------------------------------------------------------------------------
--  HideRating -- options.lua
--
--  The interface options panel.
--
--  Copyright (C) 2026 Cody Young (codyy).
--  Licensed under the GNU General Public License v3 or later.
--  See LICENSE, or <https://www.gnu.org/licenses/gpl-3.0.html>.
-------------------------------------------------------------------------------

local addonName, HR = ...

local panel, category
local checkboxes = {}

local function CreateCheckbox(parent, key, label, tooltip, indented)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)

    local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 2, 1)
    text:SetText(label)

    check.key = key
    check.label = text
    check.indented = indented

    check:SetScript("OnClick", function(self)
        HR.Set(key, self:GetChecked() and true or false)
        HR.RefreshOptions()
    end)

    if tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", GameTooltip_Hide)
    end

    checkboxes[#checkboxes + 1] = check
    return check
end

local function SetCheckboxEnabled(check, enabled)
    if enabled then
        check:Enable()
        check.label:SetTextColor(1, 0.82, 0)
        check.label:SetAlpha(1)
    else
        check:Disable()
        check.label:SetTextColor(0.5, 0.5, 0.5)
        check.label:SetAlpha(0.6)
    end
end

function HR.RefreshOptions()
    if not panel then return end

    for _, check in ipairs(checkboxes) do
        check:SetChecked(HR.Get(check.key) and true or false)
    end

    -- Sub-options only mean something while their parent option is on.
    SetCheckboxEnabled(panel.allowKnown, HR.Get("friendsOnlyWhispers"))
    SetCheckboxEnabled(panel.pvpOnly, HR.Get("hideChat"))
end

function HR.BuildOptions()
    if panel then return end

    panel = CreateFrame("Frame")
    panel.name = "HideRating"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("HideRating")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Keep ratings, strangers, and chat noise out of sight. Also available from /hiderating.")

    local rating = CreateCheckbox(panel, "hideRating", "Hide PvP ratings",
        "Masks your ratings in the PvP window, on inspected players, and on the scoreboard and post-match summary.")
    rating:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -18)

    local whispers = CreateCheckbox(panel, "friendsOnlyWhispers", "Only show whispers from friends",
        "Whispers from anyone who is not a character or Battle.net friend are not shown.")
    whispers:SetPoint("TOPLEFT", rating, "BOTTOMLEFT", 0, -10)

    local allowKnown = CreateCheckbox(panel, "whisperAllowKnown", "...but allow guild and group members",
        "Guildmates and anyone currently in your party or raid can still whisper you.", true)
    allowKnown:SetPoint("TOPLEFT", whispers, "BOTTOMLEFT", 20, -6)
    panel.allowKnown = allowKnown

    local chat = CreateCheckbox(panel, "hideChat", "Hide chat windows",
        "Hides the chat frames, tabs, and chat buttons. Typing still works: the edit box stays visible while you type.")
    chat:SetPoint("TOPLEFT", allowKnown, "BOTTOMLEFT", -20, -10)

    local pvpOnly = CreateCheckbox(panel, "chatOnlyInPvP", "...only in arenas and battlegrounds",
        "Chat comes back as soon as you leave instanced PvP.", true)
    pvpOnly:SetPoint("TOPLEFT", chat, "BOTTOMLEFT", 20, -6)
    panel.pvpOnly = pvpOnly

    panel:SetScript("OnShow", HR.RefreshOptions)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    HR.RefreshOptions()
end

function HR.OpenOptions()
    HR.BuildOptions()

    if Settings and Settings.OpenToCategory and category then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

-- Keep the panel in step with slash-command toggles.
HR.Subscribe(function()
    if panel then HR.RefreshOptions() end
end)
