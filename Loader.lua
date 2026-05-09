-- [[ SECTION: INITIALIZATION & SERVICES ]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local UI_PARENT = (RunService:IsStudio() and LocalPlayer.PlayerGui) or (pcall(function() return CoreGui.Name end) and CoreGui) or LocalPlayer.PlayerGui

-- [[ SECTION: UTILITIES & VARIABLES ]]
local DEV_PANEL_VERSION = "v1.0"
local PANEL_TITLE = "⚙ Devansh Admin Panel"
local PILL_TITLE = "⚙ Devansh"

local COLORS = {
	Bg = Color3.fromRGB(12, 12, 20),
	Border = Color3.fromRGB(0, 200, 255),
	Text = Color3.fromRGB(210, 210, 240),
	Active = Color3.fromRGB(80, 255, 150),
	Inactive = Color3.fromRGB(80, 80, 100),
	Placeholder = Color3.fromRGB(100, 100, 120)
}

local panelPosition = isMobile and UDim2.new(1, -310, 1, -430) or UDim2.new(0, 10, 0, 10)
local pillPosition = isMobile and UDim2.new(1, -130, 1, -50) or UDim2.new(0, 10, 0, 10)

local State = {}
local Connections = {}
local Toggles = {}

-- Utility to create UI instances compactly
local function create(className, properties, children)
	local inst = Instance.new(className)
	for k, v in pairs(properties or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function addCorner(radius, parent)
	return create("UICorner", {CornerRadius = UDim.new(0, radius)}, {parent and {Parent = parent} or nil}[1] or nil)
end

local function addStroke(color, parent)
	return create("UIStroke", {Color = color, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

-- [[ SECTION: NOTIFICATION SYSTEM ]]
local NotifGui = create("ScreenGui", {Name = "DevanshNotifs", Parent = UI_PARENT, DisplayOrder = 1000})
local NotifFrame = create("Frame", {
	BackgroundTransparency = 1, Size = UDim2.new(0, 200, 1, 0),
	Position = isMobile and UDim2.new(0.5, -100, 0, 10) or UDim2.new(1, -210, 0, 10), Parent = NotifGui
})
local NotifLayout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Top}, {Parent = NotifFrame})

local function Notify(text, icon)
	local notif = create("Frame", {
		Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = COLORS.Bg, BackgroundTransparency = 0.15,
		Position = UDim2.new(1, 50, 0, 0), Parent = NotifFrame, ClipsDescendants = true
	})
	addCorner(4).Parent = notif
	create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = COLORS.Border, BorderSizePixel = 0, Parent = notif})
	create("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0),
		BackgroundTransparency = 1, Text = text, TextColor3 = COLORS.Text, TextSize = 11,
		Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = notif
	})
	create("TextLabel", {
		Size = UDim2.new(0, 30, 1, 0), BackgroundTransparency = 1, Text = icon or "✅",
		TextColor3 = COLORS.Text, TextSize = 14, Font = Enum.Font.Gotham, Parent = notif
	})
	
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	task.delay(2.5, function()
		local out = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1})
		out:Play()
		out.Completed:Connect(function() notif:Destroy() end)
	end)
end

-- [[ SECTION: COMMAND DEFINITIONS & STATE ]]
local Commands = {}

local function addCmd(cat, emoji, name, desc, isToggle, func)
	table.insert(Commands, {category = cat, emoji = emoji, name = name, desc = desc, isToggle = isToggle, active = false, func = func})
end

local function getChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getHRP() return getChar():FindFirstChild("HumanoidRootPart") end
local function getHum() return getChar():FindFirstChild("Humanoid") end

