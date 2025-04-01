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

  DM:DebugMsg("Settings saved")
end

-- Load settings from saved variables
function DM:LoadSettings()
  DotMasterDB = DotMasterDB or {}
  DM.enabled = (DotMasterDB.enabled ~= nil) and DotMasterDB.enabled or DM.defaults.enabled
  DM.DEBUG_MODE = (DotMasterDB.debug ~= nil) and DotMasterDB.debug or true

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
        print("  /dm show - Show GUI (if available)")
        print("  /dm reset - Reset to default settings")
        print("  /dm save - Force save settings")
        print("  /dm reload - Reload UI")
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
