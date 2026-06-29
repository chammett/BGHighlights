local addonName, BGH = ...

-- ==========================================
-- 5.1. MAIN FRAME (The Wall)
-- ==========================================

BGH.activeMedalFrames = {}
BGH.MedalFramePool = {}

local BGFrame = CreateFrame("Frame", "BGHighlightsMainFrame", UIParent)
BGFrame:SetSize(384, 512) 
BGFrame:SetPoint("CENTER", UIParent, "CENTER")
BGFrame:SetFrameStrata("HIGH")
BGFrame:Hide()

BGH.BGFrame = BGFrame

table.insert(UISpecialFrames, "BGHighlightsMainFrame") 

BGFrame:SetMovable(true)
BGFrame:EnableMouse(true)
BGFrame:RegisterForDrag("LeftButton")
BGFrame:SetScript("OnDragStart", BGFrame.StartMoving)
BGFrame:SetScript("OnDragStop", BGFrame.StopMovingOrSizing)

local topLeft = BGFrame:CreateTexture(nil, "ARTWORK")
topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
topLeft:SetSize(256, 256)
topLeft:SetPoint("TOPLEFT", 0, 0)

local topRight = BGFrame:CreateTexture(nil, "ARTWORK")
topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
topRight:SetSize(128, 256)
topRight:SetPoint("TOPLEFT", 256, 0)

local bottomLeft = BGFrame:CreateTexture(nil, "ARTWORK")
bottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft")
bottomLeft:SetSize(256, 256)
bottomLeft:SetPoint("TOPLEFT", 0, -256)

local bottomRight = BGFrame:CreateTexture(nil, "ARTWORK")
bottomRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight")
bottomRight:SetSize(128, 256)
bottomRight:SetPoint("TOPLEFT", 256, -256)

local portrait = BGFrame:CreateTexture("BGHighlightsPortrait", "BACKGROUND")
portrait:SetSize(60, 60)
portrait:SetPoint("TOPLEFT", 9, -6)
SetPortraitTexture(portrait, "player")

BGFrame:HookScript("OnShow", function()
    SetPortraitTexture(portrait, "player")
end)

local titleText = BGFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleText:SetPoint("TOP", BGFrame, "TOP", 0, -18)
titleText:SetText("BGHighlights")

local mapText = BGFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mapText:SetPoint("TOP", BGFrame, "TOP", 0, -42)
mapText:SetJustifyH("CENTER")
mapText:SetText("Previous Match: No Data")
BGFrame.mapText = mapText

local topCloseButton = CreateFrame("Button", nil, BGFrame, "UIPanelCloseButton")
topCloseButton:SetPoint("TOPRIGHT", BGFrame, "TOPRIGHT", -30, -8)

topCloseButton:SetScript("OnClick", function()
    PlaySound(850, "Master")
    BGFrame:Hide()
end)

local settingsBtn = CreateFrame("Button", nil, BGFrame)
settingsBtn:SetSize(15, 15) 
settingsBtn:SetPoint("RIGHT", topCloseButton, "LEFT", -6, 0)
settingsBtn:SetNormalTexture("Interface\\Icons\\trade_engineering")
settingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
settingsBtn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

if settingsBtn:GetNormalTexture() then settingsBtn:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92) end
if settingsBtn:GetPushedTexture() then settingsBtn:GetPushedTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92) end

settingsBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Configuration", 1, 1, 1)
    GameTooltip:Show()
end)

settingsBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

-- ==========================================
-- LIFETIME STATS DROPDOWN
-- ==========================================
local mapDropdown = nil
BGH.SelectedLifetimeMap = "Overall"

local function MapDropdown_OnClick(self)
    UIDropDownMenu_SetSelectedID(mapDropdown, self:GetID())
    BGH.SelectedLifetimeMap = self.value
    
    if BGFrame.ClearMedalsUI then BGFrame:ClearMedalsUI() end
    if BGFrame.RenderLifetimeStats then BGFrame:RenderLifetimeStats() end
end

