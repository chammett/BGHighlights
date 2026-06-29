local addonName, BGH = ...

-- ==========================================
-- 6.1. VERSION CONTROL & NETWORK ENFORCER
-- ==========================================

-- SHIFT TO NAMESPACE: Global State tracking flags
BGH.IsKillSwitched = false
BGH.InspectCache = BGH.InspectCache or {}

local highestKnownVersion = BGH.VERSION_CODE
local CACHE_DURATION = 180 -- seconds

-- Visual Alert Utility for the Outdated User
local function TriggerVersionAlert(latestStr)
    print("|cffff0000==================================================|r")
    print("|cffff0000[BGH CRITICAL ALERT]: Your version of BGHighlights is outdated!|r")
    print(string.format("|cffffffffActive Match Medal generation has been disabled. Please update to |cff00ff00v%s|cffffffff.|r", latestStr))
    print("|cffff0000==================================================|r")
    
    if RaidNotice_AddMessage then
        RaidNotice_AddMessage(RaidWarningFrame, "|cffff0000[BGH Outdated] Medal Processing Frozen! Please Update!|r", ChatTypeInfo["RAID_WARNING"])
    end
    
    -- SHIFT TO NAMESPACE: Pull the UI frame from UI.lua
    if BGH.BGHighlightsUpdatePopup then
        BGH.BGHighlightsUpdatePopup:Show()
    end
end

-- ==========================================
-- 6.2. DEV TOOL: Version Update Tester
-- ==========================================
SLASH_BGHUPDATE1 = "/bghupdate"
SlashCmdList["BGHUPDATE"] = function()
    BGH.IsKillSwitched = false 
    TriggerVersionAlert("9.9.9-DEV")
end

-- Outbound Handshake Broadcasts
local function BroadcastLocalVersion()
    if IsInInstance() then
        local _, instanceType = IsInInstance()
        if instanceType == "pvp" then
            -- SHIFT TO NAMESPACE: Pulls version and checksum from Init.lua
            local payload = BGH.VERSION_CODE .. ":" .. BGH.VERSION_STR
            local signature = BGH.GenerateChecksum(payload)
            
            C_ChatInfo.SendAddonMessage("BGH", "V_REQ:" .. payload .. ":" .. signature, "INSTANCE_CHAT")
        end
    end
end

-- Version Mismatch Detection
local VersionWatcher = CreateFrame("Frame")
VersionWatcher:RegisterEvent("PLAYER_LOGIN")
VersionWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

VersionWatcher:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(3.0, function()
            BroadcastLocalVersion()
            if IsInGuild() then
                C_ChatInfo.SendAddonMessage("BGH", "V_REQ:" .. BGH.VERSION_CODE .. ":" .. BGH.VERSION_STR, "GUILD")
            end
        end)
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            C_Timer.After(3.0, function()
                BroadcastLocalVersion()
            end)
        end
    end
end)

-- ==========================================
-- 6.3. INSPECT COMMUNICATION PROTOCOL
-- ==========================================
C_ChatInfo.RegisterAddonMessagePrefix("BGH")

-- ==========================================
-- 6.4. SERIALIZATION (Compression)
-- ==========================================
local function SerializeMedals()
    local parts = {}
    local lastNonZero = 0
    
    if type(BGHL_PlayerMedals) ~= "table" then BGHL_PlayerMedals = {} end
    
    for i, data in ipairs(BGH.MedalRegistry) do
        local earnedData = BGHL_PlayerMedals[data.title]
        if type(earnedData) == "table" and (earnedData.total or 0) > 0 then
            parts[i] = string.format("%d,%d,%d,%d,%d", 
                earnedData.common or 0, earnedData.uncommon or 0, 
                earnedData.rare or 0, earnedData.epic or 0, earnedData.legendary or 0)
            lastNonZero = i
        else
            local oldVal = tonumber(earnedData) or 0
            if oldVal > 0 then
                parts[i] = string.format("%d,0,0,0,0", oldVal)
                lastNonZero = i
            else
                parts[i] = "0"
            end
        end
    end
    
    local compressedParts = {}
    for i = 1, lastNonZero do table.insert(compressedParts, parts[i]) end
    local medalPayload = table.concat(compressedParts, ":")

    -- NEW: Serialize Lifetime Stats
    local lts = (BGHL_LifetimeStats and BGHL_LifetimeStats.Overall) or {}
    local m = lts.highestMinor or {}
    local lifetimePayload = string.format("%d,%d,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%d,%d,%d,%d,%d",
        lts.matchesPlayed or 0, lts.totalMedals or 0, lts.sumMomentum or 0, 
        lts.sumObjectives or 0, lts.sumWeight or 0, lts.highMomentum or 0, 
        lts.highObjectives or 0, lts.highWeight or 0, lts.highestMedals or 0, 
        m.Swords or 0, m.Cups or 0, m.Wands or 0, m.Coins or 0)

    return medalPayload .. "|" .. lifetimePayload
