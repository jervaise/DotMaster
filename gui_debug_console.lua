-- gui_debug_console.lua
-- DotMaster Debug Console UI

local DM = DotMaster   -- reference to main addon
local Debug = DM.Debug -- reference to debug module

-- Local constants
local CONSOLE_WIDTH = 800
local CONSOLE_HEIGHT = 500
local LINE_HEIGHT = 14
local MAX_VISIBLE_LINES = math.floor((CONSOLE_HEIGHT - 100) / LINE_HEIGHT)
local SCROLL_STEP = 3

-- Local variables
local messageLines = {}
local scrollOffset = 0
local filterText = ""

-- Debug Console Frame
local DebugConsole = {}
DM.debugFrame = DebugConsole -- Expose to addon

-- Create main debug console frame
function DebugConsole:Create()
  if self.frame then
    return self.frame
  end

  -- Main frame
  local frame = CreateFrame("Frame", "DotMasterDebugConsole", UIParent, "BackdropTemplate")
  self.frame = frame
  frame:SetSize(CONSOLE_WIDTH, CONSOLE_HEIGHT)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(100)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Set backdrop
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })

  -- Title Bar
  local titleBar = frame:CreateTexture(nil, "ARTWORK")
  titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  titleBar:SetWidth(CONSOLE_WIDTH - 40)
  titleBar:SetHeight(40)
  titleBar:SetPoint("TOP", 0, 12)

  local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  titleText:SetPoint("TOP", titleBar, "TOP", 0, -14)
  titleText:SetText("DotMaster Debug Console")

  -- Close button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
  closeButton:SetScript("OnClick", function() self:Toggle() end)

  -- Create content area
  local contentFrame = CreateFrame("Frame", nil, frame)
  contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -30)
  contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 50)
  self.contentFrame = contentFrame

  -- Create scrollable message area
  local messageFrame = CreateFrame("Frame", nil, contentFrame)
  messageFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -10)
  messageFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -25, 30)
  messageFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  messageFrame:SetBackdropColor(0, 0, 0, 0.9)
  self.messageFrame = messageFrame

  -- Create message lines
  self.lines = {}
  for i = 1, MAX_VISIBLE_LINES do
    local line = messageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    line:SetPoint("TOPLEFT", messageFrame, "TOPLEFT", 8, -6 - ((i - 1) * LINE_HEIGHT))
    line:SetPoint("RIGHT", messageFrame, "RIGHT", -8, 0)
    line:SetJustifyH("LEFT")
    line:SetTextColor(1, 1, 1, 1)
    line:SetText("")
    self.lines[i] = line
  end

  -- Scrollbar
  local scrollbar = CreateFrame("Slider", nil, messageFrame, "UIPanelScrollBarTemplate")
  scrollbar:SetPoint("TOPRIGHT", messageFrame, "TOPRIGHT", -2, -16)
  scrollbar:SetPoint("BOTTOMRIGHT", messageFrame, "BOTTOMRIGHT", -2, 16)
  scrollbar:SetMinMaxValues(0, 1)
  scrollbar:SetValueStep(1)
  scrollbar:SetValue(0)
  scrollbar:SetWidth(16)
  scrollbar:SetScript("OnValueChanged", function(self, value)
    scrollOffset = math.floor(value)
    DebugConsole:UpdateDisplay()
  end)
  self.scrollbar = scrollbar

  -- Button bar at the bottom
  local buttonBar = CreateFrame("Frame", nil, frame)
  buttonBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
  buttonBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
  buttonBar:SetHeight(30)

  -- Clear button
  local clearButton = CreateFrame("Button", nil, buttonBar, "UIPanelButtonTemplate")
  clearButton:SetPoint("LEFT", buttonBar, "LEFT", 0, 0)
  clearButton:SetSize(80, 22)
  clearButton:SetText("Clear")
  clearButton:SetScript("OnClick", function() self:Clear() end)

  -- Copy button
  local copyButton = CreateFrame("Button", nil, buttonBar, "UIPanelButtonTemplate")
  copyButton:SetPoint("LEFT", clearButton, "RIGHT", 10, 0)
  copyButton:SetSize(80, 22)
  copyButton:SetText("Copy")
  copyButton:SetScript("OnClick", function() self:CopyToClipboard() end)

  -- Filter input
  local filterLabel = buttonBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  filterLabel:SetPoint("LEFT", copyButton, "RIGHT", 20, 0)
  filterLabel:SetText("Filter:")

  local filterBox = CreateFrame("EditBox", nil, buttonBar, "InputBoxTemplate")
  filterBox:SetPoint("LEFT", filterLabel, "RIGHT", 10, 0)
  filterBox:SetSize(150, 20)
  filterBox:SetAutoFocus(false)
  filterBox:SetText("")
  filterBox:SetScript("OnTextChanged", function(self)
    local settings = Debug.GetSettings()
    settings.filterString = self:GetText()
    Debug.SaveSettings(settings)
    DebugConsole:UpdateDisplay()
  end)
  filterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  filterBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  self.filterBox = filterBox

  -- Category management
  local categoryFrame = CreateFrame("Frame", nil, frame)
  categoryFrame:SetPoint("TOPLEFT", messageFrame, "BOTTOMLEFT", 0, -5)
  categoryFrame:SetPoint("BOTTOMRIGHT", buttonBar, "TOPRIGHT", 0, 5)
  categoryFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  categoryFrame:SetBackdropColor(0, 0, 0, 0.5)

  -- Create category checkboxes
  self.categoryCheckboxes = {}
  local prevCheckbox = nil
  local xOffset = 10

  for category, _ in pairs(Debug.CATEGORY) do
    local checkbox = CreateFrame("CheckButton", nil, categoryFrame, "UICheckButtonTemplate")
    local checkboxHeight = checkbox:GetHeight()
    local labelText = _G[checkbox:GetName() .. "Text"]

    if not prevCheckbox then
      checkbox:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", xOffset, -8)
    else
      if xOffset + checkbox:GetWidth() + 10 > categoryFrame:GetWidth() then
        xOffset = 10
        checkbox:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", xOffset, -8 - (checkboxHeight * 1.5))
      else
        checkbox:SetPoint("LEFT", prevCheckbox, "RIGHT", 80, 0)
      end
    end

    labelText:SetText(category)
    checkbox.category = category
    checkbox:SetChecked(Debug.GetSettings().categories[category])
    checkbox:SetScript("OnClick", function(self)
      Debug:SetCategoryEnabled(self.category, self:GetChecked())
      DebugConsole:UpdateDisplay()
    end)

    self.categoryCheckboxes[category] = checkbox
    prevCheckbox = checkbox
    xOffset = xOffset + checkbox:GetWidth() + labelText:GetStringWidth() + 10
  end

  -- Register for events
  frame:SetScript("OnMouseWheel", function(_, delta)
    local newValue = scrollbar:GetValue() - (delta * SCROLL_STEP)
    newValue = math.max(0, math.min(scrollbar:GetMaxValue(), newValue))
    scrollbar:SetValue(newValue)
  end)

  -- Hide initially
  frame:Hide()

  return frame
