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
    "DotMaster: Your DoT Tracking Companion",
    "Colors enemy nameplates\nTracks all your damage-over-time effects in one place\nWorks with any class and specialization"
  )

  -- Get the player's class color for accent elements
  local playerClass = select(2, UnitClass("player"))
  local classColor = RAID_CLASS_COLORS[playerClass] or { r = 0.6, g = 0.2, b = 1.0 }

  -- Create main content container with lower height to avoid footer overlap
  local contentPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  contentPanel:SetSize(450, 270) -- Reduced height from 370 to 270 to avoid footer overlap
  contentPanel:SetPoint("TOP", infoArea, "BOTTOM", 0, -15)

  -- Apply a subtle backdrop
  contentPanel:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  contentPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
  contentPanel:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

  -- Title for the panel
  local configTitle = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  configTitle:SetPoint("TOP", contentPanel, "TOP", 0, -15)

  -- Get current class and spec
  local currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
  local specName = currentSpecID and select(2, GetSpecializationInfoByID(currentSpecID)) or "Unknown"

  -- Format the title with class/spec info
  configTitle:SetText("Configuration - " .. currentClass .. " (" .. specName .. ")")
  configTitle:SetTextColor(classColor.r, classColor.g, classColor.b)

  -- Create the two-column layout
  -- Left column for image
  local leftColumn = CreateFrame("Frame", nil, contentPanel)
  leftColumn:SetSize(150, 150)
  leftColumn:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 30, -50)

  -- Right column for settings
  local rightColumn = CreateFrame("Frame", nil, contentPanel)
  rightColumn:SetSize(240, 150)
  rightColumn:SetPoint("TOPRIGHT", contentPanel, "TOPRIGHT", -30, -50)

  -- Add panda image with a subtle border
  local imageBorder = CreateFrame("Frame", nil, leftColumn, "BackdropTemplate")
  imageBorder:SetSize(140, 140)
  imageBorder:SetPoint("CENTER", leftColumn, "CENTER")
  imageBorder:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
  })
  imageBorder:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.6)

  local pandaImage = imageBorder:CreateTexture(nil, "ARTWORK")
  pandaImage:SetSize(120, 120)
  pandaImage:SetPoint("CENTER")
  pandaImage:SetTexture("Interface\\AddOns\\DotMaster\\Media\\dotmaster-main-icon.tga")

  -- Get settings from API
  local settings = DM.API:GetSettings()

  -- Helper function to create styled checkboxes
  local function CreateStyledCheckbox(name, parent, anchorFrame, offsetY, label)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)

    if anchorFrame then
      checkbox:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY)
    else
      checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    end

    -- Hide the default template text
    local defaultText = _G[checkbox:GetName() .. "Text"]
    if defaultText then defaultText:Hide() end

    -- Create our own text element
    local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText(label)
    text:SetTextColor(0.9, 0.9, 0.9)

    -- Store the text element reference
    checkbox.labelText = text

    return checkbox
  end

  -- Create settings checkboxes in the right column
  local enableCheckbox = CreateStyledCheckbox("DotMasterEnableCheckbox",
    rightColumn, nil, -3, "Enable DotMaster")
  enableCheckbox:SetChecked(settings.enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()

    -- Debug the state before changes
    print("DotMaster: Setting enabled state from " .. (DM.enabled and "ENABLED" or "DISABLED") ..
      " to " .. (enabled and "ENABLED" or "DISABLED"))

    -- Update the in-memory setting
    settings.enabled = enabled

    -- Force-write directly to DotMasterDB immediately
    if DotMasterDB ~= nil then
      DotMasterDB.enabled = enabled
      print("DotMaster: Force-saved enabled state to DotMasterDB: " .. (enabled and "ENABLED" or "DISABLED"))
    end

    -- Update the core state variable too
    DM.enabled = enabled

    -- Call the API function to update Plater
    DM.API:EnableAddon(enabled)

    -- Print a user-facing message
    DM:PrintMessage(enabled and "Enabled" or "Disabled")

    -- Use AutoSave for proper serialization
    DM:AutoSave()
  end)

  local minimapCheckbox = CreateStyledCheckbox("DotMasterMinimapCheckbox",
    rightColumn, enableCheckbox, -3, "Show Minimap Icon")
  minimapCheckbox:SetChecked(not (settings.minimapIcon and settings.minimapIcon.hide))
  minimapCheckbox:SetScript("OnClick", function(self)
    local showIcon = self:GetChecked()
    if not settings.minimapIcon then settings.minimapIcon = {} end
    settings.minimapIcon.hide = not showIcon
    DM:AutoSave()
    local success = pcall(function()
      if DM.ToggleMinimapIcon then
        DM:ToggleMinimapIcon()
      else
        local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if LibDBIcon then
          if settings.minimapIcon.hide then
            LibDBIcon:Hide("DotMaster")
          else
            LibDBIcon:Show("DotMaster")
          end
        end
      end
    end)
  end)

  local forceColorCheckbox = CreateStyledCheckbox("DotMasterForceColorCheckbox",
    rightColumn, minimapCheckbox, -3, "Force Threat Color")
  forceColorCheckbox:SetChecked(settings.forceColor)
  forceColorCheckbox:SetScript("OnClick", function(self)
    local forceColor = self:GetChecked()

    -- Update the local settings
    settings.forceColor = forceColor

    -- Force-save directly to DotMasterDB
    if DotMasterDB ~= nil then
      if not DotMasterDB.settings then DotMasterDB.settings = {} end
      DotMasterDB.settings.forceColor = forceColor
      print("DotMaster: Force-saved Force Threat Color setting to DotMasterDB: " ..
        (forceColor and "ENABLED" or "DISABLED"))
    end

    -- Print message to user
    DM:PrintMessage("Force Threat Color " .. (forceColor and "Enabled" or "Disabled"))

    -- AutoSave for serialization
    DM:AutoSave()

    -- Reinstall Plater mod to ensure changes take effect
    if settings.enabled and Plater and DM.PlaterIntegration then
      print("DotMaster: Reinstalling Plater mod due to Force Color setting change")
      DM.PlaterIntegration:InstallPlaterMod()
    end
  end)

  -- Create a checkbox for border-only mode
  local borderOnlyCheckbox = CreateStyledCheckbox("DotMasterBorderOnlyCheckbox",
    rightColumn, forceColorCheckbox, -3, "Border-only")
  borderOnlyCheckbox:SetChecked(settings.borderOnly)

  -- Border thickness control
  if settings.borderThickness == nil then settings.borderThickness = 2 end
  local thicknessContainer = CreateFrame("Frame", nil, rightColumn)
  thicknessContainer:SetSize(70, 26)
  thicknessContainer:SetPoint("LEFT", borderOnlyCheckbox.labelText, "RIGHT", 10, 0)

  -- Value container
  local thicknessValueContainer = CreateFrame("Frame", nil, thicknessContainer)
  thicknessValueContainer:SetSize(30, 26)
  thicknessValueContainer:SetPoint("LEFT", thicknessContainer, "LEFT", 0, 0)

  -- Thickness value display
  local thicknessValue = thicknessValueContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  thicknessValue:SetPoint("RIGHT", thicknessValueContainer, "RIGHT", 0, 0)
  thicknessValue:SetJustifyH("RIGHT")
  thicknessValue:SetText(settings.borderThickness .. " px")

  -- Decrease button
  local decreaseButton = CreateFrame("Button", nil, thicknessContainer)
  decreaseButton:SetSize(16, 16)
  decreaseButton:SetPoint("LEFT", thicknessValueContainer, "RIGHT", 2, 0)
  decreaseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  decreaseButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
  decreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  decreaseButton:SetScript("OnClick", function()
    if settings.borderThickness > 1 then
      -- Decrement the thickness value
      local oldValue = settings.borderThickness
      settings.borderThickness = settings.borderThickness - 1
      local newValue = settings.borderThickness

      -- Update the display
      thicknessValue:SetText(settings.borderThickness .. " px")

      -- Distinctive debug message to track the change
      print("|cFFFF9900DotMaster-BorderDebug: DECREASED thickness from " .. oldValue .. " to " .. newValue .. "|r")

      -- Force-save the borderThickness to DotMasterDB immediately
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderThickness = newValue
        print("|cFFFF9900DotMaster-BorderDebug: FORCE SAVED thickness value " .. newValue .. " to DotMasterDB|r")
      end

      -- Use AutoSave instead of direct SaveSettings
      DM:AutoSave()

      -- Update nameplates if enabled
      if settings.enabled then
        DM:UpdateAllNameplates()
      end
    end
  end)

  -- Increase button
  local increaseButton = CreateFrame("Button", nil, thicknessContainer)
  increaseButton:SetSize(16, 16)
  increaseButton:SetPoint("LEFT", decreaseButton, "RIGHT", 2, 0)
  increaseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
  increaseButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
  increaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  increaseButton:SetScript("OnClick", function()
    if settings.borderThickness < 5 then
      -- Increment the thickness value
      local oldValue = settings.borderThickness
      settings.borderThickness = settings.borderThickness + 1
      local newValue = settings.borderThickness

      -- Update the display
      thicknessValue:SetText(settings.borderThickness .. " px")

      -- Distinctive debug message to track the change
      print("|cFFFF9900DotMaster-BorderDebug: INCREASED thickness from " .. oldValue .. " to " .. newValue .. "|r")

      -- Force-save the borderThickness to DotMasterDB immediately
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderThickness = newValue
        print("|cFFFF9900DotMaster-BorderDebug: FORCE SAVED thickness value " .. newValue .. " to DotMasterDB|r")
      end

      -- Use AutoSave instead of direct SaveSettings
      DM:AutoSave()

      -- Update nameplates if enabled
      if settings.enabled then
        DM:UpdateAllNameplates()
      end
    end
  end)

  -- Now set up the border checkbox handler AFTER the thickness container is fully created
  borderOnlyCheckbox:SetScript("OnClick", function(self)
    local borderOnly = self:GetChecked()

    -- Update local settings
    settings.borderOnly = borderOnly

    -- Force-save directly to DotMasterDB
    if DotMasterDB ~= nil then
      if not DotMasterDB.settings then DotMasterDB.settings = {} end
      DotMasterDB.settings.borderOnly = borderOnly
      print("DotMaster: Force-saved Border Only setting to DotMasterDB: " ..
        (borderOnly and "ENABLED" or "DISABLED"))

      -- If disabling border-only mode, mark that we need to restore Plater's thickness on reload
      if not borderOnly then
        DotMasterDB.shouldRestorePlaterThickness = true
        print("DotMaster: Border-only mode disabled - will restore Plater's original thickness on reload")
      end
    end

    -- Show/hide thickness container - EXPLICITLY show/hide it
    if borderOnly then
      print("DotMaster: Showing thickness controls")
      thicknessContainer:Show()
    else
      print("DotMaster: Hiding thickness controls")
      thicknessContainer:Hide()
    end

    -- Print message to user
    DM:PrintMessage("Border-only " .. (borderOnly and "Enabled" or "Disabled"))

    -- AutoSave for serialization
    DM:AutoSave()

    -- Reinstall Plater mod to ensure changes take effect
    if settings.enabled and Plater and DM.PlaterIntegration then
      print("DotMaster: Reinstalling Plater mod due to Border Only setting change")
      DM.PlaterIntegration:InstallPlaterMod()
    end

    -- NOTE: Do NOT show reload popup immediately
    -- Let the popup appear only when the GUI is closed
    -- This matches the behavior of the border thickness changes

    -- Update nameplates if enabled
    if settings.enabled then DM:UpdateAllNameplates() end
  end)

  -- Initially hide/show based on state
  if settings.borderOnly then
    print("DotMaster: Initially showing thickness controls")
    thicknessContainer:Show()
  else
    print("DotMaster: Initially hiding thickness controls")
    thicknessContainer:Hide()
  end

  -- Flash checkbox
  local flashingCheckbox = CreateStyledCheckbox("DotMasterFlashingCheckbox",
    rightColumn, borderOnlyCheckbox, -3, "Expiry Flash")
  flashingCheckbox:SetChecked(settings.flashExpiring)

  -- Seconds control
  local secondsContainer = CreateFrame("Frame", nil, rightColumn)
  secondsContainer:SetSize(70, 26)
  secondsContainer:SetPoint("LEFT", flashingCheckbox.labelText, "RIGHT", 10, 0)

  -- Seconds value container
  local secondsValueContainer = CreateFrame("Frame", nil, secondsContainer)
  secondsValueContainer:SetSize(30, 26)
  secondsValueContainer:SetPoint("LEFT", secondsContainer, "LEFT", 0, 0)

  -- Seconds value display
  local secondsValue = secondsValueContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  secondsValue:SetPoint("RIGHT", secondsValueContainer, "RIGHT", 0, 0)
  secondsValue:SetJustifyH("RIGHT")
  secondsValue:SetText(settings.flashThresholdSeconds .. " s")

  -- Second decrease button
  local secondsDecreaseButton = CreateFrame("Button", nil, secondsContainer)
  secondsDecreaseButton:SetSize(16, 16)
  secondsDecreaseButton:SetPoint("LEFT", secondsValueContainer, "RIGHT", 2, 0)
  secondsDecreaseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  secondsDecreaseButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
  secondsDecreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  secondsDecreaseButton:SetScript("OnClick", function()
    if settings.flashThresholdSeconds > 1 then
      settings.flashThresholdSeconds = settings.flashThresholdSeconds - 0.5
      secondsValue:SetText(settings.flashThresholdSeconds .. " s")

      -- Force-save directly to DotMasterDB
      if DotMasterDB ~= nil then
        if not DotMasterDB.settings then DotMasterDB.settings = {} end
        DotMasterDB.settings.flashThresholdSeconds = settings.flashThresholdSeconds
        print("DotMaster: Force-saved Flash Threshold to DotMasterDB: " ..
          settings.flashThresholdSeconds .. " seconds")
      end

      DM:AutoSave()
    end
  end)

  -- Seconds increase button
  local secondsIncreaseButton = CreateFrame("Button", nil, secondsContainer)
  secondsIncreaseButton:SetSize(16, 16)
  secondsIncreaseButton:SetPoint("LEFT", secondsDecreaseButton, "RIGHT", 2, 0)
  secondsIncreaseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
  secondsIncreaseButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
  secondsIncreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  secondsIncreaseButton:SetScript("OnClick", function()
    if settings.flashThresholdSeconds < 8 then
      settings.flashThresholdSeconds = settings.flashThresholdSeconds + 0.5
      secondsValue:SetText(settings.flashThresholdSeconds .. " s")

      -- Force-save directly to DotMasterDB
      if DotMasterDB ~= nil then
        if not DotMasterDB.settings then DotMasterDB.settings = {} end
        DotMasterDB.settings.flashThresholdSeconds = settings.flashThresholdSeconds
        print("DotMaster: Force-saved Flash Threshold to DotMasterDB: " ..
          settings.flashThresholdSeconds .. " seconds")
      end

      DM:AutoSave()
    end
  end)

  -- Initially hide/show based on state
  if settings.flashExpiring then
    secondsContainer:Show()
  else
    secondsContainer:Hide()
  end

  -- Flash checkbox handler
  flashingCheckbox:SetScript("OnClick", function(self)
    local flashExpiring = self:GetChecked()

    -- Update local settings
    settings.flashExpiring = flashExpiring

    -- Force-save directly to DotMasterDB
    if DotMasterDB ~= nil then
      if not DotMasterDB.settings then DotMasterDB.settings = {} end
      DotMasterDB.settings.flashExpiring = flashExpiring
      print("DotMaster: Force-saved Flash Expiring setting to DotMasterDB: " ..
        (flashExpiring and "ENABLED" or "DISABLED"))
    end

    -- Show/hide seconds container
    if secondsContainer then
      if flashExpiring then
        secondsContainer:Show()
      else
        secondsContainer:Hide()
      end
    end

    -- Print message to user
    DM:PrintMessage("Expiry Flash " .. (flashExpiring and "Enabled" or "Disabled"))

    -- AutoSave for serialization
    DM:AutoSave()
  end)

  -- Register event to fix checkbox text
  local eventFrame = CreateFrame("Frame")
  eventFrame:RegisterEvent("ZONE_CHANGED")
  eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  eventFrame:SetScript("OnEvent", function()
    C_Timer.After(0.5, RestoreCheckboxTexts)
  end)

  return parent
end
