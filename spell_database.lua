-- DotMaster spell_database.lua (restored legacy backend)
-- Dynamic spell database with automatic detection and classification

local DM = DotMaster

-- Initialize database
DM.spellDatabase = DM.spellDatabase or {}
DM.dmspellsdb = DM.dmspellsdb or {}

-- Function to add a spell to the database
function DM:AddSpellToDatabase(spellID, spellName, spellIcon, className, specName)
  if not spellID or not spellName then return end

  local numericID = tonumber(spellID)
  if not numericID then return end

  DM.spellDatabase[numericID] = {
    spellname = spellName,
    spellicon = spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
    class = className or "UNKNOWN",
    spec = specName or "General",
    lastUsed = GetServerTime(),
    useCount = (DM.spellDatabase[numericID] and DM.spellDatabase[numericID].useCount or 0) + 1
  }
end

-- Function to remove a spell from the database
function DM:RemoveSpellFromDatabase(spellID)
  if not spellID then return end
  DM.spellDatabase[spellID] = nil
end

-- Function to get the full database
function DM:LoadDatabase()
  return DM.spellDatabase or {}
end

-- Function to get settings for populating Database tab
function DM.API:GetSpellDatabase()
  return DM.spellDatabase or {}
end

-- Legacy dmspellsdb functions
function DM:LoadDMSpellsDB()
  if DotMasterDB and DotMasterDB.dmspellsdb then
    DM.dmspellsdb = DotMasterDB.dmspellsdb
  else
    DM.dmspellsdb = {}
  end
end

function DM:SaveDMSpellsDB()
  if not DotMasterDB then DotMasterDB = {} end
  DotMasterDB.dmspellsdb = DM.dmspellsdb
end

function DM:AddSpellToDMSpellsDB(spellID, spellName, spellIcon, className, specName)
  if not spellID or not spellName then return end
  local numericID = tonumber(spellID)
  if not numericID then return end
  DM.dmspellsdb[numericID] = {
    spellname = spellName,
    spellicon = spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
    wowclass = className or "UNKNOWN",
    wowspec = specName or "General",
    color = { 1, 0, 0 },
    priority = 999,
    tracked = 1,
    enabled = 1
  }
  DM:SaveDMSpellsDB()
end

function DM:ResetDMSpellsDB()
  DM.dmspellsdb = {}
  if DotMasterDB then DotMasterDB.dmspellsdb = nil end
end

-- Hook LoadDatabase and tracked spells
