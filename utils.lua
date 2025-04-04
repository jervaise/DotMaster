-- DotMaster utils.lua
-- Utility functions for the addon

local DM = DotMaster

-- Simple print function
function DM:PrintMessage(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Deep copy function for tables
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

-- Count entries in a table
function DM:TableCount(t)
  if not t or type(t) ~= "table" then
    return 0
  end
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- Determine the most appropriate color for text based on the background color
function DM:GetReadableTextColor(r, g, b)
  -- Calculate luminance (formula for perceived brightness)
  local luminance = 0.299 * r + 0.587 * g + 0.114 * b

  -- If the background is dark, use white text; otherwise use black text
  if luminance < 0.5 then
    return 1, 1, 1 -- White
  else
    return 0, 0, 0 -- Black
  end
end

-- Utility function to round numbers
function DM:Round(num, decimalPlaces)
  local mult = 10 ^ (decimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Utility function to get player class color
function DM:GetClassColor()
  -- Get player's class
  local _, playerClass = UnitClass("player")

  -- Use standard class colors
  local classColors = {
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
    EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
  }

  -- Return the color object for the player's class, or a default color
  if classColors[playerClass] then
    return classColors[playerClass].r, classColors[playerClass].g, classColors[playerClass].b
  else
    return 0.5, 0.5, 0.5 -- Default gray if class not found
  end
end

-- Utility function to convert hex color to RGB
function DM:HexToRGB(hex)
  hex = hex:gsub("#", "")
  if hex:len() == 3 then
    return tonumber("0x" .. hex:sub(1, 1)) / 15,
        tonumber("0x" .. hex:sub(2, 2)) / 15,
        tonumber("0x" .. hex:sub(3, 3)) / 15
  elseif hex:len() == 6 then
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
  end
  return 1, 1, 1 -- Default white
end

-- Utility function to convert RGB to hex
function DM:RGBToHex(r, g, b)
  r = math.floor(r * 255 + 0.5)
  g = math.floor(g * 255 + 0.5)
  b = math.floor(b * 255 + 0.5)
  return string.format("#%02x%02x%02x", r, g, b)
end
