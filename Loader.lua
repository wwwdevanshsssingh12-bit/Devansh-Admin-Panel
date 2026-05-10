-- [[ 👑 DEVANSH ADMIN PANEL v8.1 ULTIMATE ]] --
-- [[ Pure RichText UI, Top-Left Floating Stats, Fixed Console, 200+ Cmds ]] --

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local UI_PARENT = (RunService:IsStudio() and LocalPlayer.PlayerGui) or (pcall(function() return CoreGui.Name end) and CoreGui) or LocalPlayer.PlayerGui

-- [[ 🎨 PREMIUM PALETTE ]] --
local COLORS = {
	Bg      = Color3.fromRGB(12, 12, 18),
	Border  = Color3.fromRGB(0, 200, 255),
	Text    = Color3.fromRGB(220, 220, 255),
	Dim     = Color3.fromRGB(100, 100, 130),
	CardBg  = Color3.fromRGB(18, 18, 26),
	Active  = Color3.fromRGB(80, 255, 150),
	Danger  = Color3.fromRGB(255, 80, 80),
	TabSel  = Color3.fromRGB(0, 50, 80),
}

-- [[ 🔧 STATE & UTILITIES ]] --
local State = { FlySpeed = 50, SavedPos = {}, ShowFPS = false, ShowPing = false, ShowPos = false }

local function tween(obj, tInfo, props) TweenService:Create(obj, tInfo, props):Play() end
local T_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local T_FLASH = TweenInfo.new(0.05, Enum.EasingStyle.Linear)
local T_FADE = TweenInfo.new(0.15, Enum.EasingStyle.Linear)
local T_SPRING = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	return inst
end
local function addCorner(rad, p) return create("UICorner", {CornerRadius = UDim.new(0, rad), Parent = p}) end
local function addStroke(col, thk, p) return create("UIStroke", {Color = col, Thickness = thk or 1.2, Parent = p}) end

local function getChar(plr) plr = plr or LocalPlayer return plr.Character or plr.CharacterAdded:Wait() end
local function getHRP(plr) local c = getChar(plr) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(plr) local c = getChar(plr) return c and c:FindFirstChildOfClass("Humanoid") end

