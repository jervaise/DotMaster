-- DotMaster gui_spell_row.lua
-- Contains spell configuration row functionality

local DM = DotMaster

-- FontString helper functions
local DMFontStringHelper = {}

-- Helper function to update text with truncation
function DMFontStringHelper.UpdateText(self, text)
  if not text then return end
  local font, size, flags = self:GetFont()
  if not font then return end

  self:SetText(text)
  -- Add ellipsis if text is too long for the field width
  if self:GetStringWidth() > self:GetWidth() then
    local truncated = text
    while self:GetStringWidth() > (self:GetWidth() - 10) and truncated:len() > 1 do
      truncated = truncated:sub(1, -2)
      self:SetText(truncated .. "...")
    end
  end
end

-- Create a row for spell configuration
function DM:CreateSpellConfigRow(spellIDStr, index, yOffset)
  -- Ensure scroll child exists
  if not DM.GUI.scrollChild then
    DM:DebugMsg("scrollChild not found in CreateSpellConfigRow", "gui")
    return nil
  end

  -- Fetch the config from dmspellsdb using the string ID
  local config = DM.dmspellsdb and DM.dmspellsdb[spellIDStr]
  if not config then
    DM:DebugMsg(string.format("Config not found in dmspellsdb for spell ID: %s", spellIDStr), "error")
    return nil
  end

  -- Basic frame creation
  local PADDING = DM.GUI.layout and DM.GUI.layout.padding or { INNER = 8 }
  local scrollChild = DM.GUI.scrollChild
  local spellRow = CreateFrame("Frame", "DotMasterSpellRow" .. index, scrollChild)

  local rowWidth = math.max((scrollChild:GetWidth() - (PADDING.INNER * 2)), 420)
  local rowHeight = 36 -- Define row height
  spellRow:SetSize(rowWidth, rowHeight)
  spellRow:SetPoint("TOPLEFT", PADDING.INNER, -yOffset)
  spellRow.spellID = spellIDStr -- Store the spellID (string) reference

  -- Basic background
  local bg = spellRow:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  if index % 2 == 0 then
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5) -- Darker
  else
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- Lighter
  end

  -- TODO: Add highlight on hover later

  -- Basic Spell ID Text
  local idText = spellRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  idText:SetPoint("LEFT", 40, 0) -- Position slightly indented
  idText:SetText(spellIDStr or "N/A")

  -- Basic Spell Name Text
  local nameText = spellRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nameText:SetPoint("LEFT", 110, 0) -- Position after ID
  nameText:SetWidth(150)            -- Give it some width
  nameText:SetJustifyH("LEFT")
  nameText:SetText(config.spellname or "Unknown Name")

  DM:DebugMsg(string.format("Created basic row %d for spell %s (%s)", index, spellIDStr, config.spellname or "?"), "gui")

  return spellRow -- Return the created frame
end
