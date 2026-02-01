local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- optional: wait for the car to exist
local car = workspace:WaitForChild("Piastri") -- adjust if multiple cars exist
local driveSeat = car:WaitForChild("DriveSeat", true)

-- Disable jumping while seated
humanoid.Jumping:Connect(function(active)
	if humanoid.SeatPart == driveSeat then
		-- prevent jump
		humanoid.Jump = false
	end
end)

-- Optionally block Space key to prevent seat exit
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space then
		if humanoid.SeatPart == driveSeat then
			-- block default space behavior
			gameProcessed = true
		end
	end
end)
