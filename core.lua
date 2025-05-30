-- DotMaster core.lua
-- Core structures and minimal initialization

-- Register DotMaster global object if not already done
if not DotMaster then
  DotMaster = CreateFrame("Frame", "DotMaster", UIParent)
end

-- Create a shorthand reference
local DM = DotMaster

-- Skip duplicate initialization if bootstrap has already handled it
if DM.initState and DM.initState ~= "bootstrap" then
  return
end

-- Initialize necessary structures
DM.settings = DM.settings or {}
DM.enabled = true

-- Get version from TOC with proper API
local function GetVersion()
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    return C_AddOns.GetAddOnMetadata("DotMaster", "Version")
  elseif GetAddOnMetadata then
    return GetAddOnMetadata("DotMaster", "Version")
  else
    return "2.2.0" -- Hardcoded fallback
  end
end

-- Set up basic defaults
DM.defaults = DM.defaults or {
  enabled = true,
  forceColor = false,
  borderOnly = false,
  borderThickness = 2,
  flashExpiring = false,
  flashThresholdSeconds = 3.0,
  version = GetVersion() or "Unknown",
  trackSwapBuffs = true
}

-- First, we'll setup our slash commands and the help system
local function HelpCommand(msg)
  print("|cff00cc00DotMaster|r: Available commands:");
  print("   |cff00ff00/dm help|r - Shows this help");
  print("   |cff00ff00/dm show|r - Shows configuration window");
  print("   |cff00ff00/dm toggle|r - Shows/hides configuration window");
end

-- Process slash commands
function DM:SlashCommand(msg)
  msg = string.lower(msg);
  if (msg == "" or msg == "help") then
    HelpCommand(msg);
  elseif (msg == "show") then
    DM.GUI:Show();
  elseif (msg == "toggle") then
    DM.GUI:Toggle();
  elseif (msg == "enable" or msg == "on") then
    DM.enabled = true
    if DotMasterDB then DotMasterDB.enabled = true end
    --DM:PrintMessage("DotMaster enabled")
  elseif (msg == "disable" or msg == "off") then
    DM.enabled = false
    if DotMasterDB then DotMasterDB.enabled = false end
    --DM:PrintMessage("DotMaster disabled")
  else
    --DM:PrintMessage("Unknown command: " .. msg)
    DM:GUI_Toggle() -- Toggle GUI for unknown commands for convenience
    HelpCommand(msg);
  end
end

-- Helper function to count table entries
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
