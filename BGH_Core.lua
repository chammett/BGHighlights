local addonName, BGH = ...

-- ==========================================
-- 4.1. SLASH COMMANDS & UTILITIES
-- ==========================================

-- /bgh command to open the AddOn
SLASH_BGH1 = "/bgh"
SlashCmdList["BGH"] = function(msg)

		PlaySound(844, "Master")
    if BGH.BGFrame and BGH.BGFrame:IsShown() then
        BGH.BGFrame:Hide()
    else
        if BGH.BGFrame then BGH.BGFrame.currentPage = 1 end
        if BGH.BGFrame then PanelTemplates_SetTab(BGH.BGFrame, 1) end
        if BGH.UpdateTabColors then BGH.UpdateTabColors() end
        if BGH.BGHSettingsFrame then BGH.BGHSettingsFrame:Hide() end
        
        if BGH.arcanaScrollFrame then BGH.arcanaScrollFrame:Hide() end
        if BGH.infoScrollFrame then BGH.infoScrollFrame:Hide() end
        if BGH.BGHDevFrame then BGH.BGHDevFrame:Hide() end
        if BGH.arcanaBackground then BGH.arcanaBackground:Hide() end
        if BGH.spreadBackground then BGH.spreadBackground:Show() end
        
        if BGH.scrollFrame then BGH.scrollFrame:Show() end
        if BGH.BGFrame and BGH.BGFrame.UpdateTextElements then BGH.BGFrame:UpdateTextElements() end
        if BGH.BGFrame then BGH.BGFrame:Show() end
		PlaySound(844, "Master")
    end
end

-- /bghtest command to simulate end-of-match reveal
SLASH_BGHTEST1 = "/bghtest"
SlashCmdList["BGHTEST"] = function()
    local matchData = BGHL_MatchHistory and BGHL_MatchHistory[1]
    
    if not matchData then
        print("|cff00ccff[BGHighlights]:|r No match data available to test.")
        return
    end

    -- 1. Setup the UI
    if BGH.BGFrame then
        BGH.BGFrame:Show()
        BGH.BGFrame.currentPage = 1
        PanelTemplates_SetTab(BGH.BGFrame, 1)
        if BGH.UpdateTabColors then BGH.UpdateTabColors() end
        
        -- Hide secondary frames
        if BGH.arcanaScrollFrame then BGH.arcanaScrollFrame:Hide() end
        if BGH.infoScrollFrame then BGH.infoScrollFrame:Hide() end
        if BGH.BGHDevFrame then BGH.BGHDevFrame:Hide() end
        if BGH.BGHSettingsFrame then BGH.BGHSettingsFrame:Hide() end
        if BGH.arcanaBackground then BGH.arcanaBackground:Hide() end
        
        -- Show the main spread
        if BGH.spreadBackground then BGH.spreadBackground:Show() end
        if BGH.scrollFrame then BGH.scrollFrame:Show() end
        
        if BGH.BGFrame.UpdateTextElements then BGH.BGFrame:UpdateTextElements(true) end
        if BGH.BGFrame.ClearMedalsUI then BGH.BGFrame:ClearMedalsUI() end
    end
    
    -- 2. Trigger the reveal simulation (isEndOfMatch = false, isTestReveal = true)
    if BGH.RenderMedals then
        BGH.RenderMedals(matchData, false, true)
    end
end

-- ==========================================
-- 4.2. DATA COLLECTION & EVENTS
-- ==========================================
local BGHL_MatchData = {}
local matchEvaluated = false

local function InitializePlayer(playerName)
    if not BGHL_MatchData[playerName] then
        BGHL_MatchData[playerName] = { killingBlows = 0, deaths = 0, honorableKills = 0, damageDone = 0, healingDone = 0, bgStats = {}, flagPickups = 0, flagDrops = 0, faction = nil }
    end
end

local BGHL_NameMap = {}

local function ParseScoreboard()
    local numScores, numStats = GetNumBattlefieldScores(), GetNumBattlefieldStats()
    for i = 1, numScores do
        local name, kb, hk, deaths, honor, faction, _, _, _, classToken, dmg, heal = GetBattlefieldScore(i)
        if name then
            -- Map the base name to the full server ID for chat parsing
            local baseName = strsplit("-", name)
            BGHL_NameMap[baseName] = name 
            
            InitializePlayer(name)
            local p = BGHL_MatchData[name]
            p.killingBlows, p.deaths, p.honorableKills, p.damageDone, p.healingDone, p.classToken, p.faction = kb, deaths, hk, dmg, heal, classToken, faction
            for j = 1, numStats do
                local statName, statValue = GetBattlefieldStatInfo(j), GetBattlefieldStatData(i, j) 
                if statName and statValue then p.bgStats[statName] = statValue end
            end
        end
    end
end

local function ParseBGChat(text)
    local pickerRaw = string.match(text, "flag was picked up by ([^!]+)!")
    if pickerRaw then
        local picker = BGHL_NameMap[pickerRaw] or pickerRaw 
        InitializePlayer(picker)
        BGHL_MatchData[picker].flagPickups = (BGHL_MatchData[picker].flagPickups or 0) + 1
        return
    end

    local dropperRaw = string.match(text, "flag was dropped by ([^!]+)!")
    if dropperRaw then
        local dropper = BGHL_NameMap[dropperRaw] or dropperRaw 
        InitializePlayer(dropper)
        BGHL_MatchData[dropper].flagDrops = (BGHL_MatchData[dropper].flagDrops or 0) + 1
        return
    end

    local assaulterRaw = string.match(text, "([^%s]+) claims the") or string.match(text, "([^%s]+) has assaulted the")
    if assaulterRaw then
        local assaulter = BGHL_NameMap[assaulterRaw] or assaulterRaw 
        InitializePlayer(assaulter)
        BGHL_MatchData[assaulter].bgStats["ChatAssaults"] = (BGHL_MatchData[assaulter].bgStats["ChatAssaults"] or 0) + 1
        return
    end
