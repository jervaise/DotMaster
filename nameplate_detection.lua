-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

-- Function to get the player's current class
local function GetPlayerClass()
  local _, class = UnitClass("player")
  return class
end

-- Helper function to check if a specific DoT is on a unit
function DM:HasPlayerDotOnUnit(unitToken, spellID)
  if not unitToken or not UnitExists(unitToken) or not spellID then return false end

  DM:NameplateDebug("HasPlayerDotOnUnit called: %s, SpellID: %d", unitToken, spellID)

  -- Check if we can use the C_UnitAuras API (newer clients)
  if C_UnitAuras and C_UnitAuras.GetAuraDataByUnit then
    -- Get all auras on the unit and check for our spell
    local auras = C_UnitAuras.GetAuraDataByUnit(unitToken, "HARMFUL")
    if auras then
      for _, auraData in ipairs(auras) do
        if auraData.spellId == spellID and auraData.sourceUnit == "player" then
          return true
        end
      end
    end
  elseif AuraUtil and AuraUtil.ForEachAura then
    -- Use AuraUtil.ForEachAura which works on all client versions
    local found = false
    AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(name, _, _, _, _, _, caster, _, _, id)
      if id == spellID and caster == "player" then
        found = true
        return true -- Stop iteration
      end
    end)

    if found then
      return true
    end
  else
    -- Fallback to UnitAura for legacy support
    local success, result = pcall(function()
      for i = 1, 40 do
        local name, _, _, _, _, _, source, _, _, auraSpellID = UnitAura(unitToken, i, "HARMFUL")
        if not name then break end

        if auraSpellID == spellID and source == "player" then
          return true
        end
      end
      return false
    end)

    if success and result then
      return true
    end
  end

  return false
end

-- Checks for tracked debuffs on a unit
function DM:CheckForTrackedDebuffs(unitToken)
  if not unitToken or not UnitExists(unitToken) then return nil end

  DM:NameplateDebug("CheckForTrackedDebuffs called: %s", unitToken)

  -- First, check for combinations if the feature is enabled
  if DM.combinations and DM.combinations.settings.enabled then
    local comboID, comboData = self:CheckCombinationsOnUnit(unitToken)

    if comboID and comboData and comboData.color then
      DM:NameplateDebug("Found active combination: %s", comboData.name or comboID)

      -- Format the color to work with the nameplate system
      local comboColor = {
        comboData.color.r or comboData.color[1] or 1,
        comboData.color.g or comboData.color[2] or 0,
        comboData.color.b or comboData.color[3] or 0
      }

      return "combo_" .. comboID, comboColor
    end
  end

  -- If no spell database is present, early return
  if not self.dmspellsdb or not next(self.dmspellsdb) then return nil end

  -- Get current player class
  local playerClass = GetPlayerClass()

  -- Check each spell config in priority order (if available)
  local sortedConfigs = {}
  for spellID, config in pairs(self.dmspellsdb) do
    -- Only include spells that are:
    -- 1. Enabled (for nameplate coloring)
    -- 2. Tracked (for display)
    -- 3. Belong to the player's current class
    if config.enabled == 1 and
        config.tracked == 1 and
        config.wowclass == playerClass then
      table.insert(sortedConfigs, { id = spellID, priority = config.priority or 999, config = config })
      DM:NameplateDebug("Added spell to check list: %d (%s) for class %s",
        spellID, config.spellname or "Unknown", playerClass)
    end
  end

  -- If no applicable spells found, return early
  if #sortedConfigs == 0 then
    DM:NameplateDebug("No matching spells found for player class: %s", playerClass)
    return nil
  end

  -- Sort by priority (lower numbers = higher priority)
  table.sort(sortedConfigs, function(a, b) return (a.priority or 999) < (b.priority or 999) end)

  -- Check each spell in priority order
  for _, entry in ipairs(sortedConfigs) do
    local spellID = entry.id
    local config = entry.config

    DM:NameplateDebug("Checking SpellID: %d, Priority: %s", spellID, tostring(config.priority or "none"))

    -- Check if the spell is active using our helper function
    if self:HasPlayerDotOnUnit(unitToken, spellID) then
      DM:NameplateDebug("Found debuff: %d", spellID)
      return spellID, config.color
    end
  end

  DM:NameplateDebug("No tracked debuffs found")
  return nil
end
