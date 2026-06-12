--[[
    Fling Script - UN Style UI
    Multi-target fling with clean interface
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local uiParent
do
    local ok = pcall(function() game:GetService("CoreGui"):IsA("DataModel") end)
    uiParent = ok and game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
end

local rgb = Color3.fromRGB
local ud2 = UDim2.new
local ud = UDim.new
local bold = Enum.Font.GothamBold
local reg = Enum.Font.Gotham

-- Color Palette
local C = {
    bg = rgb(25, 25, 25),
    surface = rgb(35, 35, 35),
    part_bg = rgb(45, 45, 45),
    surfaceAlt = rgb(40, 40, 40),
    border = rgb(45, 45, 52),
    accent = rgb(50, 120, 255),
    textPri = rgb(218, 218, 222),
    textSec = rgb(115, 115, 128),
    dot_red = rgb(220, 80, 70),
    dot_yel = rgb(255, 215, 0),
    dot_grn = rgb(60, 180, 90),
    toggle_off = rgb(55, 55, 62),
    toggle_on = rgb(50, 120, 255),
    knob = rgb(245, 245, 248),
    white = rgb(255, 255, 255),
    fling_btn = rgb(0, 160, 80),
    fling_once = rgb(50, 120, 255),
}

-- Config
local CFG_FOLDER = "FlingScript"
local CFG_FILE = "settings"
local CFG_EXT = ".cfg"

local function cfgSafely(fn, ...)
    if fn then
        local ok, res = pcall(fn, ...)
        if not ok then return nil end
        return res
    end
end

local function ensureCfgFolder()
    if isfolder and not cfgSafely(isfolder, CFG_FOLDER) then
        cfgSafely(makefolder, CFG_FOLDER)
    end
end

local function saveConfig(data)
    ensureCfgFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        cfgSafely(writefile, CFG_FOLDER.."/"..CFG_FILE..CFG_EXT, encoded)
    end
end

local function loadConfig()
    local path = CFG_FOLDER.."/"..CFG_FILE..CFG_EXT
    if not cfgSafely(isfile, path) then return nil end
    local content = cfgSafely(readfile, path)
    if not content then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    return ok and data or nil
end

local savedCfg = loadConfig() or {}

local cfgTransparency = savedCfg.transparency or 0.25
local cfgLightMode = savedCfg.lightMode or false
local cfgKeybind1Name = savedCfg.keybind1 or "LeftControl"
local cfgKeybind2Name = savedCfg.keybind2 or "Z"

local function keycodeFromName(name)
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    return (ok and kc) or Enum.KeyCode.Unknown
end

local activeKeybind = {
    keycodeFromName(cfgKeybind1Name),
    keycodeFromName(cfgKeybind2Name),
}

local uiTransparency = cfgTransparency

local function triggerAutoSave()
    saveConfig({
        transparency = uiTransparency,
        lightMode = cfgLightMode,
        keybind1 = activeKeybind[1].Name,
        keybind2 = activeKeybind[2].Name,
    })
end

-- Theme
local themeRegistry = {}

local function applyTheme()
    if cfgLightMode then
        C.bg = rgb(240, 240, 240)
        C.surface = rgb(225, 225, 225)
        C.part_bg = rgb(215, 215, 215)
        C.surfaceAlt = rgb(200, 200, 200)
        C.border = rgb(180, 180, 180)
        C.textPri = rgb(30, 30, 30)
        C.textSec = rgb(90, 90, 90)
        C.toggle_off = rgb(170, 170, 170)
        C.knob = rgb(255, 255, 255)
        C.white = rgb(20, 20, 20)
    else
        C.bg = rgb(25, 25, 25)
        C.surface = rgb(35, 35, 35)
        C.part_bg = rgb(45, 45, 45)
        C.surfaceAlt = rgb(40, 40, 40)
        C.border = rgb(45, 45, 52)
        C.textPri = rgb(218, 218, 222)
        C.textSec = rgb(115, 115, 128)
        C.toggle_off = rgb(55, 55, 62)
        C.knob = rgb(245, 245, 248)
        C.white = rgb(255, 255, 255)
    end

    for _, record in ipairs(themeRegistry) do
        if record.obj and record.obj.Parent then
            for prop, cKey in pairs(record.tags) do
                if C[cKey] then
                    record.obj[prop] = C[cKey]
                end
            end
        end
    end
end

local function Make(className, props)
    local inst = Instance.new(className)
    local tags = {}
    for k, v in pairs(props) do
        inst[k] = v
        if typeof(v) == "Color3" then
            for cKey, cVal in pairs(C) do
                if v == cVal and cKey ~= "toggle_on" and cKey ~= "dot_red" and cKey ~= "dot_yel" and cKey ~= "dot_grn" then
                    tags[k] = cKey
                    break
                end
            end
        end
    end
    if next(tags) then
        table.insert(themeRegistry, {obj = inst, tags = tags})
    end
    return inst
end

local transparencyFrames = {}
local function applyTransparency(t)
    uiTransparency = math.clamp(t, 0, 0.85)
    for _, e in ipairs(transparencyFrames) do
        if e.frame and e.frame.Parent then
            local target = math.clamp(e.base + uiTransparency * (1 - e.base), 0, 0.90)
            e.frame.BackgroundTransparency = target
        end
    end
end

-- GUI
local existingGui = uiParent:FindFirstChild("FlingScriptUI")
if existingGui then existingGui:Destroy() end

local Gui = Make("ScreenGui", {
    Name = "FlingScriptUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = uiParent,
})

local NORMAL_W, NORMAL_H = 320, 440

local Main = Make("Frame", {
    Size = ud2(0, NORMAL_W, 0, NORMAL_H),
    Position = ud2(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = uiTransparency,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
    Parent = Gui,
})
Make("UICorner", {CornerRadius = ud(0, 16), Parent = Main})

local MainScale = Make("UIScale", {Scale = 1, Parent = Main})

local BorderFrame = Make("Frame", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1,
    BorderSizePixel = 0, Parent = Main,
})
Make("UICorner", {CornerRadius = ud(0,16), Parent = BorderFrame})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.5, Parent = BorderFrame})

