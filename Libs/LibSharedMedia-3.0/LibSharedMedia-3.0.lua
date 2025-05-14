--[[
LibSharedMedia-3.0.lua
Provides registration and access to media stored by multiple addons.
]]

local MAJOR, MINOR = "LibSharedMedia-3.0", 90000 + 300 -- Matches 9.0.0 and minor version 300
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end                             -- No upgrade needed

local _G = getfenv(0)

lib.MediaType = {
  BACKGROUND = "background",
  BORDER = "border",
  FONT = "font",
  SOUND = "sound",
  STATUSBAR = "statusbar",
}

lib.MediaTable = {
  background = {},
  border = {},
  font = {},
  sound = {},
  statusbar = {},
}

local DefaultMedia = {
  background = {
    ["Blizzard Dialog Background"] = [[Interface\DialogFrame\UI-DialogBox-Background]],
    ["Blizzard Low Health"] = [[Interface\FullScreenTextures\LowHealth]],
    ["Blizzard Marble"] = [[Interface\FrameGeneral\UI-Background-Marble]],
    ["Blizzard Out of Control"] = [[Interface\FullScreenTextures\OutOfControl]],
    ["Blizzard Parchment"] = [[Interface\AchievementFrame\UI-Achievement-Parchment-Horizontal]],
    ["Blizzard Rock"] = [[Interface\FrameGeneral\UI-Background-Rock]],
    ["Blizzard Tabard Background"] = [[Interface\TabardFrame\TabardFrameBackground]],
    ["Solid"] = [[Interface\Buttons\WHITE8X8]],
    ["Transparent"] = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
  },
  border = {
    ["None"] = [[Interface\None]],
    ["Blizzard Dialog"] = [[Interface\DialogFrame\UI-DialogBox-Border]],
    ["Blizzard Dialog Gold"] = [[Interface\DialogFrame\UI-DialogBox-Gold-Border]],
    ["Blizzard Toast"] = [[Interface\AchievementFrame\UI-Achievement-Toast-Border]],
    ["Solid"] = [[Interface\Buttons\WHITE8X8]],
  },
  font = {
    ["Arial Narrow"] = [[Fonts\ARIALN.TTF]],
    ["Friz Quadrata TT"] = [[Fonts\FRIZQT__.TTF]],
    ["Morpheus"] = [[Fonts\MORPHEUS.TTF]],
    ["Skurri"] = [[Fonts\SKURRI.TTF]],
  },
  sound = {
    ["None"] = [[Interface\None]],
  },
  statusbar = {
    ["Blizzard"] = [[Interface\TargetingFrame\UI-StatusBar]],
    ["Blizzard Character Skills Bar"] = [[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]],
    ["Solid"] = [[Interface\Buttons\WHITE8X8]],
  },
}

-- Register default media
for mediatype, mediatable in pairs(DefaultMedia) do
  for name, mediapath in pairs(mediatable) do
    lib:Register(mediatype, name, mediapath)
  end
end

-- Register function to allow addons to register media
function lib:Register(mediatype, name, mediapath)
  if not mediatype or not name or not mediapath then return end

  mediatype = mediatype:lower()
  if not lib.MediaTable[mediatype] then return end

  lib.MediaTable[mediatype][name] = mediapath
  return true
end

-- Fetch function to allow addons to retrieve media
function lib:Fetch(mediatype, name)
  if not mediatype or not name then return end

  mediatype = mediatype:lower()
  if not lib.MediaTable[mediatype] then return end

  return lib.MediaTable[mediatype][name]
end
