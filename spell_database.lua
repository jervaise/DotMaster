-- DotMaster spell_database.lua
-- Handles adding, tracking, and managing the spell database.

local DM = DotMaster

-- Initialize database
DM.spellDatabase = DM.spellDatabase or {}

-- Initialize new database structure
DM.dmspellsdb = DM.dmspellsdb or {}

-- Define class color table (useful for spell configuration)
DM.classColors = {
  DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
  DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
  DRUID = { r = 1.00, g = 0.49, b = 0.04 },
  HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
  MAGE = { r = 0.41, g = 0.80, b = 0.94 },
  MONK = { r = 0.00, g = 1.00, b = 0.59 },
  PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
  PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
  ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
  SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
  WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
  WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
  EVOKER = { r = 0.20, g = 0.58, b = 0.50 }
}

-- Helper function to count entries in a table
function DM:TableCount(t)
  if not t then return 0 end
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- Function to add a spell to the database
function DM:AddSpellToDB(spellID, forceUpdate)
  -- Validate inputs
  if not spellID then
    return false, "No spell ID provided"
  end

  -- Convert to numeric ID
  local numericID = tonumber(spellID)
  if not numericID then
    return false, "Invalid spell ID (not a number): " .. tostring(spellID)
  end

  -- Initialize spell database if not already done
  if not self.dmspellsdb then
    self.dmspellsdb = {}
  end

  -- Don't overwrite existing entries unless forced
  if self.dmspellsdb[numericID] and not forceUpdate then
    return false, "Spell already exists in database (ID: " .. numericID .. ")"
  end

  -- Get spell info
  local spellName, _, spellIcon = GetSpellInfo(numericID)
  if not spellName then
    return false, "Invalid spell ID (no info available): " .. numericID
  end

  -- Create or update the entry
  self.dmspellsdb[numericID] = {
    id = numericID,
    name = spellName,
    icon = spellIcon,
    priority = self.dmspellsdb[numericID] and self.dmspellsdb[numericID].priority or 100,
    enabled = self.dmspellsdb[numericID] and self.dmspellsdb[numericID].enabled or true,
    color = self.dmspellsdb[numericID] and self.dmspellsdb[numericID].color or nil
  }

  -- Save to database
  local _, playerClass = UnitClass("player")
  if not self.dmspellsdb[numericID].class then
    self.dmspellsdb[numericID].class = playerClass
  end

  return true, "Spell added: " .. spellName .. " (ID: " .. numericID .. ")"
end

-- Function to save the spell database to SavedVariables
function DM:SaveDMSpellsDB()
  -- Create main SavedVariables table if it doesn't exist
  if not DotMasterDB then
    DotMasterDB = {}
  end

  -- Save spellDatabase
  DotMasterDB.spellDatabase = self.spellDatabase or {}

  -- Save active tracked spells
  DotMasterDB.dmspellsdb = self.dmspellsdb or {}

  -- Count spells for reporting
  local count = DM:TableCount(self.dmspellsdb)
end

-- Function to load the spell database from SavedVariables
function DM:LoadDMSpellsDB()
  -- Check if saved database exists
  if DotMasterDB and DotMasterDB.spellDatabase then
    self.spellDatabase = DotMasterDB.spellDatabase
  else
    self.spellDatabase = {}
  end

  -- Load active tracked spells
  if DotMasterDB and DotMasterDB.dmspellsdb then
    self.dmspellsdb = DotMasterDB.dmspellsdb

    -- Ensure numeric IDs
    self:NormalizeSpellIDs(self.dmspellsdb)
  else
    self.dmspellsdb = {}
  end
end

-- Function to completely reset the database
function DM:ResetDatabase()
  -- Reset the database
  self.dmspellsdb = {}
  self.spellDatabase = {}

  -- Also reset the SavedVariables
  if DotMasterDB then
    DotMasterDB.dmspellsdb = {}
    DotMasterDB.spellDatabase = {}
  else
    DotMasterDB = {
      dmspellsdb = {},
      spellDatabase = {}
    }
  end

  -- Return success
  return true
end

-- Save just the active spells db
function DM:SaveSpellsDB()
  -- Create main SavedVariables table if it doesn't exist
  if not DotMasterDB then
    DotMasterDB = {}
  end

  -- Save tracked spells
  DotMasterDB.dmspellsdb = self.dmspellsdb or {}

  -- Count spells for reporting
  local count = 0
  for _ in pairs(self.dmspellsdb or {}) do
    count = count + 1
  end
end

-- Function to ensure all spell IDs are numeric
function DM:NormalizeSpellIDs(db)
  if not db then
    return
  end

  local fixed = 0
  local toConvert = {}

  -- First pass - identify string keys that should be numeric
  for id, data in pairs(db) do
    if type(id) == "string" then
      local numericID = tonumber(id)
      if numericID then
        toConvert[id] = numericID
        fixed = fixed + 1
      end
    end
  end

  -- Second pass - create new entries with numeric keys
  for stringID, numericID in pairs(toConvert) do
    db[numericID] = db[stringID]
    db[stringID] = nil
  end

  return fixed
end

-- Function to import spells from saved database
function DM:ImportFromSavedDB()
  -- Capture current count for debugging
  local oldCount = DM:TableCount(self.dmspellsdb or {})

  -- Load from saved variables
  if DotMasterDB and DotMasterDB.dmspellsdb then
    -- Initialize if not already done
    if not self.dmspellsdb then
      self.dmspellsdb = {}
    end

    -- Import all spells, preserving existing entries
    for id, data in pairs(DotMasterDB.dmspellsdb) do
      if not self.dmspellsdb[id] then
        self.dmspellsdb[id] = data
      end
    end

    local newCount = DM:TableCount(self.dmspellsdb)
  end

  return true
end

-- DatabaseDebug function (used only for database operations)
function DM:DatabaseDebug(message, ...)
  -- This function is intentionally left empty to remove debug calls
  -- without having to modify all the calling locations
end

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

-- Make sure to NOT call LoadDMSpellsDB here - it will be called during ADDON_LOADED in bootstrap
-- DM:LoadDMSpellsDB() -- This line is removed
