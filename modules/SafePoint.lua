local module = {}

local safePointCFrame = nil -- Stores the CFrame of the set point
local currentPointPart = nil -- Reference to the visual Part instance
local currentDistanceLabel = nil -- Reference to the TextLabel for distance

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PointFolder = workspace:FindFirstChild("PointFolder")
if not PointFolder then
	PointFolder = Instance.new("Folder", workspace)
	PointFolder.Name = "PointFolder"
end

-- This function now correctly handles destroying the old point if it exists
-- and creates a new one.
local function CreateOrReplacePointVisuals()
	-- Destroy existing point if any
	local existingPoint = PointFolder:FindFirstChild("Point")
	if existingPoint then
		existingPoint:Destroy()
	end

	-- Create the physical part
	local part = Instance.new("Part")
	part.CanCollide = false
	part.Anchored = true
	part.Transparency = 1 -- Invisible, visuals are via BillboardGui
	part.Name = "Point"
	part.Size = Vector3.new(1, 1, 1) -- Small, doesn't really matter much
	part.Parent = PointFolder -- Parent it here

	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.AlwaysOnTop = true
	billboardGui.Size = UDim2.new(5, 0, 5, 0) -- Kept stud-based, adjusted size
	billboardGui.StudsOffset = Vector3.new(0, 2.5, 0) -- Lifts the GUI above the part's center
	billboardGui.Parent = part

	-- Create TextLabel for distance
	local distanceTextLabel = Instance.new("TextLabel")
	distanceTextLabel.TextColor3 = Color3.fromRGB(255, 170, 33)
	distanceTextLabel.Font = Enum.Font.RobotoMono
	distanceTextLabel.Text = "N/A"
	distanceTextLabel.TextScaled = true
	distanceTextLabel.Size = UDim2.new(1, 0, 1, 0)
	distanceTextLabel.BackgroundTransparency = 1
	distanceTextLabel.Parent = billboardGui

	return part, distanceTextLabel
end

function module.Set()
	safePointCFrame = Camera.CFrame

	-- CreateOrReplacePointVisuals handles destruction of old and creation of new
	local point, distLabel = CreateOrReplacePointVisuals()

	point.CFrame = safePointCFrame -- Set the CFrame of the newly created part
	currentPointPart = point
	currentDistanceLabel = distLabel

	return safePointCFrame
end

function module.Teleport()
	if safePointCFrame then
		local Character = Player.Character
		if Character and Character.PrimaryPart then
			-- Use the Position component of the CFrame for MoveTo
			-- For more precise teleportation preserving orientation, use SetPrimaryPartCFrame:
			-- Character:SetPrimaryPartCFrame(safePointCFrame)
			Character:MoveTo(safePointCFrame.Position)
		else
			warn("SafePoint: Cannot teleport, Player character or PrimaryPart not found.")
		end
	else
		warn("SafePoint: Cannot teleport, safe point not set.")
	end
end

local lastCalculatedDistance = nil

RunService.Heartbeat:Connect(function()
	if safePointCFrame and currentPointPart and currentDistanceLabel then
		local Character = Player.Character
		if Character and Character.PrimaryPart then
			local playerPosition = Character.PrimaryPart.Position
			local pointPosition = currentPointPart.Position -- Use the part's actual position

			-- Correct distance calculation
			local distanceValue = (playerPosition - pointPosition).Magnitude
			local roundedDistance = math.round(distanceValue)

			-- Only update if the rounded distance has changed
			if roundedDistance == lastCalculatedDistance then
				return
			end

			currentDistanceLabel.Text = roundedDistance .. "m"
			lastCalculatedDistance = roundedDistance
		else
			-- Character not available (e.g., dead, loading)
			if currentDistanceLabel.Text ~= "N/A" then
				currentDistanceLabel.Text = "N/A"
			end
			lastCalculatedDistance = nil -- Reset to ensure update when character reappears
		end
	elseif currentDistanceLabel and currentDistanceLabel.Text ~= "N/A" then
        -- If no safepoint is set, but label exists, ensure it shows N/A
        currentDistanceLabel.Text = "N/A"
        lastCalculatedDistance = nil
    end
end)

-- Optional: A function to clear the point if needed
function module.Clear()
	if currentPointPart then
		currentPointPart:Destroy()
		currentPointPart = nil
	end
	if currentDistanceLabel then
		-- The label is parented to the part, so it's already destroyed.
		-- Just clear the reference.
		currentDistanceLabel = nil
	end
	safePointCFrame = nil
	lastCalculatedDistance = nil
	print("SafePoint: Cleared.")
end


return module