-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  if not DotMasterDB then
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
  DotMasterDB.settings.developerMode = settings.developerMode

  -- Save debug settings if they exist
  if settings.debug then
    DotMasterDB.debug = settings.debug
  end
end

-- Load settings from saved variables
function DM:LoadSettings()
  -- First log if SavedVariables are available
  if not DotMasterDB then
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
    minimapIcon = { hide = false },
    developerMode = false
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

    if DotMasterDB.settings.developerMode ~= nil then
      settings.developerMode = DotMasterDB.settings.developerMode
    end
  end

  -- Load minimap settings
  if DotMasterDB.minimap then
    settings.minimapIcon = DotMasterDB.minimap
  end

  -- Load debug settings if they exist
  if DotMasterDB.debug then
    settings.debug = DotMasterDB.debug
  end

  -- Set the enabled state in both API and core for compatibility
  DM.enabled = settings.enabled

  -- Save to API
  DM.API:SaveSettings(settings)

  -- Set up debug database reference for direct access
  DM.db = settings
end

-- Initialize the main slash commands
function DM:InitializeMainSlashCommands()
  SLASH_DOTMASTER1 = "/dm"
  SlashCmdList["DOTMASTER"] = function(msg)
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
    elseif command == "show" and DM.GUI and DM.GUI.frame then
      DM.GUI.frame:Show()
    elseif command == "reload" then
      ReloadUI()
    elseif command == "debug" then
      -- Toggle debug console
      if DM.debugFrame then
        DM.debugFrame:Toggle()
      else
        DM:PrintMessage("Debug console not available")
      end
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
              minimapIcon = { hide = false },
              developerMode = false
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
        if DM.GUI.frame:IsShown() then
          DM.GUI.frame:Hide()
        else
          DM.GUI.frame:Show()
        end
      elseif command == "show" and DM.GUI and DM.GUI.frame then
        DM.GUI.frame:Show()
      elseif command == "reload" then
        ReloadUI()
      else
        DM:PrintMessage("Available commands:")
        DM:PrintMessage("  /dm on - Enable addon")
        DM:PrintMessage("  /dm off - Disable addon")
        DM:PrintMessage("  /dm show - Show GUI (if loaded)")
        DM:PrintMessage("  /dm debug - Toggle debug console")
        DM:PrintMessage("  /dm reset - Reset to default settings")
        DM:PrintMessage("  /dm save - Force save settings")
        DM:PrintMessage("  /dm reload - Reload UI")
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
