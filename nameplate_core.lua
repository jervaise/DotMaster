-- DotMaster nameplate_core.lua
-- Core nameplate management functionality

local DM = DotMaster

-- Nameplate added event handler
function DM:NameplateAdded(unitToken)
  if not self.enabled then return end
  self.activePlates[unitToken] = true

  C_Timer.After(0.1, function()
    if self.activePlates[unitToken] then
      self:UpdateNameplate(unitToken)
    end
  end)
end

-- Nameplate removed event handler
function DM:NameplateRemoved(unitToken)
  if self.coloredPlates[unitToken] then
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then
      self:RestoreDefaultColor(nameplate, unitToken)
    end
  end

  self.activePlates[unitToken] = nil
  self.coloredPlates[unitToken] = nil
  self.originalColors[unitToken] = nil

  -- Also clean up any stored border thickness data
  if self.originalBorderThickness and self.originalBorderThickness[unitToken] then
    self.originalBorderThickness[unitToken] = nil
  end
end

-- Handle aura changes on nameplates
function DM:UnitAuraChanged(unitToken)
  if not unitToken or not unitToken:match("^nameplate") then return end
  if not self.activePlates[unitToken] then return end
  self:UpdateNameplate(unitToken)
end

-- Update a nameplate's color based on debuffs
function DM:UpdateNameplate(unitToken)
  if not self.enabled or not unitToken or not UnitExists(unitToken) then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
  if not nameplate then return end

  local activeSpellID, color = self:CheckForTrackedDebuffs(unitToken)

  if activeSpellID and color then
    self:ApplyColorToNameplate(nameplate, unitToken, color)
  else
    self:RestoreDefaultColor(nameplate, unitToken)
  end
end

-- Reset all nameplate colors
function DM:ResetAllNameplates()
  for unitToken in pairs(self.coloredPlates) do
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate then
      self:RestoreDefaultColor(nameplate, unitToken)
    end
  end
  wipe(self.coloredPlates)
end

-- Update all nameplate colors
function DM:UpdateAllNameplates()
  for unitToken in pairs(self.activePlates) do
    self:UpdateNameplate(unitToken)
  end
end

-- Helper function to find the health bar in a nameplate
function DM:GetHealthBar(nameplate)
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
end
