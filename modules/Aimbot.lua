-- AimbotModule.lua (изменения отмечены)

local AimbotModule = {}

-- local FriendsModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Friends.lua'))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Добавим Workspace для гравитации

local Settings = {
	isProgrammaticallyEnabled = false,
	targetPartName = "Head",
	smoothness = 15,
	maxAimDistance = 500,
	aimFov = 90,
    -- [[ НОВЫЕ НАСТРОЙКИ ДЛЯ ПРЕДИКЦИИ ]]
    projectileSpeed = 200,      -- Скорость снаряда в studs/second (настроить под игру!)
                                -- Если 0 или меньше, предикция по скорости снаряда отключается
    predictTargetVelocity = true, -- Учитывать скорость цели
    compensateGravity = true,   -- Компенсировать гравитацию
}

local isManuallyActive = false
local currentTargetInfo = nil -- Будем хранить не только часть, но и персонажа
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function isAimingEffectivelyActive()
	return Settings.isProgrammaticallyEnabled or isManuallyActive
end

local function isInFov(targetPosition, cameraCFrame, fovDegrees)
	if not cameraCFrame then return false end
	local directionToTarget = (targetPosition - cameraCFrame.Position).Unit
	local cameraLookVector = cameraCFrame.LookVector
	local angle = math.deg(math.acos(math.clamp(directionToTarget:Dot(cameraLookVector), -1, 1)))
	return angle <= fovDegrees / 2
end

local Friends = {}

local function findNearestTarget()
	local nearestTargetData = nil -- Будет хранить {part, character, distance}
	local shortestDistance = Settings.maxAimDistance
	local localCharacter = localPlayer.Character

	if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") or not camera then
		return nil
	end

	local localHRP = localCharacter.HumanoidRootPart
	local cameraCFrame = camera.CFrame

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and not Friends[player.Name] then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local targetPart = character:FindFirstChild(Settings.targetPartName)
                local targetHRP = character:FindFirstChild("HumanoidRootPart") -- Нужен для скорости

				if humanoid and humanoid.Health > 0 and targetPart and targetPart:IsA("BasePart") and targetHRP then -- Убедимся, что HRP есть
					local distance = (localHRP.Position - targetPart.Position).Magnitude
					if distance < shortestDistance then
						if isInFov(targetPart.Position, cameraCFrame, Settings.aimFov) then
							local rayOrigin = cameraCFrame.Position
							local rayDirection = (targetPart.Position - rayOrigin).Unit * distance
							local raycastParams = RaycastParams.new()
							raycastParams.FilterDescendantsInstances = {localCharacter}
							raycastParams.FilterType = Enum.RaycastFilterType.Exclude

							local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

							if not raycastResult or (raycastResult.Instance:IsDescendantOf(character)) then
								shortestDistance = distance
								nearestTargetData = {
                                    part = targetPart,
                                    character = character, -- Сохраняем персонажа для доступа к HRP.Velocity
                                    hrp = targetHRP       -- Сохраняем HRP для удобства
                                }
							end
						end
					end
				end
			end
		end
	end
	return nearestTargetData
end