local function MapDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    local pLevel = UnitLevel("player")
    
    local options = {
        { text = "Overall", value = "Overall", req = 0 },
        { text = "Warsong Gulch", value = "Warsong Gulch", req = 10 },
        { text = "Arathi Basin", value = "Arathi Basin", req = 20 },
        { text = "Alterac Valley", value = "Alterac Valley", req = 51 },
        { text = "Eye of the Storm", value = "Eye of the Storm", req = 61 }
    }
    
    for i, opt in ipairs(options) do
        if pLevel >= opt.req then
            info.text = opt.text
            info.value = opt.value
            info.func = MapDropdown_OnClick
            info.checked = (BGH.SelectedLifetimeMap == opt.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

-- ==========================================
-- LIFETIME STATS RENDERER
-- ==========================================
function BGFrame:RenderLifetimeStats()
    if type(BGHL_LifetimeStats) ~= "table" then return end
    
    if not mapDropdown then
        mapDropdown = CreateFrame("Frame", "BGHLifetimeMapDropdown", BGH.scrollChild, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(mapDropdown, 160)
        UIDropDownMenu_JustifyText(mapDropdown, "CENTER")
        UIDropDownMenu_Initialize(mapDropdown, MapDropdown_Initialize)
		mapDropdown.point = "TOPLEFT"
        mapDropdown.relativePoint = "BOTTOMLEFT"
        mapDropdown.xOffset = 40 
        mapDropdown.yOffset = 25
    end
    
    mapDropdown:SetPoint("TOP", BGH.scrollChild, "TOP", 30, -5)
    mapDropdown:Show()
    UIDropDownMenu_SetText(mapDropdown, BGH.SelectedLifetimeMap or "Overall")
    
    local mapKey = BGH.SelectedLifetimeMap or "Overall"
    local lts = {}
    if mapKey == "Overall" then
        lts = BGHL_LifetimeStats.Overall or {}
    else
        lts = BGHL_LifetimeStats.Maps and BGHL_LifetimeStats.Maps[mapKey] or {}
    end

    local matches = lts.matchesPlayed or 0
    local avgMedals = matches > 0 and (lts.totalMedals or 0) / matches or 0
    local avgMom = matches > 0 and (lts.sumMomentum or 0) / matches or 0
    local avgObj = matches > 0 and (lts.sumObjectives or 0) / matches or 0
    local avgWeight = matches > 0 and (lts.sumWeight or 0) / matches or 0

    local currentY = -45
    local poolIndex = 1

    local function AddStatRow(title, desc, icon, colorCode)
        local mockData = { title = title, desc = desc, icon = icon, playerName = UnitName("player"), comboPct = 0, taxPct = 0 }
        
        local frame = BGH.UpdateOrCreateMedalRow(poolIndex, BGH.scrollChild, mockData, colorCode)
        poolIndex = poolIndex + 1
        
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:SetScript("OnClick", nil)
        
        local kids = {frame:GetChildren()}
        for _, child in ipairs(kids) do
            if child:GetObjectType() == "Button" then
                child:SetScript("OnEnter", nil)
                child:SetScript("OnLeave", nil)
                child:SetScript("OnClick", nil)
            end
        end
        
        frame:SetPoint("TOP", BGH.scrollChild, "TOP", 25, currentY)
        currentY = currentY - frame:GetHeight() - 10
        table.insert(BGH.activeMedalFrames, frame)
    end

    AddStatRow("Career Overview", 
        string.format("Matches Played: |cff00ff00%d|r\nTotal Medals Earned: |cff00ff00%d|r", matches, lts.totalMedals or 0), 
        "Interface\\Icons\\Ability_Rogue_SliceDice", 4)

    AddStatRow("Performance Averages", 
        string.format("Avg Momentum: |cff00ccff%.1f|r\nAvg Objectives: |cff00ccff%.1f|r\nAvg Medal Weight: |cff00ccff%.1f|r\nAvg Medals/Match: |cff00ccff%.1f|r", avgMom, avgObj, avgWeight, avgMedals), 
        "Interface\\Icons\\Spell_Magic_LesserInvisibilty", 3)

    local faces = { [11]="Page", [12]="Knight", [13]="Queen", [14]="King" }
    local function GetRankStr(tier)
        if tier <= 0 then return "|cff777777None|r" end
        if tier == 1 then return "|cff00ff00Ace|r" end
        if tier > 1 and tier <= 10 then return string.format("|cff0070dd%d|r", tier) end
        return string.format("|cffa335ee%s|r", faces[tier] or "King")
    end

    local minors = lts.highestMinor or {}
    AddStatRow("Highest Minor Arcana Drawn", 
        string.format("Swords (Offense): %s\nCups (Healing): %s\nWands (Objectives): %s\nCoins (Momentum): %s", 
        GetRankStr(minors.Swords or 0), GetRankStr(minors.Cups or 0), GetRankStr(minors.Wands or 0), GetRankStr(minors.Coins or 0)), 
        "Interface\\Icons\\Spell_Holy_RemoveCurse", 2)

    AddStatRow("Lifetime Highs", 
        string.format("Record Momentum: |cffff8000%.1f|r\nRecord Objectives: |cffff8000%.1f|r\nRecord Weight: |cffff8000%.1f|r\nRecord Medals/Match: |cffff8000%d|r", 
        lts.highMomentum or 0, lts.highObjectives or 0, lts.highWeight or 0, lts.highestMedals or 0), 
        "Interface\\Icons\\Ability_Druid_FlightForm", 1)

    BGH.scrollChild:SetHeight(math.abs(currentY))
    BGH.scrollFrame:UpdateScrollChildRect()
end

-- ==========================================
-- PAGINATION UI (The Spread)
-- ==========================================
BGFrame.currentPage = 1

local pageFrame = CreateFrame("Frame", nil, BGFrame)
pageFrame:SetSize(300, 30)
pageFrame:SetPoint("TOP", BGFrame, "TOP", 0, -56)
BGFrame.pageFrame = pageFrame

local pageText = pageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
pageText:SetPoint("CENTER", pageFrame, "CENTER", 0, 9)
pageText:SetText("Match 1 of 1")
BGFrame.pageText = pageText

local btnPrev = CreateFrame("Button", nil, pageFrame, "UIPanelButtonTemplate")
btnPrev:SetSize(30, 22)
btnPrev:SetPoint("RIGHT", pageText, "LEFT", -6, 0)
btnPrev:SetText("<")

local btnNext = CreateFrame("Button", nil, pageFrame, "UIPanelButtonTemplate")
btnNext:SetSize(30, 22)
btnNext:SetPoint("LEFT", pageText, "RIGHT", 6, 0)
btnNext:SetText(">")

local btnFirst = CreateFrame("Button", nil, pageFrame, "UIPanelButtonTemplate")
btnFirst:SetSize(30, 22)
btnFirst:SetPoint("RIGHT", btnPrev, "LEFT", 2, 0)
btnFirst:SetText("<<")

local btnLast = CreateFrame("Button", nil, pageFrame, "UIPanelButtonTemplate")
btnLast:SetSize(30, 22)
btnLast:SetPoint("LEFT", btnNext, "RIGHT", -2, 0)
btnLast:SetText(">>")

function BGFrame:UpdatePageData(skipRender)
    local historyCount = (BGHL_MatchHistory and #BGHL_MatchHistory) or 0
    local maxPages = historyCount > 0 and (historyCount + 1) or 1 

    if self.currentPage < 1 then self.currentPage = 1 end
    if self.currentPage > maxPages then self.currentPage = maxPages end

    btnFirst:SetEnabled(self.currentPage > 1)
    btnPrev:SetEnabled(self.currentPage > 1)
    btnNext:SetEnabled(self.currentPage < maxPages)
    btnLast:SetEnabled(self.currentPage < maxPages)

    if self.currentPage <= historyCount then
		if mapDropdown then mapDropdown:Hide() end
        self.pageText:SetText(string.format("   Match %d of %d   ", self.currentPage, historyCount))
        local matchData = BGHL_MatchHistory[self.currentPage]
        if matchData then
            if self.currentPage == 1 then
                self.mapText:SetText("Last Match: " .. (matchData.MapName or "Unknown"))
            else
                self.mapText:SetText("Historical Match: " .. (matchData.MapName or "Unknown"))
            end
            
            if not skipRender then
                self:ClearMedalsUI()
                if BGH.RenderMedals then BGH.RenderMedals(matchData, false) end
            end
        end
    else
        self.pageText:SetText("Lifetime Statistics")
        self.mapText:SetText("Overall Performance")
        if not skipRender then
            self:ClearMedalsUI() 
            self:RenderLifetimeStats()
        end
    end
end

btnFirst:SetScript("OnClick", function() BGFrame.currentPage = 1; PlaySound(844, "Master"); BGFrame:UpdatePageData() end)
btnPrev:SetScript("OnClick", function() BGFrame.currentPage = BGFrame.currentPage - 1; PlaySound(844, "Master"); BGFrame:UpdatePageData() end)
btnNext:SetScript("OnClick", function() BGFrame.currentPage = BGFrame.currentPage + 1; PlaySound(844, "Master"); BGFrame:UpdatePageData() end)
btnLast:SetScript("OnClick", function()
	PlaySound(844, "Master")
    local historyCount = (BGHL_MatchHistory and #BGHL_MatchHistory) or 0
    BGFrame.currentPage = historyCount > 0 and (historyCount + 1) or 1
    BGFrame:UpdatePageData() 
end)

function BGFrame:UpdateTextElements(skipRender)
    local tab = PanelTemplates_GetSelectedTab(self)
    
    if tab == 1 then
        self.pageFrame:Show()
        self:UpdatePageData(skipRender)
    elseif tab == 2 then
        self.pageFrame:Hide()
        self.mapText:SetText("Collected Medals")
    elseif tab == 3 then
        self.pageFrame:Hide()
        self.mapText:SetText("Scoring Mechanics")
    elseif tab == 4 then
        self.pageFrame:Hide()
        self.mapText:SetText("Project Development")
    elseif tab == 5 then
        self.pageFrame:Hide() 
        self.mapText:SetText("Configuration")
    end
end

-- ==========================================
-- OUT-OF-DATE ALERT POPUP
-- ==========================================
local BGHUpdateFrame = CreateFrame("Frame", "BGHighlightsUpdatePopup", UIParent, "BackdropTemplate")
BGHUpdateFrame:SetSize(420, 130)
BGHUpdateFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
BGHUpdateFrame:SetFrameStrata("DIALOG")
BGHUpdateFrame:Hide()

BGH.BGHighlightsUpdatePopup = BGHUpdateFrame

BGHUpdateFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local alertIcon = BGHUpdateFrame:CreateTexture(nil, "ARTWORK")
alertIcon:SetTexture("Interface\\Icons\\INV_Misc_Ticket_Tarot_Maelstrom_01")
alertIcon:SetSize(64, 64)
alertIcon:SetPoint("LEFT", BGHUpdateFrame, "LEFT", 24, 8)

local alertIconBorder = CreateFrame("Frame", nil, BGHUpdateFrame, "BackdropTemplate")
alertIconBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
})
alertIconBorder:SetSize(72, 72)
alertIconBorder:SetPoint("CENTER", alertIcon, "CENTER", 0, 0)

local alertText = BGHUpdateFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
alertText:SetPoint("LEFT", alertIcon, "RIGHT", 16, 8)
alertText:SetPoint("RIGHT", BGHUpdateFrame, "RIGHT", -24, 8)
alertText:SetJustifyH("LEFT")
alertText:SetText("|cffff0000Your BGHighlights AddOn is out of date!|r\n\nParticipating in a battleground while BGH is out of date will result in zero medal awards regardless of your performance.")

local alertBtn = CreateFrame("Button", nil, BGHUpdateFrame, "UIPanelButtonTemplate")
alertBtn:SetSize(120, 24)
alertBtn:SetPoint("BOTTOM", BGHUpdateFrame, "BOTTOM", 0, 16)
alertBtn:SetText("Understood")
alertBtn:SetScript("OnClick", function(self) self:GetParent():Hide() end)

-- ==========================================
-- TABS, BORDERS & SCROLL FRAMES 
-- ==========================================
local tabSpread = CreateFrame("Button", "BGHighlightsMainFrameTab1", BGFrame, "CharacterFrameTabButtonTemplate")
tabSpread:SetID(1)
tabSpread:SetText("The Spread")
tabSpread.yOffset = 78 
tabSpread:SetPoint("TOPLEFT", BGFrame, "BOTTOMLEFT", 15, tabSpread.yOffset)
PanelTemplates_TabResize(tabSpread, 0)

local tabArcana = CreateFrame("Button", "BGHighlightsMainFrameTab2", BGFrame, "CharacterFrameTabButtonTemplate")
tabArcana:SetID(2)
tabArcana:SetText("My Arcana")
tabArcana:SetPoint("LEFT", tabSpread, "RIGHT", -16, 0)
PanelTemplates_TabResize(tabArcana, 0)

local tabInfo = CreateFrame("Button", "BGHighlightsMainFrameTab3", BGFrame, "CharacterFrameTabButtonTemplate")
tabInfo:SetID(3)
tabInfo:SetText("Info")
tabInfo:SetPoint("LEFT", tabArcana, "RIGHT", -16, 0)
PanelTemplates_TabResize(tabInfo, 0)

local tabDev = CreateFrame("Button", "BGHighlightsMainFrameTab4", BGFrame, "CharacterFrameTabButtonTemplate")
tabDev:SetID(4)
tabDev:SetText("Dev")
tabDev:SetPoint("LEFT", tabInfo, "RIGHT", -16, 0)
PanelTemplates_TabResize(tabDev, 0)

BGFrame.numTabs = 4
PanelTemplates_SetNumTabs(BGFrame, 4)
PanelTemplates_SetTab(BGFrame, 1)

local settingsFrame = CreateFrame("Frame", "BGHSettingsFrame", BGFrame)
settingsFrame:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
settingsFrame:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83) 
settingsFrame:Hide()
BGH.BGHSettingsFrame = settingsFrame

local settingsHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -10)
settingsHeader:SetText("|cffffff00BROADCAST SETTINGS|r\n\nAutomatically announce your highest Major Arcana at the end of a match:")
settingsHeader:SetWidth(250)
settingsHeader:SetJustifyH("LEFT")
settingsHeader:SetWordWrap(true)

