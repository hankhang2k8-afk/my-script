local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local selectedTarget = nil
local savedLocations = {} 
local locationCounter = 0

-- Các biến cho tính năng
local hoverHeight, hoverKey, isHovering, positionLock = 35, Enum.KeyCode.C, false, nil
local mouseTpKey, isBindingMouseTp = Enum.KeyCode.X, false
local isDraggingSlider, isBindingHover = false, false

-- Biến cho ESP
local espEnabled, espColor, espMaxDistance = false, Color3.fromRGB(255, 0, 100), 2000
local espMode = "ALL" -- "ALL" hoặc "PLAYERS"
local activeESPs, espTargets = {}, {}
local isDraggingEspSlider = false

local function releaseHover()
	if positionLock then positionLock:Destroy(); positionLock = nil end
	isHovering = false
end

-- BƯỚC 1: KHỞI TẠO UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuantumTeleportTabsGui"; screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local soundFolder = Instance.new("Folder", screenGui); soundFolder.Name = "UISounds"
local function createSound(id, vol, pitch)
	local snd = Instance.new("Sound", soundFolder)
	snd.SoundId = "rbxassetid://" .. id; snd.Volume = vol or 0.2; snd.PlaybackSpeed = pitch or 1
	return snd
end
local sfx_hover = createSound("8505085609", 0.08, 1.2)
local sfx_click = createSound("8505086088", 0.2, 1)
local sfx_open = createSound("6042080345", 0.2, 1.5)
local sfx_close = createSound("6042080345", 0.2, 1.1)
local sfx_teleport = createSound("4400508003", 0.3, 1.8)

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 520, 0, 320); mainFrame.Position = UDim2.new(0.5, -260, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30); mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5); mainFrame.ClipsDescendants = true 

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2; uiStroke.Color = Color3.fromRGB(255, 255, 255); uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local uiGradient = Instance.new("UIGradient", uiStroke)
uiGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 100)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(150, 0, 255)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 150, 255)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 150)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 200, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 100))
})

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -34, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(235, 87, 87); closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.Font = Enum.Font.GothamBold; closeBtn.ZIndex = 5
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- BƯỚC 2: TẠO SIDEBAR
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 150, 1, 0); sidebar.BackgroundTransparency = 1

local appTitle = Instance.new("TextLabel", sidebar)
appTitle.Size = UDim2.new(1, 0, 0, 40); appTitle.Position = UDim2.new(0, 0, 0, 5)
appTitle.BackgroundTransparency = 1; appTitle.Text = "TÍNH NĂNG"; appTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
appTitle.Font = Enum.Font.GothamBold; appTitle.TextSize = 14

local function createSidebarBtn(text, yPos, active)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -20, 0, 35); btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = active and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(30, 30, 35)
    btn.Text = text; btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local tabPlayerBtn   = createSidebarBtn("NGƯỜI CHƠI", 50, true)
local tabWaypointBtn = createSidebarBtn("VỊ TRÍ ĐÃ LƯU", 95, false)
local tabHoverBtn    = createSidebarBtn("LƠ LỬNG", 140, false)
local tabMouseTpBtn  = createSidebarBtn("TELEPORT CHUỘT", 185, false)
local tabEspBtn      = createSidebarBtn("ESP (NHÌN XUYÊN)", 230, false)

local creditLabel = Instance.new("TextLabel", sidebar)
creditLabel.Size = UDim2.new(1, 0, 0, 20); creditLabel.Position = UDim2.new(0, 0, 1, -25)
creditLabel.BackgroundTransparency = 1; creditLabel.Text = "cre: Mewwcutixam🐧💧"
creditLabel.TextColor3 = Color3.fromRGB(255, 255, 255); creditLabel.Font = Enum.Font.GothamBold; creditLabel.TextSize = 11
local creditGradient = Instance.new("UIGradient", creditLabel); creditGradient.Color = uiGradient.Color

local separator = Instance.new("Frame", mainFrame)
separator.Size = UDim2.new(0, 2, 1, -40); separator.Position = UDim2.new(0, 150, 0, 20)
separator.BackgroundColor3 = Color3.fromRGB(50, 50, 55); separator.BorderSizePixel = 0

-- BƯỚC 3: QUÉT ESP & ANIMATION
local function scanWorkspaceForESP()
    while espEnabled do
        local found = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then found[p.Character] = hrp end
            end
        end
        if espMode == "ALL" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= localPlayer.Character and not found[obj] then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then found[obj] = hrp end
                end
            end
        end
        espTargets = found
        task.wait(1.5) 
    end
