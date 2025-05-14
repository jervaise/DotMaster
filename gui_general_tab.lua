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
    "DotMasterForceColorCheckbox",
    "DotMasterExtendColorsCheckbox",
    "DotMasterBorderOnlyCheckbox"
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
        elseif checkboxName == "DotMasterExtendColorsCheckbox" then
          checkbox.labelText:SetText("Extend Plater Colors to Borders")
        elseif checkboxName == "DotMasterBorderOnlyCheckbox" then
          checkbox.labelText:SetText("Use Borders for DoT Tracking")
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
  contentPanel:SetSize(450, 330) -- Changed height from 430px to 330px
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
  leftColumn:SetSize(140, 140)
  leftColumn:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 25, -50) -- Added 15px left margin (from 10 to 25)

  -- Right column for settings
  local rightColumn = CreateFrame("Frame", nil, contentPanel)
  rightColumn:SetSize(240, 200)
  rightColumn:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 180, -50)

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

  -- Add "Get Jervaise Plater Profile" button below the bear image
  local profileButton = CreateFrame("Button", "DotMasterPlaterProfileButton", leftColumn, "UIPanelButtonTemplate")
  profileButton:SetSize(130, 22)
  profileButton:SetPoint("TOP", imageBorder, "BOTTOM", 0, -10)
  profileButton:SetText("Get Plater Profile")

  -- Add class color to the button
  if classColor then
    local normalTexture = profileButton:GetNormalTexture()
    if normalTexture then
      normalTexture:SetVertexColor(
        classColor.r * 0.7 + 0.3,
        classColor.g * 0.7 + 0.3,
        classColor.b * 0.7 + 0.3
      )
    end
  end

  -- Create Profile URL Popup function
  local function ShowProfileURLPopup()
    -- Create or get the popup frame
    if not DM.PlaterProfilePopup then
      local popup = CreateFrame("Frame", "DotMasterPlaterProfilePopup", UIParent, "BackdropTemplate")
      popup:SetSize(400, 150)
      popup:SetPoint("CENTER")
      popup:SetFrameStrata("DIALOG")
      popup:SetMovable(true)
      popup:EnableMouse(true)
      popup:RegisterForDrag("LeftButton")
      popup:SetScript("OnDragStart", popup.StartMoving)
      popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
      popup:Hide()

      -- Add backdrop
      popup:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
      })
      popup:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
      popup:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

      -- Title
      local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      title:SetPoint("TOP", 0, -16)
      title:SetText("Jervaise Plater Profile")
      title:SetTextColor(1, 0.82, 0) -- WoW Gold

      -- Instructions
      local instructions = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
      instructions:SetText("Copy the URL below to import the recommended Plater profile:")
      instructions:SetTextColor(0.9, 0.9, 0.9)

      -- Create editbox for URL
      local editBox = CreateFrame("EditBox", "DotMasterProfileURLEditBox", popup, "InputBoxTemplate")
      editBox:SetSize(350, 20)
      editBox:SetPoint("TOP", instructions, "BOTTOM", 0, -15)
      editBox:SetAutoFocus(false)
      editBox:SetText("https://wago.io/wYmUzrWb5")
      editBox:SetScript("OnEscapePressed", function() popup:Hide() end)
      editBox:SetScript("OnEnterPressed", function() editBox:HighlightText() end)
      editBox:SetScript("OnShow", function()
        C_Timer.After(0.1, function() editBox:HighlightText() end)
      end)

      -- Close button
      local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
      closeButton:SetPoint("TOPRIGHT", -3, -3)
      closeButton:SetSize(26, 26)

      -- Done button
      local doneButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
      doneButton:SetSize(80, 22)
      doneButton:SetPoint("BOTTOM", 0, 15)
      doneButton:SetText("Done")
      doneButton:SetScript("OnClick", function() popup:Hide() end)

      DM.PlaterProfilePopup = popup
    end

    DM.PlaterProfilePopup:Show()
  end

  -- Set the button's click handler
  profileButton:SetScript("OnClick", ShowProfileURLPopup)

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

  -- Add General Settings header/separator
  local generalHeaderContainer = CreateFrame("Frame", nil, rightColumn)
  generalHeaderContainer:SetSize(240, 24)
  generalHeaderContainer:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, 0)

  -- Create general header text
  local generalHeaderText = generalHeaderContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  generalHeaderText:SetPoint("LEFT", generalHeaderContainer, "LEFT", 2, 0)
  generalHeaderText:SetText("General Settings")
  generalHeaderText:SetTextColor(0.7, 0.7, 0.7)

  -- Add separator line
  local generalSeparator = generalHeaderContainer:CreateTexture(nil, "ARTWORK")
  generalSeparator:SetHeight(1)
  generalSeparator:SetPoint("LEFT", generalHeaderText, "RIGHT", 5, 0)
  generalSeparator:SetPoint("RIGHT", generalHeaderContainer, "RIGHT", -5, 0)
  generalSeparator:SetColorTexture(0.4, 0.4, 0.4, 0.6)

  -- Create settings checkboxes in the right column
  local enableCheckbox = CreateStyledCheckbox("DotMasterEnableCheckbox",
    rightColumn, generalHeaderContainer, -3, "Enable DotMaster")
  enableCheckbox:SetChecked(settings.enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()

    -- Update DotMaster addon state
    DM.enabled = enabled

    -- Force-save directly to DotMasterDB
    if DotMasterDB ~= nil then
      DotMasterDB.enabled = enabled
    end

    -- Call the API function to update Plater
    DM.API:EnableAddon(enabled)

    -- AutoSave for serialization
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
    end

    -- AutoSave for serialization
    DM:AutoSave()

    -- Reinstall Plater mod to ensure changes take effect
    if settings.enabled and Plater and DM.PlaterIntegration then
      print("DotMaster: Reinstalling Plater mod due to Force Color setting change")
      DM.PlaterIntegration:InstallPlaterMod()
    end
  end)

  -- Flash checkbox
  local flashingCheckbox = CreateStyledCheckbox("DotMasterFlashingCheckbox",
    rightColumn, forceColorCheckbox, -3, "Expiry Flash")
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
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.flashThresholdSeconds = settings
            .flashThresholdSeconds
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
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.flashThresholdSeconds = settings
            .flashThresholdSeconds
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
    end

    -- Show/hide seconds container
    if secondsContainer then
      if flashExpiring then
        secondsContainer:Show()
      else
        secondsContainer:Hide()
      end
    end

    -- AutoSave for serialization
    DM:AutoSave()
  end)

  -- Add Border Logic header/separator
  local borderHeaderContainer = CreateFrame("Frame", nil, rightColumn)
  borderHeaderContainer:SetSize(240, 24)
  borderHeaderContainer:SetPoint("TOPLEFT", flashingCheckbox, "BOTTOMLEFT", 0, -8)

  -- Create border header text
  local borderHeaderText = borderHeaderContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  borderHeaderText:SetPoint("LEFT", borderHeaderContainer, "LEFT", 2, 0)
  borderHeaderText:SetText("Border Logic")
  borderHeaderText:SetTextColor(0.7, 0.7, 0.7)

  -- Add separator line
  local borderSeparator = borderHeaderContainer:CreateTexture(nil, "ARTWORK")
  borderSeparator:SetHeight(1)
  borderSeparator:SetPoint("LEFT", borderHeaderText, "RIGHT", 5, 0)
  borderSeparator:SetPoint("RIGHT", borderHeaderContainer, "RIGHT", -5, 0)
  borderSeparator:SetColorTexture(0.4, 0.4, 0.4, 0.6)

  -- Create a checkbox for extending Plater colors to borders
  local extendColorsCheckbox = CreateStyledCheckbox("DotMasterExtendColorsCheckbox",
    rightColumn, borderHeaderContainer, -3, "Extend Plater Colors to Borders")
  extendColorsCheckbox:SetChecked(settings.extendPlaterColors)

  -- Create a checkbox for border-only mode
  local borderOnlyCheckbox = CreateStyledCheckbox("DotMasterBorderOnlyCheckbox",
    rightColumn, extendColorsCheckbox, -3, "Use Borders for DoT Tracking")
  borderOnlyCheckbox:SetChecked(settings.borderOnly)

  -- Set up click handlers for mutual exclusivity
  extendColorsCheckbox:SetScript("OnClick", function(self)
    -- Get the checked state
    local extendColors = self:GetChecked()

    -- Update settings
    settings.extendPlaterColors = extendColors

    -- Save settings
    if DotMasterDB ~= nil then
      if not DotMasterDB.settings then DotMasterDB.settings = {} end
      DotMasterDB.settings.extendPlaterColors = extendColors
    end

    -- If this option is enabled, disable the other option (they're mutually exclusive)
    if extendColors and borderOnlyCheckbox then
      borderOnlyCheckbox:SetChecked(false)
      settings.borderOnly = false
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderOnly = false
      end
    end

    -- AutoSave for serialization
    DM:AutoSave()

    -- Reinstall Plater mod to ensure changes take effect
    if settings.enabled and Plater and DM.PlaterIntegration then
      print("DotMaster: Reinstalling Plater mod due to Extend Colors setting change")
      DM.PlaterIntegration:InstallPlaterMod()
    end
  end)

  -- Set up border checkbox click handler
  borderOnlyCheckbox:SetScript("OnClick", function(self)
    -- Get the checked state
    local borderOnly = self:GetChecked()

    -- Update settings
    settings.borderOnly = borderOnly

    -- Save settings
    if DotMasterDB ~= nil then
      if not DotMasterDB.settings then DotMasterDB.settings = {} end
      DotMasterDB.settings.borderOnly = borderOnly
    end

    -- If this option is enabled, disable the other option (they're mutually exclusive)
    if borderOnly and extendColorsCheckbox then
      extendColorsCheckbox:SetChecked(false)
      settings.extendPlaterColors = false
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.extendPlaterColors = false
      end
    end

    -- AutoSave for serialization
    DM:AutoSave()

    -- Reinstall Plater mod to ensure changes take effect
    if settings.enabled and Plater and DM.PlaterIntegration then
      print("DotMaster: Reinstalling Plater mod due to Border Only setting change")
      DM.PlaterIntegration:InstallPlaterMod()
    end
  end)

  -- Border thickness control
  if settings.borderThickness == nil then settings.borderThickness = 2 end
  local thicknessContainer = CreateFrame("Frame", nil, rightColumn)
  thicknessContainer:SetSize(240, 26)
  thicknessContainer:SetPoint("TOPLEFT", borderOnlyCheckbox, "BOTTOMLEFT", 0, -3)

  -- Thickness label
  local thicknessLabel = thicknessContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  thicknessLabel:SetPoint("LEFT", thicknessContainer, "LEFT", 26, 0)
  thicknessLabel:SetText("Border Thickness:")
  thicknessLabel:SetTextColor(0.8, 0.8, 0.8)

  -- Value container
  local thicknessValueContainer = CreateFrame("Frame", nil, thicknessContainer)
  thicknessValueContainer:SetSize(30, 26)
  thicknessValueContainer:SetPoint("LEFT", thicknessLabel, "RIGHT", 5, 0)

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

      -- Force-save the borderThickness to DotMasterDB immediately
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderThickness = newValue
      end

      -- Use AutoSave instead of direct SaveSettings
      DM:AutoSave()

      -- Ensure the change is tracked for reload popup when GUI closes
      DM:TrackBorderThicknessChange()
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

      -- Force-save the borderThickness to DotMasterDB immediately
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderThickness = newValue
      end

      -- Use AutoSave instead of direct SaveSettings
      DM:AutoSave()

      -- Ensure the change is tracked for reload popup when GUI closes
      DM:TrackBorderThicknessChange()
    end
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
