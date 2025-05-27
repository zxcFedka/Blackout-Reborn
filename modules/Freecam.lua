local FreecamModule = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Player and Camera (доступны внутри модуля)
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration (доступны внутри модуля)
local MOVE_SPEED = 50
local SPRINT_MULTIPLIER = 3
local MOUSE_SENSITIVITY = 0.003
local MAX_PITCH = math.rad(89)
local MIN_PITCH = math.rad(-89)

-- State variables (upvalues - локальные переменные модуля, сохраняющие состояние)
local isFreecamActive = false
local originalCameraType
local originalCameraCFrame
local originalHRPAnchoredState -- Состояние Anchored для HumanoidRootPart до активации фрикама

local currentYaw = 0
local currentPitch = 0

-- Connections (для управления ими: подключения/отключения)
local renderSteppedConnection
local characterAddedConnection

--[[
	Внутренняя функция для анкеровки/деанкеровки текущего персонажа игрока.
	@param characterModel Модель персонажа.
	@param shouldBeAnchored true, чтобы заанкерить; false, чтобы восстановить исходное состояние.
]]
local function _anchorPlayerCharacter(characterModel, shouldBeAnchored)
	if not characterModel then return end
	local humanoid = characterModel:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = characterModel:FindFirstChild("HumanoidRootPart")

	if humanoid and humanoidRootPart then
		if shouldBeAnchored then
			-- Если персонаж сидит, нужно его поднять
			if humanoid.Sit then
				humanoid.Sit = false
				task.wait() -- Даем короткое время на обработку вставания
			end
			humanoidRootPart.Anchored = true
		else
			-- Восстанавливаем исходное состояние Anchored.
			-- originalHRPAnchoredState может быть nil, если персонажа не было
			-- при первом включении фрикама, или если оно еще не было установлено.
			-- В таком случае, по умолчанию ставим false.
			humanoidRootPart.Anchored = originalHRPAnchoredState or false
		end
	end
end

--[[
	Обработчик события добавления нового персонажа (например, после респавна).
	Если фрикам активен, новый персонаж также должен быть обездвижен.
	@param newCharacter Новая модель персонажа.
]]
local function _handleCharacterAdded(newCharacter)
	if isFreecamActive then -- Убеждаемся, что фрикам все еще активен
		-- Даем небольшую задержку, чтобы убедиться, что HumanoidRootPart доступен.
		task.wait(0.1)
		_anchorPlayerCharacter(newCharacter, true) -- Анкерим нового персонажа
		--print("FreecamModule: New character anchored.")
	end
end

--[[
	Функция, вызываемая каждый кадр для обновления камеры, когда фрикам активен.
	@param deltaTime Время, прошедшее с предыдущего кадра.
]]
local function _updateCameraOnRenderStep(deltaTime)
	if not isFreecamActive then return end -- Дополнительная проверка

	-- 1. Обработка вращения мыши
	local mouseDelta = UserInputService:GetMouseDelta()
	currentYaw = currentYaw - mouseDelta.X * MOUSE_SENSITIVITY
	currentPitch = currentPitch - mouseDelta.Y * MOUSE_SENSITIVITY
	currentPitch = math.clamp(currentPitch, MIN_PITCH, MAX_PITCH)

	-- 2. Обработка движения клавиатурой
	local actualSpeed = MOVE_SPEED
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
		actualSpeed = actualSpeed * SPRINT_MULTIPLIER
	end

	local rotationCFrame = CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(currentPitch, 0, 0)
	local moveDirection = Vector3.new()

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += rotationCFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= rotationCFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= rotationCFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += rotationCFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDirection += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDirection -= Vector3.new(0, 1, 0) end

	local finalMoveOffsetMagnitude = 0
	if moveDirection.Magnitude > 0 then
		finalMoveOffsetMagnitude = actualSpeed * deltaTime
	end

	-- 3. Обновляем CFrame камеры
	-- Сначала применяем вращение к текущей позиции камеры, чтобы получить новую ориентацию
	local newOrientation = CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(currentPitch, 0, 0)
	camera.CFrame = CFrame.new(camera.CFrame.Position) * newOrientation

	-- Затем, если есть движение, смещаем камеру ВДОЛЬ ЕЕ НОВОГО LookVector/RightVector
	if finalMoveOffsetMagnitude > 0 then
		local relativeMove = Vector3.new()
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then relativeMove += Vector3.new(0,0,-1) end -- Вперед по локальной Z
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then relativeMove += Vector3.new(0,0,1)  end -- Назад по локальной Z
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then relativeMove += Vector3.new(-1,0,0) end -- Влево по локальной X
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then relativeMove += Vector3.new(1,0,0)  end -- Вправо по локальной X

		local worldMove = camera.CFrame:VectorToWorldSpace(relativeMove.Unit * finalMoveOffsetMagnitude)

		local verticalMove = Vector3.new()
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then verticalMove += Vector3.new(0, 1, 0) end -- Вверх по мировой Y
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then verticalMove -= Vector3.new(0, 1, 0) end -- Вниз по мировой Y

		camera.CFrame = camera.CFrame + worldMove + (verticalMove * finalMoveOffsetMagnitude)
	end
