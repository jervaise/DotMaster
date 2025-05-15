-- DotMaster combinations_db.lua
-- Database structure and functions for DoT combinations

local DM = DotMaster

-- Function to check if combinations database is initialized
function DM:IsCombinationsInitialized()
  -- Check if the current spec has a profile initialized
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DebugMsg("Combinations database is not initialized (current spec profile not found)")
    return false
  end

  -- Check if the current spec has a combinations field
  if not currentProfile.combinations then
    DM:DebugMsg("Combinations database is not initialized (current spec profile has no combinations field)")
    return false
  end

  return true
end

-- Function to force initialization of combinations database
function DM:ForceCombinationsInitialization()
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DebugMsg("Cannot initialize combinations - no current spec profile")
    return false
  end

  if DM:IsCombinationsInitialized() then
    DM:DebugMsg("Combinations database already initialized for current spec")
    return true
  end

  DM:DebugMsg("Forcing combinations database initialization for current spec...")

  -- Create a minimal valid structure in the current spec profile
  if not currentProfile.combinations then
    currentProfile.combinations = {
      data = {},
      settings = {
        enabled = true,
        priorityOverIndividual = true,
      }
    }
    DM:DebugMsg("Created combinations structure in current spec profile")
  end

  -- Save to permanent storage
  if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
    DM.ClassSpec:SaveCurrentSettings()
    DM:DebugMsg("Saved initialized combinations structure to permanent storage")
  end

  return true
end

-- Ensure we have a DeepCopy function (fallback implementation if needed)
if not DM.DeepCopy then
  DM.DeepCopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
        copy[DM.DeepCopy(orig_key)] = DM.DeepCopy(orig_value)
      end
      setmetatable(copy, DM.DeepCopy(getmetatable(orig)))
    else
      copy = orig
    end
    return copy
  end
  DM:DebugMsg("Created fallback DeepCopy function for combinations module")
end

-- Ensure we have a TableCount function (fallback implementation if needed)
if not DM.TableCount then
  DM.TableCount = function(tbl)
    if not tbl or type(tbl) ~= "table" then
      return 0
    end

    local count = 0
    for _ in pairs(tbl) do
      count = count + 1
    end
    return count
  end
  DM:DebugMsg("Created fallback TableCount function for combinations module")
end

-- Ensure we have a HasPlayerDotOnUnit function (placeholder if needed)
if not DM.HasPlayerDotOnUnit then
  DM.HasPlayerDotOnUnit = function(self, unit, spellID)
    -- This is just a placeholder until the real implementation is loaded
    -- Returns false since we can't detect DoTs without the actual implementation
    return false
  end
  DM:DebugMsg("Created placeholder HasPlayerDotOnUnit function for combinations module")
end

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

-- Helper function to get the combinations from the current spec profile
function DM:GetCurrentSpecCombinations()
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DebugMsg("WARNING: Cannot get combinations - no current spec profile")
    return nil
  end

  -- First check for the standard 'combinations' field
  if not currentProfile.combinations then
    -- Check for legacy 'combos' field
    if currentProfile.combos then
      -- Migrate data from 'combos' to 'combinations'
      currentProfile.combinations = currentProfile.combos
      currentProfile.combos = nil -- Remove legacy field after migration
      DM:DebugMsg("GetCurrentSpecCombinations migrated legacy 'combos' field to 'combinations'")
    else
      -- Initialize combinations structure if it doesn't exist
      currentProfile.combinations = {
        data = {},
        settings = {
          enabled = true,
          priorityOverIndividual = true,
        }
      }
      DM:DebugMsg("Created initial combinations structure in current spec profile")
    end
  end

  return currentProfile.combinations
end

