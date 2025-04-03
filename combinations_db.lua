-- DotMaster combinations_db.lua
-- Database structure and functions for DoT combinations

local DM = DotMaster

-- Default combinations database structure
DM.defaultCombinations = {
  -- Settings for the combinations feature
  settings = {
    enabled = true,                -- Master toggle for combinations feature
    priorityOverIndividual = true, -- Do combinations override individual spells?
  },

  -- Actual combinations data
  data = {}
}

-- Initialize combinations database
function DM:InitializeCombinationsDB()
  DM:DebugMsg("Initializing combinations database")

  -- Create combinations namespace if it doesn't exist
  if not DotMasterDB.combinations then
    DotMasterDB.combinations = DM.DeepCopy(DM.defaultCombinations)
    DM:DebugMsg("Created new combinations database structure")
  end

  -- Ensure all required fields exist (for version upgrades)
  if not DotMasterDB.combinations.settings then
    DotMasterDB.combinations.settings = DM.DeepCopy(DM.defaultCombinations.settings)
    DM:DebugMsg("Added missing settings to combinations database")
  end

  if not DotMasterDB.combinations.data then
    DotMasterDB.combinations.data = {}
    DM:DebugMsg("Added missing data table to combinations database")
  end

  -- Store reference for easier access
  DM.combinations = DotMasterDB.combinations

  DM:DebugMsg("Combinations database initialized with " .. DM:TableCount(DM.combinations.data) .. " combinations")
end

-- Save combinations database
function DM:SaveCombinationsDB()
  if not DotMasterDB then
    DM:DebugMsg("ERROR: Cannot save combinations - DotMasterDB not initialized")
    return
  end

  -- Ensure the combinations entry exists
  DotMasterDB.combinations = DM.combinations
  DM:DebugMsg("Combinations database saved with " .. DM:TableCount(DM.combinations.data) .. " combinations")
end

-- Create a new combination
function DM:CreateCombination(name, spells, color)
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot create combination - database not initialized")
    return nil
  end

  -- Generate a unique ID using timestamp
  local id = "combo_" .. time()

  -- Find the highest priority and increment by 1
  local priority = 1
  for _, combo in pairs(DM.combinations.data) do
    if combo.priority and combo.priority >= priority then
      priority = combo.priority + 1
    end
  end

  -- Create the new combination
  DM.combinations.data[id] = {
    name = name or "New Combination",
    spells = spells or {},
    color = color or { r = 1, g = 0, b = 0, a = 1 },
    priority = priority,
    enabled = true,
    threshold = "all" -- "all" or numeric value
  }

  -- Save changes
  DM:SaveCombinationsDB()

  return id
end

-- Delete a combination
function DM:DeleteCombination(id)
  if not DM.combinations or not DM.combinations.data[id] then
    DM:DebugMsg("ERROR: Cannot delete combination - ID not found: " .. tostring(id))
    return false
  end

  -- Remove the combination
  DM.combinations.data[id] = nil

  -- Save changes
  DM:SaveCombinationsDB()

  return true
end

-- Update an existing combination
function DM:UpdateCombination(id, updates)
  if not DM.combinations or not DM.combinations.data[id] then
    DM:DebugMsg("ERROR: Cannot update combination - ID not found: " .. tostring(id))
    return false
  end

  -- Apply updates
  for key, value in pairs(updates) do
    DM.combinations.data[id][key] = value
  end

  -- Save changes
  DM:SaveCombinationsDB()

  return true
end

-- Update combination priorities
function DM:UpdateCombinationPriorities(priorityTable)
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot update priorities - database not initialized")
    return false
  end

  -- Apply the new priorities
  for id, priority in pairs(priorityTable) do
    if DM.combinations.data[id] then
      DM.combinations.data[id].priority = priority
    end
  end

  -- Save changes
  DM:SaveCombinationsDB()

  return true
end

-- Check if a unit has a combination active
function DM:CheckCombinationsOnUnit(unit)
  if not DM.combinations or not DM.combinations.settings.enabled then
    return nil
  end

  local activeCombo = nil
  local highestPriority = 999999

  -- Sort combinations by priority
  local sortedCombos = {}
  for id, combo in pairs(DM.combinations.data) do
    if combo.enabled then
      table.insert(sortedCombos, { id = id, priority = combo.priority or 999, data = combo })
    end
  end

  table.sort(sortedCombos, function(a, b) return a.priority < b.priority end)

  -- Check each combination
  for _, comboInfo in ipairs(sortedCombos) do
    local combo = comboInfo.data
    local required = combo.threshold == "all" and #combo.spells or tonumber(combo.threshold) or #combo.spells
    local count = 0

    -- Check how many spells from this combination are active
    for _, spellID in ipairs(combo.spells) do
      if DM:HasPlayerDotOnUnit(unit, spellID) then
        count = count + 1
      end
    end

    -- If we have enough active spells, use this combination
    if count >= required then
      activeCombo = comboInfo
      break
    end
  end

  if activeCombo then
    return activeCombo.id, activeCombo.data
  end

  return nil
end

-- Hook this feature into the settings loading/saving system
local originalLoadSettings = DM.LoadSettings
DM.LoadSettings = function(self)
  -- Call original function
  if originalLoadSettings then
    originalLoadSettings(self)
  end

  -- Initialize combinations database
  if DM.InitializeCombinationsDB then
    DM:InitializeCombinationsDB()
  end
end

local originalSaveSettings = DM.SaveSettings
DM.SaveSettings = function(self)
  -- Call original function
  if originalSaveSettings then
    originalSaveSettings(self)
  end

  -- Save combinations database
  if DM.SaveCombinationsDB then
    DM:SaveCombinationsDB()
  end
end