end

-- Update the display with current message list
function DebugConsole:UpdateDisplay()
  if not self.frame or not self.frame:IsShown() then
    return
  end

  -- Update filter if needed
  local settings = Debug.GetSettings()
  if self.filterBox:GetText() ~= settings.filterString then
    self.filterBox:SetText(settings.filterString)
  end

  -- Update category checkboxes
  for category, checkbox in pairs(self.categoryCheckboxes) do
    checkbox:SetChecked(settings.categories[category])
  end

  -- Get filtered messages
  local filteredMessages = {}
  for _, message in ipairs(messageLines) do
    if Debug:IsCategoryEnabled(message.category) then
      if settings.filterString == "" or string.find(message.text:lower(), settings.filterString:lower()) then
        table.insert(filteredMessages, message)
      end
    end
  end

  -- Update scrollbar range
  local numMessages = #filteredMessages
  local maxScroll = math.max(0, numMessages - MAX_VISIBLE_LINES)
  self.scrollbar:SetMinMaxValues(0, maxScroll)

  -- Auto-scroll to bottom if enabled
  if settings.autoScrollToBottom and scrollOffset == self.scrollbar:GetValue() then
    self.scrollbar:SetValue(maxScroll)
    scrollOffset = maxScroll
  end

  -- Display messages
  for i = 1, MAX_VISIBLE_LINES do
    local lineIndex = i + scrollOffset
    local line = self.lines[i]

    if lineIndex <= numMessages then
      local message = filteredMessages[lineIndex]
      local messageText = ""

      -- Add timestamp if enabled
      if settings.showTimestamps then
        local timestamp = message.timestamp or "00:00:00"
        messageText = "|cFF888888[" .. timestamp .. "]|r "
      end

      -- Add category
      local catColor = Debug.COLORS[message.category] or Debug.COLORS[Debug.CATEGORY.GENERAL]
      local colorStr = string.format("|cFF%02x%02x%02x",
        math.floor(catColor.r * 255),
        math.floor(catColor.g * 255),
        math.floor(catColor.b * 255))

      messageText = messageText .. colorStr .. "[" .. message.category .. "]|r "

      -- Add message text
      messageText = messageText .. message.text

      line:SetText(messageText)
    else
      line:SetText("")
    end
  end