end

local function DeserializeMedals(payload)
    local medalPayload, lifetimePayload = strsplit("|", payload)
    local parsedMedals = {}
    local rawCounts = {strsplit(":", medalPayload or "")} 
    
    for i, data in ipairs(BGH.MedalRegistry) do
        local rawString = rawCounts[i] or "0"
        if rawString == "0" then
            parsedMedals[data.title] = { total = 0, common = 0, uncommon = 0, rare = 0, epic = 0, legendary = 0 }
        else
            local c, u, r, e, l = strsplit(",", rawString)
            parsedMedals[data.title] = {
                total = (tonumber(c) or 0) + (tonumber(u) or 0) + (tonumber(r) or 0) + (tonumber(e) or 0) + (tonumber(l) or 0),
                common = tonumber(c) or 0, uncommon = tonumber(u) or 0, rare = tonumber(r) or 0,
                epic = tonumber(e) or 0, legendary = tonumber(l) or 0
            }
        end
    end

    -- NEW: Deserialize Lifetime Stats
    local parsedLifetime = {}
    if lifetimePayload then
        local mp, tm, sm, so, sw, hm, ho, hw, hmed, swd, cup, wnd, coi = strsplit(",", lifetimePayload)
        parsedLifetime = {
            matchesPlayed = tonumber(mp) or 0, totalMedals = tonumber(tm) or 0,
            sumMomentum = tonumber(sm) or 0, sumObjectives = tonumber(so) or 0,
            sumWeight = tonumber(sw) or 0, highMomentum = tonumber(hm) or 0,
            highObjectives = tonumber(ho) or 0, highWeight = tonumber(hw) or 0,
            highestMedals = tonumber(hmed) or 0,
            highestMinor = { Swords = tonumber(swd) or 0, Cups = tonumber(cup) or 0, Wands = tonumber(wnd) or 0, Coins = tonumber(coi) or 0 }
        }
    end

    return { medals = parsedMedals, lifetime = parsedLifetime }
end

-- ==========================================
-- 6.5. TRANSMIT & RECEIVE
-- ==========================================
function BGHL_RequestInspectData(targetPlayer)
    local cleanName = strsplit("-", targetPlayer)
    
    local cached = BGH.InspectCache[cleanName]
    if cached and (GetTime() - cached.timestamp < CACHE_DURATION) then
        print("BGH: Loading " .. cleanName .. "'s Arcana from cache!")
        if BGHL_OnInspectDataReceived then
            BGHL_OnInspectDataReceived(cleanName, cached.data)
        end
        return
    end

    C_ChatInfo.SendAddonMessage("BGH", "REQ", "WHISPER", targetPlayer)
end

