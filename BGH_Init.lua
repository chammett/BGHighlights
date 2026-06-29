local addonName, BGH = ...

-- ==========================================
-- 1.1. VERSION CONTROL & CI/CD INJECTION
-- ==========================================
local BGH_VERSION_STR = "@project-version@"

if BGH_VERSION_STR == "@" .. "project-version" .. "@" then 
    BGH_VERSION_STR = "1.0.0" 
end

local function ParseVersionString(vStr)
    local major, minor, patch = string.match(vStr, "(%d+)%.(%d+)%.(%d+)")
    if major and minor and patch then
        return (tonumber(major) * 10000) + (tonumber(minor) * 100) + tonumber(patch)
    end
    return 0 
end

BGH.VERSION_STR = BGH_VERSION_STR
BGH.VERSION_CODE = ParseVersionString(BGH_VERSION_STR)


-- ==========================================
-- 1.2. THE SECURITY LAYER
-- ==========================================
local SECRET_SALT = "Tranquility_OIT_2026!" 

-- SHIFT TO NAMESPACE: Network.lua needs this for packet signing
function BGH.GenerateChecksum(payload)
    local combined = payload .. SECRET_SALT
    local hash = 5381
    
    for i = 1, string.len(combined) do
        local byte = string.byte(combined, i)
        hash = (hash * 33) + byte
        hash = hash % 4294967296 
    end
    
    return tostring(hash)
end

-- SHIFT TO NAMESPACE: Tarot.lua calls this after a match ends
function BGH.SealDatabase()
    if type(BGHL_PlayerMedals) ~= "table" then return end
    
    local dataString = ""
    -- SHIFT TO NAMESPACE: MedalRegistry will live in Tarot.lua
    for _, medal in ipairs(BGH.MedalRegistry) do
        local count = 0
        local earnedData = BGHL_PlayerMedals[medal.title]
        
        if type(earnedData) == "table" then
            count = earnedData.total or 0
        else
            count = tonumber(earnedData) or 0
        end
        
        dataString = dataString .. tostring(count) .. "-"
    end
    
    BGHL_PlayerMedals.DBHash = BGH.GenerateChecksum(dataString)
end

local IntegrityScanner = CreateFrame("Frame")
IntegrityScanner:RegisterEvent("PLAYER_ENTERING_WORLD")
IntegrityScanner:SetScript("OnEvent", function(self, event)
    if type(BGHL_PlayerMedals) == "table" then
        local expectedHash = BGHL_PlayerMedals.DBHash
        local savedVersion = BGHL_PlayerMedals.savedVersion or 0 
        
        local dataString = ""
        for _, medal in ipairs(BGH.MedalRegistry) do
            local count = 0
            local earnedData = BGHL_PlayerMedals[medal.title]
            
            if type(earnedData) == "table" then
                count = earnedData.total or 0
            else
                count = tonumber(earnedData) or 0
            end
            
            dataString = dataString .. tostring(count) .. "-"
        end
        
        local actualHash = BGH.GenerateChecksum(dataString)
        
		local isNewInstall = true
		for _, medal in ipairs(BGH.MedalRegistry) do
			if BGHL_PlayerMedals[medal.title] ~= nil then
				isNewInstall = false
				break
			end
		end

		if expectedHash == actualHash then
			BGHL_PlayerMedals.savedVersion = BGH.VERSION_CODE
			BGH.SealDatabase()
		elseif expectedHash == nil and isNewInstall then
			BGHL_PlayerMedals.savedVersion = BGH.VERSION_CODE
			BGH.SealDatabase()
		elseif savedVersion < BGH.VERSION_CODE then
			print(string.format("|cff00ccff[BGH Security]: AddOn update detected..."))
			BGHL_PlayerMedals.savedVersion = BGH.VERSION_CODE
			BGH.SealDatabase()
		else
			wipe(BGHL_PlayerMedals)
			BGHL_PlayerMedals.savedVersion = BGH.VERSION_CODE
			BGH.SealDatabase()
		end
    end
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

-- ==========================================
-- 1.3. DATA MIGRATION & INITIALIZATION ENGINE
-- ==========================================
local MigrationEngine = CreateFrame("Frame")
MigrationEngine:RegisterEvent("PLAYER_LOGIN")
MigrationEngine:SetScript("OnEvent", function(self)
    -- 1. Initialize Baseline
    if type(BGHL_LastMatchData) ~= "table" then BGHL_LastMatchData = {} end
    if type(BGHL_Settings) ~= "table" then 
        BGHL_Settings = { broadcastParty = false, broadcastRaid = false, broadcastGuild = false } 
    end
    
    -- 2. Migrate Match History
    if type(BGHL_MatchHistory) ~= "table" then 
        BGHL_MatchHistory = {} 
        -- DATA MIGRATION: Salvage the legacy single-match save
        if type(BGHL_LastMatchData) == "table" and BGHL_LastMatchData.MapName then
            table.insert(BGHL_MatchHistory, BGHL_LastMatchData)
        end
    end
    
    -- 3. Initialize/Migrate Lifetime Stats
    if type(BGHL_LifetimeStats) ~= "table" then
        BGHL_LifetimeStats = { Overall = {}, Maps = {} }
    end
    
    if not BGHL_LifetimeStats.Overall then
        local migrated = {
            Overall = {
                matchesPlayed = BGHL_LifetimeStats.matchesPlayed or 0,
                totalMedals = BGHL_LifetimeStats.totalMedals or 0,
                sumWeight = BGHL_LifetimeStats.sumWeight or 0,
                sumMomentum = BGHL_LifetimeStats.sumMomentum or 0,
                sumObjectives = BGHL_LifetimeStats.sumObjectives or 0,
                highWeight = BGHL_LifetimeStats.highWeight or 0,
                highMomentum = BGHL_LifetimeStats.highMomentum or 0,
                highObjectives = BGHL_LifetimeStats.highObjectives or 0,
                highestMedals = BGHL_LifetimeStats.highestMedals or 0,
                highestMinor = BGHL_LifetimeStats.highestMinor or { Swords = 0, Cups = 0, Wands = 0, Coins = 0 }
            },
            Maps = {}
        }
        BGHL_LifetimeStats = migrated
    end
	
	-- 4. Native Scoreboard Modification
    -- Make the Blizzard end-of-match window draggable for side-by-side viewing
    if WorldStateScoreFrame then
        WorldStateScoreFrame:SetMovable(true)
        WorldStateScoreFrame:EnableMouse(true)
        WorldStateScoreFrame:RegisterForDrag("LeftButton")
        
        -- Use HookScript instead of SetScript to safely preserve native Blizzard code
        WorldStateScoreFrame:HookScript("OnDragStart", WorldStateScoreFrame.StartMoving)
        WorldStateScoreFrame:HookScript("OnDragStop", WorldStateScoreFrame.StopMovingOrSizing)
    end
	
	-- 5. Welcome Message Broadcast
    print(string.format("|cff00ccff[BGHighlights]|r v%s by Isuira @ Dreamscyth loaded! Type |cffffff00/bgh|r or |cffffff00left-click|r the minimap icon to view your Arcana.", BGH.VERSION_STR))
	
end)