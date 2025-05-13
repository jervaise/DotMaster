-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  if not DotMasterDB then DotMasterDB = {} end
  if not DotMasterDB.settings then DotMasterDB.settings = {} end

  -- Make sure the enabled state is properly saved
  DotMasterDB.enabled = DM.enabled

  -- Log the enabled state being saved
  print("DotMaster: Saving enabled state: " .. (DM.enabled and "ENABLED" or "DISABLED"))

  -- Ensure all settings are in the right format before saving
  DotMasterDB.settings.forceColor = DM.API:GetSettings().forceColor and true or false
  DotMasterDB.settings.borderOnly = DM.API:GetSettings().borderOnly and true or false
  DotMasterDB.settings.borderThickness = DM.API:GetSettings().borderThickness
  DotMasterDB.settings.flashExpiring = DM.API:GetSettings().flashExpiring and true or false
  DotMasterDB.settings.flashThresholdSeconds = DM.API:GetSettings().flashThresholdSeconds

  -- Log values being saved
  print("DotMaster: Saved Force Color: " .. (DotMasterDB.settings.forceColor and "ENABLED" or "DISABLED"))
  print("DotMaster: Saved Border Only: " .. (DotMasterDB.settings.borderOnly and "ENABLED" or "DISABLED"))
  print("DotMaster: Saved Flash Expiring: " .. (DotMasterDB.settings.flashExpiring and "ENABLED" or "DISABLED"))

  -- Save the minimap icon state
  if DM.API:GetSettings().minimapIcon then
    DotMasterDB.minimapIcon = DM.API:GetSettings().minimapIcon
  end

  -- Save current settings to class/spec profile
  if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
    DM.ClassSpec:SaveCurrentSettings()
  end

  -- DIRECTLY reinstall the Plater mod with these settings
  -- Note: This may be temporarily disabled by AutoSave to prevent double-pushing
  if self.InstallPlaterMod then
    DM:PrintMessage("Embedding your current DotMaster configuration into bokmaster...")
    self:InstallPlaterMod()
  end
end

