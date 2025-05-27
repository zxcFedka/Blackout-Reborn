local ESPModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration (локальные для модуля)
local FriendList = {
	-- ["whylaway"] = true,
	["aphroishak"] = true,
	-- ["cursed13371"] = true
}

local HIGHLIGHT_NAME = "MyCustomPlayerHighlight"

local HighlightTemplate = Instance.new("Highlight")
HighlightTemplate.Name = HIGHLIGHT_NAME
HighlightTemplate.FillColor = Color3.fromRGB(255, 0, 0)
HighlightTemplate.OutlineColor = Color3.fromRGB(180, 0, 0)
HighlightTemplate.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
HighlightTemplate.Enabled = true -- Шаблон всегда включен, но применяется выборочно

-- State variables (локальные для модуля)
local isEspActive = false -- Состояние ESP, управляется через SetEnabled
local connections = {} -- Таблица для хранения всех соединений, чтобы их можно было отключить

--[[
	Внутренняя функция для обновления визуальных эффектов игрока (модель и ник).
	Решает, применять ли эффекты, на основе isEspActive и списка друзей.
	@param player Игрок, для которого обновляются визуалы.
]]
local function _updatePlayerVisuals(player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")

	local isFriend = FriendList[player.Name] == true

	-- --- Подсветка модели ---
	if hrp then
		local existingHighlight = hrp:FindFirstChild(HIGHLIGHT_NAME)

		if not isEspActive or isFriend then -- Если ESP выключен ИЛИ это друг
			if existingHighlight then
				existingHighlight:Destroy()
			end
		else -- ESP включен И это НЕ друг
		local newHighlight
			if not existingHighlight then
				newHighlight = HighlightTemplate:Clone()
				newHighlight.Adornee = character -- Важно: Adornee должен быть моделью для корректной работы Highlight
				newHighlight.Parent = hrp
			elseif not newHighlight.Enabled then
				newHighlight.Enabled = true
			end
		end
	end

end

--[[
	Обработчик добавления персонажа игроку.
	@param player Игрок, у которого появился персонаж.
]]
local function _onCharacterAdded(player)
	-- Даем небольшую задержку, чтобы убедиться, что все части персонажа загрузились
	task.wait(0.2)
	_updatePlayerVisuals(player)
end

--[[
	Обработчик добавления нового игрока в игру.
	@param player Новый игрок.
]]
local function _onPlayerAdded(player)
	if player.Character then
		_onCharacterAdded(player)
	end
	-- Сохраняем соединение, чтобы его можно было отключить
	table.insert(connections, player.CharacterAdded:Connect(function() _onCharacterAdded(player) end))
end

--[[
	Обработчик Heartbeat для периодического обновления.
]]
local lastHeartbeatUpdateTime = 0
local HEARTBEAT_UPDATE_INTERVAL = 0.5
local function _onHeartbeat(deltaTime)
	if not isEspActive then return end -- Если ESP не активен, не делаем частых обновлений

	lastHeartbeatUpdateTime = lastHeartbeatUpdateTime + deltaTime
	if lastHeartbeatUpdateTime >= HEARTBEAT_UPDATE_INTERVAL then
		lastHeartbeatUpdateTime = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				_updatePlayerVisuals(player)
			end
		end
	end
end

--[[
	Основная функция модуля для включения или выключения ESP.
	@param enable true для включения, false для выключения.
]]
function ESPModule:SetEnabled(enable)
	if type(enable) ~= "boolean" then
		warn("ESPModule:SetEnabled - expected boolean argument, got " .. type(enable))
		return
	end

	if enable == isEspActive then
		--print("ESPModule: Already in the desired state (" .. tostring(enable) .. ").")
		return
	end

	isEspActive = enable
	--print("ESPModule: Set to " .. tostring(isEspActive))

	if isEspActive then
		-- ВКЛЮЧЕНИЕ ESP
		-- Применяем ко всем текущим игрокам
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				_onCharacterAdded(player) -- Используем _onCharacterAdded для начальной обработки
			end
			-- Убедимся, что CharacterAdded подключен для всех существующих игроков
			local foundConnection = false
			for _, connEntry in ipairs(connections) do
				if connEntry.Player == player and connEntry.Event == "CharacterAdded" then
					foundConnection = true
					break
				end
			end
			if not foundConnection then
				local conn = player.CharacterAdded:Connect(function() _onCharacterAdded(player) end)
				table.insert(connections, {Connection = conn, Player = player, Event = "CharacterAdded"})
			end
		end

		-- Подключаем обработчики для новых игроков и Heartbeat
		if not connections["PlayerAdded"] then
			connections["PlayerAdded"] = Players.PlayerAdded:Connect(_onPlayerAdded)
		end
		if not connections["Heartbeat"] then
			connections["Heartbeat"] = RunService.Heartbeat:Connect(_onHeartbeat)
			lastHeartbeatUpdateTime = 0 -- Сброс таймера при активации
		end
	else
		-- ВЫКЛЮЧЕНИЕ ESP
		-- Отключаем все эффекты для всех игроков
		for _, player in ipairs(Players:GetPlayers()) do
			_updatePlayerVisuals(player) -- Эта функция уберет эффекты, если isEspActive = false
		end
		-- Примечание: Heartbeat сам перестанет делать что-либо, если isEspActive = false,
		-- но лучше его отключить, чтобы не тратить ресурсы.
		if connections["Heartbeat"] and connections["Heartbeat"].Connected then
			connections["Heartbeat"]:Disconnect()
			connections["Heartbeat"] = nil
		end
		-- PlayerAdded и CharacterAdded для существующих игроков можно оставить,
		-- так как они ничего не сделают, если isEspActive = false.
		-- Либо полностью очищать и переподключать, но это сложнее в управлении.
		-- Для простоты, оставим CharacterAdded для уже подключенных игроков,
		-- но PlayerAdded отключим, чтобы новые игроки не получали лишних обработчиков.
		if connections["PlayerAdded"] and connections["PlayerAdded"].Connected then
			connections["PlayerAdded"]:Disconnect()
			connections["PlayerAdded"] = nil
		end
		-- Чтобы полностью очистить все соединения (если это предпочтительнее):
		-- for key, connData in pairs(connections) do
		-- 	if type(connData) == "RBXScriptConnection" and connData.Connected then
		-- 		connData:Disconnect()
		-- 	elseif type(connData) == "table" and connData.Connection and connData.Connection.Connected then
		-- 		connData.Connection:Disconnect()
		-- 	end
		-- end
		-- table.clear(connections) -- или connections = {}
	end
end

--[[
	Функция для добавления имени игрока в список друзей.
	@param playerName Имя игрока (string).
]]
function ESPModule:AddFriend(playerName)
	if type(playerName) == "string" then
		FriendList[playerName] = true
		print("ESPModule: ".. playerName .. " added to friends.")
		-- Обновить визуалы для этого игрока, если он онлайн
		local player = Players:FindFirstChild(playerName)
		if player then
			_updatePlayerVisuals(player)
		end
	else
		warn("ESPModule:AddFriend - expected string argument, got " .. type(playerName))
	end
end

--[[
	Функция для удаления имени игрока из списка друзей.
	@param playerName Имя игрока (string).
]]
function ESPModule:RemoveFriend(playerName)
	if type(playerName) == "string" then
		if FriendList[playerName] then
			FriendList[playerName] = nil
			print("ESPModule: ".. playerName .. " removed from friends.")
			-- Обновить визуалы для этого игрока, если он онлайн
			local player = Players:FindFirstChild(playerName)
			if player then
				_updatePlayerVisuals(player)
			end
		else
			print("ESPModule: ".. playerName .. " not found in friends list.")
		end
	else
		warn("ESPModule:RemoveFriend - expected string argument, got " .. type(playerName))
	end
end

--[[
	Функция для получения текущего состояния ESP (активен или нет).
	@return boolean: true если ESP активен, false если нет.
]]
function ESPModule:IsEnabled()
	return isEspActive
end

return ESPModule