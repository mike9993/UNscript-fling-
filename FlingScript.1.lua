--[[
    Fling Script - UN Style UI
    Multi-target fling with advanced features
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local uiParent
do
    local ok = pcall(function() game:GetService("CoreGui"):IsA("DataModel") end)
    uiParent = ok and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
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
    dot_blue = rgb(70, 130, 220),
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
local cfgFlingPower = savedCfg.flingPower or 1
local cfgGhostFling = savedCfg.ghostFling or false
local cfgSafeReturn = savedCfg.safeReturn ~= false
local cfgDirection = savedCfg.direction or "RANDOM"
local cfgTargetKeybindName = savedCfg.target3DKeybind or "Middle"
local cfgComboKey1Name = savedCfg.comboKey1 or "F"
local cfgComboKey2Name = savedCfg.comboKey2 or "L"
local cfgComboTimeWindow = math.huge

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
        flingPower = cfgFlingPower,
        ghostFling = cfgGhostFling,
        safeReturn = cfgSafeReturn,
        direction = cfgDirection,
        target3DKeybind = cfgTargetKeybindName,
        comboKey1 = cfgComboKey1Name,
        comboKey2 = cfgComboKey2Name,
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
                if v == cVal and cKey ~= "toggle_on" and cKey ~= "dot_red" and cKey ~= "dot_yel" and cKey ~= "dot_grn" and cKey ~= "dot_blue" then
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

-- Transparency system: track every background frame that should respond
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

local function registerTransparencyFrame(frame, base)
    table.insert(transparencyFrames, {frame = frame, base = base or 0})
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

-- Pill UI
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

local SettingsBtn = Make("TextButton", {
    Size = ud2(0,28,0,28), Position = ud2(1,-64,0,7),
    BackgroundTransparency = 1, Text = "⚙",
    TextColor3 = C.textSec, TextSize = 16, Font = bold, Parent = HeaderBar,
})

local ModsBtn = Make("TextButton", {
    Size = ud2(0,28,0,28), Position = ud2(1,-36,0,7),
    BackgroundTransparency = 1, Text = "⚡",
    TextColor3 = C.textSec, TextSize = 16, Font = bold, Parent = HeaderBar,
})

-- Pages
local MainPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
})

local SetPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, ClipsDescendants = true,
    Visible = false, Parent = Main,
})

local ModsPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, ClipsDescendants = true,
    Visible = false, Parent = Main,
})

local activePage = "main"
local function switchPage(page)
    activePage = page
    MainPage.Visible = (page == "main")
    SetPage.Visible = (page == "settings")
    ModsPage.Visible = (page == "modifiers")
    SettingsBtn.TextColor3 = (page == "settings") and C.accent or C.textSec
    ModsBtn.TextColor3 = (page == "modifiers") and C.accent or C.textSec
end

-- =================== MAIN PAGE ===================

-- Search Bar
local SearchFrame = Make("Frame", {
    Size = ud2(1,-24,0,30), Position = ud2(0,12,0,6),
    BackgroundColor3 = C.surface, BackgroundTransparency = 0.2,
    BorderSizePixel = 0, Parent = MainPage,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = SearchFrame})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = SearchFrame})
registerTransparencyFrame(SearchFrame, 0.2)

local SearchIcon = Make("TextLabel", {
    Size = ud2(0,24,1,0), Position = ud2(0,6,0,0),
    BackgroundTransparency = 1, Text = "🔍",
    TextColor3 = C.textSec, TextSize = 12, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = SearchFrame,
})

local SearchBox = Make("TextBox", {
    Size = ud2(1,-36,1,0), Position = ud2(0,28,0,0),
    BackgroundTransparency = 1, Text = "",
    TextColor3 = C.textPri, PlaceholderText = "Search players...",
    PlaceholderColor3 = C.textSec, Font = reg, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false, Parent = SearchFrame,
})

-- Status
local StatusLabel = Make("TextLabel", {
    Size = ud2(1,-24,0,18), Position = ud2(0,12,0,40),
    BackgroundTransparency = 1, Text = "Select targets to fling",
    TextColor3 = C.textSec, Font = reg, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = MainPage,
})

-- Player List
local SelectionFrame = Make("Frame", {
    Size = ud2(1,-24,0,170), Position = ud2(0,12,0,62),
    BackgroundColor3 = C.surface, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = MainPage,
})
Make("UICorner", {CornerRadius = ud(0,12), Parent = SelectionFrame})
registerTransparencyFrame(SelectionFrame, 0.3)

