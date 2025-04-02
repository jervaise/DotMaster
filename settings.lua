-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  DotMasterDB = DotMasterDB or {}
  DotMasterDB.enabled = DM.enabled
  DotMasterDB.version = "0.6.6"

  -- Save debug categories and options
  if DM.DEBUG_CATEGORIES then
    DotMasterDB.debugCategories = DM.DEBUG_CATEGORIES
    DM:DatabaseDebug("Debug categories saved")
  end

  if DM.DEBUG_CONSOLE_OUTPUT ~= nil then
    DotMasterDB.debugConsoleOutput = DM.DEBUG_CONSOLE_OUTPUT
    DM:DatabaseDebug("Debug console output setting saved")
  end

  DM:DebugMsg("Settings saved")
end

-- Load settings from saved variables
function DM:LoadSettings()
  DotMasterDB = DotMasterDB or {}
  DM.enabled = (DotMasterDB.enabled ~= nil) and DotMasterDB.enabled or DM.defaults.enabled

  -- Load debug settings
  if DotMasterDB.debugCategories then
    DM.DEBUG_CATEGORIES = DotMasterDB.debugCategories
    DM:DatabaseDebug("Debug categories loaded from saved variables")
  else
    DM:DatabaseDebug("No saved debug categories found, using defaults")
  end

  if DotMasterDB.debugConsoleOutput ~= nil then
    DM.DEBUG_CONSOLE_OUTPUT = DotMasterDB.debugConsoleOutput
    DM:DatabaseDebug("Debug console output setting loaded")
  else
    DM:DatabaseDebug("No saved debug console output setting found, using default")
  end

  -- Load spell configuration or use defaults
  if DotMasterDB.spellConfig and next(DotMasterDB.spellConfig) then
    DM.spellConfig = DotMasterDB.spellConfig
    DM:DatabaseDebug("Spell configuration loaded from saved variables")
  else
    -- Deep copy default spellConfig to avoid reference issues
    DM.spellConfig = DM:DeepCopy(DM.defaults.spellConfig)
    DM:DatabaseDebug("No saved spell configuration found, using defaults")
  end

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
        if DM.Debug.ShowHelp then
          DM.Debug:ShowHelp()
        else
          -- Fallback if help function is not available
          DM:PrintMessage("Debug commands:")
          DM:PrintMessage("  /dmdebug - Toggle debug console")
          DM:PrintMessage("  /dmdebug console - Open debug console")
          DM:PrintMessage("  /dmdebug status - Show debug status")
          DM:PrintMessage("  /dmdebug category <name> [on|off] - Toggle category")
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
          DM:PrintMessage("  /dmdebug category <name> [on|off] - Toggle category")
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
      DM.enabled = true
      DM:PrintMessage("Enabled")
      if DM.UpdateAllNameplates then DM:UpdateAllNameplates() else DM:DebugMsg("UpdateAllNameplates not available") end
      DM:SaveSettings()
    elseif command == "off" or command == "disable" then
      DM.enabled = false
      DM:PrintMessage("Disabled")
      if DM.ResetAllNameplates then DM:ResetAllNameplates() else DM:DebugMsg("ResetAllNameplates not available") end
      DM:SaveSettings()
    elseif command == "debug" or command == "status" then
      DM:DebugMsg("Status Information:")
      DM:DebugMsg("Enabled: " .. (DM.enabled and "Yes" or "No"))
      DM:DebugMsg("GUI loaded: " .. (DM.GUI and "Yes" or "No"))
      DM:DebugMsg("GUI frame exists: " .. (DM.GUI and DM.GUI.frame and "Yes" or "No"))
      DM:DebugMsg("Active plates: " .. (DM.TableCount and DM:TableCount(DM.activePlates) or "N/A"))
      DM:DebugMsg("Colored plates: " .. (DM.TableCount and DM:TableCount(DM.coloredPlates) or "N/A"))
      DM:DebugMsg("Tracked spells: " .. (DM.TableCount and DM:TableCount(DM.spellConfig) or "N/A"))
      DM:DebugMsg("Spell configurations:")
      for spellID, config in pairs(DM.spellConfig or {}) do
        DM:DebugMsg("  - " ..
          spellID .. ": " .. (config.name or "Unknown") .. " (" .. (config.enabled and "Enabled" or "Disabled") .. ")")
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
      if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
          text =
          "Are you sure you want to reset all DotMaster settings? This will delete all your saved spells and configurations.",
          button1 = "Yes",
          button2 = "No",
          OnAccept = function()
            DM:DebugMsg("Resetting all settings")
            DotMasterDB = nil
            DM.spellConfig = {}
            if DM.DeepCopy then DM.spellConfig = DM:DeepCopy(DM.defaults.spellConfig) end
            DM.enabled = DM.defaults.enabled
            DM:PrintMessage("Settings reset to defaults")
            if DM.ResetAllNameplates then DM:ResetAllNameplates() end
            if DM.UpdateAllNameplates then DM:UpdateAllNameplates() end
            DM:SaveSettings()
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
      else
        DM:PrintMessage("Cannot show reset confirmation dialog.")
      end
    elseif command == "save" then
      DM:SaveSettings()
      DM:PrintMessage("Settings saved")
    elseif command == "fixdb" or command == "normalizedb" or command == "fixdatabase" then
      DM:PrintMessage("Attempting to fix database ID format...")
      if DM.NormalizeDatabaseIDs then
        local dbSize = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
        DM:PrintMessage("Current database size: " .. dbSize .. " entries")

        DM:NormalizeDatabaseIDs()
        DM:SaveDMSpellsDB()

        -- Update the UI if database tab is active
        if DM.GUI and DM.GUI.RefreshDatabaseTabList then
          DM.GUI:RefreshDatabaseTabList()
          DM:PrintMessage("UI refreshed with normalized database")
        end

        DM:PrintMessage("Database fix complete. Database now has " .. DM:TableCount(DM.dmspellsdb) .. " entries")
      else
        DM:PrintMessage("Database normalization function not found")
      end
    elseif command == "dbstate" or command == "dumpdb" then
      -- Print detailed information about the database
      DM:PrintMessage("Database State:")

      -- Check if database exists
      if not DM.dmspellsdb then
        DM:PrintMessage("Database is nil!")
        return
      end

      -- Print database size
      local dbSize = DM:TableCount(DM.dmspellsdb)
      DM:PrintMessage("Database contains " .. dbSize .. " spells")

      -- Check SavedVariables entries
      if DotMasterDB and DotMasterDB.dmspellsdb then
        local svSize = DM:TableCount(DotMasterDB.dmspellsdb)
        DM:PrintMessage("SavedVariables database contains " .. svSize .. " spells")
      else
        DM:PrintMessage("SavedVariables database is nil or empty")
      end

      -- Print type information
      DM:PrintMessage("Database type: " .. type(DM.dmspellsdb))

      -- Count ID types
      local stringIds, numberIds, otherIds = 0, 0, 0
      for id, _ in pairs(DM.dmspellsdb) do
        if type(id) == "string" then
          stringIds = stringIds + 1
        elseif type(id) == "number" then
          numberIds = numberIds + 1
        else
          otherIds = otherIds + 1
        end
      end

      DM:PrintMessage("ID Types: " .. stringIds .. " string, " .. numberIds .. " number, " .. otherIds .. " other")

      -- Print details of each spell
      local count = 0
      for id, data in pairs(DM.dmspellsdb) do
        count = count + 1
        if count <= 10 or dbSize <= 20 then -- Show all if 20 or less, otherwise first 10
          local colorStr = data.color and
              string.format("R:%.1f G:%.1f B:%.1f", data.color[1], data.color[2], data.color[3]) or "nil"
          DM:PrintMessage(string.format(
            "Spell %d: ID=%s (type=%s), Name=%s, Class=%s, Spec=%s, Icon=%s, Tracked=%s, Enabled=%s, Priority=%s, Color=%s",
            count,
            tostring(id),
            type(id),
            data.spellname or "nil",
            data.wowclass or "nil",
            data.wowspec or "nil",
            data.spellicon or "nil",
            data.tracked or "nil",
            data.enabled or "nil",
            data.priority or "nil",
            colorStr
          ))
        end
      end

      if count > 10 and dbSize > 20 then
        DM:PrintMessage("... and " .. (count - 10) .. " more spells (showing only first 10)")
      end
    else
      -- Try to toggle main GUI if available, otherwise print help
      if DM.GUI and DM.GUI.frame then
        DM:DebugMsg("Attempting to toggle GUI")
        if DM.GUI.frame:IsShown() then
          DM.GUI.frame:Hide()
        else
          DM.GUI.frame:Show()
        end
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
        DM:PrintMessage("  /dm fixdb - Fix database ID format issues")
        DM:PrintMessage("  /dm dbstate - Show detailed database state and spells")
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