-- Pill UI (for minimize)
local PillUI = Make("TextButton", {
    Size = ud2(0,110,0,34), Position = ud2(0.5,0,0,12),
    AnchorPoint = Vector2.new(0.5,0),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = uiTransparency,
    Text = "FLING SCRIPT",
    TextColor3 = C.textPri, Font = bold, TextSize = 12,
    Active = true, Visible = false, Parent = Gui,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = PillUI})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = PillUI})
local PillScale = Make("UIScale", {Scale = 1, Parent = PillUI})

-- Header
local HeaderBar = Make("Frame", {
    Size = ud2(1,0,0,42), BackgroundTransparency = 1,
    BorderSizePixel = 0, Parent = Main,
})

local function makeDot(xPos, color, parent)
    local dot = Make("TextButton", {
        Size = ud2(0,16,0,16), Position = ud2(0,xPos,0,14),
        Text = "", BackgroundColor3 = color,
        BorderSizePixel = 0, Parent = parent or HeaderBar,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = dot})
    return dot
end

local CloseBtn = makeDot(14, C.dot_red)
local MinBtn = makeDot(36, C.dot_yel)
local MaxBtn = makeDot(58, C.dot_grn)

local TitleLabel = Make("TextLabel", {
    Size = ud2(0,120,0,42), Position = ud2(0.5,-60,0,0),
    BackgroundTransparency = 1, Text = "FLING SCRIPT",
    TextColor3 = C.textPri, TextSize = 13, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, Parent = HeaderBar,
})

local ToggleBtn = Make("TextButton", {
    Size = ud2(0,28,0,28), Position = ud2(1,-36,0,7),
    BackgroundTransparency = 1, Text = "⚙",
    TextColor3 = C.textSec, TextSize = 16, Font = bold, Parent = HeaderBar,
})

