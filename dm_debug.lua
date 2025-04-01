--[[
  DotMaster - Debug Module

  File: dm_debug.lua
  Purpose: Provides debugging and logging functionality for the addon

  Functions:
  - DebugMsg(): Log a debug message
  - ErrorMsg(): Log an error message
  - WarningMsg(): Log a warning message
  - InfoMsg(): Log an info message
  - ExportLogs(): Export logs for troubleshooting

  Dependencies:
  - dm_core.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster -- reference to main addon
local Debug = {}     -- local table for module functions
DM.Debug = Debug     -- expose to addon namespace

-- Local variables
local debugLog = {}
local maxLogEntries = 500
local logLevel = {
  DEBUG = 1,
  INFO = 2,
  WARNING = 3,
  ERROR = 4
}

-- Local helper function - Add timestamped entry to debug log
local function addLogEntry(level, message)
  if #debugLog >= maxLogEntries then
    table.remove(debugLog, 1) -- Remove oldest entry
  end

  local timestamp = date("%H:%M:%S")
  local entry = {
    timestamp = timestamp,
    level = level,
    message = message
  }

  table.insert(debugLog, entry)
end

-- Main debug message function
function DM:DebugMsg(message)
  if not self.DEBUG_MODE then return end

  addLogEntry(logLevel.DEBUG, message)
  print("|cFF88CCFF[DotMaster Debug]:|r " .. message)
end

-- Error message function
function Debug:ErrorMsg(message)
  addLogEntry(logLevel.ERROR, message)
  print("|cFFFF0000[DotMaster Error]:|r " .. message)
end

-- Warning message function
function Debug:WarningMsg(message)
  addLogEntry(logLevel.WARNING, message)
  print("|cFFFFFF00[DotMaster Warning]:|r " .. message)
end

-- Info message function
function Debug:InfoMsg(message)
  addLogEntry(logLevel.INFO, message)
  if DM.DEBUG_MODE then
    print("|cFF00FF00[DotMaster Info]:|r " .. message)
  end
end

-- Export logs function
function Debug:ExportLogs()
  local export = "DotMaster Debug Log (v" .. DM.VERSION .. ")\n"
  export = export .. "------------------------\n"

  for i, entry in ipairs(debugLog) do
    local levelText = "DEBUG"
    if entry.level == logLevel.INFO then
      levelText = "INFO"
    elseif entry.level == logLevel.WARNING then
      levelText = "WARNING"
    elseif entry.level == logLevel.ERROR then
      levelText = "ERROR"
    end

    export = export .. entry.timestamp .. " [" .. levelText .. "] " .. entry.message .. "\n"
  end

  -- Use WoW's built-in functionality to display large text
  if StaticPopupDialogs["DOTMASTER_EXPORT_DIALOG"] == nil then
    StaticPopupDialogs["DOTMASTER_EXPORT_DIALOG"] = {
      text = "Debug Log Export (Ctrl+C to copy):",
      button1 = "Close",
      hasEditBox = true,
      editBoxWidth = 350,

      OnShow = function(self, data)
        self.editBox:SetText(data)
        self.editBox:HighlightText()
        self.editBox:SetFocus()
      end,

      EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
      end,

      timeout = 0,
      whileDead = true,
      preferredIndex = 3,
    }
  end

  StaticPopup_Show("DOTMASTER_EXPORT_DIALOG", nil, nil, export)

  return export -- Also return it for potential other uses
end

-- Initialize the debug system
function Debug:Initialize()
  DM:DebugMsg("Debug system initialized")
end

-- Return the module
return Debug
