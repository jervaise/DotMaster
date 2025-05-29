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

  -- Add direct ESC key handling as a backup
  frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      -- self:Hide() -- The frame is in UISpecialFrames, which will handle hiding it.
      -- This handler's primary job is now to stop ESCAPE from propagating further.
      return true -- Return true to stop ESC from propagating to the game menu
    end
    return false  -- Let other keys propagate normally
  end)

  -- Only propagate non-ESC keys
  frame:SetPropagateKeyboardInput(true)

  -- Make the frame closable with the B key (Blizzard standard)
  frame:EnableKeyboard(true)
  frame:SetScript("OnKeyUp", function(self, key)
    -- if key == "ESCAPE" then  -- Removed this block
    --   self:Hide()
    -- end
    -- The 'B' key functionality was previously removed.
    -- ESCAPE key press is now handled by OnKeyDown to also stop propagation.
  end)

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
          "DotMaster is an advanced DoT tracking addon that enhances your enemy nameplates through Plater integration. It visually tracks your damage-over-time and healing-over-time effects with customizable colors, making it easier to manage your DoTs during combat for any class and specialization.",
          yOffset)

    -- Overview Section
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("How DotMaster Works", yOffset)
    yOffset = yOffset -
        CreateText(
          "DotMaster seamlessly integrates with Plater Nameplates to provide real-time visual tracking of your DoTs. When you apply a DoT to a target, its nameplate changes color based on your settings. You can choose to color the entire nameplate or just the border, with custom colors for each spell or combination of spells.",
          yOffset)

    -- Features Section
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Key Features", yOffset)

    -- Feature list with explanations
    yOffset = yOffset -
        CreateFeature("Advanced DoT Tracking",
          "Track all DoTs/HoTs with custom colors on enemy nameplates. Perfect for multi-DoT classes like Warlocks, Shadow Priests, and Affliction specializations.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Combinations Tracking",
          "Create unique colors for when multiple specific DoTs are active on the same target, ideal for complex rotations and priority management.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Border-Only Mode",
          "Keep Plater's health bar colors intact while using borders to track DoTs, maintaining important information like target health percentage.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Expiry Warning",
          "Nameplates flash when DoTs are about to expire, with customizable threshold, interval, and brightness settings.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("M+ Profile Integration",
          "Extend Plater colors option preserves important M+ mob indicators (like casters, healers, etc.) while still showing DoT status.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Class & Spec Awareness",
          "Automatically adapts to your current class and specialization with unique settings for each.",
          yOffset)

    -- Settings Section
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Getting Started", yOffset)

    yOffset = yOffset -
        CreateText(
          "1. |cFFFFD100Enable DotMaster|r - Open the addon with /dm and check 'Enable DotMaster' in the General tab\n" ..
          "2. |cFFFFD100Install Plater Integration|r - Click the 'Install Plater Integration' button if prompted\n" ..
          "3. |cFFFFD100Add DoTs to Track|r - Go to the Tracked Spells tab and add spells you want to monitor\n" ..
          "4. |cFFFFD100Customize Colors|r - Assign unique colors to each spell for easy recognition\n" ..
          "5. |cFFFFD100Create Combinations|r - Set up spell combinations in the Combinations tab for more advanced tracking\n" ..
          "6. |cFFFFD100Adjust Visual Settings|r - Fine-tune border thickness, expiry flash settings, and other visual preferences",
          yOffset)

    -- Tab Explanations
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Understanding the Tabs", yOffset)

    yOffset = yOffset -
        CreateFeature("General Tab",
          "Core settings including enabling/disabling the addon, Plater integration, minimap icon, border behavior, and expiry flash settings. This is where you control how DotMaster looks and behaves.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Tracked Spells Tab",
          "Manage which spells DotMaster monitors. Add spells, set unique colors, and define display priorities. Higher priority spells take precedence when multiple DoTs are active.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Combinations Tab",
          "Create and manage spell combinations. Define spell groups that should display a unique color when all spells in the group are active on the same target, perfect for complex rotations.",
          yOffset)
    yOffset = yOffset -
        CreateFeature("Database Tab",
          "View all spells DotMaster has detected from your character. Use the 'Find My Dots' feature to discover and track new spells as you cast them.",
          yOffset)

    -- Visual Settings Explained
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Visual Options Explained", yOffset)

    yOffset = yOffset -
        CreateText(
          "|cFFFFD100Border Logic:|r\n" ..
          "• |cFFADD8E6Extend Plater Colors to Borders:|r Preserves Plater's M+ color coding for important mobs in borders\n" ..
          "• |cFFADD8E6Use Borders for DoT Tracking:|r Only changes border color instead of the entire health bar\n" ..
          "• |cFFADD8E6Border Thickness:|r Adjusts the thickness of nameplate borders (requires UI reload)\n\n" ..
          "|cFFFFD100Expiry Warning:|r\n" ..
          "• |cFFADD8E6Expiry Flash:|r Enables flashing when DoTs are about to expire\n" ..
          "• |cFFADD8E6Seconds:|r How many seconds before expiration the flashing begins\n" ..
          "• |cFFADD8E6Interval:|r Controls how quickly the nameplate flashes\n" ..
          "• |cFFADD8E6Brightness:|r Adjusts the intensity of the flashing effect",
          yOffset)

    -- Pro Tips
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Pro Tips", yOffset)

    yOffset = yOffset -
        CreateText(
          "• |cFFFFD100Color Strategy:|r Use bright colors for high-priority DoTs and softer colors for maintenance DoTs\n" ..
          "• |cFFFFD100Border-Only Mode:|r Ideal for tanks and M+ where health percentages are critical information\n" ..
          "• |cFFFFD100Combination Priority:|r Set higher priority for your core DoT combinations to ensure they're always visible\n" ..
          "• |cFFFFD100Custom Per Spec:|r Configure different tracking settings for different specializations (e.g., Shadow vs Discipline)\n" ..
          "• |cFFFFD100Find My Dots:|r Cast your spells once to auto-detect them if you're unsure of spell IDs",
          yOffset)

    -- Troubleshooting
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Troubleshooting", yOffset)

    yOffset = yOffset -
        CreateText(
          "• |cFFFFD100Colors Not Showing:|r Ensure DotMaster is enabled and Plater integration is installed\n" ..
          "• |cFFFFD100Missing Spells:|r Use the Database tab's 'Find My Dots' feature to detect your spells\n" ..
          "• |cFFFFD100UI Reload Prompt:|r Some settings (like border thickness) require a UI reload to take effect\n" ..
          "• |cFFFFD100Plater Updates:|r If you update Plater, you may need to reinstall the DotMaster integration\n" ..
          "• |cFFFFD100Reset Option:|r Use /dm reset if you need to start fresh with default settings",
          yOffset)

    -- Footer
    yOffset = yOffset - 20 -- Extra space
    yOffset = yOffset - CreateSection("Commands & Resources", yOffset)
    yOffset = yOffset -
        CreateText(
          "|cFFFFD100Slash Commands:|r\n" ..
          "• |cFFADD8E6/dm|r or |cFFADD8E6/dotmaster|r - Toggle the main interface\n" ..
          "• |cFFADD8E6/dm minimap|r - Toggle minimap icon\n" ..
          "• |cFFADD8E6/dm reset|r - Reset to default settings\n" ..
          "• |cFFADD8E6/dm version|r - Display current version\n\n" ..
          "For additional support and the latest updates, visit the addon page on CurseForge, Wago, or GitHub.",
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
      DM:AutoSave()
    end

    -- Get current settings
    local settings = DM.API:GetSettings()

    -- Ensure sessionStartSettings exists
    if not DM.sessionStartSettings then
      DM.sessionStartSettings = {
        borderThickness = nil,
        borderOnly = nil
      }

      -- Initialize with current settings
      if DotMasterDB and DotMasterDB.settings then
        DM.sessionStartSettings.borderThickness = DotMasterDB.settings.borderThickness
        DM.sessionStartSettings.borderOnly = DotMasterDB.settings.borderOnly
      end
    end

    -- Check for changes by direct comparison with SESSION start values
    local settingsChanged = false
    local changedSettings = {}

    -- Compare border thickness with session start value (convert to numbers for proper comparison)
    if tonumber(settings.borderThickness) ~= tonumber(DM.sessionStartSettings.borderThickness) then
      settingsChanged = true
      table.insert(changedSettings, "Border Thickness")
    end

    -- Compare border only mode with session start value (convert to boolean for proper comparison)
    local currentBorderOnly = settings.borderOnly and true or false
    local sessionStartBorderOnly = DM.sessionStartSettings.borderOnly and true or false
    if currentBorderOnly ~= sessionStartBorderOnly then
      settingsChanged = true
      table.insert(changedSettings, "Border Only Mode")
    end

    -- Update saved settings in DB
    if DotMasterDB and DotMasterDB.settings then
      DotMasterDB.settings.borderThickness = settings.borderThickness
      DotMasterDB.settings.borderOnly = settings.borderOnly
    end

    -- Force push to DotMaster Integration with current settings
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
    end

    if DM.UpdatePlaterStatusFooter then
      DM:UpdatePlaterStatusFooter()
    end

    -- Show reload UI prompt if settings changed
    if settingsChanged then
      -- First hide any existing dialog
      StaticPopup_Hide("DOTMASTER_RELOAD_NEEDED")

      -- Simplified reload dialog
      StaticPopupDialogs["DOTMASTER_RELOAD_NEEDED"] = {
        text = "You need to reload your UI to apply border settings changes.",
        button1 = "Reload Now",
        button2 = "Later",
        OnAccept = function()
          -- Update session start values before reload
          DM.sessionStartSettings.borderThickness = settings.borderThickness
          DM.sessionStartSettings.borderOnly = settings.borderOnly
          ReloadUI()
        end,
        OnCancel = function()
          -- Update session start values to avoid repeated prompts
          DM.sessionStartSettings.borderThickness = settings.borderThickness
          DM.sessionStartSettings.borderOnly = settings.borderOnly
          DM:PrintMessage("Remember to reload your UI to fully apply border settings changes.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true,
      }

      -- Give a small delay before showing the dialog
      C_Timer.After(0.1, function()
        -- Force a specific dialog at a global level
        _G["StaticPopup_Show"]("DOTMASTER_RELOAD_NEEDED")
      end)
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

  -- Create tab system with modern UI/UX design
  local tabHeight = 40 -- Increased from 30 for better touch targets
  local tabFrames = {}
  local tabButtons = {}
  DM.GUI.tabFrames = tabFrames
  DM.GUI.tabButtons = tabButtons
  DM.GUI.activeTabID = 1 -- Track the active tab ID

  -- Tab names and order
  local tabNames = {
    "General",
    "Tracked Spells",
    "Combinations",
    "Database"
  }

  -- Create modern tab container with full-width background
  local tabContainer = CreateFrame("Frame", nil, frame)
  tabContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -40)
  tabContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -40)
  tabContainer:SetHeight(tabHeight)

  -- Modern gradient background for tab container
  local tabContainerBg = tabContainer:CreateTexture(nil, "BACKGROUND")
  tabContainerBg:SetAllPoints()
  tabContainerBg:SetColorTexture(0.08, 0.08, 0.08, 0.95) -- Dark modern background

  -- Add subtle top border
  local topBorder = tabContainer:CreateTexture(nil, "BORDER")
  topBorder:SetHeight(1)
  topBorder:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 0, 0)
  topBorder:SetPoint("TOPRIGHT", tabContainer, "TOPRIGHT", 0, 0)
  topBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)

  -- Add subtle bottom border with accent color
  local bottomBorder = tabContainer:CreateTexture(nil, "BORDER")
  bottomBorder:SetHeight(2)
  bottomBorder:SetPoint("BOTTOMLEFT", tabContainer, "BOTTOMLEFT", 0, 0)
  bottomBorder:SetPoint("BOTTOMRIGHT", tabContainer, "BOTTOMRIGHT", 0, 0)
  bottomBorder:SetColorTexture(0.2, 0.4, 0.8, 0.6) -- Subtle blue accent

  -- Calculate tab width to span full container width
  local containerPadding = 16 -- 8px padding on each side
  local tabSpacing = 2        -- Minimal spacing between tabs
  local totalSpacing = (tabSpacing * (#tabNames - 1))
  local availableWidth = frame:GetWidth() - containerPadding
  local tabWidth = (availableWidth - totalSpacing) / #tabNames

  -- Create each tab frame and button
  for i = 1, #tabNames do
    -- Tab content frame
    tabFrames[i] = CreateFrame("Frame", "DotMasterTabFrame" .. i, frame)
    tabFrames[i]:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -(40 + tabHeight))
    tabFrames[i]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 60)
    tabFrames[i]:Hide()

    -- Modern tab button with full width coverage
    local tabButton = CreateFrame("Button", "DotMasterTab" .. i, tabContainer)
    tabButton:SetHeight(tabHeight)
    tabButton:SetWidth(tabWidth)
    tabButtons[i] = tabButton

    -- Position tabs to span full width
    local xOffset = 8 + (i - 1) * (tabWidth + tabSpacing) -- Start with 8px padding
    tabButton:SetPoint("LEFT", tabContainer, "LEFT", xOffset, 0)

    -- Modern tab styling with layered approach
    -- Base background (inactive state)
    local baseTexture = tabButton:CreateTexture(nil, "BACKGROUND", nil, 0)
    baseTexture:SetAllPoints()
    baseTexture:SetColorTexture(0.12, 0.12, 0.12, 0.8) -- Slightly lighter than container
    tabButton.baseTexture = baseTexture

    -- Active state overlay
    local activeTexture = tabButton:CreateTexture(nil, "BACKGROUND", nil, 1)
    activeTexture:SetAllPoints()
    activeTexture:SetColorTexture(0.18, 0.18, 0.18, 0.95) -- Lighter for active state
    activeTexture:Hide()
    tabButton.activeTexture = activeTexture

    -- Hover state overlay
    local hoverTexture = tabButton:CreateTexture(nil, "BACKGROUND", nil, 2)
    hoverTexture:SetAllPoints()
    hoverTexture:SetColorTexture(0.15, 0.15, 0.15, 0.9) -- Medium shade for hover
    hoverTexture:Hide()
    tabButton.hoverTexture = hoverTexture

    -- Active indicator line at bottom
    local activeIndicator = tabButton:CreateTexture(nil, "OVERLAY")
    activeIndicator:SetHeight(3)
    activeIndicator:SetPoint("BOTTOMLEFT", tabButton, "BOTTOMLEFT", 4, 0)
    activeIndicator:SetPoint("BOTTOMRIGHT", tabButton, "BOTTOMRIGHT", -4, 0)
    activeIndicator:SetColorTexture(0.3, 0.6, 1.0, 1.0) -- Modern blue accent
    activeIndicator:Hide()
    tabButton.activeIndicator = activeIndicator

    -- Modern typography
    local text = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(tabNames[i])
    text:SetTextColor(0.85, 0.85, 0.85)                -- Softer white for better readability
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Slightly larger, outlined text
    tabButton.text = text

    -- Modern interaction states
    tabButton:SetScript("OnEnter", function(self)
      if self.id ~= DM.GUI.activeTabID then
        self.hoverTexture:Show()
        self.text:SetTextColor(1.0, 1.0, 1.0) -- Brighter on hover
      end
      -- Subtle scale animation could be added here in future
    end)

    tabButton:SetScript("OnLeave", function(self)
      if self.id ~= DM.GUI.activeTabID then
        self.hoverTexture:Hide()
        self.text:SetTextColor(0.85, 0.85, 0.85) -- Return to normal
      end
    end)

    -- Store ID and click handler
    tabButton.id = i
    tabButton:SetScript("OnClick", function(self)
      DM.GUI:SelectTab(self.id)
    end)
  end

  -- Set initial active tab styling
  if tabButtons[1] then
    tabButtons[1].activeTexture:Show()
    tabButtons[1].activeIndicator:Show()
    tabButtons[1].text:SetTextColor(1.0, 1.0, 1.0) -- Bright white for active
  end
  tabFrames[1]:Show()

  -- Create tab content
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

  -- Create Database tab content
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

    -- Ensure sessionStartSettings exists
    if not DM.sessionStartSettings then
      DM.sessionStartSettings = {
        borderThickness = nil,
        borderOnly = nil
      }

      -- Initialize with current settings to avoid false positives on first window open/close
      if DotMasterDB and DotMasterDB.settings then
        local settings = DM.API:GetSettings()
        DM.sessionStartSettings.borderThickness = settings.borderThickness
        DM.sessionStartSettings.borderOnly = settings.borderOnly
      end
    end

    DM.GUI:UpdatePlaterOverlayStatus()
  end)

  return frame