end

local function ResetMatchData()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "pvp" then 
        if type(BGHL_MatchData) == "table" then
            for k, v in pairs(BGHL_MatchData) do
                if type(v) == "table" then wipe(v) end
            end
            wipe(BGHL_MatchData)
        end
        matchEvaluated = false 
    end
end

local function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function EvaluateTarotMedals()
    -- SHIFT TO NAMESPACE: Required so Network.lua can access it
    if type(BGH.InspectCache) == "table" then wipe(BGH.InspectCache) else BGH.InspectCache = {} end
    
    BGHL_MatchData.MapName = GetRealZoneText()
    print("|cff00ccff[BGHighlights]: Match ended! The scales of fate are balancing...|r")
    
    -- SHIFT TO NAMESPACE: Call the Math Engine in Tarot.lua
    if BGH.RenderMedals then BGH.RenderMedals(BGHL_MatchData, true) end
    
    local evaluatedCopy = {}
    evaluatedCopy.MapName = BGHL_MatchData.MapName
    evaluatedCopy.winner = BGHL_MatchData.winner
    
    for playerName, stats in pairs(BGHL_MatchData) do
        if type(stats) == "table" then
            evaluatedCopy[playerName] = {}
            for k, v in pairs(stats) do evaluatedCopy[playerName][k] = DeepCopy(v) end
        end
    end
    
    table.insert(BGHL_MatchHistory, 1, evaluatedCopy)
    if #BGHL_MatchHistory > 15 then table.remove(BGHL_MatchHistory) end
    
    local localPlayerBase = UnitName("player")
    local localPlayer = localPlayerBase
    local pStats = evaluatedCopy[localPlayer]
    
    -- If base name isn't found, find the full Name-Server ID
    if not pStats then
        for k, v in pairs(evaluatedCopy) do
            if string.match(k, "^" .. localPlayerBase .. "%-") then
                localPlayer = k
                pStats = v
                break
            end
        end
    end
    
    if pStats then
        local mapName = BGHL_MatchData.MapName
        
        local function ApplyBaseStats(target)
            target.matchesPlayed = (target.matchesPlayed or 0) + 1
            
            local momentum = pStats.momentumScore or 0
            local objectives = pStats.objectiveScore or 0
            
            target.sumMomentum = (target.sumMomentum or 0) + momentum
            target.sumObjectives = (target.sumObjectives or 0) + objectives
            
            if momentum > (target.highMomentum or 0) then target.highMomentum = momentum end
            if objectives > (target.highObjectives or 0) then target.highObjectives = objectives end
            
            if pStats.arcanaTiers then
                target.highestMinor = target.highestMinor or { Swords = 0, Cups = 0, Wands = 0, Coins = 0 }
                for suit, tier in pairs(pStats.arcanaTiers) do
                    if tier > (target.highestMinor[suit] or 0) then
                        target.highestMinor[suit] = tier
                    end
                end
            end
        end

        if not BGHL_LifetimeStats.Overall then BGHL_LifetimeStats.Overall = {} end
        ApplyBaseStats(BGHL_LifetimeStats.Overall)

        if mapName then
            if not BGHL_LifetimeStats.Maps then BGHL_LifetimeStats.Maps = {} end
            if not BGHL_LifetimeStats.Maps[mapName] then BGHL_LifetimeStats.Maps[mapName] = {} end
            ApplyBaseStats(BGHL_LifetimeStats.Maps[mapName])
        end
    end

    BGHL_LastMatchData = evaluatedCopy
    
    if BGH.BGFrame then PanelTemplates_SetTab(BGH.BGFrame, 1) end
    if BGH.UpdateTabColors then BGH.UpdateTabColors() end
    
    if BGH.arcanaScrollFrame then BGH.arcanaScrollFrame:Hide() end
    if BGH.infoScrollFrame then BGH.infoScrollFrame:Hide() end
    if BGH.BGHDevFrame then BGH.BGHDevFrame:Hide() end
    if BGH.arcanaBackground then BGH.arcanaBackground:Hide() end
    if BGH.spreadBackground then BGH.spreadBackground:Show() end
    
    if BGH.scrollFrame then BGH.scrollFrame:Show() end
    if BGH.BGFrame and BGH.BGFrame.UpdateTextElements then BGH.BGFrame:UpdateTextElements(true) end
    if BGH.BGFrame then BGH.BGFrame:Show() end
end

local function CheckMatchStatus()
    if matchEvaluated then return end
    local winner = GetBattlefieldWinner()
    if winner ~= nil then
        matchEvaluated = true
        BGHL_MatchData.winner = winner
        ParseScoreboard()
        EvaluateTarotMedals()
    end
end

local EventScanner = CreateFrame("Frame")
EventScanner:RegisterEvent("UPDATE_BATTLEFIELD_SCORE") 
EventScanner:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE") 
EventScanner:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE") 
EventScanner:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL") 
EventScanner:RegisterEvent("UPDATE_BATTLEFIELD_STATUS") 
EventScanner:RegisterEvent("PLAYER_ENTERING_WORLD")     

EventScanner:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then 
        ResetMatchData() 
    end

    local _, instanceType = IsInInstance()
    if instanceType == "arena" then return end

    if event == "UPDATE_BATTLEFIELD_STATUS" then 
        CheckMatchStatus()
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then 
        if not matchEvaluated then ParseScoreboard() end
    elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or event == "CHAT_MSG_BG_SYSTEM_HORDE" or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        if not matchEvaluated then ParseBGChat(...) end
    end
end)