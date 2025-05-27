local module = {}

local SafePointPosition = nil

local Player = game.Players.LocalPlayer

local PointFolder = workspace:FindFirstChild("Pointfolder")
local CurrentPoint = nil

local distance = nil

if not PointFolder then
	PointFolder = Instance.new("Folder", workspace)
	PointFolder.Name = "PointFolder"
end

local function CreatePoint(Parent)

	if PointFolder:FindFirstChild("Point") then
		PointFolder:FindFirstChild("Point"):Destroy()
	end

	local part = Instance.new("Part")
	part.CanCollide = false
	part.Anchored = true
	part.Transparency = 1
	part.Name = "Point"
	part.Parent = Parent

	local Billboard = Instance.new("BillboardGui")
	Billboard.AlwaysOnTop = true
	Billboard.Size = UDim2.new(10,0,10,0)
	Billboard.Parent = part

	local Distance = Instance.new("TextLabel")
	Distance.TextColor3 = Color3.fromRGB(255, 170, 33)
	Distance.Font = Enum.Font.RobotoMono
	Distance.Text = "N/A"
	Distance.TextScaled = true
	Distance.Size = UDim2.new(1,0,1,0)
	Distance.BackgroundTransparency = 1

	Distance.Parent = Billboard

	return part, Distance
end

function module.Set()
	local Character = Player.Character

	SafePointPosition = Character.PrimaryPart.Position

	local Point,Distance = CreatePoint(PointFolder)

	Point.Parent = PointFolder
	Point.Position = Character.PrimaryPart.Position
	CurrentPoint = Point

	distance = Distance
end

function module.Teleport()
	if SafePointPosition ~= nil then
		local Character = Player.Character

		Character:MoveTo(SafePointPosition)
	end
end

local Length

game:GetService("RunService").Heartbeat:Connect(function()
	if SafePointPosition and CurrentPoint then
		local Character = Player.Character
		local a = CurrentPoint.Position.Magnitude
		local b = Character.PrimaryPart.Position.Magnitude

		local LastLength = Length

		Length = math.round(b - a)


		if Length == LastLength then return end

		distance.Text = Length.."m"
	end
end)

return module