-- 🏃 Movement
addCmd("Movement", "🏃", "fly", "Smooth flying", true, function(args, state)
	if state then
		local hrp = getHRP()
		if not hrp then return end
		State.FlyBV = create("BodyVelocity", {MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.new(0,0,0), Parent = hrp})
		State.FlyBG = create("BodyGyro", {MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 9000, CFrame = Camera.CFrame, Parent = hrp})
		
		State.FlyLoop = RunService.RenderStepped:Connect(function()
			local camCF = Camera.CFrame
			local moveVec = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls():GetMoveVector()
			local vel = Vector3.new(0,0,0)
			
			if moveVec.Magnitude > 0 then
				vel = (camCF.RightVector * moveVec.X + camCF.LookVector * -moveVec.Z) * 50
			end
			if State.FlyUp then vel = vel + Vector3.new(0, 50, 0) end
			if State.FlyDown then vel = vel - Vector3.new(0, 50, 0) end
			
			State.FlyBV.Velocity = vel
			State.FlyBG.CFrame = camCF
		end)
		getHum().PlatformStand = true
		if isMobile and State.MobileFlyUI then State.MobileFlyUI.Enabled = true end
	else
		if State.FlyLoop then State.FlyLoop:Disconnect() end
		if State.FlyBV then State.FlyBV:Destroy() end
		if State.FlyBG then State.FlyBG:Destroy() end
		local hum = getHum() if hum then hum.PlatformStand = false end
		if isMobile and State.MobileFlyUI then State.MobileFlyUI.Enabled = false end
	end
end)

addCmd("Movement", "🏃", "speed", "Set walk speed (max 500)", false, function(args)
	local hum = getHum() if hum then hum.WalkSpeed = math.clamp(tonumber(args[1]) or 16, 0, 500) end
end)
addCmd("Movement", "🏃", "jump", "Set jump power", false, function(args)
	local hum = getHum() if hum then hum.UseJumpPower = true; hum.JumpPower = tonumber(args[1]) or 50 end
end)
addCmd("Movement", "🏃", "noclip", "Toggle no-clip", true, function(args, state)
	if state then
		State.NoclipLoop = RunService.Stepped:Connect(function()
			for _, p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
		end)
	else
		if State.NoclipLoop then State.NoclipLoop:Disconnect() end
	end
end)
addCmd("Movement", "🏃", "tp", "Teleport to x y z", false, function(args)
	local hrp = getHRP() if hrp and args[1] and args[2] and args[3] then hrp.CFrame = CFrame.new(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])) end
end)
addCmd("Movement", "🏃", "bringme", "Teleport to part", false, function(args)
	local hrp = getHRP() local target = Workspace:FindFirstChild(args[1] or "")
	if hrp and target and target:IsA("BasePart") then hrp.CFrame = target.CFrame end
end)
addCmd("Movement", "🏃", "gravity", "Set workspace gravity", false, function(args)
	Workspace.Gravity = tonumber(args[1]) or 196.2
end)

-- 👁️ Visual
addCmd("Visual", "👁️", "esp", "Toggle player ESP boxes", true, function(args, state)
	if state then
		State.ESPLoop = RunService.RenderStepped:Connect(function()
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = p.Character.HumanoidRootPart
					if not hrp:FindFirstChild("DevanshESP") then
						local box = create("BoxHandleAdornment", {Name="DevanshESP", Size=Vector3.new(4,5.5,2), Adornee=hrp, AlwaysOnTop=true, ZIndex=10, Transparency=0.5, Color3=p.TeamColor and p.TeamColor.Color or COLORS.Active, Parent=hrp})
					end
				end
			end
		end)
	else
		if State.ESPLoop then State.ESPLoop:Disconnect() end
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local esp = p.Character.HumanoidRootPart:FindFirstChild("DevanshESP")
				if esp then esp:Destroy() end
			end
		end
	end
end)
addCmd("Visual", "👁️", "fov", "Set Camera FOV", false, function(args) Camera.FieldOfView = tonumber(args[1]) or 70 end)
addCmd("Visual", "👁️", "fullbright", "Max Lighting visibility", true, function(args, state)
	if state then
		State.OldAmbient = Lighting.Ambient
		State.FBLoop = RunService.RenderStepped:Connect(function() Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 2 end)
	else
		if State.FBLoop then State.FBLoop:Disconnect() Lighting.Ambient = State.OldAmbient or Color3.fromRGB(128,128,128) end
	end
end)
addCmd("Visual", "👁️", "thirdperson", "Lock to 3rd person", false, function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
addCmd("Visual", "👁️", "freecam", "Free camera", true, function(args, state)
	if state then Camera.CameraType = Enum.CameraType.Scriptable else Camera.CameraType = Enum.CameraType.Custom end
end)

-- ⚔️ Combat
addCmd("Combat", "⚔️", "godmode", "Invincibility loop", true, function(args, state)
	if state then State.GodLoop = RunService.RenderStepped:Connect(function() local h = getHum() if h then h.Health = h.MaxHealth end end)
	else if State.GodLoop then State.GodLoop:Disconnect() end end
end)
addCmd("Combat", "⚔️", "infinite_jump", "Unlimited jumping", true, function(args, state)
	if state then State.InfJump = UserInputService.JumpRequest:Connect(function() local h = getHum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end)
	else if State.InfJump then State.InfJump:Disconnect() end end
end)
addCmd("Combat", "⚔️", "hitbox", "Expand HRP hitbox", false, function(args)
	local size = tonumber(args[1]) or 2
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			p.Character.HumanoidRootPart.Size = Vector3.new(size, size, size)
			p.Character.HumanoidRootPart.Transparency = 0.8
		end
	end
end)

-- 🌍 World
addCmd("World", "🌍", "time", "Set ClockTime", false, function(args) Lighting.ClockTime = tonumber(args[1]) or 14 end)
addCmd("World", "🌍", "fog", "Set FogEnd", false, function(args) Lighting.FogEnd = tonumber(args[1]) or 100000 end)
addCmd("World", "🌍", "ambient", "Set Ambient RGB", false, function(args)
	if args[1] and args[2] and args[3] then Lighting.Ambient = Color3.fromRGB(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])) end
