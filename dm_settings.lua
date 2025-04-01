--[[
  DotMaster - Settings Module

  File: dm_settings.lua
  Purpose: Handle loading and saving of addon configuration

  Functions:
  - SaveSettings(): Save settings to saved variables
  - LoadSettings(): Load settings from saved variables
  - AutoSave(): Automatically save settings after a short delay
  - ResetSettings(): Reset settings to defaults

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local Settings = {}    -- Local table for module functions
DM.Settings = Settings -- Expose to addon namespace

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

-- Reset settings to defaults
function DM:ResetSettings()
  DM:DebugMsg("Resetting all settings")
  DotMasterDB = nil
  DM.spellConfig = {}
  DM.spellConfig = DM:DeepCopy(DM.defaults.spellConfig)
  DM.enabled = DM.defaults.enabled
  DM.DEBUG_MODE = true

  DM:ResetAllNameplates()
  DM:UpdateAllNameplates()
  DM:SaveSettings()

  if DM.GUI and DM.GUI.RefreshSpellList then
    DM.GUI:RefreshSpellList()
  end

  DM:DebugMsg("Settings reset to defaults")
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

-- Initialize the settings module
function Settings:Initialize()
  DM:DebugMsg("Settings module initialized")
end

-- Return the module
return Settings
