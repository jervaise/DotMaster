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

-- Apply a color to a nameplate border only
function DM:SetNameplateBorderColor(unitFrame, color)
  if not unitFrame or not unitFrame.healthBar or not color then return false end

  local Plater = _G["Plater"]
  if not Plater then return false end

  local border = unitFrame.healthBar.border
  if not border then
    DM:NameplateDebug("Border not found on healthBar")
    return false
  end

  -- Store original border thickness if we haven't already
  local unitToken = unitFrame.unit
  if unitToken and not DM.originalBorderThickness then
    DM.originalBorderThickness = {}
  end

  if unitToken and not DM.originalBorderThickness[unitToken] then
    -- Try to get current thickness from Plater DB or use 1 as default
    local currentThickness = Plater.db and Plater.db.profile and Plater.db.profile.border_thickness or 1
    DM.originalBorderThickness[unitToken] = currentThickness
    DM:NameplateDebug("Stored original border thickness for %s: %d", unitToken, currentThickness)
  end

  -- Set the border color
  border:SetVertexColor(color[1], color[2], color[3], color[4] or 1)

  -- Set the border size if specified in settings
  if DM.settings and DM.settings.borderThickness then
    border:SetBorderSizes(DM.settings.borderThickness, DM.settings.borderThickness,
      DM.settings.borderThickness, DM.settings.borderThickness)
    border:UpdateSizes()
  end

  -- Set custom border color flag so Plater knows we're handling this
  unitFrame.customBorderColor = { color[1], color[2], color[3], color[4] or 1 }

  DM:NameplateDebug("Border color set to: %d/%d/%d, thickness: %d",
    color[1] * 255, color[2] * 255, color[3] * 255,
    DM.settings.borderThickness or 1)

  return true
end

-- Create a flash animation for a nameplate
function DM:CreateNameplateFlash(unitFrame, color)
  local Plater = _G["Plater"]
  if not Plater or not Plater.CreateFlash then return nil end

  -- For border only mode, use Plater's border flash function instead
  if DM.settings.borderOnly then
    -- Create a custom border flash effect that's more visible
    return {
      Play = function()
        -- Use Plater's built-in border flash function with more frequent flashes
        if unitFrame.healthBar.canHealthFlash then
          -- Call multiple times with delayed execution to create rapid sequence
          unitFrame.healthBar.PlayHealthFlash(0.15)

          -- Create a repeating flash timer
          if not unitFrame.DotMasterBorderFlashTimer then
            unitFrame.DotMasterBorderFlashTimer = C_Timer.NewTicker(0.4, function()
              if unitFrame.healthBar and unitFrame.healthBar.canHealthFlash then
                unitFrame.healthBar.PlayHealthFlash(0.15)
              end
            end)
          end
        end
      end,
      Stop = function()
        -- Cancel the flash timer if it exists
        if unitFrame.DotMasterBorderFlashTimer then
          unitFrame.DotMasterBorderFlashTimer:Cancel()
          unitFrame.DotMasterBorderFlashTimer = nil
        end
      end
    }
  else
    -- Create a custom flash animation that respects the health value
    local healthBar = unitFrame.healthBar
    if not healthBar then return nil end

    -- Create a flash frame that's the same size as the current health value
    local flashFrame = CreateFrame("Frame", nil, healthBar)
    flashFrame:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    flashFrame:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
    flashFrame:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
    flashFrame:SetWidth(healthBar:GetWidth() * (healthBar:GetValue() / healthBar:GetMinMaxValues()))
    flashFrame:Hide()

    -- Create flash texture
    local texture = flashFrame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()

    -- More vibrant color for visibility (brighten the color)
    local r, g, b = color[1], color[2], color[3]
    -- Brighten the colors while preserving their relative proportions
    local maxChannel = math.max(r, g, b)
    if maxChannel > 0 then
      r = r / maxChannel
      g = g / maxChannel
      b = b / maxChannel
    end

    texture:SetColorTexture(r, g, b, 0.7)
    texture:SetBlendMode("ADD")

    -- Create animation group
    local animGroup = texture:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")

    -- Alpha animation (fade in) - faster and brighter
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.1)
    fadeIn:SetToAlpha(0.9)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)

    -- Alpha animation (fade out) - faster
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.9)
    fadeOut:SetToAlpha(0.1)
    fadeOut:SetDuration(0.3)
    fadeOut:SetOrder(2)

    -- Update function to make sure flash follows health value changes
    local function UpdateFlashWidth()
      if healthBar:IsVisible() then
        local min, max = healthBar:GetMinMaxValues()
        if max and max > 0 then
          local val = healthBar:GetValue() or 0
          local width = healthBar:GetWidth() * (val / max)
          flashFrame:SetWidth(width)
        end
      end
    end

    -- Set up update events
    flashFrame:SetScript("OnUpdate", UpdateFlashWidth)

    -- Set animation callbacks
    animGroup:SetScript("OnPlay", function()
      flashFrame:Show()

      -- Store original nameplate text color if needed
      -- This ensures nameplate text doesn't flash
      local nameText = unitFrame.healthBar.unitName
      if nameText then
        flashFrame.originalTextColor = { nameText:GetTextColor() }
        nameText:SetTextColor(unpack(flashFrame.originalTextColor))
      end
    end)

    animGroup:SetScript("OnStop", function()
      flashFrame:Hide()
    end)

    -- Return the animation controller
    return {
      Play = function()
        -- Update the width before playing
        UpdateFlashWidth()
        animGroup:Play()
      end,
      Stop = function()
        animGroup:Stop()
      end,
      flashFrame = flashFrame -- Store reference to flash frame
    }
  end
