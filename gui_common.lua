-- DotMaster gui_common.lua
-- Contains common GUI functionality and components

local DM = DotMaster
DotMaster_Components = {}

-- Create standardized info area for tabs
local function CreateTabInfoArea(parentFrame, titleText, explanationText)
  -- Create info area container
  local infoArea = CreateFrame("Frame", nil, parentFrame)
  infoArea:SetSize(430, 85) -- Increased height from 75px to 85px to accommodate more spacing
  infoArea:SetPoint("TOP", parentFrame, "TOP", 0, 0)

  -- Center container for text elements with equal top/bottom margins
  local textContainer = CreateFrame("Frame", nil, infoArea)
  textContainer:SetSize(430, 55)                             -- Increased height from 45px to 55px
  textContainer:SetPoint("CENTER", infoArea, "CENTER", 0, 0) -- Centered vertically

  -- Info Area Title
  local infoTitle = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  infoTitle:SetPoint("TOP", textContainer, "TOP", 0, 0)
  infoTitle:SetText(titleText)
  infoTitle:SetTextColor(1, 0.82, 0) -- WoW Gold

  -- Info Area Explanation
  local infoExplanation = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoExplanation:SetPoint("TOP", infoTitle, "BOTTOM", 0, -10) -- Increased spacing from -2 to -10
  infoExplanation:SetWidth(300)
  infoExplanation:SetJustifyH("CENTER")
  infoExplanation:SetText(explanationText)
  infoExplanation:SetTextColor(0.8, 0.8, 0.8)

  return infoArea
end

-- Define component functions first (before they are used)
DotMaster_Components.CreateGeneralTab = function(parent)
  return DM:CreateGeneralTab(parent)
end

DotMaster_Components.CreateTrackedSpellsTab = function(parent)
  return DM:CreateTrackedSpellsTab(parent)
end

-- Add Combinations tab component function
DotMaster_Components.CreateCombinationsTab = function(parent)
  return DM:CreateCombinationsTab(parent)
end

-- Store the info area creation function in the Components namespace
DotMaster_Components.CreateTabInfoArea = CreateTabInfoArea

-- Function to update Plater Integration status in the footer
function DM:UpdatePlaterStatusFooter()
  if not DM.GUI.statusMessage then return end -- Safety check

  local Plater = _G["Plater"]
  local statusText = "Plater Integration: "
  local r, g, b = 1, 1, 1 -- Default to white

  local isPlaterAvailable = (Plater ~= nil)
  local isIntegrated = false -- Renamed from dotMasterIntegrationFound for clarity

  if isPlaterAvailable and Plater.db and Plater.db.profile and Plater.db.profile.hook_data then
    local hookData = Plater.db.profile.hook_data
    if type(hookData) == "table" then
      for modName, modData in pairs(hookData) do
        if modName == "DotMaster Integration" or (type(modData) == "table" and modData.Name == "DotMaster Integration") then
          local actualMod = type(modData) == "table" and modData or hookData
          if actualMod.Hooks and actualMod.Hooks["Nameplate Updated"] then
            if type(actualMod.Hooks["Nameplate Updated"]) == "string" and string.find(actualMod.Hooks["Nameplate Updated"], "envTable.DM_SPELLS", 1, true) then
              isIntegrated = true
              break
            end
          end
        end
      end
      if not isIntegrated then
        for i, mod in ipairs(hookData) do
          if type(mod) == "table" and mod.Name == "DotMaster Integration" and mod.Hooks and mod.Hooks["Nameplate Updated"] then
            if type(mod.Hooks["Nameplate Updated"]) == "string" and string.find(mod.Hooks["Nameplate Updated"], "envTable.DM_SPELLS", 1, true) then
              isIntegrated = true
              break
            end
          end
        end
      end
    end
  end

  if not isPlaterAvailable then
    statusText = statusText .. "Error (Plater AddOn not detected)"
    r, g, b = 1, 0, 0                           -- Red
  elseif not isIntegrated then
    statusText = statusText .. "Not Integrated" -- Overlay will prompt for action
    r, g, b = 1, 0.5, 0                         -- Orange
  else                                          -- Plater is available and integrated
    statusText = statusText .. "Active"
    r, g, b = 0, 1, 0                           -- Green
  end

  DM.GUI.statusMessage:SetText(statusText)
  DM.GUI.statusMessage:SetTextColor(r, g, b)
  DM.GUI.statusMessage:Show()
end

