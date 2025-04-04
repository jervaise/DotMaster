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
  if not Plater then return nil end

  -- Create a direct flash wrapper using Plater's built-in functionality
  return {
    Play = function()
      if not unitFrame or not unitFrame.healthBar then return end

      -- For border only mode
      if DM.settings.borderOnly then
        -- Cancel any existing flash timer
        if unitFrame.DotMasterBorderFlashTimer then
          unitFrame.DotMasterBorderFlashTimer:Cancel()
          unitFrame.DotMasterBorderFlashTimer = nil
        end

        -- Create new flash
        if unitFrame.healthBar.canHealthFlash then
          -- Use direct Plater API for border flash
          Plater.FlashNameplateBorder(unitFrame, 0.25)

          -- Set up ongoing flash
          unitFrame.DotMasterBorderFlashTimer = C_Timer.NewTicker(0.35, function()
            if unitFrame and unitFrame.healthBar and unitFrame:IsShown() then
              Plater.FlashNameplateBorder(unitFrame, 0.25)
            else
              -- If the unitFrame is gone or hidden, cancel the timer
              if unitFrame.DotMasterBorderFlashTimer then
                unitFrame.DotMasterBorderFlashTimer:Cancel()
                unitFrame.DotMasterBorderFlashTimer = nil
              end
            end
          end)
        end
      else
        -- For full nameplate mode
        -- Cancel any existing animation
        if unitFrame.DotMasterFlashAnimation then
          unitFrame.DotMasterFlashAnimation:Stop()
        end

        -- Get brightened color
        local r, g, b = color[1], color[2], color[3]
        local maxChannel = math.max(r, g, b)
        if maxChannel > 0 then
          r, g, b = r / maxChannel, g / maxChannel, b / maxChannel
        end

        -- Use Plater's built-in flash animation
        unitFrame.DotMasterFlashAnimation = Plater.CreateFlash(unitFrame.healthBar, 0.25, 3, r, g, b, 0.6)

        -- Hook into the OnPlay to ensure text stays visible
        if unitFrame.DotMasterFlashAnimation then
          -- Store original OnPlay function
          local originalOnPlay = unitFrame.DotMasterFlashAnimation.Anim_OnPlay

          -- Override with our own that preserves text elements
          unitFrame.DotMasterFlashAnimation.Anim_OnPlay = function(...)
            -- Call original first
            if originalOnPlay then
              originalOnPlay(...)
            end

            -- Then protect text elements
            if unitFrame.healthBar.unitName then
              unitFrame.healthBar.unitName:SetDrawLayer("OVERLAY", 7)
            end
            if unitFrame.healthBar.lifePercent then
              unitFrame.healthBar.lifePercent:SetDrawLayer("OVERLAY", 7)
            end
          end

          -- Start the animation
          unitFrame.DotMasterFlashAnimation:Play()
        end
      end
    end,

    Stop = function()
      if not unitFrame then return end

      -- Stop border flash timer
      if unitFrame.DotMasterBorderFlashTimer then
        unitFrame.DotMasterBorderFlashTimer:Cancel()
        unitFrame.DotMasterBorderFlashTimer = nil
      end

      -- Stop nameplate flash animation
      if unitFrame.DotMasterFlashAnimation then
        unitFrame.DotMasterFlashAnimation:Stop()
        unitFrame.DotMasterFlashAnimation = nil
      end

      -- Restore any text layers
      if unitFrame.healthBar and unitFrame.healthBar.unitName then
        unitFrame.healthBar.unitName:SetDrawLayer("OVERLAY", 6)
      end
      if unitFrame.healthBar and unitFrame.healthBar.lifePercent then
        unitFrame.healthBar.lifePercent:SetDrawLayer("OVERLAY", 6)
      end
    end
  }
end

