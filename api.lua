-- DotMaster api.lua
-- API layer that isolates the GUI from backend implementation

local DM = DotMaster
DM.API = {}

-- Version info
function DM.API:GetVersion()
  return "1.0.3"
end

-- Spell tracking functions
function DM.API:GetTrackedSpells()
  -- Return empty table to populate the Tracked Spells tab
  return {}
end

function DM.API:TrackSpell(spellID, spellName, spellIcon, color, priority)
  -- Stub for adding a spell to tracking
  DM:DebugMsg("API: TrackSpell called with ID " .. tostring(spellID))
  return true
end

function DM.API:UntrackSpell(spellID)
  -- Stub for removing a spell from tracking
  DM:DebugMsg("API: UntrackSpell called with ID " .. tostring(spellID))
  return true
end

function DM.API:UpdateSpellSettings(spellID, enabled, priority, color)
  -- Stub for updating spell settings
  DM:DebugMsg("API: UpdateSpellSettings called for " .. tostring(spellID))
  return true
end

-- Combination functions
function DM.API:GetCombinations()
  -- Return empty table to populate the Combinations tab
  return {}
end

function DM.API:CreateCombination(name, color)
  -- Stub for creating a new combination
  DM:DebugMsg("API: CreateCombination called: " .. tostring(name))
  return "combo_" .. tostring(GetTime()) -- Return a fake ID
end

function DM.API:UpdateCombination(comboID, name, enabled, color)
  -- Stub for updating a combination
  DM:DebugMsg("API: UpdateCombination called for " .. tostring(comboID))
  return true
end

function DM.API:DeleteCombination(comboID)
  -- Stub for deleting a combination
  DM:DebugMsg("API: DeleteCombination called for " .. tostring(comboID))
  return true
end

function DM.API:AddSpellToCombination(comboID, spellID, priority)
  -- Stub for adding a spell to a combination
  DM:DebugMsg("API: AddSpellToCombination called")
  return true
end

function DM.API:RemoveSpellFromCombination(comboID, spellID)
  -- Stub for removing a spell from a combination
  DM:DebugMsg("API: RemoveSpellFromCombination called")
  return true
end

-- Spell database functions
function DM.API:GetSpellDatabase()
  -- Return empty table to populate the Database tab
  return {}
end

function DM.API:AddSpellToDatabase(spellID, spellName, spellIcon, class, spec)
  -- Stub for adding a spell to the database
  DM:DebugMsg("API: AddSpellToDatabase called for " .. tostring(spellID))
  return true
end

function DM.API:RemoveSpellFromDatabase(spellID)
  -- Stub for removing a spell from the database
  DM:DebugMsg("API: RemoveSpellFromDatabase called for " .. tostring(spellID))
  return true
end

-- Settings functions
function DM.API:GetSettings()
  -- Return default settings to populate the General tab
  return {
    enabled = true,
    forceColor = false,
    borderOnly = false,
    borderThickness = 2,
    flashExpiring = false,
    flashThresholdSeconds = 3.0,
    minimapIcon = {
      hide = false
    }
  }
end

function DM.API:SaveSettings(settings)
  -- Stub for saving settings
  DM:DebugMsg("API: SaveSettings called")
  return true
end

function DM.API:EnableAddon(enabled)
  -- Stub for enabling/disabling the addon
  DM:DebugMsg("API: EnableAddon called: " .. tostring(enabled))
  return true
end

-- Spell handling utilities
function DM.API:GetSpellInfo(spellID)
  -- Use WoW's GetSpellInfo for real spell data
  return GetSpellInfo(spellID)
end

function DM.API:SpellExists(spellID)
  -- Stub to check if a spell exists in our database
  DM:DebugMsg("API: SpellExists called for " .. tostring(spellID))
  return false
end

-- Debug APIs
function DM.API:GetDebugSettings()
  return {
    categories = {
      general = true,
      database = true
    },
    consoleOutput = false
  }
end

function DM.API:SaveDebugSettings(debugSettings)
  DM:DebugMsg("API: SaveDebugSettings called")
  return true
end
