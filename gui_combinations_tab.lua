-- DotMaster gui_combinations_tab.lua
-- Combinations Tab for combining multiple DoTs on nameplates

local DM = DotMaster

function DM:CreateCombinationsTab(parent)
  -- Ensure combinations are initialized
  if not DM:IsCombinationsInitialized() then
    local success = DM:ForceCombinationsInitialization()
    if success then
      DM:DebugMsg("Successfully initialized combinations database in CreateCombinationsTab")
    else
      DM:DebugMsg("WARNING: Failed to initialize combinations in CreateCombinationsTab")
    end
  end

  -- Create a container frame for all content in this tab
  local container = CreateFrame("Frame", nil, parent)
  container:SetAllPoints(parent)

  -- Create the info area at the top of the tab
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    container,
    "DoT Combinations",
    "Create combinations of DoTs to apply unique visual effects when multiple spells are active on the same target."
  )

  -- Main content area
  local contentFrame = CreateFrame("Frame", nil, container)
  contentFrame:SetPoint("TOP", infoArea, "BOTTOM", 0, -10)
  contentFrame:SetPoint("LEFT", container, "LEFT", 10, 0)
  contentFrame:SetPoint("RIGHT", container, "RIGHT", -10, 0)
  contentFrame:SetPoint("BOTTOM", container, "BOTTOM", 0, 10)

  -- Create combinations list
  local listFrame = CreateFrame("Frame", nil, contentFrame)
  listFrame:SetPoint("TOP", contentFrame, "TOP", 0, 0)
  listFrame:SetPoint("LEFT", contentFrame, "LEFT", 0, 0)
  listFrame:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 40)
  listFrame:SetWidth(contentFrame:GetWidth() - 20)

  -- List header
  local headerFrame = CreateFrame("Frame", nil, listFrame)
  headerFrame:SetPoint("TOP", listFrame, "TOP", 0, 0)
  headerFrame:SetPoint("LEFT", listFrame, "LEFT", 0, 0)
  headerFrame:SetPoint("RIGHT", listFrame, "RIGHT", 0, 0)
  headerFrame:SetHeight(25)

  -- Style the header
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

  -- Header text
  local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  headerText:SetPoint("LEFT", headerFrame, "LEFT", 10, 0)
  headerText:SetText("Combination Name")
  headerText:SetTextColor(1, 0.82, 0)

  -- Priority column
  local priorityText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  priorityText:SetPoint("LEFT", headerFrame, "LEFT", 180, 0)
  priorityText:SetText("Priority")
  priorityText:SetTextColor(1, 0.82, 0)

  -- Color column
  local colorText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  colorText:SetPoint("LEFT", headerFrame, "LEFT", 240, 0)
  colorText:SetText("Color")
  colorText:SetTextColor(1, 0.82, 0)

  -- Action column
  local actionText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  actionText:SetPoint("LEFT", headerFrame, "LEFT", 310, 0)
  actionText:SetText("Actions")
  actionText:SetTextColor(1, 0.82, 0)

  -- Create a scrollable list for combinations
  local scrollFrame = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -1)
  scrollFrame:SetPoint("LEFT", listFrame, "LEFT", 0, 0)
  scrollFrame:SetPoint("RIGHT", listFrame, "RIGHT", -20, 0)
  scrollFrame:SetPoint("BOTTOM", listFrame, "BOTTOM", 0, 0)

  -- Content frame inside the scroll frame
  local scrollContent = CreateFrame("Frame", nil, scrollFrame)
  scrollContent:SetSize(scrollFrame:GetWidth(), 500) -- Height will adjust dynamically
  scrollFrame:SetScrollChild(scrollContent)

  -- Add New Combination button
  local addButton = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
  addButton:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 10)
  addButton:SetSize(200, 25)
  addButton:SetText("Create New Combination")

  addButton:SetScript("OnClick", function()
    DM:ShowCombinationDialog()
  end)

  -- Store references to the UI elements
  local combinationRows = {}

  -- Function to update the combinations list
  local function UpdateCombinationsList()
    -- Clear existing rows
    for _, row in ipairs(combinationRows) do
      row:Hide()
    end

    -- Reset scroll content height
    scrollContent:SetHeight(10)

    -- If database isn't initialized, try to force initialize it
    if not DM:IsCombinationsInitialized() then
      -- Create error message
      local messageFrame = CreateFrame("Frame", nil, scrollContent)
      messageFrame:SetSize(scrollContent:GetWidth(), 80)
      messageFrame:SetPoint("CENTER", scrollContent, "CENTER")

      local messageBg = messageFrame:CreateTexture(nil, "BACKGROUND")
      messageBg:SetAllPoints()
      messageBg:SetColorTexture(0.1, 0, 0, 0.5)

      local messageText = messageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      messageText:SetPoint("CENTER", messageFrame, "CENTER", 0, 10)
      messageText:SetText("Combinations database not initialized")
      messageText:SetTextColor(1, 0.3, 0.3)

      -- Add a button to force initialization
      local initButton = CreateFrame("Button", nil, messageFrame, "UIPanelButtonTemplate")
      initButton:SetSize(200, 24)
      initButton:SetPoint("CENTER", messageFrame, "CENTER", 0, -15)
      initButton:SetText("Initialize Combinations Database")

      initButton:SetScript("OnClick", function()
        -- Try to force initialization
        if DM:ForceCombinationsInitialization() then
          -- Refresh the list if successful
          UpdateCombinationsList()
        else
          -- Show error if failed
          messageText:SetText("Failed to initialize database. See chat for details.")
        end
      end)

      return
    end

    -- Sort combinations by priority
    local sortedCombos = {}
    for id, combo in pairs(DM.combinations.data) do
      table.insert(sortedCombos, { id = id, priority = combo.priority or 999, data = combo })
    end

    table.sort(sortedCombos, function(a, b) return a.priority < b.priority end)

    -- Create or update rows for each combination
    local rowHeight = 30
    local yOffset = 0

    for index, comboInfo in ipairs(sortedCombos) do
      local row = combinationRows[index]

      -- Create row if it doesn't exist
      if not row then
        row = CreateFrame("Frame", nil, scrollContent)
        row:SetHeight(rowHeight)

        -- Row background (alternating colors)
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()

        -- Name text
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", row, "LEFT", 10, 0)
        nameText:SetWidth(160)
        nameText:SetJustifyH("LEFT")
        row.nameText = nameText

        -- Priority text
        local priorityText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        priorityText:SetPoint("LEFT", row, "LEFT", 180, 0)
        row.priorityText = priorityText

        -- Color swatch
        local colorSwatch = CreateFrame("Button", nil, row)
        colorSwatch:SetSize(20, 20)
        colorSwatch:SetPoint("LEFT", row, "LEFT", 240, 0)

        local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
        colorTexture:SetAllPoints()
        row.colorTexture = colorTexture

        -- Edit button
        local editButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        editButton:SetSize(60, 20)
        editButton:SetPoint("LEFT", row, "LEFT", 310, 0)
        editButton:SetText("Edit")
        row.editButton = editButton

        -- Delete button
        local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        deleteButton:SetSize(60, 20)
        deleteButton:SetPoint("LEFT", editButton, "RIGHT", 5, 0)
        deleteButton:SetText("Delete")
        row.deleteButton = deleteButton

        combinationRows[index] = row
      end

      -- Set row data
      local id = comboInfo.id
      local combo = comboInfo.data

      -- Position the row
      row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", scrollContent, "RIGHT", 0, 0)

      -- Background color (alternating)
      local rowBg = row:GetRegions()
      rowBg:SetColorTexture(index % 2 == 0 and 0.2 or 0.15, index % 2 == 0 and 0.2 or 0.15,
        index % 2 == 0 and 0.2 or 0.15, 0.8)

      -- Update text fields
      row.nameText:SetText(combo.name or "Unnamed")
      row.priorityText:SetText(combo.priority or "")

      -- Update color swatch
      if combo.color then
        row.colorTexture:SetColorTexture(
          combo.color.r or combo.color[1] or 1,
          combo.color.g or combo.color[2] or 1,
          combo.color.b or combo.color[3] or 1,
          combo.color.a or combo.color[4] or 1
        )
      else
        row.colorTexture:SetColorTexture(0.7, 0.7, 0.7, 1)
      end

      -- Button handlers
      row.editButton:SetScript("OnClick", function()
        DM:ShowCombinationDialog(id)
      end)

      row.deleteButton:SetScript("OnClick", function()
        DM:ShowDeleteConfirmation(id, UpdateCombinationsList)
      end)

      -- Store the combo ID in the row for drag & drop
      row.comboID = id

      -- Show the row
      row:Show()

      -- Update yOffset for next row
      yOffset = yOffset + rowHeight
    end

    -- Update scroll content height
    scrollContent:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
  end

  -- Store the update function
  container.UpdateCombinationsList = UpdateCombinationsList

  -- Export functions to the main addon
  DM.GUI = DM.GUI or {}
  DM.GUI.UpdateCombinationsList = function()
    if container and container.UpdateCombinationsList then
      container:UpdateCombinationsList()
    end
  end

  -- Setup drag & drop for reordering
  -- (This will be implemented with scrollable elements)

  -- Initial update after creation
  C_Timer.After(0.2, UpdateCombinationsList)

  return container
