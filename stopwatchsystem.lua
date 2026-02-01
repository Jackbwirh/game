local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Stopwatch state
local startTime = 0
local elapsedTime = 0
local isRunning = false
local isPaused = false
local hasStarted = false
local hasFinished = false

-- Best time system
local bestTimes = {} -- Stores best times per map
local bestTimeLabel = nil
local currentMapName = Workspace:FindFirstChild("Map") and Workspace.Map.Name or "DefaultMap"

-- GUI elements
local screenGui = nil
local timerLabel = nil
local statusLabel = nil
local finishGui = nil
local improveButton = nil
local menuButton = nil

-- Finish lines
local finishLine = Workspace:WaitForChild("FinishLine")
local finishLine2 = Workspace:WaitForChild("FinishLine2")
local currentFinishLine = nil
local finishLineNumber = 1

-- Function to format time
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%05.2f", minutes, secs)
end

-- Function to update best time label
local function updateBestTimeDisplay()
	local best = bestTimes[currentMapName]
	if best then
		bestTimeLabel.Text = "Best Time: " .. formatTime(best)
	else
		bestTimeLabel.Text = "Best Time: NA"
	end
end

-- Function to create GUI
local function createGUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StopwatchGUI"
	screenGui.Parent = playerGui
	screenGui.ResetOnSpawn = false

	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 200, 0, 100) -- height to fit timer, status, best time
	mainFrame.Position = UDim2.new(0, 10, 0, 10) -- top-left corner
	mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	mainFrame.BackgroundTransparency = 0.3
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	-- Create rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	-- Create timer label
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0, 40)
	timerLabel.Position = UDim2.new(0, 0, 0, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "00:00.00"
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.SourceSansBold
	timerLabel.Parent = mainFrame

	-- Create status label
	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Position = UDim2.new(0, 0, 0, 40)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Waiting to start..."
	statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.Parent = mainFrame

	-- Create best time label
	bestTimeLabel = Instance.new("TextLabel")
	bestTimeLabel.Name = "BestTimeLabel"
	bestTimeLabel.Size = UDim2.new(1, 0, 0, 20)
	bestTimeLabel.Position = UDim2.new(0, 0, 0, 70)
	bestTimeLabel.BackgroundTransparency = 1
	bestTimeLabel.TextColor3 = Color3.new(1, 1, 1)
	bestTimeLabel.TextScaled = true
	bestTimeLabel.Font = Enum.Font.SourceSans
	bestTimeLabel.Text = "Best Time: NA"
	bestTimeLabel.Parent = mainFrame

	updateBestTimeDisplay()
end

-- Function to get spawn position
local function getSpawnPosition()
	local respawnPointName = finishLineNumber == 2 and "NewRespawnPoint2" or "NewRespawnPoint"
	local respawnPoint = Workspace:FindFirstChild(respawnPointName)
	if respawnPoint then
		-- Find actual ground below the RespawnPoint
		local rayStart = respawnPoint.Position + Vector3.new(0, 10, 0)
		local rayDirection = Vector3.new(0, -50, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {respawnPoint}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

		local raycastResult = workspace:Raycast(rayStart, rayDirection, raycastParams)

		if raycastResult then
			-- Add a small offset to ensure car sits on the ground
			local groundY = raycastResult.Position.Y + 2
			print("Found ground at Y:", groundY, "(" .. respawnPointName .. " Y:", respawnPoint.Position.Y, ")")
			return Vector3.new(respawnPoint.Position.X, groundY, respawnPoint.Position.Z)
		else
			-- No ground found, use RespawnPoint position
			print("No ground found, using " .. respawnPointName .. " position")
			return respawnPoint.Position
		end
	else
		-- Fallback to hardcoded coordinates if no respawn point found
		if finishLineNumber == 2 then
			return Vector3.new(317.547, 2, 347.826) -- NewRespawnPoint2 position
		else
			return Vector3.new(80.838, 105, 348.999) -- NewRespawnPoint position
		end
	end
end

-- Function to teleport car to spawn position
local function teleportCarToSpawn()
	local car = getCar()
	if car then
		local spawnPosition = getSpawnPosition()
		local spawnCFrame = CFrame.new(spawnPosition)

		print("Teleporting car to spawn position: " .. tostring(spawnPosition))

		-- Store original anchor states and anchor car temporarily
		local originalAnchorStates = {}
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				originalAnchorStates[part] = part.Anchored
				part.Anchored = true
			end
		end

		print("Car temporarily anchored for teleportation")

		-- Try multiple teleportation methods
		local success = false

		-- Method 1: SetPrimaryPartCFrame
		if car.PrimaryPart then
			car:SetPrimaryPartCFrame(spawnCFrame)
			print("Method 1: SetPrimaryPartCFrame used")
			success = true
		else
			print("Method 1 failed: No PrimaryPart")
		end

		-- Method 2: Move all parts individually
		if not success then
			print("Trying Method 2: Moving parts individually")
			local primaryPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				local offset = spawnCFrame:ToObjectSpace(primaryPart.CFrame)
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CFrame = spawnCFrame:ToWorldSpace(offset:Inverse() * part.CFrame:ToObjectSpace(primaryPart.CFrame))
					end
				end
				print("Method 2: Individual part movement used")
				success = true
			end
		end

		-- Method 3: PivotTo as last resort
		if not success then
			print("Trying Method 3: PivotTo")
			car:PivotTo(spawnCFrame)
			print("Method 3: PivotTo used")
		end

		-- Reset car velocity
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end

		-- Wait a moment to ensure position is set
		task.wait(0.2)

		-- Restore original anchor states
		for part, wasAnchored in pairs(originalAnchorStates) do
			if part and part.Parent then
				part.Anchored = wasAnchored
			end
		end

		print("Anchor states restored")
		-- Final position check
		local currentPos = car:GetPivot().Position
		if math.abs(currentPos.X - spawnPosition.X) > 0.5 or math.abs(currentPos.Y - spawnPosition.Y) > 0.5 or math.abs(currentPos.Z - spawnPosition.Z) > 0.5 then
			print("Final position correction needed...")
			local finalCFrame = CFrame.new(spawnPosition)
			if car.PrimaryPart then
				car:SetPrimaryPartCFrame(finalCFrame)
			else
				car:PivotTo(finalCFrame)
			end

			-- Reset velocity again
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end

			print("Final position set to: " .. tostring(spawnPosition))
		end

		print("Car teleported to spawn position: " .. tostring(spawnPosition))

		-- Continuous position correction for 3 seconds to ensure car stays in place
		local correctionTime = 3
		local correctionInterval = 0.05
		local elapsed = 0

		spawn(function()
			while elapsed < correctionTime do
				task.wait(correctionInterval)
				elapsed = elapsed + correctionInterval

				local currentPos = car:GetPivot().Position
				if math.abs(currentPos.X - spawnPosition.X) > 0.2 or math.abs(currentPos.Y - spawnPosition.Y) > 0.2 or math.abs(currentPos.Z - spawnPosition.Z) > 0.2 then
					print("Continuous correction at " .. string.format("%.2f", elapsed) .. "s - Current: " .. tostring(currentPos) .. " Target: " .. tostring(spawnPosition))
					local correctionCFrame = CFrame.new(spawnPosition)
					if car.PrimaryPart then
						car:SetPrimaryPartCFrame(correctionCFrame)
					else
						car:PivotTo(correctionCFrame)
					end

					-- Reset velocity
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end
					end
				end
			end
			print("Position correction completed")
		end)

		return true
	else
		print("No car found to teleport!")
		return false
	end
end

-- Function to get the car the player is currently in
local function getCar()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.SeatPart then
		local seat = humanoid.SeatPart
		local car = seat:FindFirstAncestorOfClass("Model")
		print("Found car via seat: " .. (car and car.Name or "nil"))
		return car
	end

	-- Alternative method: look for any model with a VehicleSeat in Workspace descendants
	for _, model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChildWhichIsA("VehicleSeat") then
			local seat = model:FindFirstChildWhichIsA("VehicleSeat")
			if seat.Occupant == humanoid then
				print("Found car via alternative method: " .. model.Name)
				return model
			end
		end
	end

	-- Another method: look for Piastri model in Workspace descendants
	for _, model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and model.Name == "Piastri" then
			local seat = model:FindFirstChildWhichIsA("VehicleSeat")
			if seat and seat.Occupant == humanoid then
				print("Found Piastri car: " .. model.Name)
				return model
			end
		end
	end

	print("No car found")
	return nil
end

-- Function to reset stopwatch
local function resetStopwatch()
	startTime = 0
	elapsedTime = 0
	isRunning = false
	isPaused = false
	hasStarted = false
	hasFinished = false
	isControlDisabled = false -- Re-enable controls on reset

	if timerLabel then
		timerLabel.Text = "00:00.00"
	end
	if statusLabel then
		statusLabel.Text = "Waiting to start..."
		statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	end

	-- Hide finish GUI when resetting
	if finishGui then
		finishGui.Enabled = false
	end

	-- Re-enable car controls
	local car = getCar()
	if car then
		local seat = car:FindFirstChildWhichIsA("VehicleSeat")
		if seat then
			-- Restore original values if they were stored
			local originalMaxSpeed = seat:GetAttribute("OriginalMaxSpeed")
			local originalTorque = seat:GetAttribute("OriginalTorque")

			if originalMaxSpeed and originalTorque then
				seat.MaxSpeed = originalMaxSpeed
				seat.Torque = originalTorque
				-- Remove the attributes
				seat:SetAttribute("OriginalMaxSpeed", nil)
				seat:SetAttribute("OriginalTorque", nil)
			end
		end
	end
end

-- Function to start the stopwatch
local function startStopwatch()
	if not hasStarted then
		hasStarted = true
		isRunning = true
		startTime = tick()
		if statusLabel then
			statusLabel.Text = "Racing..."
			statusLabel.TextColor3 = Color3.new(0, 1, 0)
		end
		print("Stopwatch started!")
	end
end

-- Function to handle improve button click
local function onImproveButtonClick()
	-- Disable button immediately to prevent multiple clicks
	if improveButton then
		improveButton.Active = false
		improveButton.Text = "Respawning..."
	end

	-- Reset the race
	resetStopwatch()

	-- Get the car and player info
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- Wait a moment before teleporting to ensure everything is ready
	task.wait(0.1)

	-- Get the appropriate respawn point based on which finish line was crossed
	local respawnPointName = finishLineNumber == 2 and "NewRespawnPoint2" or "NewRespawnPoint"
	local respawnPoint = Workspace:FindFirstChild(respawnPointName)

	if respawnPoint then
		-- Get the car the player is in
		local car = getCar()

		if car then
			-- Teleport the car first
			local spawnCFrame = CFrame.new(respawnPoint.Position)

			if car.PrimaryPart then
				car:SetPrimaryPartCFrame(spawnCFrame)
			else
				car:PivotTo(spawnCFrame)
			end

			-- Reset car velocity
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end

			-- Wait a moment then ensure player is still in car
			task.wait(0.1)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and not humanoid.SeatPart then
				-- Put player back in car if they got out
				local seat = car:FindFirstChildWhichIsA("VehicleSeat")
				if seat then
					humanoid:Sit(seat)
				end
			end

		else
			-- Teleport character only if no car
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(respawnPoint.Position)
			else
				character:SetPrimaryPartCFrame(CFrame.new(respawnPoint.Position))
			end
		end

	end

	-- Reset velocity
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end

	-- Ensure player stays in the car
	if humanoid and not humanoid.SeatPart then
		-- If player got out of car during teleport, put them back in
		local car = getCar()
		if car then
			local seat = car:FindFirstChildWhichIsA("VehicleSeat")
			if seat then
				humanoid:Sit(seat)
			end
		end
	end

	-- Wait a moment before hiding GUI to ensure teleport completes
	task.wait(0.5)

	-- Hide the finish GUI
	if finishGui then
		finishGui.Enabled = false
	end

	-- Re-enable button after a delay
	task.wait(1)
	if improveButton then
		improveButton.Active = true
		improveButton.Text = "Improve"
	end
end

-- Function to handle menu button click
local function onMenuButtonClick()
	-- Disable button immediately to prevent multiple clicks
	if menuButton then
		menuButton.Active = false
		menuButton.Text = "Loading..."
	end

	-- Get the player and character
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- Remove player from car if they're in one
	if humanoid and humanoid.SeatPart then
		-- Use pcall to safely remove player from seat
		pcall(function()
			-- Try the Sit method first
			if humanoid.Sit then
				humanoid:Sit(nil) -- Get out of the car
			else
				-- Alternative method: set SeatPart to nil
				humanoid.SeatPart = nil
			end
		end)
		print("Player removed from car safely")
	end

	-- Wait a moment before teleporting
	task.wait(0.1)

	-- Teleport car to SpawnLocation (always, regardless of finish line)
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then
		-- Get the car the player is in
		local car = getCar()
		if car then
			-- Use SpawnLocation position
			local targetPosition = spawnLocation.Position and spawnLocation.Position ~= Vector3.new(0, 0, 0) and spawnLocation.Position or Vector3.new(0, 10, 0)
			local spawnCFrame = CFrame.new(targetPosition)

			if car.PrimaryPart then
				car:SetPrimaryPartCFrame(spawnCFrame)
			else
				car:PivotTo(spawnCFrame)
			end

			-- Reset car velocity
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end
			
			print("Car teleported to SpawnLocation for menu: " .. tostring(targetPosition))
		else
			print("No car found to teleport for menu")
		end
	else
		print("SpawnLocation not found in Workspace")
	end

	-- Reset velocity
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end

	-- Reset the stopwatch completely
	resetStopwatch()

	-- Hide the finish GUI
	if finishGui then
		finishGui.Enabled = false
	end

	-- Hide the timer GUI to show map selection
	if screenGui then
		screenGui.Enabled = false
	end

	-- Show the map selection GUI
	local playerGui = player:WaitForChild("PlayerGui")
	local mapSelectUI = playerGui:FindFirstChild("MapSelectUI")
	if mapSelectUI then
		mapSelectUI.Enabled = true
		print("Map selection UI shown")
	else
		print("MapSelectUI not found - creating new one")
		-- If the MapSelectUI doesn't exist, we need to create it
		-- This would be handled by the the LocalScript, but we can force it to show
		local localScript = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("LocalScript")
		if localScript then
			-- The LocalScript should have already created the MapSelectUI
			-- If it's disabled, enable it
			local existingUI = playerGui:FindFirstChild("MapSelectUI")
			if existingUI then
				existingUI.Enabled = true
			end
		end
	end

	-- Reset the selected respawn point to default (Map 1)
	player:SetAttribute("SelectedRespawnPoint", "NewRespawnPoint")

	print("Player returned to menu - map selection shown")

	-- Re-enable button after a delay (though GUI will be hidden)
	task.wait(1)
	if menuButton then
		menuButton.Active = true
		menuButton.Text = "Menu"
	end
end

-- Function to create finish GUI
local function createFinishGUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create finish ScreenGui
	finishGui = Instance.new("ScreenGui")
	finishGui.Name = "FinishGUI"
	finishGui.Parent = playerGui
	finishGui.ResetOnSpawn = false
	finishGui.Enabled = false -- Start disabled

	-- Create main frame (increased height for two buttons)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 250) -- Increased height
	mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125) -- Adjusted position
	mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	mainFrame.BackgroundTransparency = 0.2
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = finishGui

	-- Create rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = finishLineNumber == 2 and "Finish Line 2 Completed!" or "Race Finished!"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = mainFrame

	-- Create time label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, 0, 0, 30)
	timeLabel.Position = UDim2.new(0, 0, 0, 70)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "Time: " .. formatTime(elapsedTime)
	timeLabel.TextColor3 = Color3.new(0.7, 1, 0.7)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.SourceSans
	timeLabel.Parent = mainFrame

	-- Create improve button
	improveButton = Instance.new("TextButton")
	improveButton.Name = "ImproveButton"
	improveButton.Size = UDim2.new(0, 120, 0, 40)
	improveButton.Position = UDim2.new(0.25, -60, 0, 120) -- Left side
	improveButton.BackgroundColor3 = finishLineNumber == 2 and Color3.new(1, 0.4, 0.4) or Color3.new(0.2, 0.6, 1)
	improveButton.BorderSizePixel = 0
	improveButton.Text = "Improve"
	improveButton.TextColor3 = Color3.new(1, 1, 1)
	improveButton.TextScaled = true
	improveButton.Font = Enum.Font.SourceSansBold
	improveButton.Parent = mainFrame

	-- Add corner to improve button
	local improveButtonCorner = Instance.new("UICorner")
	improveButtonCorner.CornerRadius = UDim.new(0, 8)
	improveButtonCorner.Parent = improveButton

	-- Create menu button
	menuButton = Instance.new("TextButton")
	menuButton.Name = "MenuButton"
	menuButton.Size = UDim2.new(0, 120, 0, 40)
	menuButton.Position = UDim2.new(0.75, -60, 0, 120) -- Right side
	menuButton.BackgroundColor3 = Color3.new(0.8, 0.4, 0.2) -- Orange color
	menuButton.BorderSizePixel = 0
	menuButton.Text = "Menu"
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.TextScaled = true
	menuButton.Font = Enum.Font.SourceSansBold
	menuButton.Parent = mainFrame

	-- Add corner to menu button
	local menuButtonCorner = Instance.new("UICorner")
	menuButtonCorner.CornerRadius = UDim.new(0, 8)
	menuButtonCorner.Parent = menuButton

	-- Improve button hover effects
	improveButton.MouseEnter:Connect(function()
		if finishLineNumber == 2 then
			improveButton.BackgroundColor3 = Color3.new(1, 0.5, 0.5)
		else
			improveButton.BackgroundColor3 = Color3.new(0.3, 0.7, 1)
		end
	end)

	improveButton.MouseLeave:Connect(function()
		if finishLineNumber == 2 then
			improveButton.BackgroundColor3 = Color3.new(1, 0.4, 0.4)
		else
			improveButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
		end
	end)

	-- Menu button hover effects
	menuButton.MouseEnter:Connect(function()
		menuButton.BackgroundColor3 = Color3.new(1, 0.5, 0.2) -- Lighter orange
	end)

	menuButton.MouseLeave:Connect(function()
		menuButton.BackgroundColor3 = Color3.new(0.8, 0.4, 0.2) -- Original orange
	end)

	-- Connect button click handlers
	improveButton.MouseButton1Click:Connect(onImproveButtonClick)
	menuButton.MouseButton1Click:Connect(onMenuButtonClick)
