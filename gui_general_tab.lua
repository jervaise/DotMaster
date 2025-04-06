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
    "Colors Plater enemy nameplates\nTracks all your damage-over-time effects in one place\nWorks with any class and specialization"
  )

  -- ===== NEW MODERN UI DESIGN BEGINS HERE =====

  -- Create a styled content panel with border
  local contentPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  contentPanel:SetSize(410, 420) -- Reduced height from 450 to 420 (30px less)
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
  imagePanel:SetSize(150, 170) -- Increased from 150x150 to 150x170 to fit the checkbox area
  imagePanel:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 30, -25)

  -- Add panda image with a subtle border
  local imageBorder = CreateFrame("Frame", nil, imagePanel, "BackdropTemplate")
  imageBorder:SetSize(140, 140) -- Increased from 128x128 to 140x140
  imageBorder:SetPoint("CENTER", imagePanel, "CENTER")
  imageBorder:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
  })
  imageBorder:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.6)

  local pandaImage = imageBorder:CreateTexture(nil, "ARTWORK")
  pandaImage:SetSize(120, 120) -- Increased from 110x110 to 120x120
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

  -- Get settings from API
  local settings = DM.API:GetSettings()

  -- Create the main feature checkbox
  local enableCheckbox = CreateStyledCheckbox("DotMasterEnableCheckbox",
    checkboxContainer, nil, 0, "Enable DotMaster")
  enableCheckbox:SetChecked(settings.enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()
    DM.API:EnableAddon(enabled)
    DM:PrintMessage(enabled and "Enabled" or "Disabled")

    -- Update settings
    settings.enabled = enabled
    DM.API:SaveSettings(settings)
  end)

  -- Create minimap checkbox
  local minimapCheckbox = CreateStyledCheckbox("DotMasterMinimapCheckbox",
    checkboxContainer, enableCheckbox, -4, "Show Minimap Icon")
  minimapCheckbox:SetChecked(not (settings.minimapIcon and settings.minimapIcon.hide))
  minimapCheckbox:SetScript("OnClick", function(self)
    local showIcon = self:GetChecked()

    -- Update settings
    if not settings.minimapIcon then settings.minimapIcon = {} end
    settings.minimapIcon.hide = not showIcon
    DM.API:SaveSettings(settings)

    -- Toggle minimap icon if LibDBIcon is available
    local LibDBIcon = LibStub("LibDBIcon-1.0")
    if LibDBIcon then
      if settings.minimapIcon.hide then
        LibDBIcon:Hide("DotMaster")
      else
        LibDBIcon:Show("DotMaster")
      end
    end
  end)

  -- Create force threat color checkbox
  local forceColorCheckbox = CreateStyledCheckbox("DotMasterForceColorCheckbox",
    checkboxContainer, minimapCheckbox, -4, "Force Threat Color")
  forceColorCheckbox:SetChecked(settings.forceColor)
  forceColorCheckbox:SetScript("OnClick", function(self)
    local forceColor = self:GetChecked()

    -- Update settings
    settings.forceColor = forceColor
    DM.API:SaveSettings(settings)

    DM:PrintMessage("Force Threat Color " .. (forceColor and "Enabled" or "Disabled"))
  end)

  -- Create border-only checkbox and thickness control together
  local borderOnlyCheckbox = CreateStyledCheckbox("DotMasterBorderOnlyCheckbox",
    checkboxContainer, forceColorCheckbox, -4, "Border-only")
  borderOnlyCheckbox:SetChecked(settings.borderOnly)

  -- Initialize thickness value if needed
  if settings.borderThickness == nil then settings.borderThickness = 2 end

  -- Create a compact thickness control next to the border-only checkbox
  local thicknessContainer = CreateFrame("Frame", nil, checkboxContainer)
  thicknessContainer:SetSize(70, 26)
  thicknessContainer:SetPoint("LEFT", borderOnlyCheckbox.labelText, "RIGHT", 10, 0)

  -- Create a fixed-width container for the value to prevent button movement
  local thicknessValueContainer = CreateFrame("Frame", nil, thicknessContainer)
  thicknessValueContainer:SetSize(30, 26)
  thicknessValueContainer:SetPoint("LEFT", thicknessContainer, "LEFT", 0, 0)

  -- Create the thickness value display
  local thicknessValue = thicknessValueContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  thicknessValue:SetPoint("RIGHT", thicknessValueContainer, "RIGHT", 0, 0)
  thicknessValue:SetJustifyH("RIGHT")
  thicknessValue:SetText(settings.borderThickness .. " px")

  -- Create decrease button with fixed position
  local decreaseButton = CreateFrame("Button", nil, thicknessContainer)
  decreaseButton:SetSize(16, 16)
  decreaseButton:SetPoint("LEFT", thicknessValueContainer, "RIGHT", 2, 0)
  decreaseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  decreaseButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
  decreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  decreaseButton:SetScript("OnClick", function()
    if settings.borderThickness > 1 then
      settings.borderThickness = settings.borderThickness - 1
      thicknessValue:SetText(settings.borderThickness .. " px")
      if settings.enabled then
        DM:UpdateAllNameplates()
      end
      DM.API:SaveSettings(settings)
    end
  end)

  -- Create increase button with fixed position
  local increaseButton = CreateFrame("Button", nil, thicknessContainer)
  increaseButton:SetSize(16, 16)
  increaseButton:SetPoint("LEFT", decreaseButton, "RIGHT", 2, 0)
  increaseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
  increaseButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
  increaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  increaseButton:SetScript("OnClick", function()
    if settings.borderThickness < 4 then
      settings.borderThickness = settings.borderThickness + 1
      thicknessValue:SetText(settings.borderThickness .. " px")
      if settings.enabled then
        DM:UpdateAllNameplates()
      end
      DM.API:SaveSettings(settings)
    end
  end)

  -- Initially hide or show the thickness control based on checkbox state
  if settings.borderOnly then
    thicknessContainer:Show()
  else
    thicknessContainer:Hide()
  end

  -- Set up the border-only checkbox handler
  borderOnlyCheckbox:SetScript("OnClick", function(self)
    local borderOnly = self:GetChecked()
    DM:PrintMessage("Border-only " .. (borderOnly and "Enabled" or "Disabled"))

    -- Show/hide the thickness control based on checkbox state
    if thicknessContainer then
      if borderOnly then
        thicknessContainer:Show()
      else
        thicknessContainer:Hide()
      end
    end

    -- Update settings
    settings.borderOnly = borderOnly
    DM.API:SaveSettings(settings)

    if settings.enabled then
      DM:UpdateAllNameplates()
    end
  end)

  -- Create flashing checkbox and seconds control together
  local flashingCheckbox = CreateStyledCheckbox("DotMasterFlashingCheckbox",
    checkboxContainer, borderOnlyCheckbox, -4, "Expiry Flash") -- Changed from -5 to -4
  flashingCheckbox:SetChecked(settings.flashExpiring)

  -- Create a container for the seconds input
  local secondsContainer = CreateFrame("Frame", nil, checkboxContainer)
  secondsContainer:SetSize(70, 26)
  secondsContainer:SetPoint("LEFT", flashingCheckbox.labelText, "RIGHT", 10, 0)

  -- Create a fixed-width container for the value to prevent button movement
  local secondsValueContainer = CreateFrame("Frame", nil, secondsContainer)
  secondsValueContainer:SetSize(30, 26)
  secondsValueContainer:SetPoint("LEFT", secondsContainer, "LEFT", 0, 0)

  -- Create the seconds value display
  local secondsValue = secondsValueContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  secondsValue:SetPoint("RIGHT", secondsValueContainer, "RIGHT", 0, 0)
  secondsValue:SetJustifyH("RIGHT")
  secondsValue:SetText(settings.flashThresholdSeconds .. " s")

  -- Create decrease button for seconds with fixed position
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
      DM.API:SaveSettings(settings)
    end
  end)

  -- Create increase button for seconds with fixed position
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
      DM.API:SaveSettings(settings)
    end
  end)

  -- Initially hide or show the seconds control based on checkbox state
  if settings.flashExpiring then
    secondsContainer:Show()
  else
    secondsContainer:Hide()
  end

  -- Set up the flashing checkbox handler
  flashingCheckbox:SetScript("OnClick", function(self)
    local flashExpiring = self:GetChecked()
    DM:PrintMessage("Expiry Flash " .. (flashExpiring and "Enabled" or "Disabled"))

    -- Show/hide the seconds control based on checkbox state
    if secondsContainer then
      if flashExpiring then
        secondsContainer:Show()
      else
        secondsContainer:Hide()
      end
    end

    -- Update settings
    settings.flashExpiring = flashExpiring
    DM.API:SaveSettings(settings)
  end)

  -- Create a second area for information about the addon in a nice box
  local infoBox = CreateFrame("Frame", nil, contentPanel, "BackdropTemplate")
  infoBox:SetSize(370, 140)
  infoBox:SetPoint("TOP", contentPanel, "TOP", 0, -200)
  infoBox:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  infoBox:SetBackdropColor(0.1, 0.1, 0.1, 0.5)       -- Even more transparent than the main panel
  infoBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6) -- Subtle border

  -- Create info box title with decoration
  local infoBoxTitle = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoBoxTitle:SetPoint("TOP", infoBox, "TOP", 0, -10)
  infoBoxTitle:SetText("How to use DotMaster")
  infoBoxTitle:SetTextColor(1, 0.82, 0) -- WoW Gold for titles

  -- Add information text with better formatting
  local infoText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  infoText:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 20, -30)
  infoText:SetPoint("BOTTOMRIGHT", infoBox, "BOTTOMRIGHT", -20, 10)
  infoText:SetJustifyH("LEFT")
  infoText:SetJustifyV("TOP")
  infoText:SetSpacing(4) -- Add line spacing for better readability
  infoText:SetText(
    "1. Go to the Tracked Spells tab to add your DoTs\n" ..
    "2. Set colors for each spell by clicking on the colored box\n" ..
    "3. Set priorities to determine which color is shown when\n    multiple DoTs are active on the same target\n" ..
    "4. You can create spell combinations in the Combinations tab\n" ..
    "5. Use /dm to toggle this window, /dm on or /dm off to enable/disable"
  )

  -- Create a command list section at the bottom
  local commandsTitle = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  commandsTitle:SetPoint("TOP", infoBox, "BOTTOM", 0, -15)
  commandsTitle:SetText("Slash Commands")
  commandsTitle:SetTextColor(classColor.r, classColor.g, classColor.b)

  local commandsText = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  commandsText:SetPoint("TOP", commandsTitle, "BOTTOM", 0, -5)
  commandsText:SetWidth(370)
  commandsText:SetJustifyH("CENTER")
  commandsText:SetText(
    "/dm - Toggle this window\n" ..
    "/dm on - Enable the addon\n" ..
    "/dm off - Disable the addon\n" ..
    "/dmdebug - Show the debug console"
  )

  -- Register special event to fix broken checkbox text when moving between zones
  -- Only restore after zone changes to avoid unnecessary text setting
  local eventFrame = CreateFrame("Frame")
  eventFrame:RegisterEvent("ZONE_CHANGED")
  eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  eventFrame:SetScript("OnEvent", function()
    C_Timer.After(0.5, RestoreCheckboxTexts)
  end)

  return parent
end