local function CreateSettingCheckbox(parent, name, labelText, yOffset, settingKey)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    _G[name.."Text"]:SetText(labelText)
    
    cb:SetScript("OnShow", function(self) self:SetChecked(BGHL_Settings[settingKey]) end)
    cb:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked() ~= nil and self:GetChecked() ~= false
        BGHL_Settings[settingKey] = isChecked
    end)
    return cb
end

local cbParty = CreateSettingCheckbox(settingsFrame, "BGHSetParty", "Party Chat", -60, "broadcastParty")
local cbRaid  = CreateSettingCheckbox(settingsFrame, "BGHSetRaid", "Battleground / Raid Chat", -85, "broadcastRaid")
local cbGuild = CreateSettingCheckbox(settingsFrame, "BGHSetGuild", "Guild Chat", -110, "broadcastGuild")

function BGH.UpdateTabColors()
    for i = 1, BGFrame.numTabs do
        local tabName = "BGHighlightsMainFrameTab"..i
        local tab = _G[tabName]
        if tab then
            local left, middle, right = _G[tabName.."Left"], _G[tabName.."Middle"], _G[tabName.."Right"]
            if i == PanelTemplates_GetSelectedTab(BGFrame) then
                if left then left:SetVertexColor(0.4, 0.1, 0.6) end
                if middle then middle:SetVertexColor(0.4, 0.1, 0.6) end
                if right then right:SetVertexColor(0.4, 0.1, 0.6) end
            else
                if left then left:SetVertexColor(1, 1, 1) end
                if middle then middle:SetVertexColor(1, 1, 1) end
                if right then right:SetVertexColor(1, 1, 1) end
            end
        end
    end
    PanelTemplates_UpdateTabs(BGFrame)
end
BGH.UpdateTabColors()

