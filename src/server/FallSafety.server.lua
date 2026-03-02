game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local hrp = character:WaitForChild("HumanoidRootPart")
        game:GetService("RunService").Heartbeat:Connect(function()
            if hrp and hrp.Position.Y < -20 then
                -- Teleport back to shop spawn
                local spawn = workspace.Zones.YourShop:FindFirstChild("SpawnPoint")
                if spawn then
                    hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end)
    end)
end)
print("[FallSafety] Initialized")
