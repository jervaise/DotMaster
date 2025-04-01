--[[
  DotMaster - Spell Database Module

  File: sp_database.lua
  Purpose: Dynamic spell database with automatic detection and classification

  Functions:
  - AddSpellToDatabase(): Add a spell to the database
  - GetSpellsForClass(): Get all spells for a class
  - GetSpellsForSpec(): Get all spells for a spec
  - SearchSpellsByName(): Search for spells by name
  - SaveSpellDatabase(): Save database to SavedVariables
  - LoadSpellDatabase(): Load database from SavedVariables
  - CleanupSpellDatabase(): Clean up database (remove old entries)

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local SpellDB = {}   -- Local table for module functions
DM.SpellDB = SpellDB -- Expose to addon namespace

-- Initialize database
DM.spellDatabase = {}
DM.MAX_DATABASE_SIZE = 500

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
function SpellDB:AddSpellToDatabase(spellID, spellName, className, specName)
  -- Check parameters
  if not spellID or not spellName then return end

  -- Convert to number
  spellID = tonumber(spellID)
  if not spellID then return end

  -- Initialize database if needed
  if not DM.spellDatabase then DM.spellDatabase = {} end

  -- Update or add entry
  if not DM.spellDatabase[spellID] then
    -- Check if we're at capacity
    local databaseSize = DM:TableCount(DM.spellDatabase)
    if databaseSize >= DM.MAX_DATABASE_SIZE then
      -- We're at capacity, might need to clean up
      -- For now, just don't add any more
      return
    end

    -- Add new entry
    DM.spellDatabase[spellID] = {
      name = spellName,
      class = className or "UNKNOWN",
      spec = specName or "General",
      firstSeen = GetServerTime(),
      lastUsed = GetServerTime(),
      useCount = 1
    }
  else
    -- Update existing entry
    DM.spellDatabase[spellID].lastUsed = GetServerTime()
    DM.spellDatabase[spellID].useCount = (DM.spellDatabase[spellID].useCount or 0) + 1

    -- Update name if provided
    if spellName and spellName ~= "" and spellName ~= "Unknown" then
      DM.spellDatabase[spellID].name = spellName
    end

    -- Update class/spec if provided
    if className and className ~= "" and className ~= "UNKNOWN" then
      DM.spellDatabase[spellID].class = className
    end

    if specName and specName ~= "" and specName ~= "General" then
      DM.spellDatabase[spellID].spec = specName
    end
  end

  -- Update legacy SpellNames table
  DM.SpellNames[spellID] = spellName
end

-- Function to get all spells for a class
function SpellDB:GetSpellsForClass(className)
  if not DM.spellDatabase then return {} end

  local spells = {}
  for id, spellData in pairs(DM.spellDatabase) do
    if not className or className == "ALL" or spellData.class == className then
      spells[id] = spellData
    end
  end

  return spells
end

-- Function to get all spells for a spec
function SpellDB:GetSpellsForSpec(className, specName)
  if not DM.spellDatabase then return {} end

  local spells = {}
  for id, spellData in pairs(DM.spellDatabase) do
    if (not className or className == "ALL" or spellData.class == className) and
        (not specName or specName == "ALL" or spellData.spec == specName) then
      spells[id] = spellData
    end
  end

  return spells
end

-- Function to search for spells by name
function SpellDB:SearchSpellsByName(searchText)
  if not DM.spellDatabase then return {} end
  if not searchText or searchText == "" or searchText == "Search..." then return DM.spellDatabase end

  local results = {}
  searchText = searchText:lower()

  for id, spellData in pairs(DM.spellDatabase) do
    if spellData.name and spellData.name:lower():find(searchText) then
      results[id] = spellData
    end
  end

  return results
end

-- Function to save database
function SpellDB:SaveSpellDatabase()
  -- Save to SavedVariables
  if not DotMasterDB then DotMasterDB = {} end
  DotMasterDB.spellDatabase = DM.spellDatabase

  -- Also update legacy SpellNames
  DotMasterDB.SpellNames = DM.SpellNames
end

-- Function to load database
function SpellDB:LoadSpellDatabase()
  -- Load from SavedVariables
  if DotMasterDB and DotMasterDB.spellDatabase then
    DM.spellDatabase = DotMasterDB.spellDatabase
  end

  -- Also load legacy SpellNames for compatibility
  if DotMasterDB and DotMasterDB.SpellNames then
    DM.SpellNames = DotMasterDB.SpellNames
  end

  -- Update legacy SpellNames from database for consistency
  if DM.spellDatabase then
    for id, spellData in pairs(DM.spellDatabase) do
      DM.SpellNames[id] = spellData.name
    end
  end
end

-- Function to clean up database (remove old entries)
function SpellDB:CleanupSpellDatabase()
  if not DM.spellDatabase then return end

  local databaseSize = DM:TableCount(DM.spellDatabase)
  if databaseSize <= DM.MAX_DATABASE_SIZE then return end

  -- Sort by last used time
  local spellsToSort = {}
  for id, data in pairs(DM.spellDatabase) do
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
  local toRemove = databaseSize - DM.MAX_DATABASE_SIZE
  for i = 1, toRemove do
    if i <= #spellsToSort then
      local id = spellsToSort[i].id
      DM.spellDatabase[id] = nil
      -- Also update legacy SpellNames
      DM.SpellNames[id] = nil
    end
  end
end

-- Debug message function with module name
function SpellDB:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[SpellDB] " .. message)
  end
end

-- Initialize the spell database module
function SpellDB:Initialize()
  -- Connect to the DM namespace for backward compatibility
  DM.AddSpellToDatabase = function(self, ...) SpellDB:AddSpellToDatabase(...) end
  DM.GetSpellsForClass = function(self, ...) return SpellDB:GetSpellsForClass(...) end
  DM.GetSpellsForSpec = function(self, ...) return SpellDB:GetSpellsForSpec(...) end
  DM.SearchSpellsByName = function(self, ...) return SpellDB:SearchSpellsByName(...) end
  DM.SaveSpellDatabase = function(self) SpellDB:SaveSpellDatabase() end
  DM.LoadSpellDatabase = function(self) SpellDB:LoadSpellDatabase() end
  DM.CleanupSpellDatabase = function(self) SpellDB:CleanupSpellDatabase() end

  SpellDB:DebugMsg("Spell database module initialized")
  SpellDB:LoadSpellDatabase()
end

-- Return the module
return SpellDB
