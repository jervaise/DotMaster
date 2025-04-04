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

-- Process a single unit for DoT tracking and nameplate coloring
function DM:ProcessDotsForUnit(unit)
  if not unit or not self:ShouldProcessNameplates() then return end

  local unitName = UnitName(unit)
  if not unitName then return end

  DM:NameplateDebug("Processing DoTs for unit: %s", unitName)

  -- Find all active DoTs on this unit
  local activeDots = self:GetActiveDots(unit)
  if not activeDots or not next(activeDots) then
    -- If we were previously tracking this unit but now it has no DoTs,
    -- we need to reset its color
    self:ResetNameplate(unit)
    return
  end

  -- Find the best color to use based on priority rules
  local bestColor, bestSpellName, bestSpellID = self:GetBestColorForUnit(unit, activeDots)

  if bestColor then
    DM:NameplateDebug("Best color found for %s: %d/%d/%d (from %s)",
      unitName, bestColor[1] * 255, bestColor[2] * 255, bestColor[3] * 255, bestSpellName)

    -- Find the nameplate for this unit
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate then
      -- Apply the color to the nameplate
      self:ApplyColorToNameplate(nameplate, unit, bestColor)
    else
      DM:NameplateDebug("Could not find nameplate for unit: %s", unitName)
    end
  else
    DM:NameplateDebug("No DoT color priority found for %s", unitName)

    -- Reset the nameplate to its original color if we've colored it before
    self:ResetNameplate(unit)
  end

  -- Check for expiring DoTs regardless of whether we found a best color
  -- This ensures we handle flashing animations properly
  if DM.settings.flashExpiring then
    self:CheckForExpiringDoTs(unit)
  end
end

-- Runs a specific hook from a Plater script if it exists
function DM:RunPlaterScriptHook(modName, hookName, unitId, unitFrame, modTable)
  if not self.compiledScripts or not self.compiledScripts[modName] or not self.compiledScripts[modName][hookName] then
    --DM:DebugMsg("Hook '%s' not found or not compiled for mod '%s'", hookName, modName)
    return
  end

  -- Ensure necessary components are available
  if not self.ErrorHandler then
    DM:DebugMsg("Error handler not available, cannot run Plater script hook.")
    return
  end

  -- Create env table
  local env = {
    isFTCEnabled = DM.settings and DM.settings.forceColor or false,
    -- other env variables if needed
  }

  -- Execute the script for the current hook
  local func = self.compiledScripts[modName][hookName]
  if func then
    -- Pass env table to the script
    local success, err = xpcall(func, self.ErrorHandler, modTable, unitId, unitFrame, env, modTable)
    if not success then
      DM:DebugMsg("Error executing Plater script '%s' hook '%s': %s", modName, hookName, tostring(err))
    end
  else
    -- This case should technically be caught by the check at the top,
    -- but added for extra safety.
    DM:DebugMsg("Cannot run hook '%s': Compiled script function is nil for mod '%s'", hookName, modName)
  end
end
