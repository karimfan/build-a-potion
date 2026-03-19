-- FixZoneAssets: Patches broken assets baked into the .rbxl at startup
-- 1) Replaces invalid sound asset IDs (9114...) with working audio
-- 2) Raises rugs to fix Z-fighting with ground tiles
-- 3) Removes the SoundTestAnchor leftover

local SOUND_FIXES = {
    ["Workspace.Zones.IngredientMarket.MysticAnchor.MarketChatter"] = "rbxassetid://130759239",       -- crowd murmur (2.1s)
    ["Workspace.Zones.TradingPost.GoldAnchor.FireCrackling"]        = "rbxassetid://158853971",       -- fire burning (13.8s)
    ["Workspace.Zones.WildGrove.FireflyAnchor.ForestAmbience"]      = "rbxassetid://9112835068",      -- neighborhood birds (64.4s)
    ["Workspace.Zones.YourShop.EvolutionTiers.Tier4_EnchantedAura.ArcaneWeatherAnchor.MagicalHum"] = "rbxassetid://4590657391", -- mystical hum (1.1s)
}

local function resolvePath(path)
    local current = game
    for segment in path:gmatch("[^%.]+") do
        current = current:FindFirstChild(segment)
        if not current then return nil end
    end
    return current
end

task.defer(function()
    -- Fix broken sound IDs
    for path, newId in pairs(SOUND_FIXES) do
        local snd = resolvePath(path)
        if snd and snd:IsA("Sound") then
            snd.SoundId = newId
        end
    end

    -- Remove leftover test anchor
    local testAnchor = workspace:FindFirstChild("SoundTestAnchor")
    if testAnchor then
        testAnchor:Destroy()
    end

    -- Fix rug Z-fighting: raise rugs so bottom face clears the ground tiles
    local tradingPost = resolvePath("Workspace.Zones.TradingPost")
    if tradingPost then
        for _, child in ipairs(tradingPost:GetChildren()) do
            if child:IsA("BasePart") and child.Name:match("^Rug") then
                local pos = child.Position
                if pos.Y < 0.15 then
                    child.Position = Vector3.new(pos.X, 0.15, pos.Z)
                end
            end
        end
    end

    print("[FixZoneAssets] Patched sounds and rug positions")
end)