local function SkinScrollBar(scrollFrame)
    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    if not scrollBar then return end

    local trough = scrollBar:CreateTexture(nil, "BACKGROUND", nil, -1)
    trough:SetWidth(27) 
    trough:SetPoint("TOP", scrollBar, "TOP", 0, 18)
    trough:SetPoint("BOTTOM", scrollBar, "BOTTOM", 0, -16)
    trough:SetColorTexture(0, 0, 0, 0.85) 

    local topTex = scrollBar:CreateTexture(nil, "BACKGROUND", nil, 0)
    topTex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
    topTex:SetSize(31, 256)
    topTex:SetPoint("TOPLEFT", scrollBar, "TOPLEFT", -8, 21)
    topTex:SetTexCoord(0, 0.484375, 0, 1)

    local bottomTex = scrollBar:CreateTexture(nil, "BACKGROUND", nil, 0)
    bottomTex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
    bottomTex:SetSize(31, 106)
    bottomTex:SetPoint("BOTTOMLEFT", scrollBar, "BOTTOMLEFT", -8, -18)
    bottomTex:SetTexCoord(0.515625, 1.0, 0, 0.4140625)

    local middleTex = scrollBar:CreateTexture(nil, "BACKGROUND", nil, 0)
    middleTex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
    middleTex:SetWidth(31)
    middleTex:SetPoint("TOP", topTex, "BOTTOM")
    middleTex:SetPoint("BOTTOM", bottomTex, "TOP")
    middleTex:SetTexCoord(0, 0.484375, 0.75, 1) 
end

local function HookMouseWheel(frame)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        local scrollBar = _G[self:GetName() .. "ScrollBar"]
        if scrollBar then
            local step = 75 
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            local newVal = scrollBar:GetValue() - (delta * step)
            scrollBar:SetValue(math.max(minVal, math.min(maxVal, newVal)))
        end
    end)
end

-- Container 1: Match Highlights (The Spread)
local scrollFrame = CreateFrame("ScrollFrame", "BGHighlightsScrollFrame", BGFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
scrollFrame:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83) 
local scrollChild = CreateFrame("Frame", "BGHighlightsScrollChild", scrollFrame)
scrollChild:SetWidth(250)
scrollChild:SetHeight(1) 
scrollFrame:SetScrollChild(scrollChild)
SkinScrollBar(scrollFrame)
HookMouseWheel(scrollFrame)

BGH.scrollFrame = scrollFrame
BGH.scrollChild = scrollChild

-- Container 2: Achievements (My Arcana)
local arcanaScrollFrame = CreateFrame("ScrollFrame", "BGArcanaScrollFrame", BGFrame, "UIPanelScrollFrameTemplate")
arcanaScrollFrame:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
arcanaScrollFrame:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83) 
arcanaScrollFrame:Hide()
local arcanaScrollChild = CreateFrame("Frame", "BGArcanaScrollChild", arcanaScrollFrame)
arcanaScrollChild:SetWidth(250)
arcanaScrollChild:SetHeight(680) 
arcanaScrollFrame:SetScrollChild(arcanaScrollChild)
SkinScrollBar(arcanaScrollFrame)
HookMouseWheel(arcanaScrollFrame)

BGH.arcanaScrollFrame = arcanaScrollFrame

-- Container 3: Info & Legend
local infoScrollFrame = CreateFrame("ScrollFrame", "BGHInfoScrollFrame", BGFrame, "UIPanelScrollFrameTemplate")
infoScrollFrame:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
infoScrollFrame:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83) 
infoScrollFrame:Hide()
local infoScrollChild = CreateFrame("Frame", "BGHInfoScrollChild", infoScrollFrame)
infoScrollChild:SetWidth(270)
infoScrollChild:SetHeight(920) 
infoScrollFrame:SetScrollChild(infoScrollChild)
SkinScrollBar(infoScrollFrame)
HookMouseWheel(infoScrollFrame)

BGH.infoScrollFrame = infoScrollFrame

local infoText = infoScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
infoText:SetPoint("TOPLEFT", infoScrollChild, "TOPLEFT", 10, -10)
infoText:SetWidth(250)
infoText:SetJustifyH("LEFT")

local sW = BGH.ScoringWeights or { drTaxPerMedal = 15, isolationMult = 1.0, attritionMult = 5.0, vanguardMult = 0.5, triageDivisor = 1.0 }

local infoTextStr = string.format([[
|cffffff00THE SPREAD (BOARD SIZE)|r

The Tarot only reveals itself to the most influential forces on the battlefield. The maximum number of Major Arcana awarded is determined by the scale of the conflict:
|cffffffffWarsong Gulch:|r Top 3
|cffffffffArathi Basin & Eye of the Storm:|r Top 5
|cffffffffAlterac Valley:|r Top 10


|cffffff00THE DRAW (MEDAL RARITY)|r

Medals are forged in rarities based on your Final Weight ranking on the board. The rarities you have collected can be viewed in the 'My Arcana' tab.
|cffa335eeEpic:|r 1st Place
|cff0070ddRare:|r 2nd Place
|cff1eff00Uncommon:|r 3rd Place
|cffffffffCommon:|r 4th Place and below

*Whispers speak of a |cffff8000Legendary|r draw... an anomaly granted only to those whose performances shatter the scales of fate. But who can say if such myths are true?*


|cffffff00SCORING LEGEND & BREAKDOWN |r

The tooltips in The Spread transparently display the calculation for your score. The color-coded elements within the parentheses map directly to the mechanics below.


|cffffff00Combo Multiplier|r

|cff00ccffMinor Arcana:|r Grants a positive percentage weight multiplier based on exceptional combat performance.

|cffff0000Glory Tax:|r Prevents board-sweeps. You incur a |cffff0000%d%%|r diminishing returns penalty for each medal held past the first.


|cff00ccffMinor Arcana Calculations|r
Cards are drawn by exceeding the match average in four domains. The tier of the card increases based on specific percentage steps above the mean.

|cffffffffSwords (Offense):|r Max of Damage or KBs (20%% steps)

|cffffffffCups (Healing):|r Healing Output (50%% steps)

|cffffffffWands (Objectives):|r Objective Score (50%% steps)

|cffffffffCoins (Momentum):|r Momentum Score (20%% steps)

|cffffff00Card Tiers & Multipliers|r
|cffffffffAce (Tier 1) to 10:|r +1%% combo weight multiplier per tier.

|cffffffffFace Cards (11-14):|r Page, Knight, Queen, King yield accelerated growth: 10%% base + 2%% per Face Card (Up to +18%% maximum combo bonus for a King).


|cffffff00Objective Score|r

|cffffffffHard Objectives:|r Raw count of Flag/Node interactions.

|cffff8000Isolation Bonus:|r Rewards solitary defenders. 
Formula: (KBs / HKs) * sqrt(KBs) * %.1f


|cffffff00Momentum Score|r

|cffffffffHard Momentum:|r Base points from Flag Pickups/Defenses.

|cffffff00Teamfight Scalar (HKs):|r Rewards participation. Your HKs divided by the Match Average.

|cffcc00ffAttrition Bonus:|r Absorbing enemy pressure. 
Formula: (Your Deaths / Team Deaths) * %.1f

|cff00ffccHealer Momentum:|r Aggressive pushing & triage.
Vanguard: (Your Healing / Match Avg Healing) * %.2f
Triage: (Your Healing per Team Death) / (Match Healing per Match Death)
Formula: ((Vanguard Bonus) + (Triage Bonus)) / 2


|cffffff00Z-Scores (Standard Deviation)|r

Z-Scores measure how far your performance deviates from the match average.
A score of |cff00ff001.0|r means you performed exactly one standard deviation above the lobby average.
 
Formula: (Your Stat - Match Average) / Standard Deviation


|cffffff00Total Medal Weight (Positioning)|r

Medals are ranked by Total Weight. 

1. |cffffffffBase Weight:|r The sum of Z-Scores for the specific stats required by any given medal.

2. |cff00ff00Combo Impact:|r Base Weight is multiplied by your net Combo Percentage (Minor Arcana minus Glory Tax).

3. |cffff8000Padding:|r (Objectives * 0.5) and (Momentum * 0.25) are added as un-taxable flat bonuses to prioritize BG mechanics.

]], 
sW.drTaxPerMedal, 
sW.isolationMult, 
sW.attritionMult, 
sW.vanguardMult)