-- Main Page & Settings Page
local MainPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
})

local SetPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, ClipsDescendants = true,
    Visible = false, Parent = Main,
})

-- Status
local StatusLabel = Make("TextLabel", {
    Size = ud2(1,-24,0,24), Position = ud2(0,12,0,8),
    BackgroundTransparency = 1, Text = "Select targets to fling",
    TextColor3 = C.textSec, Font = reg, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = MainPage,
})

-- Player List
local SelectionFrame = Make("Frame", {
    Size = ud2(1,-24,0,200), Position = ud2(0,12,0,38),
    BackgroundColor3 = C.surface,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = MainPage,
})
Make("UICorner", {CornerRadius = ud(0,12), Parent = SelectionFrame})

local PlayerScrollFrame = Make("ScrollingFrame", {
    Size = ud2(1,-8,1,-8), Position = ud2(0,4,0,4),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = SelectionFrame,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,3), Parent = PlayerScrollFrame})

-- Buttons Frame
local ButtonsFrame = Make("Frame", {
    Size = ud2(1,-24,0,120), Position = ud2(0,12,0,244),
    BackgroundTransparency = 1, Parent = MainPage,
})

-- Select All / Deselect All
local SelectAllBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,30), Position = ud2(0,0,0,0),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "SELECT ALL", TextColor3 = C.textPri,
    Font = bold, TextSize = 11, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = SelectAllBtn})

local DeselectAllBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,30), Position = ud2(0.5,3,0,0),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "DESELECT ALL", TextColor3 = C.textPri,
    Font = bold, TextSize = 11, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = DeselectAllBtn})

-- Select Nearest / Auto Select 
local SelectNearestBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,30), Position = ud2(0,0,0,35),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "SELECT NEAREST", TextColor3 = C.textPri,
    Font = bold, TextSize = 11, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = SelectNearestBtn})

local AutoSelectFrame = Make("Frame", {
    Size = ud2(0.5,-3,0,30), Position = ud2(0.5,3,0,35),
    BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = AutoSelectFrame})

Make("TextLabel", {
    Size = ud2(1,-40,1,0), Position = ud2(0,10,0,0),
    BackgroundTransparency = 1, Text = "Auto Select",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = AutoSelectFrame,
})

local AutoSelectToggle = Make("Frame", {
    Size = ud2(0,30,0,16), Position = ud2(1,-36,0,7),
    BackgroundColor3 = C.toggle_off,
    BorderSizePixel = 0, Parent = AutoSelectFrame,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = AutoSelectToggle})

local AutoSelectKnob = Make("Frame", {
    Size = ud2(0,12,0,12), Position = ud2(0,2,0,2),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = AutoSelectToggle,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = AutoSelectKnob})

local autoSelectEnabled = false

local AutoSelectHitbox = Make("TextButton", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
    ZIndex = 5, Parent = AutoSelectToggle,
})

-- Fling Buttons
local FlingOnceBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,36), Position = ud2(0,0,0,75),
    BackgroundColor3 = C.fling_once,
    BackgroundTransparency = 0.05,
    Text = "FLING ONCE", TextColor3 = C.white,
    Font = bold, TextSize = 13, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = FlingOnceBtn})

local FlingBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,36), Position = ud2(0.5,3,0,75),
    BackgroundColor3 = C.fling_btn,
    BackgroundTransparency = 0.05,
    Text = "FLING LOOP", TextColor3 = C.white,
    Font = bold, TextSize = 13, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = FlingBtn})


-- Settings Page
Make("TextLabel", {
    Size = ud2(1,0,0,42), BackgroundTransparency = 1, Text = "Settings",
    TextColor3 = C.textPri, TextSize = 16, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = SetPage,
})

local SettingsScroll = Make("ScrollingFrame", {
    Size = ud2(1,-24,1,-54), Position = ud2(0,12,0,48),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = SetPage,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,8), Parent = SettingsScroll})

