-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  DotMasterDB = DotMasterDB or {}
  DotMasterDB.enabled = DM.enabled
  DotMasterDB.version = DM.defaults.version
  DotMasterDB.spellConfig = DM.spellConfig
  DotMasterDB.debug = DM.DEBUG_MODE

  -- Save debug categories and options
  if DM.DEBUG_CATEGORIES then
    DotMasterDB.debugCategories = DM.DEBUG_CATEGORIES
  end

  if DM.DEBUG_CONSOLE_OUTPUT ~= nil then
    DotMasterDB.debugConsoleOutput = DM.DEBUG_CONSOLE_OUTPUT
  end

  DM:DebugMsg("Settings saved")
end

-- Load settings from saved variables
function DM:LoadSettings()
  DotMasterDB = DotMasterDB or {}
  DM.enabled = (DotMasterDB.enabled ~= nil) and DotMasterDB.enabled or DM.defaults.enabled
  DM.DEBUG_MODE = (DotMasterDB.debug ~= nil) and DotMasterDB.debug or true

  -- Load debug settings
  if DotMasterDB.debugCategories then
    DM.DEBUG_CATEGORIES = DotMasterDB.debugCategories
  end

  if DotMasterDB.debugConsoleOutput ~= nil then
    DM.DEBUG_CONSOLE_OUTPUT = DotMasterDB.debugConsoleOutput
  end

  -- Load spell configuration or use defaults
  if DotMasterDB.spellConfig and next(DotMasterDB.spellConfig) then
    DM.spellConfig = DotMasterDB.spellConfig
  else
    -- Deep copy default spellConfig to avoid reference issues
    DM.spellConfig = DM:DeepCopy(DM.defaults.spellConfig)
  end

  DM:DebugMsg("Settings loaded")
end

