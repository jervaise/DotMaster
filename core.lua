-- DotMaster core.lua
-- Core structures and minimal initialization

local DM = DotMaster

-- Skip duplicate initialization if bootstrap has already handled it
if DM.initState and DM.initState ~= "bootstrap" then
  DM:DebugMsg("Core.lua: Skipping duplicated initialization (current state: " .. DM.initState .. ")")
  return
end

-- Initialize necessary structures
DM.settings = DM.settings or {}
DM.enabled = true

-- Set up basic defaults
DM.defaults = DM.defaults or {
  enabled = true,
  debug = false,
  version = "1.0.3",
  flashExpiring = false,
  flashThresholdSeconds = 3.0
}

-- Enable development mode - can be toggled from settings
DM.DEBUG_MODE = false

-- Register a slash command to toggle debug mode
SLASH_DMDEBUG1 = "/dmdebug"
SlashCmdList["DMDEBUG"] = function(msg)
  DM.DEBUG_MODE = not DM.DEBUG_MODE
  DM:PrintMessage("Debug mode is now " .. (DM.DEBUG_MODE and "ON" or "OFF"))
end

-- Utility function for table size
function DM:TableCount(table)
  local count = 0
  if table then
    for _ in pairs(table) do
      count = count + 1
    end
  end
  return count
end

-- Basic message printing function
function DM:PrintMessage(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Color picker debug function
function DM:ColorPickerDebug(message)
  if DM.DEBUG_MODE then
    DM:PrintMessage("[ColorPicker] " .. message)
  end
end

DM:DebugMsg("Core.lua execution finished.")
