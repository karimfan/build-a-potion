local ArenaTuning = {}

-- Combat power per potion tier
ArenaTuning.PotionCombatPower = {
    Common = 10,
    Uncommon = 25,
    Rare = 80,
    Mythic = 250,
    Divine = 1000,
}

-- Star bonus: flat power per star
ArenaTuning.StarPowerPerStar = 1

-- Wager limits
ArenaTuning.MaxWagers = 3
ArenaTuning.MinStarsToEnter = 5
ArenaTuning.MinPotionsToEnter = 5

-- Phase timers
ArenaTuning.LoadoutSeconds = 30
ArenaTuning.FightSeconds = 8
ArenaTuning.ResultSeconds = 15  -- time to claim reward before auto-resolve

-- Boost mechanic
ArenaTuning.MaxBoostClicks = 40       -- achievable = ~5 clicks/sec over 8s
ArenaTuning.BoostMaxPercent = 0.20    -- boost adds up to 20% of potion power
ArenaTuning.BoostClickCooldown = 0.08 -- min seconds between counted clicks (anti-autoclicker)

-- Luck factor: ±10%
ArenaTuning.LuckMin = 0.90
ArenaTuning.LuckMax = 1.10

-- Rewards
ArenaTuning.WinnerStars = 3           -- flat star bonus for winning
ArenaTuning.UnderdogBonusStars = 2    -- extra stars if you beat someone with more stars
ArenaTuning.DuelCooldownSeconds = 30  -- cooldown between duels per player

-- Duel states
ArenaTuning.DuelState = {
    Pending = "pending",       -- challenge sent, waiting for accept
    Loadout = "loadout",       -- both players picking potions
    Fighting = "fighting",     -- 8-second auto-sim + boost
    Result = "result",         -- winner revealed, claiming reward
    Done = "done",             -- complete
}

-- Get combat power for a potion key (handles mutations)
function ArenaTuning.getPotionPower(potionId, PotionsData, MutationTuningData)
    local baseId = potionId
    local mutation = nil
    local sep = potionId:find("__")
    if sep then
        baseId = potionId:sub(1, sep - 1)
        mutation = potionId:sub(sep + 2)
    end

    local potion = PotionsData and PotionsData[baseId]
    if not potion then return 0 end

    local tier = potion.tier or "Common"
    local basePower = ArenaTuning.PotionCombatPower[tier] or 10

    -- Apply mutation multiplier
    if mutation and MutationTuningData and MutationTuningData.Types and MutationTuningData.Types[mutation] then
        basePower = math.floor(basePower * MutationTuningData.Types[mutation].sellMultiplier)
    end

    return basePower
end

-- Compute total combat power for a duel participant
function ArenaTuning.computePower(wagers, starCount, boostClicks, PotionsData, MutationTuningData)
    local potionPower = 0
    for _, potionId in ipairs(wagers) do
        potionPower = potionPower + ArenaTuning.getPotionPower(potionId, PotionsData, MutationTuningData)
    end

    local starBonus = (starCount or 0) * ArenaTuning.StarPowerPerStar
    local boostRatio = math.clamp((boostClicks or 0) / ArenaTuning.MaxBoostClicks, 0, 1)
    local boostBonus = potionPower * boostRatio * ArenaTuning.BoostMaxPercent

    return potionPower + starBonus + boostBonus
end

return ArenaTuning