local CommFrame = CreateFrame("Frame")
CommFrame:RegisterEvent("CHAT_MSG_ADDON")
CommFrame:SetScript("OnEvent", function(self, event, prefix, text, channel, sender)
    if prefix ~= "BGH" then return end
	
local cmd, vCode, vStr, receivedSignature = string.match(text, "^([^:]+):([^:]+):([^:]+):([^:]+)$")

if cmd == "V_REQ" or cmd == "V_ALERT" then
    local payload = vCode .. ":" .. vStr
    local expectedSignature = BGH.GenerateChecksum(payload)
    
    if receivedSignature ~= expectedSignature then return end

    local senderVersionCode = tonumber(vCode) or 0
    
    if senderVersionCode > highestKnownVersion then
        highestKnownVersion = senderVersionCode
        
        if not BGH.IsKillSwitched then
            BGH.IsKillSwitched = true
            TriggerVersionAlert(vStr)
        end
        
    elseif senderVersionCode < BGH.VERSION_CODE then
        local myPayload = BGH.VERSION_CODE .. ":" .. BGH.VERSION_STR
        local mySignature = BGH.GenerateChecksum(myPayload)
        C_ChatInfo.SendAddonMessage("BGH", "V_ALERT:" .. myPayload .. ":" .. mySignature, "WHISPER", sender)
    end
end
    
    local cleanSender = strsplit("-", sender)
    local localPlayer = strsplit("-", UnitName("player"))
    
    if cleanSender == localPlayer then return end

    if text == "REQ" then
        local payload = "DAT:" .. SerializeMedals()
        C_ChatInfo.SendAddonMessage("BGH", payload, "WHISPER", sender)
        
    elseif string.sub(text, 1, 4) == "DAT:" then
        local payloadString = string.sub(text, 5)
        local parsedData = DeserializeMedals(payloadString)
        
        BGH.InspectCache[cleanSender] = {
            timestamp = GetTime(),
            data = parsedData
        }
        
        if BGHL_OnInspectDataReceived then
            BGHL_OnInspectDataReceived(cleanSender, parsedData)
        end
    end
end)

-- ==========================================
-- 6.6. INSPECT UI INTEGRATION & TAB HOOK
-- ==========================================
local BGHInspectFrame = nil
local inspectTimeoutTimer = nil
local inspectGridButtons = {}