-- Create the main GUI
function DM:CreateGUI()
  -- Get the player's class color
  local playerClass = select(2, UnitClass("player"))
  local classColor = RAID_CLASS_COLORS[playerClass] or { r = 0.6, g = 0.2, b = 1.0 }

  -- Initialize original critical settings if not already done (e.g., by settings.lua loading earlier)
  -- This ensures they are captured at least once when the GUI is created for the session.
  if DM.originalCriticalSettings then -- Check if the table exists
    local settings = DM.API:GetSettings()
    if DM.originalCriticalSettings.borderThickness == nil then
      DM.originalCriticalSettings.borderThickness = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness) or
          settings.borderThickness
    end
    if DM.originalCriticalSettings.extendPlaterColors == nil then
      DM.originalCriticalSettings.extendPlaterColors = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.extendPlaterColors ~= nil) and
          DotMasterDB.settings.extendPlaterColors or settings.extendPlaterColors
    end
    if DM.originalCriticalSettings.borderOnly == nil then
      DM.originalCriticalSettings.borderOnly = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderOnly ~= nil) and
          DotMasterDB.settings.borderOnly or settings.borderOnly
    end
  end

  -- Track border thickness changes
  if not DM.originalBorderThickness then
    local settings = DM.API:GetSettings()
    DM.originalBorderThickness = settings.borderThickness
  end

  -- Create main frame
  local frame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(500, 600)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  -- Register with UI special frames to enable Escape key closing
  tinsert(UISpecialFrames, "DotMasterOptionsFrame")

  -- Add a backdrop
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  -- Use class color for the title text
  title:SetText(string.format("|cFF%02x%02x%02xDotMaster|r",
    classColor.r * 255,
    classColor.g * 255,
    classColor.b * 255))

  -- Close Button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -3, -3)
  closeButton:SetSize(26, 26)

  -- Function to close all child windows
  function DM.GUI:CloseAllChildWindows()
    -- Close the help window if it exists and is shown
    if DM.GUI.helpWindow and DM.GUI.helpWindow:IsShown() then
      DM.GUI.helpWindow:Hide()
    end

    -- Close combination dialog if it exists and is shown
    if DM.GUI.combinationDialog and DM.GUI.combinationDialog:IsShown() then
      DM.GUI.combinationDialog:Hide()
    end

    -- Close spell selection window for combinations if it exists and is shown
    if DM.GUI.comboSpellSelectionFrame and DM.GUI.comboSpellSelectionFrame:IsShown() then
      DM.GUI.comboSpellSelectionFrame:Hide()
    end

    -- Close spell selection dialog if it exists and is shown
    if DM.spellSelectionFrame and DM.spellSelectionFrame:IsShown() then
      DM.spellSelectionFrame:Hide()
    end

    -- Close help popup if it exists and is shown
    if DM.GUI.HelpPopupFrame and DM.GUI.HelpPopupFrame:IsShown() then
      DM.GUI.HelpPopupFrame:Hide()
    end

    -- Close Find My Dots recording frame if it exists and is shown
    if DM.recordingFrame and DM.recordingFrame:IsShown() then
      DM:StopFindMyDots(false)
    end

    -- Close Dots Confirmation frame if it exists and is shown
    if DM.dotsConfirmFrame and DM.dotsConfirmFrame:IsShown() then
      DM.dotsConfirmFrame:Hide()
    end

    -- Close any static popups that belong to DotMaster
    for name, _ in pairs(StaticPopupDialogs) do
      if name:find("DOTMASTER_") then
        StaticPopup_Hide(name)
      end
    end
  end

  -- Help Button (Question Mark)
  local helpButton = CreateFrame("Button", nil, frame)
  helpButton:SetSize(20, 20)
  helpButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -2, 0)

  -- Informative text for the help button
  local helpButtonText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  helpButtonText:SetText("How to use")
  helpButtonText:SetTextColor(0.7, 0.7, 0.7, 0.9)             -- Light grey, slightly transparent
  helpButtonText:SetPoint("RIGHT", helpButton, "LEFT", -3, 0) -- Position to the left of the icon, with small spacing

  -- Create the texture for the question mark icon
  local helpIcon = helpButton:CreateTexture(nil, "ARTWORK")
  helpIcon:SetAllPoints()
  helpIcon:SetTexture("Interface\\FriendsFrame\\InformationIcon")

  -- Add hover effect
  helpButton:SetHighlightTexture("Interface\\FriendsFrame\\InformationIcon", "ADD")

  -- Help window creation function
  local function CreateHelpWindow()
    -- Create the help window frame
    local helpFrame = CreateFrame("Frame", "DotMasterHelpFrame", UIParent, "BackdropTemplate")
    helpFrame:SetSize(500, 600)
    helpFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
    helpFrame:SetFrameStrata("HIGH")
    helpFrame:SetMovable(true)
    helpFrame:EnableMouse(true)
    helpFrame:RegisterForDrag("LeftButton")
    helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
    helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
    helpFrame:Hide()

    -- Register with UI special frames to enable Escape key closing
    tinsert(UISpecialFrames, "DotMasterHelpFrame")

    -- Add a backdrop
    helpFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    helpFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    helpFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- Title
    local title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    -- Use class color for the title text
    title:SetText(string.format("|cFF%02x%02x%02xDotMaster Guide|r",
      classColor.r * 255,
      classColor.g * 255,
      classColor.b * 255))

    -- Close Button
    local helpCloseButton = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
    helpCloseButton:SetPoint("TOPRIGHT", -3, -3)
    helpCloseButton:SetSize(26, 26)

    -- Create a scrollable content frame
    local scrollFrame = CreateFrame("ScrollFrame", "DotMasterHelpScrollFrame", helpFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 20)

    local content = CreateFrame("Frame", "DotMasterHelpContent", scrollFrame)
    content:SetSize(450, 1200) -- Make it taller than the scroll frame to enable scrolling
    scrollFrame:SetScrollChild(content)

    -- Helper function to create section headers
    local function CreateSection(title, yOffset)
      local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      header:SetPoint("TOPLEFT", 10, yOffset)
      header:SetText(title)
      header:SetTextColor(1, 0.82, 0) -- WoW Gold

      local line = content:CreateTexture(nil, "ARTWORK")
      line:SetHeight(1)
      line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
      line:SetPoint("RIGHT", content, "RIGHT", -10, 0)
      line:SetColorTexture(0.6, 0.6, 0.6, 0.8)

      return header:GetStringHeight() + 4 -- Return height used by header + line
    end

    -- Helper function to create content text
    local function CreateText(text, yOffset, width)
      local textObj = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      textObj:SetPoint("TOPLEFT", 10, yOffset)
      textObj:SetWidth(width or 430)
      textObj:SetJustifyH("LEFT")
      textObj:SetText(text)
      textObj:SetTextColor(0.9, 0.9, 0.9)

      return textObj:GetStringHeight() + 10 -- Return height + padding
    end

    -- Helper function to create feature explanation
    local function CreateFeature(title, description, yOffset)
      local featureTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      featureTitle:SetPoint("TOPLEFT", 15, yOffset)
      featureTitle:SetText("• " .. title)
      featureTitle:SetTextColor(0.8, 0.95, 1) -- Light blue for feature names

      local featureDesc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      featureDesc:SetPoint("TOPLEFT", 25, yOffset - featureTitle:GetStringHeight() - 2)
      featureDesc:SetWidth(415)
      featureDesc:SetJustifyH("LEFT")
      featureDesc:SetText(description)
      featureDesc:SetTextColor(0.9, 0.9, 0.9)

      return featureTitle:GetStringHeight() + featureDesc:GetStringHeight() + 15
    end

    -- Fill content with DotMaster guide
    local yOffset = 0

    -- Introduction
    yOffset = yOffset - CreateSection("What is DotMaster?", yOffset)
    yOffset = yOffset -
        CreateText(
          "DotMaster is an addon that colors enemy nameplates based on the damage-over-time (DoT) effects you apply to them. It works with any class and specialization, making it easier to track which targets have your DoTs applied and which ones need attention.",
          yOffset)

    -- Overview Section
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("How DotMaster Works", yOffset)
    yOffset = yOffset -
        CreateText(
          "DotMaster integrates with Plater Nameplates to provide dynamic visual tracking of DoTs through nameplate colors, borders, or both. When you apply a DoT spell to a target, its nameplate or border will change color based on your configuration.",
          yOffset)

    -- Features Section
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Key Features", yOffset)

    -- Feature list with explanations
    yOffset = yOffset -
        CreateFeature("DoT Tracking",
          "Colors enemy nameplates based on the DoTs you've applied to them. Track individual DoTs or combinations for more complex rotations.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Expiry Flash",
          "Nameplates can flash when your DoTs are about to expire, helping you time re-applications perfectly.", yOffset)
    yOffset = yOffset -
        CreateFeature("Border Only Mode",
          "Instead of coloring the entire nameplate, you can opt to only color the border, preserving other nameplate information.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Extend Plater Colors",
          "Apply Plater's custom NPC colors to nameplate borders for better visibility.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Force Threat Color", "Prioritize threat coloring over DoT coloring for better tanking awareness.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Border Thickness", "Customize the nameplate border thickness to your preference.", yOffset)

    -- Settings Section
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Settings Explained", yOffset)

    yOffset = yOffset -
        CreateFeature("General Settings",
          "Control basic addon functionality, including enabling/disabling the addon, showing the minimap icon, and determining how threat and DoT colors interact.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Tracked Spells",
          "Add specific spells to track. Each spell can have its own custom color. You can add spells directly from your spellbook or by spell ID.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Combinations",
          "Create color rules for specific combinations of DoTs. When all DoTs in a combination are active on a target, it will use the combination color instead of individual DoT colors.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Border Logic",
          "Control whether DoT colors affect the entire nameplate or just the border. You can also customize the border thickness and extend Plater's NPC colors to borders.",
          yOffset)

    -- Usage Tips
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Usage Tips", yOffset)

    yOffset = yOffset -
        CreateText("• Border-only mode is useful when you want to preserve health bar colors but still track DoTs",
          yOffset)
    yOffset = yOffset -
        CreateText(
          "• For multi-DoT specializations, create combinations for your core DoT sets to easily track targets with all DoTs applied",
          yOffset)
    yOffset = yOffset -
        CreateText(
          "• Extend Plater Colors works only for NPCs with custom colors set in Plater's NPC Colors & Names tab",
          yOffset)
    yOffset = yOffset -
        CreateText("• When adjusting border thickness, you'll need to reload your UI for the changes to apply fully",
          yOffset)
    yOffset = yOffset -
        CreateText("• If Plater integration is missing, use the 'Install Plater Integration' button in the window",
          yOffset)

    -- Additional Resources
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Additional Resources", yOffset)
    yOffset = yOffset -
        CreateText(
          "For additional tips, configurations, and Plater profiles optimized for use with DotMaster, check the recommended Plater profile accessible through the 'Get Jervaise Plater Profile' button in the General tab.",
          yOffset)

    -- GUI Tabs Overview
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("GUI Tabs Overview", yOffset)

    yOffset = yOffset -
        CreateText(
          "|cFFFFD100Key Features:|r\n" ..
          "- Automatic DoT Detection: Finds your DoTs as you play.\n" ..
          "- Customizable Tracking: Choose which spells to track, their colors, and priorities.\n" ..
          "- Plater Integration: Seamlessly colors Plater nameplates based on your DoTs.\n" ..
          "- Spell Combinations: Group multiple DoTs into a single, prioritized visual.\n" ..
          "- Class and Spec Awareness: Works with any class and specialization.",
          yOffset)

    yOffset = yOffset -
        CreateText(
          "|cFFFFD100GUI Tabs Overview:|r\n" ..
          "- |cFFADD8E6General Tab:|r Configure core DotMaster settings, Plater integration, minimap icon, and appearance options like border logic.\n" ..
          "- |cFFADD8E6Tracked Spells Tab:|r Manage individual spells. Enable/disable tracking, set custom colors, and assign priorities for display.\n" ..
          "- |cFFADD8E6Combinations Tab:|r Create and manage spell combinations. Define sets of spells that should be treated as a single, powerful effect with its own color and priority.\n" ..
          "- |cFFADD8E6Database Tab:|r View all spells DotMaster has detected. Use the \"Find My Dots\" feature to discover new spells cast by your character.",
          yOffset)

    yOffset = yOffset -
        CreateText(
          "|cFFFFD100Getting Started:|r\n" ..
          "1. Open DotMaster settings with /dm.\n" ..
          "2. Configure your preferences and settings.\n" ..
          "3. Enjoy seamless integration with Plater Nameplates!",
          yOffset)

    return helpFrame
  end

  -- Create the help window when the button is clicked
  helpButton:SetScript("OnClick", function()
    if not DM.GUI.helpWindow then
      DM.GUI.helpWindow = CreateHelpWindow()
    end

    if DM.GUI.helpWindow:IsShown() then
      DM.GUI.helpWindow:Hide()
    else
      DM.GUI.helpWindow:Show()
    end
  end)

  -- Add force push on close
  closeButton:HookScript("OnClick", function()
    -- Close all child windows
    DM.GUI:CloseAllChildWindows()

    -- Force push settings to DotMaster Integration when closing
    if not DM.disablePush then
      if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
        DM.ClassSpec:PushConfigToPlater()
      end
    end
  end)

  -- Hook into frame hide to save settings
  frame:HookScript("OnHide", function()
    -- Close all child windows when the main window is closed
    DM.GUI:CloseAllChildWindows()

    -- Update settings if needed
    if DM:GetSaveNeeded() then
      -- Apply settings on close
      DM:AutoSave()
    end

    -- Force reload of DotMasterDB settings just to double-check
    local settings = DM.API:GetSettings()

    -- Store border thickness back in DotMasterDB
    if DotMasterDB and DotMasterDB.settings then
      DotMasterDB.settings.borderThickness = settings.borderThickness
    end

    -- Force push to DotMaster Integration with current settings when window is closed by any means
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
    end
    if DM.UpdatePlaterStatusFooter then DM:UpdatePlaterStatusFooter() end -- Restore call

    -- Make sure original settings are initialized (safety check)
    if not DM.originalBorderThickness then
      DM.originalBorderThickness = settings.borderThickness
    end

    -- Check if critical Plater settings have changed and show reload popup if needed
    if DM.TrackCriticalSettingsChange and DM:TrackCriticalSettingsChange() then
      -- Directly show the reload UI popup if settings have changed
      if DM.ShowReloadUIPopupForCriticalChanges then
        DM:ShowReloadUIPopupForCriticalChanges()
      end
    end
  end)

  -- Author credit
  local author = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  author:SetPoint("BOTTOM", 0, 12) -- Increase from 5 to 12 to add more space
  -- Read version from API first, then SavedVariables, fallback to defaults if not found
  local versionString = (DM.API and DM.API.GetVersion and DM.API:GetVersion()) or
      (DotMasterDB and DotMasterDB.version) or
      (DM.defaults and DM.defaults.version) or "N/A"
  author:SetText("by Jervaise - v" .. versionString)

  -- Create a footer frame that will contain global buttons
  local footerFrame = CreateFrame("Frame", "DotMasterFooterFrame", frame)
  footerFrame:SetHeight(45)                                       -- Increased from 40 to 45
  footerFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 25) -- Increased y-offset from 20 to 25
  footerFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 25)

  -- Add a status message text in the footer
  local statusMessage = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusMessage:SetPoint("CENTER", footerFrame, "CENTER", 0, 0)
  statusMessage:SetText("Plater Integration: Initializing...")
  statusMessage:SetTextColor(0.7, 0.7, 0.7)                             -- Neutral color initially
  DM.GUI.statusMessage = statusMessage                                  -- Store reference

  if DM.UpdatePlaterStatusFooter then DM:UpdatePlaterStatusFooter() end -- Initial update for the message

  -- Add a subtle separator line at the top of the footer
  local separator = footerFrame:CreateTexture(nil, "ARTWORK")
  separator:SetHeight(1)
  separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
  separator:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 0, 0)
  separator:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", 0, 0)

  -- Create the save button in the footer with class-colored styling
  local saveButton = CreateFrame("Button", "DotMasterSaveButton", footerFrame, "UIPanelButtonTemplate")
  saveButton:SetSize(140, 24)
  saveButton:SetPoint("CENTER", footerFrame, "CENTER", 0, 0) -- Centered vertically in the footer
  saveButton:SetText("Save Settings")
  saveButton:Hide()                                          -- Hide the save button since we're auto-saving

  -- Add a subtle class-colored glow to the save button
  if classColor then
    local normalTexture = saveButton:GetNormalTexture()
    if normalTexture then
      normalTexture:SetVertexColor(
        classColor.r * 0.7 + 0.3,
        classColor.g * 0.7 + 0.3,
        classColor.b * 0.7 + 0.3
      )
    end
  end

  saveButton:SetScript("OnClick", function()
    -- Save DotMaster configuration
    DM.API:SaveSettings(DM.API:GetSettings())

    -- Push to Plater
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
    end

    -- Update class/spec specific settings
    if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
      DM.ClassSpec:SaveCurrentSettings()
    end

    DM:PrintMessage("Settings saved and pushed to Plater")
  end)

  -- Create tab system
  local tabHeight = 30
  local tabFrames = {}
  local activeTab = 1

  -- Tab background
  local tabBg = frame:CreateTexture(nil, "BACKGROUND")
  tabBg:SetPoint("TOPLEFT", 8, -40)
  tabBg:SetPoint("TOPRIGHT", -8, -40)
  tabBg:SetHeight(tabHeight)
  tabBg:SetColorTexture(0, 0, 0, 0.6) -- Match debug window transparency

  for i = 1, 4 do
    -- Tab content frames
    tabFrames[i] = CreateFrame("Frame", "DotMasterTabFrame" .. i, frame)
    tabFrames[i]:SetPoint("TOPLEFT", 10, -(45 + tabHeight))
    tabFrames[i]:SetPoint("BOTTOMRIGHT", -10, 60) -- Increased from 30 to 60 to make room for footer
    tabFrames[i]:Hide()

    -- Custom tab buttons
    local tabButton = CreateFrame("Button", "DotMasterTab" .. i, frame)
    tabButton:SetSize(100, tabHeight)

    -- Tab styling
    local normalTexture = tabButton:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    -- Set initial inactive color
    normalTexture:SetColorTexture(0, 0, 0, 0.7)
    tabButton.normalTexture = normalTexture -- Store reference to the texture

    -- Tab text
    local text = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    if i == 1 then
      text:SetText("General")
    elseif i == 2 then
      text:SetText("Tracked Spells")
    elseif i == 3 then
      text:SetText("Combinations")
    else
      text:SetText("Database")
    end
    text:SetTextColor(1, 0.82, 0)

    -- Store ID and script
    tabButton.id = i
    tabButton:SetScript("OnClick", function(self)
      DM.GUI:SelectTab(self.id)
    end)

    -- Position tabs side by side with appropriate spacing
    -- Adjust width to fit 4 tabs
    local tabWidth = 115
    tabButton:SetSize(tabWidth, tabHeight)
    tabButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i - 1) * (tabWidth + 5), -40)
  end

  -- Set initial active tab
  local firstTab = _G["DotMasterTab1"]
  if firstTab and firstTab.normalTexture then
    -- Set to active color
    firstTab.normalTexture:SetColorTexture(0.2, 0.2, 0.2, 0.8)
  end
  tabFrames[1]:Show()

  -- Ensure functions exist before calling them
  if DM.CreateGeneralTab then
    DM:CreateGeneralTab(tabFrames[1])
  elseif DotMaster_Components.CreateGeneralTab then
    DotMaster_Components.CreateGeneralTab(tabFrames[1])
  else
    print("Error: CreateGeneralTab function not found!")
  end

  -- Create Tracked Spells tab content
  if DotMaster_Components.CreateTrackedSpellsTab then
    DotMaster_Components.CreateTrackedSpellsTab(tabFrames[2])
  else
    print("Error: CreateTrackedSpellsTab function not found!")
  end

  -- Create Combinations tab content
  if DotMaster_Components.CreateCombinationsTab then
    DotMaster_Components.CreateCombinationsTab(tabFrames[3])
  else
    print("Error: CreateCombinationsTab function not found!")
  end

  -- Create Database tab content (now index 4 instead of 3)
  if DotMaster_Components.CreateDatabaseTab then
    DotMaster_Components.CreateDatabaseTab(tabFrames[4])
  else
    print("Error: CreateDatabaseTab function not found!")
  end

  -- Initialize GUI frame
  DM.GUI.frame = frame
  DM.GUI.tabs = {}

  -- Create Plater Status Overlay (Initially Hidden)
  local overlay = CreateFrame("Frame", "DotMasterPlaterOverlay", frame, "BackdropTemplate")
  overlay:SetAllPoints(frame)
  overlay:SetFrameStrata("DIALOG")                                   -- Ensure it's above tabs but below pop-ups
  overlay:SetFrameLevel(frame:GetFrameLevel() + 100)                 -- High frame level to cover content
  overlay:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", -- Standard WoW dark background
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  overlay:SetBackdropColor(0, 0, 0, 0.85) -- Semi-transparent black
  overlay:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  overlay:EnableMouse(true)               -- Intercept mouse clicks
  overlay:Hide()
  DM.GUI.PlaterOverlay = overlay

  local overlayMessage = overlay:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  overlayMessage:SetPoint("CENTER", overlay, "CENTER", 0, 30)
  overlayMessage:SetTextColor(1, 0.82, 0) -- Gold color
  overlayMessage:SetJustifyH("CENTER")
  overlayMessage:SetWidth(frame:GetWidth() - 100)
  DM.GUI.PlaterOverlayMessage = overlayMessage

  local overlayButton = CreateFrame("Button", "DotMasterPlaterOverlayButton", overlay, "UIPanelButtonTemplate")
  overlayButton:SetSize(200, 30)
  overlayButton:SetPoint("TOP", overlayMessage, "BOTTOM", 0, -20)
  DM.GUI.PlaterOverlayButton = overlayButton

  -- Function to check Plater status and update the overlay
  function DM.GUI:UpdatePlaterOverlayStatus()
    local isPlaterAvailable = (_G["Plater"] ~= nil)
    local isIntegrated = false

    if isPlaterAvailable and Plater.db and Plater.db.profile and Plater.db.profile.hook_data then
      local hookData = Plater.db.profile.hook_data
      if type(hookData) == "table" then
        for modName, modData in pairs(hookData) do
          if modName == "DotMaster Integration" or (type(modData) == "table" and modData.Name == "DotMaster Integration") then
            local actualMod = type(modData) == "table" and modData or hookData
            if actualMod.Hooks and actualMod.Hooks["Nameplate Updated"] then
              if type(actualMod.Hooks["Nameplate Updated"]) == "string" and string.find(actualMod.Hooks["Nameplate Updated"], "envTable.DM_SPELLS", 1, true) then
                isIntegrated = true
                break
              end
            end
          end
        end
        if not isIntegrated then -- Fallback for array-like structure
          for i, mod in ipairs(hookData) do
            if type(mod) == "table" and mod.Name == "DotMaster Integration" and mod.Hooks and mod.Hooks["Nameplate Updated"] then
              if type(mod.Hooks["Nameplate Updated"]) == "string" and string.find(mod.Hooks["Nameplate Updated"], "envTable.DM_SPELLS", 1, true) then
                isIntegrated = true
                break
              end
            end
          end
        end
      end
    end

    if not isPlaterAvailable then
      DM.GUI.PlaterOverlayMessage:SetText(
        "DotMaster requires Plater Nameplates to be installed and enabled.\nPlease ensure Plater is installed and active.")
      DM.GUI.PlaterOverlayButton:Hide()
      DM.GUI.PlaterOverlay:Show()
    elseif not isIntegrated then
      DM.GUI.PlaterOverlayMessage:SetText(
        "DotMaster needs to integrate with Plater Nameplates.\nClick the button below to install the required Plater script.")
      DM.GUI.PlaterOverlayButton:SetText("Install Plater Integration")
      DM.GUI.PlaterOverlayButton:SetScript("OnClick", function()
        local modString =
        "!PLATER:2!PY/BasJAFEUr+BN11UW3lhitibsOnSixhNqF0EWgPGZe4pA4b5gZg3U139OF39ikSJeXey6ce2WzPSdfgPNoH3LtsbbgFWnuvw3yA1HD5i8s/pwPna1AYMmkfNeu/J+VBUoFpSR//MtTJUg/+RrY8+TwOLZssdui7UDJBqdvcLlAw5IRW47ZKrD0Z+2hRe1DVls6mZCJFpwLmyOYLyVd4JZaDLnpzI3jzqAIGVSVOocCtaDToHaDe8Hwus/5R3RepvEiWsziZJVGSZpuPYkOrevPTe5G1/sMpCS93rXQrzdkhtcu/AI="

        if _G["Plater"] then
          if type(_G["Plater"].ImportScriptString) == "function" then
            DM:PrintMessage(
              "Setting up DotMaster colors with Plater...")
            local success, importedObject, wasEnabled = _G["Plater"].ImportScriptString(modString, true, false, true,
              false)

            if success and importedObject then
              DM:PrintMessage("Connection with Plater established successfully!")

              if not importedObject.Enabled then
                if type(_G["Plater"].EnableHook) == "function" then
                  _G["Plater"].EnableHook(importedObject)
                  DM:PrintMessage("Enabling Plater integration...")
                  if type(_G["Plater"].CompileHook) == "function" then
                    _G["Plater"].CompileHook(importedObject)
                  elseif type(_G["Plater"].CompileAllHooksAndScripts) == "function" then
                    _G["Plater"].CompileAllHooksAndScripts()
                  end
                else
                  DM:PrintMessage("Plater integration could not be enabled automatically.")
                end
              else
                DM:PrintMessage("Plater integration is active.")
              end

              DM.GUI:UpdatePlaterOverlayStatus() -- Update overlay status immediately

              C_Timer.After(0.5, function()
                if DM.InstallPlaterMod then
                  DM:PrintMessage(
                    "Applying DotMaster colors to Plater nameplates...")
                  DM:InstallPlaterMod()
                  DM.GUI:UpdatePlaterOverlayStatus() -- Refresh overlay status again after InstallPlaterMod
                else
                  DM:PrintMessage("Could not apply color settings to Plater.")
                  DM.GUI:UpdatePlaterOverlayStatus() -- Still refresh overlay
                end
              end)
            else
              DM:PrintMessage(
                "Plater.ImportScriptString executed, but it did not return success or a valid imported object. Plater's internal debug messages (if any) might provide more details.")
              DM.GUI:UpdatePlaterOverlayStatus() -- Refresh overlay status
            end
          else
            DM:PrintMessage(
              "Plater addon IS LOADED, but its ImportScriptString function was not found or is not a function. This is the primary function needed for import.")
            DM.GUI:UpdatePlaterOverlayStatus() -- Refresh overlay status
          end
        else
          DM:PrintMessage(
            "Plater addon IS NOT LOADED (or _G[\"Plater\"] is nil). Cannot import DotMaster Integration mod. Please ensure Plater is enabled.")
          DM.GUI:UpdatePlaterOverlayStatus() -- Refresh overlay status
        end
      end)
      DM.GUI.PlaterOverlayButton:Show()
      DM.GUI.PlaterOverlay:Show()
    else                                                                    -- Plater is available and integrated
      DM.GUI.PlaterOverlay:Hide()
      if DM.UpdatePlaterStatusFooter then DM:UpdatePlaterStatusFooter() end -- Restore call
    end
  end

  -- Call initially and on show
  frame:SetScript("OnShow", function(self)
    -- Original OnShow logic if any (e.g., from LibAdvancedOptionsPanel-1.0)
    if self.OnShow_Original then self:OnShow_Original() end
    DM.GUI:UpdatePlaterOverlayStatus()
  end)
  -- DM.GUI:UpdatePlaterOverlayStatus() -- Initial check when GUI is created (if frame is already shown, OnShow will handle)

  -- Initialize Tabs
  local tabInfo = {
    -- ... existing code ...
  }

  return frame
