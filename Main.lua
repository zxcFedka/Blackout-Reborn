local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local EspModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Esp.lua'))()
local FreecamModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Freecam.lua'))()
local AimbotModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/Aimbot.lua'))()
local SafepointModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/modules/SafePoint.lua'))()

local Players = game.Players

local Window = Rayfield:CreateWindow({
   Name = "Blackout zalupa",
   Icon = 0,
   LoadingTitle = "Loading huinyu...",
   LoadingSubtitle = "by zxcfedka)",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Big Hub"
   },
   Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
   KeySystem = false,
   KeySettings = { Title = "Untitled", Subtitle = "Key System", Note = "No method of obtaining the key is provided", FileName = "Key", SaveKey = true, GrabKeyFromSite = false, Key = {"Hello"} }
})

local Tab = Window:CreateTab("Main")

local SectionEsp = Tab:CreateSection("Esp")
local EspEnabled = false
local ToggleEsp = Tab:CreateToggle({ -- Используем SectionEsp
    Name = "Toggle Esp",
    Callback = function()
        EspEnabled = not EspEnabled
        EspModule:SetEnabled(EspEnabled)
    end,
    Flag = "EspToggle" -- Добавь флаг для сохранения
})

local FriendColorPicker = Tab:CreateColorPicker({
    Name = "Friend Color",
    Color = Color3.fromRGB(255,255,255),
    Flag = "ColorPicker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        print(Value)
        EspModule:SetFriendFillColor(Value)
    end
})

local PlayerColorPicker = Tab:CreateColorPicker({
    Name = "Enemy Color",
    Color = Color3.fromRGB(255,255,255),
    Flag = "ColorPicker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        print(Value)
        EspModule:SetFillColor(Value)
    end
})

local PlayersList = {}

for i, v in Players do
    PlayersList[i] = true
end

local Dropdown = Tab:CreateDropdown({
   Name = "Friend list",
   Options = PlayersList,
   CurrentOption = {},
   MultipleOptions = false,
   Flag = "Dropdown1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Options)
        print(Options)
   end,
})

local SectionSafePoint = Tab:CreateSection("SafePoint")

local SetPointKeybind = Tab:CreateKeybind({
    Name = "Bind to set Safepoint",
    CurrentKeybind = "J",
    HoldToInteract = false,
    Flag = "SafePointKeybind",
    Callback = function()
		SafepointModule.Set()
    end,
})

local TeleportToPointKeybind = Tab:CreateKeybind({
    Name = "Bind to teleport to Safepoint",
    CurrentKeybind = "K",
    HoldToInteract = false,
    Flag = "TPSafePointKeybind",
    Callback = function()
		SafepointModule.Teleport()
    end,
})

local SectionFreecam = Tab:CreateSection("Freecam")
local FreecamEnabled = false
local ToggleFreecam = Tab:CreateToggle({ -- Используем SectionFreecam
    Name = "Toggle Freecam",
    Callback = function()
        FreecamEnabled = not FreecamEnabled
        FreecamModule:SetEnabled(FreecamEnabled)
    end,
    Flag = "FreecamToggle" -- Добавь флаг для сохранения
})

local FreecamKeybind = Tab:CreateKeybind({
    Name = "Freecam bind",
    CurrentKeybind = "M",
    HoldToInteract = false,
    Flag = "FreecamHoldKeybind",
    Callback = function()
        FreecamEnabled = not FreecamEnabled
		ToggleFreecam:Set(FreecamEnabled)

        FreecamModule:SetEnabled(FreecamEnabled)
    end,
})


local SectionAimbot = Tab:CreateSection("Aimbot")

-- Кнопка-переключатель для полного включения/выключения аимбота (программно)
local AimbotProgrammaticallyEnabled = false -- Начальное состояние
AimbotModule.SetEnabled(AimbotProgrammaticallyEnabled) -- Устанавливаем начальное состояние в модуле

local aimbotKeybind = Tab:CreateKeybind({
    Name = "Hold to Aim",
    CurrentKeybind = "Q",
    HoldToInteract = true,
    Flag = "AimbotHoldKeybind",
    Callback = function(isHolding)
		AimbotModule.SetManualAimActive(isHolding)
    end,
})

-- Выпадающий список для выбора части тела
local characterParts = {
    "Head", "Torso",
	"HumanoidRootPart",
	"LeftArm", "RightArm",
	"LeftLeg", "RightLeg"
}
local defaultAimPart = "Head"
AimbotModule.SetTargetPart(defaultAimPart) -- Устанавливаем начальное значение в модуле

local aimPartDropdown = Tab:CreateDropdown({
    Name = "Aim Part",
    Options = characterParts,
    CurrentOption = {defaultAimPart}, -- Rayfield ожидает таблицу, даже для одиночного выбора
    MultipleOptions = false,
    Flag = "AimbotTargetPartDropdown",
    Callback = function(selectedOptions) -- Rayfield передает таблицу выбранных опций
        local newTargetPart = selectedOptions[1]
            
        AimbotModule.SetTargetPart(newTargetPart)
    end,
})

-- Слайдер для плавности
local defaultSmoothness = 15
AimbotModule.SetSmooth(defaultSmoothness) -- Устанавливаем начальное значение

local smoothnessSlider = Tab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {5, 50}, -- Диапазон значений (мин, макс)
    Increment = 1, -- Шаг изменения
    Suffix = "", -- Суффикс (например, "ms")
    CurrentValue = defaultSmoothness, -- Начальное значение
    Flag = "AimbotSmoothnessSlider",
    Callback = function(value)
        AimbotModule.SetSmooth(value)
    end,
})

-- Слайдер или инпут для дистанции
local defaultDistance = 500
AimbotModule.SetDistance(defaultDistance) -- Устанавливаем начальное значение

local distanceSlider = Tab:CreateSlider({
    Name = "Max Aim Distance",
    Range = {50, 2000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = defaultDistance,
    Flag = "AimbotDistanceSlider",
    Callback = function(value)
         AimbotModule.SetDistance(value)
    end,
})

local defaultAimFov = 90 -- Начальное значение FOV (полный угол конуса)
AimbotModule.SetAimFov(defaultAimFov) -- Устанавливаем начальное значение в модуле

local aimFovSlider = Tab:CreateSlider({
    Name = "Aim FOV ( degrés )", -- Field of View
    Range = {10, 180},     -- Диапазон значений (например, от узкого 10 до широкого 180 градусов)
    Increment = 1,          -- Шаг изменения
    Suffix = "°",           -- Суффикс "градусы"
    CurrentValue = defaultAimFov, -- Начальное значение
    Flag = "AimbotFovSlider",   -- Уникальный флаг
    Callback = function(value)
        if AimbotModule then
            AimbotModule.SetAimFov(value)
            print("Aimbot FOV set to:", value)
        end
    end,
})

Players.PlayerAdded:Connect(function(player)
    if PlayersList[player] then
        return 
    else
        PlayersList[player] = true
        end
end)

Players.PlayerRemoving:Connect(function(player)
     if PlayersList[player] then
        PlayersList[player] = nil
     end
end)