function BGHL_OnInspectDataReceived(playerName, data)
    if not BGHInspectFrame or not BGHInspectFrame:IsShown() then return end
    
	local inspectUnit = (InspectFrame and InspectFrame.unit) or "target"
    local currentTargetName = UnitName(inspectUnit)
	
	if not currentTargetName then return end
    
    local cleanTargetName = strsplit("-", currentTargetName)
    if playerName ~= cleanTargetName then 
        return 
    end
	
    if inspectTimeoutTimer and not inspectTimeoutTimer:IsCancelled() then
        inspectTimeoutTimer:Cancel()
    end
    
    BGHInspectFrame.fallbackText:Hide()
	BGHInspectFrame.pageFrame:Show()
    
	-- Dynamically hide old inspect stats to prevent data bleed between targets
    local poolIndex = 100
    while BGH.MedalFramePool[poolIndex] do
        BGH.MedalFramePool[poolIndex]:Hide()
        poolIndex = poolIndex + 1
    end
	
    -- 1. Populate the Major Arcana Grid
    for i, medalData in ipairs(BGH.MedalRegistry) do
        local medalStats = data.medals and data.medals[medalData.title]
        local count = medalStats and medalStats.total or 0
        local btn = inspectGridButtons[i]
        
        if count == 0 then
            btn.icon:SetDesaturated(true)
            btn.countText:SetText("|cff7777770|r")
        else
            btn.icon:SetDesaturated(false)
            btn.countText:SetText("|cffffff00" .. count .. "|r")
        end
    end
	
	-- 2. Populate the Minor Arcana Grid
    local minorReg = BGH.MinorRegistry or {}
    local inspectLts = data.lifetime
    local faces = { [11]="P", [12]="Kn", [13]="Q", [14]="K" }
    
    local function GetShortRankStr(tier)
        if tier == 1 then return "A" end
        if tier <= 10 then return tostring(tier) end
        return faces[tier] or "K"
    end

    for i, data in ipairs(minorReg) do
        local btn = BGHInspectFrame.minorButtons and BGHInspectFrame.minorButtons[i]
        if btn then
            local rank = inspectLts and inspectLts.highestMinor and inspectLts.highestMinor[data.suit] or 0
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

    -- 2. Populate Lifetime Stats
    local lts = data.lifetime
    if lts then
        local matches = lts.matchesPlayed or 0
        local avgMedals = matches > 0 and (lts.totalMedals or 0) / matches or 0
        local avgMom = matches > 0 and (lts.sumMomentum or 0) / matches or 0
        local avgObj = matches > 0 and (lts.sumObjectives or 0) / matches or 0
        local avgWeight = matches > 0 and (lts.sumWeight or 0) / matches or 0

        local currentY = -10
        local poolIndexOffset = 100 

        local function AddStatRow(title, desc, icon, colorCode)
            local mockData = { title = title, desc = desc, icon = icon, playerName = playerName, comboPct = 0, taxPct = 0 }
            
            local frame = BGH.UpdateOrCreateMedalRow(poolIndexOffset, BGHInspectFrame.statsScrollChild, mockData, colorCode)
            poolIndexOffset = poolIndexOffset + 1
            
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
            
            frame:SetPoint("TOP", BGHInspectFrame.statsScrollChild, "TOP", 0, currentY)
            currentY = currentY - frame:GetHeight() - 10
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
        AddStatRow("Highest Minor Arcana", 
            string.format("Swords: %s\nCups: %s\nWands: %s\nCoins: %s", 
            GetRankStr(minors.Swords or 0), GetRankStr(minors.Cups or 0), GetRankStr(minors.Wands or 0), GetRankStr(minors.Coins or 0)), 
            "Interface\\Icons\\Spell_Holy_RemoveCurse", 2)

        AddStatRow("Lifetime Highs", 
            string.format("Record Momentum: |cffff8000%.1f|r\nRecord Objectives: |cffff8000%.1f|r\nRecord Weight: |cffff8000%.1f|r\nRecord Medals: |cffff8000%d|r", 
            lts.highMomentum or 0, lts.highObjectives or 0, lts.highWeight or 0, lts.highestMedals or 0), 
            "Interface\\Icons\\Ability_Druid_FlightForm", 1)

        BGHInspectFrame.statsScrollChild:SetHeight(math.abs(currentY))
        BGHInspectFrame.statsScrollFrame:UpdateScrollChildRect()
    end
    
    -- Reset to page 1 to ensure a clean slate when clicking on a new target
    BGHInspectFrame.currentPage = 1
    BGHInspectFrame.UpdatePage()
end

function BGH_StartInspectRequest()
	local inspectUnit = (InspectFrame and InspectFrame.unit) or "target"
    local targetName = UnitName(inspectUnit)
    if not targetName then return end

    BGHInspectFrame.scrollFrame:Hide()
    BGHInspectFrame.statsScrollFrame:Hide()
    BGHInspectFrame.pageFrame:Hide()
    BGHInspectFrame.bg:Hide()
    BGHInspectFrame.fallbackText:SetText("Loading Arcana Data...")
    BGHInspectFrame.fallbackText:Show()

    if inspectTimeoutTimer and not inspectTimeoutTimer:IsCancelled() then
        inspectTimeoutTimer:Cancel()
    end
    
    inspectTimeoutTimer = C_Timer.NewTimer(1.5, function()
        BGHInspectFrame.fallbackText:SetText(targetName .. " does not have BGH installed!\n\nNo medals to display.")
    end)

    BGHL_RequestInspectData(targetName)
end