-- Load settings from saved variables
function DM:LoadSettings()
  print("DotMaster: Loading settings...")

  -- Initialize DB if needed
  if not DotMasterDB then
    DotMasterDB = {}
    print("DotMaster: Initialized new settings database")
  end

  -- Explicitly make sure enabled is a boolean to prevent type errors
  if DotMasterDB.enabled == nil then
    print("DotMaster: No enabled state found in database, defaulting to DISABLED")
    DotMasterDB.enabled = false
  elseif type(DotMasterDB.enabled) ~= "boolean" then
    print("DotMaster: WARNING - Found non-boolean enabled state, fixing")
    DotMasterDB.enabled = (DotMasterDB.enabled == true)
  end

  -- CRITICAL FIX: Remove 'enabled' setting from all class/spec profiles
  -- to prevent class-specific override of global enabled state
  if DotMasterDB.classProfiles then
    print("DotMaster: Checking for enabled settings in class profiles...")
    local fixedAny = false
    for className, classData in pairs(DotMasterDB.classProfiles) do
      for specID, specData in pairs(classData) do
        if specData.settings and specData.settings.enabled ~= nil then
          print("DotMaster: FIXING - Removed enabled=" ..
            (specData.settings.enabled and "true" or "false") ..
            " from " .. className .. " spec #" .. specID)
          specData.settings.enabled = nil
          fixedAny = true
        end
      end
    end
    if fixedAny then
      print("DotMaster: Fixed class/spec profiles - enabled setting should now be global only")
    else
      print("DotMaster: No class/spec profiles had enabled setting - good!")
    end
  end

  -- Fix corrupted settings
  if DotMasterDB and DotMasterDB.enabled ~= nil then
    print("DotMaster: Enabled state found in database: " .. (DotMasterDB.enabled and "ENABLED" or "DISABLED"))

    -- Ensure settings table exists
    if not DotMasterDB.settings then
      print("DotMaster: Settings table missing - creating new settings table")
      DotMasterDB.settings = {}
    end

    -- Check for specific missing/corrupted settings
    if DotMasterDB.settings.forceColor == nil then
      print("DotMaster: Force Threat Color setting missing - initializing to default")
      DotMasterDB.settings.forceColor = false
    elseif type(DotMasterDB.settings.forceColor) ~= "boolean" then
      print("DotMaster: Force Threat Color setting corrupted - fixing")
      DotMasterDB.settings.forceColor = (DotMasterDB.settings.forceColor == true)
    end

    if DotMasterDB.settings.borderOnly == nil then
      print("DotMaster: Border Only setting missing - initializing to default")
      DotMasterDB.settings.borderOnly = false
    elseif type(DotMasterDB.settings.borderOnly) ~= "boolean" then
      print("DotMaster: Border Only setting corrupted - fixing")
      DotMasterDB.settings.borderOnly = (DotMasterDB.settings.borderOnly == true)
    end

    if DotMasterDB.settings.flashExpiring == nil then
      print("DotMaster: Flash Expiring setting missing - initializing to default")
      DotMasterDB.settings.flashExpiring = false
    elseif type(DotMasterDB.settings.flashExpiring) ~= "boolean" then
      print("DotMaster: Flash Expiring setting corrupted - fixing")
      DotMasterDB.settings.flashExpiring = (DotMasterDB.settings.flashExpiring == true)
    end
  end

  -- Initialize API settings with defaults
  local settings = {
    enabled = false, -- Default to false to ensure we read from saved variables
    forceColor = false,
    borderOnly = false,
    borderThickness = 2,
    flashExpiring = false,
    flashThresholdSeconds = 3.0,
    minimapIcon = { hide = false }
  }

  -- CRITICAL: Explicitly set enabled state from DotMasterDB
  if DotMasterDB then
    settings.enabled = DotMasterDB.enabled
    print("DotMaster: Loading enabled state from DB: " .. (settings.enabled and "ENABLED" or "DISABLED"))
  end

  -- Load settings from saved variables if available
  if DotMasterDB.settings then
    if DotMasterDB.settings.forceColor ~= nil then
      settings.forceColor = DotMasterDB.settings.forceColor
      print("DotMaster: Loaded Force Threat Color setting: " .. (settings.forceColor and "ENABLED" or "DISABLED"))
    end

    if DotMasterDB.settings.borderOnly ~= nil then
      settings.borderOnly = DotMasterDB.settings.borderOnly
      print("DotMaster: Loaded Border Only setting: " .. (settings.borderOnly and "ENABLED" or "DISABLED"))
    end

    if DotMasterDB.settings.borderThickness ~= nil then
      settings.borderThickness = DotMasterDB.settings.borderThickness
      print("DotMaster: Loaded Border Thickness: " .. settings.borderThickness)
    end

    if DotMasterDB.settings.flashExpiring ~= nil then
      settings.flashExpiring = DotMasterDB.settings.flashExpiring
      print("DotMaster: Loaded Flash Expiring setting: " .. (settings.flashExpiring and "ENABLED" or "DISABLED"))
    end

    if DotMasterDB.settings.flashThresholdSeconds ~= nil then
      settings.flashThresholdSeconds = DotMasterDB.settings.flashThresholdSeconds
      print("DotMaster: Loaded Flash Threshold: " .. settings.flashThresholdSeconds .. " seconds")
    end
  end

  -- Load minimap settings
  if DotMasterDB.minimap then
    settings.minimapIcon = DotMasterDB.minimap
    print("DotMaster: Loaded Minimap settings: " .. (settings.minimapIcon.hide and "HIDDEN" or "SHOWN"))
  end

  -- CRITICAL: Set main enabled state to the DotMasterDB value
  -- This is the main variable that controls addon functionality
  DM.enabled = DotMasterDB.enabled

  print("DotMaster: Settings loaded successfully - addon state: " ..
    (DM.enabled and "ENABLED" or "DISABLED"))

  -- Save to API
  DM.API:SaveSettings(settings)

  -- Initialize class/spec integration
  if DM.ClassSpec and DM.ClassSpec.Initialize then
    DM.ClassSpec:Initialize()
  end

  -- Perform sanity check to ensure consistent state
  C_Timer.After(0.1, function()
    local finalSettings = DM.API:GetSettings()
    if finalSettings.enabled ~= DotMasterDB.enabled then
      print("DotMaster: CRITICAL ERROR - Settings and DotMasterDB enabled states don't match after loading!")
      print("DotMaster: Forcing enabled state to match DotMasterDB: " ..
        (DotMasterDB.enabled and "ENABLED" or "DISABLED"))
      finalSettings.enabled = DotMasterDB.enabled
      DM.enabled = DotMasterDB.enabled
      DM.API:SaveSettings(finalSettings)
    end
  end)
end