local PlayerScrollFrame = Make("ScrollingFrame", {
    Size = ud2(1,-8,1,-8), Position = ud2(0,4,0,4),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = SelectionFrame,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,3), Parent = PlayerScrollFrame})

-- Buttons
local ButtonsFrame = Make("Frame", {
    Size = ud2(1,-24,0,120), Position = ud2(0,12,0,238),
    BackgroundTransparency = 1, Parent = MainPage,
})

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
    BackgroundColor3 = C.toggle_off, BorderSizePixel = 0, Parent = AutoSelectFrame,
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

local FlingOnceBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,36), Position = ud2(0,0,0,75),
    BackgroundColor3 = C.fling_once, BackgroundTransparency = 0.05,
    Text = "FLING ONCE", TextColor3 = C.white,
    Font = bold, TextSize = 13, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = FlingOnceBtn})

local FlingBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,36), Position = ud2(0.5,3,0,75),
    BackgroundColor3 = C.fling_btn, BackgroundTransparency = 0.05,
    Text = "FLING LOOP", TextColor3 = C.white,
    Font = bold, TextSize = 13, Parent = ButtonsFrame,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = FlingBtn})

-- =================== SETTINGS PAGE ===================
Make("TextLabel", {
    Size = ud2(1,0,0,42), BackgroundTransparency = 1, Text = "Settings",
    TextColor3 = C.textPri, TextSize = 16, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = SetPage,
})

local SettingsTabBar = Make("Frame", {
    Size = ud2(1,-24,0,30), Position = ud2(0,12,0,42),
    BackgroundTransparency = 1, Parent = SetPage,
})
Make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = ud(0,6), Parent = SettingsTabBar,
})

local function makeSettingsTab(name, width)
    local btn = Make("TextButton", {
        Size = ud2(0,width or 75,0,26), BackgroundColor3 = C.surfaceAlt,
        BackgroundTransparency = 0.5, Text = name,
        TextColor3 = C.textSec, TextSize = 10, Font = bold, Parent = SettingsTabBar,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = btn})
    local pill = Make("Frame", {
        Size = ud2(0,0,0,2), Position = ud2(0.5,0,1,-2),
        AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.accent,
        BorderSizePixel = 0, Parent = btn,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    return {Button = btn, Pill = pill}
end

local sTab = {}
sTab.Shortcuts = makeSettingsTab("Shortcuts")
sTab.Appearance = makeSettingsTab("Appearance")

local function makeSetScroll(visible)
    local s = Make("ScrollingFrame", {
        Size = ud2(1,-24,1,-78), Position = ud2(0,12,0,78),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
        CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Active = true, Visible = visible, Parent = SetPage,
    })
    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = s})
    return s
end

local ScrollShortcuts = makeSetScroll(true)
local ScrollAppearance = makeSetScroll(false)

local activeSettingsTab = "Shortcuts"
local tabTween = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function switchSettingsTab(name)
    if activeSettingsTab == name then return end
    activeSettingsTab = name
    ScrollShortcuts.Visible = (name == "Shortcuts")
    ScrollAppearance.Visible = (name == "Appearance")
    for key, tab in pairs(sTab) do
        local active = (key == name)
        TweenService:Create(tab.Pill, tabTween, { Size = active and ud2(0,40,0,2) or ud2(0,0,0,2) }):Play()
        TweenService:Create(tab.Button, tabTween, { TextColor3 = active and C.textPri or C.textSec, BackgroundTransparency = active and 0.2 or 0.5 }):Play()
    end
end

sTab.Shortcuts.Button.MouseButton1Click:Connect(function()  switchSettingsTab("Shortcuts") end)
sTab.Appearance.Button.MouseButton1Click:Connect(function() switchSettingsTab("Appearance") end)

-- === SHORTCUTS TAB ===
-- Toggle UI Keybind
local KeybindPill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ScrollShortcuts,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = KeybindPill})