infoText:SetText(infoTextStr)

-- Container 4: The Dev Tab
local devFrame = CreateFrame("Frame", "BGHDevFrame", BGFrame)
devFrame:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
devFrame:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83) 
devFrame:Hide()
BGH.BGHDevFrame = devFrame

local devText = devFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
devText:SetPoint("TOPLEFT", devFrame, "TOPLEFT", 10, -10)
devText:SetWidth(250)
devText:SetJustifyH("LEFT")
devText:SetText("|cffffff00BEHIND THE VEIL|r\n\nBGHighlights is an open-source project in active development. As the scales of fate are still being balanced, your feedback, bug reports, and suggestions are critical to perfecting the Tarot.\n\n\n|cffffff00SUPPORT THE ARCHITECT|r\n\nIf you enjoy the competitive fire this AddOn brings to your battlegrounds, consider supporting its continued development! Buy me a coffee, or contribute to the open-source code below.")

local function CreateCopyBox(parent, labelText, url, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    label:SetText(labelText)

    local boxBackground = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    boxBackground:SetSize(240, 24)
    boxBackground:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    boxBackground:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    boxBackground:SetBackdropColor(0, 0, 0, 0.5)
    boxBackground:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local box = CreateFrame("EditBox", nil, boxBackground)
    box:SetFontObject("ChatFontNormal")
    box:SetPoint("TOPLEFT", boxBackground, "TOPLEFT", 8, 0)
    box:SetPoint("BOTTOMRIGHT", boxBackground, "BOTTOMRIGHT", -8, 0)
    box:SetAutoFocus(false)
    box:SetText(url)
    
    box:SetScript("OnCursorChanged", function(self) self:HighlightText() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnTextChanged", function(self, isUserInput)
        if isUserInput then self:SetText(url) self:HighlightText() end
    end)
    
    return boxBackground
end

local paypalBox = CreateCopyBox(devFrame, "Buy me a Coffee (PayPal):", "https://paypal.me/chrishammett1992", -220)
local githubBox = CreateCopyBox(devFrame, "Public GitHub Repository:", "https://github.com/chammett/BGHighlights", -280)

local spreadBackground = BGFrame:CreateTexture(nil, "ARTWORK")
spreadBackground:SetDrawLayer("ARTWORK", 1) 
spreadBackground:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
spreadBackground:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83)
spreadBackground:SetTexture("Interface\\AddOns\\BGHighlights\\Media\\spread_bg.tga")
spreadBackground:SetTexCoord(0, 260/512, 0, 420/512)
spreadBackground:SetAlpha(0.5)
BGH.spreadBackground = spreadBackground

local arcanaBackground = BGFrame:CreateTexture(nil, "ARTWORK")
arcanaBackground:SetDrawLayer("ARTWORK", 1) 
arcanaBackground:SetPoint("TOPLEFT", BGFrame, "TOPLEFT", 22, -74)
arcanaBackground:SetPoint("BOTTOMRIGHT", BGFrame, "BOTTOMRIGHT", -66, 83)
arcanaBackground:SetTexture("Interface\\AddOns\\BGHighlights\\Media\\arcana_bg.tga")
arcanaBackground:SetTexCoord(0, 260/512, 0, 420/512)
arcanaBackground:SetAlpha(0.5)
arcanaBackground:Hide()
BGH.arcanaBackground = arcanaBackground

settingsBtn:SetScript("OnClick", function()
	PlaySound(841, "Master")
    local currentTab = PanelTemplates_GetSelectedTab(BGFrame)
    
    if currentTab == 5 then
        local goBackTo = BGFrame.previousTab or 1
        local tabBtn = _G["BGHighlightsMainFrameTab" .. goBackTo]
        if tabBtn and tabBtn:HasScript("OnClick") then tabBtn:GetScript("OnClick")(tabBtn) end
    else
        BGFrame.previousTab = currentTab
        PanelTemplates_SetTab(BGFrame, 5)
        BGH.UpdateTabColors()
        
        for i = 1, BGFrame.numTabs do
            local t = _G["BGHighlightsMainFrameTab" .. i]
            if t then PanelTemplates_DeselectTab(t) end
        end
        
        scrollFrame:Hide()
        arcanaScrollFrame:Hide()
        infoScrollFrame:Hide()
        devFrame:Hide()
        spreadBackground:Hide()
        arcanaBackground:Hide()
        
        BGFrame:UpdateTextElements()
        settingsFrame:Show()
    end
end)

-- ==========================================
-- ARCANA ACHIEVEMENTS UI (THE GRID)
-- ==========================================
local arcanaButtons = {}
local minorButtons = {}