end

RunService.RenderStepped:Connect(function()
	if mainFrame.Visible then
		local rotation = (tick() * 60) % 360
		uiGradient.Rotation = rotation; creditGradient.Rotation = rotation
		uiStroke.Transparency = 0.35 + math.sin(tick() * 2.5) * 0.25 
	end
	
	if isHovering then
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.MoveDirection.Magnitude > 0 then releaseHover() end
	end

    if espEnabled then
		local myPos = localPlayer.Character and localPlayer.Character.PrimaryPart and localPlayer.Character.PrimaryPart.Position
		if myPos then
            for model, gui in pairs(activeESPs) do
                if not espTargets[model] or not model.Parent then
                    gui:Destroy(); activeESPs[model] = nil
                end
            end
			for model, hrp in pairs(espTargets) do
                local dist = (hrp.Position - myPos).Magnitude
                if dist <= espMaxDistance then
                    if not activeESPs[model] then
                        local bgui = Instance.new("BillboardGui")
                        bgui.Name = "ESPCircle"; bgui.AlwaysOnTop = true; bgui.Size = UDim2.new(5, 0, 5, 0); bgui.LightInfluence = 0
                        local frame = Instance.new("Frame", bgui)
                        frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1
                        local stroke = Instance.new("UIStroke", frame)
                        stroke.Thickness = 3; stroke.Color = espColor
                        Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
                        bgui.Parent = hrp; activeESPs[model] = bgui
                    end
                else
                    if activeESPs[model] then activeESPs[model]:Destroy(); activeESPs[model] = nil end
                end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if selectedTarget == player then selectedTarget = nil end
end)

-- BƯỚC 4: TẠO CONTENT AREA 
local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, -152, 1, 0); contentArea.Position = UDim2.new(0, 152, 0, 0)
contentArea.BackgroundTransparency = 1

local function createTitle(parent, text)
    local t = Instance.new("TextLabel", parent)
    t.Size = UDim2.new(1, -40, 0, 40); t.Position = UDim2.new(0, 20, 0, 5)
    t.BackgroundTransparency = 1; t.Text = text; t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left; t.TextSize = 14
end

---------------------------------------------
-- TAB 1: NGƯỜI CHƠI
---------------------------------------------
local playerTab = Instance.new("Frame", contentArea)
playerTab.Size = UDim2.new(1, 0, 1, 0); playerTab.BackgroundTransparency = 1
createTitle(playerTab, "DỊCH CHUYỂN TỚI NGƯỜI CHƠI")

local dropdownBtn = Instance.new("TextButton", playerTab)
dropdownBtn.Size = UDim2.new(1, -40, 0, 40); dropdownBtn.Position = UDim2.new(0, 20, 0, 50)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); dropdownBtn.Text = "CHỌN NGƯỜI CHƠI ▼"
dropdownBtn.TextColor3 = Color3.fromRGB(200, 200, 200); dropdownBtn.Font = Enum.Font.GothamSemibold; dropdownBtn.TextSize = 13
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)

local playerScrollFrame = Instance.new("ScrollingFrame", playerTab)
playerScrollFrame.Size = UDim2.new(1, -40, 0, 140); playerScrollFrame.Position = UDim2.new(0, 20, 0, 95)
playerScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40); playerScrollFrame.BorderSizePixel = 0
playerScrollFrame.ScrollBarThickness = 4; playerScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerScrollFrame.Visible = false; playerScrollFrame.ZIndex = 5; playerScrollFrame.ClipsDescendants = true
Instance.new("UICorner", playerScrollFrame).CornerRadius = UDim.new(0, 8)
local pListLayout = Instance.new("UIListLayout", playerScrollFrame); pListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local teleportBtn = Instance.new("TextButton", playerTab)
teleportBtn.Size = UDim2.new(1, -40, 0, 45); teleportBtn.Position = UDim2.new(0, 20, 1, -65)
teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); teleportBtn.Text = "KHỞI ĐỘNG DỊCH CHUYỂN"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255); teleportBtn.Font = Enum.Font.GothamBold; teleportBtn.ZIndex = 1
Instance.new("UICorner", teleportBtn).CornerRadius = UDim.new(0, 8)