-- Tracks if border settings have been changed during this session
function DM:TrackBorderThicknessChange()
  -- Get current settings
  local settings = DM.API:GetSettings()
  local currentThickness = settings.borderThickness
  local currentBorderOnly = settings.borderOnly and true or false -- Force to boolean
  local currentEnabled = settings.enabled and true or false       -- Track enabled state

  -- Initialize original values if not set
  if not DM.originalBorderThickness then
    -- Use DotMasterDB directly if available
    if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness then
      DM.originalBorderThickness = DotMasterDB.settings.borderThickness
    else
      DM.originalBorderThickness = currentThickness
    end

    print("|cFFFF9900DotMaster-Debug: Original thickness initialized to " .. DM.originalBorderThickness .. "|r")

    -- Also initialize original border-only state
    if DotMasterDB and DotMasterDB.settings then
      DM.originalBorderOnly = DotMasterDB.settings.borderOnly and true or false -- Force to boolean
    else
      DM.originalBorderOnly = currentBorderOnly
    end

    print("|cFFFF9900DotMaster-Debug: Original border-only state initialized to " ..
      (DM.originalBorderOnly and "ENABLED" or "DISABLED") .. "|r")

    -- Initialize original enabled state
    if DotMasterDB then
      DM.originalEnabled = DotMasterDB.enabled and true or false -- Force to boolean
    else
      DM.originalEnabled = currentEnabled
    end

    print("|cFFFF9900DotMaster-Debug: Original enabled state initialized to " ..
      (DM.originalEnabled and "ENABLED" or "DISABLED") .. "|r")

    print("|cFFFF9900DotMaster-Debug: Border settings initialized and tracking active|r")
    return false
  end

  -- Check all states (thickness, border-only, and enabled)
  -- Convert everything to same type (number for thickness, boolean for others)
  local thicknessChanged = tonumber(DM.originalBorderThickness) ~= tonumber(currentThickness)
  local borderOnlyChanged = (DM.originalBorderOnly and true or false) ~= (currentBorderOnly and true or false)
  local enabledChanged = (DM.originalEnabled and true or false) ~= (currentEnabled and true or false)

  -- Debug output for all tracked settings
  print("|cFFFF9900DotMaster-Debug: Thickness check - Original: " .. DM.originalBorderThickness ..
    " Current: " .. currentThickness .. " Changed: " .. tostring(thicknessChanged) .. "|r")

  print("|cFFFF9900DotMaster-Debug: Border-only check - Original: " ..
    (DM.originalBorderOnly and "ENABLED" or "DISABLED") ..
    " Current: " .. (currentBorderOnly and "ENABLED" or "DISABLED") ..
    " Changed: " .. tostring(borderOnlyChanged) .. "|r")

  print("|cFFFF9900DotMaster-Debug: Enabled check - Original: " ..
    (DM.originalEnabled and "ENABLED" or "DISABLED") ..
    " Current: " .. (currentEnabled and "ENABLED" or "DISABLED") ..
    " Changed: " .. tostring(enabledChanged) .. "|r")

  -- Return true if any setting has changed
  return thicknessChanged or borderOnlyChanged or enabledChanged
end

-- Shows reload UI popup for border settings changes
function DM:ShowReloadUIPopupForBorderThickness()
  -- Force creation of popup dialog template
  if not StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"] then
    StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"] = {
      text = "Border settings have changed.\n\nReload UI to fully apply these changes?",
      button1 = "Reload Now",
      button2 = "Later",
      OnAccept = function()
        ReloadUI()
      end,
      OnCancel = function()
        DM:PrintMessage("Remember to reload your UI to fully apply border setting changes.")
        -- Update the stored original values to prevent repeated prompts
        local settings = DM.API:GetSettings()
        DM.originalBorderThickness = settings.borderThickness
        DM.originalBorderOnly = settings.borderOnly
        DM.originalEnabled = settings.enabled -- Update enabled state too
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
  end

  local settings = DM.API:GetSettings()

  -- Do one more explicit check to avoid false positives
  if not DM.originalBorderThickness or not DM.originalBorderOnly or not DM.originalEnabled then
    print("|cFFFF9900DotMaster-Debug: Cannot verify changes - original values not initialized|r")
    return false
  end

  -- Double-check for actual changes using strict typing
  local currentThickness = tonumber(settings.borderThickness)
  local originalThickness = tonumber(DM.originalBorderThickness)
  local currentBorderOnly = settings.borderOnly and true or false
  local originalBorderOnly = DM.originalBorderOnly and true or false
  local currentEnabled = settings.enabled and true or false
  local originalEnabled = DM.originalEnabled and true or false

  local thicknessChanged = currentThickness ~= originalThickness
  local borderOnlyChanged = currentBorderOnly ~= originalBorderOnly
  local enabledChanged = currentEnabled ~= originalEnabled

  -- Only proceed if there are actual changes
  if not (thicknessChanged or borderOnlyChanged or enabledChanged) then
    print("|cFFFF9900DotMaster-Debug: No actual changes detected, skipping reload popup|r")
    return false
  end

  -- If we made it here, there are real changes
  print("|cFFFF9900DotMaster-Debug: Verified actual changes - showing reload popup|r")

  -- Simplify the popup message to be more generic
  local changedSettings = {}

  -- Identify which settings changed (for debugging purposes)
  if thicknessChanged then
    table.insert(changedSettings, "thickness")
  end
  if borderOnlyChanged then
    table.insert(changedSettings, "border-only mode")
  end
  if enabledChanged then
    table.insert(changedSettings, "enabled state")
  end

  -- Use a simple generic message instead of detailed changes
  StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"].text =
  "Border settings have changed.\n\nReload UI to fully apply these changes?";

  print("|cFFFF9900DotMaster-Debug: Showing reload popup for border setting changes: " ..
    table.concat(changedSettings, ", ") .. "|r")

  -- Show the popup
  StaticPopup_Show("DOTMASTER_RELOAD_CONFIRM")
  return true