-- Shortcuts Section
local ShortcutsSection = Make("Frame", {
    Size = ud2(1,0,0,80), BackgroundTransparency = 1, Parent = SettingsScroll,
})

Make("TextLabel", {
    Size = ud2(1,0,0,20), BackgroundTransparency = 1, Text = "SHORTCUTS",
    TextColor3 = C.textSec, TextSize = 10, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = ShortcutsSection,
})

local ShortcutPill = Make("Frame", {
    Size = ud2(1,0,0,36), Position = ud2(0,0,0,24),
    BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = ShortcutsSection,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = ShortcutPill})

Make("TextLabel", {
    Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Toggle UI Keybind",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = ShortcutPill,
})

local KeybindBtn = Make("TextButton", {
    Size = ud2(0,110,0,22), Position = ud2(1,-145,0,7),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "[ " .. activeKeybind[1].Name .. " + " .. activeKeybind[2].Name .. " ]",
    TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = ShortcutPill,
})
Make("UICorner", {CornerRadius = ud(0,4), Parent = KeybindBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = KeybindBtn})

local isListeningForKeybind = false
local tempKeys = {}

KeybindBtn.MouseButton1Click:Connect(function()
    if not isListeningForKeybind then
        isListeningForKeybind = true
        tempKeys = {}
        KeybindBtn.Text = "[ Press 1st Key ]"
        KeybindBtn.TextColor3 = C.dot_yel
    end
end)

-- Appearance Section
local ThemeSection = Make("Frame", {
    Size = ud2(1,0,0,130), BackgroundTransparency = 1, Parent = SettingsScroll,
})

Make("TextLabel", {
    Size = ud2(1,0,0,20), BackgroundTransparency = 1, Text = "APPEARANCE",
    TextColor3 = C.textSec, TextSize = 10, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = ThemeSection,
})

-- Light Mode Toggle
local LightModePill = Make("Frame", {
    Size = ud2(1,0,0,36), Position = ud2(0,0,0,24),
    BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = ThemeSection,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = LightModePill})

Make("TextLabel", {
    Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Light Mode",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = LightModePill,
})

local LightModeToggle = Make("Frame", {
    Size = ud2(0,36,0,18), Position = ud2(1,-46,0,9),
    BackgroundColor3 = cfgLightMode and C.toggle_on or C.toggle_off,
    BorderSizePixel = 0, Parent = LightModePill,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = LightModeToggle})

local LightModeKnob = Make("Frame", {
    Size = ud2(0,14,0,14),
    Position = cfgLightMode and ud2(0,20,0,2) or ud2(0,2,0,2),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = LightModeToggle,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = LightModeKnob})

local LightModeHitbox = Make("TextButton", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
    ZIndex = 5, Parent = LightModeToggle,
})

-- Transparency Slider
local SliderPill = Make("Frame", {
    Size = ud2(1,0,0,56), Position = ud2(0,0,0,68),
    BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = ThemeSection,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = SliderPill})

Make("TextLabel", {
    Size = ud2(0,120,0,20), Position = ud2(0,14,0,6),
    BackgroundTransparency = 1, Text = "Transparency",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderPill,
})

local SliderValueLbl = Make("TextLabel", {
    Size = ud2(0,36,0,20), Position = ud2(1,-50,0,6),
    BackgroundTransparency = 1,
    Text = math.floor(cfgTransparency/0.85*100+0.5).."%",
    TextColor3 = C.textSec, TextSize = 10, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Right, Parent = SliderPill,
})

local SliderTrack = Make("Frame", {
    Size = ud2(1,-28,0,6), Position = ud2(0,14,0,36),
    BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
    BorderSizePixel = 0, Parent = SliderPill,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderTrack})

local initFrac = cfgTransparency / 0.85
local SliderFill = Make("Frame", {
    Size = ud2(initFrac,0,1,0), BackgroundColor3 = C.accent,
    BackgroundTransparency = 0, BorderSizePixel = 0, Parent = SliderTrack,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderFill})

