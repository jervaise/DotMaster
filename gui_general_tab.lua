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
    edgeFile = nil, -- Removed border edge file
    edgeSize = 0,   -- Set edge size to 0
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  contentPanel:SetBackdropColor(0, 0, 0, 0.7) -- Changed to match tab background color (darker)
  -- contentPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8) -- Removed border color setting since there's no border

  -- Title for the panel
  local configTitle = contentPanel:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
  configTitle:SetPoint("TOP", contentPanel, "TOP", 0, -15)

  -- Get current class and spec
  local currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
  local specName = currentSpecID and select(2, GetSpecializationInfoByID(currentSpecID)) or "Unknown"

  -- Format the title with class/spec info
  configTitle:SetText("Configuration - " .. currentClass .. " (" .. specName .. ")")
  configTitle:SetTextColor(classColor.r, classColor.g, classColor.b)

  -- Define layout constants
  local V_PADDING_BELOW_CONFIG_TITLE = 30
  local LEFT_MARGIN_PANEL = 20
  local RIGHT_MARGIN_PANEL = 20
  local INTER_COLUMN_SPACING = 15
  local LEFT_COLUMN_WIDTH = 140
  local COLUMN_CONTENT_HEIGHT = 280 -- Estimated height for column content area

  -- Calculate starting Y offset for columns, below configTitle
  -- Note: configTitle:GetHeight() can be small before text is set, so use a fixed estimate or ensure text is set first.
  -- For simplicity here, assuming configTitle height + padding is roughly 30-35px.
  -- A more robust way would be to get height after text set, or use fixed offsets known from design.
  local columnTopY = -((configTitle:GetStringHeight() or 16) + V_PADDING_BELOW_CONFIG_TITLE)

  -- Left column
  local leftColumn = CreateFrame("Frame", nil, contentPanel)
  leftColumn:SetSize(LEFT_COLUMN_WIDTH, COLUMN_CONTENT_HEIGHT)
  leftColumn:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", LEFT_MARGIN_PANEL, columnTopY)

  -- Right column
  local availableWidthForRightColumn = contentPanel:GetWidth() - LEFT_MARGIN_PANEL - LEFT_COLUMN_WIDTH -
      INTER_COLUMN_SPACING - RIGHT_MARGIN_PANEL
  local rightColumn = CreateFrame("Frame", nil, contentPanel)
  rightColumn:SetSize(availableWidthForRightColumn, COLUMN_CONTENT_HEIGHT)
  rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", INTER_COLUMN_SPACING, 0) -- Vertically align with leftColumn's top

  -- Panda image (Content for leftColumn)
  local pandaImage = leftColumn:CreateTexture(nil, "ARTWORK")
  pandaImage:SetSize(128, 128)
  pandaImage:SetPoint("TOP", leftColumn, "TOP", 0, -5) -- 5px padding from top of leftColumn
  pandaImage:SetTexture("Interface\\AddOns\\DotMaster\\Media\\dotmaster-main-icon.tga")

  -- Descriptive text for Jervaise Plater Profile button
  local profileDescription = leftColumn:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormalSmall"))
  profileDescription:SetText(
    "For the best experience, install the Jervaise Plater Profile. It includes predefined M+ nameplate colors for casters & important mobs.")
  profileDescription:SetTextColor(0.8, 0.8, 0.8, 0.9) -- Light grey, slightly transparent
  profileDescription:SetJustifyH("CENTER")
  profileDescription:SetJustifyV("TOP")
  profileDescription:SetWidth(130)                                         -- Match the width of the image/button area
  profileDescription:SetPoint("TOPLEFT", pandaImage, "BOTTOMLEFT", 0, -10) -- Position below panda image

  -- "Get Jervaise Plater Profile" button below the description text
  local platerProfileButton = CreateFrame("Button", "DotMasterPlaterProfileButton", leftColumn, "UIPanelButtonTemplate")
  platerProfileButton:SetSize(130, 22)
  platerProfileButton:SetPoint("TOPLEFT", profileDescription, "BOTTOMLEFT", 0, -8) -- Position below description
  platerProfileButton:SetText("Jervaise Plater Profile")

  -- Add class color to the button
  if classColor then
    local normalTexture = platerProfileButton:GetNormalTexture()
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
      local title = popup:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormalLarge"))
      title:SetPoint("TOP", 0, -16)
      title:SetText("Jervaise Plater Profile")
      title:SetTextColor(1, 0.82, 0) -- WoW Gold

      -- Instructions
      local instructions = popup:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
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
  platerProfileButton:SetScript("OnClick", ShowProfileURLPopup)

  -- Get settings from API
  local settings = DM.API:GetSettings()
  if settings.flashThresholdSeconds == nil then
    settings.flashThresholdSeconds = 3 -- Default to 3 seconds if not set
  end

  -- Helper function to create styled checkboxes
  local function CreateStyledCheckbox(name, parent, relativeTo, yOffset, label)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)

    if relativeTo then
      checkbox:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, yOffset or -5)
    else
      checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -5)
    end

    -- Hide the default template text
    local defaultText = _G[checkbox:GetName() .. "Text"]
    if defaultText then defaultText:Hide() end

    -- Create our own text element
    local text = checkbox:CreateFontString(nil, "ARTWORK", DM:GetExpresswayFont("GameFontNormal"))
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText(label)
    text:SetTextColor(0.9, 0.9, 0.9)

    -- Store the text element reference
    checkbox.labelText = text

    -- Add tooltip functionality
    checkbox.tooltipText = ""
    checkbox:SetScript("OnEnter", function(self)
      if self.tooltipText and self.tooltipText ~= "" then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
        GameTooltip:Show()
      end
    end)

    checkbox:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    return checkbox
  end

  -- Add General Settings header/separator
  local generalHeaderContainer = CreateFrame("Frame", nil, rightColumn)
  generalHeaderContainer:SetSize(rightColumn:GetWidth() - 10, 24)           -- Use rightColumn's calculated width
  generalHeaderContainer:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, -5) -- 5px padding within rightColumn

  -- Create general header text
  local generalHeaderText = generalHeaderContainer:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontNormalSmall"))
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
  enableCheckbox.tooltipText = "Turn DotMaster on or off. When disabled, DotMaster will not track any DoTs."
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
  minimapCheckbox.tooltipText =
  "Show or hide the DotMaster icon on the minimap. You can still access DotMaster through slash commands when hidden."
  minimapCheckbox:SetScript("OnClick", function(self)
    local showIcon = self:GetChecked()
    DotMasterDB = DotMasterDB or {}
    DotMasterDB.minimap = DotMasterDB.minimap or {}
    DotMasterDB.minimap.hide = not showIcon

    -- Keep API settings in sync
    if not settings.minimapIcon then settings.minimapIcon = {} end
    settings.minimapIcon.hide = DotMasterDB.minimap.hide

    DM:AutoSave()

    -- Apply immediately
    if DM.ToggleMinimapIcon then
      DM:ToggleMinimapIcon()
    else
      local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
      if LibDBIcon then
        if DotMasterDB.minimap.hide then
          LibDBIcon:Hide("DotMaster")
        else
          LibDBIcon:Show("DotMaster")
        end
      end
    end
  end)

  local forceColorCheckbox = CreateStyledCheckbox("DotMasterForceColorCheckbox",
    rightColumn, minimapCheckbox, -3, "Force Threat Color")
  forceColorCheckbox:SetChecked(settings.forceColor)
  forceColorCheckbox.tooltipText =
  "Override Plater's color settings to always use threat colors, even when other features might change them."
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
  flashingCheckbox.tooltipText =
  "Flash nameplate borders when your DoTs are about to expire. Adjust the warning time with the controls to the right."

  -- Seconds control
  local secondsContainer = CreateFrame("Frame", nil, rightColumn)
  secondsContainer:SetSize(70, 26)
  secondsContainer:SetPoint("LEFT", flashingCheckbox.labelText, "RIGHT", 10, 0)

  -- Seconds value container
  local secondsValueContainer = CreateFrame("Frame", nil, secondsContainer)
  secondsValueContainer:SetSize(30, 26)
  secondsValueContainer:SetPoint("LEFT", secondsContainer, "LEFT", 0, 0)

  -- Seconds value display
  local secondsValue = secondsValueContainer:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontHighlightSmall"))
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
    secondsContainer:Show() -- Always show the seconds container
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

    -- Show/hide flash customization sliders
    if flashFrequencySlider and flashBrightnessSlider then
      -- Always show sliders regardless of flashExpiring state
      flashFrequencySlider:Show()
      flashBrightnessSlider:Show()
    end

    -- Always show seconds container
    if secondsContainer then
      secondsContainer:Show()
    end

    -- AutoSave for serialization
    DM:AutoSave()
  end)

  -- Create Flash Frequency Slider
  local flashFrequencySlider = CreateFrame("Slider", "DotMasterFlashFrequencySlider", rightColumn,
    "OptionsSliderTemplate")
  flashFrequencySlider:SetWidth(85)
  flashFrequencySlider:SetHeight(16)
  flashFrequencySlider:SetPoint("TOPLEFT", flashingCheckbox, "BOTTOMLEFT", 20, -20)
  flashFrequencySlider:SetOrientation("HORIZONTAL")
  flashFrequencySlider:SetMinMaxValues(0.1, 1.0)
  flashFrequencySlider:SetValueStep(0.1)
  flashFrequencySlider:SetObeyStepOnDrag(true)
  flashFrequencySlider:SetValue(settings.flashFrequency or 0.5)

  -- Set slider text
  _G[flashFrequencySlider:GetName() .. "Text"]:SetText("Interval")
  _G[flashFrequencySlider:GetName() .. "Low"]:SetText("")
  _G[flashFrequencySlider:GetName() .. "High"]:SetText("")

  -- Create value text
  local flashFrequencyValue = flashFrequencySlider:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontHighlightSmall"))
  flashFrequencyValue:SetPoint("TOP", flashFrequencySlider, "BOTTOM", 0, 0)
  flashFrequencyValue:SetText(string.format("%.1f s", settings.flashFrequency or 0.5))

  -- Handle slider changes
  flashFrequencySlider:SetScript("OnValueChanged", function(self, value)
    -- Round to nearest 0.1
    value = math.floor(value * 10 + 0.5) / 10

    -- Update value text
    flashFrequencyValue:SetText(string.format("%.1f s", value))

    -- Update settings
    settings.flashFrequency = value

    -- Update database
    if DotMasterDB and DotMasterDB.settings then
      DotMasterDB.settings.flashFrequency = value
    end

    -- Save settings
    DM:AutoSave()
  end)

  -- Create Flash Brightness Slider
  local flashBrightnessSlider = CreateFrame("Slider", "DotMasterFlashBrightnessSlider", rightColumn,
    "OptionsSliderTemplate")
  flashBrightnessSlider:SetWidth(85)
  flashBrightnessSlider:SetHeight(16)
  flashBrightnessSlider:SetPoint("LEFT", flashFrequencySlider, "RIGHT", 10, 0)
  flashBrightnessSlider:SetOrientation("HORIZONTAL")
  flashBrightnessSlider:SetMinMaxValues(0.2, 1.0)
  flashBrightnessSlider:SetValueStep(0.1)
  flashBrightnessSlider:SetObeyStepOnDrag(true)
  flashBrightnessSlider:SetValue(settings.flashBrightness or 0.3)

  -- Set slider text
  _G[flashBrightnessSlider:GetName() .. "Text"]:SetText("Brightness")
  _G[flashBrightnessSlider:GetName() .. "Low"]:SetText("")
  _G[flashBrightnessSlider:GetName() .. "High"]:SetText("")

  -- Create value text
  local flashBrightnessValue = flashBrightnessSlider:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontHighlightSmall"))
  flashBrightnessValue:SetPoint("TOP", flashBrightnessSlider, "BOTTOM", 0, 0)
  flashBrightnessValue:SetText(string.format("%d%%", math.floor((settings.flashBrightness or 0.3) * 100)))

  -- Handle slider changes
  flashBrightnessSlider:SetScript("OnValueChanged", function(self, value)
    -- Round to nearest 0.1
    value = math.floor(value * 10 + 0.5) / 10

    -- Update value text
    flashBrightnessValue:SetText(string.format("%d%%", math.floor(value * 100)))

    -- Update settings
    settings.flashBrightness = value

    -- Update database
    if DotMasterDB and DotMasterDB.settings then
      DotMasterDB.settings.flashBrightness = value
    end

    -- Save settings
    DM:AutoSave()
  end)

  -- Do not initially hide sliders (always show them)
  -- if not settings.flashExpiring then
  --   flashFrequencySlider:Hide()
  --   flashBrightnessSlider:Hide()
  -- end

  -- Add Border Logic header/separator
  local borderHeaderContainer = CreateFrame("Frame", nil, rightColumn)
  borderHeaderContainer:SetSize(240, 24)
  borderHeaderContainer:SetPoint("TOPLEFT", flashFrequencySlider, "BOTTOMLEFT", -20, -15)

  -- Create border header text
  local borderHeaderText = borderHeaderContainer:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontNormalSmall"))
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
  extendColorsCheckbox.tooltipText =
  "Preserve Plater profile colors for caster/important mobs in borders while tracking DoTs. Exclusive with 'Use Borders for DoT Tracking'."

  -- Create a checkbox for border-only mode
  local borderOnlyCheckbox = CreateStyledCheckbox("DotMasterBorderOnlyCheckbox",
    rightColumn, extendColorsCheckbox, -3, "Use Borders for DoT Tracking")
  borderOnlyCheckbox:SetChecked(settings.borderOnly)
  borderOnlyCheckbox.tooltipText =
  "Use only the border color to indicate DoT status. Keeps Plater's original health bar colors. Cannot be used with 'Extend Plater Colors'."

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
    DM:TrackCriticalSettingsChange()

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
    DM:TrackCriticalSettingsChange()

    -- Reinstall Plater mod to ensure changes take effect
    if settings.enabled and Plater and DM.PlaterIntegration then
      print("DotMaster: Reinstalling Plater mod due to Border Only setting change")
      DM.PlaterIntegration:InstallPlaterMod()
    end
  end)

  -- Border thickness control
  if settings.borderThickness == nil then settings.borderThickness = 2.0 end
  local thicknessContainer = CreateFrame("Frame", nil, rightColumn)
  thicknessContainer:SetSize(240, 26)
  thicknessContainer:SetPoint("TOPLEFT", borderOnlyCheckbox, "BOTTOMLEFT", 0, -3)

  -- Thickness label
  local thicknessLabel = thicknessContainer:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontHighlightSmall"))
  thicknessLabel:SetPoint("LEFT", thicknessContainer, "LEFT", 26, 0)
  thicknessLabel:SetText("Border Thickness:")
  thicknessLabel:SetTextColor(0.8, 0.8, 0.8)

  -- Value container
  local thicknessValueContainer = CreateFrame("Frame", nil, thicknessContainer)
  thicknessValueContainer:SetSize(40, 26) -- Increased width for decimal display
  thicknessValueContainer:SetPoint("LEFT", thicknessLabel, "RIGHT", 5, 0)

  -- Format thickness value with one decimal place
  local function formatThickness(value)
    return string.format("%.1f px", value)
  end

  -- Thickness value display
  local thicknessValue = thicknessValueContainer:CreateFontString(nil, "OVERLAY",
    DM:GetExpresswayFont("GameFontHighlightSmall"))
  thicknessValue:SetPoint("RIGHT", thicknessValueContainer, "RIGHT", 0, 0)
  thicknessValue:SetJustifyH("RIGHT")
  thicknessValue:SetText(formatThickness(settings.borderThickness))

  -- Decrease button
  local decreaseButton = CreateFrame("Button", nil, thicknessContainer)
  decreaseButton:SetSize(16, 16)
  decreaseButton:SetPoint("LEFT", thicknessValueContainer, "RIGHT", 2, 0)
  decreaseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  decreaseButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
  decreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  decreaseButton:SetScript("OnClick", function()
    if settings.borderThickness > 1.0 then
      -- Decrement the thickness value by 0.1
      local oldValue = settings.borderThickness
      settings.borderThickness = math.max(1.0, math.floor((settings.borderThickness - 0.1) * 10 + 0.5) / 10)
      local newValue = settings.borderThickness

      -- Update the display
      thicknessValue:SetText(formatThickness(settings.borderThickness))

      -- Force-save the borderThickness to DotMasterDB immediately
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderThickness = newValue
      end

      -- Use AutoSave instead of direct SaveSettings
      DM:AutoSave()

      -- Ensure the change is tracked for reload popup when GUI closes
      DM:TrackCriticalSettingsChange()
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
    if settings.borderThickness < 5.0 then
      -- Increment the thickness value by 0.1
      local oldValue = settings.borderThickness
      settings.borderThickness = math.min(5.0, math.floor((settings.borderThickness + 0.1) * 10 + 0.5) / 10)
      local newValue = settings.borderThickness

      -- Update the display
      thicknessValue:SetText(formatThickness(settings.borderThickness))

      -- Force-save the borderThickness to DotMasterDB immediately
      if DotMasterDB and DotMasterDB.settings then
        DotMasterDB.settings.borderThickness = newValue
      end

      -- Use AutoSave instead of direct SaveSettings
      DM:AutoSave()

      -- Ensure the change is tracked for reload popup when GUI closes
      DM:TrackCriticalSettingsChange()
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
