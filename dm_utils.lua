--[[
  DotMaster - Utils Module

  File: dm_utils.lua
  Purpose: General utility functions used throughout the addon

  Functions:
  - FormatTime(): Format time in seconds to MM:SS format
  - GetUnitColor(): Get color for a unit
  - Clamp(): Clamp a value between min and max
  - GetTimeLeft(): Get time left on an aura
  - TableContains(): Check if a table contains a value
  - InitializeSlashCommands(): Initialize slash commands

  Dependencies:
  - dm_core.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster -- reference to main addon
local Utils = {}     -- local table for module functions
DM.Utils = Utils     -- expose to addon namespace

-- Format time in seconds to MM:SS format
function Utils:FormatTime(timeInSeconds)
  if not timeInSeconds or timeInSeconds <= 0 then
    return "0:00"
  end

  local minutes = math.floor(timeInSeconds / 60)
  local seconds = math.floor(timeInSeconds % 60)

  return string.format("%d:%02d", minutes, seconds)
end

-- Get color for a unit (player, hostile, etc.)
function Utils:GetUnitColor(unitToken)
  if not unitToken then return { 1, 1, 1 } end

  if UnitIsPlayer(unitToken) then
    local _, class = UnitClass(unitToken)
    local color = RAID_CLASS_COLORS[class]
    return { color.r, color.g, color.b }
  elseif UnitIsFriend("player", unitToken) then
    return { 0, 1, 0 } -- Friendly = green
  else
    return { 1, 0, 0 } -- Hostile = red
  end
end

-- Clamp a value between min and max
function Utils:Clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  else
    return value
  end
end

-- Get time left on an aura
function Utils:GetTimeLeft(expirationTime)
  if not expirationTime or expirationTime == 0 then
    return 0
  end

  local timeLeft = expirationTime - GetTime()
  return timeLeft > 0 and timeLeft or 0
end

-- Check if a table contains a value
function Utils:TableContains(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

-- Set up slash commands
function DM:InitializeSlashCommands()
  -- Register slash commands
  SLASH_DOTMASTER1 = "/dotmaster"
  SLASH_DOTMASTER2 = "/dm"

  SlashCmdList["DOTMASTER"] = function(msg)
    msg = msg:lower():trim()

    if msg == "toggle" then
      DM.enabled = not DM.enabled
      DM:PrintMessage("DotMaster is now " .. (DM.enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))

      -- Update all nameplates
      for unitToken in pairs(DM.activePlates) do
        if DM.enabled then
          DM:UpdateNameplate(unitToken)
        else
          DM:ResetNameplate(unitToken)
        end
      end
    elseif msg == "debug" then
      DM.DEBUG_MODE = not DM.DEBUG_MODE
      DM:PrintMessage("Debug mode is now " .. (DM.DEBUG_MODE and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
    elseif msg == "reset" then
      -- Reset settings to defaults
      DM:ResetSettings()
      DM:PrintMessage("Settings have been reset to defaults")
    elseif msg == "findmydots" or msg == "find" or msg == "fmd" then
      -- Toggle Find My Dots window
      if DM.ToggleFindMyDotsWindow then
        DM:ToggleFindMyDotsWindow()
      else
        DM:PrintMessage("Find My Dots functionality not loaded")
      end
    elseif msg == "help" then
      -- Show help
      DM:PrintMessage("Commands:")
      print("   |cFFCCCCCC/dm|r - Open the configuration panel")
      print("   |cFFCCCCCC/dm toggle|r - Toggle the addon on/off")
      print("   |cFFCCCCCC/dm debug|r - Toggle debug mode")
      print("   |cFFCCCCCC/dm reset|r - Reset settings to defaults")
      print("   |cFFCCCCCC/dm find|r or |cFFCCCCCC/dm fmd|r - Toggle Find My Dots window")
      print("   |cFFCCCCCC/dm help|r - Show this help message")
    else
      -- With no args or unknown command, open the configuration panel
      if DM.OpenConfigPanel then
        DM:OpenConfigPanel()
      else
        DM:PrintMessage("Configuration panel not loaded yet")
      end
    end
  end

  DM:DebugMsg("Slash commands initialized")
end

-- Debug message function improved with module name
function Utils:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[Utils] " .. message)
  end
end

-- Return the module
return Utils