end

-- Force push settings to bokmaster
function DM:ForcePushToBokmaster()
  if DM.InstallPlaterMod then
    DM:PrintMessage("Force pushing current settings to bokmaster...")
    DM:InstallPlaterMod()
    return true
  else
    DM:PrintMessage("Error: bokmaster installation function not found")
    return false
  end
end

-- Initialize the main slash commands
function DM:InitializeMainSlashCommands()
  SLASH_DOTMASTER1 = "/dm"
  SlashCmdList["DOTMASTER"] = function(msg)
    -- Use the new HandleSlashCommand function
    DM:HandleSlashCommand(msg)
  end
end

-- Create a function that automatically saves after config changes
function DM:AutoSave()
  -- Create a timer to save settings after a short delay (to avoid excessive saving)
  if DM.saveTimer then
    DM.saveTimer:Cancel()
  end

  -- Update status message if it exists
  if DM.GUI and DM.GUI.statusMessage then
    DM.GUI.statusMessage:SetText("Auto-saving: Pending...")
    DM.GUI.statusMessage:SetTextColor(1, 0.82, 0) -- Gold color for pending
  end

  DM.saveTimer = C_Timer.NewTimer(0.5, function() -- Reduced from 1s to 0.5s for more responsive feel
    -- First update the saved variables with current settings
    -- but don't push to Plater from inside SaveSettings to avoid double-pushing
    -- Store the current InstallPlaterMod function
    local originalInstallPlaterMod = DM.InstallPlaterMod
    DM.InstallPlaterMod = nil -- Temporarily disable so SaveSettings doesn't call it

    -- Save settings
    DM:SaveSettings()

    -- Restore the original function
    DM.InstallPlaterMod = originalInstallPlaterMod

    -- Now push to Plater with a slight delay to ensure settings are fully saved
    C_Timer.After(0.1, function()
      -- Push to Plater with more reliable call
      if DM.InstallPlaterMod then
        DM:PrintMessage("Auto-save: Pushing settings to bokmaster...")
        DM:InstallPlaterMod()
      end

      -- Update class/spec specific settings
      if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
        DM.ClassSpec:SaveCurrentSettings()
      end
    end)

    -- Update status message if it exists
    if DM.GUI and DM.GUI.statusMessage then
      DM.GUI.statusMessage:SetText("Auto-saved & Pushed to Plater")
      DM.GUI.statusMessage:SetTextColor(0.2, 1, 0.2) -- Green for success

      -- Reset back to default message after 2 seconds
      C_Timer.After(2, function()
        if DM.GUI and DM.GUI.statusMessage then
          DM.GUI.statusMessage:SetText("Auto-saving: Enabled")
          DM.GUI.statusMessage:SetTextColor(0.7, 0.7, 0.7)
        end
      end)
    end
  end)
end