end

-- Function to set up finish line camera
local function setupFinishCamera()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	-- Store original camera type
	if not originalCameraType then
		originalCameraType = camera.CameraType
	end

	-- Create a new camera for finish line view
	finishCamera = Instance.new("Camera")
	finishCamera.Name = "FinishCamera"
	finishCamera.CameraType = Enum.CameraType.Fixed
	finishCamera.FieldOfView = 70

	-- Position camera at the appropriate finish line looking along the track
	if currentFinishLine then
		-- Check if car is on left side of finish line (negative X direction)
		local car = getCar()
		local carPos = car and car:GetPivot().Position or currentFinishLine.Position
		local finishPos = currentFinishLine.Position

		-- Determine camera position based on which side car came from
		local cameraOffset
		if carPos.X < finishPos.X then
			-- Car came from left side, position camera on right side looking back
			cameraOffset = Vector3.new(-15, 8, -20) -- Right side, looking back along track
		else
			-- Car came from right side, position camera on left side looking back
			cameraOffset = Vector3.new(15, 8, -20) -- Left side, looking back along track
		end

		finishCamera.CFrame = CFrame.new(currentFinishLine.Position + cameraOffset, currentFinishLine.Position)
	end

	-- Set the new camera as current
	camera.CameraType = Enum.CameraType.Scriptable
	finishCamera.Parent = workspace
	workspace.CurrentCamera = finishCamera
