local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, RootPart = nil, nil, nil

local lastDashTime = 0
local isEnabled = false
local isOnCooldown = false
local cooldownTime = 4.6
local currentSession = 0

local connections = {}

local function cleanupConnections()
    for _, connection in pairs(connections) do
        if connection and connection.Disconnect then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    connections = {}
end

local function safeFindFirstChild(parent, name, className)
    if not parent then return nil end
    local obj = parent:FindFirstChild(name)
    if obj and (not className or obj:IsA(className)) then
        return obj
    end
    return nil
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Lethal Kiba"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Enabled = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 120, 0, 32)
ToggleButton.Position = UDim2.new(0.5, -60, 0.8, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ToggleButton.Text = "OFF"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextScaled = true
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 9999
ToggleButton.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 3
UIStroke.Color = Color3.fromRGB(180, 60, 255)
UIStroke.Transparency = 0.1
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = ToggleButton

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = ToggleButton

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 20, 140)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 60))
})
Gradient.Rotation = 45
Gradient.Parent = ToggleButton

local CooldownFrame = Instance.new("Frame")
CooldownFrame.Size = UDim2.new(0, 180, 0, 18)
CooldownFrame.Position = UDim2.new(0.5, -90, 0.72, 0)
CooldownFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
CooldownFrame.BorderSizePixel = 2
CooldownFrame.BorderColor3 = Color3.fromRGB(255, 0, 200)
CooldownFrame.ZIndex = 9999
CooldownFrame.Visible = false
CooldownFrame.Parent = ScreenGui

local CooldownCorner = Instance.new("UICorner")
CooldownCorner.CornerRadius = UDim.new(0, 8)
CooldownCorner.Parent = CooldownFrame

local BackPixel = Instance.new("Frame")
BackPixel.Size = UDim2.new(1, -6, 1, -6)
BackPixel.Position = UDim2.new(0, 3, 0, 3)
BackPixel.BackgroundColor3 = Color3.fromRGB(35, 0, 60)
BackPixel.BorderSizePixel = 0
BackPixel.ZIndex = 9999
BackPixel.Parent = CooldownFrame

local BackCorner = Instance.new("UICorner")
BackCorner.CornerRadius = UDim.new(0, 6)
BackCorner.Parent = BackPixel

local CooldownBar = Instance.new("Frame")
CooldownBar.Size = UDim2.new(1, 0, 1, 0)
CooldownBar.BackgroundColor3 = Color3.fromRGB(255, 70, 200)
CooldownBar.BorderSizePixel = 0
CooldownBar.ZIndex = 10000
CooldownBar.Parent = BackPixel

local CooldownBarCorner = Instance.new("UICorner")
CooldownBarCorner.CornerRadius = UDim.new(0, 6)
CooldownBarCorner.Parent = CooldownBar

local PixelGrid = Instance.new("UIGradient")
PixelGrid.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 250)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 160))
})
PixelGrid.Rotation = 90
PixelGrid.Parent = CooldownBar

local CooldownLabel = Instance.new("TextLabel")
CooldownLabel.Size = UDim2.new(1, 0, 1, 0)
CooldownLabel.BackgroundTransparency = 1
CooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CooldownLabel.Font = Enum.Font.Arcade
CooldownLabel.TextScaled = true
CooldownLabel.Text = "COOLDOWN"
CooldownLabel.ZIndex = 10001
CooldownLabel.Parent = CooldownFrame

local isDragging, dragStartPos, buttonStartPos, dragInputConnection = false, nil, nil, nil
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        buttonStartPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)
ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputConnection = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInputConnection and isDragging and buttonStartPos then
        local delta = input.Position - dragStartPos
        local newX = buttonStartPos.X.Offset + delta.X
        local newY = buttonStartPos.Y.Offset + delta.Y
        ToggleButton.Position = UDim2.new(buttonStartPos.X.Scale, newX, buttonStartPos.Y.Scale, newY)
        CooldownFrame.Position = UDim2.new(buttonStartPos.X.Scale, newX - 30, buttonStartPos.Y.Scale, newY - 40)
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    currentSession += 1
    ToggleButton:TweenSize(UDim2.new(0, 112, 0, 30), "Out", "Quad", 0.05, true)
    task.wait(0.05)
    ToggleButton:TweenSize(UDim2.new(0, 120, 0, 32), "Out", "Quad", 0.05, true)
    isEnabled = not isEnabled
    ToggleButton.Text = isEnabled and "ON" or "OFF"
