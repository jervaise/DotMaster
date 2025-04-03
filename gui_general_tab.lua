-- DotMaster gui_general_tab.lua
-- Contains the General tab functionality for the GUI

local DM = DotMaster

-- Helper function to restore checkbox text
local function RestoreCheckboxTexts()
  -- With our new implementation using direct font strings,
  -- restoration should no longer be needed, but we'll keep
  -- this as a fallback just in case
  local checkboxes = {
    "DotMasterEnableCheckbox",
    "DotMasterMinimapCheckbox",
    "DotMasterForceColorCheckbox"
  }

  for _, checkboxName in ipairs(checkboxes) do
    local checkbox = _G[checkboxName]
    if checkbox then
      -- Check if our custom text element exists
      if checkbox.labelText then
        if checkboxName == "DotMasterEnableCheckbox" then
          checkbox.labelText:SetText("Enable DotMaster")
        elseif checkboxName == "DotMasterMinimapCheckbox" then
          checkbox.labelText:SetText("Show Minimap Icon")
        elseif checkboxName == "DotMasterForceColorCheckbox" then
          checkbox.labelText:SetText("Force Threat Color")
        end
      end
    end
  end
end

-- Create General tab content
function DM:CreateGeneralTab(parent)
  -- Create standardized info area
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    parent,
    "DotMaster: Your DoT Tracking |cFFFF6A00Plater|r Companion",
    "• Highlights enemy nameplates with your active DoTs\n• Tracks all your damage-over-time effects in one place\n• Works with any class and specialization"
  )

  -- ===== NEW MODERN UI DESIGN BEGINS HERE =====

  -- Create a styled content panel with border
  local contentPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  contentPanel:SetSize(410, 350)
  contentPanel:SetPoint("TOP", infoArea, "BOTTOM", 0, -15)

  -- Apply a subtle backdrop
  contentPanel:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  contentPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.7)       -- Slightly transparent dark background
  contentPanel:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8) -- Subtle border

  -- Get the player's class color for accent elements
  local playerClass = select(2, UnitClass("player"))
  local classColor = RAID_CLASS_COLORS[playerClass] or { r = 0.6, g = 0.2, b = 1.0 }

  -- Create an image and settings layout with flex positioning
  local imagePanel = CreateFrame("Frame", nil, contentPanel)
  imagePanel:SetSize(150, 150)
  imagePanel:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 30, -25)

  -- Add panda image with a subtle border
  local imageBorder = CreateFrame("Frame", nil, imagePanel, "BackdropTemplate")
  imageBorder:SetSize(128, 128)
  imageBorder:SetPoint("CENTER", imagePanel, "CENTER")
  imageBorder:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
  })
  imageBorder:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.6)

  local pandaImage = imageBorder:CreateTexture(nil, "ARTWORK")
  pandaImage:SetSize(110, 110)
  pandaImage:SetPoint("CENTER")
  pandaImage:SetTexture("Interface\\AddOns\\DotMaster\\Media\\dotmaster-main-icon.tga")

  -- Create settings panel
  local settingsPanel = CreateFrame("Frame", nil, contentPanel)
  settingsPanel:SetSize(200, 150)
  settingsPanel:SetPoint("TOPRIGHT", contentPanel, "TOPRIGHT", -30, -25)

  -- Create a title for the settings section
  local settingsTitle = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  settingsTitle:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 0, 10)
  settingsTitle:SetText("Configuration")
  settingsTitle:SetTextColor(classColor.r, classColor.g, classColor.b)

  -- Create a container for the checkboxes with better spacing
  local checkboxContainer = CreateFrame("Frame", nil, settingsPanel)
  checkboxContainer:SetSize(200, 140)
  checkboxContainer:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -15)

  -- Helper function to create styled checkboxes
  local function CreateStyledCheckbox(name, parent, anchorFrame, offsetY, label)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)

    if anchorFrame then
      checkbox:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY)
    else
      checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    end

    -- Hide the default template text which disappears during zone transitions
    local defaultText = _G[checkbox:GetName() .. "Text"]
    if defaultText then
      defaultText:Hide()
    end

    -- Create our own text element directly attached to the checkbox
    -- This is more resilient during zone transitions
    local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText(label)
    text:SetTextColor(0.9, 0.9, 0.9) -- Brighter text for better readability

    -- Store the text element reference on the checkbox
    checkbox.labelText = text

    return checkbox
  end

  -- Create the main feature checkbox
  local enableCheckbox = CreateStyledCheckbox("DotMasterEnableCheckbox",
    checkboxContainer, nil, 0, "Enable DotMaster")
  enableCheckbox:SetChecked(DM.enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    DM.enabled = self:GetChecked()
    DM:PrintMessage(DM.enabled and "Enabled" or "Disabled")
    if DM.enabled then
      DM:UpdateAllNameplates()
    else
      DM:ResetAllNameplates()
    end
    DM:SaveSettings()
  end)

  -- Create minimap checkbox
  local minimapCheckbox = CreateStyledCheckbox("DotMasterMinimapCheckbox",
    checkboxContainer, enableCheckbox, -18, "Show Minimap Icon")
  minimapCheckbox:SetChecked(not (DotMasterDB and DotMasterDB.minimap and DotMasterDB.minimap.hide))
  minimapCheckbox:SetScript("OnClick", function(self)
    if not DotMasterDB or not DotMasterDB.minimap then return end
    DotMasterDB.minimap.hide = not self:GetChecked()
    if DM.ToggleMinimapIcon then
      DM:ToggleMinimapIcon()
    else
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

  -- Create force threat color checkbox
  local forceColorCheckbox = CreateStyledCheckbox("DotMasterForceColorCheckbox",
    checkboxContainer, minimapCheckbox, -18, "Force Threat Color")
  if DM.settings == nil then DM.settings = {} end
  if DM.settings.forceColor == nil then DM.settings.forceColor = false end
  forceColorCheckbox:SetChecked(DM.settings.forceColor)
  forceColorCheckbox:SetScript("OnClick", function(self)
    DM.settings.forceColor = self:GetChecked()
    DM:PrintMessage("Force Threat Color " .. (DM.settings.forceColor and "Enabled" or "Disabled"))
    if DM.enabled then
      DM:UpdateAllNameplates()
    end
    DM:SaveSettings()
  end)

  -- Create info section below the checkboxes
  local infoSection = CreateFrame("Frame", nil, contentPanel, "BackdropTemplate")
  infoSection:SetSize(350, 100)
  infoSection:SetPoint("TOP", contentPanel, "TOP", 0, -190)
  infoSection:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  infoSection:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
  infoSection:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

  -- Add a title for the info section
  local infoTitle = infoSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoTitle:SetPoint("TOPLEFT", infoSection, "TOPLEFT", 12, -10)
  infoTitle:SetText("Threat Color Information")
  infoTitle:SetTextColor(classColor.r, classColor.g, classColor.b)

  -- Add explanatory text with better formatting
  local infoText = infoSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  infoText:SetPoint("TOPLEFT", infoTitle, "BOTTOMLEFT", 0, -8)
  infoText:SetPoint("BOTTOMRIGHT", infoSection, "BOTTOMRIGHT", -12, 10)
  infoText:SetText(
    "Highlight targets with threat colors when they have DoTs (aggro warning for DPS, lost aggro warning for tanks)")
  infoText:SetJustifyH("LEFT")
  infoText:SetJustifyV("TOP")
  infoText:SetTextColor(0.8, 0.8, 0.8)
  infoText:SetSpacing(2) -- Add some line spacing for readability

  -- Register for PLAYER_ENTERING_WORLD to restore checkbox texts after loading screens
  local restoreTextFrame = CreateFrame("Frame")
  restoreTextFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  restoreTextFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
  restoreTextFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
      C_Timer.After(0.1, function()
        RestoreCheckboxTexts()
      end)
    end
  end)

  -- Store the function to allow manual restoration
  DM.RestoreCheckboxTexts = RestoreCheckboxTexts

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
