-- MenuHint ScreenGui
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MenuHint"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Create the hint frame
local hintFrame = Instance.new("Frame")
hintFrame.Name = "HintFrame"
hintFrame.Parent = screenGui
hintFrame.Size = UDim2.new(0, 200, 0, 40)
hintFrame.Position = UDim2.new(1, -210, 0, 10) -- Top right corner
hintFrame.BackgroundColor3 = Color3.new(0, 0, 0)
hintFrame.BackgroundTransparency = 0.3
hintFrame.BorderSizePixel = 0

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.Parent = hintFrame
corner.CornerRadius = UDim.new(0, 8)

-- Create the hint text
local hintText = Instance.new("TextLabel")
hintText.Name = "HintText"
hintText.Parent = hintFrame
hintText.Size = UDim2.new(1, -20, 1, 0)
hintText.Position = UDim2.new(0, 10, 0, 0)
hintText.BackgroundTransparency = 1
hintText.Text = "Press M for Menu"
hintText.TextColor3 = Color3.new(1, 1, 1)
hintText.TextScaled = true
hintText.Font = Enum.Font.SourceSansBold

-- Add subtle animation
local tweenInfo = TweenInfo.new(
	2, -- Time
	Enum.EasingStyle.Sine, -- EasingStyle
	Enum.EasingDirection.InOut, -- EasingDirection
	-1, -- RepeatCount (-1 for infinite)
	true, -- Reverses
	0 -- DelayTime
)

local pulseTween = TweenService:Create(hintFrame, tweenInfo, {
	BackgroundTransparency = 0.5
})

pulseTween:Play()
