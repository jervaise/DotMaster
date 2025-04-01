--[[
  DotMaster - Core Module

  File: dm_core.lua
  Purpose: Main initialization and core functionality for the addon

  Functions:
  - Initialize(): Main initialization function
  - OnEvent(): Event handler for the addon
  - PrintMessage(): Print a message with the addon prefix
  - SimplePrint(): Simple print function that doesn't require DebugMsg

  Dependencies: None (This is the first file loaded)

  Author: Jervaise
  Last Updated: 2024-06-19
]]

-- Create addon frame and namespace
DotMaster = CreateFrame("Frame")
local DM = DotMaster

-- Constants
DM.VIRULENT_PLAGUE_ID = 191587
DM.DEFAULT_PURPLE_COLOR = { 0.6, 0.2, 1.0 }
DM.MAX_CUSTOM_SPELLS = 20
DM.VERSION = "0.4.2"

-- Setup basic variables
DM.activePlates = {}
DM.coloredPlates = {}
DM.originalColors = {}
DM.enabled = true
DM.spellConfig = {}
DM.GUI = {}
DM.recordingDots = false
DM.detectedDots = {}
DM.defaults = {
  enabled = true,
  version = "0.4.2",
  lastSortOrder = 1, -- Added for sorting functionality
  spellConfig = {
    -- Default spells disabled, users will add their own
    -- [DM.VIRULENT_PLAGUE_ID] = { enabled = true, color = DM.DEFAULT_PURPLE_COLOR, name = "Virulent Plague" }
  }
}

-- Debug mode enabled by default
DM.DEBUG_MODE = true

-- Simple print function that doesn't require DebugMsg
function DM:SimplePrint(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Main initialization function
function DM:Initialize()
  -- Use SimplePrint as a fallback if DebugMsg is not available yet
  if self.DebugMsg then
    self:DebugMsg("Initializing DotMaster")
  else
    self:SimplePrint("Initializing DotMaster")
  end

  -- Load settings
  self:LoadSettings()
  if self.DebugMsg then
    self:DebugMsg("Settings loaded")
  else
    self:SimplePrint("Settings loaded")
  end

  -- Register events
  self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  self:RegisterEvent("UNIT_AURA")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LOGOUT")
  if self.DebugMsg then
    self:DebugMsg("Events registered")
  else
    self:SimplePrint("Events registered")
  end

  -- Create the GUI - Control removed
  if self.CreateGUI then
    self:CreateGUI()
    if self.DebugMsg then
      self:DebugMsg("GUI creation successful")
    else
      self:SimplePrint("GUI creation successful")
    end
  else
    if self.DebugMsg then
      self:DebugMsg("CreateGUI function not found")
    else
      self:SimplePrint("CreateGUI function not found")
    end
  end

  -- Initialize the slash commands
  self:InitializeSlashCommands()

  -- Hook Plater if available
  if _G["Plater"] then
    local Plater = _G["Plater"]
    if self.DebugMsg then
      self:DebugMsg("Plater detected, adding hooks")
    else
      self:SimplePrint("Plater detected, adding hooks")
    end

    hooksecurefunc(Plater, "UpdatePlateFrame", function(plateFrame)
      C_Timer.After(0.1, function()
        if not DM.enabled then return end
        local unitToken = plateFrame.namePlateUnitToken
        if unitToken and DM.activePlates[unitToken] then
          DM:UpdateNameplate(unitToken)
        end
      end)
    end)
  end

  self:PrintMessage("loaded. Type /dm to open options.")
end

-- Event handler
function DM:OnEvent(event, ...)
  if event == "NAME_PLATE_UNIT_ADDED" then
    self:NameplateAdded(...)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    self:NameplateRemoved(...)
  elseif event == "UNIT_AURA" then
    self:UnitAuraChanged(...)
  elseif event == "PLAYER_ENTERING_WORLD" then
    wipe(self.activePlates)
    wipe(self.coloredPlates)
    wipe(self.originalColors)
  elseif event == "PLAYER_LOGOUT" then
    self:SaveSettings()
  end
end

-- Set up event handling
DM:SetScript("OnEvent", function(self, ...) self:OnEvent(...) end)

-- Basic print message function in case dm_utils.lua isn't loaded yet
function DM:PrintMessage(message, ...)
  local prefix = "|cFFCC00FFDotMaster:|r "
  if select('#', ...) > 0 then
    print(prefix .. message, ...)
  else
    print(prefix .. message)
  end
end

-- Return the module
return DM
