-- DotMaster fonts.lua
-- Font declarations and management for the DotMaster addon

local DM = DotMaster

-- Font path
local EXPRESSWAY_FONT_PATH = "Interface\\AddOns\\DotMaster\\Media\\Fonts\\Expressway.ttf"

-- Create font objects namespace
if not DM then
  error("DotMaster not found when loading fonts.lua")
end

DM.Fonts = {}

-- Function to create font objects
local function CreateFontObjects()
  -- Create font objects for different sizes and styles

  -- Large fonts (equivalent to GameFontNormalLarge)
  DM.Fonts.ExpresswayLarge = CreateFont("DotMaster_ExpresswayLarge")
  DM.Fonts.ExpresswayLarge:SetFont(EXPRESSWAY_FONT_PATH, 16, "OUTLINE")
  DM.Fonts.ExpresswayLarge:SetTextColor(1, 1, 1, 1)

  -- Normal fonts (equivalent to GameFontNormal)
  DM.Fonts.ExpresswayNormal = CreateFont("DotMaster_ExpresswayNormal")
  DM.Fonts.ExpresswayNormal:SetFont(EXPRESSWAY_FONT_PATH, 12, "OUTLINE")
  DM.Fonts.ExpresswayNormal:SetTextColor(1, 1, 1, 1)

  -- Small fonts (equivalent to GameFontNormalSmall)
  DM.Fonts.ExpresswaySmall = CreateFont("DotMaster_ExpresswaySmall")
  DM.Fonts.ExpresswaySmall:SetFont(EXPRESSWAY_FONT_PATH, 10, "OUTLINE")
  DM.Fonts.ExpresswaySmall:SetTextColor(1, 1, 1, 1)

  -- Highlight fonts (equivalent to GameFontHighlight)
  DM.Fonts.ExpresswayHighlight = CreateFont("DotMaster_ExpresswayHighlight")
  DM.Fonts.ExpresswayHighlight:SetFont(EXPRESSWAY_FONT_PATH, 12, "OUTLINE")
  DM.Fonts.ExpresswayHighlight:SetTextColor(1, 1, 1, 1)

  -- Highlight small fonts (equivalent to GameFontHighlightSmall)
  DM.Fonts.ExpresswayHighlightSmall = CreateFont("DotMaster_ExpresswayHighlightSmall")
  DM.Fonts.ExpresswayHighlightSmall:SetFont(EXPRESSWAY_FONT_PATH, 10, "OUTLINE")
  DM.Fonts.ExpresswayHighlightSmall:SetTextColor(1, 1, 1, 1)

  -- Disable fonts (equivalent to GameFontDisable)
  DM.Fonts.ExpresswayDisable = CreateFont("DotMaster_ExpresswayDisable")
  DM.Fonts.ExpresswayDisable:SetFont(EXPRESSWAY_FONT_PATH, 12, "OUTLINE")
  DM.Fonts.ExpresswayDisable:SetTextColor(0.5, 0.5, 0.5, 1)

  -- Disable small fonts (equivalent to GameFontDisableSmall)
  DM.Fonts.ExpresswayDisableSmall = CreateFont("DotMaster_ExpresswayDisableSmall")
  DM.Fonts.ExpresswayDisableSmall:SetFont(EXPRESSWAY_FONT_PATH, 10, "OUTLINE")
  DM.Fonts.ExpresswayDisableSmall:SetTextColor(0.5, 0.5, 0.5, 1)
end

-- Font mapping table for easy replacement
DM.FontMapping = {
  ["GameFontNormalLarge"] = "DotMaster_ExpresswayLarge",
  ["GameFontNormal"] = "DotMaster_ExpresswayNormal",
  ["GameFontNormalSmall"] = "DotMaster_ExpresswaySmall",
  ["GameFontHighlight"] = "DotMaster_ExpresswayHighlight",
  ["GameFontHighlightSmall"] = "DotMaster_ExpresswayHighlightSmall",
  ["GameFontHighlightLarge"] = "DotMaster_ExpresswayLarge",
  ["GameFontDisable"] = "DotMaster_ExpresswayDisable",
  ["GameFontDisableSmall"] = "DotMaster_ExpresswayDisableSmall"
}

-- Function to get the Expressway equivalent of a GameFont
function DM:GetExpresswayFont(gameFontName)
  return DM.FontMapping[gameFontName] or "DotMaster_ExpresswayNormal"
end

-- Function to apply font to a font string
function DM:ApplyExpresswayFont(fontString, gameFontName)
  if fontString and fontString.SetFontObject then
    local expresswayFont = DM:GetExpresswayFont(gameFontName)
    fontString:SetFontObject(expresswayFont)
  end
end

-- Initialize fonts when the addon loads
function DM:InitializeFonts()
  if DM.Fonts.ExpresswayLarge then
    DM:DebugMsg("DotMaster fonts already initialized")
    return
  end

  CreateFontObjects()
  DM:DebugMsg("DotMaster fonts initialized with Expressway font")
end

-- Initialize fonts immediately
DM:InitializeFonts()