Make("TextLabel", {
    Size = ud2(0,140,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Toggle UI Keybind",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindPill,
})

local KeybindBtn = Make("TextButton", {
    Size = ud2(0,110,0,22), Position = ud2(1,-124,0,7),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "[ " .. activeKeybind[1].Name .. " + " .. activeKeybind[2].Name .. " ]",
    TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = KeybindPill,
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

-- 3D Target Keybind
local TargetKeyPill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ScrollShortcuts,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = TargetKeyPill})

Make("TextLabel", {
    Size = ud2(0,160,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "3D Target Keybind",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = TargetKeyPill,
})

local TargetKeyBtn = Make("TextButton", {
    Size = ud2(0,80,0,22), Position = ud2(1,-94,0,7),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "[ " .. cfgTargetKeybindName .. " ]",
    TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = TargetKeyPill,
})
Make("UICorner", {CornerRadius = ud(0,4), Parent = TargetKeyBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = TargetKeyBtn})

local isListeningForTargetKey = false
TargetKeyBtn.MouseButton1Click:Connect(function()
    if not isListeningForTargetKey then
        isListeningForTargetKey = true
        TargetKeyBtn.Text = "[ Press Key ]"
        TargetKeyBtn.TextColor3 = C.dot_yel
    end
end)

-- Fling Combo Keybind (single sequential input)
local ComboPill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ScrollShortcuts,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = ComboPill})

Make("TextLabel", {
    Size = ud2(0,160,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Fling Combo Keys",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = ComboPill,
})

local ComboKeyBtn = Make("TextButton", {
    Size = ud2(0,110,0,22), Position = ud2(1,-124,0,7),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "[ " .. cfgComboKey1Name .. " + " .. cfgComboKey2Name .. " ]",
    TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = ComboPill,
})
Make("UICorner", {CornerRadius = ud(0,4), Parent = ComboKeyBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = ComboKeyBtn})

local isListeningForCombo1 = false
local isListeningForCombo2 = false

ComboKeyBtn.MouseButton1Click:Connect(function()
    if not isListeningForCombo1 and not isListeningForCombo2 then
        isListeningForCombo1 = true
        ComboKeyBtn.Text = "[ Press 1st Key ]"
        ComboKeyBtn.TextColor3 = C.dot_yel
    end
end)

-- === APPEARANCE TAB ===
-- Light Mode
local LightModePill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ScrollAppearance,
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
    Size = ud2(1,0,0,56), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ScrollAppearance,
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

-- =================== MODIFIERS PAGE ===================
Make("TextLabel", {
    Size = ud2(1,0,0,42), BackgroundTransparency = 1, Text = "Modifiers",
    TextColor3 = C.textPri, TextSize = 16, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = ModsPage,
})

local ModsScroll = Make("ScrollingFrame", {
    Size = ud2(1,-24,1,-54), Position = ud2(0,12,0,48),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = ModsPage,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,8), Parent = ModsScroll})

-- Fling Power Slider
local PowerSection = Make("Frame", {
    Size = ud2(1,0,0,80), BackgroundTransparency = 1, Parent = ModsScroll,
})

Make("TextLabel", {
    Size = ud2(1,0,0,20), BackgroundTransparency = 1, Text = "FLING POWER",
    TextColor3 = C.textSec, TextSize = 10, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = PowerSection,
})

local PowerPill = Make("Frame", {
    Size = ud2(1,0,0,56), Position = ud2(0,0,0,24),
    BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = PowerSection,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = PowerPill})

local PowerValueLbl = Make("TextLabel", {
    Size = ud2(0,40,0,20), Position = ud2(1,-54,0,6),
    BackgroundTransparency = 1, Text = cfgFlingPower .. "x",
    TextColor3 = C.textSec, TextSize = 10, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Right, Parent = PowerPill,
})

Make("TextLabel", {
    Size = ud2(0,140,0,20), Position = ud2(0,14,0,6),
    BackgroundTransparency = 1, Text = "Velocity Multiplier",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = PowerPill,
})

local PowerTrack = Make("Frame", {
    Size = ud2(1,-28,0,6), Position = ud2(0,14,0,36),
    BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
    BorderSizePixel = 0, Parent = PowerPill,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = PowerTrack})

local powerFrac = math.clamp((cfgFlingPower - 1) / 9, 0, 1)
local PowerFill = Make("Frame", {
    Size = ud2(powerFrac,0,1,0), BackgroundColor3 = C.accent,
    BackgroundTransparency = 0, BorderSizePixel = 0, Parent = PowerTrack,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = PowerFill})

