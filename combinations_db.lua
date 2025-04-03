-- DotMaster combinations_db.lua
-- Database structure and functions for DoT combinations

local DM = DotMaster

-- Function to check if combinations database is initialized
function DM:IsCombinationsInitialized()
  if not DM.combinations then
    DM:DebugMsg("Combinations database is not initialized (DM.combinations is nil)")
    return false
  end

  if not DM.combinations.data then
    DM:DebugMsg("Combinations database is not initialized (DM.combinations.data is nil)")
    return false
  end

  if not DM.combinations.settings then
    DM:DebugMsg("Combinations database is not initialized (DM.combinations.settings is nil)")
    return false
  end

  return true
end

-- Function to force initialization of combinations database
function DM:ForceCombinationsInitialization()
  if DM:IsCombinationsInitialized() then
    DM:DebugMsg("Combinations database already initialized")
    return true
  end

  DM:DebugMsg("Forcing combinations database initialization...")

  -- Create a minimal valid structure
  if not DM.combinations then
    DM.combinations = {}
  end

  if not DM.combinations.settings then
    DM.combinations.settings = {
      enabled = true,
      priorityOverIndividual = true,
    }
  end

  if not DM.combinations.data then
    DM.combinations.data = {}
  end

  -- Save to permanent storage
  if not DotMasterDB then
    DotMasterDB = {}
  end

  DotMasterDB.combinations = DM.combinations

  -- Announce initialization
  DM:DebugMsg("Combinations database force-initialized successfully")
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

-- Initialize combinations database
function DM:InitializeCombinationsDB()
  DM:DebugMsg("Initializing combinations database")

  -- Make sure DotMasterDB exists
  if not DotMasterDB then
    DotMasterDB = {}
    DM:DebugMsg("Created new DotMasterDB table")
  end

  -- Create combinations namespace if it doesn't exist
  if not DotMasterDB.combinations then
    -- Check if DeepCopy function exists
    if DM.DeepCopy then
      DotMasterDB.combinations = DM.DeepCopy(DM.defaultCombinations)
    else
      -- Fallback to simple copy if DeepCopy isn't available
      DotMasterDB.combinations = {
        settings = {
          enabled = true,
          priorityOverIndividual = true,
        },
        data = {}
      }
    end
    DM:DebugMsg("Created new combinations database structure")
  end

  -- Ensure all required fields exist (for version upgrades)
  if DotMasterDB.combinations and not DotMasterDB.combinations.settings then
    if DM.DeepCopy then
      DotMasterDB.combinations.settings = DM.DeepCopy(DM.defaultCombinations.settings)
    else
      DotMasterDB.combinations.settings = {
        enabled = true,
        priorityOverIndividual = true,
      }
    end
    DM:DebugMsg("Added missing settings to combinations database")
  end

  if DotMasterDB.combinations and not DotMasterDB.combinations.data then
    DotMasterDB.combinations.data = {}
    DM:DebugMsg("Added missing data table to combinations database")
  end

  -- Store reference for easier access
  DM.combinations = DotMasterDB.combinations

  local comboCount = (DotMasterDB.combinations and DotMasterDB.combinations.data) and
      DM:TableCount(DotMasterDB.combinations.data) or 0
  DM:DebugMsg("Combinations database initialized with " .. comboCount .. " combinations")
end

-- Save combinations database
function DM:SaveCombinationsDB()
  if not DotMasterDB then
    DM:DebugMsg("ERROR: Cannot save combinations - DotMasterDB not initialized")
    return
  end

  -- Check if combinations exists before saving
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot save combinations - DM.combinations not initialized")
    return
  end

  -- Ensure the combinations entry exists
  DotMasterDB.combinations = DM.combinations

  local comboCount = (DM.combinations and DM.combinations.data) and DM:TableCount(DM.combinations.data) or 0
  DM:DebugMsg("Combinations database saved with " .. comboCount .. " combinations")
end