---------------------------------------------
-- TAB 2: VỊ TRÍ
---------------------------------------------
local waypointTab = Instance.new("Frame", contentArea)
waypointTab.Size = UDim2.new(1, 0, 1, 0); waypointTab.BackgroundTransparency = 1; waypointTab.Visible = false
createTitle(waypointTab, "QUẢN LÝ VỊ TRÍ")

local saveBtn = Instance.new("TextButton", waypointTab)
saveBtn.Size = UDim2.new(1, -40, 0, 40); saveBtn.Position = UDim2.new(0, 20, 0, 50)
saveBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50); saveBtn.Text = "LƯU VỊ TRÍ HIỆN TẠI"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255); saveBtn.Font = Enum.Font.GothamBold; saveBtn.TextSize = 13
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)

local locScrollFrame = Instance.new("ScrollingFrame", waypointTab)
locScrollFrame.Size = UDim2.new(1, -40, 1, -115); locScrollFrame.Position = UDim2.new(0, 20, 0, 100)
locScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40); locScrollFrame.BorderSizePixel = 0
locScrollFrame.ScrollBarThickness = 4; locScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", locScrollFrame).CornerRadius = UDim.new(0, 8)
local locListLayout = Instance.new("UIListLayout", locScrollFrame); locListLayout.SortOrder = Enum.SortOrder.LayoutOrder

---------------------------------------------
-- TAB 3: HOVER
---------------------------------------------
local hoverTab = Instance.new("Frame", contentArea)
hoverTab.Size = UDim2.new(1, 0, 1, 0); hoverTab.BackgroundTransparency = 1; hoverTab.Visible = false
createTitle(hoverTab, "CÀI ĐẶT BAY LƠ LỬNG")

local bindHoverBtn = Instance.new("TextButton", hoverTab)
bindHoverBtn.Size = UDim2.new(1, -40, 0, 40); bindHoverBtn.Position = UDim2.new(0, 20, 0, 50)
bindHoverBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); bindHoverBtn.Text = "PHÍM KÍCH HOẠT: C"
bindHoverBtn.TextColor3 = Color3.fromRGB(200, 200, 200); bindHoverBtn.Font = Enum.Font.GothamSemibold; bindHoverBtn.TextSize = 13
Instance.new("UICorner", bindHoverBtn).CornerRadius = UDim.new(0, 8)

local sliderContainer = Instance.new("Frame", hoverTab)
sliderContainer.Size = UDim2.new(1, -40, 0, 60); sliderContainer.Position = UDim2.new(0, 20, 0, 110)
sliderContainer.BackgroundTransparency = 1

local sliderLabel = Instance.new("TextLabel", sliderContainer)
sliderLabel.Size = UDim2.new(1, 0, 0, 20); sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "ĐỘ CAO: 35 STUDS"; sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sliderLabel.Font = Enum.Font.GothamSemibold; sliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local sliderBG = Instance.new("TextButton", sliderContainer)
sliderBG.Size = UDim2.new(1, 0, 0, 14); sliderBG.Position = UDim2.new(0, 0, 0, 30)
sliderBG.BackgroundColor3 = Color3.fromRGB(35, 35, 40); sliderBG.Text = ""; sliderBG.AutoButtonColor = false
Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame", sliderBG)
sliderFill.Size = UDim2.new((35-5)/(200-5), 0, 1, 0); sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderKnob = Instance.new("Frame", sliderFill)
sliderKnob.Size = UDim2.new(0, 18, 0, 18); sliderKnob.Position = UDim2.new(1, -9, 0.5, -9)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

---------------------------------------------
-- TAB 4: MOUSE TELEPORT
---------------------------------------------
local mouseTpTab = Instance.new("Frame", contentArea)
mouseTpTab.Size = UDim2.new(1, 0, 1, 0); mouseTpTab.BackgroundTransparency = 1; mouseTpTab.Visible = false
createTitle(mouseTpTab, "DỊCH CHUYỂN TỚI CON TRỎ")

local bindMouseTpBtn = Instance.new("TextButton", mouseTpTab)
bindMouseTpBtn.Size = UDim2.new(1, -40, 0, 40); bindMouseTpBtn.Position = UDim2.new(0, 20, 0, 50)
bindMouseTpBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); bindMouseTpBtn.Text = "PHÍM KÍCH HOẠT: X"
bindMouseTpBtn.TextColor3 = Color3.fromRGB(200, 200, 200); bindMouseTpBtn.Font = Enum.Font.GothamSemibold; bindMouseTpBtn.TextSize = 13
Instance.new("UICorner", bindMouseTpBtn).CornerRadius = UDim.new(0, 8)

