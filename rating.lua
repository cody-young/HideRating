-------------------------------------------------------------------------------
--  HideRating -- rating.lua
--
--  Masking ratings across the PvP, inspect, and match UI.
--
--  Copyright (C) 2026 Cody Young (codyy).
--  Licensed under the GNU General Public License v3 or later.
--  See LICENSE, or <https://www.gnu.org/licenses/gpl-3.0.html>.
-------------------------------------------------------------------------------

local addonName, HR = ...

-- What a hidden rating looks like.
local MASK = "|cff808080---|r"
local RECORD_MASK = "|cff808080- - -|r"

-- Bracket sub-frame names shared by ConquestFrame and InspectPVPFrame.
local BRACKETS = { "Arena2v2", "Arena3v3", "RatedBG", "RatedSoloShuffle", "RatedBGBlitz" }

-- rowData keys behind the scoreboard's rating columns.
local RATING_KEYS = {
    rating = true,
    ratingChange = true,
    prematchMMR = true,
}

-- Sort keys of the same columns. These come from Blizzard's table definition
-- rather than the visible header text, so they hold up on any locale.
local RATING_SORTS = {
    mmrPre = true,
    bgratingPre = true,
    bgratingPost = true,
    bgratingChange = true,
}

local function Hiding()
    return HR.Get("hideRating")
end

-- Masking is write-only: we never read a FontString back. Since 12.0 the
-- scoreboard's rating text can be a "secret" value, and insecure code that
-- compares one throws ("attempt to compare local 'current' (a secret string
-- value, while execution tainted by ...)"). So instead of caching the real
-- text to put back later, unhiding asks Blizzard to redraw the frame and the
-- genuine values come back from the source.
local savedShown = setmetatable({}, { __mode = "k" })
local savedMouse = setmetatable({}, { __mode = "k" })

local function MaskText(fontString, mask)
    if not fontString or not fontString.SetText then return end

    fontString:SetText(mask or MASK)
end

local function ConcealFrame(frame)
    if not frame or not frame.Hide then return end

    if frame:IsShown() then
        savedShown[frame] = true
        frame:Hide()
    end
end

-- Put back everything we hid, in one pass.
local function RevealConcealed()
    for frame in pairs(savedShown) do
        savedShown[frame] = nil
        if frame.Show then frame:Show() end
    end

    for header, wasEnabled in pairs(savedMouse) do
        savedMouse[header] = nil
        if header.EnableMouse then header:EnableMouse(wasEnabled) end
    end
end

-- Ask Blizzard to repopulate whatever is on screen, which is what restores the
-- real numbers over our masks. Anything not currently shown needs no help: it
-- repopulates on its own the next time it opens.
local function RequestRedraw()
    if ConquestFrame and ConquestFrame:IsShown() and type(ConquestFrame_Update) == "function" then
        ConquestFrame_Update(ConquestFrame)
    end

    if InspectPVPFrame and InspectPVPFrame:IsShown() and type(InspectPVPFrame_Update) == "function" then
        InspectPVPFrame_Update(InspectPVPFrame)
    end

    if PVPMatchScoreboard and PVPMatchScoreboard.UpdateTable and PVPMatchScoreboard:IsShown() then
        PVPMatchScoreboard:UpdateTable()
    end
end

--------------------------------------------------------------------------
-- PvP window (Blizzard_PVPUI)
--------------------------------------------------------------------------

local function MaskConquestFrame()
    local frame = ConquestFrame
    if not frame or not Hiding() then return end

    for _, bracket in ipairs(BRACKETS) do
        local panel = frame[bracket]
        if panel then
            MaskText(panel.CurrentRating)
            ConcealFrame(panel.Tier)
        end
    end
end

local function MaskRatedPanelTier()
    if not Hiding() then return end

    local inset = PVPQueueFrame and PVPQueueFrame.HonorInset
    local panel = inset and inset.RatedPanel
    if panel then ConcealFrame(panel.Tier) end
end

-- Bracket tooltips repeat the rating and tier, so they go away wholesale
-- while hiding is on.
local function SuppressBracketTooltip()
    if not Hiding() then return end
    if GameTooltip then GameTooltip:Hide() end
    if ConquestTooltip then ConquestTooltip:Hide() end
end

-- A toggle sitting on the PvP window itself, so peeking at your rating never
-- means digging through the options panel.
local toggleButton

