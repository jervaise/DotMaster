-- DotMaster settings.lua
-- Settings management for the addon

local DM = DotMaster

-- Save settings to SavedVariables
function DM:SaveSettings()
  -- Create main SavedVariables table if it doesn't exist
  if not DotMasterDB then
    DotMasterDB = {}
  end

  -- Save basic addon settings
  DotMasterDB.enabled = DM.enabled

  -- Save UI settings
  DotMasterDB.settings = DM.settings or {}

  -- Save minimap button position
  if DM.minimapIcon and DM.minimapIcon.db then
    DotMasterDB.minimapIcon = DM.minimapIcon.db
  end
end

-- Load settings from SavedVariables
function DM:LoadSettings()
  -- First check if SavedVariables exists
  if DotMasterDB then
    -- Saved variables exist, load settings
    DM.enabled = (DotMasterDB.enabled ~= nil) and DotMasterDB.enabled or true
  else
    -- No saved variables, initialize with defaults
    DM.enabled = true
    DotMasterDB = {}
  end

  -- Initialize settings table
  DM.settings = DM.settings or {}

  -- Load color preference settings
  if DotMasterDB.settings and DotMasterDB.settings.forceColor ~= nil then
    DM.settings.forceColor = DotMasterDB.settings.forceColor
  else
    DM.settings.forceColor = false
  end

  -- Load border only settings
  if DotMasterDB.settings and DotMasterDB.settings.borderOnly ~= nil then
    DM.settings.borderOnly = DotMasterDB.settings.borderOnly
  else
    DM.settings.borderOnly = false
  end

  -- Load border thickness settings
  if DotMasterDB.settings and DotMasterDB.settings.borderThickness ~= nil then
    DM.settings.borderThickness = DotMasterDB.settings.borderThickness
  else
    DM.settings.borderThickness = 2
  end

  -- Load flash expiring settings
  if DotMasterDB.settings and DotMasterDB.settings.flashExpiring ~= nil then
    DM.settings.flashExpiring = DotMasterDB.settings.flashExpiring
  else
    DM.settings.flashExpiring = DM.defaults.flashExpiring
  end

  -- Load flash threshold settings
  if DotMasterDB.settings and DotMasterDB.settings.flashThresholdSeconds ~= nil then
    DM.settings.flashThresholdSeconds = DotMasterDB.settings.flashThresholdSeconds
  else
    DM.settings.flashThresholdSeconds = DM.defaults.flashThresholdSeconds
  end

  -- Load minimap button settings
  if DotMasterDB.minimapIcon then
    DM.minimapIconDB = DotMasterDB.minimapIcon
  end
end

-- Initialize ONLY the main slash commands
function DM:InitializeMainSlashCommands()
  SLASH_DOTMASTER1 = "/dm"
  SLASH_DOTMASTER2 = "/dotmaster"
  SlashCmdList["DOTMASTER"] = function(msg)
    -- Toggle main UI with no arguments
    if msg == "" then
      if DM.GUI.ToggleMainUI then
        DM.GUI:ToggleMainUI()
      else
        DM:PrintMessage("Main UI toggle not available")
      end
      return
    end

    -- Toggle Find My Dots window with 'dots' argument
    if msg == "dots" or msg == "find" or msg == "findmydots" then
      if DM.ToggleFindMyDotsWindow then
        DM:ToggleFindMyDotsWindow()
      else
        DM:PrintMessage("Find My Dots window toggle not available")
      end
      return
    end

    -- Display help information
    DM:PrintMessage("Commands:")
    DM:PrintMessage("/dm - Toggle main UI")
    DM:PrintMessage("/dm dots - Toggle Find My Dots window")
    DM:PrintMessage("/dm help - Display this help message")
  end
end