local function onRenderStep(deltaTime)
	if not isAimingEffectivelyActive() or not camera then
		currentTargetInfo = nil
		return
	end

	local newTargetInfo = findNearestTarget()
    currentTargetInfo = newTargetInfo

	if currentTargetInfo and currentTargetInfo.part and currentTargetInfo.hrp then
		local targetPart = currentTargetInfo.part
        local targetHRP = currentTargetInfo.hrp -- HumanoidRootPart цели

		local targetPosition = targetPart.Position
		local cameraPosition = camera.CFrame.Position
        
        -- [[ ЛОГИКА ПРЕДСКАЗАНИЯ ]]
        local predictedPosition = targetPosition

        if Settings.predictTargetVelocity and Settings.projectileSpeed > 0 then
            local targetVelocity = targetHRP.Velocity
            -- Убираем вертикальную составляющую скорости цели для более простого 2D предсказания,
            -- если гравитация компенсируется отдельно. Можно оставить, если нужно учитывать прыжки в предикции.
            -- targetVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z) 

            local distanceToTarget = (targetPosition - cameraPosition).Magnitude
            
            if distanceToTarget > 0 then -- Избегаем деления на ноль
                local timeToHit = distanceToTarget / Settings.projectileSpeed
                
                -- Предсказанное смещение на основе скорости цели
                local predictionOffset = targetVelocity * timeToHit
                predictedPosition = targetPosition + predictionOffset

                if Settings.compensateGravity then
                    local gravity = Workspace.Gravity -- Гравитация в текущем мире
                    -- Рассчитываем, насколько снаряд упадет за время timeToHit
                    -- Формула: drop = 0.5 * g * t^2
                    local gravityDrop = 0.5 * gravity * (timeToHit * timeToHit)
                    -- Нам нужно целиться выше, чтобы компенсировать это падение
                    predictedPosition = predictedPosition + Vector3.new(0, gravityDrop, 0)
                end
            end
        elseif Settings.predictTargetVelocity and Settings.projectileSpeed <= 0 then
             -- Если скорость снаряда не задана, но предикция включена, можно сделать "простую" предикцию
             -- Просто добавляем небольшой вектор в направлении движения цели
             -- Это менее точно, но лучше чем ничего для медленных противников
             local targetVelocity = targetHRP.Velocity
             predictedPosition = targetPosition + targetVelocity * 0.1 -- Малый коэффициент
        end
        -- [[ КОНЕЦ ЛОГИКИ ПРЕДСКАЗАНИЯ ]]

		local newLookCFrame = CFrame.lookAt(cameraPosition, predictedPosition) -- Используем predictedPosition
		local alpha = math.clamp(deltaTime * Settings.smoothness, 0, 1)
		camera.CFrame = camera.CFrame:Lerp(newLookCFrame, alpha)
	else
        currentTargetInfo = nil -- Явно сбрасываем, если цель не найдена или невалидна
    end
end

function AimbotModule.Update(friends)
	Friends = friends
end

function AimbotModule.SetEnabled(enabled)
	if type(enabled) == "boolean" then
		Settings.isProgrammaticallyEnabled = enabled
		if not isAimingEffectivelyActive() then
			currentTargetInfo = nil
		end
	else
		warn("AimbotModule.SetEnabled: Expected boolean, got", type(enabled))
	end
end

function AimbotModule.SetManualAimActive(isActive)
	if type(isActive) == "boolean" then
		isManuallyActive = isActive
		if not isAimingEffectivelyActive() then
			currentTargetInfo = nil
		end
	else
		warn("AimbotModule.SetManualAimActive: Expected boolean, got", type(isActive))
	end
end

function AimbotModule.SetSmooth(smoothnessValue)
	local num = tonumber(smoothnessValue)
	if num and num > 0 then
		Settings.smoothness = num
	else
		warn("AimbotModule.SetSmooth: Expected positive number, got", smoothnessValue)
	end
end

function AimbotModule.SetDistance(distanceValue)
	local num = tonumber(distanceValue)
	if num and num > 0 then
		Settings.maxAimDistance = num
	else
		warn("AimbotModule.SetDistance: Expected positive number, got", distanceValue)
	end
end

function AimbotModule.SetTargetPart(partName)
	if type(partName) == "string" then
		Settings.targetPartName = partName
	else
		warn("AimbotModule.SetTargetPart: Expected non-empty string, got", partName)
	end
end

function AimbotModule.SetAimFov(fovValue)
	local num = tonumber(fovValue)
	if num and num > 0 and num <= 360 then
		Settings.aimFov = num
	else
		warn("AimbotModule.SetAimFov: Expected number between 0 and 360, got", fovValue)
	end
end

-- [[ НОВЫЕ ПУБЛИЧНЫЕ ФУНКЦИИ ДЛЯ НАСТРОЙКИ ПРЕДИКЦИИ ]]
function AimbotModule.SetProjectileSpeed(speed)
    local num = tonumber(speed)
    if num then -- Может быть 0 или отрицательным, чтобы отключить предикцию по скорости
        Settings.projectileSpeed = num
        print("AimbotModule: Projectile speed set to", Settings.projectileSpeed)
    else
        warn("AimbotModule.SetProjectileSpeed: Expected number, got", speed)
    end
end

function AimbotModule.SetPredictTargetVelocity(enabled)
    if type(enabled) == "boolean" then
        Settings.predictTargetVelocity = enabled
        print("AimbotModule: Predict target velocity set to", Settings.predictTargetVelocity)
    else
        warn("AimbotModule.SetPredictTargetVelocity: Expected boolean, got", type(enabled))
    end
end

function AimbotModule.SetCompensateGravity(enabled)
    if type(enabled) == "boolean" then
        Settings.compensateGravity = enabled
        print("AimbotModule: Compensate gravity set to", Settings.compensateGravity)
    else
        warn("AimbotModule.SetCompensateGravity: Expected boolean, got", type(enabled))
    end
end


-- Инициализация камеры
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