end

-- Function to create the tab group and tabs
function DM.GUI:CreateTabs(parent, tabInfo)
  local tabGroup = CreateFrame("Frame", nil, parent)
  tabGroup:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -40)
  tabGroup:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
  DM.GUI.frame.tabGroup = tabGroup -- Store reference to tabGroup

  local currentY = 0
  local tabWidth = 110
  local tabHeight = 28

  -- Set the numTabs property on the parent frame - CRITICAL for PanelTemplates_UpdateTabs
  parent.numTabs = #tabInfo

  for i, info in ipairs(tabInfo) do
    local tab = CreateFrame("Button", "DotMasterTab" .. i, tabGroup, "CharacterFrameTabButtonTemplate")
    tab:SetSize(tabWidth, tabHeight)
    tab:SetPoint("TOPLEFT", tabGroup, "TOPLEFT", (i - 1) * (tabWidth - 13), currentY)
    tab:SetText(info.name)
    tab.id = i

    local content = CreateFrame("Frame", "DotMasterTabContent" .. i, tabGroup)
    content:SetAllPoints(tabGroup)
    content:Hide()
    info.createFunc(content) -- Call the function to populate the tab content

    tab.content = content
    DM.GUI.tabs[i] = tab

    tab:SetScript("OnClick", function(self)
      DM.GUI:SelectTab(self.id)
    end)
  end

  return tabGroup
