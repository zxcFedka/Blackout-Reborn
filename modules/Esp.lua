local ESPModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer -- Получаем локального игрока

-- Configuration (локальные для модуля)
local FriendList = {}

local HIGHLIGHT_NAME = "MyCustomPlayerHighlight"
local FRIEND_HIGHLIGHT_NAME = "MyCustomFriendHighlight" -- Имя для хайлайта друзей
local BILLBOARD_NAME = "CustomPlayerBillboard"

-- Загружаем функцию для создания билборда
local successLoad, createBillboardAndLabelsFunc = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Billboard.lua'))()
end)

if not successLoad or typeof(createBillboardAndLabelsFunc) ~= "function" then
    warn("ESPModule: Failed to load or execute Billboard.lua. Billboard functionality will be disabled.")
    createBillboardAndLabelsFunc = function() return nil, nil, nil end -- Fallback to prevent errors
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
local playerBillboards = {} -- { [Player] = {billboard, playerLabel, hpLabel, humanoid} }

--[[
	Внутренняя функция для обновления визуальных эффектов игрока.
]]
local function _updatePlayerVisuals(player)
	if not player or not player:IsA("Player") then return end

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
			if playerBillboards[player].billboard and playerBillboards[player].billboard.Parent then
				playerBillboards[player].billboard:Destroy()
			end
			playerBillboards[player] = nil
		end
		return
	end

	local character = player.Character
	if not character or not character.Parent then
		if playerBillboards[player] then
			if playerBillboards[player].billboard and playerBillboards[player].billboard.Parent then
				playerBillboards[player].billboard:Destroy()
			end
			playerBillboards[player] = nil
		end
		-- Хайлайты удалятся вместе с персонажем или если HRP нет
		local hrp = character and character:FindFirstChild("HumanoidRootPart") -- Попытка найти, если character еще существует
		if hrp then
			local h1 = hrp:FindFirstChild(HIGHLIGHT_NAME)
			if h1 then h1:Destroy() end
			local h2 = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)
			if h2 then h2:Destroy() end
		end
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not hrp then -- HRP нужен для хайлайтов
		-- Если нет HRP, удаляем хайлайты
		-- Билборд будет обработан ниже, если head/humanoid тоже отсутствуют
	end
	
	-- Если нет ключевых частей для билборда (head/humanoid), или HRP для хайлайтов
	if not hrp or not head or not humanoid then
		if hrp then -- Если hrp есть, а остального нет, удаляем хайлайты
			local h1 = hrp:FindFirstChild(HIGHLIGHT_NAME)
			if h1 then h1:Destroy() end
			local h2 = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)
			if h2 then h2:Destroy() end
		end
		if playerBillboards[player] then
			if playerBillboards[player].billboard and playerBillboards[player].billboard.Parent then
				playerBillboards[player].billboard:Destroy()
			end
			playerBillboards[player] = nil
		end
		return
	end

	local isFriend = FriendList[player.Name] == true

	local shouldHaveEnemyEspVisuals = isEspActive and not isFriend
	local shouldHaveFriendHighlight = isEspActive and isFriend

	-- --- Управление Хайлайтами ---
	if hrp then -- Убедимся, что HRP все еще существует
		local existingHighlight = hrp:FindFirstChild(HIGHLIGHT_NAME)
		local existingFriendHighlight = hrp:FindFirstChild(FRIEND_HIGHLIGHT_NAME)

		if shouldHaveFriendHighlight then
			if existingHighlight then existingHighlight:Destroy() end
			if not existingFriendHighlight then
				local newFriendHighlight = FriendHighlightTemplate:Clone()
				newFriendHighlight.Adornee = character
				newFriendHighlight.Parent = hrp
			end
		elseif shouldHaveEnemyEspVisuals then
			if existingFriendHighlight then existingFriendHighlight:Destroy() end
			if not existingHighlight then
				local newHighlight = HighlightTemplate:Clone()
				newHighlight.Adornee = character
				newHighlight.Parent = hrp
			end
		else
			if existingHighlight then existingHighlight:Destroy() end
			if existingFriendHighlight then existingFriendHighlight:Destroy() end
		end
	end

	-- --- Билборд (Имя и HP) - только для не-друзей, если ESP активно ---
	-- (head и humanoid уже проверены выше)
	local billboardData = playerBillboards[player]

	if shouldHaveEnemyEspVisuals then
		if not billboardData or not billboardData.billboard or not billboardData.billboard.Parent then
			if billboardData and billboardData.billboard then -- Уничтожить старый, если он есть, но отсоединен
				billboardData.billboard:Destroy()
			end
			playerBillboards[player] = nil -- Очистить старые данные

            local elements = {createBillboardAndLabelsFunc()} -- Вызов обернут для безопасности
            local newBillboard = elements[1]
            local newPlayerLabel = elements[2]
            local newHpLabel = elements[3]

			if newBillboard and newPlayerLabel and newHpLabel and
               newBillboard:IsA("BillboardGui") and newPlayerLabel:IsA("TextLabel") and newHpLabel:IsA("TextLabel") then

				newBillboard.Name = BILLBOARD_NAME
				newBillboard.Adornee = head
				newBillboard.Parent = head
				newPlayerLabel.Text = player.DisplayName
				
				billboardData = {
					billboard = newBillboard,
					playerLabel = newPlayerLabel,
					hpLabel = newHpLabel,
					humanoid = humanoid
				}
				playerBillboards[player] = billboardData
				billboardData.hpLabel.Text = tostring(math.floor(humanoid.Health)) -- Установить начальное HP
			else
				warn("ESPModule: Failed to create billboard for", player.Name, "- createBillboardAndLabelsFunc returned invalid elements.")
                if newBillboard and newBillboard.Parent then newBillboard:Destroy() end -- Очистка если частично создано
			end
		end
		
		-- Обновляем HP, если билборд существует (также делается в Heartbeat)
		if playerBillboards[player] and playerBillboards[player].billboard and playerBillboards[player].billboard.Parent and playerBillboards[player].humanoid then
			playerBillboards[player].hpLabel.Text = tostring(math.floor(playerBillboards[player].humanoid.Health))
		end
	else
		if billboardData and billboardData.billboard and billboardData.billboard.Parent then
			billboardData.billboard:Destroy()
		end
		playerBillboards[player] = nil
	end
