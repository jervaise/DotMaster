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

-- Handle debug commands
function DotMaster:HandleDebugCommand(...)
  local args = { ... }
  local subCommand = args[1]

  if not subCommand or subCommand == "" or subCommand == "toggle" then
    -- Toggle debug mode
    self.db.profile.debug.enabled = not self.db.profile.debug.enabled
    self:Print("Debug mode " .. (self.db.profile.debug.enabled and "enabled" or "disabled"))
    return
  end

  if subCommand == "level" then
    local level = args[2]
    if level and self.DEBUG_LEVELS[string.upper(level)] then
      self:SetDebugLevel(string.upper(level))
      self:Print("Debug level set to " .. string.upper(level))
    else
      self:Print("Valid debug levels: ERROR, WARNING, INFO, DEBUG, TRACE")
    end
    return
  end

  if subCommand == "category" then
    local category = string.upper(args[2] or "")
    local enabled = args[3] == "true" or args[3] == "1" or args[3] == "on"

    if category and self.DEBUG_CATEGORIES[category] then
      self:ToggleDebugCategory(category, enabled)
      self:Print("Debug category " .. category .. " " .. (enabled and "enabled" or "disabled"))
    else
      self:Print("Available debug categories:")
      for cat in pairs(self.DEBUG_CATEGORIES) do
        local status = self.db.profile.debug.categories[cat] and "enabled" or "disabled"
        self:Print("  " .. cat .. ": " .. status)
      end
    end
    return
  end

  if subCommand == "performance" then
    self:ToggleDebugCategory("PERFORMANCE")
    self:Print("Performance monitoring " ..
      (self.db.profile.debug.categories.PERFORMANCE and "enabled" or "disabled"))
    return
  end

  if subCommand == "export" then
    self:ExportDebugLog()
    return
  end

  -- Display debug help if no valid subcommand
  self:Print("Debug commands:")
  self:Print("/dm debug toggle - Toggle debug mode")
  self:Print("/dm debug level [ERROR|WARNING|INFO|DEBUG|TRACE] - Set debug level")
  self:Print("/dm debug category [CATEGORY] [true|false] - Toggle debug category")
  self:Print("/dm debug performance - Toggle performance monitoring")
  self:Print("/dm debug export - Export debug log")
end

-- Export debug log to a file
function DotMaster:ExportDebugLog()
  -- Ensure debug frame exists
  if not DotMasterDebugFrame then
    local f = CreateFrame("Frame", "DotMasterDebugFrame", UIParent, "BackdropTemplate")
    f:SetPoint("CENTER")
    f:SetSize(600, 400)
    f:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)

    -- Add title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("DotMaster Debug Log")

    -- Add close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    -- Add scrollable edit box
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)

    scrollFrame:SetScrollChild(editBox)
    f.editBox = editBox

    -- Add export button
    local export = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    export:SetSize(100, 25)
    export:SetPoint("BOTTOM", 0, 10)
    export:SetText("Copy to Clipboard")
    export:SetScript("OnClick", function()
      editBox:SetFocus()
      editBox:HighlightText()
    end)

    f:Hide()
  end

  -- Format debug log
  local logText = "DotMaster Debug Log - " .. date("%Y-%m-%d %H:%M:%S") .. "\n\n"
  for _, entry in ipairs(self.debugLog) do
    logText = logText .. entry.formattedMessage .. "\n"
  end

  -- Add performance metrics if available
  if self.db.profile.debug.categories.PERFORMANCE then
    logText = logText .. "\n\nPerformance Metrics:\n"
    logText = logText .. "Current Memory Usage: " .. collectgarbage("count") .. " KB\n"

    if #self.performanceMetrics.memoryUsage > 0 then
      logText = logText .. "Memory Usage History:\n"
      for i, data in ipairs(self.performanceMetrics.memoryUsage) do
        logText = logText .. string.format("  %.1f seconds ago: %.2f KB\n",
          GetTime() - data.time, data.usage)
      end
    end

    if #self.performanceMetrics.frameRate > 0 then
      -- Calculate average FPS
      local sum = 0
      for i, data in ipairs(self.performanceMetrics.frameRate) do
        sum = sum + data.fps
      end
      local avgFPS = sum / #self.performanceMetrics.frameRate

      logText = logText .. string.format("Average FPS: %.1f\n", avgFPS)
    end
  end

  -- Add system info
  logText = logText .. "\n\nSystem Info:\n"
  logText = logText .. "WoW Version: " .. GetBuildInfo() .. "\n"
  logText = logText .. "DotMaster Version: " .. self.version .. "\n"

  -- Display in frame
  DotMasterDebugFrame.editBox:SetText(logText)
  DotMasterDebugFrame:Show()

  self:Print("Debug log exported to frame")
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

-- Open main configuration UI
function DotMaster:OpenConfigUI()
  if not self.configFrame then
    -- Create the configuration UI if it doesn't exist yet
    self:InitializeConfig()

    -- Register main options table
    local options = self:GetConfigOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)

    -- Create the config frame using AceConfigDialog
    self.configFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)

    -- Add profile panel
    self.profileFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME .. "Profiles",
      "Profiles", ADDON_NAME)
  end

  -- Open Blizzard interface options to our panel
  InterfaceOptionsFrame_OpenToCategory(self.configFrame)
  -- Call twice to ensure it actually opens (known Blizzard UI issue)
  InterfaceOptionsFrame_OpenToCategory(self.configFrame)

  self:Debug("GUI", "Opened config UI")
end

-- Open DoT tracking config UI
function DotMaster:OpenTrackingUI()
  -- First ensure the main config exists
  if not self.configFrame then
    self:OpenConfigUI()
  end

  -- Open to the tracking section
  LibStub("AceConfigDialog-3.0"):SelectGroup(ADDON_NAME, "tracking")
  InterfaceOptionsFrame_OpenToCategory(self.configFrame)

  self:Debug("GUI", "Opened tracking UI")
end

-- Open database browser UI
function DotMaster:OpenDatabaseUI()
  -- First ensure the main config exists
  if not self.configFrame then
    self:OpenConfigUI()
  end

  -- Open to the database section
  LibStub("AceConfigDialog-3.0"):SelectGroup(ADDON_NAME, "database")
  InterfaceOptionsFrame_OpenToCategory(self.configFrame)

  self:Debug("GUI", "Opened database UI")
end

-- Get configuration options table
function DotMaster:GetConfigOptions()
  -- This should return the options table that was created in the UI/ConfigUI.lua file
  if not self.fullOptionsTable then
    -- Config hasn't been initialized yet
    self:InitializeConfig()
  end

  return self.fullOptionsTable or {}
end

-- Refresh configuration UI
function DotMaster:RefreshConfig()
  if self.configFrame then
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    self:Debug("CONFIG", "Configuration UI refreshed")
  end
end
