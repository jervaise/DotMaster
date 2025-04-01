--[[
  DotMaster - Nameplate Detection Module

  File: np_detection.lua
  Purpose: Functions for detecting and scanning nameplates

  Functions:
  - CheckForTrackedDebuffs(): Check for tracked debuffs on a unit

  Dependencies:
  - dm_core.lua
  - sp_database.lua
  - sp_utils.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local NPDetection = {}       -- Local table for module functions
DM.NPDetection = NPDetection -- Expose to addon namespace

-- Check for tracked debuffs on a unit - supports multiple comma-separated IDs
function DM:CheckForTrackedDebuffs(unitToken)
  DM:SpellDebug("CheckForTrackedDebuffs called: %s", unitToken)

  -- Create a sorted list of spell IDs by priority
  local spellList = {}
  for spellIDString, config in pairs(self.spellConfig) do
    if config.enabled then
      table.insert(spellList, { id = spellIDString, priority = config.priority or 999, config = config })
    end
  end

  -- Sort by priority
  table.sort(spellList, function(a, b)
    return (a.priority or 999) < (b.priority or 999)
  end)

  -- Check user configured spells in priority order
  for _, spellData in ipairs(spellList) do
    local spellIDString = spellData.id
    local config = spellData.config

    DM:SpellDebug("Checking SpellID: %s, Priority: %s", tostring(spellIDString), tostring(config.priority or "none"))

    -- Convert spellIDString to a numeric ID
    local spellID = tonumber(spellIDString)
    if not spellID then
      DM:SpellDebug("Invalid spell ID: %s", tostring(spellIDString))
      return nil, nil
    end

    DM:SpellDebug("Checking spell: %d", spellID)

    -- Check if the debuff is present
    local debuffPresent = false

    -- Use AuraUtil.ForEachAura instead of C_UnitAuras API
    AuraUtil.ForEachAura(unitToken, "HARMFUL", nil,
      function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal,
               auraSpellId)
        DM:SpellDebug("Aura found: %d, Source: %s", auraSpellId, tostring(source))

        -- Check spell ID and source - only accept player-sourced spells
        if auraSpellId == spellID and source == "player" then
          debuffPresent = true
          DM:SpellDebug("Aura matched and is from player!")
          return true -- Exit the loop
        end

        return false -- Continue iterating
      end)

    if debuffPresent then
      DM:SpellDebug("Debuff present, returning color: %s", tostring(spellIDString))
      return spellIDString, config.color
    end
  end

  DM:SpellDebug("No tracked debuffs found")
  return nil, nil
end

-- Update nameplate auras using event data
function NPDetection:UpdateNameplateAuras(unitToken)
  if not unitToken or not DM.enabled then return end

  -- Check if this is a nameplate unit and if we're tracking it
  if not unitToken:match("nameplate%d+") or not DM.activePlates[unitToken] then
    return
  end

  -- Update the nameplate
  DM:UpdateNameplate(unitToken)
end

-- Debug message function with module name
function NPDetection:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[NPDetection] " .. message)
  end
end

-- Initialize the nameplate detection module
function NPDetection:Initialize()
  NPDetection:DebugMsg("Nameplate detection module initialized")
end

-- Return the module
return NPDetection