end


--[[
	Обработчик добавления персонажа игроку.
]]
local function _onCharacterAdded(player)
	local character = player.Character
	if not character then
		return
	end

	-- Более надежно ждем появления головы и гуманоида.
	-- Даем до 2 секунд на их появление.
	local head = character:WaitForChild("Head", 2)
	local humanoid = character:WaitForChild("Humanoid", 2) -- Используем Humanoid, не HumanoidRootPart для билборда

	if not head or not humanoid then
		warn("ESPModule: Head or Humanoid not found for " .. player.Name .. " after CharacterAdded wait. Visuals might be incomplete.")
		-- _updatePlayerVisuals все равно вызовется и должен обработать отсутствие частей,
        -- удалив, например, билборд, если он ожидался, но части для него не нашлись.
	end
	
	-- task.wait(0.1) -- Эта задержка может быть нужна в редких случаях, если WaitForChild недостаточно.
    -- Попробуйте без нее. Если проблемы вернутся, можно раскомментировать.
    -- Иногда это помогает, если другие скрипты инициализируют персонажа одновременно.

	-- Убедимся, что персонаж все еще тот, с которым мы начали,
	-- и что он все еще действителен (не был удален/заменен мгновенно).
	if player.Character ~= character or not character.Parent then
		_updatePlayerVisuals(player) -- Позволяем _updatePlayerVisuals обработать текущее (возможно, невалидное) состояние.
		return
	end
	
	_updatePlayerVisuals(player)
end

--[[
	Обработчик добавления нового игрока в игру.
]]
local function _onPlayerAdded(player)
	local conn = player.CharacterAdded:Connect(function() _onCharacterAdded(player) end)
	table.insert(connections, {Type = "CharacterAdded", Player = player, Connection = conn})

	if player.Character then
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

    for i = #connections, 1, -1 do
        local entry = connections[i]
        if entry.Type == "CharacterAdded" and entry.Player == player then
            if entry.Connection and entry.Connection.Connected then
                entry.Connection:Disconnect()
            end
            table.remove(connections, i)
            break -- Предполагаем, что для каждого игрока только одно CharacterAdded соединение
        end
    end
end