local mtpDesc = Instance.new("TextLabel", mouseTpTab)
mtpDesc.Size = UDim2.new(1, -40, 0, 40); mtpDesc.Position = UDim2.new(0, 20, 0, 100)
mtpDesc.BackgroundTransparency = 1; mtpDesc.Text = "Chỉ chuột vào vị trí bất kỳ rồi nhấn phím tắt để dịch chuyển lập tức."
mtpDesc.TextColor3 = Color3.fromRGB(150, 150, 150); mtpDesc.Font = Enum.Font.Gotham
mtpDesc.TextWrapped = true; mtpDesc.TextXAlignment = Enum.TextXAlignment.Left; mtpDesc.TextYAlignment = Enum.TextYAlignment.Top

---------------------------------------------
-- TAB 5: ESP QUÉT MAP
---------------------------------------------
local espTab = Instance.new("Frame", contentArea)
espTab.Size = UDim2.new(1, 0, 1, 0); espTab.BackgroundTransparency = 1; espTab.Visible = false
createTitle(espTab, "CÀI ĐẶT ESP QUÉT MAP")

local toggleEspBtn = Instance.new("TextButton", espTab)
toggleEspBtn.Size = UDim2.new(1, -40, 0, 35); toggleEspBtn.Position = UDim2.new(0, 20, 0, 45)
toggleEspBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); toggleEspBtn.Text = "TRẠNG THÁI: TẮT"
toggleEspBtn.TextColor3 = Color3.fromRGB(235, 87, 87); toggleEspBtn.Font = Enum.Font.GothamBold; toggleEspBtn.TextSize = 13
Instance.new("UICorner", toggleEspBtn).CornerRadius = UDim.new(0, 8)

local espModeBtn = Instance.new("TextButton", espTab)
espModeBtn.Size = UDim2.new(1, -40, 0, 35); espModeBtn.Position = UDim2.new(0, 20, 0, 85)
espModeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); espModeBtn.Text = "CHẾ ĐỘ: TẤT CẢ (NGƯỜI + BOSS)"
espModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200); espModeBtn.Font = Enum.Font.GothamSemibold; espModeBtn.TextSize = 13
Instance.new("UICorner", espModeBtn).CornerRadius = UDim.new(0, 8)

local colorLabel = Instance.new("TextLabel", espTab)
colorLabel.Size = UDim2.new(1, -40, 0, 20); colorLabel.Position = UDim2.new(0, 20, 0, 130)
colorLabel.BackgroundTransparency = 1; colorLabel.Text = "CHỌN MÀU VÒNG SÁNG"
colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255); colorLabel.Font = Enum.Font.GothamSemibold; colorLabel.TextXAlignment = Enum.TextXAlignment.Left

local colorFrame = Instance.new("Frame", espTab)
colorFrame.Size = UDim2.new(1, -40, 0, 30); colorFrame.Position = UDim2.new(0, 20, 0, 155)
colorFrame.BackgroundTransparency = 1
local cListLayout = Instance.new("UIListLayout", colorFrame)
cListLayout.FillDirection = Enum.FillDirection.Horizontal; cListLayout.Padding = UDim.new(0, 10)

local colors = {Color3.fromRGB(255, 0, 100), Color3.fromRGB(0, 255, 150), Color3.fromRGB(0, 150, 255), Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 255, 255)}
for i, col in ipairs(colors) do
    local cBtn = Instance.new("TextButton", colorFrame)
    cBtn.Size = UDim2.new(0, 25, 0, 25); cBtn.BackgroundColor3 = col; cBtn.Text = ""
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)
    local cStroke = Instance.new("UIStroke", cBtn); cStroke.Thickness = 2; cStroke.Color = Color3.fromRGB(255, 255, 255)
    cStroke.Transparency = (i == 1) and 0 or 1
    
    cBtn.MouseEnter:Connect(function() sfx_hover:Play() end)
    cBtn.MouseButton1Click:Connect(function()
        sfx_click:Play(); espColor = col
        for _, child in ipairs(colorFrame:GetChildren()) do if child:IsA("TextButton") then child.UIStroke.Transparency = (child == cBtn) and 0 or 1 end end
        for ply, gui in pairs(activeESPs) do if gui and gui:FindFirstChild("Frame") then gui.Frame.UIStroke.Color = col end end
    end)