local function InitializeArcanaUI()
    if #arcanaButtons > 0 then return end 

    -- MAJOR ARCANA HEADER
    local majorHeader = arcanaScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    majorHeader:SetPoint("TOP", arcanaScrollChild, "TOPLEFT", 148, -15)
    majorHeader:SetText("Major Arcana")

    local majorDivider = arcanaScrollChild:CreateTexture(nil, "ARTWORK")
    majorDivider:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")
    majorDivider:SetSize(300, 16)
    majorDivider:SetPoint("TOP", majorHeader, "BOTTOM", 40, -4)

    local xOffset, yOffset = 70, -50
    local colSpacing, rowSpacing = 120, 60
    local registry = BGH.MedalRegistry or {}
    local lastY = 0

    for i, data in ipairs(registry) do
        local col = (i - 1) % 2 
        local row = math.floor((i - 1) / 2)
        local xPos = xOffset + (col * colSpacing)
        local yPos = yOffset - (row * rowSpacing)
        lastY = yPos

        local iconButton = CreateFrame("Button", nil, arcanaScrollChild)
        iconButton:SetSize(36, 36)
        iconButton:SetPoint("TOPLEFT", arcanaScrollChild, "TOPLEFT", xPos, yPos)
        
        local iconTexture = iconButton:CreateTexture(nil, "BACKGROUND")
        iconTexture:SetAllPoints(iconButton)
        iconTexture:SetTexture(data.icon)
        iconButton.icon = iconTexture 

        local countString = iconButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        countString:SetPoint("TOP", iconButton, "BOTTOM", 0, -2)
        iconButton.countText = countString 

        iconButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(data.title, 1, 0.82, 0) 
            GameTooltip:AddLine(data:GetReqText(), 1, 1, 1, true) 
            
            local earnedData = BGHL_PlayerMedals and BGHL_PlayerMedals[data.title]
            local isEarned = false
            if type(earnedData) == "table" and (earnedData.total or 0) > 0 then isEarned = true
            elseif type(earnedData) ~= "table" and (tonumber(earnedData) or 0) > 0 then isEarned = true end

            if isEarned then
                local c = type(earnedData) == "table" and earnedData.common or tonumber(earnedData) or 0
                local u = type(earnedData) == "table" and earnedData.uncommon or 0
                local r = type(earnedData) == "table" and earnedData.rare or 0
                local e = type(earnedData) == "table" and earnedData.epic or 0
                local l = type(earnedData) == "table" and earnedData.legendary or 0
                
                local rarityString = string.format("Awarded as: |cffffffff%d|r   |cff1eff00%d|r   |cff0070dd%d|r   |cffa335ee%d|r", c, u, r, e)
                if l > 0 then rarityString = rarityString .. string.format("   |cffff8000%d|r", l) end
                GameTooltip:AddLine(rarityString)
            else
                GameTooltip:AddLine("Not yet earned", 0.5, 0.5, 0.5)
            end
            GameTooltip:Show()
        end)

        iconButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(arcanaButtons, iconButton)
    end

    -- MINOR ARCANA HEADER
    local minorHeader = arcanaScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minorHeader:SetPoint("TOP", arcanaScrollChild, "TOPLEFT", 148, lastY - 60)
    minorHeader:SetText("Minor Arcana")

    local minorDivider = arcanaScrollChild:CreateTexture(nil, "ARTWORK")
    minorDivider:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")
    minorDivider:SetSize(300, 16)
    minorDivider:SetPoint("TOP", minorHeader, "BOTTOM", 40, -4)

    local minorReg = BGH.MinorRegistry or {}
    local startX = 60
    local spacing = 50

    for i, data in ipairs(minorReg) do
        local iconButton = CreateFrame("Button", nil, arcanaScrollChild)
        iconButton:SetSize(36, 36)
        iconButton:SetPoint("TOPLEFT", arcanaScrollChild, "TOPLEFT", startX + ((i - 1) * spacing), lastY - 95)
        
        local iconTexture = iconButton:CreateTexture(nil, "BACKGROUND")
        iconTexture:SetAllPoints(iconButton)
        iconTexture:SetTexture(data.icon)
        iconButton.icon = iconTexture 

        local countString = iconButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        countString:SetPoint("TOP", iconButton, "BOTTOM", 0, -2)
        iconButton.countText = countString 

        iconButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(data.title, 1, 0.82, 0) 
            GameTooltip:AddLine(data.desc, 1, 1, 1, true) 
            GameTooltip:AddLine(" ")
            
            local lts = BGHL_LifetimeStats and BGHL_LifetimeStats.Overall
            local highestMinor = lts and lts.highestMinor and lts.highestMinor[data.suit] or 0
            
            if highestMinor > 0 then
                local faces = { [11]="Page", [12]="Knight", [13]="Queen", [14]="King" }
                local rankStr = highestMinor == 1 and "Ace" or (highestMinor <= 10 and tostring(highestMinor) or (faces[highestMinor] or "King"))
                
                local color = highestMinor == 1 and "|cff00ff00" or (highestMinor <= 10 and "|cff0070dd" or "|cffa335ee")
                GameTooltip:AddLine("Highest Drawn: " .. color .. rankStr .. " of " .. data.suit .. "|r")
            else
                GameTooltip:AddLine("Highest Drawn: |cff777777None|r")
            end
            GameTooltip:Show()
        end)
        iconButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(minorButtons, iconButton)
    end
    
    arcanaScrollChild:SetHeight(math.abs(lastY - 160))
end

function BGH.UpdateArcanaUI()
    InitializeArcanaUI()
    if type(BGHL_PlayerMedals) ~= "table" then BGHL_PlayerMedals = {} end
    
    local registry = BGH.MedalRegistry or {}
    for i, data in ipairs(registry) do
        local earnedData = BGHL_PlayerMedals[data.title]
        local count = type(earnedData) == "table" and (earnedData.total or 0) or (tonumber(earnedData) or 0)
        
        local btn = arcanaButtons[i]
        if btn then
            if count == 0 then
                btn.icon:SetDesaturated(true)
                btn.countText:SetText("|cff7777770|r")
            else
                btn.icon:SetDesaturated(false)
                btn.countText:SetText("|cffffff00" .. count .. "|r")
            end
        end
    end

    local minorReg = BGH.MinorRegistry or {}
    local lts = BGHL_LifetimeStats and BGHL_LifetimeStats.Overall
    local faces = { [11]="P", [12]="Kn", [13]="Q", [14]="K" }
    
    local function GetShortRankStr(tier)
        if tier == 1 then return "A" end
        if tier <= 10 then return tostring(tier) end
        return faces[tier] or "K"
    end

    for i, data in ipairs(minorReg) do
        local btn = minorButtons[i]
        if btn then
            local rank = lts and lts.highestMinor and lts.highestMinor[data.suit] or 0
            if rank == 0 then
                btn.icon:SetDesaturated(true)
                btn.countText:SetText("|cff777777-|r")
            else
                btn.icon:SetDesaturated(false)
                local color = rank == 1 and "|cff00ff00" or (rank <= 10 and "|cff0070dd" or "|cffa335ee")
                btn.countText:SetText(color .. GetShortRankStr(rank) .. "|r")
            end
        end
    end
end

tabSpread:SetScript("OnClick", function()
	PlaySound(841, "Master")
    PanelTemplates_SetTab(BGFrame, 1)
    BGH.UpdateTabColors()
    arcanaScrollFrame:Hide()
    infoScrollFrame:Hide()
    arcanaBackground:Hide()
	devFrame:Hide()
    spreadBackground:Show()
    scrollFrame:Show()
    BGFrame:UpdateTextElements()
	settingsFrame:Hide()
end)

tabArcana:SetScript("OnClick", function()
	PlaySound(841, "Master")
    PanelTemplates_SetTab(BGFrame, 2)
    BGH.UpdateTabColors()
    scrollFrame:Hide()
    infoScrollFrame:Hide()
	devFrame:Hide()
    spreadBackground:Hide()
    arcanaScrollFrame:Show()
    BGH.UpdateArcanaUI()
    arcanaBackground:Show()
    BGFrame:UpdateTextElements()
	settingsFrame:Hide()
end)

