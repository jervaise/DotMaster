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

  -- Container for bottom buttons
  local bottomButtonContainer = CreateFrame("Frame", nil, parent)
  bottomButtonContainer:SetSize(parent:GetWidth() - 20, 50)
  bottomButtonContainer:SetPoint("BOTTOM", 0, 10)

  -- Reset Database Button (Moved from Database Tab)
  local resetDbButton = CreateFrame("Button", nil, bottomButtonContainer, "UIPanelButtonTemplate")
  resetDbButton:SetSize(150, 30)
  resetDbButton:SetPoint("CENTER", 0, 0) -- Center it in the container
  resetDbButton:SetText("Reset Database")

  -- Add tooltip
  resetDbButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Reset Database", 1, 1, 1)
    GameTooltip:AddLine("Clear all spells from the database. This cannot be undone!", 1, 0.3, 0.3, true)
    GameTooltip:Show()
  end)

  resetDbButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  resetDbButton:SetScript("OnClick", function()
    -- Confirmation prompt (Copied from Database Tab)
    StaticPopupDialogs["DOTMASTER_RESET_DB_CONFIRM"] = {
      text = "Are you sure you want to reset the database?\nThis will remove ALL spells and cannot be undone!",
      button1 = "Yes, Reset",
      button2 = "Cancel",
      OnAccept = function()
        DM:DatabaseDebug("Resetting Database from General Tab")
        DM:ResetDMSpellsDB()
        DM:SaveDMSpellsDB()
        -- Refresh relevant UI if open
        if DM.GUI and DM.GUI.RefreshDatabaseTabList then
          DM.GUI:RefreshDatabaseTabList()
        end
        if DM.GUI and DM.GUI.RefreshTrackedSpellTabList then
          DM.GUI:RefreshTrackedSpellTabList()
        end
        DM:DatabaseDebug("Database has been reset and UI refreshed.")
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_RESET_DB_CONFIRM")
  end)
end
