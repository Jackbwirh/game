-- MenuHandler Script
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the menu ScreenGui
local function createMenuGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuGui"
	screenGui.Parent = playerGui
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- Start hidden

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Parent = screenGui
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0

	-- Menu frame
	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Parent = screenGui
	menuFrame.Size = UDim2.new(0, 400, 0, 300)
	menuFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	menuFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	menuFrame.BorderSizePixel = 0

	-- Add rounded corners to menu
	local menuCorner = Instance.new("UICorner")
	menuCorner.Parent = menuFrame
	menuCorner.CornerRadius = UDim.new(0, 12)

	-- Menu title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Parent = menuFrame
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Menu"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Parent = menuFrame
	closeButton.Size = UDim2.new(0, 100, 0, 40)
	closeButton.Position = UDim2.new(0.5, -50, 1, -60)
	closeButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Close"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSans

	-- Add rounded corners to close button
	local closeCorner = Instance.new("UICorner")
	closeCorner.Parent = closeButton
	closeCorner.CornerRadius = UDim.new(0, 6)

	-- Function to show menu with animation
	local function showMenu()
		screenGui.Enabled = true
		menuFrame.Size = UDim2.new(0, 0, 0, 0)
		menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local showTween = TweenService:Create(menuFrame, tweenInfo, {
			Size = UDim2.new(0, 400, 0, 300),
			Position = UDim2.new(0.5, -200, 0.5, -150)
		})
		showTween:Play()
	end

	-- Function to hide menu with animation
	local function hideMenu()
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local hideTween = TweenService:Create(menuFrame, tweenInfo, {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		})
		hideTween.Completed:Connect(function()
			screenGui.Enabled = false
		end)
		hideTween:Play()
	end

	-- Close button connection
	closeButton.MouseButton1Click:Connect(hideMenu)

	-- Return functions for external use
	return {
		show = showMenu,
		hide = hideMenu,
		gui = screenGui
	}
end

-- Create the menu
local menu = createMenuGui()

-- Function to get the car the player is currently in
local function getCar()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.SeatPart then
		local seat = humanoid.SeatPart
		local car = seat:FindFirstAncestorOfClass("Model")
		return car
	end

	-- Alternative method: look for any model with a VehicleSeat in Workspace descendants
	for _, model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChildWhichIsA("VehicleSeat") then
			local seat = model:FindFirstChildWhichIsA("VehicleSeat")
			if seat.Occupant == humanoid then
				return model
			end
		end
	end

	return nil
end

-- Function to teleport both player and car to spawn location
local function teleportToSpawn()
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if not spawnLocation then return end
	
	local spawnPosition = spawnLocation.Position
	local spawnCFrame = CFrame.new(spawnPosition.X, spawnPosition.Y + 3, spawnPosition.Z)
	
	-- Get the car the player is in
	local car = getCar()
	
	if car then
		-- Teleport the car first
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
		
		print("Car teleported to SpawnLocation")
	else
		-- If no car, teleport just the player
		local character = player.Character
		if character then
			character:SetPrimaryPartCFrame(spawnCFrame)
			print("Player teleported to SpawnLocation (no car found)")
		end
	end
	
	-- Reset player velocity
	local character = player.Character
	if character then
		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
	end
end

-- Handle M key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.M then
		-- Teleport player to SpawnLocation
		teleportToSpawn()
		
		-- Hide the custom menu if it's visible
		if menu.gui.Enabled then
			menu.hide()
		end
		
		-- Show the existing map selection UI
		local playerGui = player:WaitForChild("PlayerGui")
		local mapSelectUI = playerGui:FindFirstChild("MapSelectUI")
		if mapSelectUI then
			mapSelectUI.Enabled = true
			print("Map selection UI shown via M key")
		else
			print("MapSelectUI not found - it should be created by LocalScript")
		end
	end
end)

-- Also handle Escape key to close menu
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape and menu.gui.Enabled then
		menu.hide()
	end
end)
