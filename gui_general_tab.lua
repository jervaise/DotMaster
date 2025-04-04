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
  contentPanel:SetSize(410, 450) -- Increased height from 350 to 450
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
    checkboxContainer, enableCheckbox, -8, "Show Minimap Icon")
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
    checkboxContainer, minimapCheckbox, -8, "Force Threat Color")
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

  -- Create border-only checkbox and thickness control together
  local borderOnlyCheckbox = CreateStyledCheckbox("DotMasterBorderOnlyCheckbox",
    checkboxContainer, forceColorCheckbox, -8, "Border-only")
  if DM.settings.borderOnly == nil then DM.settings.borderOnly = false end
  borderOnlyCheckbox:SetChecked(DM.settings.borderOnly)

  -- Initialize thickness value if needed
  if DM.settings.borderThickness == nil then DM.settings.borderThickness = 2 end

  -- Create a compact thickness control next to the border-only checkbox
  local thicknessContainer = CreateFrame("Frame", nil, checkboxContainer)
  thicknessContainer:SetSize(70, 26)
  thicknessContainer:SetPoint("LEFT", borderOnlyCheckbox.labelText, "RIGHT", 10, 0)

  -- Create the thickness value display
  local thicknessValue = thicknessContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  thicknessValue:SetPoint("LEFT", thicknessContainer, "LEFT", 0, 0)
  thicknessValue:SetText(DM.settings.borderThickness .. " px")

  -- Create decrease button
  local decreaseButton = CreateFrame("Button", nil, thicknessContainer)
  decreaseButton:SetSize(18, 18)
  decreaseButton:SetPoint("LEFT", thicknessValue, "RIGHT", 2, 0)
  decreaseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  decreaseButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
  decreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  decreaseButton:SetScript("OnClick", function()
    if DM.settings.borderThickness > 1 then
      DM.settings.borderThickness = DM.settings.borderThickness - 1
      thicknessValue:SetText(DM.settings.borderThickness .. " px")
      if DM.enabled then
        DM:UpdateAllNameplates()
      end
      DM:SaveSettings()
    end
  end)

  -- Create increase button
  local increaseButton = CreateFrame("Button", nil, thicknessContainer)
  increaseButton:SetSize(18, 18)
  increaseButton:SetPoint("LEFT", decreaseButton, "RIGHT", 2, 0)
  increaseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
  increaseButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
  increaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  increaseButton:SetScript("OnClick", function()
    if DM.settings.borderThickness < 4 then
      DM.settings.borderThickness = DM.settings.borderThickness + 1
      thicknessValue:SetText(DM.settings.borderThickness .. " px")
      if DM.enabled then
        DM:UpdateAllNameplates()
      end
      DM:SaveSettings()
    end
  end)

  -- Make sure texture is shown properly
  local decreaseTexture = decreaseButton:GetNormalTexture()
  local increaseTexture = increaseButton:GetNormalTexture()
  if decreaseTexture then decreaseTexture:SetTexCoord(0, 1, 0, 1) end
  if increaseTexture then increaseTexture:SetTexCoord(0, 1, 0, 1) end

  -- Initially hide or show the thickness control based on checkbox state
  if DM.settings.borderOnly then
    thicknessContainer:Show()
  else
    thicknessContainer:Hide()
  end

  -- Add flashing checkbox
  local flashingCheckbox = CreateStyledCheckbox("DotMasterFlashingCheckbox",
    checkboxContainer, borderOnlyCheckbox, -8, "Expiry Flash")
  if DM.settings.flashExpiring == nil then DM.settings.flashExpiring = false end
  flashingCheckbox:SetChecked(DM.settings.flashExpiring)

  -- Create a container for the seconds input
  local secondsContainer = CreateFrame("Frame", nil, checkboxContainer)
  secondsContainer:SetSize(70, 26)
  secondsContainer:SetPoint("LEFT", flashingCheckbox.labelText, "RIGHT", 10, 0)

  -- Create the seconds input display
  local secondsValue = secondsContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  secondsValue:SetPoint("LEFT", secondsContainer, "LEFT", 0, 0)
  secondsValue:SetText(DM.settings.flashThresholdSeconds .. " s")

  -- Create decrease button for seconds
  local secondsDecreaseButton = CreateFrame("Button", nil, secondsContainer)
  secondsDecreaseButton:SetSize(18, 18)
  secondsDecreaseButton:SetPoint("LEFT", secondsValue, "RIGHT", 2, 0)
  secondsDecreaseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
  secondsDecreaseButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
  secondsDecreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  secondsDecreaseButton:SetScript("OnClick", function()
    if DM.settings.flashThresholdSeconds > 1 then
      DM.settings.flashThresholdSeconds = DM.settings.flashThresholdSeconds - 0.5
      secondsValue:SetText(DM.settings.flashThresholdSeconds .. " s")
      DM:SaveSettings()
    end
  end)

  -- Create increase button for seconds
  local secondsIncreaseButton = CreateFrame("Button", nil, secondsContainer)
  secondsIncreaseButton:SetSize(18, 18)
  secondsIncreaseButton:SetPoint("LEFT", secondsDecreaseButton, "RIGHT", 2, 0)
  secondsIncreaseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
  secondsIncreaseButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
  secondsIncreaseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
  secondsIncreaseButton:SetScript("OnClick", function()
    if DM.settings.flashThresholdSeconds < 8 then
      DM.settings.flashThresholdSeconds = DM.settings.flashThresholdSeconds + 0.5
      secondsValue:SetText(DM.settings.flashThresholdSeconds .. " s")
      DM:SaveSettings()
    end
  end)

  -- Initially hide or show the seconds control based on checkbox state
  if DM.settings.flashExpiring then
    secondsContainer:Show()
  else
    secondsContainer:Hide()
  end

  -- Set up the flashing checkbox handler
  flashingCheckbox:SetScript("OnClick", function(self)
    DM.settings.flashExpiring = self:GetChecked()
    DM:PrintMessage("Expiry Flash " .. (DM.settings.flashExpiring and "Enabled" or "Disabled"))

    -- Show/hide the seconds control based on checkbox state
    if secondsContainer then
      if self:GetChecked() then
        secondsContainer:Show()
      else
        secondsContainer:Hide()
      end
    end

    DM:SaveSettings()
  end)

  -- Set up the border-only checkbox handler
  borderOnlyCheckbox:SetScript("OnClick", function(self)
    DM.settings.borderOnly = self:GetChecked()
    DM:PrintMessage("Border-only " .. (DM.settings.borderOnly and "Enabled" or "Disabled"))

    -- Show/hide the thickness control based on checkbox state
    if thicknessContainer then
      if self:GetChecked() then
        thicknessContainer:Show()
      else
        thicknessContainer:Hide()
      end
    end

    if DM.enabled then
      DM:UpdateAllNameplates()
    end
    DM:SaveSettings()
  end)

  -- Container for bottom buttons (moved up before it's referenced)
  local bottomButtonContainer = CreateFrame("Frame", nil, parent)
  bottomButtonContainer:SetSize(parent:GetWidth() - 20, 50)
  bottomButtonContainer:SetPoint("BOTTOM", 0, 10)

  -- Create info section container with fixed height
  local infoSection = CreateFrame("Frame", nil, contentPanel, "BackdropTemplate")
  infoSection:SetSize(350, 140)                             -- Maintaining the 140px height
  infoSection:SetPoint("TOP", contentPanel, "TOP", 0, -190) -- Changed from -220 to -190 to move it up by 30px
  infoSection:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = nil,
    edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  infoSection:SetBackdropColor(0.05, 0.05, 0.05, 0.5)

  -- Array to store panels for easier management
  local panels = {}

  -- Function to update panel positions and visibility
  local function UpdatePanelPositions()
    local currentOffset = 0

    for i, panel in ipairs(panels) do
      -- Reposition header
      panel.header:ClearAllPoints()
      panel.header:SetPoint("TOPLEFT", infoSection, "TOPLEFT", 0, -currentOffset)

      -- Update offset for next panel
      currentOffset = currentOffset + panel.headerHeight

      -- Position and show/hide content
      panel.content:ClearAllPoints()
      panel.content:SetPoint("TOPLEFT", panel.header, "BOTTOMLEFT", 12, -4)

      if panel.isExpanded then
        panel.indicator:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
        panel.content:Show()
        currentOffset = currentOffset + panel.contentHeight + 8 -- Add padding
      else
        panel.indicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
        panel.content:Hide()
      end
    end
  end

  -- Function to expand a specific panel and collapse others
  local function ExpandPanel(panelIndex)
    for i, panel in ipairs(panels) do
      panel.isExpanded = (i == panelIndex)
    end
    UpdatePanelPositions()
  end

  -- Function to create an accordion panel
  local function CreateAccordionPanel(title, description, isExpanded)
    local panel = {}
    panel.isExpanded = isExpanded

    -- Create header button
    local header = CreateFrame("Button", nil, infoSection, "BackdropTemplate")
    header:SetSize(350, 30)
    header:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    -- Set up background
    header:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = nil,
      edgeSize = 0,
      insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    header:SetBackdropColor(0.075, 0.075, 0.075, 0.7)

    -- Create expand/collapse indicator
    local indicator = header:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(16, 16)
    indicator:SetPoint("LEFT", header, "LEFT", 8, 0)
    panel.indicator = indicator

    -- Create title text
    local titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", indicator, "RIGHT", 6, 0)
    titleText:SetText(title)
    titleText:SetTextColor(classColor.r, classColor.g, classColor.b)

    -- Create content frame
    local content = CreateFrame("Frame", nil, infoSection)
    content:SetSize(326, 0) -- Width with margins, height set later

    -- Create or update the description text
    local descText

    -- Check if this is the DoT Combinations panel (index 2)
    if title == "DoT Combinations" then
      -- Using a single text element with normal color
      descText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      descText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
      descText:SetWidth(326)
      descText:SetText(
        "Create powerful combinations requiring two or more DoTs to be active simultaneously before applying nameplate colors. Combinations always take priority over individual spells.")
      descText:SetJustifyH("LEFT")
      descText:SetJustifyV("TOP")
      descText:SetTextColor(0.8, 0.8, 0.8) -- Normal text color
      descText:SetSpacing(2)

      -- Set content height based on text
      content:SetHeight(descText:GetStringHeight() + 8)
    else
      -- Regular text for other panels
      descText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      descText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
      descText:SetWidth(326)
      descText:SetText(description)
      descText:SetJustifyH("LEFT")
      descText:SetJustifyV("TOP")
      descText:SetTextColor(0.8, 0.8, 0.8)
      descText:SetSpacing(2)

      -- Set content height based on text
      content:SetHeight(descText:GetStringHeight() + 8)
    end

    -- Store panel elements
    panel.header = header
    panel.content = content
    panel.headerHeight = header:GetHeight()
    panel.contentHeight = content:GetHeight()

    -- Add click handler
    header:SetScript("OnClick", function()
      -- Toggle this panel
      panel.isExpanded = not panel.isExpanded

      -- If expanding, collapse others
      if panel.isExpanded then
        for i, otherPanel in ipairs(panels) do
          if otherPanel ~= panel then
            otherPanel.isExpanded = false
          end
        end
      end

      UpdatePanelPositions()
    end)

    return panel
  end

  -- Create the three info panels
  local threatColorPanel = CreateAccordionPanel(
    "Threat Color Information",
    "Automatically applies threat colors to nameplates with your DoTs for instant combat feedback (shows aggro warnings for DPS, lost aggro alerts for tanks)",
    true -- First panel expanded by default
  )
  table.insert(panels, threatColorPanel)

  local combinationsPanel = CreateAccordionPanel(
    "DoT Combinations",
    "", -- Description handled specially inside the CreateAccordionPanel function
    false
  )
  table.insert(panels, combinationsPanel)

  local borderModePanel = CreateAccordionPanel(
    "Border Color Mode",
    "DotMaster can modify nameplate borders instead of the entire nameplate color. This less intrusive option preserves other nameplate visuals while still providing DoT tracking.",
    false
  )
  table.insert(panels, borderModePanel)

  -- Initial positioning update
  UpdatePanelPositions()

  -- Ensure the info section doesn't overflow its container
  infoSection:SetClipsChildren(true)

  -- Add a warning about Plater integration (moved to bottom button area)
  local platerWarning = bottomButtonContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  platerWarning:SetPoint("CENTER", bottomButtonContainer, "CENTER", 0, 0)
  platerWarning:SetWidth(350)
  platerWarning:SetText(
    "WARNING: If using Plater, disable any Plater scripts or mods that modify nameplate colors for proper DotMaster functionality.")
  platerWarning:SetTextColor(1, 0.82, 0) -- Gold text for warning
  platerWarning:SetJustifyH("CENTER")
  platerWarning:SetJustifyV("TOP")
  platerWarning:SetSpacing(2)

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
end