end

local espSliderContainer = Instance.new("Frame", espTab)
espSliderContainer.Size = UDim2.new(1, -40, 0, 50); espSliderContainer.Position = UDim2.new(0, 20, 0, 195)
espSliderContainer.BackgroundTransparency = 1

local espSliderLabel = Instance.new("TextLabel", espSliderContainer)
espSliderLabel.Size = UDim2.new(1, 0, 0, 20); espSliderLabel.BackgroundTransparency = 1
espSliderLabel.Text = "KHOẢNG CÁCH QUÉT: 2000 STUDS"; espSliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
espSliderLabel.Font = Enum.Font.GothamSemibold; espSliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local espSliderBG = Instance.new("TextButton", espSliderContainer)
espSliderBG.Size = UDim2.new(1, 0, 0, 12); espSliderBG.Position = UDim2.new(0, 0, 0, 28)
espSliderBG.BackgroundColor3 = Color3.fromRGB(35, 35, 40); espSliderBG.Text = ""; espSliderBG.AutoButtonColor = false
Instance.new("UICorner", espSliderBG).CornerRadius = UDim.new(1, 0)

local espSliderFill = Instance.new("Frame", espSliderBG)
espSliderFill.Size = UDim2.new((2000-100)/(10000-100), 0, 1, 0); espSliderFill.BackgroundColor3 = espColor
Instance.new("UICorner", espSliderFill).CornerRadius = UDim.new(1, 0)

local espSliderKnob = Instance.new("Frame", espSliderFill)
espSliderKnob.Size = UDim2.new(0, 16, 0, 16); espSliderKnob.Position = UDim2.new(1, -8, 0.5, -8)
espSliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", espSliderKnob).CornerRadius = UDim.new(1, 0)

espModeBtn.MouseButton1Click:Connect(function()
    sfx_click:Play()
    if espMode == "ALL" then
        espMode = "PLAYERS"; espModeBtn.Text = "CHẾ ĐỘ: CHỈ NGƯỜI CHƠI"; espModeBtn.TextColor3 = Color3.fromRGB(0, 150, 255)
    else
        espMode = "ALL"; espModeBtn.Text = "CHẾ ĐỘ: TẤT CẢ (NGƯỜI + BOSS)"; espModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    if espEnabled then
        for model, gui in pairs(activeESPs) do if gui then gui:Destroy() end end
        table.clear(activeESPs); table.clear(espTargets)
    end
end)

toggleEspBtn.MouseButton1Click:Connect(function()
    sfx_click:Play()
    espEnabled = not espEnabled
    if espEnabled then
        toggleEspBtn.Text = "TRẠNG THÁI: ĐANG BẬT"; toggleEspBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
        task.spawn(scanWorkspaceForESP)
    else
        toggleEspBtn.Text = "TRẠNG THÁI: TẮT"; toggleEspBtn.TextColor3 = Color3.fromRGB(235, 87, 87)
        for model, gui in pairs(activeESPs) do if gui then gui:Destroy() end end
        table.clear(activeESPs); table.clear(espTargets)
    end
end)

-- BƯỚC 5: OVERLAY & CONTEXT MENU
local closeMenuArea = Instance.new("TextButton", screenGui)
closeMenuArea.Size = UDim2.new(1, 0, 1, 0); closeMenuArea.BackgroundTransparency = 1; closeMenuArea.Text = ""
closeMenuArea.Visible = false; closeMenuArea.ZIndex = 9

local contextMenu = Instance.new("Frame", screenGui)
contextMenu.Size = UDim2.new(0, 120, 0, 90); contextMenu.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
contextMenu.Visible = false; contextMenu.ZIndex = 10
Instance.new("UICorner", contextMenu).CornerRadius = UDim.new(0, 6)

local btnRename = Instance.new("TextButton", contextMenu)
local btnHotkey = Instance.new("TextButton", contextMenu)
local btnDelete = Instance.new("TextButton", contextMenu)
local ctxLayout = Instance.new("UIListLayout", contextMenu); ctxLayout.Padding = UDim.new(0, 1)

local function styleCtxBtn(btn, text, color)
	btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = Color3.fromRGB(55, 55, 60); btn.BorderSizePixel = 0
	btn.Text = text; btn.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 12; btn.ZIndex = 10
