--[[
  DotMaster - Nameplate Coloring Module

  File: np_coloring.lua
  Purpose: Handle nameplate coloring functionality

  Functions:
  - ApplyColorToNameplate(): Apply color to a nameplate
  - RestoreDefaultColor(): Restore a nameplate's original color

  Dependencies:
  - dm_core.lua
  - np_core.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local NPColoring = {}      -- Local table for module functions
DM.NPColoring = NPColoring -- Expose to addon namespace

-- Apply color to a nameplate
function DM:ApplyColorToNameplate(nameplate, unitToken, color)
  DM:SpellDebug("ApplyColorToNameplate called: %s, Color: %d/%d/%d",
    unitToken, color[1] * 255, color[2] * 255, color[3] * 255)

  local healthBar

  if _G["Plater"] then
    DM:SpellDebug("Plater detected")
    local unitFrame = nameplate.unitFrame
    if not unitFrame or not unitFrame.healthBar then
      DM:SpellDebug("Plater unitFrame or healthBar not found")
      return
    end
    healthBar = unitFrame.healthBar
  else
    DM:SpellDebug("Using standard nameplate")
    healthBar = self:GetHealthBar(nameplate)
    if not healthBar then
      DM:SpellDebug("HealthBar not found")
      return
    end
  end

  -- Store original color if not already colored
  if not self.coloredPlates[unitToken] then
    local r, g, b = healthBar:GetStatusBarColor()
    DM:SpellDebug("Saving original color: %d/%d/%d", r * 255, g * 255, b * 255)
    self.originalColors[unitToken] = { r, g, b }
  end

  -- Mark as colored and apply color
  self.coloredPlates[unitToken] = true
  DM:SpellDebug("Applying new color: %d/%d/%d", color[1] * 255, color[2] * 255, color[3] * 255)
  healthBar:SetStatusBarColor(unpack(color))
  DM:SpellDebug("Nameplate color successfully changed")
end

-- Restore a nameplate's original color
function DM:RestoreDefaultColor(nameplate, unitToken)
  if not self.coloredPlates[unitToken] then return end

  local healthBar
  local unitFrame

  if _G["Plater"] then
    local Plater = _G["Plater"] -- Local variable
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

-- Debug message function with module name
function NPColoring:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[NPColoring] " .. message)
  end
end

-- Initialize the nameplate coloring module
function NPColoring:Initialize()
  NPColoring:DebugMsg("Nameplate coloring module initialized")
end

-- Return the module
return NPColoring
