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
  if not DM.GUI.scrollChild then
    DM:DebugMsg("scrollChild not found in CreateSpellConfigRow")
    return
  end

  -- Ensure spellConfig entry exists for this spellID
  DM.spellConfig[spellID] = DM.spellConfig[spellID] or { enabled = true, color = { 1, 0, 0 }, name = "Unknown" }
  local config = DM.spellConfig[spellID]

  -- Get layout constants
  local PADDING = DM.GUI.layout and DM.GUI.layout.padding or { INNER = 8 }
  local COLUMN_POSITIONS = DM.GUI.layout and DM.GUI.layout.columns or {
    ON = 8, ID = 36, NAME = 103, COLOR = 250, SAVE = 290, DEL = 328, UP = 358, DOWN = 388
  }
  local COLUMN_WIDTHS = DM.GUI.layout and DM.GUI.layout.widths or {
    ON = 24, ID = 55, NAME = 140, COLOR = 30, SAVE = 30, DEL = 30, UP = 24, DOWN = 24
  }

  local scrollChild = DM.GUI.scrollChild
  local spellRow = CreateFrame("Frame", "DotMasterSpellRow" .. index, scrollChild)

  -- Get current width, use wider default if scrollChild is unexpectedly narrow
  local rowWidth = math.max((scrollChild:GetWidth() - (PADDING.INNER * 2)), 420)
  spellRow:SetSize(rowWidth, 36) -- Consistent height for better spacing
  spellRow:SetPoint("TOPLEFT", PADDING.INNER, -yOffset)
  spellRow.spellID = spellID     -- Store the spellID reference in the frame

  -- Alternating row backgrounds for better visibility
  local bg = spellRow:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  if index % 2 == 0 then
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5) -- Darker for even rows
  else
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- Lighter for odd rows
  end

  -- Row highlight on mouse over
  local highlight = spellRow:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
  highlight:SetBlendMode("ADD")

  -- Enable checkbox - precisely positioned
  local enableCheck = CreateFrame("CheckButton", nil, spellRow, "UICheckButtonTemplate")
  enableCheck:SetSize(20, 20)
  enableCheck:SetPoint("LEFT", COLUMN_POSITIONS.ON, 0) -- Vertical center alignment
  enableCheck:SetChecked(config.enabled)
  enableCheck:SetScript("OnClick", function(self)
    -- Ensure spellConfig entry exists
    if not DM.spellConfig[spellID] then
      DM.spellConfig[spellID] = {
        enabled = true,
        color = { 1, 0, 0 },
        name = "Unknown"
      }
    end

    DM.spellConfig[spellID].enabled = self:GetChecked()
    DM:UpdateAllNameplates()
    DM:SaveSettings() -- Save settings immediately
  end)

  -- Spell ID field - support for comma-separated IDs
  local idField = CreateFrame("EditBox", nil, spellRow, "InputBoxTemplate")
  idField:SetSize(COLUMN_WIDTHS.ID * 0.9, 20)      -- Reduced width to avoid overlap
  idField:SetPoint("LEFT", COLUMN_POSITIONS.ID, 0) -- Precise positioning
  idField:SetAutoFocus(false)
  idField:SetText(spellID)

  -- Create nameField ahead of time so it's available in OnEnterPressed
  ---@class FontStringWithUpdate : FontString
  local nameField = spellRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nameField:SetPoint("LEFT", COLUMN_POSITIONS.NAME, 0) -- Precise positioning
  nameField:SetWidth(COLUMN_WIDTHS.NAME * 0.95)        -- Reduced width to avoid overlap
  nameField:SetJustifyH("LEFT")                        -- Left align text

  -- Store original SetText and create a specialized UpdateText function for this instance
  local originalSetText = nameField.SetText
  ---@diagnostic disable: inject-field
  nameField.UpdateText = function(self, text)
    if not text then return end

    -- First set the text normally
    originalSetText(self, text)

    -- Then handle truncation if needed
    if self:GetStringWidth() > self:GetWidth() then
      local truncated = text
      while self:GetStringWidth() > (self:GetWidth() - 10) and truncated:len() > 1 do
        truncated = truncated:sub(1, -2)
        originalSetText(self, truncated .. "...")
      end
    end
  end

  -- Function to check if a spell ID exists in the config
  local function SpellIDExists(idString)
    if not idString or idString == "" then return false, nil end

    local numID = tonumber(idString)
    if not numID then return false, nil end

    for existingID, cfg in pairs(DM.spellConfig) do
      -- Skip self comparison
      if existingID ~= spellID then
        -- Check exact match with the existing ID
        if tonumber(existingID) == numID then
          return true, { numID }, { cfg.name or ("Spell #" .. numID) }
        end
      end
    end

    return false, nil, nil
  end

  -- Function to reset the field to original value
  local function ResetToOriginal()
    idField:SetText(spellID)
    nameField:UpdateText(config.name)
  end

  -- Save function - common function used by Enter and Save button
  local function SaveSpellData()
    local newIDText = idField:GetText()
    DM:SpellDebug("Saving spell ID: %s", newIDText)

    if newIDText and newIDText ~= "" then
      -- First check if spell ID already exists
      local exists, foundIDs, foundNames = SpellIDExists(newIDText)

      if exists then
        -- Create a formatted string of duplicates
        local idList = foundIDs and foundIDs[1] or ""
        local nameList = foundNames and foundNames[1] or "Unknown"

        -- Reset the field to original value
        ResetToOriginal()

        -- Show popup dialog for duplicate warning
        StaticPopupDialogs["DOTMASTER_DUPLICATE_SPELL"] = {
          text = "Duplicate spell detected!\n\nSpell ID: " ..
              idList .. "\nName: " .. nameList .. "\n\nThis spell is already in your list.",
          button1 = "OK",
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show("DOTMASTER_DUPLICATE_SPELL")
        return
      end

      DM:SpellDebug("Old spellID: %s will be deleted", spellID)

      -- If the spell has a priority, store it
      local priority = DM.spellConfig[spellID].priority or 999

      -- Only remove old entry if it's not the default entry
      if spellID ~= 0 then
        DM.spellConfig[spellID] = nil
      end

      local numericID = tonumber(newIDText)
      if not numericID then
        DM:SpellDebug("Invalid ID format: %s", newIDText)
        return
      end

      -- Use GetSpellName function from spelldata.lua
      local name = DM:GetSpellName(numericID)
      DM:SpellDebug("Spell name found: %s", name)

      if not name or name == "Unknown" then
        name = "Spell #" .. numericID
      end

      -- Create new spell config
      DM.spellConfig[newIDText] = {
        enabled = config.enabled,
        color = config.color or { 1, 0, 0 },
        name = name,
        saved = true,       -- Mark as saved
        priority = priority -- Keep the same priority
      }
      DM:SpellDebug("Spell config created: %s", newIDText)

      -- Update the displayed name with truncation handling
      nameField:UpdateText(name)
      DM:SpellDebug("Calling nameplate update")
      DM:UpdateAllNameplates()
      DM:SpellDebug("Saving settings")
      DM:SaveSettings()

      -- Refresh spell list
      DM.GUI:RefreshSpellList()
    end
  end

  -- Enter also triggers save
  idField:SetScript("OnEnterPressed", function(self)
    SaveSpellData()
    self:ClearFocus()
  end)

  -- Color picker
  local color = config.color or { 1, 0, 0 } -- Default color if nil
  DM:SpellDebug("Creating color swatch for spell: %s with color: %s, %s, %s",
    spellID, color[1], color[2], color[3])

  local colorSwatch = DotMaster_CreateColorSwatch(spellRow, color[1], color[2], color[3], function(r, g, b)
    DM:SpellDebug("Color changed for spell: %s to RGB: %s, %s, %s", spellID, r, g, b)

    -- Ensure spellConfig entry exists
    if not DM.spellConfig[spellID] then
      DM.spellConfig[spellID] = {
        enabled = true,
        color = { r, g, b },
        name = "Unknown"
      }
      DM:SpellDebug("Created new spell config for spell ID: %s", spellID)
    else
      DM.spellConfig[spellID].color = { r, g, b }
      -- Mark as saved after color change
      DM.spellConfig[spellID].saved = true
    end

    DM:UpdateAllNameplates()
    -- DM:SaveSettings() -- Called from color picker, no need to call again here
  end)
  colorSwatch:SetPoint("LEFT", COLUMN_POSITIONS.COLOR, 0) -- Precise positioning

  -- Save button with checkmark icon and saved state
  local saveBtn = CreateFrame("Button", nil, spellRow, "UIPanelButtonTemplate")
  saveBtn:SetSize(26, 24)
  saveBtn:SetPoint("LEFT", COLUMN_POSITIONS.SAVE, 0) -- Precise positioning

  -- Create texture for checkmark icon
  local saveTexture = saveBtn:CreateTexture(nil, "ARTWORK")
  saveTexture:SetSize(16, 16)
  saveTexture:SetPoint("CENTER")
  saveTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")

  -- Remove button text, just show checkmark icon
  saveBtn:SetText("")

  -- Tooltip for save button
  saveBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Save Changes", 1, 1, 1)
    GameTooltip:Show()
  end)

  saveBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  -- Setup saved state appearance
  if config.saved then
    -- Desaturate both the button and icon when saved
    saveTexture:SetDesaturated(true)
    -- Get button textures (NormalTexture, PushedTexture etc.)
    for i = 1, saveBtn:GetNumRegions() do
      local region = select(i, saveBtn:GetRegions())
      if region and region:IsObjectType("Texture") and region ~= saveTexture then
        region:SetDesaturated(true)
      end
    end
  end

  -- Apply better visuals
  saveBtn:SetScript("OnClick", function()
    SaveSpellData()
    -- Desaturate icon and button after saving
    saveTexture:SetDesaturated(true)
    -- Desaturate button textures
    for i = 1, saveBtn:GetNumRegions() do
      local region = select(i, saveBtn:GetRegions())
      if region and region:IsObjectType("Texture") and region ~= saveTexture then
        region:SetDesaturated(true)
      end
    end
    -- Mark spell as saved
    if DM.spellConfig[idField:GetText()] then
      DM.spellConfig[idField:GetText()].saved = true
    end
  end)

  -- Delete button with improved styling
  local deleteBtn = CreateFrame("Button", nil, spellRow, "UIPanelButtonTemplate")
  deleteBtn:SetSize(26, 24)
  deleteBtn:SetPoint("LEFT", COLUMN_POSITIONS.DEL, 0) -- Precise positioning
  deleteBtn:SetText("X")
  deleteBtn:SetNormalFontObject("GameFontNormalSmall")

  -- Make it red-tinted to indicate danger
  for i, region in ipairs({ deleteBtn:GetRegions() }) do
    if region:GetObjectType() == "Texture" then
      region:SetVertexColor(1.0, 0.3, 0.3)
    end
  end

  -- Tooltip for delete button
  deleteBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Delete Spell", 1, 0, 0) -- Red text to indicate danger
    GameTooltip:Show()
  end)

  deleteBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  deleteBtn:SetScript("OnClick", function()
    -- Create confirmation dialog
    StaticPopupDialogs["DOTMASTER_DELETE_CONFIRM"] = {
      text = "Are you sure you want to delete this spell?",
      button1 = "Yes",
      button2 = "No",
      OnAccept = function()
        if DM.spellConfig[spellID] then
          DM.spellConfig[spellID] = nil
          spellRow:Hide()
          DM:UpdateAllNameplates()
          DM.GUI:RefreshSpellList()
          DM:SaveSettings() -- Save settings immediately
        else
          DM:SpellDebug("Attempted to delete non-existent spell config: %s", spellID)
        end
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_DELETE_CONFIRM")
  end)

  -- Up button - Standart WoW butonları kullanarak daha görünür hale getir
  local upBtn = CreateFrame("Button", nil, spellRow)
  upBtn:SetSize(24, 24)
  upBtn:SetPoint("LEFT", COLUMN_POSITIONS.UP, 0)

  -- Normal texture
  local upNormal = upBtn:CreateTexture(nil, "ARTWORK")
  upNormal:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
  upNormal:SetAllPoints()
  upBtn:SetNormalTexture(upNormal)

  -- Pushed texture
  local upPushed = upBtn:CreateTexture(nil, "ARTWORK")
  upPushed:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
  upPushed:SetAllPoints()
  upBtn:SetPushedTexture(upPushed)

  -- Highlight texture
  local upHighlight = upBtn:CreateTexture(nil, "HIGHLIGHT")
  upHighlight:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
  upHighlight:SetAllPoints()
  upBtn:SetHighlightTexture(upHighlight)

  -- Tooltip for up button
  upBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Move Up", 1, 1, 1)
    GameTooltip:Show()
  end)

  upBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  upBtn:SetScript("OnClick", function()
    -- Ensure priority exists
    if not DM.spellConfig[spellID].priority then
      -- Set priorities for all if not exists
      DM:SetDefaultPriorities()
    end

    local currentPriority = DM.spellConfig[spellID].priority
    if currentPriority > 1 then
      -- Find spell with priority-1
      local targetSpellID = nil
      for id, config in pairs(DM.spellConfig) do
        if config.priority and config.priority == (currentPriority - 1) then
          targetSpellID = id
          break
        end
      end

      if targetSpellID then
        -- Swap priorities
        DM.spellConfig[spellID].priority = currentPriority - 1
        DM.spellConfig[targetSpellID].priority = currentPriority

        -- Save and refresh
        DM:SaveSettings()
        DM.GUI:RefreshSpellList()
      end
    end
  end)

  -- Down button - Standart WoW butonları kullanarak daha görünür hale getir
  local downBtn = CreateFrame("Button", nil, spellRow)
  downBtn:SetSize(24, 24)
  downBtn:SetPoint("LEFT", COLUMN_POSITIONS.DOWN, 0)

  -- Normal texture
  local downNormal = downBtn:CreateTexture(nil, "ARTWORK")
  downNormal:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  downNormal:SetAllPoints()
  downBtn:SetNormalTexture(downNormal)

  -- Pushed texture
  local downPushed = downBtn:CreateTexture(nil, "ARTWORK")
  downPushed:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
  downPushed:SetAllPoints()
  downBtn:SetPushedTexture(downPushed)

  -- Highlight texture
  local downHighlight = downBtn:CreateTexture(nil, "HIGHLIGHT")
  downHighlight:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
  downHighlight:SetAllPoints()
  downBtn:SetHighlightTexture(downHighlight)

  -- Tooltip for down button
  downBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Move Down", 1, 1, 1)
    GameTooltip:Show()
  end)

  downBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  downBtn:SetScript("OnClick", function()
    -- Ensure priority exists
    if not DM.spellConfig[spellID].priority then
      -- Set priorities for all if not exists
      DM:SetDefaultPriorities()
    end

    local currentPriority = DM.spellConfig[spellID].priority
    local maxPriority = DM:GetMaxPriority()

    if currentPriority < maxPriority then
      -- Find spell with priority+1
      local targetSpellID = nil
      for id, config in pairs(DM.spellConfig) do
        if config.priority and config.priority == (currentPriority + 1) then
          targetSpellID = id
          break
        end
      end

      if targetSpellID then
        -- Swap priorities
        DM.spellConfig[spellID].priority = currentPriority + 1
        DM.spellConfig[targetSpellID].priority = currentPriority

        -- Save and refresh
        DM:SaveSettings()
        DM.GUI:RefreshSpellList()
      end
    end
  end)

  -- Spell name - update based on spelldata
  -- Get current name from spelldata.lua
  if not config.name or config.name == "Unknown" or config.name == "New Spell" then
    if type(spellID) == "string" and string.find(spellID, ",") then
      local names = {}
      for id in string.gmatch(spellID, "%d+") do
        local spellName = DM:GetSpellName(tonumber(id))
        table.insert(names, spellName)
      end
      config.name = table.concat(names, ", ")
    else
      config.name = DM:GetSpellName(tonumber(spellID) or 0)
    end

    -- Save settings
    DM:SaveSettings()
  end

  -- Use our custom text update function to handle long names
  nameField:UpdateText(config.name)

  -- Create function to update row element positions when frame size changes
  local function UpdateRowPositions(positions, widths)
    -- If no positions/widths passed, use current ones from DM.GUI.layout
    positions = positions or DM.GUI.layout.columns
    widths = widths or DM.GUI.layout.widths

    if not positions or not widths then return end

    -- Update all element positions based on new layout
    enableCheck:SetPoint("LEFT", positions.ON, 0)

    idField:SetPoint("LEFT", positions.ID, 0)
    idField:SetWidth(widths.ID * 0.9) -- Reduce width slightly to prevent overlap

    nameField:SetPoint("LEFT", positions.NAME, 0)
    nameField:SetWidth(widths.NAME * 0.95) -- Reduce width slightly to prevent overlap

    colorSwatch:SetPoint("LEFT", positions.COLOR, 0)
    saveBtn:SetPoint("LEFT", positions.SAVE, 0)
    upBtn:SetPoint("LEFT", positions.UP, 0)
    downBtn:SetPoint("LEFT", positions.DOWN, 0)
    deleteBtn:SetPoint("LEFT", positions.DEL, 0)

    -- Update row width if scrollChild width has changed
    local newWidth = scrollChild:GetWidth() - (PADDING.INNER * 2)
    if newWidth > 0 then
      spellRow:SetWidth(newWidth)
    end
  end

  -- Attach the function to the spellRow so it can be called from the parent
  spellRow.UpdatePositions = UpdateRowPositions

  DM.GUI.spellFrames[index] = spellRow
  return spellRow
end
