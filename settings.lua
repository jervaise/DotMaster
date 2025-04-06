-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  if not DotMasterDB then
    DM:DatabaseDebug("Creating new SavedVariables table for DotMasterDB")
    DotMasterDB = {}
  end

  -- Get settings from API
  local settings = DM.API:GetSettings()

  -- Update DotMasterDB with current settings
  DotMasterDB.enabled = settings.enabled
  DotMasterDB.version = "1.0.3"

  -- Save force threat color setting
  DotMasterDB.settings = DotMasterDB.settings or {}
  DotMasterDB.settings.forceColor = settings.forceColor
  DotMasterDB.settings.borderOnly = settings.borderOnly
  DotMasterDB.settings.borderThickness = settings.borderThickness
  DotMasterDB.settings.flashExpiring = settings.flashExpiring
  DotMasterDB.settings.flashThresholdSeconds = settings.flashThresholdSeconds

  DM:DatabaseDebug("Force threat color setting saved: " .. (settings.forceColor and "Enabled" or "Disabled"))
  DM:DatabaseDebug("Border only setting saved: " .. (settings.borderOnly and "Enabled" or "Disabled"))
  DM:DatabaseDebug("Border thickness saved: " .. (settings.borderThickness or "Default"))
  DM:DatabaseDebug("Flash expiring setting saved: " .. (settings.flashExpiring and "Enabled" or "Disabled"))
  DM:DatabaseDebug("Flash threshold saved: " .. (settings.flashThresholdSeconds or "Default") .. " seconds")

  -- Save debug categories and options
  local debugSettings = DM.API:GetDebugSettings()

  if debugSettings.categories then
    DotMasterDB.debugCategories = debugSettings.categories
    DM:DatabaseDebug("Debug categories saved")
  end

  if debugSettings.consoleOutput ~= nil then
    DotMasterDB.debugConsoleOutput = debugSettings.consoleOutput
    DM:DatabaseDebug("Debug console output setting saved")
  end

  DM:DebugMsg("Settings saved")
end

-- Load settings from saved variables
function DM:LoadSettings()
  -- First log if SavedVariables are available
  if DotMasterDB then
    DM:DatabaseDebug("SavedVariables (DotMasterDB) found - loading settings")
  else
    DM:DatabaseDebug("SavedVariables (DotMasterDB) not found - initializing with defaults")
    DotMasterDB = {}
  end

  -- Initialize API settings with defaults
  local settings = {
    enabled = (DotMasterDB.enabled ~= nil) and DotMasterDB.enabled or true,
    forceColor = false,
    borderOnly = false,
    borderThickness = 2,
    flashExpiring = false,
    flashThresholdSeconds = 3.0,
    minimapIcon = { hide = false }
  }

  -- Load settings from saved variables if available
  if DotMasterDB.settings then
    if DotMasterDB.settings.forceColor ~= nil then
      settings.forceColor = DotMasterDB.settings.forceColor
    end

    if DotMasterDB.settings.borderOnly ~= nil then
      settings.borderOnly = DotMasterDB.settings.borderOnly
    end

    if DotMasterDB.settings.borderThickness ~= nil then
      settings.borderThickness = DotMasterDB.settings.borderThickness
    end

    if DotMasterDB.settings.flashExpiring ~= nil then
      settings.flashExpiring = DotMasterDB.settings.flashExpiring
    end

    if DotMasterDB.settings.flashThresholdSeconds ~= nil then
      settings.flashThresholdSeconds = DotMasterDB.settings.flashThresholdSeconds
    end
  end

  -- Load minimap settings
  if DotMasterDB.minimap then
    settings.minimapIcon = DotMasterDB.minimap
  end

  -- Set the enabled state in both API and core for compatibility
  DM.enabled = settings.enabled

  -- Save to API
  DM.API:SaveSettings(settings)

  DM:DebugMsg("Settings loaded")
end

