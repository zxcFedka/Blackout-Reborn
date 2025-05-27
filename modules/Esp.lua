local ESPModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer -- Получаем локального игрока

-- Configuration (локальные для модуля)
local FriendList = {
	-- ["whylaway"] = true,
	["aphroishak"] = true,
	-- ["cursed13371"] = true
}

local HIGHLIGHT_NAME = "MyCustomPlayerHighlight"
local FRIEND_HIGHLIGHT_NAME = "MyCustomFriendHighlight" -- Имя для хайлайта друзей
local BILLBOARD_NAME = "CustomPlayerBillboard"

-- Загружаем функцию для создания билборда
local createBillboardAndLabels = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Billboard.lua'))()
if typeof(createBillboardAndLabels) ~= "function" then
	warn("ESPModule: Failed to load Billboard module or it did not return a function.")
	createBillboardAndLabels = function()
		warn("ESPModule: Using fallback billboard creator.")
		local b = Instance.new("BillboardGui")
		local pl = Instance.new("TextLabel", b); pl.Name = "player"; pl.Text = "Error"
		local hl = Instance.new("TextLabel", b); hl.Name = "hp"; hl.Text = "N/A"
		return b, pl, hl
	end
end

-- Шаблон Highlight для обычных игроков (не друзей)
local HighlightTemplate = Instance.new("Highlight")
HighlightTemplate.Name = HIGHLIGHT_NAME
HighlightTemplate.FillColor = Color3.fromRGB(255, 0, 0) -- Красный для врагов
HighlightTemplate.OutlineTransparency = 1
HighlightTemplate.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
HighlightTemplate.Enabled = true

-- Шаблон Highlight для друзей
local FriendHighlightTemplate = Instance.new("Highlight")
FriendHighlightTemplate.Name = FRIEND_HIGHLIGHT_NAME
FriendHighlightTemplate.FillColor = Color3.fromRGB(0, 255, 0) -- Зеленый для друзей (по умолчанию)
FriendHighlightTemplate.OutlineTransparency = 1
FriendHighlightTemplate.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
FriendHighlightTemplate.Enabled = true

-- State variables (локальные для модуля)
local isEspActive = false
local connections = {}
local playerBillboards = {} -- { [Player] = {billboard, playerLabel, hpLabel} }

--[[
	Внутренняя функция для обновления визуальных эффектов игрока.
]]
local function _updatePlayerVisuals(player)
	if not player then return end -- Дополнительная проверка

	-- Не применять ESP к локальному игроку
	if player == LocalPlayer then
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local h1 = hrp:FindFirstChild(HIGHLIGHT_NAME)
				if h1 then h1:Destroy() end
				local h2 = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)
				if h2 then h2:Destroy() end
			end
		end
		if playerBillboards[player] then
			playerBillboards[player].billboard:Destroy()
			playerBillboards[player] = nil
		end
		return
	end

	local character = player.Character
	if not character then
		if playerBillboards[player] then
			playerBillboards[player].billboard:Destroy()
			playerBillboards[player] = nil
		end
		-- Убедимся, что хайлайты тоже удалены, если персонаж исчез
		-- (Хотя Adornee на модель должен сам это делать, но для надежности)
		-- Это может быть излишним, если HighlightTemplate.Adornee = character
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	-- Если нет ключевых частей, удаляем все эффекты
	if not hrp or not head or not humanoid then
		if hrp then -- Если hrp есть, а остального нет, удаляем хайлайты
			local h1 = hrp:FindFirstChild(HIGHLIGHT_NAME)
			if h1 then h1:Destroy() end
			local h2 = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)
			if h2 then h2:Destroy() end
		end
		if playerBillboards[player] then
			playerBillboards[player].billboard:Destroy()
			playerBillboards[player] = nil
		end
		return
	end

	local isFriend = FriendList[player.Name] == true

	-- Определяем, какие эффекты должны быть активны
	local shouldHaveEnemyEspVisuals = isEspActive and not isFriend
	local shouldHaveFriendHighlight = isEspActive and isFriend

	-- --- Управление Хайлайтами ---
	local existingHighlight = hrp:FindFirstChild(HIGHLIGHT_NAME)
	local existingFriendHighlight = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)

	if shouldHaveFriendHighlight then -- Если ESP активен и это друг
		if existingHighlight then existingHighlight:Destroy() end -- Удаляем вражеский хайлайт
		if not existingFriendHighlight then
			local newFriendHighlight = FriendHighlightTemplate:Clone()
			newFriendHighlight.Adornee = character
			newFriendHighlight.Parent = hrp
		end
	elseif shouldHaveEnemyEspVisuals then -- Если ESP активен и это не друг (и не LocalPlayer)
		if existingFriendHighlight then existingFriendHighlight:Destroy() end -- Удаляем дружеский хайлайт
		if not existingHighlight then
			local newHighlight = HighlightTemplate:Clone()
			newHighlight.Adornee = character
			newHighlight.Parent = hrp
		end
	else -- ESP выключен, или не применимо
		if existingHighlight then existingHighlight:Destroy() end
		if existingFriendHighlight then existingFriendHighlight:Destroy() end
	end

	-- --- Билборд (Имя и HP) - только для не-друзей, если ESP активно ---
	if head and humanoid then
		local billboardData = playerBillboards[player]

		if shouldHaveEnemyEspVisuals then -- Билборд только для "врагов"
			if not billboardData or not billboardData.billboard.Parent then
				local newBillboard, newPlayerLabel, newHpLabel = createBillboardAndLabels()
				
				newBillboard.Name = BILLBOARD_NAME
				newBillboard.Adornee = head
				newBillboard.Parent = head
				
				newPlayerLabel.Text = player.DisplayName
				
				billboardData = {
					billboard = newBillboard,
					playerLabel = newPlayerLabel,
					hpLabel = newHpLabel,
					humanoid = humanoid -- Сохраняем humanoid для легкого доступа в Heartbeat
				}
				playerBillboards[player] = billboardData
			end
			-- Обновляем HP (имя обычно не меняется)
			billboardData.hpLabel.Text = tostring(math.floor(humanoid.Health))
		else -- Для друзей или если ESP выключен - билборда нет
			if billboardData and billboardData.billboard.Parent then
				billboardData.billboard:Destroy()
			end
			playerBillboards[player] = nil
		end
	end