end)

-- 👤 Player
addCmd("Player", "👤", "invisible", "Make char transparent", false, function()
	for _, p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = 1 end end
end)
addCmd("Player", "👤", "visible", "Restore visibility", false, function()
	for _, p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" or p:IsA("Decal") then p.Transparency = 0 end end
end)
addCmd("Player", "👤", "char", "Load appearance (UserId)", false, function(args)
	local h = getHum() if h and args[1] then h:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(tonumber(args[1]))) end
end)
addCmd("Player", "👤", "resetchar", "Reset character", false, function() local h = getHum() if h then h.Health = 0 end end)
addCmd("Player", "👤", "name", "Custom overhead name", false, function(args)
	local head = getChar():FindFirstChild("Head")
	if head then
		local bg = create("BillboardGui", {Name="DevName", Size=UDim2.new(0,100,0,30), StudsOffset=Vector3.new(0,2,0), Parent=head})
		create("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=table.concat(args, " "), TextColor3=COLORS.Border, TextScaled=true, Font=Enum.Font.GothamBold, Parent=bg})
	end
end)

-- 🔧 Utility
addCmd("Utility", "🔧", "showstats", "HUD (FPS/Ping)", true, function(args, state)
	if state then
		State.StatsUI = create("ScreenGui", {Parent = UI_PARENT, Name = "DevStats"})
		local frame = create("Frame", {Size = UDim2.new(0, 120, 0, 50), Position = UDim2.new(0, 10, 0, 10), BackgroundColor3 = COLORS.Bg, BackgroundTransparency = 0.15, Parent = State.StatsUI})
		addCorner(4, frame); addStroke(COLORS.Border, frame)
		local txt = create("TextLabel", {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Code, Parent = frame})
		State.StatsLoop = RunService.RenderStepped:Connect(function()
			txt.Text = "FPS: " .. math.floor(1 / RunService.RenderStepped:Wait()) .. "\nPing: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms"
		end)
	else
		if State.StatsLoop then State.StatsLoop:Disconnect() end
		if State.StatsUI then State.StatsUI:Destroy() end
	end
end)
addCmd("Utility", "🔧", "delhats", "Remove accessories", false, function() local h = getHum() if h then h:RemoveAccessories() end end)

-- ⭐ Fun
addCmd("Fun", "⭐", "spin", "Spin via BodyAngularVel", true, function(args, state)
	local hrp = getHRP()
	if state and hrp then
		State.SpinVel = create("BodyAngularVelocity", {MaxTorque=Vector3.new(9e9,9e9,9e9), AngularVelocity=Vector3.new(0, 50, 0), Parent=hrp})
	else
		if State.SpinVel then State.SpinVel:Destroy() end
	end
end)
addCmd("Fun", "⭐", "bighead", "Resize head", false, function(args)
	local head = getChar():FindFirstChild("Head") local s = tonumber(args[1]) or 3
	if head then head.Size = Vector3.new(s, s, s) end
end)
addCmd("Fun", "⭐", "trail", "Rainbow trail", true, function(args, state)
	local hrp = getHRP()
	if state and hrp then
		local a0 = create("Attachment", {Position=Vector3.new(0,1,0), Parent=hrp})
		local a1 = create("Attachment", {Position=Vector3.new(0,-1,0), Parent=hrp})
		State.TrailObj = create("Trail", {Attachment0=a0, Attachment1=a1, Color=ColorSequence.new(COLORS.Border), Parent=hrp})
	else
		if State.TrailObj then State.TrailObj.Attachment0:Destroy() State.TrailObj.Attachment1:Destroy() State.TrailObj:Destroy() end
	end
end)

-- [[ SECTION: COMMAND PARSER ]]
local function executeCommand(inputStr)
	local args = string.split(inputStr, " ")
	local cmdName = table.remove(args, 1):lower():gsub("^/", "")
	
	local toggleOff = (args[1] and args[1]:lower() == "off")
	if toggleOff then table.remove(args, 1) end

	for _, cmd in ipairs(Commands) do
		if cmd.name == cmdName then
			local success, err = pcall(function()
				if cmd.isToggle then
					cmd.active = not toggleOff
					cmd.func(args, cmd.active)
					-- Update UI Toggle Dot visually
					if Toggles[cmd.name] then
						Toggles[cmd.name].TextColor3 = cmd.active and COLORS.Active or COLORS.Inactive
					end
					Notify("Toggled " .. cmdName .. (cmd.active and " ON" or " OFF"))
				else
					cmd.func(args)
					Notify("Executed " .. cmdName)
				end
			end)
			if not success then Notify("Error: " .. cmdName, "⚠️") warn(err) end
			return
		end
	end
	Notify("Unknown command: " .. cmdName, "❌")
end

-- [[ SECTION: GUI CREATION ]]
local MainGui = create("ScreenGui", {Name = "DevanshAdminPanel", Parent = UI_PARENT, ResetOnSpawn = false})

-- Pill Button (Collapsed State)
local PillBtn = create("TextButton", {
	Size = UDim2.new(0, 120, 0, 32), Position = pillPosition, BackgroundColor3 = COLORS.Bg,
	BackgroundTransparency = 0.15, Text = PILL_TITLE, TextColor3 = COLORS.Text,
	Font = Enum.Font.GothamBold, TextSize = 12, Parent = MainGui
})
addCorner(8, PillBtn); addStroke(COLORS.Border, PillBtn)

-- Main Panel (Expanded State)
local pWidth, pHeight = isMobile and 300 or 280, isMobile and 420 or 380
local PanelFrame = create("Frame", {
	Size = UDim2.new(0, pWidth, 0, pHeight), Position = panelPosition,
	BackgroundColor3 = COLORS.Bg, BackgroundTransparency = 0.15, Visible = false, Parent = MainGui
})
addCorner(8, PanelFrame); addStroke(COLORS.Border, PanelFrame)

-- Top Bar
local TopBar = create("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = PanelFrame})
create("TextLabel", {
	Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
	Text = PANEL_TITLE, TextColor3 = COLORS.Text, Font = Enum.Font.GothamBold, TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar
})
local MinBtn = create("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -54, 0, 2), BackgroundTransparency = 1, Text = "—", TextColor3 = COLORS.Text, Font = Enum.Font.Gotham, TextSize = 14, Parent = TopBar})
local CloseBtn = create("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -26, 0, 2), BackgroundTransparency = 1, Text = "✕", TextColor3 = COLORS.Text, Font = Enum.Font.Gotham, TextSize = 14, Parent = TopBar})

-- Category Tabs
local TabsFrame = create("ScrollingFrame", {
	Size = UDim2.new(1, -10, 0, 32), Position = UDim2.new(0, 5, 0, 30), BackgroundTransparency = 1,
	CanvasSize = UDim2.new(0, 260, 0, 0), ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, Parent = PanelFrame
})
local TabListLayout = create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), Parent = TabsFrame})

-- Command List
local ListFrame = create("ScrollingFrame", {
	Size = UDim2.new(1, -10, 1, -100), Position = UDim2.new(0, 5, 0, 65), BackgroundTransparency = 1,
	ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = PanelFrame
})
local CmdListLayout = create("UIListLayout", {Padding = UDim.new(0, 2), Parent = ListFrame})

-- Input Bar
local InputFrame = create("Frame", {Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 1, -35), BackgroundTransparency = 1, Parent = PanelFrame})
local CmdInput = create("TextBox", {
	Size = UDim2.new(1, -35, 1, 0), BackgroundColor3 = Color3.fromRGB(20, 20, 30), BackgroundTransparency = 0.2,
	Text = "", PlaceholderText = "/command args...", TextColor3 = COLORS.Text, Font = Enum.Font.Code,
	TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = InputFrame
})
addCorner(4, CmdInput); addStroke(COLORS.Placeholder, CmdInput)
create("UIPadding", {PaddingLeft = UDim.new(0, 8), Parent = CmdInput})

