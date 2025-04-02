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
  if not spellID or not spellName then
    self:DatabaseDebug("Failed to add spell to database - missing spellID or spellName")
    return
  end

  -- Always convert ID to string for consistency
  local idStr = tostring(spellID)

  self:DatabaseDebug(string.format("Adding spell to dmspellsdb - ID=%s, Name=%s, Class=%s, Spec=%s",
    idStr, spellName, className or "UNKNOWN", specName or "General"))

  -- Default values
  local defaultColor = { 1, 0, 0 } -- Red
  local defaultPriority = 999
  local defaultTracked = 1
  local defaultEnabled = 1

  -- Check if the spell already exists in the database
  local isNew = not DM.dmspellsdb[idStr]
  if not isNew then
    self:DatabaseDebug(string.format("Spell %s already exists in database, updating", idStr))
  end

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

  self:DatabaseDebug(string.format("%s spell in dmspellsdb: ID=%s, Name=%s",
    isNew and "Added new" or "Updated", idStr, spellName))
end

-- Function to reset the database
function DM:ResetDMSpellsDB()
  self:DatabaseDebug("Resetting database - current size: " .. (DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0))

  -- Clear the dmspellsdb table
  DM.dmspellsdb = {}

  self:DatabaseDebug("Database completely reset.")
end

-- Function to save the database to saved variables
function DM:SaveDMSpellsDB()
  self:DatabaseDebug("Saving database to saved variables - size: " ..
  (DM.dmspellsdb and DM:TableCount(DM.dmspellsdb) or 0))

  if not DotMasterDB then DotMasterDB = {} end
  DotMasterDB.dmspellsdb = DM.dmspellsdb

  -- Verify the saved data
  local savedSize = DotMasterDB.dmspellsdb and DM:TableCount(DotMasterDB.dmspellsdb) or 0
  self:DatabaseDebug("Database saved to saved variables - verified size: " .. savedSize)
end

-- Function to normalize database IDs to ensure they're all strings
function DM:NormalizeDatabaseIDs()
  local normalized = {}
  local fixed = 0
  local stringCount = 0
  local numberCount = 0
  local otherCount = 0

  if not DM.dmspellsdb then
    self:DatabaseDebug("No spell database to normalize")
    return
  end

  -- First, log what we're working with
  self:DatabaseDebug("Starting database ID normalization - DB type: " .. type(DM.dmspellsdb))
  self:DatabaseDebug("Current database has " .. DM:TableCount(DM.dmspellsdb) .. " entries")

  for id, data in pairs(DM.dmspellsdb) do
    local idType = type(id)
    local idStr = tostring(id)

    -- Count by type
    if idType == "string" then
      stringCount = stringCount + 1
    elseif idType == "number" then
      numberCount = numberCount + 1
    else
      otherCount = otherCount + 1
    end

    -- If original type wasn't string, we fixed something
    if idType ~= "string" then
      fixed = fixed + 1
      if fixed <= 3 then
        self:DatabaseDebug(string.format("Normalizing ID %s of type %s to string, spell name: %s",
          tostring(id), idType, data.spellname or "unknown"))
      end
    end

    -- Always store with string key
    normalized[idStr] = data
  end

  -- Replace with normalized version
  DM.dmspellsdb = normalized

  local totalFixed = fixed + numberCount + otherCount

  -- Provide detailed log of what happened
  if totalFixed > 0 then
    self:DatabaseDebug(string.format("Database ID normalization complete: %d entries processed",
      DM:TableCount(normalized)))
    self:DatabaseDebug(string.format("- Found %d string IDs, %d number IDs, %d other types", stringCount, numberCount,
      otherCount))
    self:DatabaseDebug(string.format("- Normalized %d IDs to ensure string format", totalFixed))
  else
    self:DatabaseDebug("Database IDs already normalized (all string format)")
  end
end

-- Function to load the database from saved variables
function DM:LoadDMSpellsDB()
  self:DatabaseDebug("Loading database from saved variables")

  if DotMasterDB and DotMasterDB.dmspellsdb then
    local savedSize = DM:TableCount(DotMasterDB.dmspellsdb)
    self:DatabaseDebug("Found saved database with " .. savedSize .. " entries")

    -- Debug first few spells to verify data structure
    local count = 0
    for id, data in pairs(DotMasterDB.dmspellsdb) do
      if count < 3 then
        self:DatabaseDebug(string.format("Saved spell: ID=%s (type=%s), Name=%s",
          tostring(id), type(id), data.spellname or "unknown"))
        count = count + 1
      else
        break
      end
    end

    -- Copy the database
    DM.dmspellsdb = DotMasterDB.dmspellsdb
    self:DatabaseDebug("Database loaded from saved variables - copied structure")

    -- Normalize IDs to ensure they're all strings
    self:DatabaseDebug("Running ID normalization on loaded database")
    self:NormalizeDatabaseIDs()

    -- Verify final database state
    self:DatabaseDebug("Database loading complete - final size: " .. DM:TableCount(DM.dmspellsdb))
  else
    self:DatabaseDebug("No saved database found in SavedVariables, initializing empty database")
    DM.dmspellsdb = {}
  end
end

-- Call LoadDMSpellsDB on addon load
DM:LoadDMSpellsDB()
