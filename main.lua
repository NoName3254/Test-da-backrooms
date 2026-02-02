-- Security Dashboard (SAFE TESTING)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")

local PickupItem = Remotes:FindFirstChild("PickupItem")
local SaveData = Remotes:FindFirstChild("SaveData")

-- ===== UI =====
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "SecurityDashboard"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.38, 0.45)
frame.Position = UDim2.fromScale(0.31, 0.27)
frame.BackgroundColor3 = Color3.fromRGB(22,22,26)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.fromScale(1, 0.14)
title.BackgroundTransparency = 1
title.Text = "🔐 Security Test Dashboard"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(235,235,235)

local log = Instance.new("TextLabel", frame)
log.Position = UDim2.fromScale(0.04, 0.16)
log.Size = UDim2.fromScale(0.92, 0.36)
log.BackgroundColor3 = Color3.fromRGB(16,16,20)
log.TextColor3 = Color3.fromRGB(200,200,200)
log.TextWrapped = true
log.TextYAlignment = Top
log.Font = Enum.Font.Gotham
log.TextSize = 14
log.Text = "Status: READY"
Instance.new("UICorner", log).CornerRadius = UDim.new(0,10)

local function addLog(t)
	log.Text ..= "\n• "..t
end

local function button(text, y, cb)
	local b = Instance.new("TextButton", frame)
	b.Position = UDim2.fromScale(0.06, y)
	b.Size = UDim2.fromScale(0.88, 0.1)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(55,55,65)
	b.TextColor3 = Color3.fromRGB(255,255,255)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
	b.MouseButton1Click:Connect(cb)
	return b
end

-- ===== TEST MODULES =====

-- Dupe Attempt: Spam + Double-fire
button("🧪 Dupe Attempt (Spam + Double)", 0.56, function()
	if not PickupItem then return addLog("PickupItem missing") end
	addLog("Running dupe-attempt tests...")
	for i = 1, 20 do
		PickupItem:FireServer({ ItemId="Keycard", Amount=1 })
	end
	task.spawn(function()
		PickupItem:FireServer({ ItemId="Keycard", Amount=1 })
	end)
	task.spawn(function()
		PickupItem:FireServer({ ItemId="Keycard", Amount=1 })
	end)
	addLog("Payloads sent. Expect server to reject/limit.")
end)

-- Inventory Integrity
button("📦 Inventory Integrity (Edge Values)", 0.68, function()
	if not PickupItem then return addLog("PickupItem missing") end
	local cases = {
		{ItemId="Keycard", Amount=0},
		{ItemId="Keycard", Amount=-5},
		{ItemId="Keycard", Amount=999},
	}
	for _, c in ipairs(cases) do
		PickupItem:FireServer(c)
	end
	addLog("Edge payloads sent.")
end)

-- Save Race
button("💾 Save Race (Invoke Burst)", 0.8, function()
	if not SaveData then return addLog("SaveData missing") end
	addLog("Running Save race...")
	for i=1,5 do
		task.spawn(function()
			pcall(function()
				SaveData:InvokeServer({ Coins = 100 })
			end)
		end)
	end
	addLog("Save race invoked.")
end)

local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")

local lastFire = {}
local COOLDOWN = 0.3
local ItemDB = { Keycard = true }

local function rateOK(plr)
	local t = os.clock()
	if lastFire[plr] and (t - lastFire[plr] < COOLDOWN) then
		warn("[FAIL] Rate-limit hit", plr.Name)
		return false
	end
	lastFire[plr] = t
	return true
end

local PickupItem = Remotes:FindFirstChild("PickupItem")
if PickupItem then
	PickupItem.OnServerEvent:Connect(function(plr, data)
		if typeof(data) ~= "table" then warn("[FAIL] Type") return end
		if not ItemDB[data.ItemId] then warn("[FAIL] ItemId") return end
		if typeof(data.Amount) ~= "number" or data.Amount ~= 1 then
			warn("[FAIL] Amount clamp", data.Amount)
			return
		end
		if not rateOK(plr) then return end
		-- PASS if nothing abnormal happens
	end)
end

local SaveData = Remotes:FindFirstChild("SaveData")
if SaveData then
	local lock = {}
	SaveData.OnServerInvoke = function(plr, payload)
		if lock[plr] then
			warn("[FAIL] Save race", plr.Name)
			return false
		end
		lock[plr] = true
		task.wait(0.1)
		lock[plr] = nil
		return true
	end
end
