-- DotMaster api.lua
-- Provides a clean API contract between the GUI and backend systems

-- Reference to main addon
local DM = DotMaster
local API = {}
DM.API = API

-- API Methods ---------------------------------------------

-- Get addon settings
function API:GetSettings()
  if DM.Debug then
    DM.Debug:Database("API:GetSettings() called")
  end

  -- Return settings from core
  return DM.db or {}
end

-- Save addon settings
function API:SaveSettings(settings)
  if DM.Debug then
    DM.Debug:Database("API:SaveSettings() called")
  end

  -- Pass to core
  DM.db = settings
end

-- Get all tracked spells
function API:GetTrackedSpells()
  if DM.Debug then
    DM.Debug:Database("API:GetTrackedSpells() called")
  end

  -- Get spells from settings
  local db = self:GetSettings()
  if not db.trackedSpells then
    db.trackedSpells = {}
  end

  return db.trackedSpells
end

-- Start tracking a new spell
function API:TrackSpell(spellID, spellName, spellIcon, color, priority)
  if DM.Debug then
    DM.Debug:Database("API:TrackSpell(%d, %s, _, _, %d) called", spellID, spellName, priority)
  end

  -- Validate inputs
  if not spellID or not spellName or not spellIcon then
    if DM.Debug then
      DM.Debug:Error("API:TrackSpell() called with invalid parameters")
    end
    return false
  end

  -- Get tracked spells
  local trackedSpells = self:GetTrackedSpells()

  -- Check if spell is already tracked
  for _, spell in pairs(trackedSpells) do
    if spell.id == spellID then
      -- Update existing spell
      spell.name = spellName
      spell.icon = spellIcon
      if color then spell.color = color end
      if priority then spell.priority = priority end

      if DM.Debug then
        DM.Debug:Database("Updated existing spell: %s (%d)", spellName, spellID)
      end
      return true
    end
  end

  -- Add new spell
  local spell = {
    id = spellID,
    name = spellName,
    icon = spellIcon,
    color = color or { r = 1, g = 0, b = 0, a = 1 },
    priority = priority or 0,
    enabled = true
  }

  table.insert(trackedSpells, spell)

  if DM.Debug then
    DM.Debug:Database("Added new spell: %s (%d)", spellName, spellID)
  end
  return true
end

-- Stop tracking a spell
function API:UntrackSpell(spellID)
  if DM.Debug then
    DM.Debug:Database("API:UntrackSpell(%d) called", spellID)
  end

  -- Validate input
  if not spellID then
    if DM.Debug then
      DM.Debug:Error("API:UntrackSpell() called with invalid parameter")
    end
    return false
  end

  -- Get tracked spells
  local trackedSpells = self:GetTrackedSpells()

  -- Find and remove spell
  for i, spell in ipairs(trackedSpells) do
    if spell.id == spellID then
      table.remove(trackedSpells, i)
      if DM.Debug then
        DM.Debug:Database("Removed spell with ID: %d", spellID)
      end
      return true
    end
  end

  if DM.Debug then
    DM.Debug:Database("Spell not found: %d", spellID)
  end
  return false
end

-- Update a tracked spell's properties
function API:UpdateSpell(spellID, properties)
  if DM.Debug then
    DM.Debug:Database("API:UpdateSpell(%d, properties) called", spellID)
  end

  -- Validate inputs
  if not spellID or not properties then
    if DM.Debug then
      DM.Debug:Error("API:UpdateSpell() called with invalid parameters")
    end
    return false
  end

  -- Get tracked spells
  local trackedSpells = self:GetTrackedSpells()

  -- Find and update spell
  for _, spell in ipairs(trackedSpells) do
    if spell.id == spellID then
      -- Update properties
      for k, v in pairs(properties) do
        spell[k] = v
      end

      if DM.Debug then
        DM.Debug:Database("Updated spell %d properties", spellID)
      end
      return true
    end
  end

  if DM.Debug then
    DM.Debug:Database("Spell not found for update: %d", spellID)
  end
  return false
end

-- Get all combinations
function API:GetCombinations()
  if DM.Debug then
    DM.Debug:Database("API:GetCombinations() called")
  end

  -- Get combinations from settings
  local db = self:GetSettings()
  if not db.combinations then
    db.combinations = {}
  end

  return db.combinations
end

-- Create a new combination
function API:CreateCombination(name, spellIDs, color)
  if DM.Debug then
    DM.Debug:Database("API:CreateCombination(%s, spellIDs, color) called", name)
  end

  -- Validate inputs
  if not name or not spellIDs or #spellIDs == 0 then
    if DM.Debug then
      DM.Debug:Error("API:CreateCombination() called with invalid parameters")
    end
    return false
  end

  -- Get combinations
  local combinations = self:GetCombinations()

  -- Create new combination
  local combination = {
    name = name,
    spellIDs = spellIDs,
    color = color or { r = 1, g = 1, b = 0, a = 1 },
    enabled = true
  }

  table.insert(combinations, combination)

  if DM.Debug then
    DM.Debug:Database("Created new combination: %s with %d spells", name, #spellIDs)
  end
  return true
end

-- Get a combination by name
function API:GetCombinationByName(name)
  if DM.Debug then
    DM.Debug:Database("API:GetCombinationByName(%s) called", name)
  end

  -- Validate input
  if not name then
    if DM.Debug then
      DM.Debug:Error("API:GetCombinationByName() called with invalid parameter")
    end
    return nil
  end

  -- Get combinations
  local combinations = self:GetCombinations()

  -- Find combination by name
  for _, combination in ipairs(combinations) do
    if combination.name == name then
      return combination
    end
  end

  return nil
end

-- Delete a combination by name
function API:DeleteCombination(name)
  if DM.Debug then
    DM.Debug:Database("API:DeleteCombination(%s) called", name)
  end

  -- Validate input
  if not name then
    if DM.Debug then
      DM.Debug:Error("API:DeleteCombination() called with invalid parameter")
    end
    return false
  end

  -- Get combinations
  local combinations = self:GetCombinations()

  -- Find and remove combination
  for i, combination in ipairs(combinations) do
    if combination.name == name then
      table.remove(combinations, i)
      if DM.Debug then
        DM.Debug:Database("Deleted combination: %s", name)
      end
      return true
    end
  end

  if DM.Debug then
    DM.Debug:Database("Combination not found: %s", name)
  end
  return false
end

-- Enable/disable the addon
function API:EnableAddon(enabled)
  if DM.Debug then
    DM.Debug:General("API:EnableAddon(%s) called", tostring(enabled))
  end

  -- Get settings
  local settings = self:GetSettings()

  -- Update enabled state
  settings.enabled = enabled

  -- Apply changes
  self:SaveSettings(settings)

  -- Update display
  if enabled then
    if DM.EnableNameplateHook then
      DM:EnableNameplateHook()
    end
  else
    if DM.DisableNameplateHook then
      DM:DisableNameplateHook()
    end
  end

  return true
end

-- Return the API module
return API
