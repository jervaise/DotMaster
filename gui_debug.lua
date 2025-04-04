-- DotMaster gui_debug.lua
-- Debug output window and debug system centralization

local DM = DotMaster
DM.GUI = DM.GUI or {}
DM.Debug = DM.Debug or {}

-- Debug configuration
local MAX_DEBUG_LINES = 500
local debugMessages = {}
local debugCategories = {
  general = true,     -- General debug messages
  spell = true,       -- Spell-related debug
  nameplate = true,   -- Nameplate-related debug
  gui = true,         -- GUI-related debug
  performance = true, -- Performance-related debug
  database = true,    -- Database-related debug
}

-- Local implementation of DeepCopy to avoid dependency on utils.lua loading order
local function DeepCopy(original)
  local copy
  if type(original) == "table" then
    copy = {}
    for k, v in pairs(original) do
      if type(v) == "table" then
        copy[k] = DeepCopy(v)
      else
        copy[k] = v
      end
    end
  else
    copy = original
  end
  return copy
end

-- Initialize debug system
function DM.Debug:Init()
  -- Set default debug state from saved variables
  DM.DEBUG_CATEGORIES = (DotMasterDB and DotMasterDB.debugCategories) or DeepCopy(debugCategories)

  -- Migrate old debug messages if present
  if DM.oldDebugMessages and #DM.oldDebugMessages > 0 then
    DM:DebugMsg("Debug system initialized - importing " .. #DM.oldDebugMessages .. " early initialization messages")

    -- Clear existing messages to avoid duplication
    wipe(debugMessages)

    -- Import the early initialization messages
    for _, msg in ipairs(DM.oldDebugMessages) do
      table.insert(debugMessages, msg)
    end

    -- Clear the old messages to prevent duplication
    DM.oldDebugMessages = {}
  end

  -- Hook original debug functions
  self:HookDebugFunctions()

  -- Force a display update if the console window exists
  C_Timer.After(0.5, function()
    if DM.GUI.debugFrame and DM.GUI.debugEditBox then
      self:UpdateDisplay()
    end
  end)
end

-- Hook and replace original debug functions
function DM.Debug:HookDebugFunctions()
  -- Store original functions if needed for backward compatibility
  DM._originalDebugMsg = DM.DebugMsg
  DM._originalSpellDebug = DM.SpellDebug

  -- Replace with new centralized functions
  DM.DebugMsg = function(self, message, ...)
    DM.Debug:Log("general", message, ...)
  end

  DM.SpellDebug = function(self, message, ...)
    DM.Debug:Log("spell", message, ...)
  end

  -- Add new category-specific debug functions
  DM.NameplateDebug = function(self, message, ...)
    DM.Debug:Log("nameplate", message, ...)
  end

  DM.GUIDebug = function(self, message, ...)
    DM.Debug:Log("gui", message, ...)
  end

  DM.PerformanceDebug = function(self, message, ...)
    DM.Debug:Log("performance", message, ...)
  end

  DM.DatabaseDebug = function(self, message, ...)
    DM.Debug:Log("database", message, ...)
  end

  -- Add missing ColorPickerDebug function
  DM.ColorPickerDebug = function(self, message, ...)
    DM.Debug:Log("colorpicker", message, ...)
  end
end

-- Centralized log function
function DM.Debug:Log(category, message, ...)
  -- Skip if category is disabled (removed general category check)
  if DM.DEBUG_CATEGORIES and not DM.DEBUG_CATEGORIES[category] then
    return
  end

  -- Format the message with any arguments
  local formattedMessage
  if select('#', ...) > 0 then
    formattedMessage = string.format(message, ...)
  else
    formattedMessage = message
  end

  -- Add category prefix based on type
  local categoryColors = {
    general = "CC00FF",     -- Purple
    spell = "FF00FF",       -- Pink
    nameplate = "00CCFF",   -- Blue
    gui = "FFCC00",         -- Gold
    performance = "00FF00", -- Green
    database = "FFA500",    -- Orange
  }

  local colorCode = categoryColors[category] or "FFFFFF"
  local prefix = string.format("|cFF%s[%s]|r ", colorCode, category:upper())

  -- Add timestamp
  local timestamp = date("|cFF888888[%H:%M:%S]|r ", GetServerTime())
  local fullMessage = timestamp .. prefix .. formattedMessage

  -- Add to debug messages array
  table.insert(debugMessages, fullMessage)

  -- Limit the number of lines stored
  if #debugMessages > MAX_DEBUG_LINES then
    table.remove(debugMessages, 1)
  end

  -- Update EditBox content if window exists and is shown
  if DM.GUI.debugFrame and DM.GUI.debugFrame:IsShown() and DM.GUI.debugEditBox then
    self:UpdateDisplay()
  end

  -- Also output to console if console output is enabled
  if DM.DEBUG_CONSOLE_OUTPUT == true then
    -- Use a simpler format for console
    print(prefix .. formattedMessage)
  end
end

-- Update the debug window display
function DM.Debug:UpdateDisplay()
  if not DM.GUI.debugEditBox then return end

  local filteredMessages = {}

  -- If we have no debug messages, just return
  if #debugMessages == 0 then
    DM.GUI.debugEditBox:SetText("")
    return
  end

  -- Process messages and apply category filters
  for _, msg in ipairs(debugMessages) do
    -- Check if this message belongs to a filtered category
    local shouldDisplay = true

    -- Look for category tags like [GENERAL], [SPELL], etc.
    for category, enabled in pairs(DM.DEBUG_CATEGORIES or {}) do
      local pattern = "%[" .. category:upper() .. "%]"
      if msg:match(pattern) and not enabled then
        shouldDisplay = false
        break
      end
    end

    if shouldDisplay then
      table.insert(filteredMessages, msg)
    end
  end

  -- Update EditBox content
  local content = table.concat(filteredMessages, "\n")

  -- Check if content is different to avoid unnecessary updates
  if DM.GUI.debugEditBox:GetText() ~= content then
    DM.GUI.debugEditBox:SetText(content)
  end
end

-- Function to create the Debug Window
function DM.Debug:CreateDebugWindow()
  if DM.GUI.debugFrame then
    return -- Already created
  end

  -- Create main frame
  local frame = CreateFrame("Frame", "DotMasterDebugFrame", UIParent)
  DM.GUI.debugFrame = frame -- Store reference

  frame:SetSize(700, 500)
  frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
  frame:SetFrameStrata("MEDIUM")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide() -- Hidden by default

  -- Apply backdrop - properly check for the API version
  if BackdropTemplateMixin then
    Mixin(frame, BackdropTemplateMixin)
    frame:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
  else
    -- Fallback for older versions - create background texture
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

    -- Create border using textures instead of backdrop
    local borderSize = 16

    -- Top border
    local topBorder = frame:CreateTexture(nil, "OVERLAY")
    topBorder:SetTexture("Interface/Tooltips/UI-Tooltip-Border")
    topBorder:SetTexCoord(0.5, 1, 0, 0.5)
    topBorder:SetHeight(borderSize)
    topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, borderSize)
    topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, borderSize)

    -- Bottom border
    local bottomBorder = frame:CreateTexture(nil, "OVERLAY")
    bottomBorder:SetTexture("Interface/Tooltips/UI-Tooltip-Border")
    bottomBorder:SetTexCoord(0.5, 1, 0.5, 1)
    bottomBorder:SetHeight(borderSize)
    bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, -borderSize)
    bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -borderSize)

    -- Left border
    local leftBorder = frame:CreateTexture(nil, "OVERLAY")
    leftBorder:SetTexture("Interface/Tooltips/UI-Tooltip-Border")
    leftBorder:SetTexCoord(0, 0.5, 0.5, 1)
    leftBorder:SetWidth(borderSize)
    leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderSize, 0)
    leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -borderSize, 0)

    -- Right border
    local rightBorder = frame:CreateTexture(nil, "OVERLAY")
    rightBorder:SetTexture("Interface/Tooltips/UI-Tooltip-Border")
    rightBorder:SetTexCoord(0.5, 1, 0.5, 1)
    rightBorder:SetWidth(borderSize)
    rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", borderSize, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderSize, 0)
  end

  -- Title
  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -10)
  title:SetText("|cFF999999DotMaster Debug Console|r")

  -- Close Button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -3, -3)
  closeButton:SetScript("OnClick", function() frame:Hide() end)

  -- Category Filters
  local filterTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  filterTitle:SetPoint("TOPLEFT", 16, -35)
  filterTitle:SetText("Filters:")

  local xOffset = 80
  for category, _ in pairs(debugCategories) do
    local checkbox = CreateFrame("CheckButton", "DotMasterDebugFilter_" .. category, frame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", xOffset, -35)
    checkbox:SetSize(22, 22)

    local text = _G[checkbox:GetName() .. "Text"]
    text:SetText(category:gsub("^%l", string.upper))
    text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)

    -- Set initial state from saved value
    checkbox:SetChecked(DM.DEBUG_CATEGORIES[category])

    -- Add click handler
    checkbox:SetScript("OnClick", function(self)
      DM.DEBUG_CATEGORIES[category] = self:GetChecked()
      -- Update display with new filter
      DM.Debug:UpdateDisplay()
      -- Save settings
      if DotMasterDB then
        DotMasterDB.debugCategories = DM.DEBUG_CATEGORIES
      end
    end)

    -- Increment offset for next checkbox
    xOffset = xOffset + 100
  end

  -- Scroll Frame for the EditBox
  local scrollFrame = CreateFrame("ScrollFrame", "DotMasterDebugScrollFrame", frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 16, -60) -- Adjusted position since we removed the console checkbox
  scrollFrame:SetPoint("BOTTOMRIGHT", -36, 40)

  -- EditBox within the ScrollFrame
  local editBox = CreateFrame("EditBox", "DotMasterDebugEditBox", scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetMaxLetters(0)
  editBox:EnableMouse(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetWidth(scrollFrame:GetWidth())
  editBox:SetHeight(scrollFrame:GetHeight())
  editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
  editBox:SetScript("OnTextSet", function(self)
    self:HighlightText(0, 0)
    scrollFrame:UpdateScrollChildRect()

    -- Standard method for scrolling to bottom
    if scrollFrame.ScrollToBottom then
      C_Timer.After(0.05, function() scrollFrame:ScrollToBottom() end)
    elseif scrollFrame.SetVerticalScroll then
      C_Timer.After(0.05, function()
        scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
      end)
    end
  end)

  scrollFrame:SetScrollChild(editBox)
  DM.GUI.debugEditBox = editBox

  -- Button Container
  local buttonContainer = CreateFrame("Frame", nil, frame)
  buttonContainer:SetPoint("BOTTOMLEFT", 16, 10)
  buttonContainer:SetPoint("BOTTOMRIGHT", -36, 10)
  buttonContainer:SetHeight(22)

  -- Clear Button
  local clearButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  clearButton:SetSize(80, 22)
  clearButton:SetPoint("RIGHT", -90, 0)
  clearButton:SetText("Clear Log")
  clearButton:SetScript("OnClick", function()
    debugMessages = {}
    editBox:SetText("")
  end)

  -- Copy Button
  local copyButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  copyButton:SetSize(80, 22)
  copyButton:SetPoint("RIGHT", clearButton, "LEFT", -10, 0)
  copyButton:SetText("Copy All")
  copyButton:SetScript("OnClick", function()
    -- Improved copy mechanism
    editBox:SetFocus()
    editBox:HighlightText()
    -- Use delayed execution to ensure text is selected
    C_Timer.After(0.1, function()
      editBox:HighlightText()
    end)
  end)

  -- Export Button
  local exportButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  exportButton:SetSize(80, 22)
  exportButton:SetPoint("RIGHT", copyButton, "LEFT", -10, 0)
  exportButton:SetText("Export")
  exportButton:SetScript("OnClick", function()
    -- Create a temporary global variable with debug log
    _G["DOTMASTER_DEBUG_EXPORT"] = table.concat(debugMessages, "\n")
    DM:PrintMessage(
      "Debug log exported to global variable DOTMASTER_DEBUG_EXPORT. Use /dump DOTMASTER_DEBUG_EXPORT to view.")
  end)

  -- Initialization Messages Button
  local initButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  initButton:SetSize(120, 22)
  initButton:SetPoint("LEFT", 0, 0)
  initButton:SetText("Init Messages")
  initButton:SetScript("OnClick", function()
    -- Collect all initialization-related messages
    local initMsgs = {}
    for _, msg in ipairs(debugMessages) do
      if msg:match("triggered")
          or msg:match("initialized")
          or msg:match("initialization")
          or msg:match("init ")
          or msg:match("loaded")
          or msg:match("created")
          or msg:match("ADDON_LOADED")
          or msg:match("PLAYER_") then
        table.insert(initMsgs, msg)
      end
    end

    -- Display the filtered messages
    local content = table.concat(initMsgs, "\n")
    editBox:SetText(content)
    editBox:SetFocus()

    -- Add a note at the top
    editBox:Insert("===== INITIALIZATION MESSAGES =====\n\n" .. content)
  end)

  DM:PrintMessage("Debug console created")

  -- Ensure messages are displayed immediately
  C_Timer.After(0.1, function()
    self:UpdateDisplay()
  end)

  return frame
end

-- Toggle debug window visibility
function DM.Debug:ToggleWindow()
  if not DM.GUI.debugFrame then
    self:CreateDebugWindow()
  end

  if DM.GUI.debugFrame:IsShown() then
    DM.GUI.debugFrame:Hide()
  else
    DM.GUI.debugFrame:Show()
    -- Update display when showing
    C_Timer.After(0.1, function()
      self:UpdateDisplay()
    end)
  end
end

-- Save debug settings
function DM.Debug:SaveSettings()
  if DotMasterDB then
    DotMasterDB.debugCategories = DM.DEBUG_CATEGORIES
    DotMasterDB.debugConsoleOutput = DM.DEBUG_CONSOLE_OUTPUT
  end
end

-- Show debug system help
function DM.Debug:ShowHelp()
  DM:PrintMessage("DotMaster Debug System:")
  DM:PrintMessage("  - Type |cFFFFD100/dmdebug|r to toggle the debug console")
  DM:PrintMessage("  - Type |cFFFFD100/dmdebug on|r or |cFFFFD100/dmdebug off|r to enable/disable debug mode")
  DM:PrintMessage("  - Type |cFFFFD100/dmdebug status|r to check debug status")
  DM:PrintMessage("  - Type |cFFFFD100/dmdebug category <name> [on|off]|r to control debug categories")
  DM:PrintMessage("Available categories:")

  for category, enabled in pairs(DM.DEBUG_CATEGORIES or {}) do
    local status = enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
    DM:PrintMessage("  - " .. category .. ": " .. status)
  end
end

-- Initialize the debug system when this file loads
DM.Debug:Init()