local function InitializeInspectArcanaTab()
    if BGHInspectFrame then return end 

    local tab = CreateFrame("Button", "InspectFrameTab5", InspectFrame, "CharacterFrameTabButtonTemplate")
    tab:SetID(5)
    tab:SetText("Arcana")
    PanelTemplates_TabResize(tab, 0)

    PanelTemplates_SetNumTabs(InspectFrame, 5)

    BGHInspectFrame = CreateFrame("Frame", "BGHInspectMainPanel", InspectFrame)
    BGHInspectFrame:SetSize(320, 332) 
    BGHInspectFrame:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 8, -64)
    BGHInspectFrame:Hide()

    local nativeParchment = BGHInspectFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
    nativeParchment:SetAllPoints()
    nativeParchment:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Raid-Parchment")
    nativeParchment:SetTexCoord(0, 1, 0, 0.6)

    BGHInspectFrame.bg = BGHInspectFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    BGHInspectFrame.bg:SetAllPoints() 
    BGHInspectFrame.bg:SetTexture("Interface\\AddOns\\BGHighlights\\Media\\inspect_bg.tga")
    BGHInspectFrame.bg:SetTexCoord(0, 320/512, 0, 332/512) 
    BGHInspectFrame.bg:SetAlpha(0.8)
    BGHInspectFrame.bg:Hide()

    BGHInspectFrame.fallbackText = BGHInspectFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BGHInspectFrame.fallbackText:SetPoint("CENTER", BGHInspectFrame, "CENTER", 0, 0)
    BGHInspectFrame.fallbackText:SetJustifyH("CENTER")
    BGHInspectFrame.fallbackText:SetWidth(250)

    BGHInspectFrame.scrollFrame = CreateFrame("ScrollFrame", "BGHInspectScrollFrame", BGHInspectFrame, "UIPanelScrollFrameTemplate")
    BGHInspectFrame.scrollFrame:SetPoint("BOTTOMRIGHT", BGHInspectFrame, "BOTTOMRIGHT", -22, 2)
    BGHInspectFrame.scrollFrame:Hide()

    BGHInspectFrame.scrollChild = CreateFrame("Frame", "BGHInspectScrollChild", BGHInspectFrame.scrollFrame)
    BGHInspectFrame.scrollChild:SetSize(300, 620) 
    BGHInspectFrame.scrollFrame:SetPoint("TOPLEFT", BGHInspectFrame, "TOPLEFT", 2, 0)

    -- Create the new container for Lifetime Stats
    BGHInspectFrame.statsScrollFrame = CreateFrame("ScrollFrame", "BGHInspectStatsScrollFrame", BGHInspectFrame, "UIPanelScrollFrameTemplate")
    BGHInspectFrame.statsScrollFrame:SetPoint("TOPLEFT", BGHInspectFrame, "TOPLEFT", 2, 0) 
    BGHInspectFrame.statsScrollFrame:SetPoint("BOTTOMRIGHT", BGHInspectFrame, "BOTTOMRIGHT", -22, 2)
    BGHInspectFrame.statsScrollFrame:Hide()

    BGHInspectFrame.statsScrollChild = CreateFrame("Frame", "BGHInspectStatsScrollChild", BGHInspectFrame.statsScrollFrame)
    BGHInspectFrame.statsScrollChild:SetSize(300, 600)
    BGHInspectFrame.statsScrollFrame:SetScrollChild(BGHInspectFrame.statsScrollChild)

    -- Build the Pagination Frame
    BGHInspectFrame.pageFrame = CreateFrame("Frame", nil, BGHInspectFrame)
    BGHInspectFrame.pageFrame:SetSize(300, 25)
    BGHInspectFrame.pageFrame:SetPoint("BOTTOM", BGHInspectFrame, "TOP", 0, 2)

    BGHInspectFrame.pageText = BGHInspectFrame.pageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    BGHInspectFrame.pageText:SetPoint("CENTER")
    BGHInspectFrame.pageText:SetText("Arcana Collection")

    BGHInspectFrame.btnPrev = CreateFrame("Button", nil, BGHInspectFrame.pageFrame, "UIPanelButtonTemplate")
    BGHInspectFrame.btnPrev:SetSize(25, 20)
    BGHInspectFrame.btnPrev:SetPoint("RIGHT", BGHInspectFrame.pageText, "LEFT", -10, 0)
    BGHInspectFrame.btnPrev:SetText("<")

    BGHInspectFrame.btnNext = CreateFrame("Button", nil, BGHInspectFrame.pageFrame, "UIPanelButtonTemplate")
    BGHInspectFrame.btnNext:SetSize(25, 20)
    BGHInspectFrame.btnNext:SetPoint("LEFT", BGHInspectFrame.pageText, "RIGHT", 10, 0)
    BGHInspectFrame.btnNext:SetText(">")

    BGHInspectFrame.currentPage = 1

    BGHInspectFrame.UpdatePage = function()
        if BGHInspectFrame.currentPage == 1 then
            BGHInspectFrame.pageText:SetText("Arcana Collection")
            BGHInspectFrame.statsScrollFrame:Hide()
            BGHInspectFrame.scrollFrame:Show()
            BGHInspectFrame.bg:Show() -- Show spread_bg texture
            BGHInspectFrame.btnPrev:SetEnabled(false)
            BGHInspectFrame.btnNext:SetEnabled(true)
        else
            BGHInspectFrame.pageText:SetText("   Lifetime Stats   ")
            BGHInspectFrame.scrollFrame:Hide()
            BGHInspectFrame.bg:Hide() -- Reveal native parchment
            BGHInspectFrame.statsScrollFrame:Show()
            BGHInspectFrame.btnPrev:SetEnabled(true)
            BGHInspectFrame.btnNext:SetEnabled(false)
        end
    end

    BGHInspectFrame.btnPrev:SetScript("OnClick", function() BGHInspectFrame.currentPage = 1; BGHInspectFrame.UpdatePage() end)
    BGHInspectFrame.btnNext:SetScript("OnClick", function() BGHInspectFrame.currentPage = 2; BGHInspectFrame.UpdatePage() end)
	
    BGHInspectFrame.scrollFrame:SetScrollChild(BGHInspectFrame.scrollChild)
    
    local function SkinInspectScrollBar(scrollFrameName)
    local scrollFrame = _G[scrollFrameName]
    local scrollBar = _G[scrollFrameName .. "ScrollBar"]
    if not scrollBar then return end

    -- 1. Shift the entire scrollbar track UP to align with the frame's top edge
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, -14)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 12)

    -- 2. Hide Blizzard's default border textures to prevent visual bleeding
    for _, texName in ipairs({"Top", "Bottom", "Middle"}) do
        local bgTex = _G[scrollFrameName .. "ScrollBar" .. texName]
        if bgTex then bgTex:Hide() end
    end

    -- 3. Fix the Thumb Gap by shifting the buttons slightly inward over the track
    local upBtn = _G[scrollFrameName .. "ScrollBarScrollUpButton"]
    if upBtn then
        upBtn:ClearAllPoints()
        upBtn:SetPoint("BOTTOM", scrollBar, "TOP", 0, -1) -- This pushes the top cap and button up and down
    end

    local downBtn = _G[scrollFrameName .. "ScrollBarScrollDownButton"]
    if downBtn then
        downBtn:ClearAllPoints()
        downBtn:SetPoint("TOP", scrollBar, "BOTTOM", 0, 1) -- Pushes the bottom cap up and down
    end

    -- 4. Anchor the custom parchment textures directly to the buttons so they wrap perfectly
    local trough = scrollBar:CreateTexture(nil, "BACKGROUND", nil, -1)
    trough:SetWidth(27)
    trough:SetPoint("TOP", upBtn or scrollBar, "TOP", 0, 4) -- This pushes the background trough graphic up and down
    trough:SetPoint("BOTTOM", downBtn or scrollBar, "BOTTOM", 0, 0)
    trough:SetColorTexture(0, 0, 0, 0.9)

    local topTex = scrollBar:CreateTexture(nil, "BACKGROUND", nil, 0)
    topTex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
    topTex:SetSize(30, 256)
    topTex:SetPoint("TOPLEFT", upBtn or scrollBar, "TOPLEFT", -6, 4) -- This pushes the cap up without moving the button
    topTex:SetTexCoord(0, 0.484375, 0, 1)

    local bottomTex = scrollBar:CreateTexture(nil, "BACKGROUND", nil, 0)
    bottomTex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
    bottomTex:SetSize(30, 106) -- Texture for the trough border
    bottomTex:SetPoint("BOTTOMLEFT", downBtn or scrollBar, "BOTTOMLEFT", -6, -2)
    bottomTex:SetTexCoord(0.515625, 1.0, 0, 0.4140625)

    local middleTex = scrollBar:CreateTexture(nil, "BACKGROUND", nil, 0)
    middleTex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
    middleTex:SetWidth(30)
    middleTex:SetPoint("TOP", topTex, "BOTTOM")
    middleTex:SetPoint("BOTTOM", bottomTex, "TOP")
    middleTex:SetTexCoord(0, 0.484375, 0.75, 1) 
