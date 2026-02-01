local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local respawnPoint1 = Workspace:WaitForChild("NewRespawnPoint")
local respawnPoint2 = Workspace:WaitForChild("NewRespawnPoint2")

-------------------------------------------------
-- SET DEFAULT RESPAWN POINT (MAP 1)
-------------------------------------------------
player:SetAttribute("SelectedRespawnPoint", "NewRespawnPoint")

-------------------------------------------------
-- GET CAR PLAYER IS IN
-------------------------------------------------
local function getCar()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	if humanoid.SeatPart then
		return humanoid.SeatPart:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-------------------------------------------------
-- TELEPORT CAR (SAME LOGIC)
-------------------------------------------------
local function teleportCarTo(respawnPoint)
	local car = getCar()
	if not car then return end

	local primaryPart =
		car.PrimaryPart
		or car:FindFirstChild("DriveSeat")
		or car:FindFirstChildWhichIsA("BasePart")

	if not primaryPart then return end

	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local rayStart = respawnPoint.Position + Vector3.new(0, 10, 0)
	local rayDirection = Vector3.new(0, -50, 0)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { respawnPoint }
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = Workspace:Raycast(rayStart, rayDirection, params)
	local groundY = result and result.Position.Y or respawnPoint.Position.Y

	local size = car:GetExtentsSize()
	local targetPosition = Vector3.new(
		respawnPoint.Position.X,
		groundY + size.Y / 2 + 1,
		respawnPoint.Position.Z
	)

	local targetCFrame = CFrame.new(targetPosition)

	if car.PrimaryPart then
		car:SetPrimaryPartCFrame(targetCFrame)
	else
		car:PivotTo(targetCFrame)
	end
end

-------------------------------------------------
-- UI
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MapSelectUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function createButton(text, pos)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromScale(0.25, 0.12)
	b.Position = pos
	b.Text = text
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BorderSizePixel = 0

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b

	b.Parent = gui
	return b
end

local map1Button = createButton("Map 1", UDim2.fromScale(0.375, 0.38))
local map2Button = createButton("Map 2", UDim2.fromScale(0.375, 0.52))

-------------------------------------------------
-- BUTTON ACTIONS
-------------------------------------------------
map1Button.MouseButton1Click:Connect(function()
	player:SetAttribute("SelectedRespawnPoint", "NewRespawnPoint")
	teleportCarTo(respawnPoint1)
	gui.Enabled = false
end)

map2Button.MouseButton1Click:Connect(function()
	player:SetAttribute("SelectedRespawnPoint", "NewRespawnPoint2")
	teleportCarTo(respawnPoint2)
	gui.Enabled = false
end)
