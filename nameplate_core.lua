-- DotMaster nameplate_core.lua
-- Core nameplate management functionality

local DM = DotMaster

-- TEMPORARY: Message to show when nameplate functions are called
local DISABLED_MESSAGE = "Nameplate features are temporarily disabled during development."

-- Nameplate added event handler
function DM:NameplateAdded(unitToken)
  -- TEMPORARILY DISABLED
  self:DebugMsg("NameplateAdded: " .. DISABLED_MESSAGE)
  return

  -- Original code below (commented out)
  --[[
  if not self.enabled then return end
  self.activePlates[unitToken] = true

  C_Timer.After(0.1, function()
    if self.activePlates[unitToken] then
      self:UpdateNameplate(unitToken)
    end
  end)
  --]]
end

-- Nameplate removed event handler
function DM:NameplateRemoved(unitToken)
  -- TEMPORARILY DISABLED
  self:DebugMsg("NameplateRemoved: " .. DISABLED_MESSAGE)
  return

  -- Original code below (commented out)
  --[[
  if self.coloredPlates[unitToken] then
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then
      self:RestoreDefaultColor(nameplate, unitToken)
    end
  end

  self.activePlates[unitToken] = nil
  self.coloredPlates[unitToken] = nil
  self.originalColors[unitToken] = nil
  --]]
end

-- Handle aura changes on nameplates
function DM:UnitAuraChanged(unitToken)
  -- TEMPORARILY DISABLED
  self:DebugMsg("UnitAuraChanged: " .. DISABLED_MESSAGE)
  return

  -- Original code below (commented out)
  --[[
  if not unitToken or not unitToken:match("^nameplate") then return end
  if not self.activePlates[unitToken] then return end
  self:UpdateNameplate(unitToken)
  --]]
end

-- Update a nameplate's color based on debuffs
function DM:UpdateNameplate(unitToken)
  -- TEMPORARILY DISABLED
  self:DebugMsg("UpdateNameplate: " .. DISABLED_MESSAGE)
  return

  -- Original code below (commented out)
  --[[
  if not self.enabled or not unitToken or not UnitExists(unitToken) then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
  if not nameplate then return end

  local activeSpellID, color = self:CheckForTrackedDebuffs(unitToken)

  if activeSpellID and color then
    self:ApplyColorToNameplate(nameplate, unitToken, color)
  else
    self:RestoreDefaultColor(nameplate, unitToken)
  end
  --]]
end

-- Reset all nameplate colors
function DM:ResetAllNameplates()
  -- TEMPORARILY DISABLED
  self:DebugMsg("ResetAllNameplates: " .. DISABLED_MESSAGE)
  return

  -- Original code below (commented out)
  --[[
  for unitToken in pairs(self.coloredPlates) do
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then
      self:RestoreDefaultColor(nameplate, unitToken)
    end
  end
  wipe(self.coloredPlates)
  --]]
end

-- Update all nameplate colors
function DM:UpdateAllNameplates()
  -- TEMPORARILY DISABLED
  self:DebugMsg("UpdateAllNameplates: " .. DISABLED_MESSAGE)
  return

  -- Original code below (commented out)
  --[[
  for unitToken in pairs(self.activePlates) do
    self:UpdateNameplate(unitToken)
  end
  --]]
end

-- Helper function to find the health bar in a nameplate
function DM:GetHealthBar(nameplate)
  -- TEMPORARILY DISABLED
  self:DebugMsg("GetHealthBar: " .. DISABLED_MESSAGE)
  return nil

  -- Original code below (commented out)
  --[[
  local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar

  if not healthBar then
    for i = 1, nameplate:GetNumChildren() do
      local child = select(i, nameplate:GetChildren())
      if child:GetObjectType() == "StatusBar" then
        healthBar = child
        break
      end
    end
  end

  return healthBar
  --]]
end
