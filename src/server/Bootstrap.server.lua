-- Bootstrap: Ensures services initialize in deterministic order
-- This script runs first and loads all server services

print("[Bootstrap] Starting Brew a Potion server...")

local SSS = game:GetService("ServerScriptService")
local Services = SSS:WaitForChild("Services")

-- Services are Script instances that self-initialize
-- This bootstrap just confirms they're all present
local requiredServices = {
    "PlayerDataService",
    "MarketService", 
    "EconomyService",
    "BrewingService",
    "ZoneService",
    "WildGroveDecorationService",
    "ArenaService",
}

for _, serviceName in ipairs(requiredServices) do
    local service = Services:FindFirstChild(serviceName)
    if service then
        print("[Bootstrap] Found: " .. serviceName)
    else
        warn("[Bootstrap] Missing: " .. serviceName .. " (will be added in later phases)")
    end
end

print("[Bootstrap] Server startup complete")