tabInfo:SetScript("OnClick", function()
	PlaySound(841, "Master")
    PanelTemplates_SetTab(BGFrame, 3)
    BGH.UpdateTabColors()
    scrollFrame:Hide()
    arcanaScrollFrame:Hide()
    spreadBackground:Hide()
    arcanaBackground:Hide()
	devFrame:Hide()
    infoScrollFrame:Show()
	BGFrame:UpdateTextElements()
	settingsFrame:Hide()
end)

tabDev:SetScript("OnClick", function()
	PlaySound(841, "Master")
    PanelTemplates_SetTab(BGFrame, 4)
    BGH.UpdateTabColors()
    scrollFrame:Hide()
    arcanaScrollFrame:Hide()
    infoScrollFrame:Hide()
    spreadBackground:Hide()
    arcanaBackground:Hide()
    devFrame:Show()
    BGFrame:UpdateTextElements()
	settingsFrame:Hide()
end)

-- ==========================================
-- MEDAL ROW GENERATOR
-- ==========================================
function BGH.UpdateOrCreateMedalRow(index, parent, medal, rankColor)
    local medalFrame = BGH.MedalFramePool[index]
    
    if not medalFrame then
        medalFrame = CreateFrame("Button", nil, parent, "BackdropTemplate")
        medalFrame:SetWidth(240)
        
        medalFrame.iconButton = CreateFrame("Button", nil, medalFrame)
        medalFrame.iconButton:SetSize(40, 40)
        medalFrame.iconButton:SetPoint("TOPLEFT", medalFrame, "TOPLEFT", 8, -8)
        
        medalFrame.iconTexture = medalFrame.iconButton:CreateTexture(nil, "BACKGROUND")
        medalFrame.iconTexture:SetAllPoints(medalFrame.iconButton)
        
        medalFrame.titleString = medalFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        medalFrame.titleString:SetPoint("TOPLEFT", medalFrame.iconButton, "TOPRIGHT", 10, -2)
        
        medalFrame.descString = medalFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        medalFrame.descString:SetPoint("TOPLEFT", medalFrame.titleString, "BOTTOMLEFT", 0, -4)
        medalFrame.descString:SetWidth(165)
        medalFrame.descString:SetJustifyH("LEFT")
        medalFrame.descString:SetWordWrap(true)
        
        medalFrame.glow = medalFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
        medalFrame.glow:SetPoint("TOPLEFT", medalFrame, "TOPLEFT", 4, -4)
        medalFrame.glow:SetPoint("BOTTOMRIGHT", medalFrame, "BOTTOMRIGHT", -4, 4)
        medalFrame.glow:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        medalFrame.glow:SetVertexColor(1.0, 0.5, 0.0)
        medalFrame.glow:SetBlendMode("ADD")
        medalFrame.glow:Hide()
        
        local animGroup = medalFrame.glow:CreateAnimationGroup()
        animGroup:SetLooping("REPEAT")
        local fadeOut = animGroup:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(0.65); fadeOut:SetToAlpha(0.15); fadeOut:SetDuration(1.5); fadeOut:SetOrder(1)
        local fadeIn = animGroup:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.15); fadeIn:SetToAlpha(0.65); fadeIn:SetDuration(1.5); fadeIn:SetOrder(2)
        medalFrame.glow.animGroup = animGroup

        local socketAnim = medalFrame.glow:CreateAnimationGroup()
        socketAnim:SetLooping("NONE")
        local socketFade = socketAnim:CreateAnimation("Alpha")
        socketFade:SetFromAlpha(0.85)
        socketFade:SetToAlpha(0.0)
        socketFade:SetDuration(1.5)
        socketFade:SetOrder(1)
        socketAnim:SetScript("OnFinished", function() medalFrame.glow:Hide() end)
        medalFrame.socketAnim = socketAnim

        BGH.MedalFramePool[index] = medalFrame
    end
    
    medalFrame:Show() 
    medalFrame.glow:Hide()
    medalFrame.glow.animGroup:Stop()
    if medalFrame.socketAnim then medalFrame.socketAnim:Stop() end -- Stop old socket anims from pool
    
    medalFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    if rankColor == "LEGENDARY" then
        medalFrame:SetBackdropBorderColor(1.0, 0.5, 0.0, 1) 
        medalFrame:SetBackdropColor(1.0, 0.5, 0.0, 0.25)
        medalFrame.glow:SetVertexColor(1.0, 0.5, 0.0)
        medalFrame.glow:Show()
        medalFrame.glow.animGroup:Play()
    elseif rankColor == 1 then
        medalFrame:SetBackdropBorderColor(0.64, 0.21, 0.93, 1) 
        medalFrame:SetBackdropColor(0.64, 0.21, 0.93, 0.15) 
        medalFrame.glow:SetVertexColor(0.64, 0.21, 0.93)   
    elseif rankColor == 2 then
        medalFrame:SetBackdropBorderColor(0.0, 0.44, 0.87, 1)  
        medalFrame:SetBackdropColor(0.0, 0.44, 0.87, 0.15)
        medalFrame.glow:SetVertexColor(0.0, 0.44, 0.87)
    elseif rankColor == 3 then
        medalFrame:SetBackdropBorderColor(0.12, 1.0, 0.0, 1)   
        medalFrame:SetBackdropColor(0.12, 1.0, 0.0, 0.15)
        medalFrame.glow:SetVertexColor(0.12, 1.0, 0.0)
    elseif rankColor == 0 then
        medalFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        medalFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.15)
        medalFrame.glow:SetVertexColor(0.5, 0.5, 0.5)
    else
        medalFrame:SetBackdropBorderColor(1, 1, 1, 1)          
        medalFrame:SetBackdropColor(1, 1, 1, 0.05)
        medalFrame.glow:SetVertexColor(1, 1, 1)
    end

    if medal.icon == "PORTRAIT" then
        SetPortraitTexture(medalFrame.iconTexture, "player")
        medalFrame.iconTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
    else
        medalFrame.iconTexture:SetTexture(medal.icon)
        medalFrame.iconTexture:SetTexCoord(0, 1, 0, 1)
    end

    medalFrame.titleString:SetText(medal.title)
    medalFrame.descString:SetText(medal.desc)
    
    local textHeight = medalFrame.descString:GetStringHeight()
    local calculatedHeight = math.max(60, textHeight + 35) 
    medalFrame:SetHeight(calculatedHeight)

    local function ShowMedalTooltip(self)
        GameTooltip:SetOwner(medalFrame, "ANCHOR_RIGHT")
        GameTooltip:AddLine(string.format("|cffffff00%s|r - |cffffff00%s|r", medal.title, medal.displayName or medal.playerName))
        
        local comboParts = {}
        if (medal.minorBuffPctTotal or 0) > 0 then table.insert(comboParts, string.format("+|cff00ccff%d%%|r", medal.minorBuffPctTotal)) end
        if (medal.taxPct or 0) < 0 then table.insert(comboParts, string.format("-|cffff0000%d%%|r", math.abs(medal.taxPct))) end
        local comboBreakdown = #comboParts > 0 and string.format(" (%s)", table.concat(comboParts, " ")) or ""
        local comboColor = (medal.comboPct or 0) >= 0 and "|cff00ff00" or "|cffff0000"
        GameTooltip:AddLine(string.format("|cffffff00Combo|r: %s%d%%|r%s", comboColor, medal.comboPct or 0, comboBreakdown))
        
        local objBreakdown = string.format(" (|cffffffff%.1f|r + |cffff8000%.1f|r)", medal.objHard or 0, medal.objIso or 0)
        GameTooltip:AddLine(string.format("|cffffff00Objectives|r: |cff00ff00%.1f|r%s", medal.objScore or 0, objBreakdown))
        
        local momBreakdown = string.format(" (|cffffffff%.1f|r + |cffffff00%.1f|r + |cffcc00ff%.1f|r + |cff00ffcc%.1f|r)", medal.momHard or 0, medal.momHK or 0, medal.momAttr or 0, medal.momHeal or 0)
        GameTooltip:AddLine(string.format("|cffffff00Momentum|r: |cff00ff00%.1f|r%s", medal.momScore or 0, momBreakdown))
        
        if medal.baseWeight and medal.weight then
            local comboImpact = (medal.scaledBase or 0) - medal.baseWeight
            local comboImpactStr = ""
            
            if comboImpact >= 0 then
                comboImpactStr = string.format("+ |cff00ff00%.2f|r", comboImpact)
            else
                comboImpactStr = string.format("- |cffff0000%.2f|r", math.abs(comboImpact))
            end
            
            local weightBreakdown = string.format(" (|cffffffff%.2f|r %s + |cffff8000%.2f|r)", medal.baseWeight, comboImpactStr, medal.padding or 0)
            GameTooltip:AddLine(string.format("|cffffff00Medal Weight|r: |cff00ff00%.2f|r%s", medal.weight, weightBreakdown))
        end
        
        if medal.minorCards and #medal.minorCards > 0 then
            GameTooltip:AddLine(" ") 
            GameTooltip:AddLine("|cff00ccffMinor Arcana Drawn:|r")
            for _, card in ipairs(medal.minorCards) do
                GameTooltip:AddLine(string.format("|cff00ccff%s|r (+%d%%)", card.name, card.buff * 100))
                GameTooltip:AddLine(card.reason, 0.8, 0.8, 0.8, true) 
            end
        end

        GameTooltip:Show()
    end
    
    local function HideMedalTooltip() GameTooltip:Hide() end
    
    local function OnMedalClick()
        if IsShiftKeyDown() then
            local cleanDesc = medal.desc:gsub("|c%x%x%x%x%x%x%x%x", "")
            cleanDesc = cleanDesc:gsub("|r", "")
            local linkText = string.format("[%s] - %s", medal.title, cleanDesc)
            
            if ChatFrame1EditBox and ChatFrame1EditBox:IsVisible() then
                ChatFrame1EditBox:Insert(linkText)
            else
                ChatFrame_OpenChat(linkText)
            end
        end
    end

    medalFrame:SetScript("OnClick", OnMedalClick)
    medalFrame.iconButton:SetScript("OnClick", OnMedalClick)
    medalFrame:SetScript("OnEnter", ShowMedalTooltip)
    medalFrame:SetScript("OnLeave", HideMedalTooltip)
    medalFrame.iconButton:SetScript("OnEnter", ShowMedalTooltip)
    medalFrame.iconButton:SetScript("OnLeave", HideMedalTooltip)

    return medalFrame