end

    -- Apply it to both frames
    SkinInspectScrollBar(BGHInspectFrame.scrollFrame:GetName())
    SkinInspectScrollBar(BGHInspectFrame.statsScrollFrame:GetName())

    local majorHeader = BGHInspectFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    majorHeader:SetPoint("TOP", BGHInspectFrame.scrollChild, "TOPLEFT", 148, -15)
    majorHeader:SetText("Major Arcana")

    local majorDivider = BGHInspectFrame.scrollChild:CreateTexture(nil, "ARTWORK")
    majorDivider:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")
    majorDivider:SetSize(300, 16)
    majorDivider:SetPoint("TOP", majorHeader, "BOTTOM", 40, -4)

    local xOffset, yOffset = 60, -50 
    local colSpacing, rowSpacing = 140, 55
    local lastY = 0

    for i, data in ipairs(BGH.MedalRegistry) do
        local col = (i - 1) % 2 
        local row = math.floor((i - 1) / 2)
        local xPos = xOffset + (col * colSpacing)
        local yPos = yOffset - (row * rowSpacing)
        lastY = yPos

        local iconButton = CreateFrame("Button", nil, BGHInspectFrame.scrollChild)
        iconButton:SetSize(36, 36)
        iconButton:SetPoint("TOPLEFT", BGHInspectFrame.scrollChild, "TOPLEFT", xPos, yPos)
        
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
            
            local targetName = UnitName(InspectFrame.unit or "target")
            if targetName then
                local cleanName = strsplit("-", targetName)
                local cached = BGH.InspectCache[cleanName]
                
                if cached and cached.data then
                    local earnedData = cached.data.medals and cached.data.medals[data.title]
                    local totalEarned = earnedData and earnedData.total or 0
                    
                    if totalEarned > 0 then
                        local l = earnedData.legendary or 0
                        local rarityString = string.format("Awarded as: |cffffffff%d|r   |cff1eff00%d|r   |cff0070dd%d|r   |cffa335ee%d|r", 
                            earnedData.common or 0, earnedData.uncommon or 0, 
                            earnedData.rare or 0, earnedData.epic or 0)
                        
                        if l > 0 then rarityString = rarityString .. string.format("   |cffff8000%d|r", l) end
                        GameTooltip:AddLine(rarityString)
                    else
                        GameTooltip:AddLine("Not yet earned", 0.5, 0.5, 0.5)
                    end
                else
                    GameTooltip:AddLine("Not yet earned", 0.5, 0.5, 0.5)
                end
            end
            GameTooltip:Show()
        end)
        
        iconButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(inspectGridButtons, iconButton)
    end

    -- MINOR ARCANA HEADER (Inspect Tab)
    local minorHeader = BGHInspectFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minorHeader:SetPoint("TOP", BGHInspectFrame.scrollChild, "TOPLEFT", 148, lastY - 60)
    minorHeader:SetText("Minor Arcana")

    local minorDivider = BGHInspectFrame.scrollChild:CreateTexture(nil, "ARTWORK")
    minorDivider:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")
    minorDivider:SetSize(300, 16)
    minorDivider:SetPoint("TOP", minorHeader, "BOTTOM", 40, -4)

    local minorReg = BGH.MinorRegistry or {}
    local startX = 60
    local spacing = 50
    BGHInspectFrame.minorButtons = {}

    for i, data in ipairs(minorReg) do
        local iconButton = CreateFrame("Button", nil, BGHInspectFrame.scrollChild)
        iconButton:SetSize(36, 36)
        iconButton:SetPoint("TOPLEFT", BGHInspectFrame.scrollChild, "TOPLEFT", startX + ((i - 1) * spacing), lastY - 95)
        
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
            
            local targetName = UnitName(InspectFrame.unit or "target")
            if targetName then
                local cleanName = strsplit("-", targetName)
                local cached = BGH.InspectCache[cleanName]
                
                local highestMinor = 0
                if cached and cached.data and cached.data.lifetime and cached.data.lifetime.highestMinor then
                    highestMinor = cached.data.lifetime.highestMinor[data.suit] or 0
                end
                
                if highestMinor > 0 then
                    local faces = { [11]="Page", [12]="Knight", [13]="Queen", [14]="King" }
                    local rankStr = highestMinor == 1 and "Ace" or (highestMinor <= 10 and tostring(highestMinor) or (faces[highestMinor] or "King"))
                    local color = highestMinor == 1 and "|cff00ff00" or (highestMinor <= 10 and "|cff0070dd" or "|cffa335ee")
                    
                    GameTooltip:AddLine("Highest Drawn: " .. color .. rankStr .. " of " .. data.suit .. "|r")
                else
                    GameTooltip:AddLine("Highest Drawn: |cff777777None|r")
                end
            end
            GameTooltip:Show()
        end)
        iconButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(BGHInspectFrame.minorButtons, iconButton)
    end
    
    BGHInspectFrame.scrollChild:SetHeight(math.abs(lastY - 160))

    tab:SetScript("OnClick", function()
        PanelTemplates_SetTab(InspectFrame, 5)
        if InspectPaperDollFrame then InspectPaperDollFrame:Hide() end
        if InspectPVPFrame then InspectPVPFrame:Hide() end
        if InspectTalentFrame then InspectTalentFrame:Hide() end
        if InspectGuildFrame then InspectGuildFrame:Hide() end
        
        BGHInspectFrame:Show()
        BGH_StartInspectRequest()
    end)

    for i = 1, 4 do
        local nativeTab = _G["InspectFrameTab"..i]
        if nativeTab then
            nativeTab:HookScript("OnClick", function()
                if BGHInspectFrame then BGHInspectFrame:Hide() end
            end)
        end
    end

    hooksecurefunc("InspectFrame_UpdateTabs", function()
        local lastVisibleTab = InspectFrameTab1
        for i = 2, 4 do
            local t = _G["InspectFrameTab"..i]
            if t and t:IsShown() then
                lastVisibleTab = t
            end
        end

        local unit = InspectFrame.unit
        if unit and UnitIsEnemy("player", unit) then
            InspectFrameTab5:Hide()
            PanelTemplates_SetNumTabs(InspectFrame, lastVisibleTab:GetID())
        else
            InspectFrameTab5:Show()
            InspectFrameTab5:ClearAllPoints()
            InspectFrameTab5:SetPoint("LEFT", lastVisibleTab, "RIGHT", -16, 0)
            PanelTemplates_SetNumTabs(InspectFrame, 5)
        end
        PanelTemplates_UpdateTabs(InspectFrame)
    end)

    InspectFrame:HookScript("OnHide", function()
        if BGHInspectFrame then BGHInspectFrame:Hide() end
        if inspectTimeoutTimer and not inspectTimeoutTimer:IsCancelled() then
            inspectTimeoutTimer:Cancel()
        end
    end)
end

-- ==========================================
-- 6.7. LOAD-ON-DEMAND EVENT LISTENER
-- ==========================================
local InspectLoader = CreateFrame("Frame")
InspectLoader:RegisterEvent("ADDON_LOADED")
InspectLoader:RegisterEvent("PLAYER_LOGIN")

InspectLoader:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Blizzard_InspectUI" then
        InitializeInspectArcanaTab()
        self:UnregisterEvent("ADDON_LOADED")
        
    elseif event == "PLAYER_LOGIN" then
        local isLoaded = false
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            isLoaded = C_AddOns.IsAddOnLoaded("Blizzard_InspectUI")
        elseif IsAddOnLoaded then
            isLoaded = IsAddOnLoaded("Blizzard_InspectUI")
        end
        
        if isLoaded then
            InitializeInspectArcanaTab()
        end
    end
end)