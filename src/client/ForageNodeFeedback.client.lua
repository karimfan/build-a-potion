-- ForageNodeFeedback: Handles visual feedback when foraging nodes
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer

-- Track original node states
local nodeStates = {}

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
    if triggerPlayer ~= player then return end
    local parent = prompt.Parent
    if not parent or not parent.Name:match("ForageNode") then return end
    
    -- Save original state if not already saved
    if not nodeStates[parent] then
        nodeStates[parent] = {
            size = parent.Size,
            transparency = parent.Transparency,
            color = parent.Color,
        }
    end
    
    local orig = nodeStates[parent]
    
    -- Shrink and dim the node
    TweenService:Create(parent, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = orig.size * 0.4,
        Transparency = 0.7,
    }):Play()
    
    -- Disable point light if present
    local light = parent:FindFirstChildWhichIsA("PointLight")
    if light then
        TweenService:Create(light, TweenInfo.new(0.3), {
            Brightness = 0.3,
        }):Play()
    end
    
    -- Restore after cooldown (60 seconds)
    task.delay(58, function()
        if parent and parent.Parent then
            TweenService:Create(parent, TweenInfo.new(1, Enum.EasingStyle.Elastic), {
                Size = orig.size,
                Transparency = orig.transparency,
            }):Play()
            
            if light then
                TweenService:Create(light, TweenInfo.new(1), {
                    Brightness = 2,
                }):Play()
            end
        end
    end)
end)

-- Add gentle pulsing animation to all forage nodes
task.spawn(function()
    task.wait(2) -- let nodes load
    local zones = workspace:FindFirstChild("Zones")
    if not zones then return end
    local grove = zones:FindFirstChild("WildGrove")
    if not grove then return end
    
    while true do
        for _, child in ipairs(grove:GetChildren()) do
            if child.Name:match("ForageNode") and child.Transparency < 0.5 then
                -- Subtle pulse
                local orig = nodeStates[child] and nodeStates[child].size or child.Size
                TweenService:Create(child, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Size = orig * 1.15,
                }):Play()
                task.wait(1)
                TweenService:Create(child, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Size = orig,
                }):Play()
            end
        end
        task.wait(2)
    end
end)

print("[ForageNodeFeedback] Initialized")