local SliderKnob = Make("Frame", {
    Size = ud2(0,14,0,14), Position = ud2(initFrac,-7,0,-4),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = SliderTrack,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderKnob})

local sliderDragging = false
local SliderHitbox = Make("TextButton", {
    Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7),
    BackgroundTransparency = 1, Text = "", Parent = SliderTrack,
})

local function updateSlider(inputX)
    local relX = inputX - SliderTrack.AbsolutePosition.X
    local frac = math.clamp(relX / SliderTrack.AbsoluteSize.X, 0, 1)
    SliderFill.Size = ud2(frac, 0, 1, 0)
    SliderKnob.Position = ud2(frac, -7, 0, -4)
    SliderValueLbl.Text = math.floor(frac * 100 + 0.5).."%"
    applyTransparency(frac * 0.85)
end

-- Variables
local SelectedTargets = {}
local PlayerCheckboxes = {}
local FlingActive = false
local FlingMode = nil
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Functions
local function CountSelectedTargets()
    local count = 0
    for _ in pairs(SelectedTargets) do
        count = count + 1
    end
    return count
end

local function UpdateStatus()
    local count = CountSelectedTargets()
    if FlingActive then
        if FlingMode == "once" then
            StatusLabel.Text = "Flinging " .. count .. " target(s) (once)"
        else
            StatusLabel.Text = "Flinging " .. count .. " target(s) (loop)"
        end
        StatusLabel.TextColor3 = C.dot_red
    else
        StatusLabel.Text = count .. " target(s) selected"
        StatusLabel.TextColor3 = C.textSec
    end
end

local function RefreshPlayerList()
    for _, child in pairs(PlayerScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    PlayerCheckboxes = {}

    local PlayerList = Players:GetPlayers()
    table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)

    for _, player in ipairs(PlayerList) do
        if player ~= Players.LocalPlayer then
            local PlayerEntry = Make("Frame", {
                Size = ud2(1,-8,0,32), BackgroundColor3 = C.surfaceAlt,
                BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Parent = PlayerScrollFrame,
            })
            Make("UICorner", {CornerRadius = ud(0,6), Parent = PlayerEntry})

            local Checkbox = Make("Frame", {
                Size = ud2(0,20,0,20), Position = ud2(0,8,0,6),
                BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = PlayerEntry,
            })
            Make("UICorner", {CornerRadius = ud(0,4), Parent = Checkbox})
            Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = Checkbox})

            local Checkmark = Make("TextLabel", {
                Size = ud2(1,0,1,0), BackgroundTransparency = 1,
                Text = "✓", TextColor3 = C.dot_grn, TextSize = 14,
                Font = bold, Visible = SelectedTargets[player.Name] ~= nil,
                Parent = Checkbox,
            })

            local NameLabel = Make("TextLabel", {
                Size = ud2(1,-40,1,0), Position = ud2(0,34,0,0),
                BackgroundTransparency = 1, Text = player.Name,
                TextColor3 = C.textPri, TextSize = 12, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = PlayerEntry,
            })

            local ClickArea = Make("TextButton", {
                Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
                ZIndex = 2, Parent = PlayerEntry,
            })

            -- [[ DOUBLE TAP LOGIC IMPLEMENTED HERE ]]
            local lastClickTime = 0
            ClickArea.MouseButton1Click:Connect(function()
                local currentTime = tick()
                
                -- Detect Double Tap (within 0.25 seconds)
                if currentTime - lastClickTime < 0.25 then
                    -- Deselect everyone else visually
                    for _, cb in pairs(PlayerCheckboxes) do
                        cb.Checkmark.Visible = false
                    end
                    -- Clear the table entirely
                    for k in pairs(SelectedTargets) do SelectedTargets[k] = nil end
                    
                    -- Single out the clicked player
                    SelectedTargets[player.Name] = player
                    Checkmark.Visible = true
                    
                    lastClickTime = 0 -- Reset so a triple click doesn't trigger it again
                else
                    -- Standard Single Tap
                    if SelectedTargets[player.Name] then
                        SelectedTargets[player.Name] = nil
                        Checkmark.Visible = false
                    else
                        SelectedTargets[player.Name] = player
                        Checkmark.Visible = true
                    end
                    lastClickTime = currentTime
                end
                
                UpdateStatus()
            end)

            PlayerCheckboxes[player.Name] = {
                Entry = PlayerEntry,
                Checkmark = Checkmark,
            }
        end
    end

    PlayerScrollFrame.CanvasSize = ud2(0, 0, 0, 0)