end

-- Function to create the tab group and tabs
function DM.GUI:CreateTabs(parent, tabInfo)
  -- This function is no longer used after removing tab system
  -- Keeping as stub for compatibility
end

-- Function to select a tab
function DM.GUI:SelectTab(tabID)
  -- Safety checks
  if not DM.GUI or not DM.GUI.tabFrames or not DM.GUI.tabButtons then
    return false
  end

  -- Ensure tabID is valid
  if not tabID or type(tabID) ~= "number" or tabID < 1 or tabID > #DM.GUI.tabFrames then
    return false
  end

  -- Store the active tab ID
  DM.GUI.activeTabID = tabID

  -- Hide all tab frames and reset button appearance to inactive state
  for i = 1, #DM.GUI.tabFrames do
    if DM.GUI.tabFrames[i] then
      DM.GUI.tabFrames[i]:Hide()
    end

    -- Reset all tabs to inactive state with modern styling
    if DM.GUI.tabButtons[i] then
      local button = DM.GUI.tabButtons[i]

      -- Hide active state elements
      if button.activeTexture then
        button.activeTexture:Hide()
      end
      if button.activeIndicator then
        button.activeIndicator:Hide()
      end
      if button.hoverTexture then
        button.hoverTexture:Hide()
      end

      -- Set inactive text color
      if button.text then
        button.text:SetTextColor(0.85, 0.85, 0.85)
      end
    end
  end

  -- Show selected tab content
  if DM.GUI.tabFrames[tabID] then
    DM.GUI.tabFrames[tabID]:Show()
  else
    print("Error: Tab content frame " .. tabID .. " not found")
    return false
  end

  -- Set active tab appearance with modern styling
  if DM.GUI.tabButtons[tabID] then
    local activeButton = DM.GUI.tabButtons[tabID]

    -- Show active state elements
    if activeButton.activeTexture then
      activeButton.activeTexture:Show()
    end
    if activeButton.activeIndicator then
      activeButton.activeIndicator:Show()
    end

    -- Set active text color
    if activeButton.text then
      activeButton.text:SetTextColor(1.0, 1.0, 1.0) -- Bright white for active
    end
  end

  -- Refresh appropriate tab content when clicked
  if tabID == 2 then -- Tracked Spells tab
    if DM.GUI.RefreshTrackedSpellTabList then
      pcall(function() DM.GUI:RefreshTrackedSpellTabList("") end)
    end
  elseif tabID == 4 then -- Database tab
    if DM.GUI.RefreshDatabaseTabList then
      pcall(function() DM.GUI:RefreshDatabaseTabList("") end)
    end
  end

  -- Play sound if available
  if SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB then
    pcall(function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end)
  end

  return true
