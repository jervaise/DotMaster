-- DotMaster gui_general_tab.lua
-- Contains the General tab functionality for the GUI

local DM = DotMaster

-- Create General tab content
function DM:CreateGeneralTab(parent)
  -- Temporary Disable Notice
  local disableNotice = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  disableNotice:SetPoint("TOP", 0, -10)
  disableNotice:SetText("NAMEPLATE FEATURES TEMPORARILY DISABLED")
  disableNotice:SetTextColor(1, 0.3, 0.3)

  -- Disable explanation
  local disableExplanation = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  disableExplanation:SetPoint("TOP", disableNotice, "BOTTOM", 0, -5)
  disableExplanation:SetWidth(350)
  disableExplanation:SetText(
    "Nameplate coloring has been temporarily disabled during development. These features will be re-enabled in a future update.")
  disableExplanation:SetTextColor(1, 0.8, 0.3)

  -- General Tab Header (moved down)
  local generalHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  generalHeader:SetPoint("TOP", disableExplanation, "BOTTOM", 0, -20)
  generalHeader:SetText("Debuff nameplate coloring")

  -- General Tab Background
  local generalBg = parent:CreateTexture(nil, "BACKGROUND")
  generalBg:SetPoint("TOPLEFT", 5, -95) -- Adjusted for the warning message
  generalBg:SetPoint("BOTTOMRIGHT", -5, 5)
  generalBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

  -- Enable checkbox - left aligned
  local checkBox = CreateFrame("CheckButton", "DotMasterEnableCheckbox", parent, "UICheckButtonTemplate")
  checkBox:SetPoint("TOPLEFT", 20, -110) -- Adjusted position
  checkBox:SetSize(26, 26)

  local checkBoxText = _G[checkBox:GetName() .. "Text"]
  checkBoxText:SetText("Enable DotMaster")
  checkBoxText:SetPoint("LEFT", checkBox, "RIGHT", 2, 0)

  checkBox:SetChecked(DM.enabled)
  checkBox:SetScript("OnClick", function(self)
    DM.enabled = self:GetChecked()
    DM:PrintMessage(DM.enabled and "Enabled" or "Disabled")
    if DM.enabled then
      DM:UpdateAllNameplates()
    else
      DM:ResetAllNameplates()
    end
    DM:SaveSettings() -- Save settings immediately
  end)

  -- Debug Console Button
  local debugConsoleButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  debugConsoleButton:SetSize(120, 22)
  debugConsoleButton:SetPoint("LEFT", checkBoxText, "RIGHT", 20, 0)
  debugConsoleButton:SetText("Debug Console")
  debugConsoleButton:SetScript("OnClick", function()
    -- Toggle debug window visibility
    DM.Debug:ToggleWindow()
  end)

  -- Add help text for debug command
  local debugHelpText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  debugHelpText:SetPoint("TOPLEFT", checkBox, "BOTTOMLEFT", 0, -5)
  debugHelpText:SetWidth(350)
  debugHelpText:SetJustifyH("LEFT")
  debugHelpText:SetText("Type |cFFFFD100/dmdebug|r for quick access to debug options")
  debugHelpText:SetTextColor(0.7, 0.7, 0.7)

  -- Reset All Settings button
  local resetButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  resetButton:SetSize(150, 30)
  resetButton:SetPoint("TOPLEFT", 20, -180) -- Adjusted position
  resetButton:SetText("Reset All Settings")

  resetButton:SetScript("OnClick", function()
    -- Create confirmation dialog
    StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
      text =
      "Are you sure you want to reset all DotMaster settings? This will delete all your saved spells and configurations.",
      button1 = "Yes",
      button2 = "No",
      OnAccept = function()
        DM:PrintMessage("Resetting all settings to defaults...")
        -- Reset all settings
        DotMasterDB = nil
        DM.enabled = DM.defaults.enabled
        DM.DEBUG_MODE = true

        -- Reset spell database
        DM:ResetDMSpellsDB()

        -- Apply changes
        DM:ResetAllNameplates()
        DM:UpdateAllNameplates()
        DM:SaveSettings()
        DM:SaveDMSpellsDB()

        -- Refresh UI
        if DM.GUI and DM.GUI.RefreshSpellList then
          DM.GUI:RefreshSpellList()
        end

        DM:PrintMessage("All settings have been reset to defaults.")
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_RESET_CONFIRM")
  end)
end