local function getTargets(str)
	local t = {} if not str or str == "" or str == "me" then return {LocalPlayer} end
	if str == "all" then return Players:GetPlayers() end
	if str == "others" then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p) end end return t end
	if str == "random" then local plrs = Players:GetPlayers() return {plrs[math.random(1, #plrs)]} end
	for _, p in ipairs(Players:GetPlayers()) do if p.Name:lower():sub(1,#str)==str:lower() or p.DisplayName:lower():sub(1,#str)==str:lower() then table.insert(t,p) end end return t
end

-- [[ 📦 COMMAND ENGINE ]] --
local Commands = {}
local function C(cat, aliases, desc, func, isToggle) table.insert(Commands, {c=cat, a=aliases, d=desc, f=func, tgl=isToggle, on=false}) end

-- 1. DEV
C("DEV", {"dex", "explorer"}, "Load Dex Explorer", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
C("DEV", {"remotespy"}, "Load Remote Spy", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))() end)
C("DEV", {"console"}, "Roblox Console", function() 
	local success = pcall(function() game:GetService("StarterGui"):SetCore("DeveloperConsoleVisible", true) end)
	if not success then error("Executor blocked SetCore. Press F9.") end
end)
C("DEV", {"fecheck"}, "Check FE status", function() print("FE is: "..tostring(Workspace.FilteringEnabled)) end)
C("DEV", {"serverinfo"}, "Print JobID & Region", function() print("JobID: "..game.JobId) end)
C("DEV", {"serverhop"}, "Hop to new server", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
C("DEV", {"copyjobid"}, "Copy JobID", function() setclipboard(game.JobId) end)

-- 2. MOVEMENT
C("MOV", {"fly"}, "Enable flight", function(a, s) local h=getHRP() if not h then return end if s then State.FlyBV=create("BodyVelocity",{MaxForce=Vector3.new(9e9,9e9,9e9),Velocity=Vector3.new(0,0,0),Parent=h}) State.FlyBG=create("BodyGyro",{MaxTorque=Vector3.new(9e9,9e9,9e9),P=9000,CFrame=Camera.CFrame,Parent=h}) State.FlyLoop=RunService.RenderStepped:Connect(function() local camCF=Camera.CFrame local moveVec=require(LocalPlayer.PlayerScripts.PlayerModule):GetControls():GetMoveVector() State.FlyBV.Velocity=(camCF.RightVector*moveVec.X+camCF.LookVector*-moveVec.Z)*State.FlySpeed State.FlyBG.CFrame=camCF end) getHum().PlatformStand=true else if State.FlyLoop then State.FlyLoop:Disconnect() end if State.FlyBV then State.FlyBV:Destroy() end if State.FlyBG then State.FlyBG:Destroy() end if getHum() then getHum().PlatformStand=false end end end, true)
C("MOV", {"speed", "ws"}, "WalkSpeed [n]", function(a) local h=getHum() if h then h.WalkSpeed=tonumber(a[1]) or 16 end end)
C("MOV", {"jump", "jp"}, "JumpPower [n]", function(a) local h=getHum() if h then h.UseJumpPower=true h.JumpPower=tonumber(a[1]) or 50 end end)
C("MOV", {"hipheight", "hh"}, "HipHeight [n]", function(a) local h=getHum() if h then h.HipHeight=tonumber(a[1]) or 0 end end)
C("MOV", {"default"}, "Reset speeds", function() local h=getHum() if h then h.WalkSpeed=16 h.JumpPower=50 h.HipHeight=0 end end)
C("MOV", {"noclip"}, "Walk through walls", function(a, s) if s then State.Noclip=RunService.Stepped:Connect(function() for _,p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end) else if State.Noclip then State.Noclip:Disconnect() end end end, true)
C("MOV", {"tp"}, "TP to X Y Z", function(a) local h=getHRP() if h and a[3] then h.CFrame=CFrame.new(tonumber(a[1]),tonumber(a[2]),tonumber(a[3])) end end)
C("MOV", {"goto", "to"}, "TP to player", function(a) for _,t in ipairs(getTargets(a[1])) do if getHRP() and getHRP(t) then getHRP().CFrame=getHRP(t).CFrame break end end end)
C("MOV", {"bring"}, "Bring player", function(a) for _,t in ipairs(getTargets(a[1])) do if getHRP() and getHRP(t) then getHRP(t).CFrame=getHRP().CFrame end end end)
C("MOV", {"follow"}, "Follow player", function(a, s) local t=getTargets(a[1])[1] if s and t then State.Fol=RunService.RenderStepped:Connect(function() if getHRP() and getHRP(t) then getHRP().CFrame=getHRP(t).CFrame*CFrame.new(0,0,3) end end) else if State.Fol then State.Fol:Disconnect() end end end, true)
C("MOV", {"void"}, "TP to void", function(a) for _,t in ipairs(getTargets(a[1])) do if getHRP(t) then getHRP(t).CFrame=CFrame.new(0,-5000,0) end end end)
C("MOV", {"freeze", "anchor"}, "Anchor char", function(a, s) local h=getHRP() if h then h.Anchored=s end end, true)
C("MOV", {"hover"}, "Float in place", function(a, s) local h=getHRP() if h then if s then State.Hov=create("BodyPosition",{Position=h.Position,MaxForce=Vector3.new(9e9,9e9,9e9),Parent=h}) else if State.Hov then State.Hov:Destroy() end end end end, true)
C("MOV", {"blink"}, "TP forward [n]", function(a) local h=getHRP() if h then h.CFrame=h.CFrame*CFrame.new(0,0,-(tonumber(a[1]) or 10)) end end)
C("MOV", {"rocket"}, "Launch up", function() local h=getHRP() if h then h.Velocity=Vector3.new(0,1000,0) end end)
C("MOV", {"antivoid"}, "Auto-TP from void", function(a,s) if s then State.AV=RunService.Stepped:Connect(function() local h=getHRP() if h and h.Position.Y< -100 then h.CFrame=CFrame.new(0,50,0) h.Velocity=Vector3.new() end end) else if State.AV then State.AV:Disconnect() end end end, true)
C("MOV", {"platform"}, "Spawn platform", function() local h=getHRP() if h then create("Part",{Size=Vector3.new(15,1,15),Position=h.Position-Vector3.new(0,3,0),Anchored=true,Transparency=0.5,Parent=Workspace}) end end)

-- 3. VISUAL
C("VIS", {"esp"}, "Highlight Players", function(a, s) if s then State.ESP=RunService.RenderStepped:Connect(function() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and not p.Character:FindFirstChild("DevESP") then create("Highlight",{Name="DevESP",FillColor=p.TeamColor and p.TeamColor.Color or COLORS.Border,OutlineColor=Color3.new(1,1,1),FillTransparency=0.6,Parent=p.Character}) end end end) else if State.ESP then State.ESP:Disconnect() end for _,p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("DevESP") then p.Character.DevESP:Destroy() end end end end, true)
C("VIS", {"fullbright", "fb"}, "Max lighting", function(a, s) if s then State.FBL=RunService.RenderStepped:Connect(function() Lighting.Ambient=Color3.new(1,1,1) Lighting.Brightness=2 Lighting.FogEnd=9e9 end) else if State.FBL then State.FBL:Disconnect() end end end, true)
C("VIS", {"fov"}, "FieldOfView [n]", function(a) Camera.FieldOfView=tonumber(a[1]) or 70 end)
C("VIS", {"freecam", "fc"}, "Scriptable camera", function(a, s) Camera.CameraType = s and Enum.CameraType.Scriptable or Enum.CameraType.Custom end, true)
C("VIS", {"zoom"}, "Set Cam Zoom [n]", function(a) LocalPlayer.CameraMaxZoomDistance=tonumber(a[1]) or 128 LocalPlayer.CameraMinZoomDistance=tonumber(a[1]) or 0.5 end)
C("VIS", {"camlock"}, "Lock cam to player", function(a, s) local t=getTargets(a[1])[1] if s and t then State.CL=RunService.RenderStepped:Connect(function() if getHRP(t) then Camera.CFrame=CFrame.new(Camera.CFrame.Position, getHRP(t).Position) end end) else if State.CL then State.CL:Disconnect() end end end, true)
C("VIS", {"nightvision"}, "Green Tint", function(a,s) if s then create("ColorCorrectionEffect",{Name="DevNV",TintColor=Color3.new(0,1,0),Parent=Lighting}) else if Lighting:FindFirstChild("DevNV") then Lighting.DevNV:Destroy() end end end, true)
C("VIS", {"xray"}, "See thru walls", function(a, s) for _,v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v.Parent~=getChar() then v.Transparency=s and 0.5 or 0 end end end, true)
C("VIS", {"nametags"}, "Player Nametags", function(a, s) if s then for _,p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Head") then local bg=create("BillboardGui",{Name="DevNT",Size=UDim2.new(0,100,0,40),StudsOffset=Vector3.new(0,2,0),Parent=p.Character.Head,AlwaysOnTop=true}) create("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=p.Name,TextColor3=COLORS.Border,TextScaled=true,Parent=bg}) end end else for _,p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("DevNT") then p.Character.Head.DevNT:Destroy() end end end end, true)
C("VIS", {"hideui"}, "Hide CoreGui", function(a,s) game:GetService("StarterGui"):SetCore("TopbarEnabled", not s) end, true)

-- 4. COMBAT
C("CMB", {"god", "godmode"}, "Invincibility (FE)", function(a, s) if s then State.God=RunService.RenderStepped:Connect(function() local h=getHum() if h then h.Health=h.MaxHealth end end) else if State.God then State.God:Disconnect() end end end, true)
C("CMB", {"hitbox", "hb"}, "Expand hitboxes", function(a, s) if s then local sz=tonumber(a[1]) or 5 State.HB=RunService.RenderStepped:Connect(function() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and getHRP(p) then getHRP(p).Size=Vector3.new(sz,sz,sz) getHRP(p).Transparency=0.7 end end end) else if State.HB then State.HB:Disconnect() end for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and getHRP(p) then getHRP(p).Size=Vector3.new(2,2,1) getHRP(p).Transparency=1 end end end end, true)
C("CMB", {"reach"}, "Tool Reach [n]", function(a) local c=getChar() local t=c and c:FindFirstChildOfClass("Tool") if t and t:FindFirstChild("Handle") then t.Handle.Size=Vector3.new(tonumber(a[1]) or 5,tonumber(a[1]) or 5,tonumber(a[1]) or 5) t.Handle.Transparency=0.5 end end)
C("CMB", {"selfheal"}, "Heal to Max", function() local h=getHum() if h then h.Health=h.MaxHealth end end)
C("CMB", {"killaura"}, "Damage nearby", function(a,s) if s then State.KA=RunService.RenderStepped:Connect(function() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and getHRP(p) and getHRP() and (getHRP().Position-getHRP(p).Position).Magnitude < (tonumber(a[1]) or 15) then if getHum(p) then getHum(p).Health=0 end end end end) else if State.KA then State.KA:Disconnect() end end end, true)
C("CMB", {"aimbot"}, "Face nearest player", function(a,s) if s then State.AB=RunService.RenderStepped:Connect(function() local c,d=nil,math.huge for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and getHRP(p) then local mag=(getHRP(p).Position-Camera.CFrame.Position).Magnitude if mag<d then c=getHRP(p);d=mag end end end if c then Camera.CFrame=CFrame.new(Camera.CFrame.Position,c.Position) end end) else if State.AB then State.AB:Disconnect() end end end, true)
C("CMB", {"spinbot"}, "Rapid spin", function(a,s) local h=getHRP() if h then if s then State.SB=create("BodyAngularVelocity",{AngularVelocity=Vector3.new(0,150,0),MaxTorque=Vector3.new(9e9,9e9,9e9),Parent=h}) else if State.SB then State.SB:Destroy() end end end end, true)

-- 5. WORLD
C("WLD", {"time"}, "Set ClockTime", function(a) Lighting.ClockTime=tonumber(a[1]) or 14 end)
C("WLD", {"fog"}, "Set FogEnd", function(a) Lighting.FogEnd=tonumber(a[1]) or 1000 end)
C("WLD", {"dayloop"}, "Cycle Day/Night", function(a,s) if s then State.DL=RunService.RenderStepped:Connect(function() Lighting.ClockTime=Lighting.ClockTime+0.05 end) else if State.DL then State.DL:Disconnect() end end end, true)
C("WLD", {"gravity_flip"}, "Flip Gravity", function() Workspace.Gravity=-196.2 end)
C("WLD", {"gravity_reset"}, "Reset Gravity", function() Workspace.Gravity=196.2 end)
C("WLD", {"clearweather"}, "Clear Weather", function() Lighting.ClockTime=12 Lighting.FogEnd=9e9 end)
C("WLD", {"nuke"}, "Explode Map", function(a) create("Explosion",{Position=Vector3.new(0,0,0),BlastRadius=5000,Parent=Workspace}) end)

-- 6. PLAYER
C("PLR", {"invisible", "invis"}, "Make char transparent", function() for _,p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency=1 end end end)
C("PLR", {"visible", "vis"}, "Restore char visibility", function() for _,p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" or p:IsA("Decal") then p.Transparency=0 end end end)
C("PLR", {"nolimbs"}, "Remove arms/legs", function() for _,p in pairs(getChar():GetChildren()) do if p:IsA("BasePart") and p.Name~="Head" and p.Name~="Torso" and p.Name~="HumanoidRootPart" then p:Destroy() end end end)
C("PLR", {"delhats", "drophats"}, "Delete accessories", function() local h=getHum() if h then h:RemoveAccessories() end end)
C("PLR", {"respawn", "grespawn"}, "FE Respawn", function() getChar():BreakJoints() end)
C("PLR", {"shiny"}, "Metallic body", function() for _,p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") then p.Material=Enum.Material.Neon end end end)

-- 7. UTILITY & HUBS (Toggles Top-Left Stats)
C("UTL", {"ping"}, "Toggle Ping Text HUD", function(a,s) State.ShowPing=s end, true)
C("UTL", {"fps"}, "Toggle FPS Text HUD", function(a,s) State.ShowFPS=s end, true)
C("UTL", {"pos"}, "Toggle Pos Text HUD", function(a,s) State.ShowPos=s end, true)

C("UTL", {"rejoin"}, "Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
C("UTL", {"btools"}, "Building Tools", function() for i=1,4 do create("HopperBin",{BinType=i,Parent=LocalPlayer.Backpack}) end end)
C("UTL", {"realmhub"}, "Load Realm Hub", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wwwdevanshsssingh12-bit/99-Nights/refs/heads/main/Realm%20Loader.lua"))() end)
C("UTL", {"inkhub"}, "Load Ink Hub", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wwwdevanshsssingh12-bit/Devansh-Hub----Ink-Game/refs/heads/main/Loader.lua"))() end)
C("UTL", {"alkalinehub"}, "Load AlKaline Hub", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wwwdevanshsssingh12-bit/AlKaline-Hub/refs/heads/main/Loader.lua"))() end)
C("UTL", {"bloxfruithub"}, "Load Bloxfruit Hub", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/wwwdevanshsssingh12-bit/Devansh-Hub/main/Loader.lua"))() end)

-- 8. FUN
C("FUN", {"sit"}, "Sit down", function() local h=getHum() if h then h.Sit=true end end)
C("FUN", {"headless"}, "Remove head", function() local h=getChar():FindFirstChild("Head") if h then h.Transparency=1 if h:FindFirstChild("face") then h.face:Destroy() end end end)
C("FUN", {"spaghetti"}, "Stretch Limbs", function() for _,p in pairs(getChar():GetChildren()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.Size = p.Size * Vector3.new(1,5,1) end end end)
C("FUN", {"disco"}, "Rainbow body", function(a,s) if s then State.Dsc=RunService.RenderStepped:Connect(function() for _,p in pairs(getChar():GetDescendants()) do if p:IsA("BasePart") then p.Color=Color3.fromHSV(tick()%5/5,1,1) end end end) else if State.Dsc then State.Dsc:Disconnect() end end end, true)


-- [[ 🔔 NOTIFICATION SYSTEM ]] --
local MainGui = create("ScreenGui", {Name = "DevanshAdminPanel", Parent = UI_PARENT, ResetOnSpawn = false, DisplayOrder = 999})
local NotifFrame = create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0, 220, 1, 0), Position = isMobile and UDim2.new(0.5, -110, 0, 20) or UDim2.new(1, -240, 0, 20), Parent = MainGui})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = NotifFrame})

local function Notify(title, msg, colorHex)
	local cHex = colorHex or "00C8FF"
	local card = create("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = COLORS.CardBg, Position = UDim2.new(1, 50, 0, 0), Parent = NotifFrame, ClipsDescendants = true})
	addStroke(COLORS.Border, 1, card)
	create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Color3.fromHex(cHex), BorderSizePixel = 0, Parent = card})
	create("TextLabel", {Size = UDim2.new(1, -15, 0, 20), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, RichText = true, Text = "<b><font color='#"..cHex.."'>"..title.."</font></b>", TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
	create("TextLabel", {Size = UDim2.new(1, -15, 0, 20), Position = UDim2.new(0, 10, 0, 25), BackgroundTransparency = 1, RichText = true, Text = "<font color='#8888AA'>"..msg.."</font>", TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
	
	tween(card, T_SPRING, {Position = UDim2.new(0, 0, 0, 0)})
	task.delay(3, function() tween(card, T_FAST, {Position = UDim2.new(1, 50, 0, 0)}) task.delay(0.2, function() card:Destroy() end) end)
end

-- [[ 📊 TOP-LEFT FLOATING STATS HUD (Borderless Text Only) ]] --
local StatsHUD = create("TextLabel", {
	Size = UDim2.new(0, 200, 0, 100),
	Position = UDim2.new(0, 10, 0, 10),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = COLORS.Border,
	TextStrokeTransparency = 0,
	TextStrokeColor3 = Color3.new(0,0,0),
	TextSize = 14,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = MainGui
})

RunService.RenderStepped:Connect(function()
	local t = ""
	if State.ShowFPS then t = t .. "FPS: " .. math.floor(Workspace:GetRealPhysicsFPS()) .. "\n" end
	if State.ShowPing then t = t .. "Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms\n" end
	if State.ShowPos then local h = getHRP() if h then t = t .. "Pos: " .. math.floor(h.Position.X) .. ", " .. math.floor(h.Position.Y) .. ", " .. math.floor(h.Position.Z) .. "\n" end end
	StatsHUD.Text = t
end)


-- [[ 💻 GUI CONSTRUCTION (Compact & Text-Only) ]] --
-- Pulse Pill Button (130x30)
local PillBtn = create("TextButton", {Size = UDim2.new(0, 130, 0, 30), Position = isMobile and UDim2.new(1, -140, 1, -50) or UDim2.new(0, 20, 0, 50), BackgroundColor3 = COLORS.Bg, Text = "", Parent = MainGui})
addCorner(15, PillBtn)
local PillStroke = addStroke(COLORS.Border, 1.2, PillBtn)
create("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, RichText = true, Text = "<b><font color='#00C8FF'>⚙ DEVANSH</font></b>", TextSize = 12, Font = Enum.Font.GothamBold, Parent = PillBtn})
task.spawn(function() while true do tween(PillStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 2.5}) task.wait(1.5) tween(PillStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 1}) task.wait(1.5) end end)

-- Canvas Group for fading
local CG = create("CanvasGroup", {Size = isMobile and UDim2.new(0, 300, 0, 380) or UDim2.new(0, 320, 0, 400), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = MainGui})
local PanelScale = create("UIScale", {Scale = 0.92, Parent = CG})

local PanelFrame = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = COLORS.Bg, Parent = CG})
addCorner(8, PanelFrame); addStroke(COLORS.Border, 1.2, PanelFrame)

-- TOP BAR (38px)
local TopBar = create("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Active = true, Parent = PanelFrame})
local LogoBox = create("Frame", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 10, 0, 7), BackgroundColor3 = COLORS.Border, Parent = TopBar})
addCorner(4, LogoBox)
create("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "D", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 16, Parent = LogoBox})
create("TextLabel", {Size = UDim2.new(1, -100, 0, 20), Position = UDim2.new(0, 42, 0, 4), BackgroundTransparency = 1, RichText = true, Text = "<b><font color='#00C8FF'>DEVANSH</font></b><font color='#CCCCEE'> Admin Panel</font>", Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar})
create("TextLabel", {Size = UDim2.new(1, -100, 0, 15), Position = UDim2.new(0, 42, 0, 20), BackgroundTransparency = 1, RichText = true, Text = "<font size='10' color='#404468'>v8.1  •  200+ Commands  •  Universal</font>", Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar})
local MinBtn = create("TextButton", {Size = UDim2.new(0, 30, 0, 38), Position = UDim2.new(1, -60, 0, 0), BackgroundTransparency = 1, Text = "—", TextColor3 = COLORS.Text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = TopBar})
local CloseBtn = create("TextButton", {Size = UDim2.new(0, 30, 0, 38), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "✕", TextColor3 = COLORS.Text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = TopBar})

-- TABS (34px)
local TabsFrame = create("ScrollingFrame", {Size = UDim2.new(1, -16, 0, 34), Position = UDim2.new(0, 8, 0, 38), BackgroundTransparency = 1, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0,0,0,0), Parent = PanelFrame})
create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = TabsFrame})

-- SEARCH (30px)
local SearchFrame = create("Frame", {Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 8, 0, 74), BackgroundColor3 = COLORS.CardBg, Parent = PanelFrame})
addCorner(4, SearchFrame); addStroke(Color3.fromRGB(40,40,60), 1, SearchFrame)
local SearchBox = create("TextBox", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, TextColor3 = COLORS.Text, PlaceholderText = "Search commands...", PlaceholderColor3 = COLORS.Dim, Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = SearchFrame})

