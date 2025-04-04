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

-- Initialize empty debug categories to disable all debug functionality
DM.DEBUG_CATEGORIES = DM.DEBUG_CATEGORIES or {
  general = false,
  nameplate = false,
  spell = false,
  gui = false,
  performance = false,
  colorpicker = false
}

-- Create Components namespace if it doesn't exist
if not DotMaster_Components then
  DotMaster_Components = {}
end

-- Legacy initialization function (now coordinated via the bootstrap events)
function DM:Initialize()
  -- No core functionality should be here anymore
  -- This is just for backward compatibility
end

-- Basic message print function
function DM:PrintMessage(message, ...)
  local prefix = "|cFFCC00FFDotMaster:|r "
  if select('#', ...) > 0 then
    print(prefix .. string.format(message, ...))
  else
    print(prefix .. message)
  end
end

-- Empty debug functions to maintain compatibility with existing code
function DM:DebugMsg(message, ...)
  -- Debug output disabled
end

-- Empty category-specific debug functions
function DM:ColorPickerDebug(message, ...)
  -- Debug output disabled
end

function DM:NameplateDebug(message, ...)
  -- Debug output disabled
end

function DM:GUIDebug(message, ...)
  -- Debug output disabled
end

function DM:DatabaseDebug(message, ...)
  -- Debug output disabled
end