end
styleCtxBtn(btnRename, "Đổi tên"); styleCtxBtn(btnHotkey, "Cài phím tắt"); styleCtxBtn(btnDelete, "Xóa vị trí", Color3.fromRGB(255, 100, 100))

local overlayFrame = Instance.new("Frame", mainFrame)
overlayFrame.Size = UDim2.new(1, 0, 1, 0); overlayFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlayFrame.BackgroundTransparency = 0.6; overlayFrame.Visible = false; overlayFrame.ZIndex = 20
Instance.new("UICorner", overlayFrame).CornerRadius = UDim.new(0, 12)

local renameBox = Instance.new("TextBox", overlayFrame)
renameBox.Size = UDim2.new(0.6, 0, 0, 40); renameBox.Position = UDim2.new(0.2, 0, 0.5, -20)
renameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55); renameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
renameBox.PlaceholderText = "Nhập tên mới + Enter"; renameBox.Font = Enum.Font.Gotham; renameBox.TextSize = 14; renameBox.Visible = false
Instance.new("UICorner", renameBox).CornerRadius = UDim.new(0, 8)

local hotkeyLabel = Instance.new("TextLabel", overlayFrame)
hotkeyLabel.Size = UDim2.new(1, 0, 1, 0); hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.Text = "Ấn phím bất kỳ..."; hotkeyLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
hotkeyLabel.Font = Enum.Font.GothamBold; hotkeyLabel.TextSize = 18; hotkeyLabel.Visible = false

-- BƯỚC 6: LOGIC CHUNG
local isUIPen = false; local isDropdownOpen = false; local activeCtxId = nil ; local isBindingKey = false

local buttons = {closeBtn, dropdownBtn, teleportBtn, saveBtn, tabPlayerBtn, tabWaypointBtn, tabHoverBtn, tabMouseTpBtn, tabEspBtn, bindHoverBtn, bindMouseTpBtn, toggleEspBtn, espModeBtn}
for _, b in ipairs(buttons) do b.MouseEnter:Connect(function() sfx_hover:Play() end) end

local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = input.Position; startPos = mainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local function switchTab(tabName)
    sfx_click:Play()
    playerTab.Visible = false; waypointTab.Visible = false; hoverTab.Visible = false; mouseTpTab.Visible = false; espTab.Visible = false
    
    local tabs = {Player=tabPlayerBtn, Waypoint=tabWaypointBtn, Hover=tabHoverBtn, MouseTp=tabMouseTpBtn, Esp=tabEspBtn}
    for k, btn in pairs(tabs) do btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); btn.TextColor3 = Color3.fromRGB(200, 200, 200) end
    
    isDropdownOpen = false; playerScrollFrame.Visible = false; contextMenu.Visible = false; closeMenuArea.Visible = false
    overlayFrame.Visible = false; isBindingKey = false; isBindingHover = false; isBindingMouseTp = false; activeCtxId = nil
    
    if tabName == "Player" then playerTab.Visible = true; tabPlayerBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tabName == "Waypoint" then waypointTab.Visible = true; tabWaypointBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabWaypointBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tabName == "Hover" then hoverTab.Visible = true; tabHoverBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabHoverBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tabName == "MouseTp" then mouseTpTab.Visible = true; tabMouseTpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabMouseTpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif tabName == "Esp" then espTab.Visible = true; tabEspBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end
end

tabPlayerBtn.MouseButton1Click:Connect(function() switchTab("Player") end)
tabWaypointBtn.MouseButton1Click:Connect(function() switchTab("Waypoint") end)
tabHoverBtn.MouseButton1Click:Connect(function() switchTab("Hover") end)
tabMouseTpBtn.MouseButton1Click:Connect(function() switchTab("MouseTp") end)
tabEspBtn.MouseButton1Click:Connect(function() switchTab("Esp") end)

local function updateSlider(mouseX)
    local p = math.clamp(mouseX - sliderBG.AbsolutePosition.X, 0, sliderBG.AbsoluteSize.X) / sliderBG.AbsoluteSize.X
    sliderFill.Size = UDim2.new(p, 0, 1, 0)
    hoverHeight = math.floor(5 + (200 - 5) * p); sliderLabel.Text = "ĐỘ CAO: " .. hoverHeight .. " STUDS"