end

local function ToggleAllPlayers(select)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local checkboxData = PlayerCheckboxes[player.Name]
            if checkboxData then
                if select then
                    SelectedTargets[player.Name] = player
                    checkboxData.Checkmark.Visible = true
                else
                    SelectedTargets[player.Name] = nil
                    checkboxData.Checkmark.Visible = false
                end
            end
        end
    end
    UpdateStatus()
end

-- Fling Logic
local function SkidFling(TargetPlayer)
    local Player = Players.LocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end

        if THumanoid and THumanoid.Sit then
            return
        end

        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end

        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end

        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not FlingActive
        end

        workspace.FallenPartsDestroyHeight = 0/0

        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        end

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid

        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    end
end

local function StopFling()
    if not FlingActive then return end
    FlingActive = false
    FlingMode = nil
    FlingBtn.Text = "FLING LOOP"
    FlingBtn.BackgroundColor3 = C.fling_btn
    FlingOnceBtn.Text = "FLING ONCE"
    FlingOnceBtn.BackgroundColor3 = C.fling_once
    UpdateStatus()
end

local function StartFlingLoop()
    if FlingActive then return end
    local count = CountSelectedTargets()
    if count == 0 then
        StatusLabel.Text = "No targets selected!"
        task.delay(1, function()
            StatusLabel.Text = "Select targets to fling"
            StatusLabel.TextColor3 = C.textSec
        end)
        return
    end

    FlingActive = true
    FlingMode = "loop"
    FlingBtn.Text = "STOP LOOP"
    FlingBtn.BackgroundColor3 = C.dot_red
    FlingOnceBtn.Text = "FLING ONCE"
    FlingOnceBtn.BackgroundColor3 = C.fling_once
    UpdateStatus()

    task.spawn(function()
        while FlingActive do
            local validTargets = {}
            for name, player in pairs(SelectedTargets) do
                if player and player.Parent then
                    validTargets[name] = player
                else
                    SelectedTargets[name] = nil
                    local checkbox = PlayerCheckboxes[name]
                    if checkbox then
                        checkbox.Checkmark.Visible = false
                    end
                end
            end

            for _, player in pairs(validTargets) do
                if FlingActive then
                    SkidFling(player)
                    task.wait(0.1)
                else
                    break
                end
            end

            UpdateStatus()
            task.wait(0.5)
        end
    end)
end

local function StartFlingOnce()
    if FlingActive then return end
    local count = CountSelectedTargets()
    if count == 0 then
        StatusLabel.Text = "No targets selected!"
        task.delay(1, function()
            StatusLabel.Text = "Select targets to fling"
            StatusLabel.TextColor3 = C.textSec
        end)
        return
    end

    FlingActive = true
    FlingMode = "once"
    FlingOnceBtn.Text = "FLINGING..."
    FlingOnceBtn.BackgroundColor3 = C.dot_red
    FlingBtn.Text = "FLING LOOP"
    FlingBtn.BackgroundColor3 = C.fling_btn
    UpdateStatus()

    task.spawn(function()
        local validTargets = {}
        for name, player in pairs(SelectedTargets) do
            if player and player.Parent then
                validTargets[name] = player
            else
                SelectedTargets[name] = nil
                local checkbox = PlayerCheckboxes[name]
                if checkbox then
                    checkbox.Checkmark.Visible = false
                end
            end
        end

        for _, player in pairs(validTargets) do
            if FlingActive then
                SkidFling(player)
                task.wait(0.1)
            else
                break
            end
        end

        StopFling()
    end)
end