-- Initialize slash commands
function DM:InitializeSlashCommands()
  DM:DebugMsg("Initializing slash commands")

  SLASH_DOTMASTER1 = "/dm"
  SlashCmdList["DOTMASTER"] = function(msg)
    DM:DebugMsg("Slash command received: " .. msg)

    local command, arg = strsplit(" ", msg, 2)
    command = strtrim(command:lower())

    if command == "on" or command == "enable" then
      DM.enabled = true
      DM:PrintMessage("Enabled")
      DM:UpdateAllNameplates()
      DM:SaveSettings() -- Save settings immediately
    elseif command == "off" or command == "disable" then
      DM.enabled = false
      DM:PrintMessage("Disabled")
      DM:ResetAllNameplates()
      DM:SaveSettings() -- Save settings immediately
    elseif command == "debug" or command == "status" then
      DM:DebugMsg("Status Information:")
      DM:DebugMsg("Enabled: " .. (DM.enabled and "Yes" or "No"))
      DM:DebugMsg("GUI loaded: " .. (DM.GUI and "Yes" or "No"))
      DM:DebugMsg("GUI frame exists: " .. (DM.GUI and DM.GUI.frame and "Yes" or "No"))
      DM:DebugMsg("Active plates: " .. DM:TableCount(DM.activePlates))
      DM:DebugMsg("Colored plates: " .. DM:TableCount(DM.coloredPlates))
      DM:DebugMsg("Tracked spells: " .. DM:TableCount(DM.spellConfig))

      -- List all tracked spells
      DM:DebugMsg("Spell configurations:")
      for spellID, config in pairs(DM.spellConfig) do
        DM:DebugMsg("  - " ..
          spellID .. ": " .. config.name .. " (" .. (config.enabled and "Enabled" or "Disabled") .. ")")
      end
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
      StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
        text =
        "Are you sure you want to reset all DotMaster settings? This will delete all your saved spells and configurations.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
          DM:DebugMsg("Resetting all settings")
          DotMasterDB = nil
          DM.spellConfig = {}
          DM.spellConfig = DM:DeepCopy(DM.defaults.spellConfig)
          DM.enabled = DM.defaults.enabled
          print("|cFFCC00FFDotMaster:|r Settings reset to defaults")
          DM:ResetAllNameplates()
          DM:UpdateAllNameplates()
          DM:SaveSettings() -- Save settings immediately

          if DM.GUI and DM.GUI.RefreshSpellList then
            DM.GUI:RefreshSpellList()
          end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("DOTMASTER_RESET_CONFIRM")
    elseif command == "save" then
      DM:SaveSettings()
      DM:PrintMessage("Settings saved")
    else
      -- Try to show GUI if available
      if DM.GUI and DM.GUI.frame then
        DM:DebugMsg("Attempting to toggle GUI")
        if DM.GUI.frame:IsShown() then
          DM.GUI.frame:Hide()
        else
          DM.GUI.frame:Show()
        end
      else
        DM:DebugMsg("GUI not available")
        print("|cFFCC00FFDotMaster:|r Available commands:")
        print("  /dm on - Enable addon")
        print("  /dm off - Disable addon")
        print("  /dm status - Display debug information")
        print("  /dm console - Open Debug Console")
        print("  /dm show - Show GUI (if available)")
        print("  /dm reset - Reset to default settings")
        print("  /dm save - Force save settings")
        print("  /dm reload - Reload UI")
      end
    end
  end

  -- Add dedicated debug command
  SLASH_DOTMASTERDEBUG1 = "/dmdebug"
  SlashCmdList["DOTMASTERDEBUG"] = function(msg)
    if not msg or msg == "" then
      -- Toggle debug window if no arguments
      if DM.Debug and DM.Debug.ToggleWindow then
        DM.Debug:ToggleWindow()
      else
        DM:PrintMessage("Debug console not available")
      end
    else
      -- Parse the command
      local command, arg = strsplit(" ", msg, 2)
      command = strtrim(command:lower())

      if command == "on" or command == "enable" then
        DM.DEBUG_MODE = true
        DM:PrintMessage("Debug Mode Enabled")
        DM:SaveSettings()
      elseif command == "off" or command == "disable" then
        DM.DEBUG_MODE = false
        DM:PrintMessage("Debug Mode Disabled")
        DM:SaveSettings()
      elseif command == "console" or command == "window" then
        if DM.Debug and DM.Debug.ToggleWindow then
          DM.Debug:ToggleWindow()
        else
          DM:PrintMessage("Debug console not available")
        end
      elseif command == "status" then
        DM:PrintMessage("Debug Status: " .. (DM.DEBUG_MODE and "Enabled" or "Disabled"))
        -- Show enabled categories
        if DM.DEBUG_CATEGORIES then
          DM:PrintMessage("Enabled Categories:")
          for category, enabled in pairs(DM.DEBUG_CATEGORIES) do
            if enabled then
              DM:PrintMessage("  - " .. category)
            end
          end
        end
      elseif command == "category" and arg then
        -- Enable/disable specific category
        local category, state = strsplit(" ", arg, 2)
        category = strtrim(category:lower())

        if DM.DEBUG_CATEGORIES and DM.DEBUG_CATEGORIES[category] ~= nil then
          if state and (state:lower() == "on" or state:lower() == "enable") then
            DM.DEBUG_CATEGORIES[category] = true
            DM:PrintMessage("Debug category '" .. category .. "' enabled")
          elseif state and (state:lower() == "off" or state:lower() == "disable") then
            DM.DEBUG_CATEGORIES[category] = false
            DM:PrintMessage("Debug category '" .. category .. "' disabled")
          else
            -- Toggle if no state specified
            DM.DEBUG_CATEGORIES[category] = not DM.DEBUG_CATEGORIES[category]
            DM:PrintMessage("Debug category '" .. category .. "' " ..
              (DM.DEBUG_CATEGORIES[category] and "enabled" or "disabled"))
          end
          DM:SaveSettings()
        else
          DM:PrintMessage("Unknown debug category: " .. category)
        end
      elseif command == "help" then
        -- Show help information
        if DM.Debug and DM.Debug.ShowHelp then
          DM.Debug:ShowHelp()
        else
          -- Fallback if help function is not available
          DM:PrintMessage("Debug commands:")
          DM:PrintMessage("  /dmdebug - Toggle debug console")
          DM:PrintMessage("  /dmdebug on|off - Enable/disable debug mode")
          DM:PrintMessage("  /dmdebug console - Open debug console")
          DM:PrintMessage("  /dmdebug status - Show debug status")
          DM:PrintMessage("  /dmdebug category <name> [on|off] - Toggle category")
          DM:PrintMessage("  /dmdebug help - Show this help")
        end
      else
        -- Show help
        if DM.Debug and DM.Debug.ShowHelp then
          DM.Debug:ShowHelp()
        else
          -- Fallback if help function is not available
          DM:PrintMessage("Debug commands:")
          DM:PrintMessage("  /dmdebug - Toggle debug console")
          DM:PrintMessage("  /dmdebug on|off - Enable/disable debug mode")
          DM:PrintMessage("  /dmdebug console - Open debug console")
          DM:PrintMessage("  /dmdebug status - Show debug status")
          DM:PrintMessage("  /dmdebug category <name> [on|off] - Toggle category")
          DM:PrintMessage("  /dmdebug help - Show this help")
        end
      end
    end
  end
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
