-- DotMaster spell_database.lua
-- Dynamic spell database with automatic detection and classification

local DM = DotMaster

-- Initialize database
DM.spellDatabase = DM.spellDatabase or {}

-- Initialize new database structure
DM.dmspellsdb = DM.dmspellsdb or {}

-- Class colors for UI
DM.classColors = {
  ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
  ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
  ["DRUID"] = { r = 1.00, g = 0.49, b = 0.04 },
  ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
  ["MAGE"] = { r = 0.41, g = 0.80, b = 0.94 },
  ["MONK"] = { r = 0.00, g = 1.00, b = 0.59 },
  ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
  ["PRIEST"] = { r = 1.00, g = 1.00, b = 1.00 },
  ["ROGUE"] = { r = 1.00, g = 0.96, b = 0.41 },
  ["SHAMAN"] = { r = 0.00, g = 0.44, b = 0.87 },
  ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
  ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
  ["EVOKER"] = { r = 0.20, g = 0.58, b = 0.50 },
  ["UNKNOWN"] = { r = 0.50, g = 0.50, b = 0.50 },
}

-- Function to add a spell to the database
function DM:AddSpellToDatabase(spellID, spellName, className, specName)
  -- Check parameters
  if not spellID or not spellName then return end

  -- Convert to number
  spellID = tonumber(spellID)
  if not spellID then return end

  -- Initialize database if needed
  if not self.spellDatabase then self.spellDatabase = {} end

  -- Update or add entry
  if not self.spellDatabase[spellID] then
    -- Add new entry
    self.spellDatabase[spellID] = {
      name = spellName,
      class = className or "UNKNOWN",
      spec = specName or "General",
      firstSeen = GetServerTime(),
      lastUsed = GetServerTime(),
      useCount = 1
    }
  else
    -- Update existing entry
    self.spellDatabase[spellID].lastUsed = GetServerTime()
    self.spellDatabase[spellID].useCount = (self.spellDatabase[spellID].useCount or 0) + 1

    -- Update name if provided
    if spellName and spellName ~= "" and spellName ~= "Unknown" then
      self.spellDatabase[spellID].name = spellName
    end

    -- Update class/spec if provided
    if className and className ~= "" and className ~= "UNKNOWN" then
      self.spellDatabase[spellID].class = className
    end

    if specName and specName ~= "" and specName ~= "General" then
      self.spellDatabase[spellID].spec = specName
    end
  end
end

-- Function to get all spells for a class
function DM:GetSpellsForClass(className)
  if not self.spellDatabase then return {} end

  local spells = {}
  for id, spellData in pairs(self.spellDatabase) do
    if not className or className == "ALL" or spellData.class == className then
      spells[id] = spellData
    end
  end

  return spells
end

-- Function to get all spells for a spec
function DM:GetSpellsForSpec(className, specName)
  if not self.spellDatabase then return {} end

  local spells = {}
  for id, spellData in pairs(self.spellDatabase) do
    if (not className or className == "ALL" or spellData.class == className) and
        (not specName or specName == "ALL" or spellData.spec == specName) then
      spells[id] = spellData
    end
  end

  return spells
end

-- Function to search for spells by name
function DM:SearchSpellsByName(searchText)
  if not self.spellDatabase then return {} end
  if not searchText or searchText == "" or searchText == "Search..." then return self.spellDatabase end

  local results = {}
  searchText = searchText:lower()

  for id, spellData in pairs(self.spellDatabase) do
    if spellData.name and spellData.name:lower():find(searchText) then
      results[id] = spellData
    end
  end

  return results
end

-- Function to save database
function DM:SaveSpellDatabase()
  -- Save to SavedVariables
  if not DotMasterDB then
    DM:DatabaseDebug("Creating new SavedVariables table for DotMasterDB")
    DotMasterDB = {}
  end
  DotMasterDB.spellDatabase = self.spellDatabase
  DM:DatabaseDebug("Saved spellDatabase with " .. DM:TableCount(self.spellDatabase) .. " entries")
end

-- Function to load database
function DM:LoadSpellDatabase()
  -- Load from SavedVariables
  if DotMasterDB and DotMasterDB.spellDatabase then
    self.spellDatabase = DotMasterDB.spellDatabase
    DM:DatabaseDebug("Loaded spellDatabase with " .. DM:TableCount(self.spellDatabase) .. " entries")
  else
    self.spellDatabase = {}
    DM:DatabaseDebug("No saved spellDatabase found, initialized empty table")
  end
end

