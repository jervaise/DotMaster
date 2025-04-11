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
  print("   |cff00ff00/dm plater|r - Get Plater script in chat");
  print("   |cff00ff00/dm platerimport|r - Open Plater import window");
  print("   |cff00ff00/dm platervalidate|r - Validate import string (debug)");
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
    -- Display script code for manual copy/paste
    DM:PrintMessage("|cFFFFD100DotMaster Integration Script for Plater:|r")

    DM:PrintMessage("|cFFFFD100Initialization tab:|r")
    DM:PrintMessage("function (scriptTable)")
    DM:PrintMessage("  --insert code here")
    DM:PrintMessage("")
    DM:PrintMessage("end")

    DM:PrintMessage("|cFFFFD100On Show tab:|r")
    DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
    DM:PrintMessage("  ")
    DM:PrintMessage("end")

    DM:PrintMessage("|cFFFFD100On Update tab:|r")
    DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
    DM:PrintMessage("  Plater.SetNameplateColor (unitFrame, scriptTable.config.agonyColor)")
    DM:PrintMessage("  if envTable._RemainingTime <= scriptTable.config.threshold then")
    DM:PrintMessage("    envTable.agonyFlash:Play()")
    DM:PrintMessage("  else")
    DM:PrintMessage("    envTable.agonyFlash:Stop()")
    DM:PrintMessage("  end")
    DM:PrintMessage("end")

    DM:PrintMessage("|cFFFFD100On Hide tab:|r")
    DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
    DM:PrintMessage("  Plater.SetNameplateColor (unitFrame)")
    DM:PrintMessage("  envTable.agonyFlash:Stop()")
    DM:PrintMessage("end")

    DM:PrintMessage("|cFFFFD100Constructor tab:|r")
    DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
    DM:PrintMessage(
    "  envTable.agonyFlash = envTable.agonyFlash or Plater.CreateFlash (unitFrame.healthBar, 0.5, scriptTable.config.threshold * 2, scriptTable.config.agonyColor)")
    DM:PrintMessage("end")

    DM:PrintMessage("|cFFFFD100For easier installation, use:|r")
    DM:PrintMessage("/dm platerimport - Open import dialog window")
  elseif (msg == "platerimport") then
    -- Show the import dialog with encoded script
    if DM.API and DM.API.ShowPlaterImportString then
      DM.API:ShowPlaterImportString()
    else
      DM:PrintMessage("API not initialized yet. Try reloading UI.")
    end
  elseif (msg == "platervalidate") then
    -- Run validation on our import string against the reference
    if DM.API and DM.API.ValidateImportString then
      DM.API:ValidateImportString(true)
    else
      DM:PrintMessage("API not initialized yet. Try reloading UI.")
    end
  else
    DM:PrintMessage("Unknown command: " .. msg)
    HelpCommand(msg);
  end
end

-- Helper function to count table entries (for debugging)
function DM:TableCount(t)
  if type(t) ~= "table" then
    return 0
  end

  local count = 0
  for _ in pairs(t) do
    count = count + 1
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

-- Nameplate coloring functions for Plater
-- Cache to store recently calculated colors for each unit
DM.UnitColorCache = {}
DM.UnitColorLastUpdate = {}

-- Get color for a unit without throttling
function DM.GetColorForUnit(unitID)
  -- This is a stub for future implementation
  -- Will return a fixed color for now
  if not unitID then return nil end

  -- For demonstration, always return a fixed color
  -- In actual implementation, this would check for DoTs on the unit
  return { r = 0.8, g = 0.2, b = 0.8 }
end

-- Get color for a unit with throttling (to improve performance)
function DM.GetColorForUnitThrottled(unitID)
  if not unitID then return nil end

  -- Check if we've calculated this unit's color recently (within 0.1 seconds)
  local now = GetTime()
  local lastUpdate = DM.UnitColorLastUpdate[unitID] or 0

  if now - lastUpdate < 0.1 then
    -- Return cached color if available
    return DM.UnitColorCache[unitID]
  end

  -- Calculate new color
  local color = DM.GetColorForUnit(unitID)

  -- Cache the result
  DM.UnitColorCache[unitID] = color
  DM.UnitColorLastUpdate[unitID] = now

  return color
end

DM:DebugMsg("Core.lua execution finished.")
