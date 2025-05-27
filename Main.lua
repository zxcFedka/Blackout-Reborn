-- [[ ----- Сначала твой код загрузки Rayfield и других модулей ----- ]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Предположим, что EspModule и FreecamModule загружаются и работают как задумано
local EspModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/Esp.lua'))()
local FreecamModule = loadstring(game:HttpGet('https://raw.githubusercontent.com/zxcFedka/Blackout-Reborn/refs/heads/main/Freecam.lua'))()
local AimbotModule = 

local successEsp, espData = pcall(function() return  end)
if successEsp then EspModule = espData else warn("Failed to load EspModule:", espData) end

local successFreecam, freecamData = pcall(function() return  end)
if successFreecam then FreecamModule = freecamData else warn("Failed to load FreecamModule:", freecamData) end

-- [[ ЗАГРУЗКА ТВОЕГО AIMBOTMODULE ]]
-- Вариант 1: Если AimbotModule это ModuleScript в игре (например, в ReplicatedStorage)
-- Убедись, что путь правильный!
local successAimbot, aimbotData = pcall(function()
    return require(game:GetService("ReplicatedStorage").AimbotModule) -- ИЗМЕНИ ПУТЬ ЕСЛИ НУЖНО
end)
if successAimbot then
    AimbotModule = aimbotData
    print("AimbotModule loaded successfully via require.")
else
    warn("Failed to load AimbotModule via require:", aimbotData)
    -- Вариант 2: Если AimbotModule тоже загружается по URL (замени URL на актуальный)
    -- local aimbotUrl = "URL_К_ТВОЕМУ_AIMBOT_MODULE_НА_GITHUB_ИЛИ_ДРУГОМ_ХОСТИНГЕ"
    -- local successAimbotHttp, aimbotHttpData = pcall(function() return loadstring(game:HttpGet(aimbotUrl))() end)
    -- if successAimbotHttp then
    -- AimbotModule = aimbotHttpData
    --     print("AimbotModule loaded successfully via HTTPGet.")
    -- else
    --     warn("Failed to load AimbotModule via HTTPGet:", aimbotHttpData)
    -- end
end


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

-- [[ ----- ESP Section (из твоего кода) ----- ]]
if EspModule then
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
else
    warn("EspModule not loaded, skipping ESP section.")
end

-- [[ ----- Freecam Section (из твоего кода) ----- ]]
if FreecamModule then
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
else
    warn("FreecamModule not loaded, skipping Freecam section.")
end


-- [[ ----- AIMBOT Section ----- ]]
if AimbotModule then
    local SectionAimbot = Tab:CreateSection("Aimbot")

    -- Кнопка-переключатель для полного включения/выключения аимбота (программно)
    local AimbotProgrammaticallyEnabled = false -- Начальное состояние
    AimbotModule:SetEnabled(AimbotProgrammaticallyEnabled) -- Устанавливаем начальное состояние в модуле

    local ToggleAimbotEnabled = SectionAimbot:CreateToggle({
        Name = "Enable Aimbot System",
        CurrentValue = AimbotProgrammaticallyEnabled, -- Rayfield может использовать это для начального значения
        Callback = function(value) -- Rayfield передает новое значение
            AimbotProgrammaticallyEnabled = value
            AimbotModule:SetEnabled(AimbotProgrammaticallyEnabled)
            print("Aimbot system programmatically set to:", AimbotProgrammaticallyEnabled)
        end,
        Flag = "AimbotSystemToggle"
    })

    -- Кейбайнд для активации аима при зажатии
    local aimbotKeybind = SectionAimbot:CreateKeybind({
       Name = "Hold to Aim",
       CurrentKeybind = "Q", -- Начальная клавиша, будет сохранена/загружена Rayfield
       HoldToInteract = true, -- Важно!
       Flag = "AimbotHoldKeybind",
       Callback = function(isHolding) -- Rayfield передает true при нажатии, false при отпускании для HoldToInteract
            if AimbotModule then
                AimbotModule:SetManualAimActive(isHolding)
                if isHolding then
                    print("Aimbot manual aim: ON (Key Held)")
                else
                    print("Aimbot manual aim: OFF (Key Released)")
                end
            end
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
           if AimbotModule and selectedOptions and selectedOptions[1] then
               local newTargetPart = selectedOptions[1]
               AimbotModule:SetTargetPart(newTargetPart)
               print("Aimbot target part set to:", newTargetPart)
           end
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
            if AimbotModule then
                AimbotModule:SetSmooth(value)
                print("Aimbot smoothness set to:", value)
            end
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
            if AimbotModule then
                AimbotModule:SetDistance(value)
                print("Aimbot max distance set to:", value)
            end
        end,
    })
else
    warn("AimbotModule not loaded, skipping Aimbot section.")
end

-- [[ ----- Конец скрипта Rayfield ----- ]]