-- Initialize combinations database
function DM:InitializeCombinationsDB()
  DM:DebugMsg("Initializing combinations database")

  -- Make sure current spec profile exists
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DebugMsg("Cannot initialize combinations - no current spec profile")
    return
  end

  -- Create combinations namespace if it doesn't exist
  if not currentProfile.combinations then
    -- Check if DeepCopy function exists
    if DM.DeepCopy then
      currentProfile.combinations = DM.DeepCopy(DM.defaultCombinations)
    else
      -- Fallback to simple copy if DeepCopy isn't available
      currentProfile.combinations = {
        settings = {
          enabled = true,
          priorityOverIndividual = true,
        },
        data = {}
      }
    end
    DM:DebugMsg("Created new combinations database structure in current spec profile")
  end

  -- Ensure all required fields exist (for version upgrades)
  if currentProfile.combinations and not currentProfile.combinations.settings then
    if DM.DeepCopy then
      currentProfile.combinations.settings = DM.DeepCopy(DM.defaultCombinations.settings)
    else
      currentProfile.combinations.settings = {
        enabled = true,
        priorityOverIndividual = true,
      }
    end
    DM:DebugMsg("Added missing settings to combinations database")
  end

  if currentProfile.combinations and not currentProfile.combinations.data then
    currentProfile.combinations.data = {}
    DM:DebugMsg("Added missing data table to combinations database")
  end

  -- Store a reference for backwards compatibility
  DM.combinations = currentProfile.combinations

  local comboCount = 0
  if currentProfile.combinations and currentProfile.combinations.data then
    comboCount = DM:TableCount(currentProfile.combinations.data)
  end
  DM:DebugMsg("Combinations database initialized with " .. comboCount .. " combinations")

  -- Save changes to permanent storage
  if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
    DM.ClassSpec:SaveCurrentSettings()
  end
end

-- Save combinations database
function DM:SaveCombinationsDB()
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DebugMsg("ERROR: Cannot save combinations - no current spec profile")
    return
  end

  -- Store a reference for backwards compatibility
  DM.combinations = currentProfile.combinations

  -- Get the current class and spec
  local currentClass, currentSpecID = nil, nil
  if DM.ClassSpec and DM.ClassSpec.GetCurrentClassAndSpec then
    currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
  else
    DM:DebugMsg("ERROR: Cannot save combinations - GetCurrentClassAndSpec function not found")
    return
  end

  -- Make sure the database structure exists
  if not DotMasterDB then
    DotMasterDB = {}
  end
  if not DotMasterDB.classProfiles then
    DotMasterDB.classProfiles = {}
  end
  if not DotMasterDB.classProfiles[currentClass] then
    DotMasterDB.classProfiles[currentClass] = {}
  end
  if not DotMasterDB.classProfiles[currentClass][currentSpecID] then
    DotMasterDB.classProfiles[currentClass][currentSpecID] = {
      spells = {},
      combinations = { data = {}, settings = {} },
      settings = {}
    }
  end

  -- Only update the combinations portion of the profile
  DotMasterDB.classProfiles[currentClass][currentSpecID].combinations = currentProfile.combinations

  -- Ensure we maintain the direct reference for the current session
  self.currentProfile = DotMasterDB.classProfiles[currentClass][currentSpecID]

  -- Push the changes to Plater if necessary
  if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
    DM.ClassSpec:PushConfigToPlater()
  end

  local comboCount = 0
  if currentProfile.combinations and currentProfile.combinations.data then
    comboCount = DM:TableCount(currentProfile.combinations.data)
  end
  DM:DebugMsg("Combinations database saved with " .. comboCount .. " combinations")
end