end

function BGFrame:ClearMedalsUI()
    for _, frame in pairs(BGH.MedalFramePool) do
        if frame then
            frame:Hide()
        end
    end
end

-- ==========================================
-- MINIMAP BUTTON
-- ==========================================
local minimapBtn = CreateFrame("Button", "BGHighlightsMinimapButton", Minimap)
minimapBtn:SetSize(32, 32)
minimapBtn:SetMovable(true)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)

local minimapIcon = minimapBtn:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetTexture("Interface\\Icons\\INV_Misc_Ticket_Tarot_Maelstrom_01")
minimapIcon:SetSize(21, 21)
minimapIcon:SetPoint("TOPLEFT", 6, -6)

local minimapBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT")

minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local function UpdateMinimapButton()
    local xpos, ypos = GetCursorPosition()
    local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
    local scale = Minimap:GetEffectiveScale()
    
    xpos = (xpos / scale) - xmin - (Minimap:GetWidth() / 2)
    ypos = (ypos / scale) - ymin - (Minimap:GetHeight() / 2)
    
    local angle = math.atan2(ypos, xpos)
    
    if type(BGHL_PlayerMedals) ~= "table" then BGHL_PlayerMedals = {} end
    BGHL_PlayerMedals.minimapAngle = angle
    
    local radius = 80
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", UpdateMinimapButton) end)
minimapBtn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("BGHighlights", 1, 0.82, 0)
    GameTooltip:AddLine("|cffffff00Left-Click|r or type |cffffff00/bgh|r to view The Spread and your Arcana.", 1, 1, 1)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

minimapBtn:SetScript("OnClick", function()

	PlaySound(841, "Master")
	if type(BGHL_MatchHistory) ~= "table" then 
        BGHL_MatchHistory = {} 
        if type(BGHL_LastMatchData) == "table" and BGHL_LastMatchData.MapName then
            table.insert(BGHL_MatchHistory, BGHL_LastMatchData)
        end
    end
	
    if type(BGHL_LastMatchData) ~= "table" then BGHL_LastMatchData = {} end
    if type(BGHL_MatchHistory) ~= "table" then BGHL_MatchHistory = {} end
    if type(BGHL_Settings) ~= "table" then 
        BGHL_Settings = { broadcastParty = false, broadcastRaid = false, broadcastGuild = false } 
    end
    if type(BGHL_LifetimeStats) ~= "table" then
        BGHL_LifetimeStats = {
            matchesPlayed = 0, totalMedals = 0, sumWeight = 0, sumMomentum = 0, sumObjectives = 0,
            highWeight = 0, highMomentum = 0, highObjectives = 0,
            highestMinor = { Swords = 0, Cups = 0, Wands = 0, Coins = 0, highestMedals = 0 }
        }
    end

    if BGFrame:IsShown() then
        BGFrame:Hide()
    else
        BGFrame.currentPage = 1 
        PanelTemplates_SetTab(BGFrame, 1)
        BGH.UpdateTabColors()
		settingsFrame:Hide()
        
        arcanaScrollFrame:Hide()
        infoScrollFrame:Hide()
        devFrame:Hide()
        arcanaBackground:Hide()
        spreadBackground:Show()
        
        scrollFrame:Show()
        BGFrame:UpdateTextElements()
        BGFrame:Show()
    end
end)

local MinimapLoader = CreateFrame("Frame")
MinimapLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
MinimapLoader:SetScript("OnEvent", function()
    local angle = (type(BGHL_PlayerMedals) == "table" and BGHL_PlayerMedals.minimapAngle) or 3.14 
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end)