local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-------------------------------------------------
-- GET CURRENT RESPAWN POINT (FROM ATTRIBUTE)
-------------------------------------------------
local function getRespawnPoint()
	local pointName = player:GetAttribute("SelectedRespawnPoint")
	if pointName then
		local point = Workspace:FindFirstChild(pointName)
		if point then
			return point
		end
	end

	-- Fallback (Map 1)
	return Workspace:WaitForChild("NewRespawnPoint")
end

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
-- RESPAWN CAR (UNCHANGED LOGIC)
-------------------------------------------------
local function respawnCar()
	local respawnPoint = getRespawnPoint()
	if not respawnPoint then return end

	local car = getCar()
	if not car then
		warn("No car found - player is not in a vehicle")
		return
	end

	local primaryPart =
		car.PrimaryPart
		or car:FindFirstChild("DriveSeat")
		or car:FindFirstChildWhichIsA("BasePart")

	if not primaryPart then
		warn("No primary part found in car")
		return
	end

	-- Clear velocity
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end

	-- Raycast to ground
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

	-- Teleport
	if car.PrimaryPart then
		car:SetPrimaryPartCFrame(targetCFrame)
	else
		car:PivotTo(targetCFrame)
	end

	-- Final velocity clear
	task.wait(0.1)
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end

	print("Car respawned at:", respawnPoint.Name)
end

-------------------------------------------------
-- R KEY LISTENER
-------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R then
		respawnCar()
	end
end)

print("Car respawn system initialized (attribute-based)")