-- Create a new combination
function DM:CreateCombination(name, spells, color)
  -- Get the current spec's combinations
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if not currentCombinations then
    DM:DebugMsg("ERROR: Cannot create combination - failed to get current spec combinations")
    return nil
  end

  -- Generate a unique ID using timestamp
  local id = "combo_" .. time()

  -- Find the highest priority and increment by 1
  local priority = 1
  if currentCombinations.data then
    for _, combo in pairs(currentCombinations.data) do
      if combo and combo.priority and combo.priority >= priority then
        priority = combo.priority + 1
      end
    end
  end

  -- Create the new combination
  if not currentCombinations.data then
    currentCombinations.data = {}
  end

  currentCombinations.data[id] = {
    name = name or "New Combination",
    spells = spells or {},
    color = color or { r = 1, g = 0, b = 0, a = 1 },
    priority = priority,
    enabled = true,
    threshold = "all",  -- "all" or numeric value
    isExpanded = false, -- ALWAYS start collapsed
  }

  -- Debug message to confirm expanded state is set correctly
  DM:DebugMsg("New combination created with ID: " .. id .. ", isExpanded explicitly set to false")

  -- Save changes
  DM:SaveCombinationsDB()

  return id
end

-- Delete a combination
function DM:DeleteCombination(id)
  -- Get the current spec's combinations
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if not currentCombinations then
    DM:DebugMsg("ERROR: Cannot delete combination - failed to get current spec combinations")
    return false
  end

  if not currentCombinations.data then
    DM:DebugMsg("ERROR: Cannot delete combination - data table not initialized")
    return false
  end

  if not id or not currentCombinations.data[id] then
    DM:DebugMsg("ERROR: Cannot delete combination - ID not found: " .. tostring(id))
    return false
  end

  -- Remove the combination
  currentCombinations.data[id] = nil

  -- Save changes
  DM:SaveCombinationsDB()

  return true
end

-- Update an existing combination
function DM:UpdateCombination(id, updates)
  -- Get the current spec's combinations
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if not currentCombinations then
    DM:DebugMsg("ERROR: Cannot update combination - failed to get current spec combinations")
    return false
  end

  if not currentCombinations.data then
    DM:DebugMsg("ERROR: Cannot update combination - data table not initialized")
    return false
  end

  if not id or not currentCombinations.data[id] then
    DM:DebugMsg("ERROR: Cannot update combination - ID not found: " .. tostring(id))
    return false
  end

  if not updates or type(updates) ~= "table" then
    DM:DebugMsg("ERROR: Cannot update combination - updates must be a table")
    return false
  end

  -- Apply updates
  for key, value in pairs(updates) do
    currentCombinations.data[id][key] = value
  end

  -- Save changes
  DM:SaveCombinationsDB()

  return true
end

-- Update combination priorities
function DM:UpdateCombinationPriorities(priorityTable)
  -- Get the current spec's combinations
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if not currentCombinations then
    DM:DebugMsg("ERROR: Cannot update priorities - failed to get current spec combinations")
    return false
  end

  if not currentCombinations.data then
    DM:DebugMsg("ERROR: Cannot update priorities - data table not initialized")
    return false
  end

  if not priorityTable or type(priorityTable) ~= "table" then
    DM:DebugMsg("ERROR: Cannot update priorities - priorityTable must be a table")
    return false
  end

  -- Apply the new priorities
  for id, priority in pairs(priorityTable) do
    if currentCombinations.data[id] then
      currentCombinations.data[id].priority = priority
    end
  end

  -- Save changes
  DM:SaveCombinationsDB()

  return true
end