end)

local nearestCacheTarget = nil
local nearestCacheTime = 0
local function findNearestPlayer()
    if not RootPart then return nil end
    local now = tick()
    if now - nearestCacheTime > 0.25 then
        nearestCacheTime = now
        local closestDistance, closestPlayer = 20, nil
        for _, descendant in pairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") and descendant ~= Character then
                local hrp = descendant:FindFirstChild("HumanoidRootPart")
                local hum = descendant:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local distance = (RootPart.Position - hrp.Position).Magnitude
                    if distance <= closestDistance then
                        closestDistance = distance
                        closestPlayer = descendant
                    end
                end
            end
        end
        nearestCacheTarget = closestPlayer
    end
    return nearestCacheTarget
end

local function performDash(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    if not Humanoid or not RootPart then return end

    local targetRoot = target.HumanoidRootPart
    local originalValues = {
        WalkSpeed = Humanoid.WalkSpeed,
        JumpPower = Humanoid.JumpPower,
        PlatformStand = Humanoid.PlatformStand,
        AutoRotate = Humanoid.AutoRotate
    }

    Humanoid.WalkSpeed = 0
    Humanoid.JumpPower = 0
    Humanoid.PlatformStand = true
    Humanoid.AutoRotate = false
    RootPart.Velocity = Vector3.new(0,0,0)
    RootPart.RotVelocity = Vector3.new(0,0,0)

    task.wait(0.2)
    pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
    RootPart.CFrame = RootPart.CFrame * CFrame.Angles(math.rad(60),0,0)

    local teleportDuration = 0.15
    local startTime = tick()
    local teleportConnection
    teleportConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= teleportDuration then
            if teleportConnection then
                pcall(function() teleportConnection:Disconnect() end)
            end
            return
        end
        if RootPart and targetRoot then
            RootPart.CFrame = CFrame.new(targetRoot.Position - targetRoot.CFrame.LookVector * 0.3) * CFrame.Angles(math.rad(90),0,0)
        end
    end)
    
    repeat task.wait() until tick() - startTime >= teleportDuration
    pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)

    Humanoid.WalkSpeed = originalValues.WalkSpeed
    Humanoid.JumpPower = originalValues.JumpPower
    Humanoid.PlatformStand = originalValues.PlatformStand
    Humanoid.AutoRotate = originalValues.AutoRotate
    RootPart.Velocity = Vector3.new(0,0,0)
    RootPart.RotVelocity = Vector3.new(0,0,0)
end

local function startCooldown()
    isOnCooldown = true
    CooldownFrame.Visible = true
    CooldownBar.Size = UDim2.new(1, 0, 1, 0)
    local tween = TweenService:Create(
        CooldownBar,
        TweenInfo.new(cooldownTime, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 1, 0)}
    )
    tween:Play()
    task.spawn(function()
        local startTime = tick()
        while true do
            if not isOnCooldown then return end
            local now = tick()
            local elapsed = now - startTime
            if elapsed >= cooldownTime then
                break
            end
            local remaining = cooldownTime - elapsed
            CooldownLabel.Text = string.format("%.1f", remaining)
            task.wait(0.05)
        end
        isOnCooldown = false
        CooldownLabel.Text = "ready"
        task.wait()
        CooldownFrame.Visible = false
    end)
end

local function activateAbility()
    if not isEnabled or isOnCooldown then return end
    local target = findNearestPlayer()
    if not target then return end
    local targetHumanoid = target:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.MaxHealth <= 0 then return end
    if targetHumanoid.Health / targetHumanoid.MaxHealth <= 0.15 then
        return
    end
    lastDashTime = tick()
    task.spawn(function() performDash(target) end)
    startCooldown()
end

