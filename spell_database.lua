-- DotMaster spell_database.lua
-- Dynamic spell database with automatic detection and classification

local DM = DotMaster

-- Initialize database
DM.spellDatabase = {}
DM.MAX_DATABASE_SIZE = 500

-- Initialize new database structure
DM.dmspellsdb = {}

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

-- Legacy SpellNames table for compatibility
DM.SpellNames = {}

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
    -- Check if we're at capacity
    local databaseSize = self:TableCount(self.spellDatabase)
    if databaseSize >= self.MAX_DATABASE_SIZE then
      -- We're at capacity, might need to clean up
      -- For now, just don't add any more
      return
    end

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

  -- Update legacy SpellNames table
  self.SpellNames[spellID] = spellName
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
  if not DotMasterDB then DotMasterDB = {} end
  DotMasterDB.spellDatabase = self.spellDatabase

  -- Also update legacy SpellNames
  DotMasterDB.SpellNames = self.SpellNames
end

-- Function to load database
function DM:LoadSpellDatabase()
  -- Load from SavedVariables
  if DotMasterDB and DotMasterDB.spellDatabase then
    self.spellDatabase = DotMasterDB.spellDatabase
  end

  -- Also load legacy SpellNames for compatibility
  if DotMasterDB and DotMasterDB.SpellNames then
    self.SpellNames = DotMasterDB.SpellNames
  end

  -- Update legacy SpellNames from database for consistency
  if self.spellDatabase then
    for id, spellData in pairs(self.spellDatabase) do
      self.SpellNames[id] = spellData.name
    end
  end
end

-- Function to clean up database (remove old entries)
function DM:CleanupSpellDatabase()
  if not self.spellDatabase then return end

  local databaseSize = self:TableCount(self.spellDatabase)
  if databaseSize <= self.MAX_DATABASE_SIZE then return end

  -- Sort by last used time
  local spellsToSort = {}
  for id, data in pairs(self.spellDatabase) do
    table.insert(spellsToSort, {
      id = id,
      lastUsed = data.lastUsed or 0,
      useCount = data.useCount or 0
    })
  end

  -- Sort by last used (oldest first)
  table.sort(spellsToSort, function(a, b)
    if a.useCount == 0 and b.useCount > 0 then
      return true -- Unused spells first
    elseif a.useCount > 0 and b.useCount == 0 then
      return false
    else
      return a.lastUsed < b.lastUsed -- Then by last used time
    end
  end)

  -- Remove oldest entries to get back to max size
  local toRemove = databaseSize - self.MAX_DATABASE_SIZE
  for i = 1, toRemove do
    if i <= #spellsToSort then
      local id = spellsToSort[i].id
      self.spellDatabase[id] = nil
      -- Also update legacy SpellNames
      self.SpellNames[id] = nil
    end
  end
end

-- Function to add a spell to the new database
function DM:AddSpellToDMSpellsDB(spellID, spellName, spellIcon, className, specName)
  if not spellID or not spellName then return end

  -- Always convert ID to string for consistency
  local idStr = tostring(spellID)

  -- Default values
  local defaultColor = { 1, 0, 0 } -- Red
  local defaultPriority = 999
  local defaultTracked = 1
  local defaultEnabled = 1

  -- Add or update spell in the database
  DM.dmspellsdb[idStr] = {
    spellname = spellName,
    spellicon = spellIcon,
    wowclass = className or "UNKNOWN",
    wowspec = specName or "General",
    color = defaultColor,
    priority = defaultPriority,
    tracked = defaultTracked,
    enabled = defaultEnabled
  }

  DM:DatabaseDebug(string.format("Added spell to dmspellsdb: ID=%s, Name=%s", idStr, spellName))
end

-- Function to reset the database
function DM:ResetDMSpellsDB()
  -- Clear the dmspellsdb table
  DM.dmspellsdb = {}

  -- Removed obsolete spellConfig clearing
  DM:DatabaseDebug("Database completely reset.")
end

-- Function to save the database to saved variables
function DM:SaveDMSpellsDB()
  if not DotMasterDB then DotMasterDB = {} end
  DotMasterDB.dmspellsdb = DM.dmspellsdb
  DM:DatabaseDebug("dmspellsdb saved to saved variables.")
end

-- Function to normalize database IDs to ensure they're all strings
function DM:NormalizeDatabaseIDs()
  local normalized = {}
  local fixed = 0

  if not DM.dmspellsdb then
    DM:DatabaseDebug("No spell database to normalize")
    return
  end

  for id, data in pairs(DM.dmspellsdb) do
    local idStr = tostring(id)
    normalized[idStr] = data
    if idStr ~= id then fixed = fixed + 1 end
  end

  DM.dmspellsdb = normalized

  if fixed > 0 then
    DM:DatabaseDebug(string.format("Normalized %d spell IDs in database to ensure string format", fixed))
  end
end

-- Function to load the database from saved variables
function DM:LoadDMSpellsDB()
  if DotMasterDB and DotMasterDB.dmspellsdb then
    DM.dmspellsdb = DotMasterDB.dmspellsdb
    DM:DatabaseDebug("dmspellsdb loaded from saved variables.")

    -- Normalize IDs to ensure they're all strings
    DM:NormalizeDatabaseIDs()
  else
    DM.dmspellsdb = {}
    DM:DatabaseDebug("No saved database found, initialized new dmspellsdb.")
  end
end

-- Call LoadDMSpellsDB on addon load
DM:LoadDMSpellsDB()
