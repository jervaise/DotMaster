-- DotMaster utils.lua
-- Common utilities and helper functions

local DM = DotMaster

-- Debug Functions
-- --------------------------------------------

-- General debug message function
function DM:DebugMsg(message, ...)
  if not self.DEBUG_MODE then return end

  local prefix = "|cFFCC00FFDotMaster Debug:|r "
  if select('#', ...) > 0 then
    print(prefix .. message, ...)
  else
    print(prefix .. message)
  end
end

-- Spell-specific debug function
function DM:SpellDebug(message, ...)
  if not self.DEBUG_MODE then return end

  local prefix = "|cFFFF00FFDM Debug:|r "
  if select('#', ...) > 0 then
    print(prefix .. message, ...)
  else
    print(prefix .. message)
  end
end

-- Print addon message (without debug restriction)
function DM:PrintMessage(message, ...)
  local prefix = "|cFFCC00FFDotMaster:|r "
  if select('#', ...) > 0 then
    print(prefix .. message, ...)
  else
    print(prefix .. message)
  end
end

-- Table & Data Helpers
-- --------------------------------------------

-- Count table entries
function DM:TableCount(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

-- Deep copy a table
function DM:DeepCopy(original)
  local copy
  if type(original) == "table" then
    copy = {}
    for k, v in pairs(original) do
      if type(v) == "table" then
        copy[k] = self:DeepCopy(v)
      else
        copy[k] = v
      end
    end
  else
    copy = original
  end
  return copy
end

-- Check if a spell ID exists in the spell config
function DM:SpellExists(spellID)
  -- Convert to number for comparison if needed
  local numericID = tonumber(spellID)
  if not numericID then return false end

  -- Check each spell config
  for existingID, _ in pairs(self.spellConfig) do
    -- Direct ID match
    if tonumber(existingID) == numericID then
      return true
    end
  end

  return false
end

-- Parse spell ID from a string
function DM:ParseSpellIDs(spellIDString)
  return { tonumber(spellIDString) }
end

-- Color Utilities
-- --------------------------------------------

-- Convert RGB (0-1) to hex color code
function DM:RGBToHex(r, g, b)
  return string.format("|cFF%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- Get contrasting text color (black or white) based on background
function DM:GetContrastColor(r, g, b)
  -- Calculate luminance using standard formula
  local luminance = 0.299 * r + 0.587 * g + 0.114 * b

  -- Return white for dark backgrounds, black for light
  if luminance < 0.5 then
    return 1, 1, 1 -- white
  else
    return 0, 0, 0 -- black
  end
end

-- Create a brightened/darkened version of a color
function DM:AdjustBrightness(r, g, b, factor)
  return math.min(r * factor, 1),
      math.min(g * factor, 1),
      math.min(b * factor, 1)
end

-- Priority Management Functions
-- --------------------------------------------

-- Set default priorities based on current order
function DM:SetDefaultPriorities()
  local priority = 1
  -- Loop through existing spell config rows in current display order
  if self.GUI.spellFrames then
    for _, frame in ipairs(self.GUI.spellFrames) do
      if frame.spellID and self.spellConfig[frame.spellID] then
        self.spellConfig[frame.spellID].priority = priority
        priority = priority + 1
      end
    end
  end

  -- If no frames exist yet, iterate through spellConfig directly
  if priority == 1 then
    for spellID, _ in pairs(self.spellConfig) do
      self.spellConfig[spellID].priority = priority
      priority = priority + 1
    end
  end

  self.lastSortOrder = priority - 1
end

-- Get max priority value from current spell configs
function DM:GetMaxPriority()
  local maxPriority = 0
  for _, config in pairs(self.spellConfig) do
    if config.priority and config.priority > maxPriority then
      maxPriority = config.priority
    end
  end
  return maxPriority
end

-- Get next available priority value
function DM:GetNextPriority()
  local maxPriority = self:GetMaxPriority()
  return maxPriority + 1
end
