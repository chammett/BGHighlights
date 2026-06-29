local addonName, BGH = ...

-- ==========================================
-- 3.1. MASTER REGISTRY (The Deck)
-- ==========================================
local BGHL_MedalRegistry = {
    { 
        title = "The Fool", icon = "Interface\\Icons\\Spell_Shadow_MindSteal", 
        reqs = { zKB = 0.4, zDmg = 0, zHeal = 0 },
        GetReqText = function(self) return string.format("Awarded for securing |cffffff00killing blows|r (|cffffff00performance|r > |cff00ff00%.1f|r standard deviations above average) while keeping |cffffff00damage|r and |cffffff00healing performances|r below the match average.", self.reqs.zKB) end 
    },
    { 
        title = "The Magician", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", 
        reqs = { zObj = 2, zDeaths = -0.5 },
        GetReqText = function(self) return string.format("Awarded for securing |cffffff00objectives|r (|cffffff00performance|r > |cff00ff00%.1f|r standard deviations above average) while maintaining a |cffffff00death rate|r below the match average.", self.reqs.zObj) end 
    },
    { 
        title = "The High Priestess", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", 
        reqs = { zHeal = 1.5, zDmg = -0.5, kb = 0 },
        GetReqText = function(self) return string.format("Awarded for massive |cffffff00healing|r (|cffffff00performance|r > |cff00ff00%.1f|r standard deviations above average) with low |cffffff00damage|r (|cffffff00performance|r > |cff00ff00%.1f|r standard deviations below average) and taking no lives (|cff00ff00%d|r |cffffff00killing blows|r).", self.reqs.zHeal, math.abs(self.reqs.zDmg), self.reqs.kb) end 
    },
    { 
        title = "The Empress", icon = "Interface\\Icons\\Spell_Nature_Rejuvenation", 
        reqs = { zOutput = 0.2, zDeaths = -0.3 }, 
        GetReqText = function(self) return string.format("Awarded for an abundance of |cffffff00damage|r and |cffffff00healing|r (|cffffff00performances|r > |cff00ff00%.1f|r standard deviations above average) with high survivability (|cffffff00deaths|r > |cff00ff00%.1f|r standard deviations below average).", self.reqs.zOutput, math.abs(self.reqs.zDeaths)) end 
    },
    { 
        title = "The Emperor", icon = "Interface\\Icons\\Ability_Warrior_CommandingShout", 
        reqs = { zObj = 1.5, zKB = 1.5, zDmg = 1.5 },
        GetReqText = function(self) return string.format("Awarded for commanding authority: |cffffff00Objective|r and |cffffff00killing blow performances|r (> |cff00ff00%.1f|r standard deviations above average) backed by strong |cffffff00damage|r (|cffffff00performance|r > |cff00ff00%.1f|r standard deviations above average).", self.reqs.zObj, self.reqs.zDmg) end 
    },
    { 
        title = "The Hierophant", icon = "Interface\\Icons\\Spell_Holy_SealOfWisdom", 
        reqs = { variance = 0.5, minHK = 0 },
        GetReqText = function(self) return string.format("Awarded for absolute conformity: Your |cffffff00performance|r across all |cffffff00combat stats|r must not deviate more than |cff00ff00%.2f|r standard deviations from the match average.", self.reqs.variance) end 
    },
    { 
        title = "The Lovers", icon = "Interface\\Icons\\Spell_Holy_GreaterHeal", 
        reqs = { zHK = 1.0, zHeal = 1.0, zKB = 0.5 },
        GetReqText = function(self) return string.format("Awarded for perfect harmony: |cffffff00Honorable kill|r and |cffffff00healing performances|r (> |cff00ff00%.1f|r standard deviations above average) while yielding executions (|cffffff00killing blow performance|r < |cff00ff00%.1f|r standard deviations above average).", self.reqs.zHK, self.reqs.zKB) end 
    },
    { 
        title = "The Chariot", icon = "Interface\\Icons\\Ability_Rogue_Sprint", 
        reqs = { zMom = 1.0, zDmg = 0.5, zHK = 0.5 },
        GetReqText = function(self) return string.format("Awarded for relentless momentum: Dominating |cffffff00objectives|r (|cffffff00momentum performance|r > |cff00ff00%.1f|r standard deviations above average) while plowing through enemies (|cffffff00damage|r and |cffffff00honorable kill performances|r > |cff00ff00%.1f|r standard deviations above average).", self.reqs.zMom, self.reqs.zDmg) end 
    },
    { 
        title = "Strength", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance", 
        reqs = { zHK = 0.75, zDeaths = 0.4, zKB = -0.4 }, 
        GetReqText = function(self) return string.format("Awarded for true sacrifice: High |cffffff00honorable kill performance|r (> |cff00ff00%.2f|r standard deviations above average) and |cffffff00deaths|r (> |cff00ff00%.1f|r standard deviations above average) while yielding executions (|cffffff00killing blow performance|r > |cff00ff00%.1f|r standard deviations below average).", self.reqs.zHK, self.reqs.zDeaths, math.abs(self.reqs.zKB)) end 
    },
    { 
        title = "The Hermit", icon = "Interface\\Icons\\Spell_Nature_AbolishMagic", 
        reqs = { zHK = -0.75, zDeaths = 0, obj = 1.5 }, 
        GetReqText = function(self) return string.format("Awarded for solitary vigilance: Actively securing |cffffff00objectives|r (> |cff00ff00%.1f|r |cffffff00interactions|r) far from team fights (|cffffff00honorable kill performance|r > |cff00ff00%.2f|r standard deviations below average, and a below-average |cffffff00death rate|r).", self.reqs.obj, math.abs(self.reqs.zHK)) end 
    },
    { 
        title = "Wheel of Fortune", icon = "Interface\\Icons\\Spell_Magic_LesserInvisibilty", 
        reqs = { zMom = 1.0 },
        GetReqText = function(self) return string.format("Awarded for turning the tides: Driving |cffffff00momentum|r (|cffffff00performance|r > |cff00ff00%.1f|r standard deviations above average) while your team is outnumbered and dying.", self.reqs.zMom) end 
    },
    { 
        title = "Justice", icon = "Interface\\Icons\\Spell_Nature_StarFall", 
        reqs = { zHeal = 1.0, zDmg = 0, kb = 2 },
        GetReqText = function(self) return string.format("Awarded for dispensing justice: |cffffff00Healing performance|r (> |cff00ff00%.1f|r standard deviations above average) while executing enemies (|cff00ff00%d|r+ |cffffff00killing blows|r), despite a below-average |cffffff00damage performance|r.", self.reqs.zHeal, self.reqs.kb) end 
    },
    { 
        title = "The Hanged Man", icon = "Interface\\Icons\\spell_shadow_psychicscream", 
        reqs = { zDeaths = 0.5, zObj = 0.5, zMom = 0.5 },
        GetReqText = function(self) return string.format("Awarded for true surrender: Pushing |cffffff00objectives|r (|cffffff00objective|r and |cffffff00momentum performances|r > |cff00ff00%.1f|r standard deviations above average) while taking hits for the team (|cffffff00deaths|r > |cff00ff00%.1f|r standard deviations above average).", self.reqs.zObj, self.reqs.zDeaths) end 
    },
    { 
        title = "Death", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", 
        reqs = { zDmg = 0.75, zHK = 0.75, zDeaths = 0.75 }, 
        GetReqText = function(self) return string.format("Awarded for absolute entropy: Massive |cffffff00damage|r, |cffffff00honorable kills|r, and |cffffff00deaths|r (all |cffffff00performances|r > |cff00ff00%.2f|r standard deviations above the match average).", self.reqs.zDmg) end 
    },
    { 
        title = "Temperance", icon = "Interface\\Icons\\Spell_Nature_Tranquility", 
        reqs = { zHK = 0.5, zDeaths = -0.5, kb = 0, mom = 0.5 },
        GetReqText = function(self) return string.format("Awarded for perfect composure: |cffffff00Objective momentum|r and |cffffff00honorable kill performances|r (> |cff00ff00%.1f|r standard deviations above average) with |cff00ff00%d|r |cffffff00killing blows|r and high survivability (|cffffff00deaths|r > |cff00ff00%.1f|r standard deviations below average).", self.reqs.mom, self.reqs.kb, math.abs(self.reqs.zDeaths)) end 
    },
    { 
        title = "The Devil", icon = "Interface\\Icons\\Spell_Shadow_EnslaveDemon", 
        reqs = { zOutput = 1.0, mom = 0.5, minStat = 0 },
        GetReqText = function(self) return string.format("Awarded for toxic attachment: |cffffff00Damage|r or |cffffff00killing blow performance|r (> |cff00ff00%.1f|r standard deviations above average) while contributing |cff00ff00%.1f|r |cffffff00momentum|r to the battleground.", self.reqs.zOutput, self.reqs.mom) end 
    },
    { 
        title = "The Tower", icon = "Interface\\Icons\\Ability_Warrior_ShieldWall", 
        reqs = { def = 3, zDmg = 0.65, zDeaths = 0 },
        GetReqText = function(self) return string.format("Awarded for sudden upheaval: Actively defending multiple nodes (|cff00ff00%.1f|r+ |cffffff00defenses|r) with strong |cffffff00damage performance|r (> |cff00ff00%.1f|r standard deviations above average) and a below-average |cffffff00death rate|r.", self.reqs.def, self.reqs.zDmg) end 
    },
    { 
        title = "The Star", icon = "Interface\\Icons\\Spell_Holy_DivineSpirit", 
        reqs = { zHeal = 1.25, zMom = 2.25 }, 
        GetReqText = function(self) return string.format("Awarded for being a guiding light: Restoring hope with |cffffff00healing performance|r (> |cff00ff00%.2f|r standard deviations above average) while actively driving |cffffff00momentum|r (> |cff00ff00%.2f|r standard deviations above average).", self.reqs.zHeal, self.reqs.zMom) end 
    },
    { 
        title = "The Moon", icon = "Interface\\Icons\\Ability_Stealth", 
        reqs = { zDmg = 0, zKB = 0, zObj = 1.5 },
        GetReqText = function(self) return string.format("Awarded for sharp intuition: Skirting shadows for |cffffff00objective performance|r (> |cff00ff00%.1f|r standard deviations above average) while avoiding the bloodbath (below-average |cffffff00damage|r and |cffffff00killing blow performances|r).", self.reqs.zObj) end 
    },
    { 
        title = "The Sun", icon = "Interface\\Icons\\Spell_Holy_InnerFire", 
        reqs = { zObj = 1.0, zOutput = 1.0, zDeaths = -0.7 },
        GetReqText = function(self) return string.format("Awarded for untouchable radiance: Basking in |cffffff00objective performance|r (> |cff00ff00%.1f|r standard deviations above average) with high |cffffff00combat output|r and high survivability (|cffffff00deaths|r > |cff00ff00%.1f|r standard deviations below average).", self.reqs.zObj, math.abs(self.reqs.zDeaths)) end 
    },
    { 
        title = "Judgement", icon = "Interface\\Icons\\Spell_Holy_RighteousFury", 
        reqs = { zKB = 1.0, zDeaths = 0.5, zMom = 0.5 },
        GetReqText = function(self) return string.format("Awarded for critical reckoning: |cffffff00Killing blow performance|r (> |cff00ff00%.1f|r standard deviations above average) and |cffffff00momentum|r (> |cff00ff00%.1f|r standard deviations above average), while embracing rebirth (|cffffff00deaths|r > |cff00ff00%.1f|r standard deviations above average).", self.reqs.zKB, self.reqs.zMom, self.reqs.zDeaths) end 
    },
    { 
        title = "The World", icon = "Interface\\Icons\\Spell_Holy_HolyNova", 
        reqs = { zObj = 2.25, minStat = 0 }, 
        GetReqText = function(self) return string.format("Awarded for absolute completion: Exceptional |cffffff00objective performance|r (> |cff00ff00%.2f|r standard deviations above average) with strong |cffffff00damage and healing|r (> 50%% of match average), while yielding zero zeros on the scoreboard!", self.reqs.zObj) end 
    }
}