-- Connections
SelectAllBtn.MouseButton1Click:Connect(function() ToggleAllPlayers(true) end)
DeselectAllBtn.MouseButton1Click:Connect(function() ToggleAllPlayers(false) end)

-- [[ SELECT NEAREST TARGET LOGIC HERE ]]
SelectNearestBtn.MouseButton1Click:Connect(function()
    local localChar = Players.LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    local nearestPlayer = nil
    local shortestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - localRoot.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearestPlayer = p
                end
            end
        end
    end

    if nearestPlayer then
        -- Deselect everyone else
        for name, cb in pairs(PlayerCheckboxes) do
            cb.Checkmark.Visible = false
        end
        for k in pairs(SelectedTargets) do SelectedTargets[k] = nil end
        
        -- Select the nearest player
        SelectedTargets[nearestPlayer.Name] = nearestPlayer
        if PlayerCheckboxes[nearestPlayer.Name] then
            PlayerCheckboxes[nearestPlayer.Name].Checkmark.Visible = true
        end
        UpdateStatus()
    end
end)

FlingBtn.MouseButton1Click:Connect(function()
    if FlingMode == "loop" then
        StopFling()
    else
        StartFlingLoop()
    end
end)

FlingOnceBtn.MouseButton1Click:Connect(function()
    if FlingMode == "once" then
        StopFling()
    else
        StartFlingOnce()
    end
end)

AutoSelectHitbox.MouseButton1Click:Connect(function()
    autoSelectEnabled = not autoSelectEnabled
    TweenService:Create(AutoSelectKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = autoSelectEnabled and ud2(0,16,0,2) or ud2(0,2,0,2)
    }):Play()
    TweenService:Create(AutoSelectToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundColor3 = autoSelectEnabled and C.toggle_on or C.toggle_off
    }):Play()
end)

LightModeHitbox.MouseButton1Click:Connect(function()
    cfgLightMode = not cfgLightMode
    TweenService:Create(LightModeKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = cfgLightMode and ud2(0,20,0,2) or ud2(0,2,0,2)
    }):Play()
    TweenService:Create(LightModeToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundColor3 = cfgLightMode and C.toggle_on or C.toggle_off
    }):Play()
    applyTheme()
    triggerAutoSave()
end)

SliderHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if sliderDragging then
            sliderDragging = false
            triggerAutoSave()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end)

-- Settings Toggle
local inSettings = false
ToggleBtn.MouseButton1Click:Connect(function()
    inSettings = not inSettings
    ToggleBtn.Text = inSettings and "📄" or "⚙"
    MainPage.Visible = not inSettings
    SetPage.Visible = inSettings
end)

-- Window Controls
local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local pillUsed = false
local lastMainPos = Main.Position
local isExpanded = false
local isAnimating = false

CloseBtn.MouseButton1Click:Connect(function()
    StopFling()
    Gui:Destroy()
end)

local function shrinkToPill()
    if not Main.Visible or isAnimating then return end
    isAnimating = true
    lastMainPos = Main.Position
    PillUI.Size = ud2(0,0,0,34)
    if not pillUsed then
        PillUI.Position = ud2(0.5,0,0,12)
        pillUsed = true
    end
    PillUI.Visible = true
    PillScale.Scale = 0
    TweenService:Create(PillUI, tweenInfo, {Size = ud2(0,110,0,34)}):Play()
    TweenService:Create(PillScale, tweenInfo, {Scale = 1}):Play()
    TweenService:Create(MainScale, tweenInfo, {Scale = 0}):Play()
    TweenService:Create(Main, tweenInfo, {
        Position = ud2(PillUI.Position.X.Scale, PillUI.Position.X.Offset,
            PillUI.Position.Y.Scale, PillUI.Position.Y.Offset + 17)
    }):Play()
    task.delay(0.32, function()
        if Main and Main.Parent then Main.Visible = false end
        isAnimating = false
    end)
end