end
sliderBG.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingSlider = true; updateSlider(input.Position.X) end end)

local function updateEspSlider(mouseX)
    local p = math.clamp(mouseX - espSliderBG.AbsolutePosition.X, 0, espSliderBG.AbsoluteSize.X) / espSliderBG.AbsoluteSize.X
    espSliderFill.Size = UDim2.new(p, 0, 1, 0)
    espMaxDistance = math.floor(100 + (10000 - 100) * p); espSliderLabel.Text = "KHOẢNG CÁCH QUÉT: " .. espMaxDistance .. " STUDS"
end
espSliderBG.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingEspSlider = true; updateEspSlider(input.Position.X) end end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingSlider = false; isDraggingEspSlider = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input.Position.X) end
    if isDraggingEspSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateEspSlider(input.Position.X) end
end)

local function updatePlayerList()
	for _, child in ipairs(playerScrollFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local pBtn = Instance.new("TextButton", playerScrollFrame)
			pBtn.Size = UDim2.new(1, 0, 0, 35); pBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); pBtn.BorderSizePixel = 0
			pBtn.Text = "  " .. player.Name; pBtn.TextColor3 = Color3.fromRGB(200, 200, 200); pBtn.Font = Enum.Font.GothamSemibold
			pBtn.TextSize = 13; pBtn.TextXAlignment = Enum.TextXAlignment.Left; pBtn.ZIndex = 6
			pBtn.MouseEnter:Connect(function() sfx_hover:Play() end)
			pBtn.MouseButton1Click:Connect(function()
				sfx_click:Play(); selectedTarget = player; dropdownBtn.Text = player.Name .. " ▼"
				dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255); playerScrollFrame.Visible = false; isDropdownOpen = false
			end)
		end
	end
end
dropdownBtn.MouseButton1Click:Connect(function() sfx_click:Play(); isDropdownOpen = not isDropdownOpen; playerScrollFrame.Visible = isDropdownOpen end)
Players.PlayerAdded:Connect(updatePlayerList)

teleportBtn.MouseButton1Click:Connect(function()
	sfx_click:Play()
	if selectedTarget and selectedTarget.Character and localPlayer.Character then
		local targetHRP = selectedTarget.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then releaseHover(); sfx_teleport:Play(); localPlayer.Character:PivotTo(targetHRP.CFrame * CFrame.new(0, 0, 2)) end
	end
end)

local function refreshLocationList()
	for _, child in ipairs(locScrollFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for id, data in pairs(savedLocations) do
		local locBtn = Instance.new("TextButton", locScrollFrame)
		locBtn.Size = UDim2.new(1, 0, 0, 35); locBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); locBtn.BorderSizePixel = 0
		locBtn.Text = "  " .. data.name; locBtn.TextColor3 = Color3.fromRGB(255, 255, 255); locBtn.Font = Enum.Font.GothamSemibold
		locBtn.TextSize = 13; locBtn.TextXAlignment = Enum.TextXAlignment.Left
		local keyLabel = Instance.new("TextLabel", locBtn)
		keyLabel.Size = UDim2.new(0, 40, 1, 0); keyLabel.Position = UDim2.new(1, -45, 0, 0); keyLabel.BackgroundTransparency = 1
		keyLabel.Text = data.hotkey and "["..data.hotkey.Name.."]" or ""; keyLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		keyLabel.Font = Enum.Font.GothamBold; keyLabel.TextSize = 12; keyLabel.TextXAlignment = Enum.TextXAlignment.Right
		locBtn.MouseEnter:Connect(function() sfx_hover:Play() end)
		locBtn.MouseButton1Click:Connect(function() sfx_click:Play() if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then releaseHover(); sfx_teleport:Play(); localPlayer.Character:PivotTo(data.cframe) end end)
		locBtn.MouseButton2Click:Connect(function() sfx_click:Play(); activeCtxId = id; local mousePos = UserInputService:GetMouseLocation(); contextMenu.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 35); contextMenu.Visible = true; closeMenuArea.Visible = true end)
	end
end

saveBtn.MouseButton1Click:Connect(function()
    sfx_click:Play(); local char = localPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		locationCounter = locationCounter + 1; local locId = "Loc_" .. locationCounter
		savedLocations[locId] = {name = "Vị trí " .. locationCounter, cframe = char.HumanoidRootPart.CFrame, hotkey = nil}; refreshLocationList()
	end
end)

