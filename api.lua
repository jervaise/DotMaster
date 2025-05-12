-- DotMaster api.lua
-- API layer that isolates the GUI from backend implementation

local DM = DotMaster
DM.API = {}

-- Helper function to create a deep copy of a table (in case CopyTable is not available)
local function DeepCopyTable(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[DeepCopyTable(orig_key)] = DeepCopyTable(orig_value)
    end
    setmetatable(copy, DeepCopyTable(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Version info
function DM.API:GetVersion()
  return "1.0.4"
end

-- Spell tracking functions
function DM.API:GetTrackedSpells()
  -- Return empty table to populate the Tracked Spells tab
  return {}
end

function DM.API:TrackSpell(spellID, spellName, spellIcon, color, priority)
  -- Stub for adding a spell to tracking
  return true
end

function DM.API:UntrackSpell(spellID)
  -- Stub for removing a spell from tracking
  return true
end

function DM.API:UpdateSpellSettings(spellID, enabled, priority, color)
  -- Stub for updating spell settings
  return true
end

-- Combination functions
function DM.API:GetCombinations()
  -- Return empty table to populate the Combinations tab
  return {}
end

function DM.API:CreateCombination(name, color)
  -- Stub for creating a new combination
  return "combo_" .. tostring(GetTime()) -- Return a fake ID
end

function DM.API:UpdateCombination(comboID, name, enabled, color)
  -- Stub for updating a combination
  return true
end

function DM.API:DeleteCombination(comboID)
  -- Stub for deleting a combination
  return true
end

function DM.API:AddSpellToCombination(comboID, spellID, priority)
  -- Stub for adding a spell to a combination
  return true
end

function DM.API:RemoveSpellFromCombination(comboID, spellID)
  -- Stub for removing a spell from a combination
  return true
end

-- Spell database functions
function DM.API:GetSpellDatabase()
  -- Return empty table to populate the Database tab
  return {}
end

function DM.API:AddSpellToDatabase(spellID, spellName, spellIcon, class, spec)
  -- Stub for adding a spell to the database
  return true
end

function DM.API:RemoveSpellFromDatabase(spellID)
  -- Stub for removing a spell from the database
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
  return true
end

function DM.API:EnableAddon(enabled)
  -- Stub for enabling/disabling the addon
  return true
end

-- Spell handling utilities
function DM.API:GetSpellInfo(spellID)
  -- Use WoW's GetSpellInfo for real spell data
  return GetSpellInfo(spellID)
end

function DM.API:SpellExists(spellID)
  -- Stub to check if a spell exists in our database
  return false
end

-- Add these functions to support color picker and spell selection

-- Show color picker (stub)
function DM:ShowColorPicker(r, g, b, callback)
  -- Use the built-in color picker directly for now
  local function colorFunc()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    callback(r, g, b)
  end

  local function cancelFunc()
    local prevR, prevG, prevB = unpack(ColorPickerFrame.previousValues)
    callback(prevR, prevG, prevB)
  end

  ColorPickerFrame.func = colorFunc
  ColorPickerFrame.cancelFunc = cancelFunc
  ColorPickerFrame.previousValues = { r, g, b }
  ColorPickerFrame:SetColorRGB(r, g, b)
  ColorPickerFrame:Show()
end

-- Show spell selection (stub)
function DM:ShowSpellSelection(parent, callback)
  DM:PrintMessage("Spell selection is not available in this version")

  -- Return a valid default if needed
  if callback then
    callback(0, "Unknown Spell", "Interface\\Icons\\INV_Misc_QuestionMark")
  end
end