local function expandFromPill()
    if not PillUI.Visible or isAnimating then return end
    isAnimating = true
    Main.Position = lastMainPos
    Main.Visible = true
    TweenService:Create(PillScale, tweenInfo, {Scale = 0}):Play()
    TweenService:Create(MainScale, tweenInfo, {Scale = isExpanded and 1.3 or 1}):Play()
    task.delay(0.32, function()
        if PillUI and PillUI.Parent then PillUI.Visible = false; PillScale.Scale = 1 end
        isAnimating = false
    end)
end

MinBtn.MouseButton1Click:Connect(shrinkToPill)

MaxBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    TweenService:Create(MainScale, tweenInfo, {Scale = isExpanded and 1.3 or 1}):Play()
    triggerAutoSave()
end)

-- Pill click to expand
local pillDragStart = nil
PillUI.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pillDragStart = input.Position
    end
end)
PillUI.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and pillDragStart then
        if (input.Position - pillDragStart).Magnitude < 6 then
            expandFromPill()
        end
        pillDragStart = nil
    end
end)

-- Dragging 
local dragging = false
local dragOffset = Vector2.new()
local insetOff = Vector2.new()

local function updateInset()
    local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
    if ok then insetOff = inset end
end

Main.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        updateInset()
        dragging = true
        local mousePos = UserInputService:GetMouseLocation()
        local mainPos = Main.AbsolutePosition + Main.AbsoluteSize * Main.AnchorPoint
        dragOffset = mainPos - mousePos - insetOff
    end
end)

local dragConn
dragConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local renderConn
renderConn = RunService.RenderStepped:Connect(function()
    if dragging then
        local mousePos = UserInputService:GetMouseLocation()
        local newPos = mousePos + dragOffset + insetOff
        Main.Position = UDim2.fromOffset(newPos.X, newPos.Y)
    end
end)

Gui.Destroying:Connect(function()
    if dragConn then dragConn:Disconnect() end
    if renderConn then renderConn:Disconnect() end
end)

-- Player Events
Players.PlayerAdded:Connect(function(player)
    if autoSelectEnabled then
        task.wait(0.5)
        SelectedTargets[player.Name] = player
        local checkbox = PlayerCheckboxes[player.Name]
        if checkbox then
            checkbox.Checkmark.Visible = true
        end
        UpdateStatus()
    end
    RefreshPlayerList()
end)

Players.PlayerRemoving:Connect(function(player)
    if SelectedTargets[player.Name] then
        SelectedTargets[player.Name] = nil
    end
    RefreshPlayerList()
    UpdateStatus()
end)

-- Keybind Listener
local keybindConn
keybindConn = UserInputService.InputBegan:Connect(function(input, processed)
    if not Gui or not Gui.Parent then
        keybindConn:Disconnect()
        return
    end

    if isListeningForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            table.insert(tempKeys, input.KeyCode)
            if #tempKeys == 1 then
                KeybindBtn.Text = "[ " .. tempKeys[1].Name .. " + ? ]"
            elseif #tempKeys == 2 then
                activeKeybind = {tempKeys[1], tempKeys[2]}
                isListeningForKeybind = false
                KeybindBtn.TextColor3 = C.textPri
                KeybindBtn.Text = "[ " .. tempKeys[1].Name .. " + " .. tempKeys[2].Name .. " ]"
                triggerAutoSave()
            end
        end
        return
    end

    if not processed and not isListeningForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        if #activeKeybind == 2 then
            if (input.KeyCode == activeKeybind[2] and UserInputService:IsKeyDown(activeKeybind[1]))
            or (input.KeyCode == activeKeybind[1] and UserInputService:IsKeyDown(activeKeybind[2])) then
                if Main.Visible then
                    shrinkToPill()
                elseif PillUI.Visible then
                    expandFromPill()
                end
            end
        end
    end
end)

-- Initialize
transparencyFrames = {
    {frame = Main, base = 0},
    {frame = PillUI, base = 0},
}
applyTransparency(cfgTransparency)
applyTheme()
RefreshPlayerList()
UpdateStatus()