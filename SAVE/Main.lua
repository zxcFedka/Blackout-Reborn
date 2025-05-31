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
      FolderName = "Blackout Config",
      FileName = "Config"
   },
   Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
   KeySystem = false,
   KeySettings = { Title = "Untitled", Subtitle = "Key System", Note = "No method of obtaining the key is provided", FileName = "Key", SaveKey = true, GrabKeyFromSite = false, Key = {"Hello"} }
})

warn("Initilize...")

local Friends = {}

local FriendModule = {}

function FriendModule:Add(name: string)
    if not Friends[name] then
        Friends[name] = true
        FriendModule:EventUpdate()

        return true
    end
    return nil
end

function FriendModule:Remove(name: string)
    if Friends[name] then
        Friends[name] = nil
        FriendModule:EventUpdate()

        return true
    end
    return nil
end

function FriendModule:Get()
    return Friends
end

function FriendModule:EventUpdate()
    AimbotModule:Update(Friends)
end

local Tab = Window:CreateTab("Main")

local VisualTab = Window:CreateTab("Visual")

local MiscTab = Window:CreateTab("Misc")

local FriendsTab = Window:CreateTab("Friends")

local SectionEsp = VisualTab:CreateSection("Esp")
local EspEnabled = false
local ToggleEsp = VisualTab:CreateToggle({ -- Используем SectionEsp
    Name = "Toggle Esp",
    Callback = function()
        EspEnabled = not EspEnabled
        EspModule:SetEnabled(EspEnabled)
    end,
    Flag = "EspToggle" -- Добавь флаг для сохранения
})

local FriendColorPicker = VisualTab:CreateColorPicker({
    Name = "Friend Color",
    Color = Color3.fromRGB(255,255,255),
    Flag = "ColorPicker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        print(Value)
        EspModule:SetFriendFillColor(Value)
    end
})

local PlayerColorPicker = VisualTab:CreateColorPicker({
    Name = "Enemy Color",
    Color = Color3.fromRGB(255,255,255),
    Flag = "ColorPicker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        print(Value)
        EspModule:SetFillColor(Value)
    end
})

-- local PlayersList = {}

-- for i, v in Players:GetPlayers() do
--     if v ~= Players.LocalPlayer then
--         PlayersList[v.Name] = true
--     end
-- end

-- local Dropdown = Tab:CreateDropdown({
--    Name = "Friend list",
--    Options = PlayersList,
--    CurrentOption = {},
--    MultipleOptions = false,
--    Flag = "Dropdown1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
--    Callback = function(Options)
--         print(Options)
--    end,
-- })

local AddFriendsSection = FriendsTab:CreateSection("Add Friend")

local FriendsDropdown

local InputFriend = FriendsTab:CreateInput({
   Name = "Enter Friend Name",
   CurrentValue = "",
   PlaceholderText = "Friend Name",
   RemoveTextAfterFocusLost = false,
   Flag = "Input1",
   Callback = function(Text)
    local success = FriendModule:Add(Text)
    if success then
        Rayfield:Notify({
            Title = "Friend Alert",
            Content = Text.." Added!",
            Duration = 1.5,
            Image = 4483362458,
        })

        FriendsDropdown:Refresh(FriendModule:Get())
    end
   end,
})

local FriendsSection = FriendsTab:CreateSection("Friends")

local SelectedFriend

FriendsDropdown = FriendsTab:CreateDropdown({
   Name = "Friends",
   Options = {},
   CurrentOption = {},
   MultipleOptions = false,
   Flag = "Dropdown1Friends", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Options)
        SelectedFriend = Options
   end,
})

local RemoveFriend = FriendsTab:CreateButton({
   Name = "Remove Selected Friend",
   Callback = function()
    local success = FriendModule:Remove(SelectedFriend)
    if success then

        Rayfield:Notify({
            Title = "Friend Alert",
            Content = SelectedFriend.." Removed!",
            Duration = 1.5,
            Image = 134028882209847,
        })

        FriendsDropdown:Refresh(FriendModule:Get())
    end
   end,
})

local SectionSafePoint = MiscTab:CreateSection("SafePoint")

local SetPointKeybind = MiscTab:CreateKeybind({
    Name = "Bind to set Safepoint",
    CurrentKeybind = "J",
    HoldToInteract = false,
    Flag = "SafePointKeybind",
    Callback = function()
		local pos = SafepointModule.Set()

        Rayfield:Notify({
            Title = "Safepoint Alert",
            Content = "Safe point Set at "..pos,
            Duration = 1.5,
            Image = 134028882209847,
        })

    end,
})

local TeleportToPointKeybind = MiscTab:CreateKeybind({
    Name = "Bind to teleport to Safepoint",
    CurrentKeybind = "K",
    HoldToInteract = false,
    Flag = "TPSafePointKeybind",
    Callback = function()
		SafepointModule.Teleport()
    end,
})

local SectionFreecam = MiscTab:CreateSection("Freecam")
local FreecamEnabled = false
-- local ToggleFreecam = MiscTab:CreateToggle({ -- Используем SectionFreecam
--     Name = "Toggle Freecam",
--     Callback = function()
--         FreecamEnabled = not FreecamEnabled
--         FreecamModule:SetEnabled(FreecamEnabled)
--     end,
--     Flag = "FreecamToggle" -- Добавь флаг для сохранения
-- })

local FreecamKeybind = MiscTab:CreateKeybind({
    Name = "Freecam bind",
    CurrentKeybind = "M",
    HoldToInteract = false,
    Flag = "FreecamHoldKeybind",
    Callback = function()
        FreecamEnabled = not FreecamEnabled
		-- ToggleFreecam:Set(FreecamEnabled)

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