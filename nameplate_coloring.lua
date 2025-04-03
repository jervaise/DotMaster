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
    local Plater = _G["Plater"]
    DM:NameplateDebug("Plater detected")
    local unitFrame = nameplate.unitFrame
    if unitFrame and unitFrame.healthBar then
      -- Use Plater's API instead of direct color setting
      Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)
      self.coloredPlates[unitToken] = true
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

    -- Log for debugging
    DM:NameplateDebug("RestoreDefaultColor for Plater nameplate: %s", nameplate:GetName() or "unnamed")

    -- Reset Plater's color control flags - this is critical
    unitFrame.UsingCustomColor = nil
    unitFrame.DenyColorChange = nil

    -- Reset the healthBar color variables to ensure Plater recalculates them
    healthBar.R, healthBar.G, healthBar.B, healthBar.A = nil, nil, nil, nil

    -- Call Plater's color refresh function - this is the core method in the mod example
    Plater.RefreshNameplateColor(unitFrame)

    -- This will force Plater to immediately update nameplate colors based on threat/reaction
    if Plater.UpdateAllNameplateColors then
      Plater.UpdateAllNameplateColors()
    end

    -- Force a tick to ensure threat colors are updated - key part of Plater's color system
    if Plater.ForceTickOnAllNameplates then
      Plater.ForceTickOnAllNameplates()
    end
  else
    -- Standard nameplate handling (non-Plater)
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
