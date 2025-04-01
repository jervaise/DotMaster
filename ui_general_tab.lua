--[[
  DotMaster - UI General Tab Module

  File: ui_general_tab.lua
  Purpose: General settings tab content for the main UI

  Functions:
    CreateGeneralTab(): Creates and populates the general settings tab
    UpdateEnableState(): Updates UI based on addon enabled state

  Dependencies:
    DotMaster core
    ui_components.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create UI General Tab module
local UIGeneralTab = {}
DM.UIGeneralTab = UIGeneralTab

-- UI elements
local generalTabFrame = nil
local enableCheckbox = nil
local sizeSlider = nil
local alphaSlider = nil
local positionDropdown = nil
local paddingSlider = nil
local nameplateTestButton = nil
local resetButton = nil
local minimapCheckbox = nil

-- Create and populate the general tab
function UIGeneralTab:CreateGeneralTab(parent)
  if generalTabFrame then return generalTabFrame end

  generalTabFrame = parent
  local Components = DM.UIComponents

  -- Create the header
  local header = Components:CreateHeader(parent, "General Settings", nil, true)
  header:SetPoint("TOP", 0, -10)

  -- Enabled checkbox with tooltip
  enableCheckbox = Components:CreateCheckbox(parent, "Enable DotMaster", DM.enabled)
  enableCheckbox:SetPoint("TOPLEFT", 20, -50)
  Components:SetTooltip(enableCheckbox, "Enable DotMaster", "Show spell dots above enemy nameplates")

  enableCheckbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    DM.enabled = checked

    if checked then
      DM:PrintMessage("Enabled")
      DM:UpdateAllNameplates()
    else
      DM:PrintMessage("Disabled")
      DM:ResetAllNameplates()
    end

    DM:SaveSettings()
    UIGeneralTab:UpdateEnableState()
  end)

  -- Minimap button checkbox
  minimapCheckbox = Components:CreateCheckbox(parent, "Show Minimap Button", DM.minimapEnabled)
  minimapCheckbox:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)
  Components:SetTooltip(minimapCheckbox, "Show Minimap Button",
    "Show a button on the minimap to quickly access DotMaster")

  minimapCheckbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    DM.minimapEnabled = checked

    if DM.MinimapButton and DM.MinimapButton.ToggleMinimapButton then
      DM.MinimapButton:ToggleMinimapButton(checked)
    end

    DM:SaveSettings()
  end)

  -- Dot size slider
  local sizeLabel = Components:CreateLabel(parent, "Dot Size:")
  sizeLabel:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -20)

  sizeSlider = Components:CreateSlider(parent, 6, 24, 180, 1, DM.dotSize)
  sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -5)
  _G[sizeSlider:GetName() .. "Text"]:SetText(DM.dotSize)

  sizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    _G[self:GetName() .. "Text"]:SetText(value)
    DM.dotSize = value
    DM:UpdateAllNameplates()
    DM:SaveSettings()
  end)

  -- Dot alpha slider
  local alphaLabel = Components:CreateLabel(parent, "Dot Opacity:")
  alphaLabel:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -20)

  alphaSlider = Components:CreateSlider(parent, 0.1, 1.0, 180, 0.05, DM.dotAlpha)
  alphaSlider:SetPoint("TOPLEFT", alphaLabel, "BOTTOMLEFT", 0, -5)
  _G[alphaSlider:GetName() .. "Text"]:SetText(string.format("%.2f", DM.dotAlpha))

  alphaSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value * 100 + 0.5) / 100
    _G[self:GetName() .. "Text"]:SetText(string.format("%.2f", value))
    DM.dotAlpha = value
    DM:UpdateAllNameplates()
    DM:SaveSettings()
  end)

  -- Position dropdown
  local positionLabel = Components:CreateLabel(parent, "Dot Position:")
  positionLabel:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -20)

  -- Create custom dropdown
  positionDropdown = CreateFrame("Frame", "DotMasterPositionDropdown", parent, "UIDropDownMenuTemplate")
  positionDropdown:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", -15, -5)

  -- Position options
  local positions = {
    { text = "Above", value = "ABOVE" },
    { text = "Below", value = "BELOW" },
    { text = "Left",  value = "LEFT" },
    { text = "Right", value = "RIGHT" }
  }

  -- Initialize dropdown
  UIDropDownMenu_SetWidth(positionDropdown, 120)
  UIDropDownMenu_SetText(positionDropdown,
    positions[DM.dotPosition == "ABOVE" and 1 or DM.dotPosition == "BELOW" and 2 or DM.dotPosition == "LEFT" and 3 or 4]
    .text)

  -- Setup dropdown menu
  UIDropDownMenu_Initialize(positionDropdown, function(self, level)
    for i, option in ipairs(positions) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = option.text
      info.value = option.value
      info.func = function()
        UIDropDownMenu_SetText(positionDropdown, option.text)
        DM.dotPosition = option.value
        DM:UpdateAllNameplates()
        DM:SaveSettings()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  -- Padding slider
  local paddingLabel = Components:CreateLabel(parent, "Dot Padding:")
  paddingLabel:SetPoint("TOPLEFT", positionDropdown, "BOTTOMLEFT", 15, -15)

  paddingSlider = Components:CreateSlider(parent, 1, 20, 180, 1, DM.dotPadding)
  paddingSlider:SetPoint("TOPLEFT", paddingLabel, "BOTTOMLEFT", 0, -5)
  _G[paddingSlider:GetName() .. "Text"]:SetText(DM.dotPadding)

  paddingSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    _G[self:GetName() .. "Text"]:SetText(value)
    DM.dotPadding = value
    DM:UpdateAllNameplates()
    DM:SaveSettings()
  end)

  -- Debug mode checkbox
  local debugCheckbox = Components:CreateCheckbox(parent, "Debug Mode", DM.DEBUG_MODE)
  debugCheckbox:SetPoint("TOPLEFT", paddingSlider, "BOTTOMLEFT", 0, -20)
  Components:SetTooltip(debugCheckbox, "Debug Mode", "Show additional debug information in the chat frame")

  debugCheckbox:SetScript("OnClick", function(self)
    DM.DEBUG_MODE = self:GetChecked()
    DM:PrintMessage("Debug Mode " .. (DM.DEBUG_MODE and "Enabled" or "Disabled"))
    DM:SaveSettings()
  end)

  -- Test button
  nameplateTestButton = Components:CreateButton(parent, "Test on Target", 150)
  nameplateTestButton:SetPoint("TOPLEFT", debugCheckbox, "BOTTOMLEFT", 0, -20)
  Components:SetTooltip(nameplateTestButton, "Test DotMaster", "Test DotMaster functionality on your current target")

  nameplateTestButton:SetScript("OnClick", function()
    if UnitExists("target") and UnitCanAttack("player", "target") then
      DM:TestDotsOnTarget()
    else
      DM:PrintMessage("You need to target an enemy to test dots")
    end
  end)

  -- Reset button
  resetButton = Components:CreateButton(parent, "Reset All Settings", 150)
  resetButton:SetPoint("TOPLEFT", nameplateTestButton, "BOTTOMLEFT", 0, -10)
  Components:SetTooltip(resetButton, "Reset All Settings", "Reset all settings to default values")

  resetButton:SetScript("OnClick", function()
    StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
      text = "Are you sure you want to reset all DotMaster settings to default values?",
      button1 = "Yes",
      button2 = "No",
      OnAccept = function()
        DM:ResetSettings()
        DM:PrintMessage("Settings reset to defaults")

        -- Update UI elements to reflect new values
        enableCheckbox:SetChecked(DM.enabled)
        minimapCheckbox:SetChecked(DM.minimapEnabled)
        sizeSlider:SetValue(DM.dotSize)
        alphaSlider:SetValue(DM.dotAlpha)
        UIDropDownMenu_SetText(positionDropdown,
          positions[DM.dotPosition == "ABOVE" and 1 or DM.dotPosition == "BELOW" and 2 or DM.dotPosition == "LEFT" and 3 or 4]
          .text)
        paddingSlider:SetValue(DM.dotPadding)
        debugCheckbox:SetChecked(DM.DEBUG_MODE)

        UIGeneralTab:UpdateEnableState()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_RESET_CONFIRM")
  end)

  -- Find My Dots button
  local findMyDotsButton = Components:CreateButton(parent, "Find My Dots", 150)
  findMyDotsButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -10)
  Components:SetTooltip(findMyDotsButton, "Find My Dots", "Automatically detect your spells by casting them on targets")

  findMyDotsButton:SetScript("OnClick", function()
    if DM.FindMyDots and DM.FindMyDots.ToggleFindMyDotsWindow then
      DM.FindMyDots:ToggleFindMyDotsWindow()
    else
      DM:ToggleFindMyDotsWindow()
    end
  end)

  -- Version info
  local versionLabel = Components:CreateLabel(parent, "Version: " .. (DM.version or "Unknown"), "GameFontNormalSmall")
  versionLabel:SetPoint("BOTTOMLEFT", 10, 10)

  -- Update UI based on current settings
  UIGeneralTab:UpdateEnableState()

  return generalTabFrame