local PowerKnob = Make("Frame", {
    Size = ud2(0,14,0,14), Position = ud2(powerFrac,-7,0,-4),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = PowerTrack,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = PowerKnob})

local powerDragging = false
local PowerHitbox = Make("TextButton", {
    Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7),
    BackgroundTransparency = 1, Text = "", Parent = PowerTrack,
})

local function updatePowerSlider(inputX)
    local relX = inputX - PowerTrack.AbsolutePosition.X
    local frac = math.clamp(relX / PowerTrack.AbsoluteSize.X, 0, 1)
    PowerFill.Size = ud2(frac, 0, 1, 0)
    PowerKnob.Position = ud2(frac, -7, 0, -4)
    cfgFlingPower = math.floor(1 + frac * 9 + 0.5)
    PowerValueLbl.Text = cfgFlingPower .. "x"
end

PowerHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        powerDragging = true
        updatePowerSlider(input.Position.X)
    end
end)

-- Ghost Fling Toggle
local GhostPill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ModsScroll,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = GhostPill})

Make("TextLabel", {
    Size = ud2(1,-60,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Ghost / Invisible Fling",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = GhostPill,
})

local GhostToggle = Make("Frame", {
    Size = ud2(0,36,0,18), Position = ud2(1,-46,0,9),
    BackgroundColor3 = cfgGhostFling and C.toggle_on or C.toggle_off,
    BorderSizePixel = 0, Parent = GhostPill,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = GhostToggle})

local GhostKnob = Make("Frame", {
    Size = ud2(0,14,0,14),
    Position = cfgGhostFling and ud2(0,20,0,2) or ud2(0,2,0,2),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = GhostToggle,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = GhostKnob})

local GhostHitbox = Make("TextButton", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
    ZIndex = 5, Parent = GhostToggle,
})

-- Safe Return Toggle
local SafeRetPill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ModsScroll,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = SafeRetPill})

Make("TextLabel", {
    Size = ud2(1,-60,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Safe-Return (Blink Back)",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = SafeRetPill,
})

local SafeRetToggle = Make("Frame", {
    Size = ud2(0,36,0,18), Position = ud2(1,-46,0,9),
    BackgroundColor3 = cfgSafeReturn and C.toggle_on or C.toggle_off,
    BorderSizePixel = 0, Parent = SafeRetPill,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = SafeRetToggle})

local SafeRetKnob = Make("Frame", {
    Size = ud2(0,14,0,14),
    Position = cfgSafeReturn and ud2(0,20,0,2) or ud2(0,2,0,2),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = SafeRetToggle,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = SafeRetKnob})

local SafeRetHitbox = Make("TextButton", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
    ZIndex = 5, Parent = SafeRetToggle,
})

-- Directional Priority
local DirPill = Make("Frame", {
    Size = ud2(1,0,0,36), BackgroundColor3 = C.part_bg,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ModsScroll,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = DirPill})

Make("TextLabel", {
    Size = ud2(1,-140,1,0), Position = ud2(0,14,0,0),
    BackgroundTransparency = 1, Text = "Fling Direction",
    TextColor3 = C.textPri, TextSize = 11, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = DirPill,
})

local DirBtn = Make("TextButton", {
    Size = ud2(0,110,0,22), Position = ud2(1,-124,0,7),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "[ " .. cfgDirection .. " ]",
    TextColor3 = C.accent, TextSize = 11, Font = bold, Parent = DirPill,
})
Make("UICorner", {CornerRadius = ud(0,6), Parent = DirBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = DirBtn})

local directionOrder = {"RANDOM", "UP", "DOWN"}
local directionIndex = 1
for i, v in ipairs(directionOrder) do
    if v == cfgDirection then directionIndex = i; break end
end

DirBtn.MouseButton1Click:Connect(function()
    directionIndex = directionIndex % #directionOrder + 1
    cfgDirection = directionOrder[directionIndex]
    DirBtn.Text = "[ " .. cfgDirection .. " ]"
    triggerAutoSave()
end)

-- =================== VARIABLES ===================
local SelectedTargets = {}
local PlayerCheckboxes = {}
local FlingActive = false
local FlingMode = nil
local SpectatingTarget = nil
local GhostPart = nil
local SavedCFrame = nil
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- 3D Targeting variables
local lastMPress = 0
local lastTargetedPlayer = nil