end

-- Combination Dialog
function DM:ShowCombinationDialog(comboID)
  -- Create dialog frame if it doesn't exist
  if not DM.GUI.combinationDialog then
    local dialog = CreateFrame("Frame", "DotMasterCombinationDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(400, 400)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)

    -- Set backdrop
    dialog:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    dialog:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("DoT Combination")
    dialog.title = title

    -- Close button
    local closeButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetSize(28, 28)

    -- Form elements
    -- Name field
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 15, -40)
    nameLabel:SetText("Combination Name:")

    local nameEditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    nameEditBox:SetSize(250, 25)
    nameEditBox:SetPoint("TOPLEFT", nameLabel, "TOPLEFT", 0, -20)
    nameEditBox:SetAutoFocus(false)
    nameEditBox:SetMaxLetters(50)
    dialog.nameEditBox = nameEditBox

    -- Color picker
    local colorLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", nameEditBox, "BOTTOMLEFT", 0, -15)
    colorLabel:SetText("Combination Color:")

    local colorButton = CreateFrame("Button", nil, dialog)
    colorButton:SetSize(30, 30)
    colorButton:SetPoint("TOPLEFT", colorLabel, "TOPLEFT", 0, -20)

    -- Add button texture
    local colorTexture = colorButton:CreateTexture(nil, "OVERLAY")
    colorTexture:SetAllPoints()
    colorTexture:SetColorTexture(1, 0, 0, 1)
    dialog.colorTexture = colorTexture

    -- Store selected color
    dialog.selectedColor = { r = 1, g = 0, b = 0, a = 1 }

    -- Color picker callback
    local function ColorPickerCallback(restore)
      if restore then
        -- User canceled, restore original color
        dialog.selectedColor = restore
      else
        -- Get selected color
        dialog.selectedColor = {
          r = ColorPickerFrame:GetColorRGB(),
          g = ColorPickerFrame.g,
          b = ColorPickerFrame.b,
          a = OpacitySliderFrame:GetValue()
        }
      end

      -- Update color swatch
      dialog.colorTexture:SetColorTexture(
        dialog.selectedColor.r,
        dialog.selectedColor.g,
        dialog.selectedColor.b,
        dialog.selectedColor.a
      )
    end

    -- Color button click handler
    colorButton:SetScript("OnClick", function()
      -- Store current values for cancel
      local r, g, b, a = dialog.selectedColor.r, dialog.selectedColor.g, dialog.selectedColor.b, dialog.selectedColor.a

      -- Show color picker
      ColorPickerFrame.func = ColorPickerCallback
      ColorPickerFrame.opacityFunc = ColorPickerCallback
      ColorPickerFrame.cancelFunc = function()
        ColorPickerCallback({ r = r, g = g, b = b, a = a })
      end

      ColorPickerFrame:SetColorRGB(r, g, b)
      ColorPickerFrame.opacity = a
      ColorPickerFrame.hasOpacity = true
      ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
      ColorPickerFrame:Hide() -- Forces update
      ColorPickerFrame:Show()
    end)

    -- Spell list
    local spellListLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellListLabel:SetPoint("TOPLEFT", colorButton, "BOTTOMLEFT", 0, -20)
    spellListLabel:SetText("Spells in this Combination:")

    -- Spells scroll frame
    local spellsFrame = CreateFrame("Frame", nil, dialog)
    spellsFrame:SetSize(370, 150)
    spellsFrame:SetPoint("TOPLEFT", spellListLabel, "BOTTOMLEFT", 0, -5)

    local spellsScroll = CreateFrame("ScrollFrame", nil, spellsFrame, "UIPanelScrollFrameTemplate")
    spellsScroll:SetPoint("TOPLEFT", 0, 0)
    spellsScroll:SetPoint("BOTTOMRIGHT", -20, 0)

    local spellsContent = CreateFrame("Frame", nil, spellsScroll)
    spellsContent:SetSize(spellsScroll:GetWidth(), 300)
    spellsScroll:SetScrollChild(spellsContent)
    dialog.spellsContent = spellsContent

    -- Add spell button
    local addSpellButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    addSpellButton:SetSize(150, 25)
    addSpellButton:SetPoint("TOPLEFT", spellsFrame, "BOTTOMLEFT", 0, -10)
    addSpellButton:SetText("Add Spell")

    addSpellButton:SetScript("OnClick", function()
      -- Show spell selection UI
      DM:ShowSpellSelectionForCombo(dialog)
    end)

    -- Save/Cancel buttons
    local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 25)
    saveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -10, 10)
    saveButton:SetText("Save")

    saveButton:SetScript("OnClick", function()
      -- Save the combination
      local name = dialog.nameEditBox:GetText()
      local color = dialog.selectedColor
      local spells = dialog.selectedSpells or {}

      -- Validate
      if name == "" then
        DM:PrintMessage("Please enter a name for the combination")
        return
      end

      if #spells == 0 then
        DM:PrintMessage("Please add at least one spell to the combination")
        return
      end

      -- Check if we're editing or creating
      if dialog.comboID then
        -- Update existing
        DM:UpdateCombination(dialog.comboID, {
          name = name,
          color = color,
          spells = spells
        })
      else
        -- Create new
        DM:CreateCombination(name, spells, color)
      end

      -- Update the list
      if DM.GUI.UpdateCombinationsList then
        DM.GUI:UpdateCombinationsList()
      end

      -- Hide the dialog
      dialog:Hide()
    end)

    local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 25)
    cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    cancelButton:SetText("Cancel")

    cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)

    -- Store reference
    DM.GUI.combinationDialog = dialog
  end

  local dialog = DM.GUI.combinationDialog

  -- Reset dialog state
  dialog.selectedSpells = {}
  dialog.nameEditBox:SetText("")
  dialog.selectedColor = { r = 1, g = 0, b = 0, a = 1 }
  dialog.colorTexture:SetColorTexture(1, 0, 0, 1)

  -- Clear spell list
  for _, child in ipairs({ dialog.spellsContent:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end

  -- If editing existing combo, load data
  if comboID and DM.combinations and DM.combinations.data[comboID] then
    local combo = DM.combinations.data[comboID]

    dialog.title:SetText("Edit Combination")
    dialog.comboID = comboID
    dialog.nameEditBox:SetText(combo.name or "")

    -- Set color
    if combo.color then
      dialog.selectedColor = {
        r = combo.color.r or combo.color[1] or 1,
        g = combo.color.g or combo.color[2] or 0,
        b = combo.color.b or combo.color[3] or 0,
        a = combo.color.a or combo.color[4] or 1
      }

      dialog.colorTexture:SetColorTexture(
        dialog.selectedColor.r,
        dialog.selectedColor.g,
        dialog.selectedColor.b,
        dialog.selectedColor.a
      )
    end

    -- Load spells
    dialog.selectedSpells = combo.spells or {}

    -- Populate spell list
    -- Will be implemented with the spell display functions
  else
    dialog.title:SetText("New Combination")
    dialog.comboID = nil
  end

  -- Show the dialog
  dialog:Show()
end

-- Function to show delete confirmation
function DM:ShowDeleteConfirmation(comboID, callback)
  if not comboID or not DM.combinations or not DM.combinations.data[comboID] then
    return
  end

  local combo = DM.combinations.data[comboID]

  -- Use the built-in confirmation dialog
  StaticPopupDialogs["DOTMASTER_DELETE_COMBO"] = {
    text = "Are you sure you want to delete the combination '" .. (combo.name or "Unnamed") .. "'?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
      DM:DeleteCombination(comboID)
      if callback then callback() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  StaticPopup_Show("DOTMASTER_DELETE_COMBO")
end

-- Helper function to check if player has a DoT on a unit
-- This will be implemented in the nameplate detection system
function DM:HasPlayerDotOnUnit(unit, spellID)
  -- Placeholder function
  return false
end

-- Register with the components system
DotMaster_Components.CreateCombinationsTab = function(parent)
  return DM:CreateCombinationsTab(parent)
end

-- Function to show spell selection dialog for combinations
function DM:ShowSpellSelectionForCombo(parent)
  -- Create spell selection frame if it doesn't exist
  if not DM.GUI.comboSpellSelectionFrame then
    local frame = CreateFrame("Frame", "DotMasterComboSpellSelection", UIParent, "BackdropTemplate")
    frame:SetSize(350, 450)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Set backdrop
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Select Spells for Combination")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetSize(28, 28)

    -- Search box
    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", 15, -40)
    searchLabel:SetText("Search Spells:")

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(200, 25)
    searchBox:SetPoint("TOPLEFT", searchLabel, "TOPLEFT", 0, -20)
    searchBox:SetAutoFocus(false)

    -- Create spell list scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -15)
    scrollFrame:SetPoint("RIGHT", frame, "RIGHT", -25, 0)
    scrollFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 45)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(scrollFrame:GetWidth(), 1000) -- Will be adjusted dynamically
    scrollFrame:SetScrollChild(scrollContent)

    -- "Add Selected" button
    local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addButton:SetSize(150, 25)
    addButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    addButton:SetText("Add Selected Spells")

    -- Store selected spells
    local selectedSpells = {}

    -- Function to update the spell list display
    local function UpdateSpellList(searchText)
      -- Clear existing spell buttons
      for _, child in ipairs({ scrollContent:GetChildren() }) do
        child:Hide()
      end

      -- If spell database isn't available, show error
      if not DM.dmspellsdb then
        local errorText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER", scrollContent, "CENTER", 0, 0)
        errorText:SetText("Spell database not available")
        errorText:SetTextColor(1, 0.3, 0.3)
        return
      end

      -- Filter spells based on search text and find tracked spells
      local filteredSpells = {}
      searchText = searchText and searchText:lower() or ""

      for spellIDStr, spellData in pairs(DM.dmspellsdb) do
        -- Match search text
        if (not searchText or searchText == "" or
              (spellData.spellname and spellData.spellname:lower():find(searchText)) or
              (spellData.wowclass and spellData.wowclass:lower():find(searchText)) or
              (spellData.wowspec and spellData.wowspec:lower():find(searchText))) then
          -- Only DoT spells (could be extended with additional filters)
          table.insert(filteredSpells, { id = tonumber(spellIDStr), data = spellData })
        end
      end

      -- Sort spells by name
      table.sort(filteredSpells, function(a, b)
        local nameA = a.data.spellname or ""
        local nameB = b.data.spellname or ""
        return nameA < nameB
      end)

      -- Create UI elements for each spell
      local buttonHeight = 30
      local yOffset = 0

      for index, spellInfo in ipairs(filteredSpells) do
        local spellID = spellInfo.id
        local spellData = spellInfo.data

        -- Create button for this spell
        local button = CreateFrame("Frame", nil, scrollContent)
        button:SetSize(scrollContent:GetWidth() - 20, buttonHeight)
        button:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, -yOffset)

        -- Background
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(index % 2 == 0 and 0.2 or 0.15, index % 2 == 0 and 0.2 or 0.15, index % 2 == 0 and 0.2 or 0.15,
          0.8)

        -- Checkbox
        local checkbox = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("LEFT", button, "LEFT", 5, 0)
        checkbox:SetChecked(selectedSpells[spellID] or false)

        checkbox:SetScript("OnClick", function(self)
          if self:GetChecked() then
            selectedSpells[spellID] = true
          else
            selectedSpells[spellID] = nil
          end
        end)

        -- Spell icon
        local iconSize = buttonHeight - 6
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)

        -- Get spell icon
        if spellData.spellicon then
          icon:SetTexture(spellData.spellicon)
        else
          icon:SetTexture(134400) -- Question mark
        end

        -- Spell name
        local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        name:SetPoint("RIGHT", button, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetText(spellData.spellname or "Unknown")

        -- Show class and spec info if available
        if spellData.wowclass or spellData.wowspec then
          local classInfo = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
          classInfo:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)

          local classText = ""
          if spellData.wowclass then
            classText = spellData.wowclass

            -- Get class color if available
            local classColor = RAID_CLASS_COLORS[spellData.wowclass:upper()]
            if classColor then
              classText = string.format("|cFF%02x%02x%02x%s|r",
                classColor.r * 255,
                classColor.g * 255,
                classColor.b * 255,
                spellData.wowclass)
            end
          end

          if spellData.wowspec and spellData.wowspec ~= "" then
            if classText ~= "" then
              classText = classText .. " - " .. spellData.wowspec
            else
              classText = spellData.wowspec
            end
          end

          classInfo:SetText(classText)
        end

        button:Show()
        yOffset = yOffset + buttonHeight
      end

      -- Update content height for proper scrolling
      scrollContent:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
    end

    -- Add button handler
    addButton:SetScript("OnClick", function()
      -- Get the list of selected spell IDs
      local spellList = {}
      for spellID, _ in pairs(selectedSpells) do
        table.insert(spellList, spellID)
      end

      -- Update the parent dialog
      if parent and parent.selectedSpells then
        parent.selectedSpells = spellList

        -- TODO: Display the selected spells in the parent dialog
        -- This would typically refresh the spell list display
      end

      -- Hide the selection dialog
      frame:Hide()
    end)

    -- Hook up search box
    searchBox:SetScript("OnTextChanged", function(self)
      UpdateSpellList(self:GetText())
    end)

    -- Initialize with all spells
    UpdateSpellList("")

    -- Store the frame reference
    DM.GUI.comboSpellSelectionFrame = frame

    -- Store function for later access
    frame.UpdateSpellList = UpdateSpellList
    frame.selectedSpells = selectedSpells
  end

  local frame = DM.GUI.comboSpellSelectionFrame

  -- Reset selected spells if parent has existing selections
  if parent and parent.selectedSpells then
    wipe(frame.selectedSpells)

    -- Mark existing spells as selected
    for _, spellID in ipairs(parent.selectedSpells) do
      frame.selectedSpells[spellID] = true
    end

    -- Refresh the list
    frame.UpdateSpellList("")
  end

  -- Show the frame
  frame:Show()
end
