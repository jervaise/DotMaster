-- DotMaster nameplate_coloring.lua
-- Handles nameplate coloring functionality

local DM = DotMaster

-- Apply a color to a nameplate
function DM:ApplyColorToNameplate(nameplate, unitToken, color)
  if not nameplate or not color then return false end

  DM:NameplateDebug("ApplyColorToNameplate called: %s, Color: %d/%d/%d",
    nameplate:GetName() or "unnamed",
    color[1] * 255, color[2] * 255, color[3] * 255)

  -- Check if Plater is available and handle it specially
  if _G["Plater"] then
    DM:NameplateDebug("Plater detected")
    local unitFrame = nameplate.unitFrame
    if unitFrame and unitFrame.healthBar then
      unitFrame.healthBar:SetStatusBarColor(unpack(color))
      return true
    else
      DM:NameplateDebug("Plater unitFrame or healthBar not found")
      return false
    end
  else
    DM:NameplateDebug("Using standard nameplate")
    -- Standard nameplate
    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if not healthBar then
      DM:NameplateDebug("HealthBar not found")
      return false
    end

    -- Store original color first time if not already stored
    local unitToken = nameplate.namePlateUnitToken
    if unitToken and not DM.originalColors[unitToken] then
      local r, g, b = healthBar:GetStatusBarColor()
      DM.originalColors[unitToken] = { r, g, b }
      DM:NameplateDebug("Saving original color: %d/%d/%d", r * 255, g * 255, b * 255)
    end

    -- Apply the new color
    DM.coloredPlates[unitToken] = true
    DM:NameplateDebug("Applying new color: %d/%d/%d", color[1] * 255, color[2] * 255, color[3] * 255)
    healthBar:SetStatusBarColor(unpack(color))
    DM:NameplateDebug("Nameplate color successfully changed")
    return true
  end
end

-- Restore a nameplate's original color
function DM:RestoreDefaultColor(nameplate, unitToken)
  if not self.coloredPlates[unitToken] then return end

  local healthBar
  local unitFrame

  if _G["Plater"] then
    local Plater = _G["Plater"]
    unitFrame = nameplate.unitFrame
    if not unitFrame or not unitFrame.healthBar then return end
    healthBar = unitFrame.healthBar

    if self.originalColors[unitToken] then
      healthBar:SetStatusBarColor(unpack(self.originalColors[unitToken]))
    else
      if unitFrame.RefreshHealthbarColor then
        unitFrame:RefreshHealthbarColor()
      elseif Plater.ForceRefreshNameplateColor then
        Plater.ForceRefreshNameplateColor(unitFrame)
      end
    end

    if unitFrame.PlateFrame and unitFrame.PlateFrame.UpdatePlateFrame then
      unitFrame.PlateFrame.UpdatePlateFrame()
    end
  else
    healthBar = self:GetHealthBar(nameplate)
    if not healthBar then return end

    if self.originalColors[unitToken] then
      healthBar:SetStatusBarColor(unpack(self.originalColors[unitToken]))
    else
      healthBar:SetStatusBarColor(UnitCanAttack("player", unitToken) and 1 or 0,
        UnitCanAttack("player", unitToken) and 0 or 1, 0)
    end
  end

  self.coloredPlates[unitToken] = nil
end