-- Initialize ONLY the debug slash commands
function DM:InitializeDebugSlashCommands()
  SLASH_DOTMASTERDEBUG1 = "/dmdebug"
  SlashCmdList["DOTMASTERDEBUG"] = function(msg)
    if not DM.Debug then
      DM:PrintMessage("Debug system not fully initialized.")
      return
    end

    if not msg or msg == "" then
      -- Toggle debug window if no arguments
      if DM.Debug.ToggleWindow then
        DM.Debug:ToggleWindow()
      else
        DM:PrintMessage("Debug console toggle not available")
      end
    else
      -- Parse the command
      local command, arg = strsplit(" ", msg, 2)
      command = strtrim(command:lower())

      if command == "console" or command == "window" then
        if DM.Debug.ToggleWindow then
          DM.Debug:ToggleWindow()
        else
          DM:PrintMessage("Debug console toggle not available")
        end
      elseif command == "status" then
        local debugSettings = DM.API:GetDebugSettings()

        DM:PrintMessage("Debug Status: " .. (DM.DEBUG_MODE and "Enabled" or "Disabled"))
        -- Show enabled categories
        if debugSettings.categories then
          DM:PrintMessage("Enabled Categories:")
          for category, enabled in pairs(debugSettings.categories) do
            if enabled then
              DM:PrintMessage("  - " .. category)
            end
          end
        end
      elseif command == "category" and arg then
        -- Enable/disable specific category
        local category, state = strsplit(" ", arg, 2)
        category = strtrim(category:lower())

        local debugSettings = DM.API:GetDebugSettings()

        if debugSettings.categories and debugSettings.categories[category] ~= nil then
          if state and (state:lower() == "on" or state:lower() == "enable") then
            debugSettings.categories[category] = true
            DM:PrintMessage("Debug category '" .. category .. "' enabled")
          elseif state and (state:lower() == "off" or state:lower() == "disable") then
            debugSettings.categories[category] = false
            DM:PrintMessage("Debug category '" .. category .. "' disabled")
          else
            -- Toggle if no state specified
            debugSettings.categories[category] = not debugSettings.categories[category]
            DM:PrintMessage("Debug category '" .. category .. "' " ..
              (debugSettings.categories[category] and "enabled" or "disabled"))
          end

          DM.API:SaveDebugSettings(debugSettings)
        else
          DM:PrintMessage("Unknown debug category: " .. category)
        end
      elseif command == "help" then
        -- Show help information
        if DM.Debug.ShowHelp then
          DM.Debug:ShowHelp()
        else
          -- Fallback if help function is not available
          DM:PrintMessage("Debug commands:")
          DM:PrintMessage("  /dmdebug - Toggle debug console")
          DM:PrintMessage("  /dmdebug console - Open debug console")
          DM:PrintMessage("  /dmdebug status - Show debug status")
          DM:PrintMessage("  /dmdebug category <n> [on|off] - Toggle category")
          DM:PrintMessage("  /dmdebug help - Show this help")
        end
      else
        -- Show help if command is unknown
        if DM.Debug.ShowHelp then
          DM.Debug:ShowHelp()
        else
          -- Fallback if help function is not available
          DM:PrintMessage("Debug commands:")
          DM:PrintMessage("  /dmdebug - Toggle debug console")
          DM:PrintMessage("  /dmdebug console - Open debug console")
          DM:PrintMessage("  /dmdebug status - Show debug status")
          DM:PrintMessage("  /dmdebug category <n> [on|off] - Toggle category")
          DM:PrintMessage("  /dmdebug help - Show this help")
        end
      end
    end
  end
  DM:DebugMsg("Debug slash commands initialized")
end

