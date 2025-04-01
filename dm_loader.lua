--[[
  DotMaster - Loader Module

  File: dm_loader.lua
  Purpose: Final initialization and startup sequence for the addon

  This file should be loaded last in the .toc file to ensure all modules
  are properly loaded and initialized in the correct order.

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster -- reference to main addon

-- Track initialization status
local initComplete = false

-- Local functions for initialization
local function initializeModules()
  -- Initialize Debug module first if available
  if DM.Debug and DM.Debug.Initialize then
    DM.Debug:Initialize()
    DM:DebugMsg("Debug module initialized")
  end

  -- Initialize Utils
  if DM.Utils then
    DM:DebugMsg("Utils module loaded")
  end

  -- Initialize Nameplate module
  if DM.Nameplate and DM.Nameplate.Initialize then
    DM.Nameplate:Initialize()
    DM:DebugMsg("Nameplate module initialized")
  end

  -- Initialize Spells module
  if DM.Spells and DM.Spells.Initialize then
    DM.Spells:Initialize()
    DM:DebugMsg("Spells module initialized")
  end

  -- Initialize FindMyDots module
  if DM.FindMyDots and DM.FindMyDots.Initialize then
    DM.FindMyDots:Initialize()
    DM:DebugMsg("FindMyDots module initialized")
  end

  -- Initialize UI module last
  if DM.UI and DM.UI.Initialize then
    DM.UI:Initialize()
    DM:DebugMsg("UI module initialized")
  end

  initComplete = true
  DM:DebugMsg("All modules initialized")
end

-- Now that all modules are loaded, we can safely initialize the addon
DM:Initialize()

-- Initialize all modules
initializeModules()

-- Debug note to indicate everything has loaded correctly
DM:DebugMsg("Core initialization complete - all modules loaded")

-- Return initialization status
return initComplete