-- Combo keybind variables
local comboKey1 = keycodeFromName(cfgComboKey1Name)
local comboKey2 = keycodeFromName(cfgComboKey2Name)
local lastComboKey1Press = 0

-- Forward-declare so SetPlayerSelection can reference it
local UpdateStatus

-- =================== SECURITY ===================
local function EnableSecurity()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    if not Character:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = Character
    end

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

local function DisableSecurity()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)

    local ff = Character:FindFirstChildOfClass("ForceField")
    if ff then ff:Destroy() end
end

-- Ghost Part
local function CreateGhostPart()
    if GhostPart then GhostPart:Destroy() end
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end

    SavedCFrame = RootPart.CFrame

    GhostPart = Instance.new("Part")
    GhostPart.Size = Vector3.new(1, 1, 1)
    GhostPart.Anchored = true
    GhostPart.CanCollide = false
    GhostPart.Transparency = 1
    GhostPart.Position = RootPart.Position
    GhostPart.Parent = workspace
end

local function DestroyGhostPart()
    if GhostPart then
        GhostPart:Destroy()
        GhostPart = nil
    end
end

-- =================== UI FUNCTIONS ===================
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

-- Centralized selection: handles UI checkmark, internal table, and Red ESP
local function SetPlayerSelection(player, state)
    if not player then return end

    if state then
        SelectedTargets[player.Name] = player
    else
        SelectedTargets[player.Name] = nil
    end

    if PlayerCheckboxes[player.Name] then
        PlayerCheckboxes[player.Name].Checkmark.Visible = state
    end

    if player.Character then
        local hlName = "FlingTargetESP"
        local existingHl = player.Character:FindFirstChild(hlName)
        if state then
            if not existingHl then
                local hl = Instance.new("Highlight")
                hl.Name = hlName
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0.2
                hl.Parent = player.Character
            end
        else
            if existingHl then
                existingHl:Destroy()
            end
        end
    end

    UpdateStatus()
end

local function GetPlayerStatus(player)
    local char = player.Character
    if not char then return "dead" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return "dead" end
    if char:FindFirstChildOfClass("ForceField") then return "forcefield" end
    if hum.Sit then return "seated" end
    return "alive"
end

local function RefreshPlayerList()
    local searchText = SearchBox.Text:lower()

    for _, child in pairs(PlayerScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    PlayerCheckboxes = {}

    local PlayerList = Players:GetPlayers()
    table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)

    for _, player in ipairs(PlayerList) do
        if player ~= LocalPlayer then
            local matchesSearch = searchText == "" or player.Name:lower():find(searchText, 1, true) ~= nil

            local PlayerEntry = Make("Frame", {
                Size = ud2(1,-8,0,32), BackgroundColor3 = C.surfaceAlt,
                BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Visible = matchesSearch,
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
                Size = ud2(1,-80,1,0), Position = ud2(0,34,0,0),
                BackgroundTransparency = 1, Text = player.Name,
                TextColor3 = C.textPri, TextSize = 12, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = PlayerEntry,
            })

            -- Status indicator
            local status = GetPlayerStatus(player)
            local statusColor = status == "dead" and C.dot_red
                or status == "seated" and C.dot_yel
                or status == "forcefield" and C.dot_blue
                or C.dot_grn

            local StatusDot = Make("Frame", {
                Size = ud2(0,8,0,8), Position = ud2(1,-50,0,12),
                BackgroundColor3 = statusColor, BorderSizePixel = 0,
                Parent = PlayerEntry,
            })
            Make("UICorner", {CornerRadius = ud(1,0), Parent = StatusDot})

            -- Spectate button
            local SpectateBtn = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(1,-30,0,4),
                BackgroundTransparency = 1, Text = "👁",
                TextColor3 = C.textSec, TextSize = 12, Font = reg,
                Parent = PlayerEntry,
            })

            SpectateBtn.MouseButton1Click:Connect(function()
                if SpectatingTarget == player then
                    SpectatingTarget = nil
                    local lChar = LocalPlayer.Character
                    local lHum = lChar and lChar:FindFirstChildOfClass("Humanoid")
                    if lHum then workspace.CurrentCamera.CameraSubject = lHum end
                    SpectateBtn.TextColor3 = C.textSec
                else
                    SpectatingTarget = player
                    local tChar = player.Character
                    local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                    if tHum then workspace.CurrentCamera.CameraSubject = tHum end
                    SpectateBtn.TextColor3 = C.accent
                end
            end)

            -- Click area (exclude spectate button area)
            local ClickArea = Make("TextButton", {
                Size = ud2(1,-36,1,0), BackgroundTransparency = 1, Text = "",
                ZIndex = 2, Parent = PlayerEntry,
            })

            local lastClickTime = 0
            ClickArea.MouseButton1Click:Connect(function()
                local currentTime = tick()
                if currentTime - lastClickTime < 0.25 then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then
                            SetPlayerSelection(p, false)
                        end
                    end
                    SetPlayerSelection(player, true)
                    lastClickTime = 0
                else
                    local isCurrentlySelected = SelectedTargets[player.Name] ~= nil
                    SetPlayerSelection(player, not isCurrentlySelected)
                    lastClickTime = currentTime
                end
                UpdateStatus()
            end)

            PlayerCheckboxes[player.Name] = {
                Entry = PlayerEntry,
                Checkmark = Checkmark,
                StatusDot = StatusDot,
                SpectateBtn = SpectateBtn,
            }
        end
    end
    PlayerScrollFrame.CanvasSize = ud2(0, 0, 0, 0)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    RefreshPlayerList()