end

--[[
	Обработчик добавления персонажа игроку.
]]
local function _onCharacterAdded(player)
	task.wait(0.2) 
	_updatePlayerVisuals(player)
end

--[[
	Обработчик добавления нового игрока в игру.
]]
local function _onPlayerAdded(player)
	-- Подключаем CharacterAdded при добавлении игрока
	local conn = player.CharacterAdded:Connect(function() _onCharacterAdded(player) end)
	table.insert(connections, {Type = "CharacterAdded", Player = player, Connection = conn})

	if player.Character then -- Если персонаж уже есть при подключении
		_onCharacterAdded(player)
	end
end

--[[
    Обработчик удаления игрока из игры.
]]
local function _onPlayerRemoving(player)
    if playerBillboards[player] then
        if playerBillboards[player].billboard and playerBillboards[player].billboard.Parent then
            playerBillboards[player].billboard:Destroy()
        end
        playerBillboards[player] = nil
    end
    -- Удаляем хайлайты, если были (хотя они должны удалиться с персонажем)
    -- local char = player.Character -- Персонажа уже может не быть
    -- Вместо этого, _updatePlayerVisuals при отсутствии персонажа должен чистить

    for i = #connections, 1, -1 do
        local entry = connections[i]
        if entry.Type == "CharacterAdded" and entry.Player == player then
            if entry.Connection and entry.Connection.Connected then
                entry.Connection:Disconnect()
            end
            table.remove(connections, i)
        end
    end
end

--[[
	Обработчик Heartbeat для периодического обновления HP.
]]
local lastHeartbeatUpdateTime = 0
local HEARTBEAT_UPDATE_INTERVAL = 0.2
local function _onHeartbeat(deltaTime)
	if not isEspActive then return end

	lastHeartbeatUpdateTime = lastHeartbeatUpdateTime + deltaTime
	if lastHeartbeatUpdateTime >= HEARTBEAT_UPDATE_INTERVAL then
		lastHeartbeatUpdateTime = 0
		for player, data in pairs(playerBillboards) do
			-- Обновляем HP только для тех, у кого есть активный билборд
			-- Игрок должен быть LocalPlayer == false (это уже учтено при создании билборда)
			-- Игрок должен быть не другом (это тоже учтено)
			if player and data and data.billboard and data.billboard.Parent and data.humanoid and data.humanoid.Parent then
				if data.humanoid.Health ~= tonumber(data.hpLabel.Text) then -- Обновляем только если изменилось
					data.hpLabel.Text = tostring(math.floor(data.humanoid.Health))
				end
			elseif data and data.billboard then -- Если что-то пошло не так (например, humanoid исчез)
				data.billboard:Destroy()
				playerBillboards[player] = nil
			end
		end
	end
end