-- Create a new combination
function DM:CreateCombination(name, spells, color)
  -- Ensure combinations system is initialized
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot create combination - database not initialized")
    -- Try to initialize if missing
    if DM.InitializeCombinationsDB then
      local success, errorMsg = pcall(function()
        DM:InitializeCombinationsDB()
      end)

      if not success or not DM.combinations then
        DM:DebugMsg("Failed to initialize combinations database: " .. (errorMsg or "unknown error"))
        return nil
      end
    else
      return nil
    end
  end

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
  if not DM.combinations.data then
    DM.combinations.data = {}
  end

  DM.combinations.data[id] = {
    name = name or "New Combination",
    spells = spells or {},
    color = color or { r = 1, g = 0, b = 0, a = 1 },
    priority = priority,
    enabled = true,
    threshold = "all" -- "all" or numeric value
  }

  -- Save changes safely
  local success, errorMsg = pcall(function()
    DM:SaveCombinationsDB()
  end)

  if not success then
    DM:DebugMsg("Error saving after creating combination: " .. (errorMsg or "unknown error"))
  end

  return id
end

-- Delete a combination
function DM:DeleteCombination(id)
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot delete combination - database not initialized")
    return false
  end

  if not DM.combinations.data then
    DM:DebugMsg("ERROR: Cannot delete combination - data table not initialized")
    return false
  end

  if not id or not DM.combinations.data[id] then
    DM:DebugMsg("ERROR: Cannot delete combination - ID not found: " .. tostring(id))
    return false
  end

  -- Remove the combination
  DM.combinations.data[id] = nil

  -- Save changes safely
  local success, errorMsg = pcall(function()
    DM:SaveCombinationsDB()
  end)

  if not success then
    DM:DebugMsg("Error saving after deleting combination: " .. (errorMsg or "unknown error"))
  end

  return true
end

-- Update an existing combination
function DM:UpdateCombination(id, updates)
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot update combination - database not initialized")
    return false
  end

  if not DM.combinations.data then
    DM:DebugMsg("ERROR: Cannot update combination - data table not initialized")
    return false
  end

  if not id or not DM.combinations.data[id] then
    DM:DebugMsg("ERROR: Cannot update combination - ID not found: " .. tostring(id))
    return false
  end

  if not updates or type(updates) ~= "table" then
    DM:DebugMsg("ERROR: Cannot update combination - updates must be a table")
    return false
  end

  -- Apply updates
  for key, value in pairs(updates) do
    DM.combinations.data[id][key] = value
  end

  -- Save changes safely
  local success, errorMsg = pcall(function()
    DM:SaveCombinationsDB()
  end)

  if not success then
    DM:DebugMsg("Error saving after updating combination: " .. (errorMsg or "unknown error"))
  end

  return true
end

-- Update combination priorities
function DM:UpdateCombinationPriorities(priorityTable)
  if not DM.combinations then
    DM:DebugMsg("ERROR: Cannot update priorities - database not initialized")
    return false
  end

  if not DM.combinations.data then
    DM:DebugMsg("ERROR: Cannot update priorities - data table not initialized")
    return false
  end

  if not priorityTable or type(priorityTable) ~= "table" then
    DM:DebugMsg("ERROR: Cannot update priorities - priorityTable must be a table")
    return false
  end

  -- Apply the new priorities
  for id, priority in pairs(priorityTable) do
    if DM.combinations.data[id] then
      DM.combinations.data[id].priority = priority
    end
  end

  -- Save changes safely
  local success, errorMsg = pcall(function()
    DM:SaveCombinationsDB()
  end)

  if not success then
    DM:DebugMsg("Error saving after updating priorities: " .. (errorMsg or "unknown error"))
  end

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
    return nil
  end

  if not DM.combinations.settings or not DM.combinations.settings.enabled then
    return nil
  end

  if not DM.combinations.data then
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
    return nil
  end

  table.sort(sortedCombos, function(a, b) return a.priority < b.priority end)

  -- Check each combination
  for _, comboInfo in ipairs(sortedCombos) do
    local combo = comboInfo.data
    if combo and combo.spells then
      local required = combo.threshold == "all" and #combo.spells or tonumber(combo.threshold) or #combo.spells
      local count = 0

      -- Check how many spells from this combination are active
      for _, spellID in ipairs(combo.spells) do
        -- Safely call HasPlayerDotOnUnit
        if DM.HasPlayerDotOnUnit and DM:HasPlayerDotOnUnit(unit, spellID) then
          count = count + 1
        end
      end

      -- If we have enough active spells, use this combination
      if count >= required then
        activeCombo = comboInfo
        break
      end
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
