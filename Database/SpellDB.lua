--[[
    DotMaster - Spell Database Module
    Contains the database of DoT spells for all classes
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Spell database
DotMaster.spellDB = {}

-- Cache for spell information
DotMaster.spellCache = {}

-- Initialize spell database
function DotMaster:InitializeSpellDB()
  -- Create predefined database of DoT spells
  self.spellDB = {
    -- Death Knight
    {
      spellID = 191587,
      name = "Virulent Plague",
      class = "DEATHKNIGHT",
      spec = "Unholy",
      defaultColor = { r = 0.4, g = 0.8, b = 0.2 },
      enabled = true
    },
    {
      spellID = 194310,
      name = "Festering Wound",
      class = "DEATHKNIGHT",
      spec = "Unholy",
      defaultColor = { r = 0.3, g = 0.7, b = 0.3 },
      enabled = true
    },
    {
      spellID = 55078,
      name = "Blood Plague",
      class = "DEATHKNIGHT",
      spec = "Blood",
      defaultColor = { r = 0.8, g = 0.2, b = 0.2 },
      enabled = true
    },
    {
      spellID = 155159,
      name = "Necrotic Plague",
      class = "DEATHKNIGHT",
      spec = "All",
      defaultColor = { r = 0.5, g = 0.5, b = 0.1 },
      enabled = true
    },

    -- Demon Hunter
    {
      spellID = 204598,
      name = "Sigil of Flame",
      class = "DEMONHUNTER",
      spec = "Vengeance",
      defaultColor = { r = 0.9, g = 0.3, b = 0.1 },
      enabled = true
    },
    {
      spellID = 207771,
      name = "Fiery Brand",
      class = "DEMONHUNTER",
      spec = "Vengeance",
      defaultColor = { r = 1.0, g = 0.2, b = 0.2 },
      enabled = true
    },

    -- Druid
    {
      spellID = 164812,
      name = "Moonfire",
      class = "DRUID",
      spec = "Balance",
      defaultColor = { r = 0.5, g = 0.5, b = 1.0 },
      enabled = true
    },
    {
      spellID = 164815,
      name = "Sunfire",
      class = "DRUID",
      spec = "Balance",
      defaultColor = { r = 1.0, g = 0.8, b = 0.0 },
      enabled = true
    },
    {
      spellID = 155722,
      name = "Rake",
      class = "DRUID",
      spec = "Feral",
      defaultColor = { r = 1.0, g = 0.0, b = 0.2 },
      enabled = true
    },
    {
      spellID = 1079,
      name = "Rip",
      class = "DRUID",
      spec = "Feral",
      defaultColor = { r = 1.0, g = 0.1, b = 0.1 },
      enabled = true
    },
    {
      spellID = 155625,
      name = "Thrash",
      class = "DRUID",
      spec = "Guardian",
      defaultColor = { r = 0.7, g = 0.4, b = 0.0 },
      enabled = true
    },

    -- Hunter
    {
      spellID = 217200,
      name = "Barbed Shot",
      class = "HUNTER",
      spec = "Beast Mastery",
      defaultColor = { r = 0.8, g = 0.1, b = 0.3 },
      enabled = true
    },
    {
      spellID = 259491,
      name = "Serpent Sting",
      class = "HUNTER",
      spec = "Survival",
      defaultColor = { r = 0.2, g = 0.8, b = 0.2 },
      enabled = true
    },
    {
      spellID = 271788,
      name = "Serpent Sting",
      class = "HUNTER",
      spec = "Marksmanship",
      defaultColor = { r = 0.2, g = 0.8, b = 0.2 },
      enabled = true
    },

    -- Mage
    {
      spellID = 12654,
      name = "Ignite",
      class = "MAGE",
      spec = "Fire",
      defaultColor = { r = 1.0, g = 0.4, b = 0.0 },
      enabled = true
    },
    {
      spellID = 205708,
      name = "Chilled",
      class = "MAGE",
      spec = "Frost",
      defaultColor = { r = 0.3, g = 0.6, b = 1.0 },
      enabled = true
    },
    {
      spellID = 114923,
      name = "Nether Tempest",
      class = "MAGE",
      spec = "Arcane",
      defaultColor = { r = 0.7, g = 0.3, b = 1.0 },
      enabled = true
    },

    -- Monk
    {
      spellID = 196608,
      name = "Eye of the Tiger",
      class = "MONK",
      spec = "Windwalker",
      defaultColor = { r = 0.0, g = 0.8, b = 0.6 },
      enabled = true
    },

    -- Paladin
    {
      spellID = 197277,
      name = "Judgment",
      class = "PALADIN",
      spec = "Retribution",
      defaultColor = { r = 0.9, g = 0.7, b = 0.0 },
      enabled = true
    },

    -- Priest
    {
      spellID = 589,
      name = "Shadow Word: Pain",
      class = "PRIEST",
      spec = "Shadow",
      defaultColor = { r = 0.8, g = 0.0, b = 1.0 },
      enabled = true
    },
    {
      spellID = 34914,
      name = "Vampiric Touch",
      class = "PRIEST",
      spec = "Shadow",
      defaultColor = { r = 0.6, g = 0.0, b = 0.8 },
      enabled = true
    },
    {
      spellID = 335467,
      name = "Devouring Plague",
      class = "PRIEST",
      spec = "Shadow",
      defaultColor = { r = 0.4, g = 0.0, b = 0.6 },
      enabled = true
    },

    -- Rogue
    {
      spellID = 1943,
      name = "Rupture",
      class = "ROGUE",
      spec = "All",
      defaultColor = { r = 1.0, g = 0.0, b = 0.0 },
      enabled = true
    },
    {
      spellID = 703,
      name = "Garrote",
      class = "ROGUE",
      spec = "Assassination",
      defaultColor = { r = 0.8, g = 0.2, b = 0.2 },
      enabled = true
    },
    {
      spellID = 8680,
      name = "Wound Poison",
      class = "ROGUE",
      spec = "Assassination",
      defaultColor = { r = 0.2, g = 0.7, b = 0.2 },
      enabled = true
    },
    {
      spellID = 2818,
      name = "Deadly Poison",
      class = "ROGUE",
      spec = "Assassination",
      defaultColor = { r = 0.1, g = 0.8, b = 0.1 },
      enabled = true
    },
    {
      spellID = 121411,
      name = "Crimson Tempest",
      class = "ROGUE",
      spec = "Assassination",
      defaultColor = { r = 0.9, g = 0.1, b = 0.1 },
      enabled = true
    },

    -- Shaman
    {
      spellID = 188389,
      name = "Flame Shock",
      class = "SHAMAN",
      spec = "Elemental",
      defaultColor = { r = 1.0, g = 0.4, b = 0.0 },
      enabled = true
    },
    {
      spellID = 197209,
      name = "Lightning Rod",
      class = "SHAMAN",
      spec = "Elemental",
      defaultColor = { r = 0.0, g = 0.6, b = 1.0 },
      enabled = true
    },

    -- Warlock
    {
      spellID = 980,
      name = "Agony",
      class = "WARLOCK",
      spec = "Affliction",
      defaultColor = { r = 0.7, g = 0.0, b = 1.0 },
      enabled = true
    },
    {
      spellID = 146739,
      name = "Corruption",
      class = "WARLOCK",
      spec = "Affliction",
      defaultColor = { r = 0.0, g = 0.8, b = 0.1 },
      enabled = true
    },
    {
      spellID = 32388,
      name = "Shadow Embrace",
      class = "WARLOCK",
      spec = "Affliction",
      defaultColor = { r = 0.4, g = 0.4, b = 0.7 },
      enabled = true
    },
    {
      spellID = 316099,
      name = "Unstable Affliction",
      class = "WARLOCK",
      spec = "Affliction",
      defaultColor = { r = 0.6, g = 0.0, b = 0.8 },
      enabled = true
    },
    {
      spellID = 157736,
      name = "Immolate",
      class = "WARLOCK",
      spec = "Destruction",
      defaultColor = { r = 1.0, g = 0.4, b = 0.0 },
      enabled = true
    },

    -- Warrior
    {
      spellID = 115767,
      name = "Deep Wounds",
      class = "WARRIOR",
      spec = "Arms",
      defaultColor = { r = 1.0, g = 0.0, b = 0.0 },
      enabled = true
    },
    {
      spellID = 772,
      name = "Rend",
      class = "WARRIOR",
      spec = "Arms",
      defaultColor = { r = 0.8, g = 0.2, b = 0.2 },
      enabled = true
    },

    -- Evoker
    {
      spellID = 356995,
      name = "Disintegrate",
      class = "EVOKER",
      spec = "Devastation",
      defaultColor = { r = 0.3, g = 0.6, b = 0.5 },
      enabled = true
    },
    {
      spellID = 355689,
      name = "Burning Ember",
      class = "EVOKER",
      spec = "All",
      defaultColor = { r = 0.8, g = 0.3, b = 0.1 },
      enabled = true
    }
  }

  -- Load user's spell settings from saved variables
  self:LoadSpellSettings()

  -- Clear the spell cache
  self.spellCache = {}

  self:Debug("DATABASE", "Spell database initialized with " .. #self.spellDB .. " spells")
end

-- Load spell settings from saved variables
function DotMaster:LoadSpellSettings()
  if not self.db.profile.spells then
    self.db.profile.spells = {}
  end

  -- Apply saved settings to spell database
  for i, spell in ipairs(self.spellDB) do
    local savedSpell = self.db.profile.spells[spell.spellID]
    if savedSpell then
      -- Apply saved enabled state
      if savedSpell.enabled ~= nil then
        spell.enabled = savedSpell.enabled
      end

      -- Apply saved color if exists
      if savedSpell.color then
        spell.color = savedSpell.color
      end
    end

    -- Ensure spell has a color - use default if not set
    if not spell.color then
      spell.color = CopyTable(spell.defaultColor)
    end
  end
end

-- Save spell settings to saved variables
function DotMaster:SaveSpellSettings()
  if not self.db.profile.spells then
    self.db.profile.spells = {}
  end

  -- Save current settings to database
  for i, spell in ipairs(self.spellDB) do
    self.db.profile.spells[spell.spellID] = {
      enabled = spell.enabled,
      color = spell.color
    }
  end

  self:Debug("DATABASE", "Spell settings saved")
end

-- Reset spell settings to defaults
function DotMaster:ResetSpellSettings()
  for i, spell in ipairs(self.spellDB) do
    spell.enabled = true
    spell.color = CopyTable(spell.defaultColor)
  end

  -- Clear saved settings
  self.db.profile.spells = {}

  -- Save current settings
  self:SaveSpellSettings()

  self:Debug("DATABASE", "Spell settings reset to defaults")
end

-- Get spell information from cache or API
function DotMaster:GetSpellInfo(spellID)
  -- Return cached result if available
  if self.spellCache[spellID] then
    return self.spellCache[spellID]
  end

  -- Get spell info using the correct API
  local spellInfo
  if C_Spell and C_Spell.GetSpellInfo then
    spellInfo = C_Spell.GetSpellInfo(spellID)
  else
    -- Fallback to old API (should never happen in retail)
    local name, _, icon = GetSpellInfo(spellID)
    spellInfo = {
      name = name,
      iconID = icon
    }
    self:Warning("API", "Using deprecated GetSpellInfo API for spell " .. spellID)
  end

  -- Cache the result
  if spellInfo then
    self.spellCache[spellID] = spellInfo
  else
    -- If no spellInfo returned, create a placeholder
    self.spellCache[spellID] = {
      name = "Unknown Spell (" .. spellID .. ")",
      iconID = "Interface\\Icons\\INV_Misc_QuestionMark"
    }
    self:Warning("DATABASE", "Failed to get spell info for ID " .. spellID)
  end

  return self.spellCache[spellID]
end

-- Get spell by ID
function DotMaster:GetSpellByID(spellID)
  for i, spell in ipairs(self.spellDB) do
    if spell.spellID == spellID then
      return spell
    end
  end
  return nil
end

-- Get spells by class
function DotMaster:GetSpellsByClass(class)
  local spells = {}
  for i, spell in ipairs(self.spellDB) do
    if spell.class == class then
      table.insert(spells, spell)
    end
  end
  return spells
end

-- Get enabled spells
function DotMaster:GetEnabledSpells()
  local spells = {}
  for i, spell in ipairs(self.spellDB) do
    if spell.enabled then
      table.insert(spells, spell)
    end
  end
  return spells
end

-- Enable/disable spell
function DotMaster:SetSpellEnabled(spellID, enabled)
  local spell = self:GetSpellByID(spellID)
  if not spell then
    self:Error("DATABASE", "Spell not found: " .. spellID)
    return false
  end

  spell.enabled = enabled

  -- Save settings
  self:SaveSpellSettings()

  self:Debug("DATABASE", "Spell " .. spellID .. " " .. (enabled and "enabled" or "disabled"))
  return true
end

-- Set spell color
function DotMaster:SetSpellColor(spellID, color)
  local spell = self:GetSpellByID(spellID)
  if not spell then
    self:Error("DATABASE", "Spell not found: " .. spellID)
    return false
  end

  spell.color = color

  -- Save settings
  self:SaveSpellSettings()

  self:Debug("DATABASE", "Spell " .. spellID .. " color updated")
  return true
end

-- Search spells by name
function DotMaster:SearchSpells(query)
  if not query or query == "" then
    return self.spellDB
  end

  query = string.lower(query)
  local results = {}

  for i, spell in ipairs(self.spellDB) do
    local spellInfo = self:GetSpellInfo(spell.spellID)
    local name = spellInfo and spellInfo.name or ""

    if string.find(string.lower(name), query) then
      table.insert(results, spell)
    end
  end

  return results
end

-- Check if a spell is a DoT from the enabled list
function DotMaster:IsTrackedDoT(spellID)
  local spell = self:GetSpellByID(spellID)
  return spell and spell.enabled
end

-- Get color for a DoT spell
function DotMaster:GetDoTColor(spellID)
  local spell = self:GetSpellByID(spellID)
  if spell and spell.color then
    return spell.color
  else
    return self.COLORS.WHITE
  end
end
