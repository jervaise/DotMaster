-- DotMaster by Jervaise
-- Main initialization file (init.lua)

local DM = DotMaster

-- Constants
DM.VIRULENT_PLAGUE_ID = 191587
DM.DEFAULT_PURPLE_COLOR = { 0.6, 0.2, 1.0 }
DM.MAX_CUSTOM_SPELLS = 20

-- Setup basic variables (if not already set in bootstrap)
DM.activePlates = DM.activePlates or {}
DM.coloredPlates = DM.coloredPlates or {}
DM.originalColors = DM.originalColors or {}
DM.GUI = DM.GUI or {}
DM.recordingDots = DM.recordingDots or false
DM.detectedDots = DM.detectedDots or {}

-- Enhanced defaults (extending bootstrap defaults)
DM.defaults = DM.defaults or {}
DM.defaults.lastSortOrder = 1 -- Added for sorting functionality

-- Set remaining debug categories if not set in bootstrap
if not DM.DEBUG_CATEGORIES.nameplate then
  DM.DEBUG_CATEGORIES.nameplate = false
end
if not DM.DEBUG_CATEGORIES.spell then
  DM.DEBUG_CATEGORIES.spell = false
end
if not DM.DEBUG_CATEGORIES.gui then
  DM.DEBUG_CATEGORIES.gui = false
end
if not DM.DEBUG_CATEGORIES.performance then
  DM.DEBUG_CATEGORIES.performance = false
end
if not DM.DEBUG_CATEGORIES.colorpicker then
  DM.DEBUG_CATEGORIES.colorpicker = true
end

-- Create Components namespace if it doesn't exist
if not DotMaster_Components then
  DotMaster_Components = {}
end

-- Legacy initialization function (now coordinated via the bootstrap events)
function DM:Initialize()
  DM:DebugMsg("Legacy Initialize() called - this is now managed by bootstrap.lua")
  DM:DebugMsg("Current initialization state: " .. (DM.initState or "unknown"))

  -- Provide backward compatibility for any code still calling this function
  -- No core functionality should be here anymore
end

-- Modify PrintMessage to respect DEBUG_CATEGORIES.general
function DM:PrintMessage(message, ...)
  if not DM.DEBUG_CATEGORIES.general then return end
  local prefix = "|cFFCC00FFDotMaster:|r "
  if select('#', ...) > 0 then
    DM:DebugMsg(prefix .. message, ...)
  else
    DM:DebugMsg(prefix .. message)
  end
end
