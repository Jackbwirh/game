local Players = game:GetService("Players")

local function disableJumping(humanoid)
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.JumpPower = 0
	end
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	disableJumping(humanoid)
	
	-- Also disable jumping if the humanoid respawns or gets reset
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end)
	
	-- Continuously disable jumping to prevent overrides
	task.spawn(function()
		while humanoid.Parent do
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			humanoid.JumpPower = 0
			task.wait(0.1)
		end
	end)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	
	-- Handle players who already have characters
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Connect to new players
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in the game
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