end)

local function ToggleAllPlayers(select)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            SetPlayerSelection(player, select)
        end
    end
end

-- Status refresh loop
task.spawn(function()
    while Gui and Gui.Parent do
        for name, data in pairs(PlayerCheckboxes) do
            local player = Players:FindFirstChild(name)
            if player and data.StatusDot then
                local status = GetPlayerStatus(player)
                data.StatusDot.BackgroundColor3 = status == "dead" and C.dot_red
                    or status == "seated" and C.dot_yel
                    or status == "forcefield" and C.dot_blue
                    or C.dot_grn
            end
        end
        task.wait(1)
    end
end)

-- =================== FLING LOGIC ===================
local function SkidFling(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not (Character and Humanoid and RootPart) then return end

    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
        SavedCFrame = RootPart.CFrame
    end

    EnableSecurity()

    if THumanoid and THumanoid.Sit then return end

    if cfgGhostFling then
        CreateGhostPart()
        workspace.CurrentCamera.CameraSubject = Humanoid
    else
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
    end

    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

    local powerMult = cfgFlingPower
    local isUp = (cfgDirection == "UP")
    local isDown = (cfgDirection == "DOWN")
    local isRandom = (cfgDirection == "RANDOM")

    local FPos = function(BasePart, Pos, Ang, velOverride)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        if velOverride then
            RootPart.Velocity = velOverride
        else
            RootPart.Velocity = Vector3.new(9e7 * powerMult, 9e7 * 10 * powerMult, 9e7 * powerMult)
        end
        RootPart.RotVelocity = Vector3.new(9e8 * powerMult, 9e8 * powerMult, 9e8 * powerMult)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0

        if isUp then
            -- UPPERCUT: sweep from deep torso (-0.5) through below feet (-2.5)
            -- Velocity biased entirely upward along Y-axis
            repeat
                if RootPart and THumanoid then
                    Angle = Angle + 100
                    local spinAng = CFrame.Angles(math.rad(Angle), 0, 0)
                    local upVel = Vector3.new(0, 9e8 * powerMult, 0)
                    FPos(BasePart, CFrame.new(0, -0.5, 0), spinAng, upVel)
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -2.5, 0), spinAng, upVel)
                    task.wait()
                end
            until Time + TimeToWait < tick() or not FlingActive

        elseif isDown then
            -- DOWNFORCE: sweep from deep torso (+0.5) through above head (+2.5)
            -- Velocity biased entirely downward along Y-axis
            repeat
                if RootPart and THumanoid then
                    Angle = Angle + 100
                    local spinAng = CFrame.Angles(math.rad(Angle), 0, 0)
                    local downVel = Vector3.new(0, -9e8 * powerMult, 0)
                    FPos(BasePart, CFrame.new(0, 0.5, 0), spinAng, downVel)
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 2.5, 0), spinAng, downVel)
                    task.wait()
                end
            until Time + TimeToWait < tick() or not FlingActive

        else
            -- RANDOM/OMNI: original chaotic sweeping through entire body
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        local rA = math.random(-30, 30)
                        local spinAng = CFrame.Angles(math.rad(Angle + rA), 0, 0)
                        local moveDir = THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + moveDir, spinAng)
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + moveDir, spinAng)
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + moveDir, spinAng)
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + moveDir, spinAng)
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, spinAng)
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, spinAng)
                        task.wait()
                    else
                        local rF = math.random(-2, 2)
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed + rF), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed + rF), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed + rF), CFrame.Angles(math.rad(90), 0, 0))
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

    if cfgGhostFling then
        DestroyGhostPart()
    end

    workspace.CurrentCamera.CameraSubject = Humanoid
    DisableSecurity()

    -- Safe Return: instant blink back
    if cfgSafeReturn and SavedCFrame then
        RootPart.CFrame = SavedCFrame
        Character:SetPrimaryPartCFrame(SavedCFrame)
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.new()
                part.RotVelocity = Vector3.new()
            end
        end
        Humanoid:ChangeState("GettingUp")
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
        return
    end

    if getgenv().OldPos then
        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new()
                    part.RotVelocity = Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
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
                    if checkbox then checkbox.Checkmark.Visible = false end
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
                if checkbox then checkbox.Checkmark.Visible = false end
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

