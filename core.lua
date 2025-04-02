-- DotMaster core.lua
-- Final initialization and startup

local DM = DotMaster

-- Phase 1: Early Initialization (Settings & Debug System)
local earlyInitOK, earlyInitErr = pcall(function()
  -- Load settings (essential for debug flags)
  if DM.LoadSettings then
    DM:LoadSettings()
  else
    DM:SimplePrint("LoadSettings function not found!")
  end

  -- Initialize Debug System Core (Hooks, Logging)
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
  else
    DM:SimplePrint("DM.Debug.CreateDebugWindow not found!")
  end

  -- Initialize Debug Slash Commands
  if DM.InitializeDebugSlashCommands then
    DM:InitializeDebugSlashCommands()
  else
    DM:SimplePrint("InitializeDebugSlashCommands not found!")
  end
end)

if not earlyInitOK then
  DM:SimplePrint("CRITICAL ERROR during early initialization: " .. tostring(earlyInitErr))
end

-- Phase 2: Main Addon Initialization (calls DM:Initialize() from init.lua)
-- This will now use pcall internally for fragile components
local mainInitOK, mainInitErr = pcall(function()
  DM:Initialize()
end)

if not mainInitOK then
  DM:DebugMsg("ERROR during main initialization (DM:Initialize): " .. tostring(mainInitErr))
  DM:PrintMessage("Main addon initialization failed. Some features may be broken. Check /dmdebug console.")
end

-- Final debug note
DM:DebugMsg("Core.lua execution finished.")