--[[
	Обработчик Heartbeat для периодического обновления HP.
]]
local lastHeartbeatUpdateTime = 0
local HEARTBEAT_UPDATE_INTERVAL = 0.2 -- Обновлять 5 раз в секунду
local function _onHeartbeat(deltaTime)
	if not isEspActive then return end

	lastHeartbeatUpdateTime = lastHeartbeatUpdateTime + deltaTime
	if lastHeartbeatUpdateTime >= HEARTBEAT_UPDATE_INTERVAL then
		lastHeartbeatUpdateTime = 0 -- Сброс таймера
		for player, data in pairs(playerBillboards) do
			if player and data and data.billboard and data.billboard.Parent and data.humanoid and data.humanoid.Parent then
				local currentHealth = math.floor(data.humanoid.Health)
				if tonumber(data.hpLabel.Text) ~= currentHealth then
					data.hpLabel.Text = tostring(currentHealth)
				end
                -- Дополнительная проверка на случай, если Adornee билборда изменился или пропал
                if data.billboard.Adornee ~= player.Character:FindFirstChild("Head") then
                    if player.Character and player.Character:FindFirstChild("Head") then
                        data.billboard.Adornee = player.Character:FindFirstChild("Head")
                    else
                        -- Голова пропала, возможно, стоит удалить билборд
                        data.billboard:Destroy()
                        playerBillboards[player] = nil
                    end
                end
			elseif data and data.billboard then 
				-- Если данные есть, но билборд/гуманоид невалидны, очищаем
				data.billboard:Destroy()
				playerBillboards[player] = nil
			elseif not player or not player.Parent then
                -- Если игрок вышел или что-то подобное (хотя PlayerRemoving должен это обработать)
                if data and data.billboard then data.billboard:Destroy() end
                playerBillboards[player] = nil
            end
		end
	end
end

function ESPModule:UpdateFriends(friends)
	FriendList = friends
end

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
		for _, player in ipairs(Players:GetPlayers()) do
            -- Убедимся, что CharacterAdded подключен
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
            -- Обновить визуалы
            if player.Character then
                _onCharacterAdded(player) -- Вызов _onCharacterAdded гарантирует WaitForChild и прочее
            else
                 _updatePlayerVisuals(player) -- Если персонажа нет, просто почистит
            end
		end

		if not connections.PlayerAddedGlobal or not connections.PlayerAddedGlobal.Connected then
			connections.PlayerAddedGlobal = Players.PlayerAdded:Connect(_onPlayerAdded)
		end
        if not connections.PlayerRemovingGlobal or not connections.PlayerRemovingGlobal.Connected then
            connections.PlayerRemovingGlobal = Players.PlayerRemoving:Connect(_onPlayerRemoving)
        end
		if not connections.HeartbeatGlobal or not connections.HeartbeatGlobal.Connected then
			connections.HeartbeatGlobal = RunService.Heartbeat:Connect(_onHeartbeat)
			lastHeartbeatUpdateTime = 0
		end
	else
		-- ВЫКЛЮЧЕНИЕ ESP
		for _, player in ipairs(Players:GetPlayers()) do
			_updatePlayerVisuals(player) -- Эта функция уберет все эффекты
		end
		
		if connections.HeartbeatGlobal and connections.HeartbeatGlobal.Connected then
			connections.HeartbeatGlobal:Disconnect()
			connections.HeartbeatGlobal = nil
		end
		
		-- PlayerAdded и PlayerRemoving можно оставить активными, т.к. они просто управляют CharacterAdded.
		-- А CharacterAdded соединения будут удалены в _onPlayerRemoving.
        -- Либо можно отключать и их, если модуль полностью "выгружается":
        -- if connections.PlayerAddedGlobal and connections.PlayerAddedGlobal.Connected then
		-- 	connections.PlayerAddedGlobal:Disconnect()
		-- 	connections.PlayerAddedGlobal = nil
		-- end
        -- if connections.PlayerRemovingGlobal and connections.PlayerRemovingGlobal.Connected then
		-- 	connections.PlayerRemovingGlobal:Disconnect()
		-- 	connections.PlayerRemovingGlobal = nil
		-- end
        -- -- И затем пройтись по всем CharacterAdded и отключить их.
        -- for i = #connections, 1, -1 do
        --     local entry = connections[i]
        --     if entry.Type == "CharacterAdded" and entry.Connection and entry.Connection.Connected then
        --         entry.Connection:Disconnect()
        --         table.remove(connections, i)
        --     end
        -- end
	end
end

function ESPModule:AddFriend(playerName)
	if type(playerName) == "string" then
		FriendList[playerName] = true
		local player = Players:FindFirstChild(playerName)
		if player then
			_updatePlayerVisuals(player)
		end
	else
		warn("ESPModule:AddFriend - expected string argument, got " .. type(playerName))
	end
end

function ESPModule:RemoveFriend(playerName)
	if type(playerName) == "string" then
		if FriendList[playerName] then
			FriendList[playerName] = nil
			local player = Players:FindFirstChild(playerName)
			if player then
				_updatePlayerVisuals(player)
			end
		end
	else
		warn("ESPModule:RemoveFriend - expected string argument, got " .. type(playerName))
	end
end

function ESPModule:IsEnabled()
	return isEspActive
end

-- Инициализация для уже существующих игроков при загрузке модуля
-- (Если isEspActive должно быть true по умолчанию, установите его и вызовите SetEnabled(true))
-- ESPModule:SetEnabled(true) -- Раскомментируйте, если ESP должен быть активен при старте

return ESPModule