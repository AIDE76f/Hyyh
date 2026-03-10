-- ESP + Aimbot Script with Full GUI (Complete Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========== الإعدادات الافتراضية ==========
local Settings = {
    AimbotEnabled = true,
    AimbotKey = Enum.KeyCode.LeftShift,
    TargetPart = "Head",
    Smoothness = 0.3,
    FOVSize = 150,
    ShowFOV = true,
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(255, 0, 0),
}

-- متغيرات داخلية
local aimbotActive = false
local currentTarget = nil
local fovCircle
local espInstances = {}

-- ========== دالة إنشاء الـ ESP ==========
local function createESP(player)
    if player == LocalPlayer or not Settings.ESPEnabled then return end
    
    -- حذف القديم إن وجد
    if espInstances[player] then
        for _, inst in pairs(espInstances[player]) do
            pcall(function() inst:Destroy() end)
        end
        espInstances[player] = nil
    end

    local function setupCharacter(character)
        if not character or not Settings.ESPEnabled then return end
        
        -- انتظر حتى يكتمل تحميل الأجزاء
        local head = character:WaitForChild("Head", 5)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not head or not humanoidRootPart then return end

        -- إنشاء الإطار (Highlight)
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Settings.ESPColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Adornee = character
        highlight.Parent = character

        -- إنشاء لوحة الاسم والمسافة
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_GUI"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextScaled = true
        label.Text = player.Name .. " [0m]"
        label.Parent = billboard

        -- تحديث المسافة
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not Settings.ESPEnabled or not character or not character.Parent or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if connection then connection:Disconnect() end
                return
            end
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
            label.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
        end)

        -- تخزين الكائنات لإزالتها لاحقاً
        if not espInstances[player] then espInstances[player] = {} end
        table.insert(espInstances[player], highlight)
        table.insert(espInstances[player], billboard)
        table.insert(espInstances[player], connection)
    end

    if player.Character then
        setupCharacter(player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        setupCharacter(character)
    end)
end

-- ========== تطبيق ESP على جميع اللاعبين ==========
local function refreshESP()
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    if espInstances[player] then
        for _, inst in pairs(espInstances[player]) do
            pcall(function() inst:Destroy() end)
        end
        espInstances[player] = nil
    end
end)

-- ========== دوال الـ Aimbot ==========
local function getClosestPlayer()
    local closestDistance = Settings.FOVSize
    local closestPlayer = nil
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.TargetPart) then
            local part = player.Character[Settings.TargetPart]
            local partPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local screenPos = Vector2.new(partPos.X, partPos.Y)
                local dist = (screenPos - mousePos).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

local function smoothAim(target)
    if target and target.Character and target.Character:FindFirstChild(Settings.TargetPart) then
        local targetPos = target.Character[Settings.TargetPart].Position
        local targetScreenPos = Camera:WorldToViewportPoint(targetPos)
        local currentMousePos = UserInputService:GetMouseLocation()
        
        local delta = Vector2.new(targetScreenPos.X, targetScreenPos.Y) - currentMousePos
        local newPos = currentMousePos + delta * (1 - Settings.Smoothness)
        
        -- استخدام mousemoverel إذا كانت متاحة
        if mousemoverel then
            mousemoverel(newPos.X - currentMousePos.X, newPos.Y - currentMousePos.Y)
        end
    end
end

-- ========== تفعيل Aimbot بالأزرار ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Settings.AimbotKey then
        aimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Settings.AimbotKey then
        aimbotActive = false
        currentTarget = nil
    end
end)

-- حلقة الـ aimbot
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and aimbotActive then
        currentTarget = getClosestPlayer()
        if currentTarget then
            smoothAim(currentTarget)
        end
    end
end)

-- ========== دائرة FOV ==========
local function updateFOV()
    if fovCircle then
        fovCircle.Visible = Settings.ShowFOV and Settings.AimbotEnabled
        fovCircle.Radius = Settings.FOVSize
    end
end

