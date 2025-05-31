-- AimbotModule.lua (изменения отмечены)

local AimbotModule = {}

-- local FriendsModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Friends.lua'))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Settings = {
	isProgrammaticallyEnabled = false,
	targetPartName = "Head",
	smoothness = 15,
	maxAimDistance = 500,
	aimFov = 90,
}

local isManuallyActive = false
local currentTarget = nil
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function isAimingEffectivelyActive()
	return Settings.isProgrammaticallyEnabled or isManuallyActive
end

-- Функция для проверки, находится ли точка в пределах FOV камеры
local function isInFov(targetPosition, cameraCFrame, fovDegrees)
	if not cameraCFrame then return false end

	local directionToTarget = (targetPosition - cameraCFrame.Position).Unit
	local cameraLookVector = cameraCFrame.LookVector

	-- Угол между вектором взгляда камеры и направлением на цель
	local angle = math.deg(math.acos(math.clamp(directionToTarget:Dot(cameraLookVector), -1, 1)))

	-- fovDegrees - это полный угол конуса. Мы проверяем половину этого угла от центра.
	return angle <= fovDegrees / 2
end

local Friends = {}



local function findNearestTarget()
	local nearestTargetInstance = nil
	local shortestDistance = Settings.maxAimDistance
	local localCharacter = localPlayer.Character

	if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") or not camera then -- Добавлена проверка camera
		return nil
	end

	local localHRP = localCharacter.HumanoidRootPart
	local cameraCFrame = camera.CFrame -- Получаем CFrame камеры один раз

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= localPlayer and not Friends[player.Name]  then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local targetPart = character:FindFirstChild(Settings.targetPartName)

				if humanoid and humanoid.Health > 0 and targetPart and targetPart:IsA("BasePart") then
					local distance = (localHRP.Position - targetPart.Position).Magnitude
					if distance < shortestDistance then
						-- [[ НОВАЯ ПРОВЕРКА FOV ]]
						if isInFov(targetPart.Position, cameraCFrame, Settings.aimFov) then
							local rayOrigin = cameraCFrame.Position -- Используем сохраненный CFrame
							local rayDirection = (targetPart.Position - rayOrigin).Unit * distance
							local raycastParams = RaycastParams.new()
							raycastParams.FilterDescendantsInstances = {localCharacter}
							raycastParams.FilterType = Enum.RaycastFilterType.Exclude

							local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

							if not raycastResult or (raycastResult.Instance:IsDescendantOf(character)) then
								shortestDistance = distance
								nearestTargetInstance = targetPart
							end
						-- else
							-- print("Target", player.Name, "is outside FOV")
						end
					end
				end
			end
		end
	end
	return nearestTargetInstance
end

local function onRenderStep(deltaTime)
	if not isAimingEffectivelyActive() or not camera then
		currentTarget = nil
		return
	end

	local newTarget = findNearestTarget()
    currentTarget = newTarget

	if currentTarget then
		local targetPosition = currentTarget.Position
		local cameraPosition = camera.CFrame.Position
		local newLookCFrame = CFrame.lookAt(cameraPosition, targetPosition)
		local alpha = math.clamp(deltaTime * Settings.smoothness, 0, 1)
		camera.CFrame = camera.CFrame:Lerp(newLookCFrame, alpha)
	end
end

function AimbotModule.Update(friends)
	Friends = friends
end

-- Публичные функции модуля
function AimbotModule.SetEnabled(enabled)
	
	if type(enabled) == "boolean" then
		Settings.isProgrammaticallyEnabled = enabled
		if not isAimingEffectivelyActive() then
			currentTarget = nil
		end
	else
		warn("AimbotModule.SetEnabled: Expected boolean, got", type(enabled))
	end
end

function AimbotModule.SetManualAimActive(isActive)
	-- for i, v in isActive do
	-- 	print(i,v)
	-- end

	if type(isActive) == "boolean" then
		isManuallyActive = isActive
		if not isAimingEffectivelyActive() then
			currentTarget = nil
		end
	else
		warn("AimbotModule.SetManualAimActive: Expected boolean, got", type(isActive))
	end
end

function AimbotModule.SetSmooth(smoothnessValue)
	-- for i, v in smoothnessValue do
	-- 	print(i,v)
	-- end

	local num = tonumber(smoothnessValue)
	if num and num > 0 then
		Settings.smoothness = num
	else
		warn("AimbotModule.SetSmooth: Expected positive number, got", smoothnessValue)
	end
end

function AimbotModule.SetDistance(distanceValue)
	-- for i, v in distanceValue do
	-- 	print(i,v)
	-- end

	local num = tonumber(distanceValue)
	if num and num > 0 then
		Settings.maxAimDistance = num
	else
		warn("AimbotModule.SetDistance: Expected positive number, got", distanceValue)
	end
end

function AimbotModule.SetTargetPart(partName)
	-- for i, v in partName do
	-- 	print(i,v)
	-- end

	if type(partName) == "string" then
		Settings.targetPartName = partName
	else
		warn("AimbotModule.SetTargetPart: Expected non-empty string, got", partName)
	end
end

-- [[ НОВАЯ ПУБЛИЧНАЯ ФУНКЦИЯ ДЛЯ FOV ]]
function AimbotModule.SetAimFov(fovValue)
	-- for i, v in fovValue do
	-- 	print(i,v)
	-- end

	local num = tonumber(fovValue)
	if num and num > 0 and num <= 360 then -- FOV должен быть в разумных пределах
		Settings.aimFov = num
		-- print("AimbotModule: Aim FOV set to", Settings.aimFov)
	else
		warn("AimbotModule.SetAimFov: Expected number between 0 and 360, got", fovValue)
	end
end


-- Инициализация камеры (остается без изменений)
if not camera then
	local camConnection
	camConnection = workspace.Changed:Connect(function(property)
		if property == "CurrentCamera" and workspace.CurrentCamera then
			camera = workspace.CurrentCamera
			if camConnection then
				camConnection:Disconnect()
				camConnection = nil
			end
		end
	end)
	task.wait(0.5)
	if not camera and workspace.CurrentCamera then
		camera = workspace.CurrentCamera
		if camConnection then
			camConnection:Disconnect()
			camConnection = nil
		end
	end
	if not camera then
		warn("AimbotModule: Could not get CurrentCamera after initial attempts!")
	end
end

RunService:BindToRenderStep("AimbotModuleUpdate", Enum.RenderPriority.Camera.Value + 1, onRenderStep)

return AimbotModule