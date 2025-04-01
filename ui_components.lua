--[[
  DotMaster - UI Components Module

  File: ui_components.lua
  Purpose: Common UI components and helper functions

  Functions:
    CreateLabel(): Creates a text label
    CreateEditBox(): Creates an edit box
    CreateButton(): Creates a button
    CreateCheckbox(): Creates a checkbox
    CreateSlider(): Creates a slider
    SetTooltip(): Sets tooltip for a frame
    CreateHeader(): Creates a section header

  Dependencies:
    DotMaster core

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create UI components module
local UIComponents = {}
DM.UIComponents = UIComponents

-- Constants for styling
local COLORS = {
  HEADER = { r = 1, g = 0.82, b = 0 },    -- Gold
  TEXT = { r = 0.9, g = 0.9, b = 0.9 },   -- Off-white
  LABEL = { r = 0.9, g = 0.9, b = 0.9 },  -- Off-white
  ACCENT = { r = 0.6, g = 0.2, b = 1.0 }, -- Purple
  DARK_BG = { r = 0.1, g = 0.1, b = 0.1 } -- Dark
}

-- Create a text label
function UIComponents:CreateLabel(parent, text, fontObject, width, justifyH)
  local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
  label:SetText(text)

  if width then
    label:SetWidth(width)
  end

  if justifyH then
    label:SetJustifyH(justifyH)
  end

  return label
end

-- Create an edit box
function UIComponents:CreateEditBox(parent, width, height, maxLetters)
  local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  editBox:SetSize(width or 150, height or 20)
  editBox:SetAutoFocus(false)

  if maxLetters then
    editBox:SetMaxLetters(maxLetters)
  end

  -- Auto-select all text when focused
  editBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
  end)

  -- Lose focus on enter or escape
  editBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)

  return editBox
end

-- Create a button
function UIComponents:CreateButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width or 120, height or 22)
  button:SetText(text)

  return button
end

-- Create a checkbox
function UIComponents:CreateCheckbox(parent, text, checked, width, height)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkbox:SetSize(width or 24, height or 24)

  if text then
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    checkbox.text:SetText(text)
  end

  if checked ~= nil then
    checkbox:SetChecked(checked)
  end

  return checkbox
end

-- Create a slider
function UIComponents:CreateSlider(parent, min, max, width, step, value)
  local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  slider:SetWidth(width or 200)
  slider:SetMinMaxValues(min or 0, max or 100)
  slider:SetValueStep(step or 1)
  slider:SetObeyStepOnDrag(true)

  if value ~= nil then
    slider:SetValue(value)
  end

  -- Set labels if provided
  if min ~= nil then
    _G[slider:GetName() .. "Low"]:SetText(min)
  end

  if max ~= nil then
    _G[slider:GetName() .. "High"]:SetText(max)
  end

  return slider
end

-- Set tooltip for a frame
function UIComponents:SetTooltip(frame, title, text)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if title then
      GameTooltip:SetText(title, COLORS.HEADER.r, COLORS.HEADER.g, COLORS.HEADER.b)
    end

    if text then
      GameTooltip:AddLine(text, COLORS.TEXT.r, COLORS.TEXT.g, COLORS.TEXT.b, true)
    end

    GameTooltip:Show()
  end)

  frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
end

-- Create a header with optional line underneath
function UIComponents:CreateHeader(parent, text, width, underline)
  local header = self:CreateLabel(parent, text, "GameFontNormalLarge", width)
  header:SetTextColor(COLORS.HEADER.r, COLORS.HEADER.g, COLORS.HEADER.b)

  if underline then
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetWidth(width or header:GetStringWidth() * 1.2)
    line:SetPoint("TOP", header, "BOTTOM", 0, -1)
    line:SetColorTexture(COLORS.ACCENT.r, COLORS.ACCENT.g, COLORS.ACCENT.b, 0.6)
    header.line = line
  end

  return header
end

-- Create a color picker button
function UIComponents:CreateColorPicker(parent, width, height, initialColor, callback)
  local colorButton = CreateFrame("Button", nil, parent)
  colorButton:SetSize(width or 20, height or 20)

  -- Create color texture
  local colorTexture = colorButton:CreateTexture(nil, "OVERLAY")
  colorTexture:SetAllPoints()
  colorTexture:SetColorTexture(
    initialColor and initialColor[1] or 1,
    initialColor and initialColor[2] or 0,
    initialColor and initialColor[3] or 0,
    1
  )

  -- Create border texture
  local border = colorButton:CreateTexture(nil, "BACKGROUND")
  border:SetPoint("TOPLEFT", -1, 1)
  border:SetPoint("BOTTOMRIGHT", 1, -1)
  border:SetColorTexture(0.3, 0.3, 0.3, 1)

  -- Set up color picker functionality
  colorButton:SetScript("OnClick", function()
    local r, g, b = colorTexture:GetVertexColor()

    -- Color picker settings
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { r, g, b }
    ColorPickerFrame.func = function()
      local newR, newG, newB = ColorPickerFrame:GetColorRGB()
      colorTexture:SetColorTexture(newR, newG, newB, 1)

      if callback then
        callback(newR, newG, newB)
      end
    end

    ColorPickerFrame.cancelFunc = function(previousValues)
      colorTexture:SetColorTexture(previousValues[1], previousValues[2], previousValues[3], 1)

      if callback then
        callback(previousValues[1], previousValues[2], previousValues[3])
      end
    end

    -- Show color picker
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Hide() -- Hide before show to reset position
    ColorPickerFrame:Show()
  end)

  colorButton.SetColor = function(self, r, g, b)
    colorTexture:SetColorTexture(r, g, b, 1)
  end

  colorButton.GetColor = function(self)
    local r, g, b = colorTexture:GetVertexColor()
    return { r, g, b }
  end

  return colorButton
end

-- Create scroll frame with content
function UIComponents:CreateScrollFrame(parent, width, height, scrollChildHeight)
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetSize(width, height)

  local scrollChild = CreateFrame("Frame")
  scrollFrame:SetScrollChild(scrollChild)
  scrollChild:SetSize(width - 20, scrollChildHeight or height * 2) -- 20px for scrollbar

  return scrollFrame, scrollChild
end

-- Connect to DM namespace for backward compatibility
function UIComponents:ConnectToDMNamespace()
  -- Legacy function names
  DM.CreateLabel = function(self, parent, ...) return UIComponents:CreateLabel(parent, ...) end
  DM.CreateEditBox = function(self, parent, ...) return UIComponents:CreateEditBox(parent, ...) end
  DM.CreateButton = function(self, parent, ...) return UIComponents:CreateButton(parent, ...) end
  DM.SetTooltip = function(self, frame, ...) UIComponents:SetTooltip(frame, ...) end
  DM.CreateHeader = function(self, parent, ...) return UIComponents:CreateHeader(parent, ...) end
end

-- Debug message function with module name
function UIComponents:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[UIComponents] " .. message)
  end
end

-- Initialize the module
function UIComponents:Initialize()
  self:ConnectToDMNamespace()
  UIComponents:DebugMsg("UI Components module initialized")
end

-- Return the module
return UIComponents
