local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local carTemplate = ReplicatedStorage:WaitForChild("Piastri")

Players.PlayerAdded:Connect(function(player)
	-- clone the car early
	local car = carTemplate:Clone()
	car.Parent = workspace

	-- ensure PrimaryPart
	if not car.PrimaryPart then
		if car:FindFirstChild("DriveSeat") then
			car.PrimaryPart = car.DriveSeat
		else
			warn("Car has no PrimaryPart!")
		end
	end

	-- position the car at the SpawnLocation
	local spawnLocation = workspace:WaitForChild("SpawnLocation")
	local spawnPosition = spawnLocation.Position
	
	-- Position the car slightly above the spawn location
	local carPosition = Vector3.new(spawnPosition.X, spawnPosition.Y + 5, spawnPosition.Z)
	car:SetPrimaryPartCFrame(CFrame.new(carPosition))

	-- now wait for character to load
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local driveSeat = car:WaitForChild("DriveSeat", true)

		-- Move player character to spawn location first
		local spawnLocation = workspace:WaitForChild("SpawnLocation")
		local spawnPosition = spawnLocation.Position
		character:SetPrimaryPartCFrame(CFrame.new(spawnPosition.X, spawnPosition.Y + 3, spawnPosition.Z))

		-- slight delay so LocalScripts in the car detect the player
		task.wait(0.2)
		driveSeat:Sit(humanoid)
	end)
end)
