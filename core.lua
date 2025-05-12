-- DotMaster core.lua
-- Core structures and minimal initialization

local DM = DotMaster

-- Skip duplicate initialization if bootstrap has already handled it
if DM.initState and DM.initState ~= "bootstrap" then
  return
end

-- Initialize necessary structures
DM.settings = DM.settings or {}
DM.enabled = true

-- Set up basic defaults
DM.defaults = DM.defaults or {
  enabled = true,
  version = "1.0.4",
  flashExpiring = false,
  flashThresholdSeconds = 3.0
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
  elseif (msg == "on") then
    DM.enabled = true
    DM:PrintMessage("DotMaster enabled")
  elseif (msg == "off") then
    DM.enabled = false
    DM:PrintMessage("DotMaster disabled")
  else
    DM:PrintMessage("Unknown command: " .. msg)
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

-- Add function to install DotMaster mod into Plater
function DM:InstallPlaterMod()
  local Plater = _G["Plater"]
  if not (Plater and Plater.db and Plater.db.profile) then
    DM:PrintMessage("Plater not found or incompatible")
    return
  end

  -- Ensure hook_data table exists
  if not Plater.db.profile.hook_data then
    Plater.db.profile.hook_data = {}
  end

  local data = Plater.db.profile.hook_data
  local modName = "DotMaster Integration"
  local foundIndex
  for i, mod in ipairs(data) do
    if mod.Name == modName then
      foundIndex = i
      break
    end
  end

  -- Stub code for hook
  local hookCode = "function(self, unitId, unitFrame, envTable, modTable) end"

  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName
    modEntry.Icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    modEntry.Desc = "DotMaster integration stub"
    modEntry.Author = UnitName("player") or "DotMaster"
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 1) + 1
    modEntry.PlaterCore = Plater.CoreVersion or 0
    modEntry.Hooks = { ["Nameplate Updated"] = hookCode }
    modEntry.HooksTemp = { ["Nameplate Updated"] = hookCode }
    modEntry.LastHookEdited = "Nameplate Updated"
    DM:PrintMessage("Updated existing DotMaster mod")
  else
    local newMod = {
      Enabled = true,
      Name = modName,
      Icon = "Interface\\Icons\\INV_Misc_QuestionMark",
      Desc = "DotMaster integration stub",
      Author = UnitName("player") or "DotMaster",
      Time = time(),
      Revision = 1,
      PlaterCore = Plater.CoreVersion or 0,
      Hooks = { ["Nameplate Updated"] = hookCode },
      HooksTemp = { ["Nameplate Updated"] = hookCode },
      LastHookEdited = "Nameplate Updated",
      LoadConditions = {},
      Options = {},
      UID = (createUniqueIdentifier and createUniqueIdentifier()) or nil,
    }
    -- Build options table for UI
    if Plater.CreateOptionTableForScriptObject then
      Plater.CreateOptionTableForScriptObject(newMod)
    end
    table.insert(data, newMod)
    DM:PrintMessage("Added new DotMaster mod")
  end

  -- Recompile hook scripts and refresh plates
  if Plater.WipeAndRecompileAllScripts then
    Plater.WipeAndRecompileAllScripts("hook")
  end
  if Plater.FullRefreshAllPlates then
    Plater.FullRefreshAllPlates()
  end
end