-- SHIFT TO NAMESPACE: Init.lua uses this for sealing the DB
BGH.MedalRegistry = BGHL_MedalRegistry

-- Minor Arcana Deck
local BGHL_MinorRegistry = {
    { 
        suit = "Swords", title = "Suit of Swords", icon = "Interface\\Icons\\inv_sword_39",
        desc = "Drawn by generating an exceptional amount of |cffffff00Damage|r or |cffffff00Killing Blows|r.\n\n|cff00ccffCombo Multiplier Bonus:|r\nAce through 10: +1% weight per tier.\nFace Cards: 10% base + 2% per rank (Up to +18%)."
    },
    { 
        suit = "Cups", title = "Suit of Cups", icon = "Interface\\Icons\\inv_drink_22",
        desc = "Drawn by generating an exceptional amount of |cffffff00Healing|r.\n\n|cff00ccffCombo Multiplier Bonus:|r\nAce through 10: +1% weight per tier.\nFace Cards: 10% base + 2% per rank (Up to +18%)."
    },
    { 
        suit = "Wands", title = "Suit of Wands", icon = "Interface\\Icons\\INV_Wand_01",
        desc = "Drawn by driving exceptional |cffffff00Objective Score|r.\n\n|cff00ccffCombo Multiplier Bonus:|r\nAce through 10: +1% weight per tier.\nFace Cards: 10% base + 2% per rank (Up to +18%)."
    },
    { 
        suit = "Coins", title = "Suit of Coins", icon = "Interface\\Icons\\INV_Misc_Coin_01",
        desc = "Drawn by driving exceptional |cffffff00Momentum Score|r.\n\n|cff00ccffCombo Multiplier Bonus:|r\nAce through 10: +1% weight per tier.\nFace Cards: 10% base + 2% per rank (Up to +18%)."
    }
}
BGH.MinorRegistry = BGHL_MinorRegistry