local function UpdateToggleButton()
    if not toggleButton then return end
    toggleButton:SetText(Hiding() and "Show Ratings" or "Hide Ratings")
end

local function CreateToggleButton()
    if toggleButton or not PVPQueueFrame then return end

    toggleButton = CreateFrame("Button", "HideRatingToggleButton", PVPQueueFrame, "UIPanelButtonTemplate")
    toggleButton:SetSize(120, 22)
    toggleButton:SetPoint("BOTTOMLEFT", PVPQueueFrame, "BOTTOMLEFT", 10, 10)
    toggleButton:SetFrameLevel(PVPQueueFrame:GetFrameLevel() + 10)

    toggleButton:SetScript("OnClick", function()
        HR.Set("hideRating", not Hiding())
    end)

    toggleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("HideRating", 1, 1, 1)
        GameTooltip:AddLine(Hiding()
            and "Reveal your ratings until you hide them again."
            or "Hide your ratings across the PvP UI.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    toggleButton:SetScript("OnLeave", GameTooltip_Hide)

    UpdateToggleButton()
end

local hookedPvPUI = false

local function HookPvPUI()
    if hookedPvPUI or not PVPQueueFrame or not ConquestFrame then return end

    if type(ConquestFrame_Update) == "function" then
        hooksecurefunc("ConquestFrame_Update", MaskConquestFrame)
    end

    local ratedPanel = PVPQueueFrame.HonorInset and PVPQueueFrame.HonorInset.RatedPanel
    if ratedPanel then
        hooksecurefunc(ratedPanel, "Show", MaskRatedPanelTier)
    end

    for _, bracket in ipairs(BRACKETS) do
        local panel = ConquestFrame[bracket]
        if panel and panel.HookScript then
            panel:HookScript("OnEnter", SuppressBracketTooltip)
        end
    end

    CreateToggleButton()
    MaskConquestFrame()
    MaskRatedPanelTier()
    hookedPvPUI = true
end

--------------------------------------------------------------------------
-- Inspect window (Blizzard_InspectUI)
--------------------------------------------------------------------------

local function MaskInspectFrame()
    if not InspectPVPFrame or not Hiding() then return end

    for _, bracket in ipairs(BRACKETS) do
        local panel = InspectPVPFrame[bracket]
        if panel then
            MaskText(panel.Rating)
            MaskText(panel.Record, RECORD_MASK)
            ConcealFrame(panel.Tier)
        end
    end
end

local hookedInspect = false

local function HookInspect()
    if hookedInspect or type(InspectPVPFrame_Update) ~= "function" then return end
    hooksecurefunc("InspectPVPFrame_Update", MaskInspectFrame)
    hookedInspect = true
end

--------------------------------------------------------------------------
-- Scoreboard and post-match summary (Blizzard_PVPMatch)
--------------------------------------------------------------------------

-- Cells are pooled and their mixin methods are copied in at creation time, so
-- masking on Populate only covers cells built after the hook is installed.
-- MaskMatchTable below sweeps whatever already existed.
local function MaskStringCell(cell)
    if RATING_KEYS[cell.dataProviderKey] then
        MaskText(cell.text)
    end
end

-- PVPNewRatingTemplate is only used for the post-match rating column.
local function MaskNewRatingCell(cell)
    MaskText(cell.text)
end

local function MaskMatchTable(tableBuilder)
    if not tableBuilder or not tableBuilder.columns then return end

    for _, column in ipairs(tableBuilder.columns) do
        local header = column.headerFrame
        local isRating = header and header.sortType and RATING_SORTS[header.sortType]

        if isRating then
            -- Sorting by a hidden column would still leak the ordering, so the
            -- header stops taking clicks. Headers come from a shared pool, so
            -- always restore the flag rather than only clearing it.
            if header.EnableMouse and Hiding() then
                if savedMouse[header] == nil then
                    savedMouse[header] = header:IsMouseEnabled()
                end
                header:EnableMouse(false)
            end

            if Hiding() and column.cells then
                for _, cell in pairs(column.cells) do
                    MaskText(cell.text)
                end
            end
        end
    end
end

-- The footer line under the scoreboard ("Your team's average rating: N", or
-- your own pre/post MMR in solo shuffle). Blizzard re-runs this on every tab
-- update and finishes with Show() or Hide(), so hiding from a post-hook is
-- self-repairing.
local function HideMatchmakingText(fontString)
    if Hiding() then ConcealFrame(fontString) end
end

-- Post-match summary. The earnings panel animates the rating change in, so
-- the animation groups are stopped as well -- otherwise the engine writes
-- alpha back after our Hide() and the real numbers flash on screen.
local function StopAnimations(frame)
    if not frame then return end

    if frame.GetAnimationGroups then
        for _, group in ipairs({ frame:GetAnimationGroups() }) do
            group:Stop()
        end
    end
    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            StopAnimations(child)
        end
    end
end

local function ApplyToEarnings(container)
    container = container or (PVPMatchResults and PVPMatchResults.content
        and PVPMatchResults.content.earningsContainer)
    if not container then return end

    if Hiding() then
        StopAnimations(container)
        container:SetAlpha(0)
        container:EnableMouse(false)
        ConcealFrame(container)
    else
        container:SetAlpha(1)
        container:EnableMouse(true)
    end
end

local hookedEarnings = false

local function HookEarnings()
    local content = PVPMatchResults and PVPMatchResults.content
    local container = content and content.earningsContainer
    if not container then return end

    if not hookedEarnings then
        hookedEarnings = true
        hooksecurefunc(container, "Show", ApplyToEarnings)
        if container.GetAnimationGroups then
            for _, group in ipairs({ container:GetAnimationGroups() }) do
                hooksecurefunc(group, "Play", function(self)
                    if Hiding() then self:Stop() end
                end)
            end
        end
    end

    ApplyToEarnings(container)
end

local hookedMatch = false
local hookedCells, hookedNewRating, hookedFooter, hookedTable, hookedResults = false, false, false, false, false

local function HookMatch()
    if hookedMatch then return end

    if not hookedCells and PVPCellStringMixin and PVPCellStringMixin.Populate then
        hooksecurefunc(PVPCellStringMixin, "Populate", function(cell)
            if Hiding() then MaskStringCell(cell) end
        end)
        hookedCells = true
    end

    if not hookedNewRating and PVPNewRatingMixin and PVPNewRatingMixin.Populate then
        hooksecurefunc(PVPNewRatingMixin, "Populate", function(cell)
            if Hiding() then MaskNewRatingCell(cell) end
        end)
        hookedNewRating = true
    end

    if not hookedFooter and PVPMatchUtil and PVPMatchUtil.UpdateMatchmakingText then
        hooksecurefunc(PVPMatchUtil, "UpdateMatchmakingText", HideMatchmakingText)
        hookedFooter = true
    end

    if not hookedTable and type(ConstructPVPMatchTable) == "function" then
        hooksecurefunc("ConstructPVPMatchTable", MaskMatchTable)
        hookedTable = true
    end

    if not hookedResults and PVPMatchResults then
        -- Install the summary hooks before Blizzard first shows the frame,
        -- otherwise the entrance animation renders a frame of real ratings.
        HookEarnings()
        PVPMatchResults:HookScript("OnShow", HookEarnings)
        hookedResults = true
    end

    hookedMatch = hookedCells and hookedNewRating and hookedFooter and hookedTable and hookedResults
end

--------------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------------

-- Blizzard's PvP frames load on demand, and running our code from inside that
-- secure load path taints the queue UI. Polling for the globals keeps us out
-- of it entirely.
local watcher = CreateFrame("Frame")
local sinceCheck = 0
watcher:SetScript("OnUpdate", function(self, elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < 0.1 then return end
    sinceCheck = 0

    HookPvPUI()
    HookInspect()
    HookMatch()

    if hookedPvPUI and hookedInspect and hookedMatch then
        self:SetScript("OnUpdate", nil)
    end
end)

HR.Subscribe(function(key)
    if key ~= nil and key ~= "hideRating" then return end

    UpdateToggleButton()

    if Hiding() then
        MaskConquestFrame()
        MaskRatedPanelTier()
        MaskInspectFrame()
        ApplyToEarnings()

        -- The scoreboard keeps its TableBuilder on whichever frame hosts it.
        for _, host in ipairs({ PVPMatchScoreboard, PVPMatchResults }) do
            if host and host.tableBuilder then
                MaskMatchTable(host.tableBuilder)
            end
        end
    else
        RevealConcealed()
        ApplyToEarnings()
        RequestRedraw()
    end
end)
