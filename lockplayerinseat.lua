local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function lockPlayerInSeat(player)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Find the car seat the player is sitting in
	local seat = humanoid.SeatPart
	if not seat or not seat:IsA("VehicleSeat") then return end
	
	-- Continuously ensure player stays seated
	task.spawn(function()
		while humanoid.Parent and humanoid.SeatPart == seat do
			-- Prevent jumping
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			humanoid.JumpPower = 0
			
			-- Force player to stay seated if they try to exit
			if humanoid.SeatPart ~= seat then
				seat:Sit(humanoid)
			end
			
			task.wait(0.1)
		end
	end)
end

local function onPlayerAdded(player)
	-- Wait for character to be seated
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		-- Monitor when player gets seated
		humanoid.Seated:Connect(function(isSeated, seat)
			if isSeated and seat and seat:IsA("VehicleSeat") then
				task.wait(0.5) -- Small delay to ensure fully seated
				lockPlayerInSeat(player)
			end
		end)
		
		-- Also check if already seated
		if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
			lockPlayerInSeat(player)
		end
	end)
	
	-- Handle players who already have characters
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
			lockPlayerInSeat(player)
		end
	end
end

-- Connect to new players
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in the game
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
