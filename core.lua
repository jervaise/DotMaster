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

-- First, we'll setup our slash commands and the help system
local function HelpCommand(msg)
  print("|cff00cc00DotMaster|r: Available commands:");
  print("   |cff00ff00/dm help|r - Shows this help");
  print("   |cff00ff00/dm show|r - Shows configuration window");
  print("   |cff00ff00/dm toggle|r - Shows/hides configuration window");
  print("   |cff00ff00/dm debug|r - Toggle debug mode");
  print("   |cff00ff00/dm plater|r - Inject DotMaster script into Plater");
end

-- Process slash commands
function DM:SlashCommand(msg)
  DM:DebugMsg("Slash command: " .. msg);
  msg = string.lower(msg);
  if (msg == "" or msg == "help") then
    HelpCommand(msg);
  elseif (msg == "show") then
    DM.GUI:Show();
  elseif (msg == "toggle") then
    DM.GUI:Toggle();
  elseif (msg == "on") then
    DM.enabled = true
    DM:PrintMessage("DotMaster enabled")
  elseif (msg == "off") then
    DM.enabled = false
    DM:PrintMessage("DotMaster disabled")
  elseif (msg == "debug") then
    DM.DEBUG_MODE = not DM.DEBUG_MODE;
    DM:DebugMsg("Debug mode: " .. (DM.DEBUG_MODE and "ON" or "OFF"));
  elseif (msg == "plater") then
    -- New command to inject script into Plater
    if DM.API.InjectPlaterScript then
      local success = DM.API:InjectPlaterScript()
      if success then
        -- Success message is now handled inside the InjectPlaterScript function
      else
        DM:PrintMessage("Failed to inject script into Plater. Is Plater installed and enabled?")
      end
    else
      DM:PrintMessage("API not initialized yet. Try again later.")
    end
  else
    HelpCommand(msg);
  end
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

-- Debug message printing function
function DM:DebugMsg(message)
  if DM.DEBUG_MODE then
    print("|cFF00FF00DotMaster Debug:|r " .. message)
  end
end

-- Color picker debug function
function DM:ColorPickerDebug(message)
  if DM.DEBUG_MODE then
    DM:PrintMessage("[ColorPicker] " .. message)
  end
end

DM:DebugMsg("Core.lua execution finished.")
