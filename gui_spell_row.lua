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

  -- Calculate row width to match content area - make rows full width like class headers
  local rowWidth = scrollChild:GetWidth()
  local rowHeight = 36 -- Define row height

  -- Set the row size and position - remove inner padding to match header
  spellRow:SetSize(rowWidth, rowHeight)
  spellRow:SetPoint("TOPLEFT", 0, -yOffset)
  spellRow.spellID = numericID -- Store the spellID (numeric) reference

  -- Create background for the row - full width
  local bg = spellRow:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(spellRow)
  if index % 2 == 0 then
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5) -- Darker
  else
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- Lighter
  end

  -- Highlight effect on hover
  local highlight = spellRow:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints(spellRow)
  highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
  highlight:SetBlendMode("ADD")

  -- Enable mouse interaction for highlight effect
  spellRow:EnableMouse(true)

  -- ON: Enable/Disable Checkbox
  local enableCheckbox = CreateFrame("CheckButton", nil, spellRow, "UICheckButtonTemplate")
  enableCheckbox:SetSize(24, 24)
  -- Center the checkbox in its column for better alignment
  enableCheckbox:SetPoint("CENTER", spellRow, "LEFT", COLUMN_POSITIONS.ON + (COLUMN_WIDTHS.ON / 2), 0)
  enableCheckbox:SetChecked(config.enabled == 1)

  enableCheckbox:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    DM:DatabaseDebug(string.format("Updating enabled status for %d to %s", numericID, tostring(isChecked)))
    DM.dmspellsdb[numericID].enabled = isChecked and 1 or 0

    -- Save the changes
    DM:SaveDMSpellsDB()
  end)

  -- SPELL: Combined spell icon, name and ID in a single section
  local spellContainer = CreateFrame("Frame", nil, spellRow)
  spellContainer:SetPoint("LEFT", COLUMN_POSITIONS.ID, 0)
  spellContainer:SetSize(COLUMN_WIDTHS.ID + COLUMN_WIDTHS.NAME, rowHeight)

  -- Spell Icon
  local iconSize = 24
  local icon = spellContainer:CreateTexture(nil, "ARTWORK")
  icon:SetSize(iconSize, iconSize)
  icon:SetPoint("LEFT", 0, 0)
  icon:SetTexture(config.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

  -- Create a frame for the icon border
  local iconBorder = CreateFrame("Frame", nil, spellContainer, "BackdropTemplate")
  iconBorder:SetSize(iconSize + 2, iconSize + 2)
  iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
  iconBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  iconBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  -- Spell Name and ID Text
  local nameText = spellContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  -- Allow more space for name by using most of the available width
  -- Adjust width to account for wider window
  nameText:SetWidth(COLUMN_WIDTHS.NAME + COLUMN_WIDTHS.ID - iconSize - 20)
  nameText:SetJustifyH("LEFT")
  local spellName = config.spellname or "Unknown Name"
  nameText:SetText(string.format("%s (%d)", spellName, numericID))

  -- Add helper function to nameText
  nameText.UpdateText = DMFontStringHelper.UpdateText
  nameText:UpdateText(string.format("%s (%d)", spellName, numericID))

  -- COLOR: Color Picker button using the colorpicker module
  -- Provide a default color if config.color is missing or invalid
  local r, g, b = 1, 1, 1 -- Default white
  if config and config.color and type(config.color) == "table" and #config.color >= 3 then
    r, g, b = config.color[1], config.color[2], config.color[3]
  else
    -- Log if using default due to missing/invalid color
    DM:DatabaseDebug(string.format("Spell %d missing valid color data, using default white.", numericID))
  end

  -- Ensure r, g, b are numbers (handle potential non-numeric values)
  r = tonumber(r) or 1
  g = tonumber(g) or 1
  b = tonumber(b) or 1

  -- Create color swatch using DotMaster_CreateColorSwatch
  local colorSwatch = DotMaster_CreateColorSwatch(spellRow, r, g, b, function(newR, newG, newB)
    -- Update color in database
    DM.dmspellsdb[numericID].color = { newR, newG, newB }

    -- Save changes immediately (SaveDMSpellsDB handles saving)
    -- DM:SaveDMSpellsDB() -- Already called within the swatch callback logic

    DM:DatabaseDebug(string.format("Updated color for spell %d to RGB(%f, %f, %f)",
      numericID, newR, newG, newB))
  end)
  colorSwatch:SetPoint("LEFT", COLUMN_POSITIONS.COLOR, 0)

  -- ORDER: Up/Down buttons for priority
  local orderContainer = CreateFrame("Frame", nil, spellRow)
  orderContainer:SetSize(COLUMN_WIDTHS.UP + COLUMN_WIDTHS.DOWN, rowHeight)
  orderContainer:SetPoint("LEFT", COLUMN_POSITIONS.UP, 0)

  -- Calculate centered position for the buttons with reduced spacing
  local buttonAreaWidth = COLUMN_WIDTHS.UP + COLUMN_WIDTHS.DOWN
  local buttonsWidth = 24 + 2 + 24 -- button + spacing + button
  local leftPadding = (buttonAreaWidth - buttonsWidth) / 2

  -- Down Button (left) - Standard WoW arrow
  local downButton = CreateFrame("Button", nil, orderContainer)
  downButton:SetSize(24, 24)
  downButton:SetPoint("LEFT", leftPadding, 0)
  downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
  downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

  -- UP Button (right) - Standard WoW arrow - reduced spacing
  local upButton = CreateFrame("Button", nil, orderContainer)
  upButton:SetSize(24, 24)
  upButton:SetPoint("LEFT", downButton, "RIGHT", 2, 0) -- Reduced from 5px to 2px
  upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
  upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
  upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

  -- Store reference to buttons in the row for later access
  spellRow.upButton = upButton
  spellRow.downButton = downButton
  spellRow.index = index -- Store index for checking first/last position

  -- Store references to UI elements for desaturation
  spellRow.icon = icon
  spellRow.colorSwatch = colorSwatch
  spellRow.enableCheckbox = enableCheckbox
  spellRow.textures = {
    icon = icon,
    bg = bg,
    highlight = highlight
  }

  upButton:SetScript("OnClick", function()
    local currentPriority = DM.dmspellsdb[numericID].priority or 999
    local newPriority = math.max(1, currentPriority - 10)

    if newPriority ~= currentPriority then
      DM:DatabaseDebug(string.format("Changing priority for %d from %d to %d",
        numericID, currentPriority, newPriority))

      DM.dmspellsdb[numericID].priority = newPriority

      -- Save changes
      DM:SaveDMSpellsDB()
    end
  end)

  downButton:SetScript("OnClick", function()
    local currentPriority = DM.dmspellsdb[numericID].priority or 999
    local newPriority = currentPriority + 10

    DM:DatabaseDebug(string.format("Changing priority for %d from %d to %d",
      numericID, currentPriority, newPriority))

    DM.dmspellsdb[numericID].priority = newPriority

    -- Save changes
    DM:SaveDMSpellsDB()
  end)

  -- Create UNTRACK/Remove button with proper spacing and sizing
  local untrackButton = CreateFrame("Button", nil, spellRow, "UIPanelButtonTemplate")
  untrackButton:SetSize(60, 24) -- Maintain size for consistency
  untrackButton:SetPoint("LEFT", COLUMN_POSITIONS.DEL, 0)
  untrackButton:SetText("Remove")

  -- Make button red to stand out
  untrackButton.Left:SetVertexColor(0.8, 0.2, 0.2)
  untrackButton.Middle:SetVertexColor(0.8, 0.2, 0.2)
  untrackButton.Right:SetVertexColor(0.8, 0.2, 0.2)

  -- Store reference to untrack button
  spellRow.removeButton = untrackButton

  -- Add tooltip
  untrackButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Remove Tracking")
    GameTooltip:AddLine("Remove this spell from tracked spells list", 1, 0.82, 0, true)
    GameTooltip:Show()
  end)

  untrackButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  untrackButton:SetScript("OnClick", function()
    -- Update tracked flag to 0 to "remove" from tracking
    DM:DatabaseDebug(string.format("Removing %d from tracked spells", numericID))

    if DM.dmspellsdb[numericID] then
      DM.dmspellsdb[numericID].tracked = 0
    end

    -- Save changes
    DM:SaveDMSpellsDB()
  end)

  -- Update positions when resize happens
  function spellRow.UpdatePositions(positions, widths)
    if not positions or not widths then return end

    -- Update row width to match content area
    spellRow:SetWidth(scrollChild:GetWidth())

    -- Update positioned elements
    enableCheckbox:SetPoint("CENTER", spellRow, "LEFT", positions.ON + (widths.ON / 2), 0)

    spellContainer:SetPoint("LEFT", positions.ID, 0)
    spellContainer:SetSize(widths.ID + widths.NAME, rowHeight)

    -- Update nameText width
    nameText:SetWidth(widths.NAME + widths.ID - iconSize - 20)

    colorSwatch:SetPoint("LEFT", positions.COLOR, 0)

    orderContainer:SetPoint("LEFT", positions.UP, 0)
    orderContainer:SetSize(widths.UP + widths.DOWN, rowHeight)

    -- Update arrow buttons position
    local buttonAreaWidth = widths.UP + widths.DOWN
    local buttonsWidth = 24 + 2 + 24 -- button + spacing + button
    local leftPadding = (buttonAreaWidth - buttonsWidth) / 2
    downButton:SetPoint("LEFT", leftPadding, 0)
    upButton:SetPoint("LEFT", downButton, "RIGHT", 2, 0)

    -- Position Remove button
    untrackButton:SetPoint("LEFT", positions.DEL, 0)
    -- With increased window width, we can use full button width
    untrackButton:SetWidth(60)
  end

  -- Add to tracking table
  table.insert(DM.GUI.spellFrames, spellRow)

  return spellRow
end