local RunBtn = create("TextButton", {
	Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 0, 0), BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.2, Text = "▶", TextColor3 = COLORS.Border, Font = Enum.Font.Gotham, TextSize = 12, Parent = InputFrame
})
addCorner(4, RunBtn); addStroke(COLORS.Placeholder, RunBtn)

-- Footer
create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -12), BackgroundTransparency = 1,
	Text = "Devansh Admin Panel • Universal • " .. DEV_PANEL_VERSION, TextColor3 = COLORS.Placeholder,
	Font = Enum.Font.Gotham, TextSize = 9, Parent = PanelFrame
})

-- [[ SECTION: POPULATE TABS & COMMANDS ]]
local activeCategory = "Movement"
local function PopulateList()
	for _, child in ipairs(ListFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local ySize = 0
	
	for _, cmd in ipairs(Commands) do
		if cmd.category == activeCategory then
			local row = create("TextButton", {Size = UDim2.new(1, -4, 0, 28), BackgroundTransparency = 1, Text = "", Parent = ListFrame})
			create("TextLabel", {Size = UDim2.new(0, 25, 1, 0), BackgroundTransparency = 1, Text = "["..cmd.emoji.."]", TextColor3 = COLORS.Text, Font = Enum.Font.Gotham, TextSize = 11, Parent = row})
			create("TextLabel", {Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(0, 25, 0, 0), BackgroundTransparency = 1, Text = cmd.name, TextColor3 = COLORS.Border, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
			create("TextLabel", {Size = UDim2.new(1, -115, 1, 0), Position = UDim2.new(0, 85, 0, 0), BackgroundTransparency = 1, Text = "— " .. cmd.desc, TextColor3 = COLORS.Placeholder, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
			
			if cmd.isToggle then
				local dot = create("TextLabel", {Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, Text = "●", TextColor3 = cmd.active and COLORS.Active or COLORS.Inactive, Font = Enum.Font.Gotham, TextSize = 14, Parent = row})
				Toggles[cmd.name] = dot
				row.MouseButton1Click:Connect(function() executeCommand("/" .. cmd.name .. (cmd.active and " off" or "")) end)
			else
				row.MouseButton1Click:Connect(function() CmdInput.Text = "/" .. cmd.name .. " "; CmdInput:CaptureFocus() end)
			end
			ySize = ySize + 30
		end
	end
	ListFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

local categories = {"Movement", "Visual", "Combat", "World", "Player", "Utility", "Fun"}
local emojis = {"🏃", "👁️", "⚔️", "🌍", "👤", "🔧", "⭐"}

for i, cat in ipairs(categories) do
	local tab = create("TextButton", {Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Color3.fromRGB(20, 20, 30), BackgroundTransparency = 0.5, Text = emojis[i], TextSize = 14, Parent = TabsFrame})
	addCorner(4, tab); addStroke(COLORS.Placeholder, tab)
	tab.MouseButton1Click:Connect(function() activeCategory = cat; PopulateList() end)
end
PopulateList()

-- [[ SECTION: GUI BEHAVIOR & DRAGGING ]]
local function dragElement(dragPart, movePart)
	local dragging, dragInput, dragStart, startPos
	dragPart.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = movePart.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	dragPart.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			movePart.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			
			-- Edge Snapping
			local pos = movePart.AbsolutePosition
			if pos.X < 10 then movePart.Position = UDim2.new(0, 10, movePart.Position.Y.Scale, movePart.Position.Y.Offset) end
			if pos.Y < 10 then movePart.Position = UDim2.new(movePart.Position.X.Scale, movePart.Position.X.Offset, 0, 10) end
			
			if movePart == PanelFrame then panelPosition = movePart.Position else pillPosition = movePart.Position end
		end
	end)
end

dragElement(TopBar, PanelFrame)
dragElement(PillBtn, PillBtn)

PillBtn.MouseButton1Click:Connect(function()
	PillBtn.Visible = false; PanelFrame.Visible = true; PanelFrame.Position = panelPosition
end)

MinBtn.MouseButton1Click:Connect(function()
	PanelFrame.Visible = false; PillBtn.Visible = true; PillBtn.Position = pillPosition
end)

CloseBtn.MouseButton1Click:Connect(function()
	PanelFrame.Visible = false; PillBtn.Visible = false
	Notify("Panel Hidden. PC: Press Right Shift to reopen.")
end)

-- Input Execution
RunBtn.MouseButton1Click:Connect(function() if CmdInput.Text ~= "" then executeCommand(CmdInput.Text); CmdInput.Text = "" end end)
CmdInput.FocusLost:Connect(function(enterPressed) if enterPressed and CmdInput.Text ~= "" then executeCommand(CmdInput.Text); CmdInput.Text = "" end end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		local isVis = PanelFrame.Visible or PillBtn.Visible
		if isVis then PanelFrame.Visible = false; PillBtn.Visible = false
		else PillBtn.Visible = true; PillBtn.Position = pillPosition end
	elseif input.KeyCode == Enum.KeyCode.F1 then executeCommand("/fly")
	elseif input.KeyCode == Enum.KeyCode.F2 then executeCommand("/noclip")
	elseif input.KeyCode == Enum.KeyCode.F3 then executeCommand("/esp")
	elseif input.KeyCode == Enum.KeyCode.F4 then executeCommand("/fullbright")
	end
end)

-- [[ SECTION: MOBILE FLY D-PAD OVERLAY ]]
if isMobile then
	State.MobileFlyUI = create("ScreenGui", {Name = "DevFlyMobile", Enabled = false, Parent = UI_PARENT})
	local mFlyFrame = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = State.MobileFlyUI})
	
	local upBtn = create("TextButton", {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(1, -70, 1, -140), BackgroundColor3 = COLORS.Bg, BackgroundTransparency = 0.5, Text = "▲", TextColor3 = COLORS.Text, TextSize = 20, Parent = mFlyFrame})
	local dnBtn = create("TextButton", {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(1, -70, 1, -70), BackgroundColor3 = COLORS.Bg, BackgroundTransparency = 0.5, Text = "▼", TextColor3 = COLORS.Text, TextSize = 20, Parent = mFlyFrame})
	local exitBtn = create("TextButton", {Size = UDim2.new(0, 80, 0, 30), Position = UDim2.new(0.5, -40, 0, 20), BackgroundColor3 = COLORS.Bg, BackgroundTransparency = 0.2, Text = "✕ Land", TextColor3 = COLORS.Text, Font = Enum.Font.Gotham, TextSize = 12, Parent = mFlyFrame})
	addCorner(25, upBtn); addCorner(25, dnBtn); addCorner(8, exitBtn)
	
	upBtn.InputBegan:Connect(function() State.FlyUp = true end)
	upBtn.InputEnded:Connect(function() State.FlyUp = false end)
	dnBtn.InputBegan:Connect(function() State.FlyDown = true end)
	dnBtn.InputEnded:Connect(function() State.FlyDown = false end)
	exitBtn.MouseButton1Click:Connect(function() executeCommand("/fly off") end)
end

-- Initialize
Notify("Devansh Admin Panel Loaded", "⚙")
if not isMobile then Notify("Press Right Shift to toggle", "⌨️") end