-- MASTER LOOKUP DICTIONARY
local BGHL_MedalMath = {}
for _, medal in ipairs(BGHL_MedalRegistry) do
    BGHL_MedalMath[medal.title] = medal
end

-- ==========================================
-- 3.2. SCORING WEIGHTS & CONSTANTS
-- ==========================================
local BGHL_ScoringWeights = {
    isolationMult = 1.0,      -- Multiplier for the Isolation Ratio
    attritionMult = 5.0,      -- Multiplier for the Attrition Bonus
    vanguardMult = 0.5,      -- Multiplier for Vanguard Healing
    drTaxPerMedal = 15        -- Percentage weight reduction for holding multiple medals
}

-- SHIFT TO NAMESPACE: UI.lua uses this for generating the Legend Text
BGH.ScoringWeights = BGHL_ScoringWeights

-- ==========================================
-- 3.3. TAROT RENDERER & PLAYER TRACKER
-- ==========================================
function BGH.RenderMedals(dataMatrix, isEndOfMatch, isTestReveal)
    if type(dataMatrix) ~= "table" then return end

    -- Build the Collision Map
    local nameCounts = {}
    local playerCount = 0
    for playerName, stats in pairs(dataMatrix) do
        if type(stats) == "table" and type(playerName) == "string" then
            playerCount = playerCount + 1
            local baseName = strsplit("-", playerName)
            nameCounts[baseName] = (nameCounts[baseName] or 0) + 1
        end
    end
    if playerCount == 0 then return end

	local mapName = dataMatrix.MapName or "Unknown Battleground"
	
    local teamKBs, teamDeaths = {}, {}

    local objectiveKeys = {"Bases Assaulted", "Graveyards Assaulted", "Towers Assaulted", "Flag Captures", "ChatAssaults"}
    local defendKeys = {"Bases Defended", "Graveyards Defended", "Towers Defended", "Flag Returns"}

		-- 1. Calculate Base Stat Averages (Needed for Synthetics)
    	local muHeal, sigHeal = BGH.GetPopulationStats(dataMatrix, "healingDone")
        local muDmg, sigDmg = BGH.GetPopulationStats(dataMatrix, "damageDone")
        local muKB, sigKB = BGH.GetPopulationStats(dataMatrix, "killingBlows")
        local muDeaths, sigDeaths = BGH.GetPopulationStats(dataMatrix, "deaths")
        local muHK, sigHK = BGH.GetPopulationStats(dataMatrix, "honorableKills")
        local muHonor, sigHonor = BGH.GetPopulationStats(dataMatrix, "honorGained")
    	
        for playerName, stats in pairs(dataMatrix) do
            if type(stats) == "table" and stats.faction then
                if not teamKBs[stats.faction] then teamKBs[stats.faction] = 0 end
                if not teamDeaths[stats.faction] then teamDeaths[stats.faction] = 0 end
                
                teamKBs[stats.faction] = teamKBs[stats.faction] + (tonumber(stats.killingBlows) or 0)
                teamDeaths[stats.faction] = teamDeaths[stats.faction] + (tonumber(stats.deaths) or 0)
            end
        end
        
        local matchWinner = dataMatrix.winner
        local maxMedals = 3 
        if mapName == "Warsong Gulch" then
            maxMedals = 3
        elseif mapName == "Arathi Basin" or mapName == "Eye of the Storm" then
            maxMedals = 5
        elseif mapName == "Alterac Valley" then
            maxMedals = 10
        else
            maxMedals = math.max(3, math.floor(playerCount * 0.15))
        end

        -- 2. Synthesize Objectives & Momentum
    	for playerName, stats in pairs(dataMatrix) do
            if type(stats) == "table" then
                -- 1. Hard Objectives
                local objTotal = 0
                for _, key in ipairs(objectiveKeys) do objTotal = objTotal + (tonumber(stats.bgStats[key]) or 0) end
                
                -- 2. Hard Momentum
                local momentumTotal = objTotal + (tonumber(stats.flagPickups) or 0)
                for _, key in ipairs(defendKeys) do momentumTotal = momentumTotal + (tonumber(stats.bgStats[key]) or 0) end
                
                -- Extract combat stats for proxies
                local hk = tonumber(stats.honorableKills) or 0
                local kb = tonumber(stats.killingBlows) or 0
                local deaths = tonumber(stats.deaths) or 0
                local teamDeathCount = (stats.faction and teamDeaths[stats.faction]) or math.max(1, muDeaths)
    			local heal = tonumber(stats.healingDone) or 0

    			-- SYNTHETIC PROXY 1: Teamfight Scalar (Momentum)
                local hkMomentum = 0
                if muHK > 0 then hkMomentum = hk / muHK end
                stats.momHK = hkMomentum

                -- SYNTHETIC PROXY 2: Isolation Ratio (Objectives)
                local isolationBonus = 0
                if hk > 0 and kb > 0 then
                    isolationBonus = (kb / hk) * math.sqrt(kb) * BGHL_ScoringWeights.isolationMult
                end
                stats.objIso = isolationBonus

                -- SYNTHETIC PROXY 3: Attrition (Momentum)
                local attritionBonus = (deaths / math.max(1, teamDeathCount)) * BGHL_ScoringWeights.attritionMult
                stats.momAttr = attritionBonus

    			-- SYNTHETIC PROXY 4: The Vanguard Healer (Momentum)
                local vanguardBonus = 0
                if muHeal > 0 and heal > 0 then
                    vanguardBonus = (heal / muHeal) * hkMomentum * BGHL_ScoringWeights.vanguardMult
                end

                -- SYNTHETIC PROXY 5: The Triage Index (Momentum)
                local lobbyTriage = muHeal / math.max(1, muDeaths)
                local playerTriage = heal / math.max(1, teamDeathCount)
                
                local triageBonus = 0
                if lobbyTriage > 0 then
                    triageBonus = playerTriage / lobbyTriage
                end
                
                stats.momHeal = (vanguardBonus + triageBonus) / 2
    			
                -- Save Hard Stats & Apply Synthetics!
                stats.objHard = objTotal
                stats.momHard = momentumTotal
                stats.objectiveScore = stats.objHard + stats.objIso
                stats.momentumScore = stats.momHard + stats.momHK + stats.momAttr + stats.momHeal
            end
        end

        -- 3. Calculate Derivative Stat Averages (Needed for Z-Scores and Minor Arcana)
        local muObj, sigObj = BGH.GetPopulationStats(dataMatrix, "objectiveScore")
        local muMomentum, sigMomentum = BGH.GetPopulationStats(dataMatrix, "momentumScore")
		
    local candidateMedals, earnedMedals, playerMedalCounts = {}, {}, {}
		for playerName, stats in pairs(dataMatrix) do
        if type(stats) == "table" then 
			local baseName = strsplit("-", playerName)
			local displayName = (nameCounts[baseName] and nameCounts[baseName] > 1) and playerName or baseName
            local kb = tonumber(stats.killingBlows) or 0
            local dmg = tonumber(stats.damageDone) or 0
            local heal = tonumber(stats.healingDone) or 0
            local deaths = tonumber(stats.deaths) or 0
            local hk = tonumber(stats.honorableKills) or 0
            local honor = tonumber(stats.honorGained) or 0

            local zKB, zDmg, zHeal = BGH.GetZScore(kb, muKB, sigKB), BGH.GetZScore(dmg, muDmg, sigDmg), BGH.GetZScore(heal, muHeal, sigHeal)
            local zObj, zDeaths = BGH.GetZScore(stats.objectiveScore, muObj, sigObj), BGH.GetZScore(deaths, muDeaths, sigDeaths)
            local zHK, zMomentum = BGH.GetZScore(hk, muHK, sigHK), BGH.GetZScore(stats.momentumScore, muMomentum, sigMomentum)
            
            -- ==========================================
            -- 3.4. MINOR ARCANA EVALUATION
            -- ==========================================
            local swordsTier = math.max(BGH.GetMinorTier(dmg, muDmg), BGH.GetMinorTier(kb, muKB))
            local cupsTier   = BGH.GetMinorTier(heal, muHeal, 0.50) 
            local wandsTier  = BGH.GetMinorTier(stats.objectiveScore, muObj, 0.50)
            local coinsTier  = BGH.GetMinorTier(stats.momentumScore, muMomentum)
            
			local minorCards, totalMinorBuff = BGH.GetMinorArcanaCards(swordsTier, cupsTier, wandsTier, coinsTier)
            stats.minorCards = minorCards
            stats.minorBuffPctTotal = totalMinorBuff * 100
            
			stats.arcanaTiers = { Swords = swordsTier, Cups = cupsTier, Wands = wandsTier, Coins = coinsTier }
			
			-- [ THE FOOL ]
            local mFool = BGHL_MedalMath["The Fool"].reqs
            if zKB > mFool.zKB and zDmg < mFool.zDmg and zHeal < mFool.zHeal then
                local baseWeight = zKB + math.abs(zDmg) 
                if not candidateMedals["The Fool"] or baseWeight > candidateMedals["The Fool"].weight then
                    candidateMedals["The Fool"] = { playerName = playerName, displayName = displayName, title = "The Fool", desc = string.format("|cffffff00%s|r awarded for securing |cff00ff00%d|r Kills while doing below-average damage!", displayName, kb), icon = BGHL_MedalMath["The Fool"].icon, weight = baseWeight }
                end
            end

            -- [ THE MAGICIAN ]
            local mMagician = BGHL_MedalMath["The Magician"].reqs
            if zObj > mMagician.zObj and zDeaths < mMagician.zDeaths then
                local baseWeight = zObj + math.abs(zDeaths)
                if not candidateMedals["The Magician"] or baseWeight > candidateMedals["The Magician"].weight then
                    candidateMedals["The Magician"] = { playerName = playerName, displayName = displayName, title = "The Magician", desc = string.format("|cffffff00%s|r awarded for securing |cff00ff00%.1f|r Objectives while maintaining high survivability!", displayName, stats.objectiveScore), icon = BGHL_MedalMath["The Magician"].icon, weight = baseWeight }
                end
            end
            
            -- [ THE HIGH PRIESTESS ]
            local mPriestess = BGHL_MedalMath["The High Priestess"].reqs
            if zHeal > mPriestess.zHeal and zDmg < mPriestess.zDmg and kb == mPriestess.kb then
                local baseWeight = zHeal + math.abs(zDmg)
                if not candidateMedals["The High Priestess"] or baseWeight > candidateMedals["The High Priestess"].weight then
                    candidateMedals["The High Priestess"] = { playerName = playerName, displayName = displayName, title = "The High Priestess", desc = string.format("|cffffff00%s|r awarded for massive healing without taking a single life!", displayName), icon = BGHL_MedalMath["The High Priestess"].icon, weight = baseWeight }
                end
            end
            
            -- [ THE EMPRESS ]
            local mEmpress = BGHL_MedalMath["The Empress"].reqs
            if zDmg > mEmpress.zOutput and zHeal > mEmpress.zOutput and zDeaths < mEmpress.zDeaths then
                local baseWeight = zDmg + zHeal + math.abs(zDeaths)
                if not candidateMedals["The Empress"] or baseWeight > candidateMedals["The Empress"].weight then
                    candidateMedals["The Empress"] = { playerName = playerName, displayName = displayName, title = "The Empress", desc = string.format("|cffffff00%s|r awarded for an abundance of output with high survivability!", displayName), icon = BGHL_MedalMath["The Empress"].icon, weight = baseWeight }
                end
            end
            
            -- [ THE EMPEROR ]
            local mEmperor = BGHL_MedalMath["The Emperor"].reqs
            if zObj > mEmperor.zObj and zKB > mEmperor.zKB and zDmg > mEmperor.zDmg then
                local baseWeight = zObj + zKB + zDmg
                if not candidateMedals["The Emperor"] or baseWeight > candidateMedals["The Emperor"].weight then
                    candidateMedals["The Emperor"] = { playerName = playerName, displayName = displayName, title = "The Emperor", desc = string.format("|cffffff00%s|r awarded for commanding authority: |cff00ff00%.1f|r Objectives and |cff00ff00%d|r Kills!", displayName, stats.objectiveScore, kb), icon = BGHL_MedalMath["The Emperor"].icon, weight = baseWeight }
                end
            end
            
            -- [ THE HIEROPHANT ]
            local mHiero = BGHL_MedalMath["The Hierophant"].reqs
            local isAvgGen = (math.abs(zDmg) <= mHiero.variance and math.abs(zKB) <= mHiero.variance and math.abs(zDeaths) <= mHiero.variance and math.abs(zObj) <= mHiero.variance)
            local isAvgHeal = (math.abs(zHeal) <= mHiero.variance and math.abs(zObj) <= mHiero.variance and math.abs(zDeaths) <= mHiero.variance and math.abs(zHK) <= mHiero.variance and heal > mHiero.minHK)
            if (isAvgGen or isAvgHeal) and hk > mHiero.minHK then
                local variance = isAvgGen and isAvgHeal and (math.abs(zDmg) + math.abs(zKB) + math.abs(zDeaths) + math.abs(zObj) + math.abs(zHeal) + math.abs(zHK)) or (math.abs(zDmg) + math.abs(zKB) + math.abs(zDeaths) + math.abs(zObj))
                local baseWeight = (isAvgGen and isAvgHeal and 6.0 or 4.0) - variance
                if not candidateMedals["The Hierophant"] or baseWeight > candidateMedals["The Hierophant"].weight then
                    candidateMedals["The Hierophant"] = { playerName = playerName, displayName = displayName, title = "The Hierophant", desc = string.format("|cffffff00%s|r awarded for absolute conformity: Supremely average across all combat stats.", displayName), icon = BGHL_MedalMath["The Hierophant"].icon, weight = baseWeight }
                end
            end

            -- [ THE LOVERS ]
            local mLovers = BGHL_MedalMath["The Lovers"].reqs
            if zHK > mLovers.zHK and zHeal > mLovers.zHeal and zKB < mLovers.zKB then
                local baseWeight = zHK + zHeal
                if not candidateMedals["The Lovers"] or baseWeight > candidateMedals["The Lovers"].weight then
                    candidateMedals["The Lovers"] = { playerName = playerName, displayName = displayName, title = "The Lovers", desc = string.format("|cffffff00%s|r awarded for perfect harmony: |cff00ff00%d|r Honorable Kills and massive healing!", displayName, hk), icon = BGHL_MedalMath["The Lovers"].icon, weight = baseWeight }
                end
            end
            
            -- [ THE CHARIOT ]
            local mChariot = BGHL_MedalMath["The Chariot"].reqs
            if zMomentum > mChariot.zMom and zDmg > mChariot.zDmg and zHK > mChariot.zHK then
                local baseWeight = zMomentum + zDmg + zHK
                if not candidateMedals["The Chariot"] or baseWeight > candidateMedals["The Chariot"].weight then
                    candidateMedals["The Chariot"] = { playerName = playerName, displayName = displayName, title = "The Chariot", desc = string.format("|cffffff00%s|r awarded for relentless conquest: Driving |cff00ff00%.1f|r momentum while plowing through the enemy lines (|cff00ff00%d|r HKs)!", displayName, stats.momentumScore, hk), icon = BGHL_MedalMath["The Chariot"].icon, weight = baseWeight }
                end
            end
            
            -- [ STRENGTH ]
            local mStrength = BGHL_MedalMath["Strength"].reqs
            if zHK > mStrength.zHK and zDeaths > mStrength.zDeaths and zKB < mStrength.zKB then
                local baseWeight = zHK + zDeaths + math.abs(zKB)
                if not candidateMedals["Strength"] or baseWeight > candidateMedals["Strength"].weight then
                    candidateMedals["Strength"] = { playerName = playerName, displayName = displayName, title = "Strength", desc = string.format("|cffffff00%s|r awarded for true sacrifice: |cff00ff00%d|r team kills assisted and taking the hits for the team!", displayName, hk), icon = BGHL_MedalMath["Strength"].icon, weight = baseWeight }
                end
            end
            
            -- [ THE HERMIT ]
            local mHermit = BGHL_MedalMath["The Hermit"].reqs
            if zHK < mHermit.zHK and zDeaths <= mHermit.zDeaths and stats.objectiveScore > mHermit.obj then
                local baseWeight = (math.abs(zHK) + math.abs(zDeaths) + zObj) * 0.75 
                if not candidateMedals["The Hermit"] or baseWeight > candidateMedals["The Hermit"].weight then
                    candidateMedals["The Hermit"] = { playerName = playerName, displayName = displayName, title = "The Hermit", desc = string.format("|cffffff00%s|r awarded for solitary vigilance: |cff00ff00%.1f|r objectives secured far from the team fights!", displayName, stats.objectiveScore), icon = BGHL_MedalMath["The Hermit"].icon, weight = baseWeight }
                end
            end

            -- [ WHEEL OF FORTUNE ]
            local mWheel = BGHL_MedalMath["Wheel of Fortune"].reqs
            if matchWinner ~= nil and stats.faction == matchWinner and stats.faction ~= nil and teamDeaths[stats.faction] and teamDeaths[stats.faction] >= (teamKBs[stats.faction] * 0.8) and zMomentum > mWheel.zMom then
                local baseWeight = zMomentum * (teamDeaths[stats.faction] / math.max(1, teamKBs[stats.faction]))
                if not candidateMedals["Wheel of Fortune"] or baseWeight > candidateMedals["Wheel of Fortune"].weight then
                    candidateMedals["Wheel of Fortune"] = { playerName = playerName, displayName = displayName, title = "Wheel of Fortune", desc = string.format("|cffffff00%s|r awarded for turning the tides! Driving |cff00ff00%.1f|r objectives while taking heavy casualties.", displayName, stats.momentumScore), icon = BGHL_MedalMath["Wheel of Fortune"].icon, weight = baseWeight }
                end
            end
            
            -- [ JUSTICE ]
            local mJustice = BGHL_MedalMath["Justice"].reqs
            if zHeal > mJustice.zHeal and zDmg <= mJustice.zDmg and kb >= mJustice.kb then
                local baseWeight = zHeal + math.abs(zDmg) + zKB 
                if not candidateMedals["Justice"] or baseWeight > candidateMedals["Justice"].weight then
                    candidateMedals["Justice"] = { playerName = playerName, displayName = displayName, title = "Justice", desc = string.format("|cffffff00%s|r awarded for dispensing Justice: Massive healing while executing |cff00ff00%d|r fleeing enemies!", displayName, kb), icon = BGHL_MedalMath["Justice"].icon, weight = baseWeight }
                end
            end

            -- [ THE HANGED MAN ]
            local mHanged = BGHL_MedalMath["The Hanged Man"].reqs
            if zDeaths > mHanged.zDeaths and zObj > mHanged.zObj and zMomentum > mHanged.zMom then
                local baseWeight = zDeaths + zObj + zMomentum
                if not candidateMedals["The Hanged Man"] or baseWeight > candidateMedals["The Hanged Man"].weight then
                    candidateMedals["The Hanged Man"] = { playerName = playerName, displayName = displayName, title = "The Hanged Man", desc = string.format("|cffffff00%s|r awarded for true surrender: Taking |cff00ff00%d|r deaths while relentlessly pushing |cff00ff00%.1f|r objectives!", displayName, deaths, stats.momentumScore), icon = BGHL_MedalMath["The Hanged Man"].icon, weight = baseWeight }
                end
            end

            -- [ DEATH ]
            local mDeath = BGHL_MedalMath["Death"].reqs
            if zDmg > mDeath.zDmg and zHK > mDeath.zHK and zDeaths > mDeath.zDeaths then
                local baseWeight = zDmg + zHK + zDeaths
                if not candidateMedals["Death"] or baseWeight > candidateMedals["Death"].weight then
                    candidateMedals["Death"] = { playerName = playerName, displayName = displayName, title = "Death", desc = string.format("|cffffff00%s|r awarded for absolute entropy: Inflicting massive damage and reaping |cff00ff00%d|r HKs while embracing rebirth (|cff00ff00%d|r deaths)!", displayName, hk, deaths), icon = BGHL_MedalMath["Death"].icon, weight = baseWeight }
                end
            end

            -- [ TEMPERANCE ]
            local mTemperance = BGHL_MedalMath["Temperance"].reqs
            if zHK > mTemperance.zHK and zDeaths < mTemperance.zDeaths and kb == mTemperance.kb and stats.momentumScore > mTemperance.mom then
                local baseWeight = zHK + math.abs(zDeaths) + zMomentum
                if not candidateMedals["Temperance"] or baseWeight > candidateMedals["Temperance"].weight then
                    candidateMedals["Temperance"] = { playerName = playerName, displayName = displayName, title = "Temperance", desc = string.format("|cffffff00%s|r awarded for perfect composure: Pushing objectives and assisting in |cff00ff00%d|r kills with 0 KBs!", displayName, hk), icon = BGHL_MedalMath["Temperance"].icon, weight = baseWeight }
                end
            end

            -- [ THE DEVIL ]
            local mDevil = BGHL_MedalMath["The Devil"].reqs
            if (zDmg > mDevil.zOutput or zKB > mDevil.zOutput) and stats.momHard <= mDevil.mom and stats.objHard <= mDevil.mom and (dmg > mDevil.minStat or kb > mDevil.minStat) then
                local baseWeight = math.max(zDmg, zKB) + 2.0 
                if not candidateMedals["The Devil"] or baseWeight > candidateMedals["The Devil"].weight then
                    candidateMedals["The Devil"] = { playerName = playerName, displayName = displayName, title = "The Devil", desc = string.format("|cffffff00%s|r awarded for toxic attachment: Yielding to base instincts by chasing |cff00ff00%d|r Damage and |cff00ff00%d|r KBs while entirely ignoring objectives!", displayName, dmg, kb), icon = BGHL_MedalMath["The Devil"].icon, weight = baseWeight }
                end
            end

            -- [ THE TOWER ]
            local mTower = BGHL_MedalMath["The Tower"].reqs
            local defenseScore = stats.momentumScore - stats.objectiveScore - (tonumber(stats.flagPickups) or 0)
            if defenseScore >= mTower.def and zDmg > mTower.zDmg and zDeaths <= mTower.zDeaths then
                local baseWeight = defenseScore + zDmg + math.abs(zDeaths)
                if not candidateMedals["The Tower"] or baseWeight > candidateMedals["The Tower"].weight then
                    candidateMedals["The Tower"] = { playerName = playerName, displayName = displayName, title = "The Tower", desc = string.format("|cffffff00%s|r awarded for sudden upheaval: The immovable fortress who shattered enemy pushes with |cff00ff00%.1f|r objective |cffffff00defenses|r!", displayName, defenseScore), icon = BGHL_MedalMath["The Tower"].icon, weight = baseWeight }
                end
            end

            -- [ THE STAR ]
            local mStar = BGHL_MedalMath["The Star"].reqs
            if zHeal > mStar.zHeal and zMomentum > mStar.zMom then
                local baseWeight = zHeal + zMomentum
                if not candidateMedals["The Star"] or baseWeight > candidateMedals["The Star"].weight then
                    candidateMedals["The Star"] = { playerName = playerName, displayName = displayName, title = "The Star", desc = string.format("|cffffff00%s|r awarded for being a guiding light: Restoring hope with massive healing while driving the team's |cff00ff00momentum!|r", displayName), icon = BGHL_MedalMath["The Star"].icon, weight = baseWeight }
                end
            end

            -- [ THE MOON ]
            local mMoon = BGHL_MedalMath["The Moon"].reqs
            if zDmg <= mMoon.zDmg and zKB <= mMoon.zKB and zObj > mMoon.zObj then
                local baseWeight = (math.abs(zDmg) + math.abs(zKB) + zObj) * 0.75
                if not candidateMedals["The Moon"] or baseWeight > candidateMedals["The Moon"].weight then
                    candidateMedals["The Moon"] = { playerName = playerName, displayName = displayName, title = "The Moon", desc = string.format("|cffffff00%s|r awarded for sharp intuition: Skirting the shadows to secure |cff00ff00%.1f|r objectives while actively avoiding the bloodbath!", displayName, stats.objectiveScore), icon = BGHL_MedalMath["The Moon"].icon, weight = baseWeight }
                end
            end

            -- [ THE SUN ]
            local mSun = BGHL_MedalMath["The Sun"].reqs
            if zObj > mSun.zObj and (zDmg > mSun.zOutput or zHK > mSun.zOutput) and zDeaths < mSun.zDeaths then
                local baseWeight = zObj + math.max(zDmg, zHK) + math.abs(zDeaths)
                if not candidateMedals["The Sun"] or baseWeight > candidateMedals["The Sun"].weight then
                    candidateMedals["The Sun"] = { playerName = playerName, displayName = displayName, title = "The Sun", desc = string.format("|cffffff00%s|r awarded for untouchable radiance: Basking in success with |cff00ff00%.1f|r objectives while radiating pure vitality (|cff00ff00%d|r deaths)!", displayName, stats.objectiveScore, deaths), icon = BGHL_MedalMath["The Sun"].icon, weight = baseWeight }
                end
            end

            -- [ JUDGEMENT ]
            local mJudgement = BGHL_MedalMath["Judgement"].reqs
            if zKB > mJudgement.zKB and zDeaths > mJudgement.zDeaths and zMomentum > mJudgement.zMom then
                local baseWeight = zKB + zDeaths + zMomentum
                if not candidateMedals["Judgement"] or baseWeight > candidateMedals["Judgement"].weight then
                    candidateMedals["Judgement"] = { playerName = playerName, displayName = displayName, title = "Judgement", desc = string.format("|cffffff00%s|r awarded for critical reckoning: Delivering |cff00ff00%d|r KBs and driving |cff00ff00%.1f|r objectives, while embracing rebirth (|cff00ff00%d|r deaths)!", displayName, kb, stats.momentumScore, deaths), icon = BGHL_MedalMath["Judgement"].icon, weight = baseWeight }
                end
            end

            -- [ THE WORLD ]
            local mWorld = BGHL_MedalMath["The World"].reqs
            if zObj > mWorld.zObj and dmg > (muDmg * 0.5) and heal > (muHeal * 0.5) and kb > mWorld.minStat and hk > mWorld.minStat and deaths > 0 then
                local baseWeight = zObj + zDmg + zHeal + zKB
                if not candidateMedals["The World"] or baseWeight > candidateMedals["The World"].weight then
                    candidateMedals["The World"] = { playerName = playerName, displayName = displayName, title = "The World", desc = string.format("|cffffff00%s|r awarded for absolute completion: Flourishing across all domains with |cff00ff00%.1f|r objectives while leaving zero zeros on the scoreboard!", displayName, stats.objectiveScore), icon = BGHL_MedalMath["The World"].icon, weight = baseWeight }
                end
            end
		end
	end

	-- TRANSFER UNIQUE WINNERS TO FINAL POOL
    for _, medal in pairs(candidateMedals) do
		medal.baseWeight = medal.weight
        medal.objScore = dataMatrix[medal.playerName].objectiveScore or 0
        medal.objHard = dataMatrix[medal.playerName].objHard or 0
        medal.objIso = dataMatrix[medal.playerName].objIso or 0
        
        medal.momScore = dataMatrix[medal.playerName].momentumScore or 0
        medal.momHard = dataMatrix[medal.playerName].momHard or 0
        medal.momHK = dataMatrix[medal.playerName].momHK or 0
        medal.momAttr = dataMatrix[medal.playerName].momAttr or 0
        medal.momHeal = dataMatrix[medal.playerName].momHeal or 0
        
		medal.minorCards = dataMatrix[medal.playerName].minorCards
        medal.minorBuffPctTotal = dataMatrix[medal.playerName].minorBuffPctTotal
		
        table.insert(earnedMedals, medal)
    end

	-- ==========================================
    -- 3.5. COMBO MULTIPLIER & DYNAMIC DRAFTING
    -- ==========================================
    for _, medal in ipairs(earnedMedals) do
        medal.minorBuffPctTotal = medal.minorBuffPctTotal or 0
        medal.padObj = (medal.objScore * 0.5)
        medal.padMom = (medal.momScore * 0.25)
        medal.padding = medal.padObj + medal.padMom
    end

    local finalMedals = {}
    local awardedCounts = {}
    local renderLimit = math.min(#earnedMedals, maxMedals)

    while #finalMedals < renderLimit and #earnedMedals > 0 do
        for _, medal in ipairs(earnedMedals) do
            local currentWins = awardedCounts[medal.playerName] or 0
            local taxRate = currentWins * (BGHL_ScoringWeights.drTaxPerMedal / 100)
            
            medal.taxPct = -(taxRate * 100)
            medal.comboPct = medal.minorBuffPctTotal + medal.taxPct
            
            local netMultiplier = math.max(0.1, 1.0 + (medal.comboPct / 100))
            medal.scaledBase = medal.baseWeight * netMultiplier
            
            medal.activeWeight = medal.scaledBase + medal.padding
        end

        table.sort(earnedMedals, function(a, b) return a.activeWeight > b.activeWeight end)

        local topMedal = table.remove(earnedMedals, 1)
        topMedal.weight = topMedal.activeWeight
        
        table.insert(finalMedals, topMedal)
        awardedCounts[topMedal.playerName] = (awardedCounts[topMedal.playerName] or 0) + 1
    end
    
    earnedMedals = finalMedals
    table.sort(earnedMedals, function(a, b) return a.weight > b.weight end)

    local renderLimit = math.min(#earnedMedals, maxMedals)

    if isEndOfMatch and not isTestReveal then
	
        -- SHIFT TO NAMESPACE: Checks the network state set by Network.lua
        if BGH.IsKillSwitched then
            print("|cffff0000[BGH Network]: Medal tracking suppressed for this match. You must update your client layout!|r")
            return 
        end
		
        if type(BGHL_PlayerMedals) ~= "table" then BGHL_PlayerMedals = {} end
        local localPlayer = UnitName("player")
        
        local matchHighWeight = 0 
        local matchMedalsEarned = 0
        local sumMatchWeight = 0
        local highestPlayerMedal = nil
        
        for i = 1, renderLimit do
            local medal = earnedMedals[i]
            if medal.playerName == localPlayer then
                matchMedalsEarned = matchMedalsEarned + 1
                if not highestPlayerMedal then highestPlayerMedal = medal end
                if medal.weight > matchHighWeight then matchHighWeight = medal.weight end
                sumMatchWeight = sumMatchWeight + medal.weight

                if type(BGHL_PlayerMedals[medal.title]) ~= "table" then
                    local oldVal = tonumber(BGHL_PlayerMedals[medal.title]) or 0
                    BGHL_PlayerMedals[medal.title] = { total = oldVal, common = oldVal, uncommon = 0, rare = 0, epic = 0, legendary = 0 }
                end
                
                local data = BGHL_PlayerMedals[medal.title]
                data.total = data.total + 1
                
                if medal.weight >= 18.5 then
                    data.legendary = (data.legendary or 0) + 1
                elseif i == 1 then
                    data.epic = data.epic + 1
                elseif i == 2 then
                    data.rare = data.rare + 1
                elseif i == 3 then
                    data.uncommon = data.uncommon + 1
                else
                    data.common = data.common + 1
                end
            end
        end

        local mapName = dataMatrix.MapName
        local function UpdateLifetimeRecord(target)
            target.totalMedals = (target.totalMedals or 0) + matchMedalsEarned
            target.sumWeight = (target.sumWeight or 0) + sumMatchWeight
            if matchHighWeight > (target.highWeight or 0) then target.highWeight = matchHighWeight end
            if matchMedalsEarned > (target.highestMedals or 0) then target.highestMedals = matchMedalsEarned end
        end

        if type(BGHL_LifetimeStats) == "table" then
            if BGHL_LifetimeStats.Overall then UpdateLifetimeRecord(BGHL_LifetimeStats.Overall) end
            if mapName and BGHL_LifetimeStats.Maps then
                BGHL_LifetimeStats.Maps[mapName] = BGHL_LifetimeStats.Maps[mapName] or {}
                UpdateLifetimeRecord(BGHL_LifetimeStats.Maps[mapName])
            end
        end
        
        -- SHIFT TO NAMESPACE: Init.lua functionality
        BGH.SealDatabase()
        
        -- SHIFT TO NAMESPACE: UI.lua functionality
        if BGH.UpdateArcanaUI then BGH.UpdateArcanaUI() end
		
        if highestPlayerMedal then
            local cleanDesc = highestPlayerMedal.desc:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local announceText = string.format("[BGHighlights]: [%s] - %s", highestPlayerMedal.title, cleanDesc)
            
            if BGHL_Settings.broadcastParty and IsInGroup() then
                SendChatMessage(announceText, "PARTY")
            end
            
            if BGHL_Settings.broadcastRaid then
                local inInstance, instanceType = IsInInstance()
                if inInstance and instanceType == "pvp" then
                    SendChatMessage(announceText, "INSTANCE_CHAT")
                elseif IsInRaid() then
                    SendChatMessage(announceText, "RAID")
                end
            end
            
            if BGHL_Settings.broadcastGuild and IsInGuild() then
                SendChatMessage(announceText, "GUILD")
            end
        end
    end

    -- SHIFT TO NAMESPACE: UI.lua functionality
    if BGH.BGFrame then BGH.BGFrame:ClearMedalsUI() end

	-- ==========================================
    -- 3.6. RENDERING (WITH DYNAMIC LAYOUT)
    -- ==========================================
    local currentY = -10 
    local localPlayerName = UnitName("player")
    local currentDelay = 0

    for i = 1, renderLimit do
        local medal = earnedMedals[i]
        local rankColor = i
        
        if medal.weight and medal.weight >= 18.5 then
            rankColor = "LEGENDARY"
        end
		
		-- SHIFT TO NAMESPACE: Generating UI from Tarot Engine
		if BGH.UpdateOrCreateMedalRow and BGH.scrollChild then
            local frame = BGH.UpdateOrCreateMedalRow(i, BGH.scrollChild, medal, rankColor)
            frame:SetPoint("TOP", BGH.scrollChild, "TOP", 25, currentY)
            currentY = currentY - frame:GetHeight() - 10
            table.insert(BGH.activeMedalFrames, frame)

            -- Standard pacing (+0.75s)
            currentDelay = currentDelay + 0.75
            local revealTime = currentDelay

            -- The Reveal: Staggered delay with Audio Cues & Socketing
            if isEndOfMatch or isTestReveal then
                frame:Hide()
                C_Timer.After(revealTime, function()
                    frame:Show()
                    
                    if BGH.BGFrame and BGH.BGFrame:IsShown() then
                        if medal.weight and medal.weight >= 18.5 then
                            PlaySoundFile(565425, "Master")
                        elseif medal.playerName == localPlayerName then
                            PlaySoundFile(567574, "Master")
                        else
                            PlaySoundFile(562732, "Master")
                        end
                        
                        -- Trigger socketing flash for all non-legendary medals
                        if rankColor ~= "LEGENDARY" and frame.glow and frame.socketAnim then
                            frame.glow:Show()
                            frame.socketAnim:Play()
                        end
                    end
                end)
                
                -- The Padding: Add an extra 750ms wait time AFTER a Legendary drops
                if rankColor == "LEGENDARY" then
                    currentDelay = currentDelay + 0.75
                end
            else
                frame:Show()
            end
        end
    end
        
    local myStats = dataMatrix[localPlayerName]
    
	if myStats and BGH.UpdateOrCreateMedalRow and BGH.scrollChild then
        local myTaxPct = 0
        local myWins = awardedCounts[localPlayerName] or 0
        if myWins > 1 then
            myTaxPct = -((myWins - 1) * BGHL_ScoringWeights.drTaxPerMedal)
        end
        local myCombo = (myStats.minorBuffPctTotal or 0) + myTaxPct

        local myMedalData = {
            title = "My Stats",
            desc = string.format("Your overall performance in this match. You generated |cff00ff00%.1f|r Objective Score and |cff00ff00%.1f|r Momentum.", myStats.objectiveScore or 0, myStats.momentumScore or 0),
            icon = "PORTRAIT",
            playerName = localPlayerName,
            comboPct = myCombo,
            taxPct = myTaxPct,
            objScore = myStats.objectiveScore or 0,
            objHard = myStats.objHard or 0,
            objIso = myStats.objIso or 0,
            momScore = myStats.momentumScore or 0,
            momHard = myStats.momHard or 0,
            momHK = myStats.momHK or 0,
            momAttr = myStats.momAttr or 0,
            momHeal = myStats.momHeal or 0,
            minorCards = myStats.minorCards,
            minorBuffPctTotal = myStats.minorBuffPctTotal
        }

		local myFrame = BGH.UpdateOrCreateMedalRow(renderLimit + 1, BGH.scrollChild, myMedalData, 0) 
        myFrame:SetPoint("TOP", BGH.scrollChild, "TOP", 25, currentY)
        currentY = currentY - myFrame:GetHeight() - 10
        table.insert(BGH.activeMedalFrames, myFrame)

        -- The Reveal: Trigger at the very end of our dynamic delay + one last tick
        if isEndOfMatch or isTestReveal then
            myFrame:Hide()
            C_Timer.After(currentDelay + 0.75, function()
                myFrame:Show()
                
                if BGH.BGFrame and BGH.BGFrame:IsShown() then
                    PlaySoundFile(562732, "Master")
                end
            end)
        else
            myFrame:Show()
        end
    end

    if BGH.scrollChild and BGH.scrollFrame then
        BGH.scrollChild:SetHeight(math.abs(currentY))
        BGH.scrollFrame:UpdateScrollChildRect()
        if BGH.BGFrame then BGH.BGFrame.medalCount = renderLimit end
    end
end