end

-- Function to restore original camera
local function restoreOriginalCamera()
	local camera = workspace.CurrentCamera

	-- Restore original camera
	if originalCameraType then
		camera.CameraType = originalCameraType
	end

	-- Remove finish camera
	if finishCamera then
		finishCamera:Destroy()
		finishCamera = nil
	end

	-- Reset camera to player
	camera.CameraSubject = Players.LocalPlayer.Character
end

-- Function to show finish GUI
local function showFinishGUI()
	if not finishGui then
		createFinishGUI()
	end

	if finishGui then
		-- Update the time label
		local timeLabel = finishGui.MainFrame.TimeLabel
		if timeLabel then
			timeLabel.Text = "Time: " .. formatTime(elapsedTime)
		end

		-- Update the title label based on which finish line was crossed
		local titleLabel = finishGui.MainFrame.TitleLabel
		if titleLabel then
			titleLabel.Text = finishLineNumber == 2 and "Finish Line 2 Completed!" or "Race Finished!"
		end

		-- Update button colors based on which finish line was crossed
		if improveButton then
			improveButton.BackgroundColor3 = finishLineNumber == 2 and Color3.new(1, 0.4, 0.4) or Color3.new(0.2, 0.6, 1)
			improveButton.Active = true
			improveButton.Visible = true
		end

		-- Ensure menu button is active
		if menuButton then
			menuButton.Active = true
			menuButton.Visible = true
		end

		-- Show the GUI
		finishGui.Enabled = true
	end