-- Handle slash commands
function DM:HandleSlashCommand(message)
  local command, args = strsplit(" ", message, 2)
  command = command and strlower(command) or ""

  -- Make sure to handle both old and new command formats
  if command == "toggle" then
    -- Toggle DotMaster enabled/disabled
    DM.enabled = not DM.enabled

    DM:PrintMessage("DotMaster " .. (DM.enabled and "Enabled" or "Disabled"))

    -- Update saved variables
    DotMasterDB.enabled = DM.enabled

    -- Update API settings
    local settings = DM.API:GetSettings()
    settings.enabled = DM.enabled
    DM.API:SaveSettings(settings)

    -- Force push to bokmaster
    DM:ForcePushToBokmaster()
  elseif command == "on" or command == "enable" then
    -- Enable DotMaster
    local settings = DM.API:GetSettings()
    settings.enabled = true
    DM.enabled = true
    DM:AutoSave()
    DM:PrintMessage("Enabled")
  elseif command == "off" or command == "disable" then
    -- Disable DotMaster
    local settings = DM.API:GetSettings()
    settings.enabled = false
    DM.enabled = false
    DM:AutoSave()
    DM:PrintMessage("Disabled")
  elseif command == "show" and DM.GUI and DM.GUI.frame then
    -- Show the GUI if it exists
    DM.GUI.frame:Show()
  elseif command == "push" or command == "bokmaster" then
    -- Force push to bokmaster
    DM:ForcePushToBokmaster()
  elseif command == "reload" then
    -- Reload UI
    DM:PrintMessage("Reloading UI...")
    C_Timer.After(0.5, function() ReloadUI() end)
  elseif command == "reset" then
    -- Create confirmation dialog
    if StaticPopupDialogs and StaticPopup_Show then
      StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
        text =
        "Are you sure you want to reset all DotMaster settings? This will delete all your saved spells and configurations.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
          -- Explicitly clear each component of DotMasterDB
          if DotMasterDB then
            DotMasterDB.spellConfig = nil
            DotMasterDB.dmspellsdb = nil
            DotMasterDB.spellDatabase = nil
          end
          DotMasterDB = nil

          -- Reset settings to defaults
          local defaultSettings = {
            enabled = true,
            forceColor = false,
            borderOnly = false,
            borderThickness = 2,
            flashExpiring = false,
            flashThresholdSeconds = 3.0,
            minimapIcon = { hide = false }
          }

          DM.enabled = defaultSettings.enabled
          DM:AutoSave()
          DM:PrintMessage("Settings reset to defaults")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("DOTMASTER_RESET_CONFIRM")
    else
      DM:PrintMessage("Cannot show reset confirmation dialog.")
    end
  elseif command == "save" then
    -- Force save settings
    DM:SaveSettings()
    DM:PrintMessage("Settings saved")
  elseif command == "debug" then
    -- Debug commands
    if args and strlower(args) == "flash" then
      -- Debug expiry flash
      if DM.DebugFlashExpiry then
        DM:DebugFlashExpiry(true, 5.0)
        DM:PrintMessage("Flash expiry debug mode activated - 5.0 seconds threshold")
      else
        DM:PrintMessage("Debug flash function not available")
      end
    else
      -- Toggle debug mode
      DM.debugMode = not DM.debugMode
      DM:PrintMessage("Debug mode " .. (DM.debugMode and "Enabled" or "Disabled"))
    end
  elseif command == "testflash" then
    -- Test flash expiry functionality with optional threshold parameter
    local threshold = tonumber(args)
    if DM.DebugFlashExpiry then
      DM:DebugFlashExpiry(true, threshold or 3.0)
      DM:PrintMessage("Flash expiry test activated with threshold " .. (threshold or 3.0) .. " seconds")
    else
      DM:PrintMessage("Flash expiry test function not available")
    end
  elseif command == "gui" or command == "" or command == "config" or command == "options" then
    -- Try to toggle main GUI if available
    if DM.GUI and DM.GUI.frame then
      if DM.GUI.frame:IsShown() then
        DM.GUI.frame:Hide()
      else
        DM.GUI.frame:Show()
      end
    else
      DM:OpenGUI()
    end
  else
    -- Show help
    DM:PrintMessage("DotMaster commands:")
    DM:PrintMessage("  /dm - Open/close configuration")
    DM:PrintMessage("  /dm toggle - Toggle DotMaster on/off")
    DM:PrintMessage("  /dm on, /dm enable - Enable DotMaster")
    DM:PrintMessage("  /dm off, /dm disable - Disable DotMaster")
    DM:PrintMessage("  /dm show - Show GUI (if loaded)")
    DM:PrintMessage("  /dm push - Force push settings to bokmaster")
    DM:PrintMessage("  /dm reset - Reset to default settings")
    DM:PrintMessage("  /dm save - Force save settings")
    DM:PrintMessage("  /dm reload - Reload UI")
    DM:PrintMessage("  /dm debug - Toggle debug mode")
    DM:PrintMessage("  /dm debug flash - Test flash expiry with 5s threshold")
    DM:PrintMessage("  /dm testflash [seconds] - Test flash expiry with custom threshold")
  end
end
