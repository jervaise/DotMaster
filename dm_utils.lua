--[[
  DotMaster - Utilities Module

  File: dm_utils.lua
  Purpose: Common utilities and helper functions

  Functions:
  - DebugMsg(): Print a debug message
  - SpellDebug(): Print a spell-specific debug message
  - PrintMessage(): Print an addon message
  - TableCount(): Count table entries
  - DeepCopy(): Deep copy a table
  - SpellExists(): Check if a spell ID exists in the spell config
  - ParseSpellIDs(): Parse spell IDs from a string
  - RGBToHex(): Convert RGB to hex color code
  - GetContrastColor(): Get contrasting text color
  - AdjustBrightness(): Create a brightened/darkened version of a color
  - SetDefaultPriorities(): Set default priorities based on current order
  - GetMaxPriority(): Get max priority value
  - GetNextPriority(): Get next available priority value

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local Utils = {} -- Local table for module functions
DM.Utils = Utils -- Expose to addon namespace

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

-- Slash commands processing
function DM:InitializeSlashCommands()
  -- Register slash commands
  SLASH_DOTMASTER1 = "/dotmaster"
  SLASH_DOTMASTER2 = "/dm"

  -- Handle slash commands
  SlashCmdList["DOTMASTER"] = function(msg)
    -- Get command and arguments
    local command, rest = strsplit(" ", msg, 2)
    command = command:lower()

    -- Parse command
    if command == "toggle" or command == "t" then
      -- Toggle addon on/off
      DM.enabled = not DM.enabled
      DM:PrintMessage(DM.enabled and "Enabled" or "Disabled")
      if DM.enabled then
        DM:UpdateAllNameplates()
      else
        DM:ResetAllNameplates()
      end
      DM:SaveSettings()
    elseif command == "debug" then
      -- Toggle debug mode
      DM.DEBUG_MODE = not DM.DEBUG_MODE
      DM:PrintMessage("Debug Mode " .. (DM.DEBUG_MODE and "Enabled" or "Disabled"))
      DM:SaveSettings()
    elseif command == "find" or command == "fmd" then
      -- Toggle Find My Dots window
      if DM.ToggleFindMyDotsWindow then
        DM:ToggleFindMyDotsWindow()
      else
        DM:PrintMessage("Find My Dots functionality not loaded")
      end
    elseif command == "reset" then
      -- Reset to defaults
      DM:ResetSettings()
      DM:PrintMessage("Settings reset to defaults")
    elseif command == "help" or command == "?" or command == "" then
      -- Display help
      print("|cFFCC00FFDotMaster|r commands:")
      print("   |cFFCCCCCC/dm|r or |cFFCCCCCC/dotmaster|r - Open configuration")
      print("   |cFFCCCCCC/dm toggle|r or |cFFCCCCCC/dm t|r - Toggle addon on/off")
      print("   |cFFCCCCCC/dm find|r or |cFFCCCCCC/dm fmd|r - Toggle Find My Dots window")
      print("   |cFFCCCCCC/dm debug|r - Toggle debug mode")
      print("   |cFFCCCCCC/dm reset|r - Reset settings to defaults")
      print("   |cFFCCCCCC/dm help|r - Show this help")
    else
      -- Default: open GUI
      if DM.OpenConfigGUI then
        DM:OpenConfigGUI()
      else
        DM:PrintMessage("GUI functionality not loaded")
      end
    end
  end

  DM:DebugMsg("Slash commands initialized")
end

-- Initialize the utils module
function Utils:Initialize()
  DM:DebugMsg("Utils module initialized")
end

-- Return the module
return Utils
