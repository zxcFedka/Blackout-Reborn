return function()	
	
	local Billboard = Instance.new("BillboardGui")
	Billboard.Size = UDim2.new(0,213,0,100)
	Billboard.StudsOffset = Vector3.new(0,1.1,0)
	Billboard.AlwaysOnTop = true

	local Div = Instance.new("Frame")
	Div.BackgroundColor3 = Color3.fromRGB(0,0,0)
	Div.BackgroundTransparency = 0
	Div.BorderSizePixel = 0
	
	Div.Position = UDim2.new(0,0,0.5,0)
	Div.Size = UDim2.new(1,0,0.025,0)
	Div.Parent = Billboard
	
	local UIgradient = Instance.new("UIGradient")
	
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(0.297,0),
		NumberSequenceKeypoint.new(0.699,0),
		NumberSequenceKeypoint.new(1,1),
	})
	
	UIgradient.Transparency = numberSequence
	UIgradient.Parent = Div
	
	local PlayerLabel = Instance.new("TextLabel", Billboard)
	PlayerLabel.AnchorPoint = Vector2.new(0.5,0.5)
	PlayerLabel.BackgroundTransparency = 1
	PlayerLabel.Position = UDim2.new(0.5,0,0.3,0)
	PlayerLabel.Size = UDim2.new(1,0,0.5,0)
	PlayerLabel.Font = Enum.Font.MontserratBold
	PlayerLabel.Text = "aphroishak"
	PlayerLabel.TextColor3 = Color3.fromRGB(110, 175, 50)
	PlayerLabel.TextScaled = true
	PlayerLabel.Name = "player"
	PlayerLabel.Parent = Billboard
	
	local UIStroke = Instance.new("UIStroke")
	UIStroke.Thickness = 3
	UIStroke.Color = Color3.fromRGB(0,0,0)
	UIStroke.Parent = PlayerLabel
	
	local HpLabel = Instance.new("TextLabel", Billboard)
	HpLabel.AnchorPoint = Vector2.new(0.5,0.5)
	HpLabel.BackgroundTransparency = 1
	HpLabel.Position = UDim2.new(0.5,0,0.8,0)
	HpLabel.Size = UDim2.new(1,0,0.3,0)
	HpLabel.Font = Enum.Font.MontserratBold
	HpLabel.Text = "100"
	HpLabel.TextColor3 = Color3.fromRGB(175, 33, 35)
	HpLabel.TextScaled = true
	HpLabel.Name = "hp"
	HpLabel.Parent = Billboard
	
	local UIStroke = Instance.new("UIStroke")
	UIStroke.Thickness = 3
	UIStroke.Color = Color3.fromRGB(0,0,0)
	UIStroke.Parent = HpLabel
	
	return Billboard, HpLabel, PlayerLabel
end