end

-- Function to pause the stopwatch (called when finished)
local function pauseStopwatch()
	if isRunning and not isPaused then
		isPaused = true
		isRunning = false
		if statusLabel then
			statusLabel.Text = "Finished!"
			statusLabel.TextColor3 = Color3.new(1, 1, 0)
		end
		print("Stopwatch paused at: " .. formatTime(elapsedTime))

		-- Update best time for current map
		if not bestTimes[currentMapName] or elapsedTime < bestTimes[currentMapName] then
			bestTimes[currentMapName] = elapsedTime
			print("New best time for map " .. currentMapName .. ": " .. formatTime(elapsedTime))
		end
		updateBestTimeDisplay()

		-- Show the finish GUI
		showFinishGUI()
	end
end

-- Function to reset the stopwatch
-- Duplicate resetStopwatch function removed - defined above

-- Function to update the timer display
local function updateTimer()
	if isRunning then
		elapsedTime = tick() - startTime
	end

	if timerLabel then
		timerLabel.Text = formatTime(elapsedTime)
	end
end

-- Function to check if car touches finish line
local function checkFinishLine()
	local car = getCar()
	if not car or hasFinished then return end

	-- Check both finish lines
	local finishLines = {finishLine, finishLine2}
	
	for i, currentLine in ipairs(finishLines) do
		if not currentLine then continue end
		
		local finishY = currentLine.Position.Y
		local finishPos = currentLine.Position
		local carPos = car:GetPivot().Position
		local distance = (Vector2.new(carPos.X, carPos.Z) - Vector2.new(finishPos.X, finishPos.Z)).Magnitude
		local yDiff = math.abs(carPos.Y - finishY)

		if distance > 30 then continue end

		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				local touchParts = workspace:GetPartsInPart(part)
				for _, touchPart in ipairs(touchParts) do
					if touchPart == currentLine then
						finishLineNumber = i
						currentFinishLine = currentLine
						pauseStopwatch()
						hasFinished = true
						print("Finish line " .. i .. " detected by touch!")
						return
					end
				end
				local partY = part.Position.Y
				if math.abs(partY - finishY) < 2 then
					local partDistance = (Vector2.new(part.Position.X, part.Position.Z) - Vector2.new(finishPos.X, finishPos.Z)).Magnitude
					if partDistance < 15 then
						finishLineNumber = i
						currentFinishLine = currentLine
						pauseStopwatch()
						hasFinished = true
						print("Finish line " .. i .. " detected by strict proximity! Distance: " .. string.format("%.2f", partDistance))
						return
					end
				end
			end
		end

		if distance < 30 then
			print("Car distance to finish line " .. i .. ": " .. string.format("%.2f", distance) .. ", Y diff: " .. string.format("%.2f", yDiff))
		end
	end
