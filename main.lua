-- Beta Monochrome v1.0 (NoClip Fly with Speed modifier, Base Teleport, Fixed Lockers & Key Farm)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Безопасное создание GUI через CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BetaMonochromeGUI"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Главное квадратное окно (версия зафиксирована как 1.0)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 550)
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Шапка меню
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -35, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "  BETA MONOCHROME v1.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize, Title.Font = 11, Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Кнопка закрытия [X]
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 40)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize, CloseBtn.Font = 14, Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Универсальная функция создания кнопок (возвращает саму кнопку для отслеживания зажатия)
local function createToggle(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 32)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize, btn.Font = 12, Enum.Font.Gotham
    btn.Parent = MainFrame
    
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = name .. (enabled and ": ON" or ": OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(40, 40, 40)
        callback(enabled, btn)
    end)
    return btn
end

-- Кнопка без тумблера (для телепорта на базу)
local function createButton(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 32)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize, btn.Font = 12, Enum.Font.GothamBold
    btn.Parent = MainFrame
    
    btn.MouseButton1Click:Connect(callback)
end

-- Общие таблицы для линий и текстов
local itemLines = {}
local codeTexts = {}
local lockerLines = {}
local monsterLines = {}

local function createLine(color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = color
    line.Thickness = 1.5
    line.Transparency = 1
    return line
end

local function createText()
    local txt = Drawing.new("Text")
    txt.Visible = false
    txt.Color = Color3.fromRGB(255, 255, 255)
    txt.Size = 14
    txt.Center = true
    txt.Outline = true
    return txt
end

-- 1. Fullbright
createToggle("Fullbright (No Dark)", 50, function(state)
    _G.Fullbright = state
    task.spawn(function()
        while _G.Fullbright do
            task.wait(1)
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        end
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
end)

-- 2. Бесконечная стамина
createToggle("Infinite Stamina", 90, function(state)
    _G.InfRun = state
    task.spawn(function()
        while _G.InfRun do
            task.wait(0.2)
            local char = LocalPlayer.Character
            if char then
                local values = char:FindFirstChild("Values") or char
                for _, v in pairs(values:GetDescendants()) do
                    if v.Name:lower():find("stamina") or v.Name:lower():find("energ") then
                        if v:IsA("NumberValue") or v:IsA("IntValue") then
                            v.Value = 100
                        end
                    end
                end
            end
        end
    end)
end)

-- 3. NoClip + Fly (Зажми 'E' на ПК или саму кнопку в меню на телефоне для ускорения)
local flyBtn = createToggle("NoClip + Fly", 130, function(state)
    _G.NoClipFly = state
    
    local bodyGyro, bodyVelocity
    task.spawn(function()
        while _G.NoClipFly do
            RunService.RenderStepped:Wait()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum then
                -- NoClip (проход сквозь стены)
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                -- Создаем физику полета если нет
                if not bodyGyro then
                    bodyGyro = Instance.new("BodyGyro")
                    bodyGyro.P = 9e4
                    bodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
                    bodyGyro.Parent = hrp
                end
                if not bodyVelocity then
                    bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
                    bodyVelocity.Parent = hrp
                end
                
                -- Проверка ускорения (ПК: клавиша 'E', Телефон: зажатие кнопки меню)
                local isFast = UserInputService:IsKeyDown(Enum.KeyCode.E) or (flyBtn and flyBtn.AbsoluteSize and false) -- тут проверяем ниже через InputBegan
                
                bodyGyro.CFrame = Camera.CFrame
                local speed = 50
                -- Если зажата буква E
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    speed = 120
                end
                
                bodyVelocity.Velocity = Camera.CFrame.LookVector * (hum.MoveDirection.Magnitude > 0 and speed or 0)
            end
        end
        
        -- Очистка при выключении
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
end)

-- Дополнительно для телефона (если палец зажал кнопку меню)
if flyBtn then
    flyBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            _G.FlyFastTouch = true
        end
    end)
    flyBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            _G.FlyFastTouch = false
        end
    end)
end

-- 4. Телепорт на базу
createButton("TP to Base / Spawn", 170, function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local foundBase = nil
        for _, obj in pairs(Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if name:find("base") or name:find("spawn") or name:find("lobby") or name:find("hub") then
                if obj:IsA("BasePart") then
                    foundBase = obj
                    break
                elseif obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) then
                    foundBase = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    break
                end
            end
        end
        
        if foundBase then
            hrp.CFrame = foundBase.CFrame + Vector3.new(0, 3, 0)
        else
            -- Если конкретной базы нет, кидаем вверх/на спавн мира
            hrp.CFrame = CFrame.new(0, 50, 0)
        end
    end
end)

-- 5. Авто-фарм ключей (7 секунд ждать или пока не возьмет)
createToggle("Auto-Farm Keys", 210, function(state)
    _G.KeyFarm = state
    task.spawn(function()
        while _G.KeyFarm do
            task.wait(0.5)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if not _G.KeyFarm then break end
                    if obj:IsA("BasePart") and obj.Name:lower():find("key") then
                        local startTime = tick()
                        repeat
                            if not obj or not obj.Parent then break end
                            hrp.CFrame = obj.CFrame + Vector3.new(0, 2, 0)
                            
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                fireproximityprompt(prompt)
                            else
                                firetouchinterest(hrp, obj, 0)
                                firetouchinterest(hrp, obj, 1)
                            end
                            
                            RunService.Heartbeat:Wait()
                        until (tick() - startTime >= 7) or not obj.Parent
                        
                        task.wait(0.5)
                    end
                end
            end
        end
    end)
end)

-- 6. ESP на Ключи (Желтый)
createToggle("ESP: Keys", 250, function(state)
    _G.KeyESP = state
    task.spawn(function()
        while _G.KeyESP do
            task.wait(0.1)
            for obj, line in pairs(itemLines) do
                if not obj or not obj.Parent then line:Remove() itemLines[obj] = nil end
            end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("key") then
                    if not obj:FindFirstChild("Highlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "Highlight"
                        hl.FillColor = Color3.fromRGB(255, 255, 0)
                        hl.Parent = obj
                    end
                    if not itemLines[obj] then itemLines[obj] = createLine(Color3.fromRGB(255, 255, 0)) end
                    
                    local vector, onScreen = Camera:WorldToViewportPoint(obj.Position)
                    local line = itemLines[obj]
                    if onScreen then
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(vector.X, vector.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
        end
        for _, line in pairs(itemLines) do line:Remove() end
        itemLines = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:FindFirstChild("Highlight") then obj.Highlight:Destroy() end
        end
    end)
end)

-- 7. ESP на Коды (Фиолетовый + Текст)
createToggle("ESP: Codes", 290, function(state)
    _G.CodeESP = state
    task.spawn(function()
        while _G.CodeESP do
            task.wait(0.1)
            for obj, data in pairs(codeTexts) do
                if not obj or not obj.Parent then
                    data.Line:Remove()
                    data.Text:Remove()
                    codeTexts[obj] = nil
                end
            end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("code") then
                    if not obj:FindFirstChild("CodeHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "CodeHighlight"
                        hl.FillColor = Color3.fromRGB(170, 0, 255)
                        hl.Parent = obj
                    end
                    
                    if not codeTexts[obj] then
                        codeTexts[obj] = {
                            Line = createLine(Color3.fromRGB(170, 0, 255)),
                            Text = createText()
                        }
                    end
                    
                    local codeString = "CODE"
                    local surfaceGui = obj:FindFirstChildOfClass("SurfaceGui")
                    if surfaceGui then
                        local textLabel = surfaceGui:FindFirstChildOfClass("TextLabel")
                        if textLabel then codeString = textLabel.Text end
                    end
                    
                    local vector, onScreen = Camera:WorldToViewportPoint(obj.Position)
                    local dt = codeTexts[obj]
                    if onScreen then
                        dt.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        dt.Line.To = Vector2.new(vector.X, vector.Y)
                        dt.Line.Visible = true
                        
                        dt.Text.Text = "[ CODE: " .. codeString .. " ]"
                        dt.Text.Position = Vector2.new(vector.X, vector.Y - 20)
                        dt.Text.Visible = true
                    else
                        dt.Line.Visible = false
                        dt.Text.Visible = false
                    end
                end
            end
        end
        
        for _, dt in pairs(codeTexts) do
            dt.Line:Remove()
            dt.Text:Remove()
        end
        codeTexts = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:FindFirstChild("CodeHighlight") then obj.CodeHighlight:Destroy() end
        end
    end)
end)

-- 8. ESP на Шкафы (Зеленый)
createToggle("ESP: Lockers", 330, function(state)
    _G.LockerESP = state
    task.spawn(function()
        while _G.LockerESP do
            task.wait(0.3)
            for part, line in pairs(lockerLines) do
                if not part or not part.Parent then line:Remove() lockerLines[part] = nil end
            end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local name = obj.Name:lower()
                    if name:find("locker") or name:find("cabinet") or name:find("wardrobe") or name:find("closet") then
                        local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                        
                        if targetPart then
                            if not targetPart:FindFirstChild("LockerHighlight") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "LockerHighlight"
                                hl.FillColor = Color3.fromRGB(0, 255, 0)
                                hl.Parent = targetPart
                            end
                            
                            if not lockerLines[targetPart] then
                                lockerLines[targetPart] = createLine(Color3.fromRGB(0, 255, 0))
                            end
                            
                            local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            local line = lockerLines[targetPart]
                            if onScreen then
                                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                line.To = Vector2.new(vector.X, vector.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        end
                    end
                end
            end
        end
        for _, line in pairs(lockerLines) do line:Remove() end
        lockerLines = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:FindFirstChild("LockerHighlight") then obj.LockerHighlight:Destroy() end
            if obj:IsA("Model") then
                for _, p in pairs(obj:GetChildren()) do
                    if p:FindFirstChild("LockerHighlight") then p.LockerHighlight:Destroy() end
                end
            end
        end
    end)
end)

-- 9. ESP НА МОНСТРА (Красный)
createToggle("ESP: Monster", 370, function(state)
    _G.MonsterESP = state
    task.spawn(function()
        while _G.MonsterESP do
            task.wait(0.1)
            for model, line in pairs(monsterLines) do
                if not model or not model.Parent then line:Remove() monsterLines[model] = nil end
            end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj ~= char and not obj:IsDescendantOf(char) then
                        local name = obj.Name:lower()
                        local targetPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("Head") or obj:FindFirstChildWhichIsA("BasePart")
                        
                        local isMonster = name:find("monster") or name:find("enemy") or name:find("killer") or name:find("entity") or name:find("bot") or name:find("ghost") or name:find("creature") or name:find("zombie")
                        local isPlayer = Players:GetPlayerFromCharacter(obj)
                        
                        if (isMonster or obj:FindFirstChildOfClass("Humanoid")) and targetPart and not isPlayer then
                            if not obj:FindFirstChild("MonsterHighlight") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "MonsterHighlight"
                                hl.FillColor = Color3.fromRGB(255, 0, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.Parent = obj
                            end
                            
                            if not monsterLines[obj] then
                                monsterLines[obj] = createLine(Color3.fromRGB(255, 0, 0))
                            end
                            
                            local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            local line = monsterLines[obj]
                            if onScreen then
                                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                line.To = Vector2.new(vector.X, vector.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        end
                    end
                end
            end
        end
        
        for _, line in pairs(monsterLines) do line:Remove() end
        monsterLines = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:FindFirstChild("MonsterHighlight") then obj.MonsterHighlight:Destroy() end
        end
    end)
end)
