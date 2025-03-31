--[[
    DotMaster - Constants
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Debug Levels
DotMaster.DEBUG_LEVELS = {
  ERROR = 1,
  WARNING = 2,
  INFO = 3,
  DEBUG = 4,
  TRACE = 5
}

-- Debug Categories
DotMaster.DEBUG_CATEGORIES = {
  CORE = "CORE",
  NAMEPLATE = "NAMEPLATE",
  DOT = "DOT",
  GUI = "GUI",
  DATABASE = "DATABASE",
  PROFILE = "PROFILE",
  PERFORMANCE = "PERFORMANCE",
  API = "API",
  EVENTS = "EVENTS",
  COMBAT = "COMBAT",
  CONFIG = "CONFIG",
  CUSTOM = "CUSTOM"
}

-- Nameplate Positions
DotMaster.NAMEPLATE_POSITIONS = {
  TOP = "TOP",
  BOTTOM = "BOTTOM",
  LEFT = "LEFT",
  RIGHT = "RIGHT",
  TOPLEFT = "TOPLEFT",
  TOPRIGHT = "TOPRIGHT",
  BOTTOMLEFT = "BOTTOMLEFT",
  BOTTOMRIGHT = "BOTTOMRIGHT",
  CENTER = "CENTER"
}

-- Colors
DotMaster.COLORS = {
  -- Common colors
  RED = { r = 1, g = 0, b = 0 },
  GREEN = { r = 0, g = 1, b = 0 },
  BLUE = { r = 0, g = 0, b = 1 },
  YELLOW = { r = 1, g = 1, b = 0 },
  PURPLE = { r = 1, g = 0, b = 1 },
  CYAN = { r = 0, g = 1, b = 1 },
  WHITE = { r = 1, g = 1, b = 1 },
  BLACK = { r = 0, g = 0, b = 0 },
  ORANGE = { r = 1, g = 0.5, b = 0 },

  -- Class colors (for reference)
  DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
  DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
  DRUID = { r = 1.00, g = 0.49, b = 0.04 },
  EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
  HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
  MAGE = { r = 0.41, g = 0.80, b = 0.94 },
  MONK = { r = 0.00, g = 1.00, b = 0.59 },
  PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
  PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
  ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
  SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
  WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
  WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }
}

-- Performance constants
DotMaster.PERFORMANCE = {
  COMBAT_SCAN_THROTTLE = 0.1,
  NORMAL_SCAN_THROTTLE = 0.2,
  MAX_DEBUG_LOG_SIZE = 1000,
  ANIMATION_REFRESH_RATE = 0.03
}

-- Utility functions
function DotMaster.ColorToHex(color)
  return string.format("|cff%02x%02x%02x",
    math.floor(color.r * 255),
    math.floor(color.g * 255),
    math.floor(color.b * 255)
  )
end