-- Check if a unit has a combination active
function DM:CheckCombinationsOnUnit(unit)
  -- First try to ensure combinations are initialized
  if not DM:IsCombinationsInitialized() then
    -- Try to force initialization if needed
    if not DM:ForceCombinationsInitialization() then
      DM:DebugMsg("ERROR: Could not initialize combinations in CheckCombinationsOnUnit")
      return nil
    end
  end

  -- Safe early returns if combinations system is not ready
  if not unit or not UnitExists(unit) then
    DM:DebugMsg("CheckCombinationsOnUnit: Invalid unit or unit doesn't exist")
    return nil
  end

  if not DM.combinations.settings or not DM.combinations.settings.enabled then
    DM:DebugMsg("CheckCombinationsOnUnit: Combinations not enabled in settings")
    return nil
  end

  if not DM.combinations.data then
    DM:DebugMsg("CheckCombinationsOnUnit: No combinations data available")
    return nil
  end

  local activeCombo = nil
  local highestPriority = 999999

  -- Sort combinations by priority
  local sortedCombos = {}
  for id, combo in pairs(DM.combinations.data) do
    if combo and combo.enabled then
      table.insert(sortedCombos, { id = id, priority = combo.priority or 999, data = combo })
    end
  end

  -- If no combos, early return
  if #sortedCombos == 0 then
    DM:DebugMsg("CheckCombinationsOnUnit: No enabled combinations found")
    return nil
  end

  table.sort(sortedCombos, function(a, b) return a.priority < b.priority end)
  DM:DebugMsg("CheckCombinationsOnUnit: Checking %d enabled combinations on %s", #sortedCombos, unit)

  -- Check each combination
  for _, comboInfo in ipairs(sortedCombos) do
    local combo = comboInfo.data
    local comboID = comboInfo.id

    if combo and combo.spells then
      local required = combo.threshold == "all" and #combo.spells or tonumber(combo.threshold) or #combo.spells
      local count = 0
      local activeSpells = {}

      DM:DebugMsg("Checking combination: %s (ID: %s, Priority: %d)",
        combo.name or "Unnamed", comboID, comboInfo.priority)
      DM:DebugMsg("Required spells: %d out of %d total", required, #combo.spells)

      -- Check how many spells from this combination are active
      for i, spellID in ipairs(combo.spells) do
        -- Safely call HasPlayerDotOnUnit
        local spellName = "Unknown"
        -- Use C_Spell.GetSpellInfo instead of global GetSpellInfo per README requirements
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
          spellName = spellInfo.name
        end
        local hasDoT = false

        if DM.HasPlayerDotOnUnit and DM:HasPlayerDotOnUnit(unit, spellID) then
          hasDoT = true
          count = count + 1
          table.insert(activeSpells, { id = spellID, name = spellName })
        end

        DM:DebugMsg("  Spell %d: %s (ID: %d) - %s",
          i, spellName, spellID, hasDoT and "ACTIVE" or "not active")
      end

      -- If we have enough active spells, use this combination
      if count >= required then
        DM:DebugMsg("FOUND ACTIVE COMBINATION: %s with %d/%d required spells",
          combo.name or comboID, count, required)

        -- Log all active spells in this combination
        if #activeSpells > 0 then
          DM:DebugMsg("Active spells in combination:")
          for i, spell in ipairs(activeSpells) do
            DM:DebugMsg("  %d. %s (ID: %d)", i, spell.name, spell.id)
          end
        end

        activeCombo = comboInfo
        break
      else
        DM:DebugMsg("Combination not active: %d/%d required spells found", count, required)
      end
    end
  end

  if activeCombo then
    return activeCombo.id, activeCombo.data
  end

  DM:DebugMsg("No active combinations found on unit %s", unit)
  return nil
end

-- Hook this feature into the settings loading/saving system
local originalLoadSettings = DM.LoadSettings
DM.LoadSettings = function(self)
  -- Call original function
  if originalLoadSettings then
    local success, errorMsg = pcall(function()
      originalLoadSettings(self)
    end)

    if not success then
      DM:DebugMsg("Error in original LoadSettings: " .. (errorMsg or "unknown error"))
    end
  end

  -- Initialize combinations database
  if DM.InitializeCombinationsDB then
    local success, errorMsg = pcall(function()
      DM:InitializeCombinationsDB()
    end)

    if not success then
      DM:DebugMsg("Error initializing combinations database: " .. (errorMsg or "unknown error"))
    end
  end
end

local originalSaveSettings = DM.SaveSettings
DM.SaveSettings = function(self)
  -- Call original function
  if originalSaveSettings then
    local success, errorMsg = pcall(function()
      originalSaveSettings(self)
    end)

    if not success then
      DM:DebugMsg("Error in original SaveSettings: " .. (errorMsg or "unknown error"))
    end
  end

  -- Save combinations database
  if DM.SaveCombinationsDB then
    local success, errorMsg = pcall(function()
      DM:SaveCombinationsDB()
    end)

    if not success then
      DM:DebugMsg("Error saving combinations database: " .. (errorMsg or "unknown error"))
    end
  end
end

-- Register for PLAYER_ENTERING_WORLD to ensure all other modules are loaded
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_ENTERING_WORLD" then
    -- Delay initialization slightly to ensure all modules are loaded
    C_Timer.After(0.5, function()
      if DM and DM.InitializeCombinationsDB then
        DM:DebugMsg("Running delayed combinations initialization...")
        local success = pcall(function()
          DM:InitializeCombinationsDB()
        end)

        -- Check if initialization was successful
        if not success or not DM:IsCombinationsInitialized() then
          DM:DebugMsg("Initial combination database initialization failed, trying force initialization...")
          local forceSuccess = pcall(function()
            DM:ForceCombinationsInitialization()
          end)

          if forceSuccess and DM:IsCombinationsInitialized() then
            DM:DebugMsg("Force initialization successful")

            -- Attempt to update/refresh the UI if it exists
            if DM.GUI and DM.GUI.UpdateCombinationsList then
              DM:DebugMsg("Refreshing combinations UI after initialization")
              DM.GUI.UpdateCombinationsList()
            end
          else
            -- Log visible error message
            if _G.DEFAULT_CHAT_FRAME then
              _G.DEFAULT_CHAT_FRAME:AddMessage(
                "|cFFFF0000DotMaster combinations database initialization failed. Try reloading UI.|r")
            end
          end
        end
      else
        -- Log error if DM is not ready
        if _G.DEFAULT_CHAT_FRAME then
          _G.DEFAULT_CHAT_FRAME:AddMessage(
            "|cFFFF0000DotMaster combinations module could not initialize - addon not ready|r")
        end
      end
    end)

    -- Unregister after first use
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  end
end)

-- Hook into the main addon's ADDON_LOADED handler for good measure
if not DM.combinations_db_hooked then
  local originalOnEvent = DM:GetScript("OnEvent") or function() end
  DM:SetScript("OnEvent", function(self, event, ...)
    -- Call original handler first
    originalOnEvent(self, event, ...)

    -- Add our hook for ADDON_LOADED
    if event == "ADDON_LOADED" and ... == "DotMaster" then
      DM.combinations_db_hooked = true
      DM:DebugMsg("Combinations module detected addon load")
    end
  end)
end

-- Check if a combination contains only spells from the player's class or unknown class
function DM:IsCombinationForCurrentClass(comboID)
  if not comboID or not DM.combinations or not DM.combinations.data then
    return false
  end

  local combo = DM.combinations.data[comboID]
  if not combo or not combo.spells then
    return false
  end

  -- Get current player class
  local currentClass = select(2, UnitClass("player"))

  -- Check each spell in the combination
  for _, spellID in ipairs(combo.spells) do
    -- Find the spell in the database
    if DM.dmspellsdb and DM.dmspellsdb[spellID] then
      local spellData = DM.dmspellsdb[spellID]
      -- If spell is from another class (not current and not UNKNOWN), return false
      if spellData.wowclass and spellData.wowclass ~= currentClass and spellData.wowclass ~= "UNKNOWN" then
        return false
      end
    end
  end

  -- All spells are from current class or unknown
  return true
end

-- Get combinations filtered by the current player's class
function DM:GetCombinationsForCurrentClass()
  if not DM.combinations or not DM.combinations.data then
    return {}
  end

  local filteredCombos = {}

  for comboID, combo in pairs(DM.combinations.data) do
    if DM:IsCombinationForCurrentClass(comboID) then
      filteredCombos[comboID] = combo
    end
  end

  return filteredCombos
end