-- COMMANDS SCROLLER
local ListFrame = create("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -148), Position = UDim2.new(0, 8, 0, 104), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = COLORS.Border, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), Parent = PanelFrame})
create("UIListLayout", {Padding = UDim.new(0, 2), Parent = ListFrame})

-- INPUT BAR
local InputContainer = create("Frame", {Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 1, -40), BackgroundTransparency = 1, Parent = PanelFrame})
local CmdInput = create("TextBox", {Size = UDim2.new(1, -40, 1, 0), BackgroundColor3 = COLORS.CardBg, Text = "", PlaceholderText = "/command [target] [val]", TextColor3 = COLORS.Border, PlaceholderColor3 = COLORS.Dim, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = InputContainer})
create("UIPadding", {PaddingLeft = UDim.new(0, 8), Parent = CmdInput})
addCorner(4, CmdInput); create("Frame", {Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = COLORS.Border, BorderSizePixel = 0, Parent = CmdInput})
local RunBtn = create("TextButton", {Size = UDim2.new(0, 36, 1, 0), Position = UDim2.new(1, -36, 0, 0), BackgroundColor3 = COLORS.CardBg, Text = "▶", TextColor3 = COLORS.Border, Font = Enum.Font.GothamBold, TextSize = 14, Parent = InputContainer})
addCorner(4, RunBtn); addStroke(COLORS.Border, 1, RunBtn)


