--[[
  DotMaster - Spell Utilities Module

  File: sp_utils.lua
  Purpose: Spell utility functions

  Functions:
  - GetSpellName(): Get spell name from ID
  - GetSpellColor(): Get color for a spell

  Dependencies:
  - dm_core.lua
  - sp_database.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local SpellUtils = {}      -- Local table for module functions
DM.SpellUtils = SpellUtils -- Expose to addon namespace

-- Get spell name from ID
function DM:GetSpellName(spellID)
  if not spellID then return "Unknown" end

  local numericID = tonumber(spellID)
  if not numericID then return "Unknown" end

  -- First check our local database
  if DM.SpellNames[numericID] then
    return DM.SpellNames[numericID]
  end

  -- If not in local database, try the API
  local name
  if C_Spell and C_Spell.GetSpellInfo then
    name = C_Spell.GetSpellInfo(numericID)
  end

  if name then
    -- If successful, add to database
    DM.SpellNames[numericID] = name
    return name
  end

  -- If all else fails
  return "Spell #" .. numericID
end

-- Get color for a spell
function SpellUtils:GetSpellColor(spellID)
  if not spellID then return DM.DEFAULT_PURPLE_COLOR end

  local spellConfig = DM.spellConfig[tostring(spellID)]
  if spellConfig and spellConfig.color then
    return spellConfig.color
  end

  return DM.DEFAULT_PURPLE_COLOR
end

-- Debug message function with module name
function SpellUtils:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[SpellUtils] " .. message)
  end
end

-- Initialize the spell utils module
function SpellUtils:Initialize()
  SpellUtils:DebugMsg("Spell utilities module initialized")
end

-- Return the module
return SpellUtils