-- Check for expiring DoTs and trigger flashes
function DM:CheckForExpiringDoTs(unitToken)
  if not unitToken or not DM.settings.flashExpiring then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
  if not nameplate or not nameplate.unitFrame then return end

  -- Get all active dots on this unit
  local activeDots = self:GetActiveDots(unitToken)
  if not activeDots or not next(activeDots) then
    -- If no dots found, stop any existing flash
    local unitFrame = nameplate.unitFrame
    if unitFrame.DotMasterBorderFlashing then
      if unitFrame.DotMasterBorderFlashTimer then
        unitFrame.DotMasterBorderFlashTimer:Cancel()
        unitFrame.DotMasterBorderFlashTimer = nil
      end
      unitFrame.DotMasterBorderFlashing = nil
    end

    if unitFrame.DotMasterFlash then
      unitFrame.DotMasterFlash:Stop()
      unitFrame.DotMasterFlash = nil
    end
    return
  end

  -- Find if any DoT is about to expire based on user threshold
  local expiringFound = false
  local expiringDoTName = nil
  local expiringDoTColor = nil
  local remainingTime = nil
  local now = GetTime()
  local threshold = DM.settings.flashThresholdSeconds or 3.0

  for spellID, dotInfo in pairs(activeDots) do
    remainingTime = dotInfo.expirationTime - now

    if remainingTime > 0 and remainingTime <= threshold then
      expiringFound = true
      expiringDoTName = dotInfo.name
      expiringDoTColor = dotInfo.color
      break
    end
  end

  local unitFrame = nameplate.unitFrame

  -- If there's an expiring DoT, flash
  if expiringFound then
    -- Check the flashing mode (border or full)
    if DM.settings.borderOnly then
      -- Border-only mode
      -- Set a flag to indicate we're already flashing the border
      unitFrame.DotMasterBorderFlashing = true

      -- Trigger an immediate border flash
      if unitFrame.healthBar and unitFrame.healthBar.canHealthFlash then
        -- First, flash using Plater's built-in function
        Plater.FlashNameplateBorder(unitFrame, 0.15)

        -- If we don't already have a flashing timer, create one
        if not unitFrame.DotMasterBorderFlashTimer then
          unitFrame.DotMasterBorderFlashTimer = C_Timer.NewTicker(0.3, function()
            -- Only flash if the frame still exists and is shown
            if unitFrame and unitFrame:IsShown() and unitFrame.healthBar and unitFrame.healthBar.canHealthFlash then
              Plater.FlashNameplateBorder(unitFrame, 0.15)
            else
              -- Clean up the timer if the frame is gone or hidden
              if unitFrame.DotMasterBorderFlashTimer then
                unitFrame.DotMasterBorderFlashTimer:Cancel()
                unitFrame.DotMasterBorderFlashTimer = nil
                unitFrame.DotMasterBorderFlashing = nil
              end
            end
          end)
        end
      end
    else
      -- Full nameplate mode
      -- If we don't have an animation yet, create one
      if not unitFrame.DotMasterFlash then
        -- Get color for the flash
        local r, g, b = expiringDoTColor[1], expiringDoTColor[2], expiringDoTColor[3]
        local maxChannel = math.max(r, g, b)
        if maxChannel > 0 then
          r, g, b = r / maxChannel, g / maxChannel, b / maxChannel
        end

        -- Create flash using Plater's API with proper settings
        unitFrame.DotMasterFlash = Plater.CreateFlash(unitFrame.healthBar, 0.25, 3, r, g, b, 0.6)
      end

      -- Play the animation
      if unitFrame.DotMasterFlash then
        unitFrame.DotMasterFlash:Play()
      end
    end
  else
    -- No expiring DoT, stop any flashing
    if DM.settings.borderOnly then
      -- Clean up border flash timer if it exists
      if unitFrame.DotMasterBorderFlashTimer then
        unitFrame.DotMasterBorderFlashTimer:Cancel()
        unitFrame.DotMasterBorderFlashTimer = nil
        unitFrame.DotMasterBorderFlashing = nil
      end
    else
      -- Stop full nameplate flashing
      if unitFrame.DotMasterFlash then
        unitFrame.DotMasterFlash:Stop()
        unitFrame.DotMasterFlash = nil
      end
    end
  end
end

