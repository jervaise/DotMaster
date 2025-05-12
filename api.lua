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
  local spells = {}
  -- Use the tracked spells database
  for id, entry in pairs(DotMaster.dmspellsdb or {}) do
    if entry.enabled and entry.enabled ~= 0 then
      table.insert(spells, {
        spellID = tonumber(id),
        color = entry.color,
        priority = entry.priority,
        name = entry.spellname,
      })
    end
  end
  return spells
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
  local combos = {}
  -- Use the combinations database
  if DotMaster.combinations and DotMaster.combinations.data then
    for id, combo in pairs(DotMaster.combinations.data) do
      if combo.enabled then
        table.insert(combos, {
          comboID = id,
          spellList = combo.spells,
          color = combo.color,
          priority = combo.priority,
          name = combo.name,
        })
      end
    end
  end
  return combos
end

function DM.API:CreateCombination(name, color, spells)
  -- Try to use the backend implementation
  if DM.CreateCombination then
    return DM:CreateCombination(name, spells or {}, color)
  end

  -- Fallback implementation if the backend function is not available
  -- This implements the full functionality directly in the API layer

  -- Ensure DotMasterDB and combinations structure exist
  if not DotMasterDB then DotMasterDB = {} end
  if not DotMasterDB.combinations then
    DotMasterDB.combinations = {
      settings = { enabled = true, priorityOverIndividual = true },
      data = {}
    }
  end
  if not DotMasterDB.combinations.data then DotMasterDB.combinations.data = {} end

  -- Create a reference in the addon table
  DM.combinations = DotMasterDB.combinations

  -- Generate a unique ID using timestamp
  local id = "combo_" .. time()

  -- Find the highest priority and increment by 1
  local priority = 1
  if DM.combinations.data then
    for _, combo in pairs(DM.combinations.data) do
      if combo and combo.priority and combo.priority >= priority then
        priority = combo.priority + 1
      end
    end
  end

  -- Create the new combination
  DM.combinations.data[id] = {
    name = name or "New Combination",
    spells = spells or {},
    color = color or { r = 1, g = 0, b = 0, a = 1 },
    priority = priority,
    enabled = true,
    threshold = "all", -- "all" or numeric value
    isExpanded = false -- ALWAYS start collapsed
  }

  -- Save changes to DotMasterDB
  DotMasterDB.combinations = DM.combinations

  -- Debug message if available
  if DM.DebugMsg then
    DM:DebugMsg("API Layer: Created new combination with ID: " .. id)
  end

  return id
end

function DM.API:UpdateCombination(comboID, name, enabled, color)
  -- Try to use the backend implementation if it exists
  if DM.UpdateCombination then
    -- Convert parameters to an updates table as expected by the backend
    local updates = {
      name = name,
      enabled = enabled,
      color = color
    }
    return DM:UpdateCombination(comboID, updates)
  end

  -- Fallback implementation if backend function is not available

  -- Ensure combinations data structure exists
  if not DM.combinations or not DM.combinations.data then
    return false
  end

  if not comboID or not DM.combinations.data[comboID] then
    if DM.DebugMsg then
      DM:DebugMsg("API Layer: Cannot update combination - ID not found: " .. tostring(comboID))
    end
    return false
  end

  -- Apply updates
  if name ~= nil then DM.combinations.data[comboID].name = name end
  if enabled ~= nil then DM.combinations.data[comboID].enabled = enabled end
  if color ~= nil then DM.combinations.data[comboID].color = color end

  -- Save changes to DotMasterDB
  if DotMasterDB then
    DotMasterDB.combinations = DM.combinations
  end

  -- Debug message if available
  if DM.DebugMsg then
    DM:DebugMsg("API Layer: Updated combination with ID: " .. comboID)
  end

  return true
end

function DM.API:DeleteCombination(comboID)
  -- Try to use the backend implementation
  if DM.DeleteCombination then
    return DM:DeleteCombination(comboID)
  end

  -- Fallback implementation if backend function is not available

  -- Ensure combinations data structure exists
  if not DM.combinations or not DM.combinations.data then
    return false
  end

  if not comboID or not DM.combinations.data[comboID] then
    if DM.DebugMsg then
      DM:DebugMsg("API Layer: Cannot delete combination - ID not found: " .. tostring(comboID))
    end
    return false
  end

  -- Remove the combination
  DM.combinations.data[comboID] = nil

  -- Save changes to DotMasterDB
  if DotMasterDB then
    DotMasterDB.combinations = DM.combinations
  end

  -- Debug message if available
  if DM.DebugMsg then
    DM:DebugMsg("API Layer: Deleted combination with ID: " .. comboID)
  end

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
