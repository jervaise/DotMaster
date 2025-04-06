-- DotMaster core.lua
-- Final initialization steps and startup

local DM = DotMaster

-- Skip duplicate initialization if bootstrap has already handled it
if DM.initState and DM.initState ~= "bootstrap" then
  DM:DebugMsg("Core.lua: Skipping duplicated initialization (current state: " .. DM.initState .. ")")
  return
end

-- Initialize necessary structures
DM.settings = DM.settings or {}
DM.dmspellsdb = DM.dmspellsdb or {}
DM.activePlates = DM.activePlates or {}
DM.coloredPlates = DM.coloredPlates or {}
DM.enabled = true
DM.defaults = DM.defaults or {
  enabled = true,
  debug = false,
  version = "1.0.3",
  flashExpiring = false,
  flashThresholdSeconds = 3.0
}

-- Initialize Debug System Core (Hooks, Logging)
local debugOK, debugErr = pcall(function()
  if DM.Debug and DM.Debug.Init then
    DM.Debug:Init()
    DM:DebugMsg("Core debug system initialized (logging hooked).")
  else
    DM:SimplePrint("DM.Debug.Init not found!")
  end

  -- Create Debug Console GUI (but don't show it yet)
  if DM.Debug and DM.Debug.CreateDebugWindow then
    DM.Debug:CreateDebugWindow()
    DM:DebugMsg("Debug console GUI created.")
  end
end)

if not debugOK then
  DM:SimplePrint("Error initializing debug system: " .. tostring(debugErr))
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

-- Check database state for diagnostic purposes
if DM.dmspellsdb then
  local count = DM:TableCount(DM.dmspellsdb)
  DM:DebugMsg("Database check from core.lua: " .. count .. " spells")
else
  DM:DebugMsg("Database check from core.lua: NOT LOADED")
end

-- Final debug note
DM:DebugMsg("Core.lua execution finished. Initialization will complete during PLAYER_ENTERING_WORLD event.")