end

-- Function to select a tab
function DM.GUI:SelectTab(tabID)
  -- Safety check: ensure frame.numTabs is properly set
  if not DM.GUI.frame.numTabs then
    DM.GUI.frame.numTabs = #DM.GUI.tabs
  end

  -- Set the tab with WoW's built-in system
  PanelTemplates_SetTab(DM.GUI.frame, tabID)

  -- Handle the custom tab frames (DotMasterTabFrame1, etc.)
  for i = 1, 4 do
    local tabFrame = _G["DotMasterTabFrame" .. i]
    if tabFrame then
      if i == tabID then
        tabFrame:Show()
      else
        tabFrame:Hide()
      end
    end
  end

  -- Handle the template-based tab content
  for i, tab in ipairs(DM.GUI.tabs) do
    if i == tabID then
      if tab.content then tab.content:Show() end
      if tab.OnShow then tab.OnShow() end
    else
      if tab.content then tab.content:Hide() end
    end
  end

  -- Force a visual refresh of tab button appearance
  for i = 1, 4 do
    local tabButton = _G["DotMasterTab" .. i]
    if tabButton and tabButton.normalTexture then
      if i == tabID then
        -- Active tab
        tabButton.normalTexture:SetColorTexture(0.2, 0.2, 0.2, 0.8)
      else
        -- Inactive tab
        tabButton.normalTexture:SetColorTexture(0, 0, 0, 0.7)
      end
    end
  end

  -- Refresh appropriate tab content when clicked
  if tabID == 2 then -- Tracked Spells tab
    if DM.GUI.RefreshTrackedSpellTabList then
      DM.GUI:RefreshTrackedSpellTabList("")
    end
  elseif tabID == 4 then -- Database tab
    if DM.GUI.RefreshDatabaseTabList then
      DM.GUI:RefreshDatabaseTabList("")
    end
  end

  PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