end

-- Add a message to the console
function DebugConsole:AddMessage(message)
  if not message then return end

  table.insert(messageLines, message)

  -- Limit number of stored messages
  local settings = Debug.GetSettings()
  while #messageLines > settings.maxEntries do
    table.remove(messageLines, 1)
  end

  self:UpdateDisplay()
end

-- Clear all messages
function DebugConsole:Clear()
  messageLines = {}
  scrollOffset = 0
  self.scrollbar:SetValue(0)
  self:UpdateDisplay()
end

-- Copy console contents to clipboard
function DebugConsole:CopyToClipboard()
  local settings = Debug.GetSettings()
  local output = "DotMaster Debug Log:\n"

  for _, message in ipairs(messageLines) do
    if Debug:IsCategoryEnabled(message.category) then
      if settings.filterString == "" or string.find(message.text:lower(), settings.filterString:lower()) then
        local line = ""
        if settings.showTimestamps then
          line = line .. "[" .. (message.timestamp or "00:00:00") .. "] "
        end
        line = line .. "[" .. message.category .. "] " .. message.text
        output = output .. line .. "\n"
      end
    end
  end

  -- Create temporary frame for copying
  local copyFrame = AceGUI and AceGUI:Create("Frame") or
      CreateFrame("Frame", "DotMasterCopyFrame", UIParent, "BackdropTemplate")
  copyFrame:SetTitle("Debug Console - Copy")

  if copyFrame.SetLayout then -- AceGUI
    copyFrame:SetLayout("Fill")
    copyFrame:SetWidth(600)
    copyFrame:SetHeight(400)

    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetFullWidth(true)
    editbox:SetFullHeight(true)
    editbox:SetText(output)
    editbox:DisableButton(true)
    editbox:SetFocus()
    editbox:HighlightText()

    copyFrame:AddChild(editbox)
  else -- Fallback
    copyFrame:SetSize(600, 400)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    copyFrame:SetFrameStrata("DIALOG")

    local titleText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -15)
    titleText:SetText("Debug Console - Copy")

    local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetText(output)
    editBox:HighlightText()

    scrollFrame:SetScrollChild(editBox)

    local closeButton = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", 0, 15)
    closeButton:SetSize(100, 25)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() copyFrame:Hide() end)
  end

  copyFrame:Show()
end

-- Toggle visibility
function DebugConsole:Toggle()
  if not self.frame then
    self:Create()
  end

  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
    self:UpdateDisplay()
  end
end

-- Initialize the debug console
function DebugConsole:Initialize()
  self:Create()
  return self
end

return DebugConsole
