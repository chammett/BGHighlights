local addonName, BGH = ...

-- ==========================================
-- 2.1. STATISTICAL UTILITY
-- ==========================================
function BGH.GetPopulationStats(matrix, statKey)
    local sum, count = 0, 0
    local values = {}
    for _, player in pairs(matrix) do
        if type(player) == "table" then
            local val = tonumber(player[statKey]) or 0
            sum = sum + val
            count = count + 1
            table.insert(values, val)
        end
    end
    if count == 0 then return 0, 0 end
    local mean = sum / count
    local varianceSum = 0
    for _, val in ipairs(values) do
        varianceSum = varianceSum + ((val - mean) ^ 2)
    end
    return mean, math.sqrt(varianceSum / count)
end

function BGH.GetZScore(val, mean, stdDev)
    if stdDev == 0 then return 0 end 
    return (val - mean) / stdDev
end

-- ==========================================
-- 2.2. MINOR ARCANA ENGINE
-- ==========================================
function BGH.GetMinorTier(value, mean, stepSize)
    if mean <= 0 then return 0 end
    
    -- Default to 20% increments if no custom step is provided
    stepSize = stepSize or 0.20 
    
    local percentAbove = math.max(0, (value - mean) / mean)
    return math.min(14, math.floor(percentAbove / stepSize))
end

function BGH.CalculateMinorBonus(tier)
    if tier <= 0 then return 0 end
    if tier <= 10 then
        -- 1% linear growth for Ace through 10
        return tier * 0.01 
    else
        -- Accelerated piecewise growth: 10% base + 2% per Face Card
        return 0.10 + ((tier - 10) * 0.02) 
    end
end

function BGH.GetMinorArcanaCards(swords, cups, wands, coins)
    local tiers = {
        { suit = "Swords", tier = swords, desc = "Offense" },
        { suit = "Cups", tier = cups, desc = "Healing" },
        { suit = "Wands", tier = wands, desc = "Objectives" },
        { suit = "Coins", tier = coins, desc = "Momentum" }
    }
    
    local cards = {}
    local totalBuff = 0
    local faceCards = { [11] = "Page", [12] = "Knight", [13] = "Queen", [14] = "King" }
    
    for _, data in ipairs(tiers) do
        if data.tier > 0 then
            local rank = faceCards[data.tier] or tostring(data.tier)
            if data.tier == 1 then rank = "Ace" end
            
            local cardName = rank .. " of " .. data.suit
            local multiplierStr = string.format("%.1fx", 1.0 + (data.tier * 0.1))
            local reason = string.format("Drew the %s for generating over %s average %s", cardName, multiplierStr, data.desc)
            
            -- INTERNAL HOOK: Now explicitly targets the shared namespace
            local buff = BGH.CalculateMinorBonus(data.tier)
            
            table.insert(cards, { name = cardName, reason = reason, buff = buff })
            totalBuff = totalBuff + buff
        end
    end
    
    -- Sort cards descending by buff strength to look nice in the tooltip
    table.sort(cards, function(a, b) return a.buff > b.buff end)
    
    return cards, totalBuff
end