-- =================== CONNECTIONS ===================
SelectAllBtn.MouseButton1Click:Connect(function() ToggleAllPlayers(true) end)
DeselectAllBtn.MouseButton1Click:Connect(function() ToggleAllPlayers(false) end)

SelectNearestBtn.MouseButton1Click:Connect(function()
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    local nearestPlayer = nil
    local shortestDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
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
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                SetPlayerSelection(p, false)
            end
        end
        SetPlayerSelection(nearestPlayer, true)
    end
end)

FlingBtn.MouseButton1Click:Connect(function()
    if FlingMode == "loop" then StopFling() else StartFlingLoop() end
end)

FlingOnceBtn.MouseButton1Click:Connect(function()
    if FlingMode == "once" then StopFling() else StartFlingOnce() end
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

GhostHitbox.MouseButton1Click:Connect(function()
    cfgGhostFling = not cfgGhostFling
    TweenService:Create(GhostKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = cfgGhostFling and ud2(0,20,0,2) or ud2(0,2,0,2)
    }):Play()
    TweenService:Create(GhostToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundColor3 = cfgGhostFling and C.toggle_on or C.toggle_off
    }):Play()
    triggerAutoSave()
end)

SafeRetHitbox.MouseButton1Click:Connect(function()
    cfgSafeReturn = not cfgSafeReturn
    TweenService:Create(SafeRetKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = cfgSafeReturn and ud2(0,20,0,2) or ud2(0,2,0,2)
    }):Play()
    TweenService:Create(SafeRetToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundColor3 = cfgSafeReturn and C.toggle_on or C.toggle_off
    }):Play()
    triggerAutoSave()
end)

-- Slider inputs
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
        if powerDragging then
            powerDragging = false
            triggerAutoSave()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
    if powerDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updatePowerSlider(input.Position.X)
    end
end)

-- Page switching
SettingsBtn.MouseButton1Click:Connect(function()
    switchPage(activePage == "settings" and "main" or "settings")
end)

ModsBtn.MouseButton1Click:Connect(function()
    switchPage(activePage == "modifiers" and "main" or "modifiers")
end)

-- Window controls
local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local pillUsed = false
local lastMainPos = Main.Position
local isExpanded = false
local isAnimating = false

