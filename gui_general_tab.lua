-- DotMaster gui_general_tab.lua
-- Contains the General tab functionality for the GUI

local DM = DotMaster

-- Create General tab content
function DM:CreateGeneralTab(parent)
  -- General Tab Header
  local generalHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  generalHeader:SetPoint("TOP", 0, -10)
  generalHeader:SetText("Debuff nameplate coloring")

  -- General Tab Background
  local generalBg = parent:CreateTexture(nil, "BACKGROUND")
  generalBg:SetPoint("TOPLEFT", 5, -35)
  generalBg:SetPoint("BOTTOMRIGHT", -5, 5)
  generalBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

  -- Enable checkbox - left aligned
  local checkBox = CreateFrame("CheckButton", "DotMasterEnableCheckbox", parent, "UICheckButtonTemplate")
  checkBox:SetPoint("TOPLEFT", 20, -50) -- Left aligned
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

  -- Debug mode switch checkbox
  local debugCheckBox = CreateFrame("CheckButton", "DotMasterDebugCheckbox", parent, "UICheckButtonTemplate")
  debugCheckBox:SetPoint("TOPLEFT", 20, -80) -- Below the enable checkbox
  debugCheckBox:SetSize(26, 26)

  local debugCheckBoxText = _G[debugCheckBox:GetName() .. "Text"]
  debugCheckBoxText:SetText("Debug Mode")
  debugCheckBoxText:SetPoint("LEFT", debugCheckBox, "RIGHT", 2, 0)

  debugCheckBox:SetChecked(DM.DEBUG_MODE)
  debugCheckBox:SetScript("OnClick", function(self)
    DM.DEBUG_MODE = self:GetChecked()
    DM:PrintMessage("Debug Mode " .. (DM.DEBUG_MODE and "Enabled" or "Disabled"))
    DM:SaveSettings() -- Save settings immediately
  end)

  -- Reset All Settings button
  local resetButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  resetButton:SetSize(150, 30)
  resetButton:SetPoint("TOPLEFT", 20, -120) -- Below debug checkbox
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
        DM.spellConfig = {}
        DM.spellConfig = DM:DeepCopy(DM.defaults.spellConfig)
        DM.enabled = DM.defaults.enabled
        DM.DEBUG_MODE = true

        -- Apply changes
        DM:ResetAllNameplates()
        DM:UpdateAllNameplates()
        DM:SaveSettings()

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