closeMenuArea.MouseButton1Click:Connect(function() contextMenu.Visible = false; closeMenuArea.Visible = false; activeCtxId = nil end)
btnDelete.MouseButton1Click:Connect(function()
    sfx_click:Play(); if activeCtxId then savedLocations[activeCtxId] = nil; local isEmpty = true
		for _ in pairs(savedLocations) do isEmpty = false break end
		if isEmpty then locationCounter = 0 end
		refreshLocationList(); contextMenu.Visible = false; closeMenuArea.Visible = false; activeCtxId = nil
	end
end)
btnRename.MouseButton1Click:Connect(function()
    sfx_click:Play(); if activeCtxId then contextMenu.Visible = false; closeMenuArea.Visible = false; overlayFrame.Visible = true; renameBox.Visible = true; renameBox.Text = savedLocations[activeCtxId].name; renameBox:CaptureFocus() end
end)
renameBox.FocusLost:Connect(function()
	if activeCtxId and renameBox.Text ~= "" then savedLocations[activeCtxId].name = renameBox.Text; refreshLocationList() end
	overlayFrame.Visible = false; renameBox.Visible = false; activeCtxId = nil 
end)
btnHotkey.MouseButton1Click:Connect(function()
    sfx_click:Play(); if activeCtxId then contextMenu.Visible = false; closeMenuArea.Visible = false; overlayFrame.Visible = true; hotkeyLabel.Visible = true; isBindingKey = true end
end)

local function toggleUI()
	isUIPen = not isUIPen
	if isUIPen then
		sfx_open:Play(); updatePlayerList(); mainFrame.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 520, 0, 320)}):Play()
	else
		sfx_close:Play()
		isDropdownOpen = false; playerScrollFrame.Visible = false; contextMenu.Visible = false; closeMenuArea.Visible = false
		overlayFrame.Visible = false; isBindingKey = false; isBindingHover = false; isBindingMouseTp = false; activeCtxId = nil
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play(); tween.Completed:Connect(function() if not isUIPen then mainFrame.Visible = false end end)
	end
end
closeBtn.MouseButton1Click:Connect(function() sfx_click:Play(); if isUIPen then toggleUI() end end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if isBindingKey then
		if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.M then
			for id, data in pairs(savedLocations) do if data.hotkey == input.KeyCode then data.hotkey = nil end end
			if activeCtxId and savedLocations[activeCtxId] then savedLocations[activeCtxId].hotkey = input.KeyCode end
			isBindingKey = false; overlayFrame.Visible = false; hotkeyLabel.Visible = false; refreshLocationList(); activeCtxId = nil
		end; return 
	end
    if isBindingHover then
		if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.M then
			hoverKey = input.KeyCode; bindHoverBtn.Text = "PHÍM KÍCH HOẠT: " .. hoverKey.Name; isBindingHover = false; overlayFrame.Visible = false; hotkeyLabel.Visible = false
		end; return 
	end
    if isBindingMouseTp then
		if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.M then
			mouseTpKey = input.KeyCode; bindMouseTpBtn.Text = "PHÍM KÍCH HOẠT: " .. mouseTpKey.Name; isBindingMouseTp = false; overlayFrame.Visible = false; hotkeyLabel.Visible = false
		end; return 
	end
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.M then toggleUI(); return end

    if input.KeyCode == hoverKey and not isHovering then
		local character = localPlayer.Character; if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		character:PivotTo(character:GetPivot() + Vector3.new(0, hoverHeight, 0)); hrp.AssemblyLinearVelocity = Vector3.zero
		positionLock = Instance.new("AlignPosition"); positionLock.Mode = Enum.PositionAlignmentMode.OneAttachment; positionLock.Attachment0 = hrp:FindFirstChild("RootAttachment")
		positionLock.Position = hrp.Position; positionLock.MaxForce = 1000000; positionLock.Responsiveness = 200; positionLock.Parent = hrp
		isHovering = true; return
	end

    if input.KeyCode == mouseTpKey then
        local character = localPlayer.Character
        if character and character.PrimaryPart then
            releaseHover(); sfx_teleport:Play()
            character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0); character.PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            character:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)))
        end; return
    end

	for id, data in pairs(savedLocations) do
		if data.hotkey == input.KeyCode then
			if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then releaseHover(); sfx_teleport:Play(); localPlayer.Character:PivotTo(data.cframe) end
			break
		end
	end
end)