end

-- Original CreateFooterMessage and UpdatePlaterStatusFooter can be removed later
-- if the new overlay system fully replaces their functionality.

function DM.GUI:ShowHelpPopup()
  if not DM.GUI.HelpPopupFrame then
    local helpFrame = CreateFrame("Frame", "DotMasterHelpPopupFrame", UIParent, "BackdropTemplate")
    helpFrame:SetSize(550, 450)      -- Increased height for more content
    helpFrame:SetPoint("CENTER")
    helpFrame:SetFrameStrata("HIGH") -- Ensure it's above the main options
    helpFrame:SetMovable(true)
    helpFrame:EnableMouse(true)
    helpFrame:RegisterForDrag("LeftButton")
    helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
    helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
    helpFrame:Hide()

    helpFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    helpFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95) -- Darker backdrop
    helpFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

    local title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("DotMaster Guide")

    local scrollFrame = CreateFrame("ScrollFrame", nil, helpFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 40)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1000) -- Initial height, will adjust
    scrollFrame:SetScrollChild(scrollChild)

    local helpText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", 5, -5)
    helpText:SetPoint("TOPRIGHT", -5, -5)
    helpText:SetJustifyH("LEFT")
    helpText:SetJustifyV("TOP")
    helpText:SetSpacing(4) -- Line spacing

    local text = ""
    text = text ..
        "Welcome to DotMaster! This addon helps you track your Damage over Time effects (DoTs) and other important buffs/debuffs by coloring Plater nameplates."

    text = text .. "\n\n" ..
        "|cFFFFD100Key Features:|r\n" ..
        "- Automatic DoT Detection: Finds your DoTs as you play.\n" ..
        "- Customizable Tracking: Choose which spells to track, their colors, and priorities.\n" ..
        "- Plater Integration: Seamlessly colors Plater nameplates based on your DoTs.\n" ..
        "- Spell Combinations: Group multiple DoTs into a single, prioritized visual.\n" ..
        "- Class and Spec Awareness: Works with any class and specialization."

    text = text .. "\n\n" ..
        "|cFFFFD100GUI Tabs Overview:|r\n" ..
        "- |cFFADD8E6General Tab:|r Configure core DotMaster settings, Plater integration, minimap icon, and appearance options like border logic.\n" ..
        "- |cFFADD8E6Tracked Spells Tab:|r Manage individual spells. Enable/disable tracking, set custom colors, and assign priorities for display.\n" ..
        "- |cFFADD8E6Combinations Tab:|r Create and manage spell combinations. Define sets of spells that should be treated as a single, powerful effect with its own color and priority.\n" ..
        "- |cFFADD8E6Database Tab:|r View all spells DotMaster has detected. Use the \"Find My Dots\" feature to discover new spells cast by your character."

    text = text .. "\n\n" ..
        "|cFFFFD100Getting Started:|r\n" ..
        "1. Open DotMaster settings with /dm.\n" ..
        "2. Go to the 'Database' tab and click 'Find My Dots'. Cast your spells on a target dummy for about 30 seconds.\n" ..
        "3. Click 'Add Selected Dots' to add newly detected spells to your database.\n" ..
        "4. Navigate to the 'Tracked Spells' tab. Here you can enable/disable spells, change their colors, and set priorities (lower numbers are higher priority).\n" ..
        "5. (Optional) Go to the 'Combinations' tab to group multiple spells into a single visual effect with its own color and priority.\n" ..
        "6. Ensure Plater Nameplates addon is enabled. DotMaster will automatically integrate."

    text = text .. "\n\n" ..
        "|cFFFFD100Tips for Best Use:|r\n" ..
        "- If Plater integration isn't working, ensure Plater is updated and try clicking the 'Install Plater Integration' button in DotMaster's General tab if it appears.\n" ..
        "- Some settings, like border thickness, may require a UI reload (/reload) to take full effect."

    helpText:SetText(text)
    scrollChild:SetHeight(helpText:GetHeight() + 10)

    local closeButton = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -4, -4)

    DM.GUI.HelpPopupFrame = helpFrame
  end
  DM.GUI.HelpPopupFrame:Show()
end