end

-- Update UI based on addon enabled state
function UIGeneralTab:UpdateEnableState()
  local enabled = DM.enabled

  if sizeSlider then sizeSlider:SetEnabled(enabled) end
  if alphaSlider then alphaSlider:SetEnabled(enabled) end
  if positionDropdown then
    if enabled then
      UIDropDownMenu_EnableDropDown(positionDropdown)
    else
      UIDropDownMenu_DisableDropDown(positionDropdown)
    end
  end
  if paddingSlider then paddingSlider:SetEnabled(enabled) end
  if nameplateTestButton then nameplateTestButton:SetEnabled(enabled) end
end

-- Add this tab to the main UI when the tab system is ready
function UIGeneralTab:RegisterTab()
  if DM.UIMain and DM.UIMain.GetTabSystem then
    local tabSystem = DM.UIMain:GetTabSystem()
    if tabSystem then
      tabSystem:AddTab("General", function(parent)
        UIGeneralTab:CreateGeneralTab(parent)
      end)
    end
  end
end

-- Debug message function with module name
function UIGeneralTab:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[UIGeneralTab] " .. message)
  end
end

-- Connect to DM namespace for backward compatibility
function UIGeneralTab:ConnectToDMNamespace()
  DM.CreateGeneralTab = function(self, parent)
    return UIGeneralTab:CreateGeneralTab(parent)
  end
end

-- Initialize the module
function UIGeneralTab:Initialize()
  self:ConnectToDMNamespace()
  self:RegisterTab()
  UIGeneralTab:DebugMsg("UI General Tab module initialized")
end

-- Return the module
return UIGeneralTab
