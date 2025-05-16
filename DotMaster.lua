-- DotMaster main file
DotMaster = LibStub("AceAddon-3.0"):NewAddon("DotMaster", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")
local DM = DotMaster

-- Add session settings tracking
DM.sessionStartSettings = {
  borderThickness = nil,
  borderOnly = nil
}

function DM:OnInitialize()
  -- Load saved variables
  self:LoadSettings()

  self.enabled = DotMasterDB and DotMasterDB.enabled  -- Initialize from DB, default to true
  if self.enabled == nil then self.enabled = true end -- Default if nil

  -- Save original settings state at addon load time
  if DotMasterDB and DotMasterDB.settings then
    DM.sessionStartSettings.borderThickness = DotMasterDB.settings.borderThickness
    DM.sessionStartSettings.borderOnly = DotMasterDB.settings.borderOnly
  end

  -- Initialize LDB for minimap button
  self:InitMinimapIcon()

  -- Initialize spell database
  self:InitSpellDatabase()

  -- Initialize combinations system
  self:InitCombinationSystem()
end