--[[
	Функция для установки цвета заливки для обычных игроков (не друзей).
	@param newColor Color3.
]]
function ESPModule:SetFillColor(newColor)
	if typeof(newColor) == "Color3" then
		HighlightTemplate.FillColor = newColor
		if isEspActive then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and not FriendList[player.Name] and player.Character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local highlight = hrp:FindFirstChild(HIGHLIGHT_NAME)
						if highlight then
							highlight.FillColor = newColor
						end
					end
				end
			end
		end
	else
		warn("ESPModule:SetFillColor - expected Color3 argument, got " .. type(newColor))
	end
end

--[[
	Функция для установки цвета заливки для игроков из FriendList.
	@param newColor Color3.
]]
function ESPModule:SetFriendFillColor(newColor)
	if typeof(newColor) == "Color3" then
		FriendHighlightTemplate.FillColor = newColor
		if isEspActive then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and FriendList[player.Name] and player.Character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local friendHighlight = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)
						if friendHighlight then
							friendHighlight.FillColor = newColor
						end
					end
				end
			end
		end
	else
		warn("ESPModule:SetFriendFillColor - expected Color3 argument, got " .. type(newColor))
	end
end


function ESPModule:SetPlayerNameColor(newColor)
	warn("ESPModule:SetPlayerNameColor - Not implemented. Colors are set within the Billboard module.")
end

function ESPModule:SetPlayerHPColor(newColor)
	warn("ESPModule:SetPlayerHPColor - Not implemented. Colors are set within the Billboard module.")
end

--[[
	Основная функция модуля для включения или выключения ESP.
]]
function ESPModule:SetEnabled(enable)
	if type(enable) ~= "boolean" then
		warn("ESPModule:SetEnabled - expected boolean argument, got " .. type(enable))
		return
	end

	if enable == isEspActive then
		return
	end

	isEspActive = enable

	if isEspActive then
		-- ВКЛЮЧЕНИЕ ESP
		-- Применяем ко всем текущим игрокам
		for _, player in ipairs(Players:GetPlayers()) do
			_updatePlayerVisuals(player) 
			-- Подключаем CharacterAdded для всех существующих игроков, если еще не подключено
			local needsConnection = true
			for _, entry in ipairs(connections) do
				if entry.Type == "CharacterAdded" and entry.Player == player then
					needsConnection = false
					break
				end
			end
			if needsConnection then
				local conn = player.CharacterAdded:Connect(function() _onCharacterAdded(player) end)
				table.insert(connections, {Type = "CharacterAdded", Player = player, Connection = conn})
			end
		end

		-- Подключаем глобальные обработчики, если еще не подключены
		if not connections.PlayerAddedGlobal then -- Изменил имя ключа для ясности
			connections.PlayerAddedGlobal = Players.PlayerAdded:Connect(_onPlayerAdded)
		end
        if not connections.PlayerRemovingGlobal then
            connections.PlayerRemovingGlobal = Players.PlayerRemoving:Connect(_onPlayerRemoving)
        end
		if not connections.HeartbeatGlobal then
			connections.HeartbeatGlobal = RunService.Heartbeat:Connect(_onHeartbeat)
			lastHeartbeatUpdateTime = 0
		end
	else
		-- ВЫКЛЮЧЕНИЕ ESP
		for _, player in ipairs(Players:GetPlayers()) do
			_updatePlayerVisuals(player) -- Эта функция уберет все эффекты
		end
		
		-- Отключаем Heartbeat
		if connections.HeartbeatGlobal and connections.HeartbeatGlobal.Connected then
			connections.HeartbeatGlobal:Disconnect()
			connections.HeartbeatGlobal = nil
		end
		-- PlayerAdded и PlayerRemoving можно оставить.
		-- CharacterAdded соединения будут управляться через _onPlayerRemoving
	end
end

--[[
	Функция для добавления имени игрока в список друзей.
]]
function ESPModule:AddFriend(playerName)
	if type(playerName) == "string" then
		FriendList[playerName] = true
		local player = Players:FindFirstChild(playerName)
		if player then
			_updatePlayerVisuals(player) -- Обновит визуалы (уберет билборд, сменит хайлайт)
		end
	else
		warn("ESPModule:AddFriend - expected string argument, got " .. type(playerName))
	end
end

--[[
	Функция для удаления имени игрока из списка друзей.
]]
function ESPModule:RemoveFriend(playerName)
	if type(playerName) == "string" then
		if FriendList[playerName] then
			FriendList[playerName] = nil
			local player = Players:FindFirstChild(playerName)
			if player then
				_updatePlayerVisuals(player) -- Обновит визуалы (добавит билборд, сменит хайлайт)
			end
		end
	else
		warn("ESPModule:RemoveFriend - expected string argument, got " .. type(playerName))
	end
end

--[[
	Функция для получения текущего состояния ESP (активен или нет).
]]
function ESPModule:IsEnabled()
	return isEspActive
end

return ESPModule