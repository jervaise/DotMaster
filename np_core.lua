--[[
  DotMaster - Nameplate Core Module

  File: np_core.lua
  Purpose: Core functionality for nameplate handling

  Functions:
  - NameplateAdded(): Handle when a nameplate is added
  - NameplateRemoved(): Handle when a nameplate is removed
  - UpdateNameplate(): Update a nameplate's appearance
  - ResetNameplate(): Reset a nameplate to its original appearance

  Dependencies:
  - dm_core.lua
  - dm_utils.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster -- reference to main addon
local NP = {}        -- local table for module functions
DM.Nameplate = NP    -- expose to addon namespace

-- Local variables
local activeNameplates = {}
local coloredNameplates = {}
local originalColors = {}

-- Local helper functions
local function getNameplateByUnitID(unitID)
  return C_NamePlate.GetNamePlateForUnit(unitID)
end

local function saveOriginalColor(namePlate, r, g, b)
  if not namePlate or not namePlate.UnitFrame or not namePlate.UnitFrame.healthBar then return end

  local unitToken = namePlate.namePlateUnitToken
  if not unitToken then return end

  if not originalColors[unitToken] then
    originalColors[unitToken] = { r = r, g = g, b = b }
  end
end

-- Called when a nameplate is added to the screen
function DM:NameplateAdded(unitToken)
  if not unitToken or not self.enabled then return end

  local namePlate = getNameplateByUnitID(unitToken)
  if not namePlate or not namePlate.UnitFrame or not namePlate.UnitFrame.healthBar then return end

  -- Store the original color
  local healthBar = namePlate.UnitFrame.healthBar
  local r, g, b = healthBar:GetStatusBarColor()
  saveOriginalColor(namePlate, r, g, b)

  -- Mark this as an active plate
  self.activePlates[unitToken] = true

  -- Check for auras
  self:UpdateNameplate(unitToken)

  if self.DebugMsg then
    self:DebugMsg("Nameplate added: " .. unitToken)
  end
end

-- Called when a nameplate is removed from the screen
function DM:NameplateRemoved(unitToken)
  if not unitToken then return end

  -- Remove from our tracking
  self.activePlates[unitToken] = nil
  self.coloredPlates[unitToken] = nil
  self.originalColors[unitToken] = nil

  if self.DebugMsg then
    self:DebugMsg("Nameplate removed: " .. unitToken)
  end
end

-- Update a nameplate's appearance based on auras
function DM:UpdateNameplate(unitToken)
  if not unitToken or not self.enabled then return end

  local namePlate = getNameplateByUnitID(unitToken)
  if not namePlate or not namePlate.UnitFrame or not namePlate.UnitFrame.healthBar then return end

  -- Get the unit's auras and check for our tracked debuffs
  local found = false
  local color

  -- This function will be implemented in np_detection.lua
  local activeAuras = self:ScanUnitAuras(unitToken)

  if activeAuras and #activeAuras > 0 then
    -- Use the first matching aura's color
    color = activeAuras[1].color
    found = true
  end

  -- Apply or reset color
  local healthBar = namePlate.UnitFrame.healthBar

  if found and color then
    healthBar:SetStatusBarColor(unpack(color))
    self.coloredPlates[unitToken] = color
  else
    self:ResetNameplate(unitToken)
  end
end

-- Reset a nameplate to its original appearance
function DM:ResetNameplate(unitToken)
  if not unitToken then return end

  local namePlate = getNameplateByUnitID(unitToken)
  if not namePlate or not namePlate.UnitFrame or not namePlate.UnitFrame.healthBar then return end

  local healthBar = namePlate.UnitFrame.healthBar
  local original = self.originalColors[unitToken]

  if original then
    healthBar:SetStatusBarColor(original.r, original.g, original.b)
  else
    -- Default fallback colors based on reaction
    if UnitIsPlayer(unitToken) then
      -- Use class color for players
      local _, class = UnitClass(unitToken)
      local color = RAID_CLASS_COLORS[class]
      healthBar:SetStatusBarColor(color.r, color.g, color.b)
    elseif UnitIsFriend("player", unitToken) then
      -- Friendly = green
      healthBar:SetStatusBarColor(0, 1, 0)
    else
      -- Hostile = red
      healthBar:SetStatusBarColor(1, 0, 0)
    end
  end

  self.coloredPlates[unitToken] = nil
end

-- Handle aura changes on a unit
function DM:UnitAuraChanged(unitToken)
  if not unitToken or not self.enabled then return end

  -- Only process nameplates we're tracking
  if not self.activePlates[unitToken] then return end

  -- Update the nameplate
  self:UpdateNameplate(unitToken)
end

-- Debug message function with module name
function NP:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[Nameplate] " .. message)
  end
end

-- Initialize the nameplate module
function NP:Initialize()
  NP:DebugMsg("Nameplate module initialized")
end

-- Return the module
return NP