local function onAnimationPlayed(animationTrack)
    if not isEnabled then return end
    if not animationTrack or not animationTrack.Animation then return end
    local animationId = tostring(animationTrack.Animation.AnimationId)
    
    local target = findNearestPlayer()
    if not target then return end

    local targetHumanoid = target:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.MaxHealth <= 0 then return end
    if targetHumanoid.Health / targetHumanoid.MaxHealth <= 0.2 then
        return
    end

    if string.find(animationId, "12296113986", 1, true) then
        task.delay(1.7, function()
            pcall(function()
                local args = {
                    {
                        Dash = Enum.KeyCode.W,
                        Key = Enum.KeyCode.Q,
                        Goal = "KeyPress"
                    }
                }
                if Character and Character:FindFirstChild("Communicate") then
                    Character.Communicate:FireServer(unpack(args))
                end
            end)
            activateAbility()
        end)
    elseif string.find(animationId, "95034083206292", 1, true) then
        task.delay(2.55, function()
            pcall(function()
                local args = {
                    {
                        Dash = Enum.KeyCode.W,
                        Key = Enum.KeyCode.Q,
                        Goal = "KeyPress"
                    }
                }
                if Character and Character:FindFirstChild("Communicate") then
                    Character.Communicate:FireServer(unpack(args))
                end
            end)
            activateAbility()
        end)
    elseif string.find(animationId, "10479335397",1,true) or string.find(animationId, "13380255751",1,true) then
        task.delay(0.45, function()
            if not isOnCooldown then
                startCooldown()
            end
        end)
    end
end

local function setupCharacter(newCharacter)
    cleanupConnections()
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    nearestCacheTarget = nil
    nearestCacheTime = 0
    table.insert(connections, Humanoid.AnimationPlayed:Connect(onAnimationPlayed))
    local animator = Humanoid:FindFirstChildOfClass("Animator")
    if animator then
        table.insert(connections, animator.AnimationPlayed:Connect(onAnimationPlayed))
    end
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

local function playIntro()
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    local camera = Workspace.CurrentCamera
    if not camera then
        repeat
            RunService.RenderStepped:Wait()
            camera = Workspace.CurrentCamera
        until camera
    end

    local textPart = Instance.new("Part")
    textPart.Anchored = true
    textPart.CanCollide = false
    textPart.Transparency = 1
    textPart.Size = Vector3.new(10, 3, 1)
    textPart.Name = "IntroTextPart"
    textPart.Parent = Workspace

    local startCFrame = camera.CFrame * CFrame.new(-40, 0, -30)
    local midCFrame = camera.CFrame * CFrame.new(0, 0, -30)
    local endCFrame = camera.CFrame * CFrame.new(40, 0, -30)
    textPart.CFrame = startCFrame

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = textPart
    billboard.Size = UDim2.new(0, 500, 0, 140)
    billboard.AlwaysOnTop = true
    billboard.Parent = textPart

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Made By YQANTG"
    textLabel.Font = Enum.Font.FredokaOne
    textLabel.TextScaled = true
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.Parent = billboard

    local textGradient = Instance.new("UIGradient")
    textGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 180, 255))
    })
    textGradient.Parent = textLabel

    local textStroke = Instance.new("UIStroke")
    textStroke.Thickness = 2
    textStroke.Color = Color3.fromRGB(20, 0, 50)
    textStroke.Parent = textLabel

    local blurIn = TweenService:Create(
        blur,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = 22 }
    )
    blurIn:Play()
    blurIn.Completed:Wait()

    local tweenIn = TweenService:Create(
        textPart,
        TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = midCFrame }
    )
    tweenIn:Play()
    tweenIn.Completed:Wait()

    task.wait(0.6)

    local tweenOut = TweenService:Create(
        textPart,
        TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { CFrame = endCFrame }
    )
    tweenOut:Play()
    tweenOut.Completed:Wait()

    textPart:Destroy()

    local blurOut = TweenService:Create(
        blur,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = 0 }
    )
    blurOut:Play()
    blurOut.Completed:Wait()
    blur:Destroy()

    ScreenGui.Enabled = true
end

task.spawn(playIntro)