CloseBtn.MouseButton1Click:Connect(function()
    StopFling()
    DestroyGhostPart()
    DisableSecurity()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("FlingTargetESP")
            if hl then hl:Destroy() end
        end
    end
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

-- 3D Click-to-Target & Double Tap
local targetKeyConn
targetKeyConn = UserInputService.InputBegan:Connect(function(input, processed)
    if not Gui or not Gui.Parent then
        targetKeyConn:Disconnect()
        return
    end
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local targetKC = keycodeFromName(cfgTargetKeybindName)
    if targetKC == Enum.KeyCode.Unknown then return end
    if input.KeyCode ~= targetKC then return end

    local mouse = LocalPlayer:GetMouse()
    local targetPart = mouse.Target
    if not targetPart then return end

    local character = targetPart:FindFirstAncestorOfClass("Model")
    local targetPlayer = Players:GetPlayerFromCharacter(character)
    if not targetPlayer or targetPlayer == LocalPlayer then return end

    local currentTime = tick()

    if currentTime - lastMPress < 0.3 and lastTargetedPlayer == targetPlayer then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                SetPlayerSelection(p, false)
            end
        end
        SetPlayerSelection(targetPlayer, true)
        lastMPress = 0
    else
        local isCurrentlySelected = SelectedTargets[targetPlayer.Name] ~= nil
        SetPlayerSelection(targetPlayer, not isCurrentlySelected)
        lastMPress = currentTime
        lastTargetedPlayer = targetPlayer
    end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    if autoSelectEnabled then
        task.wait(0.5)
        SetPlayerSelection(player, true)
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

    -- Target keybind listening
    if isListeningForTargetKey and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            cfgTargetKeybindName = input.KeyCode.Name
            isListeningForTargetKey = false
            TargetKeyBtn.TextColor3 = C.textPri
            TargetKeyBtn.Text = "[ " .. cfgTargetKeybindName .. " ]"
            triggerAutoSave()
        end
        return
    end

    -- Combo keybind listening (Key 1 → Key 2 sequential)
    if isListeningForCombo1 and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            cfgComboKey1Name = input.KeyCode.Name
            comboKey1 = input.KeyCode
            isListeningForCombo1 = false
            isListeningForCombo2 = true
            ComboKeyBtn.Text = "[ " .. cfgComboKey1Name .. " → ? ]"
            ComboKeyBtn.TextColor3 = C.dot_yel
        end
        return
    end

    -- Combo keybind listening (Key 2)
    if isListeningForCombo2 and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            cfgComboKey2Name = input.KeyCode.Name
            comboKey2 = input.KeyCode
            isListeningForCombo2 = false
            ComboKeyBtn.TextColor3 = C.textPri
            ComboKeyBtn.Text = "[ " .. cfgComboKey1Name .. " + " .. cfgComboKey2Name .. " ]"
            triggerAutoSave()
        end
        return
    end

    -- UI toggle keybind listening
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

    if not processed and not isListeningForKeybind and not isListeningForTargetKey
        and not isListeningForCombo1 and not isListeningForCombo2
        and input.UserInputType == Enum.UserInputType.Keyboard then

        -- Combo keybind: sequential press (Key1 then Key2, no time limit)
        if input.KeyCode == comboKey1 then
            lastComboKey1Press = tick()
        end

        if input.KeyCode == comboKey2 and comboKey1 ~= Enum.KeyCode.Unknown and comboKey2 ~= Enum.KeyCode.Unknown then
            if lastComboKey1Press > 0 then
                lastComboKey1Press = 0
                if not FlingActive then
                    StartFlingOnce()
                end
            end
        end

        -- UI toggle keybind: simultaneous hold
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

-- =================== INITIALIZE ===================
registerTransparencyFrame(Main, 0)
registerTransparencyFrame(PillUI, 0)
applyTransparency(cfgTransparency)
applyTheme()
RefreshPlayerList()
UpdateStatus()

-- =================== EXTERNAL API ===================
-- So the main UN script can control transparency and other settings
getgenv().FlingScript = {
    SetTransparency = function(t)
        applyTransparency(t)
        triggerAutoSave()
    end,
    GetTransparency = function()
        return uiTransparency
    end,
    SetFlingPower = function(p)
        cfgFlingPower = math.clamp(p, 1, 10)
        triggerAutoSave()
    end,
    SetGhostFling = function(enabled)
        cfgGhostFling = enabled
        triggerAutoSave()
    end,
    SetSafeReturn = function(enabled)
        cfgSafeReturn = enabled
        triggerAutoSave()
    end,
    SetDirection = function(dir)
        if dir == "UP" or dir == "DOWN" or dir == "RANDOM" then
            cfgDirection = dir
            triggerAutoSave()
        end
    end,
    SetComboKeys = function(key1, key2)
        local ok1, kc1 = pcall(function() return Enum.KeyCode[key1] end)
        local ok2, kc2 = pcall(function() return Enum.KeyCode[key2] end)
        if ok1 and kc1 and ok2 and kc2 then
            cfgComboKey1Name = key1
            cfgComboKey2Name = key2
            comboKey1 = kc1
            comboKey2 = kc2
            triggerAutoSave()
        end
    end,
    ToggleUI = function()
        if Main.Visible then
            shrinkToPill()
        elseif PillUI.Visible then
            expandFromPill()
        end
    end,
}