end

-- Check for expiring DoTs and trigger flashes
function DM:CheckForExpiringDoTs(unitToken)
  if not unitToken or not DM.settings.flashExpiring then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
  if not nameplate then return end

  local unitFrame = nameplate.unitFrame
  if not unitFrame then return end

  -- Get all active dots on this unit
  local activeDots = self:GetActiveDots(unitToken)
  if not activeDots or not next(activeDots) then return end

  -- Get our flash animation
  if not self.flashAnimations then self.flashAnimations = {} end

  local flash = self.flashAnimations[unitToken]

  -- Find if any DoT is about to expire
  local expiringFound = false
  local now = GetTime()
  local threshold = DM.settings.flashThresholdSeconds or 3.0

  for spellID, dotInfo in pairs(activeDots) do
    local remainingTime = dotInfo.expirationTime - now
    if remainingTime > 0 and remainingTime <= threshold then
      expiringFound = true

      -- If we don't have a flash animation yet, create one with this DoT's color
      if not flash then
        flash = self:CreateNameplateFlash(unitFrame, dotInfo.color)
        if flash then
          self.flashAnimations[unitToken] = flash
        end
      end

      break
    end
  end

  -- Play or stop the flash animation
  if expiringFound and flash then
    flash:Play()
  elseif flash then
    flash:Stop()
  end
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

      -- Check for border-only mode
      if DM.settings and DM.settings.borderOnly then
        DM:NameplateDebug("Border-only mode is enabled")

        -- Apply color only to the border
        if self:SetNameplateBorderColor(unitFrame, color) then
          self.coloredPlates[unitToken] = true

          -- Create flash animation for this nameplate if needed
          if DM.settings.flashExpiring then
            self:CheckForExpiringDoTs(unitToken)
          end

          return true
        end
      else
        -- If not using border-only mode, use full nameplate coloring
        DM:NameplateDebug("Applying regular DoT color to full nameplate")
        Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)

        -- These flags tell Plater not to change this nameplate's color
        unitFrame.UsingCustomColor = true
        unitFrame.DenyColorChange = true

        self.coloredPlates[unitToken] = true

        -- Create flash animation for this nameplate if needed
        if DM.settings.flashExpiring then
          self:CheckForExpiringDoTs(unitToken)
        end

        return true
      end
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

    -- If we were in border-only mode, restore default Plater border settings
    if DM.settings and DM.settings.borderOnly then
      -- Reset custom border color flag
      unitFrame.customBorderColor = nil

      -- Get the original border thickness if we stored it
      local borderThickness = 1 -- Fallback default
      if DM.originalBorderThickness and DM.originalBorderThickness[unitToken] then
        borderThickness = DM.originalBorderThickness[unitToken]
        DM:NameplateDebug("Using stored original border thickness: %d", borderThickness)
        -- Clear the stored value
        DM.originalBorderThickness[unitToken] = nil
      else
        -- Fallback to Plater's default border thickness from its DB
        borderThickness = Plater.db and Plater.db.profile and Plater.db.profile.border_thickness or 1
        DM:NameplateDebug("No stored thickness found, using Plater default: %d", borderThickness)
      end

      -- Reset border thickness to original
      if healthBar.border then
        healthBar.border:SetBorderSizes(borderThickness, borderThickness, borderThickness, borderThickness)
        healthBar.border:UpdateSizes()
        DM:NameplateDebug("Reset border thickness to: %d", borderThickness)
      end

      -- Restore default border color
      Plater.UpdateBorderColor(unitFrame)
      DM:NameplateDebug("Reset border color to Plater default")
    else
      -- Reset Plater's color control flags - this is critical
      unitFrame.UsingCustomColor = nil
      unitFrame.DenyColorChange = nil

      -- Reset the healthBar color variables to ensure Plater recalculates them
      healthBar.R, healthBar.G, healthBar.B, healthBar.A = nil, nil, nil, nil
    end

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

    -- Stop any flash animations
    if self.flashAnimations and self.flashAnimations[unitToken] then
      self.flashAnimations[unitToken]:Stop()
      self.flashAnimations[unitToken] = nil
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
