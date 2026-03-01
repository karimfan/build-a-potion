local UpgradeTuning = {}

UpgradeTuning.CauldronTiers = {
    {
        tier = 1, name = "Apprentice Cauldron",
        cost = 0, brewReq = 0,
        brewTimeReduction = 0, mutationBonus = 0,
    },
    {
        tier = 2, name = "Adept Cauldron",
        cost = 1000, brewReq = 0,
        brewTimeReduction = 0.20, mutationBonus = 0.02,
    },
    {
        tier = 3, name = "Master Cauldron",
        cost = 5000, brewReq = 50,
        brewTimeReduction = 0.35, mutationBonus = 0.04,
    },
    {
        tier = 4, name = "Archmage Cauldron",
        cost = 25000, brewReq = 100,
        brewTimeReduction = 0.50, mutationBonus = 0.08,
    },
}

function UpgradeTuning.getTier(tierNum)
    return UpgradeTuning.CauldronTiers[tierNum] or UpgradeTuning.CauldronTiers[1]
end

function UpgradeTuning.getNextTier(currentTier)
    if currentTier >= #UpgradeTuning.CauldronTiers then return nil end
    return UpgradeTuning.CauldronTiers[currentTier + 1]
end

return UpgradeTuning
