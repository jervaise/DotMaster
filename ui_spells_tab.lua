--[[
  DotMaster - UI Spells Tab Module

  File: ui_spells_tab.lua
  Purpose: Spells configuration tab content for the main UI

  Functions:
    CreateSpellsTab(): Creates and populates the spells configuration tab
    RefreshSpellList(): Refreshes the spell list with current settings
    CreateSpellRow(): Creates a row for a spell in the list

  Dependencies:
    DotMaster core
    ui_components.lua
    sp_database.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create UI Spells Tab module
local UISpellsTab = {}
DM.UISpellsTab = UISpellsTab

-- UI elements
local spellsTabFrame = nil
local scrollFrame = nil
local scrollChild = nil
local addEditBox = nil
local spellFrames = {}

-- Constants for layout
local PADDING = {
  OUTER = 5,  -- Outside frame padding
  INNER = 8,  -- Inner content padding
  COLUMN = 12 -- Space between columns
}

-- Column width percentages
local COLUMN_WIDTH_PCT = {
  ON = 0.06,    -- 6% Checkbox
  ID = 0.13,    -- 13% ID field
  NAME = 0.40,  -- 40% Name field
  COLOR = 0.09, -- 9% Color
  SAVE = 0.09,  -- 9% Save
  ORDER = 0.13, -- 13% Order buttons
  DEL = 0.10    -- 10% Delete button
}

-- Create and populate the spells tab
function UISpellsTab:CreateSpellsTab(parent)
  if spellsTabFrame then return spellsTabFrame end

  spellsTabFrame = parent
  local Components = DM.UIComponents

  -- Calculate column positions based on frame width
  local function UpdateColumnPositions(width)
    local positions = {}
    local widths = {}
    local xPos = PADDING.INNER

    -- Calculate positions
    positions.ON = xPos
    widths.ON = width * COLUMN_WIDTH_PCT.ON
    xPos = xPos + widths.ON

    positions.ID = xPos
    widths.ID = width * COLUMN_WIDTH_PCT.ID
    xPos = xPos + widths.ID

    positions.NAME = xPos
    widths.NAME = width * COLUMN_WIDTH_PCT.NAME
    xPos = xPos + widths.NAME

    positions.COLOR = xPos
    widths.COLOR = width * COLUMN_WIDTH_PCT.COLOR
    xPos = xPos + widths.COLOR

    positions.SAVE = xPos
    widths.SAVE = width * COLUMN_WIDTH_PCT.SAVE
    xPos = xPos + widths.SAVE

    positions.UP = xPos
    widths.UP = (width * COLUMN_WIDTH_PCT.ORDER) / 2
    xPos = xPos + widths.UP

    positions.DOWN = xPos
    widths.DOWN = (width * COLUMN_WIDTH_PCT.ORDER) / 2
    xPos = xPos + widths.DOWN

    positions.DEL = xPos
    widths.DEL = width * COLUMN_WIDTH_PCT.DEL

    -- Return both positions and widths
    return positions, widths
  end

  -- Initial positions based on frame width
  local frameWidth = parent:GetWidth() - (PADDING.OUTER * 2)
  local COLUMN_POSITIONS, COLUMN_WIDTHS = UpdateColumnPositions(frameWidth)

  -- Store layout info for later use when creating rows
  UISpellsTab.layout = {
    columnPositions = COLUMN_POSITIONS,
    columnWidths = COLUMN_WIDTHS,
    updatePositions = UpdateColumnPositions
  }

  -- Spells Tab Header
  local spellTitle = Components:CreateHeader(parent, "Configure Spell Tracking", nil, true)
  spellTitle:SetPoint("TOP", 0, -10)

  -- Instructions
  local instructions = Components:CreateLabel(parent, "Enter spell ID, click checkmark to save", nil, nil, "CENTER")
  instructions:SetPoint("TOP", spellTitle, "BOTTOM", 0, -10)
  instructions:SetTextColor(1, 0.82, 0)

  -- Add new spell section
  local addLabel = Components:CreateLabel(parent, "Add New Spell:")
  addLabel:SetPoint("TOPLEFT", PADDING.OUTER + PADDING.INNER, -55)

  -- Add spell ID input
  addEditBox = Components:CreateEditBox(parent, 80, 22, 10)
  addEditBox:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
  addEditBox:SetNumeric(true)

  Components:SetTooltip(addEditBox, "Spell ID", "Enter the numeric ID of the spell you want to track")

  -- Add button
  local addButton = Components:CreateButton(parent, "Add", 60, 22)
  addButton:SetPoint("LEFT", addEditBox, "RIGHT", 10, 0)

  addButton:SetScript("OnClick", function()
    local spellID = addEditBox:GetText()
    if spellID and spellID ~= "" then
      spellID = tonumber(spellID)
      if spellID then
        -- Check if spell exists already
        if DM:SpellExists(spellID) then
          DM:PrintMessage("Spell ID " .. spellID .. " already exists in your list")
          return
        end

        -- Get spell name from API or database
        local spellName = DM:GetSpellName(spellID)

        -- Add to configuration
        DM.spellConfig[tostring(spellID)] = {
          enabled = true,
          color = { 1, 0, 0 }, -- Default red color
          name = spellName,
          priority = DM:GetNextPriority()
        }

        -- Save and refresh
        DM:SaveSettings()
        UISpellsTab:RefreshSpellList()

        -- Clear input
        addEditBox:SetText("")
        addEditBox:ClearFocus()
      end
    end
  end)

  -- Find My Dots button
  local findMyDotsButton = Components:CreateButton(parent, "Find My Dots", 120, 22)
  findMyDotsButton:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
  Components:SetTooltip(findMyDotsButton, "Find My Dots", "Automatically detect your spells by casting them on targets")

  findMyDotsButton:SetScript("OnClick", function()
    if DM.FindMyDots and DM.FindMyDots.ToggleFindMyDotsWindow then
      DM.FindMyDots:ToggleFindMyDotsWindow()
    else
      DM:ToggleFindMyDotsWindow()
    end
  end)

  -- Spell list background for better visuals
  local spellListBg = parent:CreateTexture(nil, "BACKGROUND")
  spellListBg:SetPoint("TOPLEFT", PADDING.OUTER, -70)
  spellListBg:SetPoint("BOTTOMRIGHT", -PADDING.OUTER, 40)
  spellListBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

  -- Create scroll frame for spell list
  scrollFrame, scrollChild = Components:CreateScrollFrame(
    parent,
    parent:GetWidth() - (PADDING.OUTER * 2 + 20), -- Width with room for scrollbar
    parent:GetHeight() - 130,                     -- Height with room for header and footer
    500                                           -- Initial scroll child height
  )
  scrollFrame:SetPoint("TOPLEFT", PADDING.OUTER + PADDING.INNER, -80)
  scrollFrame:SetPoint("BOTTOMRIGHT", -(PADDING.OUTER + 20), 45)

  -- Store references
  UISpellsTab.scrollFrame = scrollFrame
  UISpellsTab.scrollChild = scrollChild
  UISpellsTab.spellFrames = spellFrames

  -- Initial refresh
  UISpellsTab:RefreshSpellList()

  -- Resize handler
  parent:SetScript("OnSizeChanged", function()
    local newWidth = parent:GetWidth() - (PADDING.OUTER * 2)
    UISpellsTab.layout.columnPositions, UISpellsTab.layout.columnWidths = UpdateColumnPositions(newWidth)

    -- Update existing spell rows
    UISpellsTab:RefreshSpellList()
  end)

  return spellsTabFrame
end

-- Create a spell row in the list
function UISpellsTab:CreateSpellRow(spellID, config, yPos)
  local Components = DM.UIComponents
  local layout = self.layout

  -- Create or get existing row
  local rowFrame = spellFrames[spellID] or CreateFrame("Frame", nil, scrollChild)
  spellFrames[spellID] = rowFrame

  -- Row dimensions and position
  local rowWidth = scrollChild:GetWidth() - 20 -- Account for scrollbar
  rowFrame:SetSize(rowWidth, 30)
  rowFrame:SetPoint("TOPLEFT", 10, -yPos)

  -- Alternate row background
  if not rowFrame.bg then
    rowFrame.bg = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame.bg:SetAllPoints()
  end

  if yPos % 60 < 30 then
    rowFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
  else
    rowFrame.bg:SetColorTexture(0.12, 0.12, 0.12, 0.4)
  end

  -- Enabled checkbox
  if not rowFrame.checkbox then
    rowFrame.checkbox = Components:CreateCheckbox(rowFrame)
    rowFrame.checkbox:SetPoint("LEFT", layout.columnPositions.ON, 0)

    rowFrame.checkbox:SetScript("OnClick", function(self)
      config.enabled = self:GetChecked()
      DM:SaveSettings()
      DM:UpdateAllNameplates()
    end)
  end

  rowFrame.checkbox:SetChecked(config.enabled)

  -- Spell ID label
  if not rowFrame.idLabel then
    rowFrame.idLabel = Components:CreateLabel(rowFrame, spellID, "GameFontNormalSmall")
    rowFrame.idLabel:SetPoint("LEFT", layout.columnPositions.ID, 0)
    rowFrame.idLabel:SetWidth(layout.columnWidths.ID - 5)
    rowFrame.idLabel:SetJustifyH("CENTER")
  else
    rowFrame.idLabel:SetText(spellID)
  end

  -- Spell name
  if not rowFrame.nameEditBox then
    rowFrame.nameEditBox = Components:CreateEditBox(rowFrame, layout.columnWidths.NAME - 10, 20, 50)
    rowFrame.nameEditBox:SetPoint("LEFT", layout.columnPositions.NAME, 0)

    rowFrame.nameEditBox:SetScript("OnEnterPressed", function(self)
      config.name = self:GetText()
      DM:SaveSettings()
      DM:UpdateAllNameplates()
      self:ClearFocus()
    end)
  end

  rowFrame.nameEditBox:SetText(config.name or "Unknown")

  -- Color picker
  if not rowFrame.colorPicker then
    rowFrame.colorPicker = Components:CreateColorPicker(rowFrame, 20, 20, config.color, function(r, g, b)
      config.color = { r, g, b }
      DM:SaveSettings()
      DM:UpdateAllNameplates()
    end)
    rowFrame.colorPicker:SetPoint("LEFT", layout.columnPositions.COLOR, 0)
  else
    rowFrame.colorPicker:SetColor(config.color[1], config.color[2], config.color[3])
  end

  -- Save button
  if not rowFrame.saveButton then
    rowFrame.saveButton = Components:CreateButton(rowFrame, "Save", layout.columnWidths.SAVE - 2, 22)
    rowFrame.saveButton:SetPoint("LEFT", layout.columnPositions.SAVE, 0)

    rowFrame.saveButton:SetScript("OnClick", function()
      config.name = rowFrame.nameEditBox:GetText()
      config.enabled = rowFrame.checkbox:GetChecked()
      DM:SaveSettings()
      DM:UpdateAllNameplates()
    end)
  end

  -- Up button
  if not rowFrame.upButton then
    rowFrame.upButton = Components:CreateButton(rowFrame, "↑", layout.columnWidths.UP - 2, 22)
    rowFrame.upButton:SetPoint("LEFT", layout.columnPositions.UP, 0)

    rowFrame.upButton:SetScript("OnClick", function()
      if config.priority and config.priority > 1 then
        -- Find spell with priority-1 and swap
        for id, cfg in pairs(DM.spellConfig) do
          if cfg.priority == config.priority - 1 then
            cfg.priority = config.priority
            config.priority = config.priority - 1
            break
          end
        end

        DM:SaveSettings()
        UISpellsTab:RefreshSpellList()
      end
    end)
  end

  -- Down button
  if not rowFrame.downButton then
    rowFrame.downButton = Components:CreateButton(rowFrame, "↓", layout.columnWidths.DOWN - 2, 22)
    rowFrame.downButton:SetPoint("LEFT", layout.columnPositions.DOWN, 0)

    rowFrame.downButton:SetScript("OnClick", function()
      if config.priority then
        -- Find spell with priority+1 and swap
        for id, cfg in pairs(DM.spellConfig) do
          if cfg.priority == config.priority + 1 then
            cfg.priority = config.priority
            config.priority = config.priority + 1
            break
          end
        end

        DM:SaveSettings()
        UISpellsTab:RefreshSpellList()
      end
    end)
  end

  -- Delete button
  if not rowFrame.deleteButton then
    rowFrame.deleteButton = Components:CreateButton(rowFrame, "Delete", layout.columnWidths.DEL - 2, 22)
    rowFrame.deleteButton:SetPoint("LEFT", layout.columnPositions.DEL, 0)

    rowFrame.deleteButton:SetScript("OnClick", function()
      -- Confirm deletion
      StaticPopupDialogs["DOTMASTER_DELETE_CONFIRM"] = {
        text = "Are you sure you want to delete the spell " .. config.name .. " (" .. spellID .. ")?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
          DM.spellConfig[tostring(spellID)] = nil
          DM:SaveSettings()
          DM:UpdateAllNameplates()
          UISpellsTab:RefreshSpellList()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("DOTMASTER_DELETE_CONFIRM")
    end)
  end

  rowFrame:Show()
  return rowFrame
end

-- Refresh the spell list
function UISpellsTab:RefreshSpellList()
  if not scrollChild then return end

  -- Hide all existing frames
  for id, frame in pairs(spellFrames) do
    frame:Hide()
  end

  -- Sort spells by priority
  local sortedSpells = {}
  for spellID, config in pairs(DM.spellConfig) do
    table.insert(sortedSpells, {
      id = spellID,
      priority = config.priority or 999,
      config = config
    })
  end

  table.sort(sortedSpells, function(a, b) return a.priority < b.priority end)

  -- Create or update rows
  local yPos = 10
  for i, spellData in ipairs(sortedSpells) do
    local rowFrame = self:CreateSpellRow(spellData.id, spellData.config, yPos)
    yPos = yPos + 30
  end

  -- Adjust scroll child height
  scrollChild:SetHeight(math.max(yPos + 10, 100))
end

-- Add this tab to the main UI when the tab system is ready
function UISpellsTab:RegisterTab()
  if DM.UIMain and DM.UIMain.GetTabSystem then
    local tabSystem = DM.UIMain:GetTabSystem()
    if tabSystem then
      tabSystem:AddTab("Spells", function(parent)
        UISpellsTab:CreateSpellsTab(parent)
      end)
    end
  end
end

-- Debug message function with module name
function UISpellsTab:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[UISpellsTab] " .. message)
  end
end

-- Connect to DM namespace for backward compatibility
function UISpellsTab:ConnectToDMNamespace()
  DM.CreateSpellsTab = function(self, parent)
    return UISpellsTab:CreateSpellsTab(parent)
  end

  -- GUI namespace for legacy code
  DM.GUI = DM.GUI or {}
  DM.GUI.RefreshSpellList = function()
    UISpellsTab:RefreshSpellList()
  end
end

-- Initialize the module
function UISpellsTab:Initialize()
  self:ConnectToDMNamespace()
  self:RegisterTab()
  UISpellsTab:DebugMsg("UI Spells Tab module initialized")
end

-- Return the module
return UISpellsTab
