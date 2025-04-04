-- DotMaster nameplate_coloring.lua
-- Handles nameplate coloring functionality

local DM = DotMaster

-- Helper function to apply threat coloring based on Plater settings
function DM:ApplyThreatColor(unitFrame, unitToken)
  local Plater = _G["Plater"]
  if not Plater then return false end

  -- Check if player is a tank
  if Plater.PlayerIsTank then
    -- Player is a tank, check if we lost aggro
    if not unitFrame.namePlateThreatIsTanking then
      -- Check for raid tanks (same logic as the mod example)
      if Plater.ZoneInstanceType == "raid" then
        -- Get tanks in the raid
        local tankPlayersInTheRaid = Plater.GetTanks()

        -- Get the target of this unit
        local unitTargetName = UnitName(unitFrame.targetUnitID)

        -- If the unit isn't targeting another tank, show the noaggro color
        if not tankPlayersInTheRaid[unitTargetName] then
          DM:NameplateDebug("Tank lost aggro - applying no-aggro color")
          Plater.SetNameplateColor(unitFrame, Plater.db.profile.tank.colors.noaggro)
          return true
        end
      else
        -- Not in raid, just apply no-aggro color
        DM:NameplateDebug("Tank lost aggro - applying no-aggro color")
        Plater.SetNameplateColor(unitFrame, Plater.db.profile.tank.colors.noaggro)
        return true
      end
    end
  else
    -- Player is DPS/healer - check if we have aggro
    if unitFrame.namePlateThreatIsTanking then
      DM:NameplateDebug("DPS/Healer has aggro - applying aggro color")
      Plater.SetNameplateColor(unitFrame, Plater.db.profile.dps.colors.aggro)
      return true
    end
  end

  return false
end

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
      -- If Force Threat Color is enabled, check threat conditions
      if DM.settings and DM.settings.forceColor then
        DM:NameplateDebug("Force Threat Color is enabled - checking threat state")

        -- Apply threat-based color if applicable
        if self:ApplyThreatColor(unitFrame, unitToken) then
          -- Tell DotMaster we're handling this nameplate
          self.coloredPlates[unitToken] = true
          return true
        end
      end

      -- If not using threat colors or no threat condition matched, use our DoT color
      DM:NameplateDebug("Applying regular DoT color")
      Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)

      -- These flags tell Plater not to change this nameplate's color
      unitFrame.UsingCustomColor = true
      unitFrame.DenyColorChange = true

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

-- Function to reapply DoT colors after leaving combat
-- This is needed because Plater resets all nameplate colors when combat ends
function DM:HookPlaterFunctions()
  local Plater = _G["Plater"]
  if not Plater then
    DM:NameplateDebug("Plater not found, cannot hook color functions")
    return
  end

  DM:NameplateDebug("Setting up Plater function hooks to prevent color flicker")

  -- Store the original function
  local originalUpdateAllNameplateColors = Plater.UpdateAllNameplateColors

  -- Hook the function that updates all nameplate colors (called when leaving combat)
  Plater.UpdateAllNameplateColors = function(...)
    -- First let Plater do its work
    local result = originalUpdateAllNameplateColors(...)

    -- Then immediately reapply our colors to prevent flicker
    if DM.enabled then
      C_Timer.After(0, function() -- Use immediate timer to ensure we run after Plater's function completes
        DM:NameplateDebug("Plater attempted to reset colors - immediately reapplying DoT colors")
        DM:UpdateAllNameplates()
      end)
    end

    return result
  end

  -- Store the original refresh function
  local originalRefreshNameplateColor = Plater.RefreshNameplateColor

  -- Hook the function that refreshes individual nameplate colors
  Plater.RefreshNameplateColor = function(unitFrame, ...)
    -- Let Plater do its work
    local result = originalRefreshNameplateColor(unitFrame, ...)

    -- Check if this is a nameplate we're tracking
    if DM.enabled and unitFrame and unitFrame.unit then
      local unitToken = unitFrame.unit
      if DM.activePlates[unitToken] then
        C_Timer.After(0, function()
          -- Reapply our colors if needed
          DM:UpdateNameplate(unitToken)
        end)
      end
    end

    return result
  end

  DM:NameplateDebug("Plater function hooks installed successfully")
end

-- Initialize the hook when this file loads
do
  C_Timer.After(1, function()
    if _G["Plater"] then
      DM:HookPlaterFunctions()
    else
      DM:NameplateDebug("Delaying Plater hook until Plater is loaded")
      C_Timer.After(2, function()
        if _G["Plater"] then
          DM:HookPlaterFunctions()
        else
          DM:NameplateDebug("Plater not found after delay, cannot hook functions")
        end
      end)
    end
  end)
end

-- We'll still keep the event registration as a backup
local combatEventFrame = CreateFrame("Frame")
combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEventFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    -- Use a very short delay to ensure we run after Plater's handlers
    C_Timer.After(0.01, function()
      if DM.enabled then
        DM:NameplateDebug("Combat ended - immediate reapplication of DoT colors")
        DM:UpdateAllNameplates()
      end
    end)
  end
end)