end

-- Initialize GUI
createGUI()

-- Listen for finish line remote event
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local finishEvent = ReplicatedStorage:WaitForChild("FinishLineTouched")

finishEvent.OnClientEvent:Connect(function()
	if not hasFinished and hasStarted then
		pauseStopwatch()
		hasFinished = true
		print("Finish line detected via RemoteEvent!")
	end
end)

-- Main update loop
RunService.Heartbeat:Connect(function()
	updateTimer()
	checkFinishLine()
end)

-- Also check finish line frequently
spawn(function()
	while true do
		checkFinishLine()
		task.wait(0.2)
	end
end)

-- Check player input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.R then
		resetStopwatch()

		-- Also teleport car to spawn position when resetting
		local success = teleportCarToSpawn()
		if success then
			-- Ensure player stays in the car
			local player = Players.LocalPlayer
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if humanoid and not humanoid.SeatPart then
				-- If player got out of car during teleport, put them back in
				local car = getCar()
				if car then
					local seat = car:FindFirstChildWhichIsA("VehicleSeat")
					if seat then
						humanoid:Sit(seat)
						print("Player seated back in car")
					else
						print("No seat found to reseat player")
					end
				end
			end

			print("Timer manually reset with R key")
		else
			print("Timer reset with R key, but failed to teleport car")
		end
	end

	-- Optional: Reset best time with B key
	if input.KeyCode == Enum.KeyCode.B then
		bestTimes[currentMapName] = nil
		updateBestTimeDisplay()
		print("Best time reset for map " .. currentMapName)
	end

	-- Debug car detection with C key
	if input.KeyCode == Enum.KeyCode.C then
		print("=== Car Detection Debug ===")
		local player = Players.LocalPlayer
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		print("Player: " .. player.Name)
		print("Character: " .. (character and character.Name or "nil"))
		print("Humanoid: " .. (humanoid and "found" or "nil"))
		print("SeatPart: " .. (humanoid and humanoid.SeatPart and humanoid.SeatPart.Name or "nil"))

		print("\n=== All Models with VehicleSeats ===")
		local carCount = 0
		for _, model in ipairs(Workspace:GetDescendants()) do
			if model:IsA("Model") and model:FindFirstChildWhichIsA("VehicleSeat") then
				local seat = model:FindFirstChildWhichIsA("VehicleSeat")
				carCount = carCount + 1
				print("Car " .. carCount .. ": " .. model.Name)
				print("  Seat: " .. seat.Name)
				print("  Occupied: " .. tostring(seat.Occupant ~= nil))
				print("  Position: " .. tostring(model:GetPivot().Position))
				if seat.Occupant then
					local occupantHumanoid = seat.Occupant.Parent:FindFirstChildOfClass("Humanoid")
					local occupantPlayer = game.Players:GetPlayerFromCharacter(seat.Occupant.Parent)
					print("  Occupied by: " .. (occupantPlayer and occupantPlayer.Name or "Unknown"))
				end
				print("---")
			end
		end
		print("Total cars found: " .. carCount)

		print("\n=== Testing getCar() function ===")
		local testCar = getCar()
		print("getCar() result: " .. (testCar and testCar.Name or "nil"))
	end

	if hasStarted then return end

	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up or
		input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down or
		input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left or
		input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		local car = getCar()
		if car then
			task.wait(0.1)
			if not hasStarted then
				startStopwatch()
			end
		end
	end
end)

-- Handle player seat changes
local function onSeatChanged()
	if hasStarted and not hasFinished then
		local car = getCar()
		if not car then
			resetStopwatch()
			print("Player got out of car - timer reset")
		end
	end
end

spawn(function()
	local player = Players.LocalPlayer
	while true do
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Seated:Connect(onSeatChanged)
		end
		task.wait(1)
	end
end)

print("Stopwatch system initialized with Best Time tracking (Top-Left GUI)!")
