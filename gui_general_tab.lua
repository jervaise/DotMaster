-- DotMaster gui_general_tab.lua
-- Contains the General tab functionality for the GUI

local DM = DotMaster

-- Create General tab content
function DM:CreateGeneralTab(parent)
  -- Create standardized info area
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    parent,
    "DotMaster",
    "Track your DoTs on enemy nameplates with visual indicators. Use the Find My Dots feature to discover and manage your damage-over-time effects for any class or specialization."
  )

  -- Create main content container frame (similar to searchContainer in Database tab)
  local mainContent = CreateFrame("Frame", nil, parent)
  mainContent:SetSize(430, 20)
  mainContent:SetPoint("TOP", infoArea, "BOTTOM", 0, 0)

  -- Add panda image below info area - positioned closer
  local pandaImage = mainContent:CreateTexture(nil, "ARTWORK")
  pandaImage:SetSize(128, 128)                            -- Reasonable size for the image
  pandaImage:SetPoint("TOP", mainContent, "BOTTOM", 0, 0) -- Reduced the gap from -10 to 0
  pandaImage:SetTexture("Interface\\AddOns\\DotMaster\\Media\\dotmaster-main-icon.tga")

  -- General Tab Background (now starts below the content container)
  local generalBg = parent:CreateTexture(nil, "BACKGROUND")
  generalBg:SetPoint("TOPLEFT", 5, -95) -- Adjusted to match other tabs
  generalBg:SetPoint("BOTTOMRIGHT", -5, 5)
  generalBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

  -- Create a centralized settings container (moved down to account for panda image)
  local settingsContainer = CreateFrame("Frame", nil, parent)
  settingsContainer:SetSize(430, 200)
  settingsContainer:SetPoint("TOP", pandaImage, "BOTTOM", 0, -10) -- Reduced margin from -20 to -10

  -- Enable checkbox - centered horizontally
  local checkBox = CreateFrame("CheckButton", "DotMasterEnableCheckbox", settingsContainer, "UICheckButtonTemplate")
  checkBox:SetPoint("TOP", settingsContainer, "TOP", 0, 0) -- Center aligned (changed from -80,0 to 0,0)
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

  -- Minimap checkbox - directly below enable checkbox and center aligned
  local minimapCheckBox = CreateFrame("CheckButton", "DotMasterMinimapCheckbox", settingsContainer,
    "UICheckButtonTemplate")
  minimapCheckBox:SetPoint("TOP", checkBox, "BOTTOM", 0, -10)
  minimapCheckBox:SetSize(26, 26)

  local minimapCheckBoxText = _G[minimapCheckBox:GetName() .. "Text"]
  minimapCheckBoxText:SetText("Show Minimap Icon")
  minimapCheckBoxText:SetPoint("LEFT", minimapCheckBox, "RIGHT", 2, 0)

  -- Set initial state from saved variables - CORRECTLY
  -- Checked = Show (hide = false), Unchecked = Hide (hide = true)
  minimapCheckBox:SetChecked(not (DotMasterDB and DotMasterDB.minimap and DotMasterDB.minimap.hide))

  -- Handle clicks
  minimapCheckBox:SetScript("OnClick", function(self)
    if not DotMasterDB or not DotMasterDB.minimap then return end

    -- Set minimap visibility based on checkbox
    -- Checked = Show (hide = false), Unchecked = Hide (hide = true)
    DotMasterDB.minimap.hide = not self:GetChecked()

    -- Update the minimap icon with the new setting
    if DM.ToggleMinimapIcon then
      -- Call our toggle function which reads the .hide value
      DM:ToggleMinimapIcon()
    else
      -- Fallback direct manipulation if function not available
      local LibDBIcon = LibStub("LibDBIcon-1.0")
      if LibDBIcon then
        if DotMasterDB.minimap.hide then
          LibDBIcon:Hide("DotMaster")
        else
          LibDBIcon:Show("DotMaster")
        end
      end
    end
  end)

  -- Container for bottom buttons
  local bottomButtonContainer = CreateFrame("Frame", nil, parent)
  bottomButtonContainer:SetSize(parent:GetWidth() - 20, 50)
  bottomButtonContainer:SetPoint("BOTTOM", 0, 10)

  -- Reset Database Button (left side)
  local resetDbButton = CreateFrame("Button", nil, bottomButtonContainer, "UIPanelButtonTemplate")
  resetDbButton:SetSize(150, 30)
  resetDbButton:SetPoint("RIGHT", bottomButtonContainer, "CENTER", -5, 0)
  resetDbButton:SetText("Reset Database")

  -- Debug Console Button (right side)
  local debugConsoleButton = CreateFrame("Button", nil, bottomButtonContainer, "UIPanelButtonTemplate")
  debugConsoleButton:SetSize(150, 30)
  debugConsoleButton:SetPoint("LEFT", bottomButtonContainer, "CENTER", 5, 0)
  debugConsoleButton:SetText("Debug Console")
  debugConsoleButton:SetScript("OnClick", function()
    -- Toggle debug window visibility
    DM.Debug:ToggleWindow()

    -- Position the debug window next to the main UI if it's visible
    if DM.GUI.debugFrame and DM.GUI.debugFrame:IsShown() then
      -- Get the parent frame (DotMasterOptionsFrame)
      local optionsFrame = parent:GetParent()
      if optionsFrame then
        -- Clear any previous anchor points
        DM.GUI.debugFrame:ClearAllPoints()
        -- Anchor the debug window's top right to the main UI's top left
        DM.GUI.debugFrame:SetPoint("TOPRIGHT", optionsFrame, "TOPLEFT", -5, 0)
      end
    end
  end)

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