if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = Settings.ShowFOV
    fovCircle.Thickness = 2
    fovCircle.Color = Color3.fromRGB(0, 255, 0)
    fovCircle.Filled = false
    fovCircle.Radius = Settings.FOVSize
    fovCircle.NumSides = 60
    
    RunService.RenderStepped:Connect(function()
        fovCircle.Position = UserInputService:GetMouseLocation()
    end)
end

-- ========== إنشاء واجهة المستخدم (GUI) كاملة بجميع القوائم ==========
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESPAimbotGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- الإطار الرئيسي
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0, 50, 0, 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- شريط العنوان
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -30, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "ESP + Aimbot (Full)"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 20
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- محتوى قابل للتمرير
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, 0, 1, -30)
    container.Position = UDim2.new(0, 0, 0, 30)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 5
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.Parent = mainFrame
    
    local yPos = 5
    
    -- دالة مساعدة لإنشاء قسم
    local function createSection(title)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, -10, 0, 25)
        section.Position = UDim2.new(0, 5, 0, yPos)
        section.BackgroundTransparency = 1
        section.Parent = container
        
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 2)
        line.Position = UDim2.new(0, 0, 1, -2)
        line.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        line.BorderSizePixel = 0
        line.Parent = section
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = title
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 18
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = section
        
        yPos = yPos + 30
        return section
    end
    
    -- دالة مساعدة لإنشاء زر اختيار (Toggle)
    local function createToggle(text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = container
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 180, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 60, 0, 25)
        toggleBtn.Position = UDim2.new(1, -65, 0.5, -12.5)
        toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        toggleBtn.Text = default and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Font = Enum.Font.SourceSansBold
        toggleBtn.TextSize = 14
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Parent = frame
        
        local state = default
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
            toggleBtn.Text = state and "ON" or "OFF"
            callback(state)
        end)
        
        yPos = yPos + 40
        return toggleBtn
    end
    
    -- دالة مساعدة لإنشاء قائمة منسدلة
    local function createDropdown(text, options, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = container
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 150, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0, 100, 0, 25)
        dropdownBtn.Position = UDim2.new(1, -105, 0.5, -12.5)
        dropdownBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        dropdownBtn.Text = default
        dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownBtn.Font = Enum.Font.SourceSans
        dropdownBtn.TextSize = 14
        dropdownBtn.BorderSizePixel = 0
        dropdownBtn.Parent = frame
        
        local expanded = false
        local optionsFrame
        
        dropdownBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            if expanded then
                if optionsFrame then optionsFrame:Destroy() end
                optionsFrame = Instance.new("Frame")
                optionsFrame.Size = UDim2.new(0, 100, 0, #options * 25)
                optionsFrame.Position = UDim2.new(1, -105, 1, 0)
                optionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                optionsFrame.BorderSizePixel = 0
                optionsFrame.Parent = frame
                
                for i, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 25)
                    optBtn.Position = UDim2.new(0, 0, 0, (i-1)*25)
                    optBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    optBtn.Text = opt
                    optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    optBtn.Font = Enum.Font.SourceSans
                    optBtn.TextSize = 14
                    optBtn.BorderSizePixel = 0
                    optBtn.Parent = optionsFrame
                    
                    optBtn.MouseButton1Click:Connect(function()
                        dropdownBtn.Text = opt
                        callback(opt)
                        expanded = false
                        optionsFrame:Destroy()
                    end)
                end
            else
                if optionsFrame then optionsFrame:Destroy() end
            end
        end)
        
        yPos = yPos + 40
    end
    
    -- دالة مساعدة لإنشاء شريط تمرير
    local function createSlider(text, min, max, default, callback, suffix)
        suffix = suffix or ""
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 45)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = container
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. string.format("%.1f", default) .. suffix
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1, -20, 0, 8)
        sliderBg.Position = UDim2.new(0, 10, 0, 25)
        sliderBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = frame
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBg
        
        local dragging = false
        local value = default
        
        local function updateSlider(input)
            local pos = input.Position.X
            local bgPos = sliderBg.AbsolutePosition.X
            local bgSize = sliderBg.AbsoluteSize.X
            local relative = math.clamp((pos - bgPos) / bgSize, 0, 1)
            value = min + (max - min) * relative
            label.Text = text .. ": " .. string.format("%.1f", value) .. suffix
            sliderFill.Size = UDim2.new(relative, 0, 1, 0)
            callback(value)
        end
        
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                updateSlider(input)
            end
        end)
        
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        yPos = yPos + 55
    end
    
    -- ========== إنشاء جميع القوائم ==========
    
    -- قسم ESP
    createSection("ESP Settings")
    createToggle("ESP Enabled", Settings.ESPEnabled, function(state)
        Settings.ESPEnabled = state
        if state then
            refreshESP()
        else
            for _, player in pairs(espInstances) do
                for _, inst in pairs(player) do
                    pcall(function() inst:Destroy() end)
                end
            end
            espInstances = {}
        end
    end)
    
    -- زر لون ESP
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, -10, 0, 35)
    colorFrame.Position = UDim2.new(0, 5, 0, yPos)
    colorFrame.BackgroundTransparency = 1
    colorFrame.Parent = container
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(0, 180, 1, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "ESP Color"
    colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorLabel.Font = Enum.Font.SourceSans
    colorLabel.TextSize = 16
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = colorFrame
    
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 60, 0, 25)
    colorBtn.Position = UDim2.new(1, -65, 0.5, -12.5)
    colorBtn.BackgroundColor3 = Settings.ESPColor
    colorBtn.Text = ""
    colorBtn.BorderSizePixel = 0
    colorBtn.Parent = colorFrame
    
    colorBtn.MouseButton1Click:Connect(function()
        -- دورة ألوان
        if Settings.ESPColor == Color3.fromRGB(255,0,0) then
            Settings.ESPColor = Color3.fromRGB(0,255,0)
        elseif Settings.ESPColor == Color3.fromRGB(0,255,0) then
            Settings.ESPColor = Color3.fromRGB(0,0,255)
        elseif Settings.ESPColor == Color3.fromRGB(0,0,255) then
            Settings.ESPColor = Color3.fromRGB(255,255,0)
        elseif Settings.ESPColor == Color3.fromRGB(255,255,0) then
            Settings.ESPColor = Color3.fromRGB(255,0,255)
        elseif Settings.ESPColor == Color3.fromRGB(255,0,255) then
            Settings.ESPColor = Color3.fromRGB(0,255,255)
        else
            Settings.ESPColor = Color3.fromRGB(255,0,0)
        end
        colorBtn.BackgroundColor3 = Settings.ESPColor
        refreshESP()
    end)
    
    yPos = yPos + 40
    
    -- قسم Aimbot
    createSection("Aimbot Settings")
    createToggle("Aimbot Enabled", Settings.AimbotEnabled, function(state)
        Settings.AimbotEnabled = state
        updateFOV()
    end)
    
    createToggle("Show FOV", Settings.ShowFOV, function(state)
        Settings.ShowFOV = state
        updateFOV()
    end)
    
    createDropdown("Target Part", {"Head", "HumanoidRootPart"}, Settings.TargetPart, function(opt)
        Settings.TargetPart = opt
    end)
    
    createSlider("Smoothness", 0, 1, Settings.Smoothness, function(val)
        Settings.Smoothness = val
    end, "")
    
    createSlider("FOV Size", 50, 400, Settings.FOVSize, function(val)
        Settings.FOVSize = val
        updateFOV()
    end, "px")
    
    -- تحديث حجم المحتوى
    container.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
end

-- تشغيل الـ GUI بعد تحميل اللعبة
task.wait(1)
pcall(createGUI)

-- تحديث ESP عند بدء التشغيل
refreshESP()

print("ESP + Aimbot with FULL GUI loaded successfully!")