-- [[ ⚙️ RENDERING & LOGIC ]] --
local activeCategory = "MOV"
local tabObjects = {}

local function PopulateList(filter)
	tween(ListFrame, T_FADE, {ScrollBarImageTransparency = 1})
	for _, child in ipairs(ListFrame:GetChildren()) do if child:IsA("TextButton") then tween(child, T_FADE, {BackgroundTransparency = 1}) child:Destroy() end end
	filter = filter and filter:lower() or ""
	
	for _, cmd in ipairs(Commands) do
		local match = false
		if filter == "" and cmd.c == activeCategory then match = true end
		if filter ~= "" then
			if cmd.d:lower():find(filter) then match = true end
			for _, alias in ipairs(cmd.a) do if alias:lower():find(filter) then match = true end end
		end
		
		if match then
			local row = create("TextButton", {Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = COLORS.CardBg, AutoButtonColor = false, Text = "", Parent = ListFrame})
			create("Frame", {Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = COLORS.Border, BorderSizePixel = 0, Parent = row})
			create("TextLabel", {Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, RichText = true, Text = "<b><font color='#00C8FF'>/" .. cmd.a[1] .. "</font></b>", Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
			create("TextLabel", {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 80, 0, 0), BackgroundTransparency = 1, RichText = true, Text = "<font color='#808098'>— " .. cmd.d .. "</font>", Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
			
			local stateLbl = create("TextLabel", {Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -35, 0, 0), BackgroundTransparency = 1, RichText = true, Text = cmd.on and "<font color='#50FF96'><b>ON</b></font>" or "<font color='#505064'>OFF</font>", Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = row})
			stateLbl.Visible = cmd.tgl
			
			row.MouseButton1Click:Connect(function()
				tween(row, T_FLASH, {BackgroundColor3 = COLORS.Border})
				task.delay(0.1, function() tween(row, T_FADE, {BackgroundColor3 = COLORS.CardBg}) end)
				if cmd.tgl then
					cmd.on = not cmd.on
					stateLbl.Text = cmd.on and "<font color='#50FF96'><b>ON</b></font>" or "<font color='#505064'>OFF</font>"
					pcall(function() cmd.f({}, cmd.on) end)
					Notify(cmd.on and "✔ Enabled" or "✖ Disabled", "/"..cmd.a[1], cmd.on and "50FF96" or "505064")
				else
					CmdInput.Text = "/" .. cmd.a[1] .. " "; CmdInput:CaptureFocus()
				end
			end)
			
			if not isMobile then
				row.MouseEnter:Connect(function() tween(row, T_FAST, {BackgroundTransparency = 0.1}) end)
				row.MouseLeave:Connect(function() tween(row, T_FAST, {BackgroundTransparency = 0}) end)
			end
		end
	end
	tween(ListFrame, T_FAST, {ScrollBarImageTransparency = 0})
end

local cats = {"DEV", "MOV", "VIS", "CMB", "WLD", "PLR", "UTL", "FUN"}
for _, cat in ipairs(cats) do
	local tab = create("TextButton", {Size = UDim2.new(0, 42, 0, 30), BackgroundColor3 = COLORS.TabSel, BackgroundTransparency = (cat==activeCategory) and 0 or 0.6, AutoButtonColor = false, RichText = true, Text = (cat==activeCategory) and "<b><font color='#00C8FF'>"..cat.."</font></b>" or "<font color='#808098'>"..cat.."</font>", Font = Enum.Font.GothamBold, TextSize = 11, Parent = TabsFrame})
	addCorner(4, tab)
	local bborder = create("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = COLORS.Border, BorderSizePixel = 0, Visible = (cat==activeCategory), Parent = tab})
	tabObjects[cat] = {Btn = tab, Border = bborder, name = cat}
	tab.MouseButton1Click:Connect(function()
		activeCategory = cat; SearchBox.Text = ""
		for cName, objs in pairs(tabObjects) do
			objs.Border.Visible = (cName == activeCategory)
			objs.Btn.BackgroundTransparency = (cName == activeCategory) and 0 or 0.6
			objs.Btn.Text = (cName == activeCategory) and "<b><font color='#00C8FF'>"..objs.name.."</font></b>" or "<font color='#808098'>"..objs.name.."</font>"
		end
		PopulateList()
	end)
end
PopulateList()

SearchBox.Changed:Connect(function(p) if p == "Text" then PopulateList(SearchBox.Text) end end)

local function executeCmd(str)
	local args = string.split(str, " ")
	local name = table.remove(args, 1):lower():gsub("^/", "")
	for _, cmd in ipairs(Commands) do
		for _, alias in ipairs(cmd.a) do
			if alias == name then
				if cmd.tgl then
					cmd.on = not cmd.on
					local s, e = pcall(function() cmd.f(args, cmd.on) end)
					if s then Notify(cmd.on and "✔ Enabled" or "✖ Disabled", "/"..name, cmd.on and "50FF96" or "505064") else Notify("✖ Error", tostring(e), "FF5050") end
					PopulateList(SearchBox.Text)
				else
					local s, e = pcall(function() cmd.f(args) end)
					if s then Notify("✔ Executed", "/"..name, "00C8FF") else Notify("✖ Error", tostring(e), "FF5050") end
				end
				return
			end
		end
	end
	Notify("✖ Unknown", "Command not found", "FF5050")
end

RunBtn.MouseButton1Click:Connect(function() 
	tween(RunBtn, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.fromRGB(0,150,200)})
	task.delay(0.15, function() tween(RunBtn, T_FAST, {BackgroundColor3 = COLORS.CardBg}) end)
	if CmdInput.Text ~= "" then executeCmd(CmdInput.Text) CmdInput.Text = "" end 
end)
CmdInput.FocusLost:Connect(function(e) if e and CmdInput.Text ~= "" then executeCmd(CmdInput.Text) CmdInput.Text = "" end end)

-- [[ 🖱️ ANIMATIONS & WINDOW LOGIC ]] --
local function makeDraggable(dragArea, moveFrame)
	local dragging, dragInput, startPos, startMousePos
	dragArea.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; startPos = moveFrame.Position; startMousePos = input.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
	dragArea.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
	UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - startMousePos moveFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

makeDraggable(TopBar, CG); makeDraggable(PillBtn, PillBtn)

local function OpenPanel()
	PillBtn.Visible = false; CG.Visible = true
	CG.GroupTransparency = 1; PanelScale.Scale = 0.92
	tween(CG, T_FAST, {GroupTransparency = 0})
	tween(PanelScale, T_SPRING, {Scale = 1})
end

local function ClosePanel(minimize)
	tween(CG, T_FAST, {GroupTransparency = 1})
	tween(PanelScale, T_FAST, {Scale = 0.92})
	task.delay(0.2, function() CG.Visible = false if minimize then PillBtn.Visible = true end end)
end

PillBtn.MouseButton1Click:Connect(OpenPanel)
MinBtn.MouseButton1Click:Connect(function() ClosePanel(true) end)
CloseBtn.MouseButton1Click:Connect(function() ClosePanel(false) Notify("ℹ Hidden", "Execute script again to open", "808098") end)

UserInputService.InputBegan:Connect(function(i, p)
	if p then return end
	if i.KeyCode == Enum.KeyCode.RightShift then
		if CG.Visible or PillBtn.Visible then CG.Visible = false PillBtn.Visible = false
		else PillBtn.Visible = true end
	end
end)

Notify("✔ Success", "Devansh Admin v8.1 loaded", "50FF96")
