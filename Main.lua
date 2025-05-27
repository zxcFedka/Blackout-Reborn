-- [[ ----- Сначала твой код загрузки Rayfield и других модулей ----- ]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Предположим, что EspModule и FreecamModule загружаются и работают как задумано
local EspModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/Esp.lua'))()
local FreecamModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/Freecam.lua'))()
local AimbotModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/Aimbot.lua'))()

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
local ToggleEsp = SectionEsp:CreateToggle({ -- Используем SectionEsp
    Name = "Toggle Esp",
    Callback = function()
        EspEnabled = not EspEnabled
        EspModule:SetEnabled(EspEnabled)
    end,
    Flag = "EspToggle" -- Добавь флаг для сохранения
})

local SectionFreecam = Tab:CreateSection("Freecam")
local FreecamEnabled = false
local ToggleFreecam = SectionFreecam:CreateToggle({ -- Используем SectionFreecam
    Name = "Toggle Freecam",
    Callback = function()
        FreecamEnabled = not FreecamEnabled
        FreecamModule:SetEnabled(FreecamEnabled)
    end,
    Flag = "FreecamToggle" -- Добавь флаг для сохранения
})


local SectionAimbot = Tab:CreateSection("Aimbot")

-- Кнопка-переключатель для полного включения/выключения аимбота (программно)
local AimbotProgrammaticallyEnabled = false -- Начальное состояние
AimbotModule:SetEnabled(AimbotProgrammaticallyEnabled) -- Устанавливаем начальное состояние в модуле

-- Кейбайнд для активации аима при зажатии
local aimbotKeybind = SectionAimbot:CreateKeybind({
    Name = "Hold to Aim",
    CurrentKeybind = "Q", -- Начальная клавиша, будет сохранена/загружена Rayfield
    HoldToInteract = true, -- Важно!
    Flag = "AimbotHoldKeybind",
    Callback = function(isHolding) -- Rayfield передает true при нажатии, false при отпускании для HoldToInteract
        AimbotModule:SetManualAimActive(isHolding)
    end,
})

-- Выпадающий список для выбора части тела
local characterParts = {
    "Head", "Torso", "HumanoidRootPart",
    "UpperTorso", "LowerTorso", -- R15
    "LeftUpperArm", "LeftLowerArm", "LeftHand", -- R15
    "RightUpperArm", "RightLowerArm", "RightHand", -- R15
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", -- R15
    "RightUpperLeg", "RightLowerLeg", "RightFoot" -- R15
}
local defaultAimPart = "Head"
AimbotModule:SetTargetPart(defaultAimPart) -- Устанавливаем начальное значение в модуле

local aimPartDropdown = SectionAimbot:CreateDropdown({
    Name = "Aim Part",
    Options = characterParts,
    CurrentOption = {defaultAimPart}, -- Rayfield ожидает таблицу, даже для одиночного выбора
    MultipleOptions = false,
    Flag = "AimbotTargetPartDropdown",
    Callback = function(selectedOptions) -- Rayfield передает таблицу выбранных опций
        local newTargetPart = selectedOptions[1]
            
        AimbotModule:SetTargetPart(newTargetPart)
    end,
})

-- Слайдер для плавности
local defaultSmoothness = 15
AimbotModule:SetSmooth(defaultSmoothness) -- Устанавливаем начальное значение

local smoothnessSlider = SectionAimbot:CreateSlider({
    Name = "Aim Smoothness",
    Range = {5, 50}, -- Диапазон значений (мин, макс)
    Increment = 1, -- Шаг изменения
    Suffix = "", -- Суффикс (например, "ms")
    CurrentValue = defaultSmoothness, -- Начальное значение
    Flag = "AimbotSmoothnessSlider",
    Callback = function(value)
        AimbotModule:SetSmooth(value)
    end,
})

-- Слайдер или инпут для дистанции
local defaultDistance = 500
AimbotModule:SetDistance(defaultDistance) -- Устанавливаем начальное значение

local distanceSlider = SectionAimbot:CreateSlider({
    Name = "Max Aim Distance",
    Range = {50, 2000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = defaultDistance,
    Flag = "AimbotDistanceSlider",
    Callback = function(value)
         AimbotModule:SetDistance(value)
    end,
})

local defaultAimFov = 90 -- Начальное значение FOV (полный угол конуса)
AimbotModule:SetAimFov(defaultAimFov) -- Устанавливаем начальное значение в модуле

local aimFovSlider = SectionAimbot:CreateSlider({
    Name = "Aim FOV ( degrés )", -- Field of View
    Range = {10, 180},     -- Диапазон значений (например, от узкого 10 до широкого 180 градусов)
    Increment = 1,          -- Шаг изменения
    Suffix = "°",           -- Суффикс "градусы"
    CurrentValue = defaultAimFov, -- Начальное значение
    Flag = "AimbotFovSlider",   -- Уникальный флаг
    Callback = function(value)
        if AimbotModule then
            AimbotModule:SetAimFov(value)
            print("Aimbot FOV set to:", value)
        end
    end,
})