-- Initialize the main slash commands
function DM:InitializeMainSlashCommands()
  SLASH_DOTMASTER1 = "/dm"
  SlashCmdList["DOTMASTER"] = function(msg)
    DM:DebugMsg("Slash command received: /dm " .. msg)

    local command, arg = strsplit(" ", msg, 2)
    command = strtrim(command:lower())

    if command == "on" or command == "enable" then
      local settings = DM.API:GetSettings()
      settings.enabled = true
      DM.enabled = true
      DM.API:SaveSettings(settings)
      DM.API:EnableAddon(true)
      DM:PrintMessage("Enabled")
    elseif command == "off" or command == "disable" then
      local settings = DM.API:GetSettings()
      settings.enabled = false
      DM.enabled = false
      DM.API:SaveSettings(settings)
      DM.API:EnableAddon(false)
      DM:PrintMessage("Disabled")
    elseif command == "debug" or command == "status" then
      DM:DebugMsg("Status Information:")
      local settings = DM.API:GetSettings()
      DM:DebugMsg("Enabled: " .. (settings.enabled and "Yes" or "No"))
      DM:DebugMsg("GUI loaded: " .. (DM.GUI and "Yes" or "No"))
      DM:DebugMsg("GUI frame exists: " .. (DM.GUI and DM.GUI.frame and "Yes" or "No"))
      DM:DebugMsg("Active plates: " .. (DM.TableCount and DM:TableCount(DM.activePlates) or "N/A"))
      DM:DebugMsg("Colored plates: " .. (DM.TableCount and DM:TableCount(DM.coloredPlates) or "N/A"))

      local trackedSpells = DM.API:GetTrackedSpells()
      DM:DebugMsg("Tracked spells: " .. (DM.TableCount and DM:TableCount(trackedSpells) or "N/A"))

      -- Add initialization state info
      DM:DebugMsg("Initialization state: " .. (DM.initState or "unknown"))
    elseif command == "console" or command == "debugconsole" or command == "log" then
      -- Open the debug console
      if DM.Debug and DM.Debug.ToggleWindow then
        DM.Debug:ToggleWindow()
      else
        DM:PrintMessage("Debug console not available")
      end
    elseif command == "show" and DM.GUI and DM.GUI.frame then
      DM:DebugMsg("Attempting to show GUI")
      DM.GUI.frame:Show()
    elseif command == "reload" then
      DM:DebugMsg("Reloading UI")
      ReloadUI()
    elseif command == "reset" then
      -- Create confirmation dialog
      if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
          text =
          "Are you sure you want to reset all DotMaster settings? This will delete all your saved spells and configurations.",
          button1 = "Yes",
          button2 = "No",
          OnAccept = function()
            DM:DebugMsg("Resetting all settings")
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
            DM.API:SaveSettings(defaultSettings)
            DM:PrintMessage("Settings reset to defaults")

            -- Save and update UI
            DM:SaveSettings()
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
      DM:SaveSettings()
      DM:PrintMessage("Settings saved")
    else
      -- Try to toggle main GUI if available, otherwise print help
      if DM.GUI and DM.GUI.frame then
        DM:DebugMsg("Attempting to toggle GUI")
        if DM.GUI.frame:IsShown() then
          DM.GUI.frame:Hide()
        else
          DM.GUI.frame:Show()
        end
      elseif command == "show" and DM.GUI and DM.GUI.frame then
        DM:DebugMsg("Attempting to show GUI")
        DM.GUI.frame:Show()
      elseif command == "reload" then
        DM:DebugMsg("Reloading UI")
        ReloadUI()
      else
        DM:DebugMsg("Main GUI not available, showing help")
        DM:PrintMessage("Available commands:")
        DM:PrintMessage("  /dm on - Enable addon")
        DM:PrintMessage("  /dm off - Disable addon")
        DM:PrintMessage("  /dm status - Display debug information")
        DM:PrintMessage("  /dm console - Open Debug Console (use /dmdebug)")
        DM:PrintMessage("  /dm show - Show GUI (if loaded)")
        DM:PrintMessage("  /dm reset - Reset to default settings")
        DM:PrintMessage("  /dm save - Force save settings")
        DM:PrintMessage("  /dm reload - Reload UI")
      end
    end
  end
  DM:DebugMsg("Main slash commands initialized")
end

-- Create a function that automatically saves after config changes
function DM:AutoSave()
  -- Create a timer to save settings after a short delay (to avoid excessive saving)
  if DM.saveTimer then
    DM.saveTimer:Cancel()
  end

  DM.saveTimer = C_Timer.NewTimer(1, function()
    DM:SaveSettings()
  end)
end