-- Apply a color to a nameplate
function DM:ApplyColorToNameplate(nameplate, unitToken, color)
  if not nameplate or not color then return false end

  -- Check if Plater is available and handle it specially
  if _G["Plater"] then
    local Plater = _G["Plater"]
    local unitFrame = nameplate.unitFrame
    if unitFrame and unitFrame.healthBar then
      -- If Force Threat Color is enabled, check threat conditions
      if DM.settings and DM.settings.forceColor then
        -- Apply threat-based color if applicable
        if self:ApplyThreatColor(unitFrame, unitToken) then
          -- Tell DotMaster we're handling this nameplate
          self.coloredPlates[unitToken] = true
          return true
        end
      end

      -- Check for border-only mode
      if DM.settings and DM.settings.borderOnly then
        -- Apply color only to the border
        if self:SetNameplateBorderColor(unitFrame, color) then
          self.coloredPlates[unitToken] = true

          -- Create flash animation for this nameplate if needed
          if DM.settings.flashExpiring then
            self:CheckForExpiringDoTs(unitToken)

            -- Set up a repeating timer to check for expiring DoTs
            if not unitFrame.DotMasterCheckTimer then
              unitFrame.DotMasterCheckTimer = C_Timer.NewTicker(0.5, function()
                if nameplate and nameplate:IsShown() and unitFrame and unitFrame.healthBar then
                  self:CheckForExpiringDoTs(unitToken)
                else
                  -- Clean up timer if the nameplate is gone
                  if unitFrame.DotMasterCheckTimer then
                    unitFrame.DotMasterCheckTimer:Cancel()
                    unitFrame.DotMasterCheckTimer = nil
                  end
                end
              end)
            end
          end

          return true
        end
      else
        -- If not using border-only mode, use full nameplate coloring
        Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)

        -- These flags tell Plater not to change this nameplate's color
        unitFrame.UsingCustomColor = true
        unitFrame.DenyColorChange = true

        self.coloredPlates[unitToken] = true

        -- Create flash animation for this nameplate if needed
        if DM.settings.flashExpiring then
          self:CheckForExpiringDoTs(unitToken)

          -- Set up a repeating timer to check for expiring DoTs
          if not unitFrame.DotMasterCheckTimer then
            unitFrame.DotMasterCheckTimer = C_Timer.NewTicker(0.5, function()
              if nameplate and nameplate:IsShown() and unitFrame and unitFrame.healthBar then
                self:CheckForExpiringDoTs(unitToken)
              else
                -- Clean up timer if the nameplate is gone
                if unitFrame.DotMasterCheckTimer then
                  unitFrame.DotMasterCheckTimer:Cancel()
                  unitFrame.DotMasterCheckTimer = nil
                end
              end
            end)
          end
        end

        return true
      end
    else
      return false
    end
  else
    -- Standard nameplate (same as before)
    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if not healthBar then
      return false
    end

    -- Store original color first time if not already stored
    local unitToken = nameplate.namePlateUnitToken
    if unitToken and not DM.originalColors[unitToken] then
      local r, g, b = healthBar:GetStatusBarColor()
      DM.originalColors[unitToken] = { r, g, b }
    end

    -- Apply the new color
    DM.coloredPlates[unitToken] = true
    healthBar:SetStatusBarColor(unpack(color))
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

    -- Cancel any timers
    if unitFrame.DotMasterCheckTimer then
      unitFrame.DotMasterCheckTimer:Cancel()
      unitFrame.DotMasterCheckTimer = nil
    end

    -- Stop any border flash timer
    if unitFrame.DotMasterBorderFlashTimer then
      unitFrame.DotMasterBorderFlashTimer:Cancel()
      unitFrame.DotMasterBorderFlashTimer = nil
      unitFrame.DotMasterBorderFlashing = nil
    end

    -- Stop full nameplate flashing
    if unitFrame.DotMasterFlash then
      unitFrame.DotMasterFlash:Stop()
      unitFrame.DotMasterFlash = nil
    end

    -- If we were in border-only mode, restore default Plater border settings
    if DM.settings and DM.settings.borderOnly then
      -- Reset custom border color flag
      unitFrame.customBorderColor = nil

      -- Get the original border thickness if we stored it
      local borderThickness = 1 -- Fallback default
      if DM.originalBorderThickness and DM.originalBorderThickness[unitToken] then
        borderThickness = DM.originalBorderThickness[unitToken]
        -- Clear the stored value
        DM.originalBorderThickness[unitToken] = nil
      else
        -- Fallback to Plater's default border thickness from its DB
        borderThickness = Plater.db and Plater.db.profile and Plater.db.profile.border_thickness or 1
      end

      -- Reset border thickness to original
      if healthBar.border then
        healthBar.border:SetBorderSizes(borderThickness, borderThickness, borderThickness, borderThickness)
        healthBar.border:UpdateSizes()
      end

      -- Restore default border color
      Plater.UpdateBorderColor(unitFrame)
    else
      -- Reset Plater's color control flags
      unitFrame.UsingCustomColor = nil
      unitFrame.DenyColorChange = nil

      -- Reset the healthBar color variables
      healthBar.R, healthBar.G, healthBar.B, healthBar.A = nil, nil, nil, nil
    end

    -- Call Plater's color refresh function
    Plater.RefreshNameplateColor(unitFrame)

    -- Force Plater to update all plates
    if Plater.UpdateAllNameplateColors then
      Plater.UpdateAllNameplateColors()
    end

    -- Force a tick to update threat colors
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