end

--[[
	Основная функция модуля для включения или выключения фрикама.
	@param enable true для включения, false для выключения.
]]
function FreecamModule:SetEnabled(enable)
	if enable == isFreecamActive then
		--print("FreecamModule: Already in the desired state (" .. tostring(enable) .. ").")
		return -- Ничего не делать, если состояние уже установлено
	end

	isFreecamActive = enable
	local character = player.Character

	if isFreecamActive then
		-- ВКЛЮЧЕНИЕ ФРИКАМА
		--print("FreecamModule: Enabling...")

		-- Сохраняем исходные параметры камеры
		originalCameraType = camera.CameraType
		originalCameraCFrame = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable

		-- Инициализируем углы поворота текущей ориентацией камеры
		local lookVector = camera.CFrame.LookVector
		currentYaw = math.atan2(-lookVector.X, -lookVector.Z)
		currentPitch = math.asin(lookVector.Y)
		currentPitch = math.clamp(currentPitch, MIN_PITCH, MAX_PITCH)

		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		-- Обездвиживаем персонажа
		if character and character:FindFirstChild("HumanoidRootPart") then
			originalHRPAnchoredState = character.HumanoidRootPart.Anchored -- Сохраняем только здесь
			_anchorPlayerCharacter(character, true)
		else
			originalHRPAnchoredState = false -- Дефолт, если персонажа нет или HRP отсутствует
		end

		-- Подключаем обработчики событий
		if not renderSteppedConnection or not renderSteppedConnection.Connected then
			renderSteppedConnection = RunService.RenderStepped:Connect(_updateCameraOnRenderStep)
		end
		if not characterAddedConnection or not characterAddedConnection.Connected then
			characterAddedConnection = player.CharacterAdded:Connect(_handleCharacterAdded)
		end
		--print("FreecamModule: Enabled.")
	else
		-- ВЫКЛЮЧЕНИЕ ФРИКАМА
		--print("FreecamModule: Disabling...")

		-- Восстанавливаем исходные параметры камеры
		if originalCameraType then camera.CameraType = originalCameraType end
		if originalCameraCFrame then camera.CFrame = originalCameraCFrame end

		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default

		-- Возвращаем подвижность персонажу (используя сохраненное originalHRPAnchoredState)
		if character then
			_anchorPlayerCharacter(character, false)
		end
		originalHRPAnchoredState = nil -- Сбрасываем, так как оно было использовано/больше не актуально

		-- Отключаем обработчики событий
		if renderSteppedConnection and renderSteppedConnection.Connected then
			renderSteppedConnection:Disconnect()
			renderSteppedConnection = nil
		end
		if characterAddedConnection and characterAddedConnection.Connected then
			characterAddedConnection:Disconnect()
			characterAddedConnection = nil
		end
		--print("FreecamModule: Disabled.")
	end
end

return FreecamModule