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

-- Specialized debug function for Plater integration
function DM:PlaterDebug(message)
  if DM.DEBUG_MODE then
    DM:PrintMessage("[Plater Integration] " .. message)
  end
end

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

-- Template for the Plater script that will handle DoT tracking
DM.API.PLATER_SCRIPT_TEMPLATE = {
  Name = "DotMaster DoT Tracker",
  Icon = "Interface\\ICONS\\Ability_Rogue_RuptureTN",
  Desc = "Tracks DoTs on nameplates",
  Author = "DotMaster",
  Time = time(),
  Enabled = true,

  -- These are the required script sections
  OnInit = [[function(scriptTable)
    -- Do minimal initialization
  end]],

  OnUpdate = [[function(self, unitId, unitFrame, envTable, scriptTable)
    -- Empty update function
  end]],

  -- Required structure elements
  SpellIds = {},
  Hooks = {},
  Options = {},
  version = 1
}

-- Function to inject or update the DotMaster script in Plater
function DM.API:InjectPlaterScript()
  -- Safety check - ensure Plater exists
  if not Plater then
    DM:PrintMessage("Error: Plater is not loaded or installed!")
    return false
  end

  DM:PrintMessage("Adding DotMaster script to Plater...")

  -- Create a copy of our template
  local script = DeepCopyTable(DM.API.PLATER_SCRIPT_TEMPLATE)

  -- Ensure Plater.db is populated
  if not Plater.db or not Plater.db.profile or not Plater.db.profile.script_data then
    DM:PrintMessage("Error: Plater database is not ready!")
    return false
  end

  -- Check if our script already exists
  local exists = false
  for i, existingScript in ipairs(Plater.db.profile.script_data) do
    if existingScript and existingScript.Name == script.Name then
      -- Update existing script
      script.Enabled = existingScript.Enabled -- Preserve enabled state
      Plater.db.profile.script_data[i] = script
      exists = true
      DM:PrintMessage("Updated existing DotMaster script")
      break
    end
  end

  -- If script doesn't exist, add it
  if not exists then
    table.insert(Plater.db.profile.script_data, script)
    DM:PrintMessage("Added new DotMaster script to Plater")
  end

  -- Try to refresh Plater scripts
  if Plater.RefreshDBUpvalues then
    Plater.RefreshDBUpvalues()
  end

  -- Let Plater know scripting was modified
  if Plater.ScriptingIsEnabled then
    Plater.ScriptingIsEnabled = true
  end

  -- Don't try to force recompile immediately as it can cause errors
  -- Plater will handle this on its own

  return true
end