-- Function to add a spell to the new database
function DM:AddSpellToDMSpellsDB(spellID, spellName, spellIcon, className, specName)
  if not spellID or not spellName then return end

  -- Convert ID to number for consistency
  local numericID = tonumber(spellID)
  if not numericID then return end

  -- Add or update spell in the database
  DM.dmspellsdb[numericID] = {
    spellname = spellName,
    spellicon = spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
    wowclass = className or "UNKNOWN",
    wowspec = specName or "General",
    color = { 1, 0, 0 }, -- Red
    priority = 999,
    tracked = 1,
    enabled = 1
  }

  -- Save immediately after adding
  DM:SaveDMSpellsDB()

  DM:DatabaseDebug(string.format("Added spell to dmspellsdb: ID=%d, Name=%s", numericID, spellName))
end

-- Function to reset the database
function DM:ResetDMSpellsDB()
  -- Clear the dmspellsdb table
  DM.dmspellsdb = {}

  -- Also explicitly remove spellConfig from SavedVariables if it exists
  if DotMasterDB then
    DotMasterDB.spellConfig = nil
  end

  DM:DatabaseDebug("Database completely reset.")
end

-- Function to save the database to saved variables
function DM:SaveDMSpellsDB()
  -- First save to the current profile if available
  if self.currentProfile then
    self.currentProfile.spells = DM.dmspellsdb
    local count = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
    DM:DatabaseDebug("Saved dmspellsdb to current profile (" .. count .. " spells)")

    -- If we have class/spec integration, also make sure it's saved properly
    if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
      DM.ClassSpec:SaveCurrentSettings()
    end
    return
  end

  -- If we don't have a current profile reference, try to get it
  local currentProfile = DM:GetCurrentSpecProfile()
  if currentProfile then
    currentProfile.spells = DM.dmspellsdb
    local count = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
    DM:DatabaseDebug("Saved dmspellsdb to spec profile via GetCurrentSpecProfile (" .. count .. " spells)")

    -- If we have class/spec integration, also make sure it's saved properly
    if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
      DM.ClassSpec:SaveCurrentSettings()
    end
    return
  end

  -- Fallback to legacy method if the above failed
  if not DotMasterDB then
    DM:DatabaseDebug("Creating new SavedVariables table for DotMasterDB")
    DotMasterDB = {}
  end

  DotMasterDB.dmspellsdb = DM.dmspellsdb

  local count = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
  DM:DatabaseDebug("Saved dmspellsdb to legacy SavedVariables (" .. count .. " spells)")
end

-- Function to normalize database IDs to ensure they're all numbers
function DM:NormalizeDatabaseIDs()
  local normalized = {}
  local fixed = 0

  if not DM.dmspellsdb then
    DM:DatabaseDebug("No spell database to normalize")
    return
  end

  for id, data in pairs(DM.dmspellsdb) do
    local numericID = tonumber(id)
    -- Only process valid numeric IDs
    if numericID then
      normalized[numericID] = data
      if numericID ~= id then fixed = fixed + 1 end
    else
      DM:DatabaseDebug(string.format("Skipping invalid non-numeric ID: %s", tostring(id)))
    end
  end

  DM.dmspellsdb = normalized

  if fixed > 0 then
    DM:DatabaseDebug(string.format("Normalized %d spell IDs in database to ensure numeric format", fixed))
  end
end

-- Function to load the database from saved variables
function DM:LoadDMSpellsDB()
  -- First check if we already have a current profile reference
  if self.currentProfile and self.currentProfile.spells then
    DM.dmspellsdb = self.currentProfile.spells
    local count = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
    DM:DatabaseDebug("Loaded dmspellsdb from current profile (" .. count .. " spells)")
    return
  end

  -- If we don't have a currentProfile yet, try to get it
  local currentProfile = self:GetCurrentSpecProfile()
  if currentProfile and currentProfile.spells then
    DM.dmspellsdb = currentProfile.spells
    local count = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
    DM:DatabaseDebug("Loaded dmspellsdb from GetCurrentSpecProfile (" .. count .. " spells)")
    return
  end

  -- Fallback to legacy method if the above failed
  if DotMasterDB and DotMasterDB.dmspellsdb then
    DM.dmspellsdb = DotMasterDB.dmspellsdb
    local count = DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0
    DM:DatabaseDebug("Loaded dmspellsdb from legacy saved variables (" .. count .. " spells)")
  else
    DM.dmspellsdb = {}
    DM:DatabaseDebug("No saved dmspellsdb found, initialized empty table")
  end
end

-- Make sure to NOT call LoadDMSpellsDB here - it will be called during ADDON_LOADED in bootstrap
-- DM:LoadDMSpellsDB() -- This line is removed
