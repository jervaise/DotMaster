--[[
  DotMaster - Loader Module

  File: dm_loader.lua
  Purpose: Final initialization and startup of the addon

  This file is loaded last and initializes the addon
  after all other modules are loaded.

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Initialize the modules in the correct order
-- First, utility and core modules
if DM.SpellDB and DM.SpellDB.Initialize then
  DM.SpellDB:Initialize()
end

if DM.SpellUtils and DM.SpellUtils.Initialize then
  DM.SpellUtils:Initialize()
end

if DM.NameplateCore and DM.NameplateCore.Initialize then
  DM.NameplateCore:Initialize()
end

-- Then UI modules
if DM.UIComponents and DM.UIComponents.Initialize then
  DM.UIComponents:Initialize()
end

if DM.UITabs and DM.UITabs.Initialize then
  DM.UITabs:Initialize()
end

if DM.UIMain and DM.UIMain.Initialize then
  DM.UIMain:Initialize()
end

if DM.UIGeneralTab and DM.UIGeneralTab.Initialize then
  DM.UIGeneralTab:Initialize()
end

if DM.UISpellsTab and DM.UISpellsTab.Initialize then
  DM.UISpellsTab:Initialize()
end

-- Initialize the FindMyDots modules if they exist
if DM.FindMyDots and DM.FindMyDots.Initialize then
  DM.FindMyDots:Initialize()
end

if DM.FindMyDotsUI and DM.FindMyDotsUI.Initialize then
  DM.FindMyDotsUI:Initialize()
end

-- Now that all modules are loaded, we can safely initialize the addon
DM:Initialize()

-- Debug note to indicate everything has loaded correctly
DM:DebugMsg("Core initialization complete - all modules loaded")