end

-- Function to restore tab state after zone changes
function DM.GUI:RestoreTabState()
  -- Check if we have a stored active tab
  if DM.GUI and DM.GUI.activeTabID then
    -- Reselect the active tab
    DM.GUI:SelectTab(DM.GUI.activeTabID)
  end
end

-- Create and register event frame for zone changes and loading screens
local loadingEventFrame = CreateFrame("Frame")
loadingEventFrame.eventCount = 0
-- Only register for the event that signifies a loading screen has started
-- loadingEventFrame:RegisterEvent("ZONE_CHANGED")
-- loadingEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- loadingEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- loadingEventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
loadingEventFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
-- loadingEventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

-- Keep a permanent reference to prevent garbage collection
DM.loadingEventFrame = loadingEventFrame

-- For debugging, keep track of which events have fired
DM.loadingEventCounts = DM.loadingEventCounts or {}

-- Function to forcibly close the GUI
local function ForceCloseGUI(event)
  -- Always close the GUI during loading screens, regardless of state
  if DM.GUI and DM.GUI.frame then
    if DM.GUI.frame:IsShown() then
      DM.GUI.frame:Hide()
    end
  end
end

loadingEventFrame:SetScript("OnEvent", function(self, event, ...)
  -- Update event counters for debugging
  DM.loadingEventCounts[event] = (DM.loadingEventCounts[event] or 0) + 1
  self.eventCount = self.eventCount + 1

  -- Only act if the loading screen is enabled
  if event == "LOADING_SCREEN_ENABLED" then
    ForceCloseGUI(event)
  end
  -- No longer need to handle other events for closing the GUI
end)

-- Function to toggle the main GUI visibility
function DM:ToggleGUI()
  -- If frame exists, toggle its visibility
  if DM.GUI and DM.GUI.frame then
    if DM.GUI.frame:IsShown() then
      DM.GUI.frame:Hide()
    else
      -- Ensure we restore last active tab before showing
      DM.GUI.frame:Show()

      -- Select the active tab
      if DM.GUI.activeTabID then
        DM.GUI:SelectTab(DM.GUI.activeTabID)
      end
    end
  else
    -- Create GUI if it doesn't exist
    DM.GUI.frame = DM:CreateGUI()
    DM.GUI.frame:Show()
  end
end

-- Function to handle minimap icon click
function DM:MinimapIconClicked()
  -- Always use the toggle function
  DM:ToggleGUI()
end

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
