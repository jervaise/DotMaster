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
function DM:CreateSpellConfigRow(spellID, index, yOffset)
  -- Ensure scroll child exists
  if not DM.GUI.scrollChild then
    DM:GUIDebug("scrollChild not found in CreateSpellConfigRow")
    return nil
  end

  -- Make sure spellID is numeric
  local numericID = tonumber(spellID)
  if not numericID then
    DM:DatabaseDebug(string.format("Invalid non-numeric spell ID: %s", tostring(spellID)))
    return nil
  end

  -- Fetch the config from dmspellsdb
  local config = DM.dmspellsdb and DM.dmspellsdb[numericID]
  if not config then
    DM:DatabaseDebug(string.format("Config not found in dmspellsdb for spell ID: %d", numericID))
    return nil
  end

  -- Get layout info
  local LAYOUT = DM.GUI.layout
  if not LAYOUT then
    DM:GUIDebug("Layout information not found in CreateSpellConfigRow")
    return nil
  end

  local COLUMN_POSITIONS = LAYOUT.columns
  local COLUMN_WIDTHS = LAYOUT.widths
  local PADDING = LAYOUT.padding

  -- Basic frame creation
  local scrollChild = DM.GUI.scrollChild
  local spellRow = CreateFrame("Frame", "DotMasterSpellRow" .. index, scrollChild)

  local rowWidth = math.max((scrollChild:GetWidth() - (PADDING.INNER * 2)), 420)
  local rowHeight = 36 -- Define row height
  spellRow:SetSize(rowWidth, rowHeight)
  spellRow:SetPoint("TOPLEFT", PADDING.INNER, -yOffset)
  spellRow.spellID = numericID -- Store the spellID (numeric) reference

  -- Basic background
  local bg = spellRow:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  if index % 2 == 0 then
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5) -- Darker
  else
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- Lighter
  end

  -- Highlight on hover
  local highlight = spellRow:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
  highlight:SetBlendMode("ADD")

  -- Enable/Disable Checkbox
  local enableCheckbox = CreateFrame("CheckButton", nil, spellRow, "UICheckButtonTemplate")
  enableCheckbox:SetSize(24, 24)
  enableCheckbox:SetPoint("LEFT", COLUMN_POSITIONS.ON, 0)
  enableCheckbox:SetChecked(config.enabled == 1)

  enableCheckbox:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    DM:DatabaseDebug(string.format("Updating enabled status for %d to %s", numericID, tostring(isChecked)))
    DM.dmspellsdb[numericID].enabled = isChecked and 1 or 0

    -- Save the changes
    DM:SaveDMSpellsDB()
  end)

  -- Spell Icon
  local iconSize = 24
  local iconFrame = CreateFrame("Frame", nil, spellRow)
  iconFrame:SetSize(iconSize, iconSize)
  iconFrame:SetPoint("LEFT", COLUMN_POSITIONS.ID, 0)

  local icon = iconFrame:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()
  icon:SetTexture(config.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

  -- Spell ID Text
  local idText = spellRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  idText:SetPoint("LEFT", iconFrame, "RIGHT", 5, 0)
  idText:SetWidth(40)
  idText:SetJustifyH("LEFT")
  idText:SetText(numericID)

  -- Spell Name Text
  local nameText = spellRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nameText:SetPoint("LEFT", COLUMN_POSITIONS.NAME, 0)
  nameText:SetWidth(COLUMN_WIDTHS.NAME)
  nameText:SetJustifyH("LEFT")
  nameText:SetText(config.spellname or "Unknown Name")

  -- Add helper function to nameText
  nameText.UpdateText = DMFontStringHelper.UpdateText
  nameText:UpdateText(config.spellname or "Unknown Name")

  -- Color Button
  local colorButton = CreateFrame("Button", nil, spellRow)
  colorButton:SetSize(24, 24)
  colorButton:SetPoint("LEFT", COLUMN_POSITIONS.COLOR, 0)

  -- Color display texture
  local colorTexture = colorButton:CreateTexture(nil, "ARTWORK")
  colorTexture:SetAllPoints()

  -- Set color from config
  local r, g, b = 1, 0, 0 -- Default red
  if config.color and config.color[1] and config.color[2] and config.color[3] then
    r, g, b = config.color[1], config.color[2], config.color[3]
  end
  colorTexture:SetColorTexture(r, g, b)

  -- Border around color
  colorButton:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")

  -- Color picker functionality
  colorButton:SetScript("OnClick", function()
    -- Store current color for cancel
    local oldR, oldG, oldB = r, g, b

    -- Color picker callback
    local function colorCallback(restore)
      local newR, newG, newB

      if restore then
        -- User clicked Cancel
        newR, newG, newB = oldR, oldG, oldB
      else
        -- Get selected colors
        newR, newG, newB = ColorPickerFrame:GetColorRGB()
      end

      -- Update visual display
      colorTexture:SetColorTexture(newR, newG, newB)

      -- Update in database
      DM.dmspellsdb[numericID].color = { newR, newG, newB }

      -- Save changes
      DM:SaveDMSpellsDB()

      DM:DatabaseDebug(string.format("Updated color for spell %d to RGB(%f, %f, %f)",
        numericID, newR, newG, newB))
    end

    -- Show the color picker
    ColorPickerFrame.func = colorCallback
    ColorPickerFrame.cancelFunc = colorCallback
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { oldR, oldG, oldB }
    ColorPickerFrame:Hide() -- Hide first to trigger OnShow handler
    ColorPickerFrame:Show()
  end)

  -- Create Save Button
  local saveButton = CreateFrame("Button", nil, spellRow, "UIPanelButtonTemplate")
  saveButton:SetSize(COLUMN_WIDTHS.SAVE, 22)
  saveButton:SetPoint("LEFT", COLUMN_POSITIONS.SAVE, 0)
  saveButton:SetText("Save")

  saveButton:SetScript("OnClick", function()
    DM:DatabaseDebug(string.format("Saving spell config for %d", numericID))
    DM:SaveDMSpellsDB()
  end)

  -- Order Up Button
  local upButton = CreateFrame("Button", nil, spellRow)
  upButton:SetSize(16, 16)
  upButton:SetPoint("LEFT", COLUMN_POSITIONS.UP, 0)
  upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
  upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
  upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

  upButton:SetScript("OnClick", function()
    local currentPriority = DM.dmspellsdb[numericID].priority or 999
    local newPriority = math.max(1, currentPriority - 10)

    if newPriority ~= currentPriority then
      DM:DatabaseDebug(string.format("Changing priority for %d from %d to %d",
        numericID, currentPriority, newPriority))

      DM.dmspellsdb[numericID].priority = newPriority

      -- Save and refresh
      DM:SaveDMSpellsDB()
      DM.GUI:RefreshTrackedSpellList()
    end
  end)

  -- Order Down Button
  local downButton = CreateFrame("Button", nil, spellRow)
  downButton:SetSize(16, 16)
  downButton:SetPoint("LEFT", COLUMN_POSITIONS.DOWN, 0)
  downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
  downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

  downButton:SetScript("OnClick", function()
    local currentPriority = DM.dmspellsdb[numericID].priority or 999
    local newPriority = currentPriority + 10

    DM:DatabaseDebug(string.format("Changing priority for %d from %d to %d",
      numericID, currentPriority, newPriority))

    DM.dmspellsdb[numericID].priority = newPriority

    -- Save and refresh
    DM:SaveDMSpellsDB()
    DM.GUI:RefreshTrackedSpellList()
  end)

  -- Delete Button
  local deleteButton = CreateFrame("Button", nil, spellRow, "UIPanelButtonTemplate")
  deleteButton:SetSize(60, 22)
  deleteButton:SetPoint("LEFT", COLUMN_POSITIONS.DEL, 0)
  deleteButton:SetText("Remove")

  deleteButton:SetScript("OnClick", function()
    -- Update tracked flag to 0 to "remove" from tracking
    DM:DatabaseDebug(string.format("Removing %d from tracked spells", numericID))

    if DM.dmspellsdb[numericID] then
      DM.dmspellsdb[numericID].tracked = 0
    end

    -- Save and refresh
    DM:SaveDMSpellsDB()
    DM.GUI:RefreshTrackedSpellList()
  end)

  -- Update positions when resize happens
  function spellRow.UpdatePositions(positions, widths)
    if not positions or not widths then return end

    enableCheckbox:SetPoint("LEFT", positions.ON, 0)
    iconFrame:SetPoint("LEFT", positions.ID, 0)
    nameText:SetPoint("LEFT", positions.NAME, 0)
    nameText:SetWidth(widths.NAME)
    colorButton:SetPoint("LEFT", positions.COLOR, 0)
    saveButton:SetPoint("LEFT", positions.SAVE, 0)
    saveButton:SetWidth(widths.SAVE)
    upButton:SetPoint("LEFT", positions.UP, 0)
    downButton:SetPoint("LEFT", positions.DOWN, 0)
    deleteButton:SetPoint("LEFT", positions.DEL, 0)
  end

  DM:GUIDebug(string.format("Created full row %d for spell %d (%s)",
    index, numericID, config.spellname or "?"))

  return spellRow -- Return the created frame
end
