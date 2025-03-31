--[[
    DotMaster - Enhanced tracking of damage-over-time effects
]]

local ADDON_NAME = "DotMaster"

-- Create addon and initialize with Ace3
local DotMaster = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0",
  "AceHook-3.0")

-- Make addon globally accessible
_G[ADDON_NAME] = DotMaster

-- Main initialization function
function DotMaster:OnInitialize()
  -- Register slash commands
  self:RegisterChatCommand("dm", "HandleSlashCommand")
  self:RegisterChatCommand("dotmaster", "HandleSlashCommand")

  -- Initialize database
  self:InitializeDB()

  -- Initialize debug system
  self:InitializeDebug()

  self:Debug("CORE", "DotMaster initialized")

  -- Initialize features based on settings
  if self.db.profile.enabled then
    self:OnEnable()
  else
    self:Print("DotMaster is currently disabled. Type /dm toggle to enable.")
  end
end

-- Called when the addon is enabled
function DotMaster:OnEnable()
  -- Initialize nameplate tracking
  self:InitializeNameplateTracker()

  -- Initialize FindMyDots if enabled
  if self.db.profile.findMyDots.enabled then
    self:InitializeFindMyDots()
  end

  self:Debug("CORE", "DotMaster enabled")
  self:Print("DotMaster enabled. Type /dm for options.")
end

-- Called when the addon is disabled
function DotMaster:OnDisable()
  -- Disable nameplate tracking
  self:DisableNameplateTracker()

  -- Disable FindMyDots if it was enabled
  self:DisableFindMyDots()

  self:Debug("CORE", "DotMaster disabled")
  self:Print("DotMaster disabled. Type /dm toggle to re-enable.")
end

-- Handle slash commands
function DotMaster:HandleSlashCommand(input)
  local args = { strsplit(" ", input) }
  local command = args[1]

  if command == "toggle" then
    if self.db.profile.enabled then
      self.db.profile.enabled = false
      self:OnDisable()
    else
      self.db.profile.enabled = true
      self:OnEnable()
    end
  elseif command == "config" or command == "options" then
    self:OpenConfigUI()
  elseif command == "tracking" then
    self:OpenTrackingUI()
  elseif command == "database" then
    self:OpenDatabaseUI()
  elseif command == "findmydots" then
    self:ToggleFindMyDots()
  elseif command == "debug" then
    self:HandleDebugCommand(select(2, unpack(args)))
  elseif command == "debugdump" then
    self:ExportDebugLog()
  elseif command == "reset" then
    self:ResetAllSettings()
  elseif command == "help" or command == "" then
    self:PrintHelp()
  else
    self:Print("Unknown command: " .. command)
    self:PrintHelp()
  end
end

-- Print help information
function DotMaster:PrintHelp()
  self:Print("DotMaster commands:")
  self:Print("/dm toggle - Toggle addon on/off")
  self:Print("/dm config - Open options panel")
  self:Print("/dm tracking - Open DoT tracking configuration panel")
  self:Print("/dm database - Open spell database browser")
  self:Print("/dm findmydots - Open Find My Dots panel")
  self:Print("/dm debug - Open debug panel")
  self:Print("/dm debugdump - Export debug log")
  self:Print("/dm reset - Reset all settings to defaults")
  self:Print("/dm help - Show this help")
end

-- Setup default options
DotMaster.defaults = {
  profile = {
    enabled = true,
    debug = {
      enabled = false,
      level = "INFO",
      categories = {
        CORE = false,
        NAMEPLATE = false,
        DOT = false,
        GUI = false,
        DATABASE = false,
        PROFILE = false,
        PERFORMANCE = false,
        API = false,
        EVENTS = false,
        COMBAT = false,
        CONFIG = false,
        CUSTOM = false
      }
    },
    nameplate = {
      enabled = true,
      size = 1.0,
      position = "TOP",
      showIcon = true,
      showTimer = true
    },
    filter = {
      trackOnlyMyDoTs = true,
      trackFriendlyTargets = false
    },
    findMyDots = {
      enabled = true,
      scale = 1.0,
      opacity = 1.0,
      showCount = true,
      showName = true,
      showIcon = true,
      showTimer = true,
      lockPosition = false
    },
    minimapIcon = {
      show = true
    }
  }
}

-- Initialize settings database
function DotMaster:InitializeDB()
  self.db = LibStub("AceDB-3.0"):New("DotMasterDB", self.defaults)

  -- Set up profile options
  self.optionsTable = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  -- Register options with config registry
  LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME .. "Profiles", self.optionsTable)

  self:Debug("CORE", "Database initialized")
end

-- Reset all settings to defaults
function DotMaster:ResetAllSettings()
  self.db:ResetProfile()
  self:Print("All settings have been reset to defaults.")

  -- Refresh UI if open
  if self.configFrame and self.configFrame:IsShown() then
    self:RefreshConfig()
  end

  -- Apply settings
  if self.db.profile.enabled then
    self:OnEnable()
  else
    self:OnDisable()
  end
end
