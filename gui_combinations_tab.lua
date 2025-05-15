-- DotMaster gui_combinations_tab.lua
-- Combinations Tab for combining multiple DoTs on nameplates

local DM = DotMaster

-- Add these functions at the top of the file, after the local DM = DotMaster line

-- Function to force refresh of all combination colors
function DM:RefreshCombinationColors()
  -- Ensure we have access to the combinations UI
  if not self.GUI or not self.GUI.frame then
    return false
  end

  -- Get all visible combination rows
  local allRows = {}
  if self.GUI.frame and self.GUI.frame.allRows then
    allRows = self.GUI.frame.allRows
  end

  -- Get the current spec's combinations
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if not currentCombinations or not currentCombinations.data then
    return false
  end

  -- Update colors for all rows
  local updatedCount = 0
  for id, combo in pairs(currentCombinations.data) do
    for _, row in ipairs(allRows or {}) do
      if row.comboID == id and row.rowBg and row.nameText and combo.color then
        -- Get color components
        local r = combo.color.r or combo.color[1] or 1
        local g = combo.color.g or combo.color[2] or 0
        local b = combo.color.b or combo.color[3] or 0

        -- Update background
        row.rowBg:SetColorTexture(r * 0.2, g * 0.2, b * 0.2, 0.8)

        -- Update text color
        row.nameText:SetTextColor(r, g, b)

        -- Update color swatch if it exists
        if row.colorTexture then
          row.colorTexture:SetColorTexture(r, g, b, 1)
        end

        updatedCount = updatedCount + 1
      end
    end
  end

  self:DebugMsg("Updated colors for " .. updatedCount .. " combination rows")
  return true
end

-- Stub functions for combinations functionality
function DM:IsCombinationsInitialized()
  return true -- Always return true to avoid initialization errors
end

function DM:ForceCombinationsInitialization()
  return true -- Always return success
end

-- Function for showing the combination dialog - stub implementation
function DM:ShowCombinationDialog()
  DM:PrintMessage("Combination dialog functionality is not available in this version")
end

-- Helper function to set up mouse wheel scrolling and hide scrollbars
local function SetupScrollFrames(frame)
  if not frame then return end

  -- Process all scrollframes in this frame
  for _, child in pairs({ frame:GetChildren() }) do
    -- Direct scrollframes
    if child:IsObjectType("ScrollFrame") then
      -- Hide scrollbar
      local scrollBar = nil
      if child:GetName() then
        scrollBar = _G[child:GetName() .. "ScrollBar"]
      else
        -- For frames without names, try to get scrollbar directly from children
        for _, subchild in pairs({ child:GetChildren() }) do
          if subchild:IsObjectType("Slider") then
            scrollBar = subchild
            break
          end
        end
      end

      if scrollBar then
        scrollBar:SetWidth(0)
        scrollBar:SetAlpha(0)
      end

      -- Adjust content width to match the scrollframe exactly
      local content = child:GetScrollChild()
      if content then
        content:SetWidth(child:GetWidth())
      end

      -- Enable mouse wheel scrolling
      child:EnableMouseWheel(true)
      child:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll()
        local scrollRange = self:GetVerticalScrollRange()

        -- Calculate new scroll position (faster scrolling with higher step)
        local newPosition = currentScroll - (delta * 30)

        -- Clamp scroll position to valid range
        newPosition = math.max(0, math.min(newPosition, scrollRange))

        -- Apply the scroll
        self:SetVerticalScroll(newPosition)
      end)
    end

    -- Nested scrollframes (in container frames)
    if child:IsObjectType("Frame") then
      SetupScrollFrames(child)
    end
  end
end

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

  -- Add tab shown/hidden hooks to close dialogs when tab is changed
  container:SetScript("OnHide", function()
    -- Close any open dialogs when the combinations tab is hidden
    if DM.GUI.combinationDialog and DM.GUI.combinationDialog:IsShown() then
      DM.GUI.combinationDialog:Hide()
      DM:DebugMsg("Closed combination dialog because combinations tab was hidden")
    end

    if DM.GUI.comboSpellSelectionFrame and DM.GUI.comboSpellSelectionFrame:IsShown() then
      DM.GUI.comboSpellSelectionFrame:Hide()
      DM:DebugMsg("Closed spell selection window because combinations tab was hidden")
    end
  end)

  -- Create the info area at the top of the tab
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    container,
    "DoT Combinations",
    "Create combinations of DoTs to apply nameplate colors. Combinations always take priority over individual spells."
  )

  -- Main content area with no vertical gap between info area and content
  local contentFrame = CreateFrame("Frame", nil, container)
  contentFrame:SetPoint("TOP", infoArea, "BOTTOM", 0, 0) -- No vertical gap
  contentFrame:SetPoint("LEFT", container, "LEFT", 10, 0)
  contentFrame:SetPoint("RIGHT", container, "RIGHT", -10, 0)
  contentFrame:SetPoint("BOTTOM", container, "BOTTOM", 0, 10)

  -- Create combinations list
  local listFrame = CreateFrame("Frame", nil, contentFrame)
  listFrame:SetPoint("TOP", contentFrame, "TOP", 0, 0)    -- Remove any top margin
  listFrame:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 40)
  listFrame:SetWidth(430)                                 -- Set to 430px exactly
  listFrame:SetPoint("CENTER", contentFrame, "TOP", 0, 0) -- Center align at top

  -- List header - Eliminate any space between infoArea and header
  local headerFrame = CreateFrame("Frame", nil, listFrame)
  headerFrame:SetPoint("TOP", listFrame, "TOP", 0, 0)
  headerFrame:SetPoint("LEFT", listFrame, "LEFT", 0, 0)
  headerFrame:SetPoint("RIGHT", listFrame, "RIGHT", 0, 0)
  headerFrame:SetHeight(20) -- Match tracked spells tab header height

  -- Style the header with dark semi-transparent background like tracked spells tab
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  headerBg:SetColorTexture(0, 0, 0, 0.6) -- Dark semi-transparent background to match tracked spells

  -- Define standardized column positions that match the tracked spells tab exactly
  -- These values must match the gui_tracked_spells_tab.lua positions
  local COLUMN_POSITIONS = {
    NAME = 20,    -- Moved 10px left (from 30)
    COLOR = 240,  -- Moved 30px right (from 210)
    ORDER = 310,  -- Moved 15px right (from 295)
    ACTIONS = 367 -- Moved 7px right (from 360)
  }

  -- Create header labels with similar style to tracked spells tab
  local function CreateHeaderLabel(text, xPosition)
    local label = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", headerFrame, "LEFT", xPosition, 0)
    label:SetText(text)
    label:SetTextColor(1, 0.82, 0) -- Gold text color
    return label
  end

  -- Header text with exact positioning
  CreateHeaderLabel("COMBINATION NAME", COLUMN_POSITIONS.NAME - 10 + 20 - 25) -- Move COMBINATION NAME 10px left originally, now 20px right from that, then 25px left
  CreateHeaderLabel("COLOR", COLUMN_POSITIONS.COLOR + 15 + 15 + 2 - 2)        -- Move COLOR 15px right originally, now 15px more to the right, plus 2px more, then 2px left
  CreateHeaderLabel("ORDER", COLUMN_POSITIONS.ORDER + 7 - 1)                  -- Move ORDER 7px right originally, now 1px left from that
  CreateHeaderLabel("ACTIONS", COLUMN_POSITIONS.ACTIONS)

  -- Create a scrollable list for combinations
  local scrollFrame = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -2) -- Changed from -1 to -2 to match tracked spells tab
  scrollFrame:SetPoint("LEFT", listFrame, "LEFT", 0, 0)
  scrollFrame:SetPoint("RIGHT", listFrame, "RIGHT", 0, 0)   -- No space for scrollbar
  scrollFrame:SetPoint("BOTTOM", listFrame, "BOTTOM", 0, 0)

  -- Hide scrollbar
  local scrollBar = nil
  if scrollFrame:GetName() then
    scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
  else
    -- For frames without names, try to get scrollbar directly from children
    for _, child in pairs({ scrollFrame:GetChildren() }) do
      if child:IsObjectType("Slider") then
        scrollBar = child
        break
      end
    end
  end

  if scrollBar then
    scrollBar:SetWidth(0)
    scrollBar:SetAlpha(0)
  end

  -- Content frame inside the scroll frame
  local scrollContent = CreateFrame("Frame", nil, scrollFrame)
  scrollContent:SetWidth(scrollFrame:GetWidth())
  scrollContent:SetHeight(1000) -- Will be adjusted dynamically
  scrollFrame:SetScrollChild(scrollContent)

  -- Add New Combination button
  local addButton = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
  addButton:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 10)
  addButton:SetSize(150, 30)                                  -- Changed from 200 to 150 to match Find My Dots button
  addButton:SetText("Create New Combination")
  addButton:SetPoint("CENTER", contentFrame, "BOTTOM", 0, 10) -- Center align at bottom

  addButton:SetScript("OnClick", function()
    DM:ShowCombinationDialog()
  end)

  -- Store references to the UI elements
  local combinationRows = {}

  -- Function to update the layout when combinations are expanded/collapsed
  local function UpdateCombinationsLayout()
    local yOffset = 2         -- Start with small offset like in tracked spells tab
    local rowHeight = 40      -- Combination row height (changed from 30 to 40)
    local spellRowHeight = 25 -- Spell row height
    local spacing = 2         -- Small spacing between rows

    -- Go through all combination rows
    for index, row in ipairs(combinationRows) do
      if row and row:IsShown() then
        -- Position the combination row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -yOffset)
        row:SetWidth(scrollContent:GetWidth())

        -- Update yOffset for next row
        yOffset = yOffset + rowHeight + spacing

        -- If this combination is expanded, position its spell frames
        if row.isExpanded and row.spellFrames then
          for _, spellFrame in ipairs(row.spellFrames) do
            spellFrame:ClearAllPoints()
            spellFrame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -yOffset)
            spellFrame:SetWidth(scrollContent:GetWidth())
            spellFrame:Show()

            -- Update yOffset for next row
            yOffset = yOffset + spellRowHeight + spacing
          end
        end
      end
    end

    -- Update scroll content height
    scrollContent:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
  end

  -- Function to update the combinations list
  local function UpdateCombinationsList()
    self:DebugMsg("Updating combinations list")

    -- Clear existing rows
    for i = 1, #combinationRows do
      local row = combinationRows[i]
      if row then
        row:Hide()
        row:ClearAllPoints()
      end
    end

    -- Reset scroll content height
    scrollContent:SetHeight(10)

    -- If database isn't initialized, try to force initialize it
    if not DM:IsCombinationsInitialized() then
      -- Create error message
      local messageFrame = CreateFrame("Frame", nil, scrollContent)
      messageFrame:SetSize(scrollContent:GetWidth(), 80)
      messageFrame:SetPoint("TOP", scrollContent, "TOP", 0, -20)
      messageFrame:SetPoint("LEFT", scrollContent, "LEFT", 0, 0)
      messageFrame:SetPoint("RIGHT", scrollContent, "RIGHT", 0, 0)

      local messageBg = messageFrame:CreateTexture(nil, "BACKGROUND")
      messageBg:SetAllPoints()
      messageBg:SetColorTexture(0.1, 0, 0, 0.5)

      local messageText = messageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      messageText:SetPoint("CENTER", messageFrame, "CENTER", 0, 10)
      messageText:SetText("Combinations database not initialized")
      messageText:SetTextColor(1, 0.3, 0.3)
      messageText:SetWidth(messageFrame:GetWidth() - 20)
      messageText:SetJustifyH("CENTER")

      -- Add a button to force initialization
      local initButton = CreateFrame("Button", nil, messageFrame, "UIPanelButtonTemplate")
      initButton:SetSize(200, 24)
      initButton:SetPoint("TOP", messageText, "BOTTOM", 0, -10)
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

    -- Clean up any orphaned spell frames that might remain from previous updates
    -- This must be after we've initialized scrollContent
    for _, child in ipairs({ scrollContent:GetChildren() }) do
      -- Skip messageFrame which is only created when DB isn't initialized
      if child.GetObjectType and child:GetObjectType() == "Frame" and not child.deleteButton and not child.initButton then
        child:Hide()
        child:SetParent(nil)
      end
    end

    -- Get combinations filtered for the current class
    local sortedCombos = {}
    local currentClass = select(2, UnitClass("player"))

    -- Get the current spec's combinations
    local currentCombinations = DM:GetCurrentSpecCombinations()

    if currentCombinations and currentCombinations.data then
      for id, data in pairs(currentCombinations.data) do
        -- Check if this combination should be shown for the current class
        local showCombo = true

        -- If the combination has spells, check if any are from another class
        if data.spells and #data.spells > 0 then
          for _, spellID in ipairs(data.spells) do
            -- Get the spell from the current spec profile
            local currentProfile = DM:GetCurrentSpecProfile()
            if currentProfile and currentProfile.spells and currentProfile.spells[spellID] then
              local spellData = currentProfile.spells[spellID]
              -- If spell is from another class (not current and not UNKNOWN), don't show this combo
              if spellData.wowclass and spellData.wowclass ~= currentClass and spellData.wowclass ~= "UNKNOWN" then
                showCombo = false
                break
              end
            end
          end
        end

        if showCombo then
          table.insert(sortedCombos, { id = id, data = data })
        end
      end
    end

    -- Sort combinations by priority
    table.sort(sortedCombos, function(a, b)
      if a.data.priority and b.data.priority then
        return a.data.priority < b.data.priority
      elseif a.data.priority then
        return true
      elseif b.data.priority then
        return false
      else
        return (a.data.name or "") < (b.data.name or "")
      end
    end)

    -- Normalize priorities to ensure sequential ordering
    local prioritiesChanged = false

    -- Get the current spec's combinations
    currentCombinations = DM:GetCurrentSpecCombinations()

    if currentCombinations and currentCombinations.data then
      for i, combo in ipairs(sortedCombos) do
        -- Ensure every combination has a valid priority
        if not combo.data.priority then
          currentCombinations.data[combo.id].priority = i
          prioritiesChanged = true
          -- Check if priority needs reassignment to maintain consecutive order
        elseif combo.data.priority ~= i then
          currentCombinations.data[combo.id].priority = i
          prioritiesChanged = true
        end
      end
    end

    -- Save if priorities were changed
    if prioritiesChanged then
      DM:SaveCombinationsDB()
      self:DebugMsg("Normalized combination priorities")
    end

    -- Create or update rows for each combination
    local rowHeight = 40 -- Changed from 30 to 40 to match class header height
    local yOffset = 2    -- Changed from 0 to 2 to match tracked spells tab's spacing

    -- Initialize tracking arrays for rows and spell frames
    local allRows = {}
    local allSpellFrames = {}

    for index, comboInfo in ipairs(sortedCombos) do
      local id = comboInfo.id
      local combo = comboInfo.data

      -- Skip if no name or process if combo has a name
      if combo.name then
        -- Create row frame
        local row = CreateFrame("Button", nil, scrollContent)
        row:SetSize(scrollContent:GetWidth(), rowHeight)
        row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -yOffset)
        row:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        row.comboID = id

        table.insert(allRows, row)

        -- Set background
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(0.075, 0.075, 0.075, 0.8)
        row.rowBg = rowBg

        -- Collapse/Expand Indicator
        local indicator = row:CreateTexture(nil, "OVERLAY")
        indicator:SetSize(16, 16)
        indicator:SetPoint("LEFT", row, "LEFT", 10, 0) -- Positioned 10px from left edge

        -- Store ID and data for later use
        row.comboID = id

        -- Set isExpanded state from data with explicit true/false
        -- Fix: There are two places setting isExpanded, causing conflicts
        -- Use an explicit comparison to false instead of a default true value
        -- For new combinations, isExpanded is explicitly set to false in combinations_db.lua
        if combo.isExpanded == nil then
          row.isExpanded = false -- Explicitly default to false if nil
          self:DebugMsg("IMPORTANT: Combination '" ..
            (combo.name or "unnamed") .. "' had nil isExpanded value, defaulting to FALSE")
        else
          row.isExpanded = combo.isExpanded
          self:DebugMsg("Setting initial expand state for combo '" .. (combo.name or "unnamed") ..
            "': " .. tostring(row.isExpanded) ..
            " (stored value: " .. tostring(combo.isExpanded) .. ")")
        end

        -- Update indicator based on expanded state
        if row.isExpanded then
          indicator:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
        else
          indicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
        end
        row.indicator = indicator

        -- Name text - similar to class names in tracked spells tab
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        nameText:SetPoint("LEFT", row, "LEFT", COLUMN_POSITIONS.NAME + 15, 0) -- Moved 15px right
        nameText:SetWidth(140)                                                -- Width for name text
        nameText:SetJustifyH("LEFT")
        row.nameText = nameText

        -- Initialize spellFrames array to track child frames
        row.spellFrames = {}

        -- Color swatch - positioned at COLOR column
        local colorSwatch = CreateFrame("Button", nil, row)
        colorSwatch:SetSize(20, 20)
        colorSwatch:SetPoint("LEFT", row, "LEFT", COLUMN_POSITIONS.COLOR + 35, 0) -- Moved 35px right from COLOR position
        colorSwatch:SetFrameLevel(row:GetFrameLevel() + 5)                        -- Increase frame level to appear above row

        local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
        colorTexture:SetAllPoints()
        row.colorTexture = colorTexture
        row.colorSwatch = colorSwatch

        -- Add click handler for the color swatch
        colorSwatch:SetScript("OnClick", function()
          -- Store the combo ID for reference
          local comboID = row.comboID

          -- Get the current spec's combinations
          local currentCombinations = DM:GetCurrentSpecCombinations()
          if not currentCombinations or not currentCombinations.data or not currentCombinations.data[comboID] then
            return
          end

          local combo = currentCombinations.data[comboID]
          local currentColor = combo.color or { r = 1, g = 0, b = 0, a = 1 }
          -- Convert array-style color to r,g,b,a if needed
          local r = currentColor.r or currentColor[1] or 1
          local g = currentColor.g or currentColor[2] or 0
          local b = currentColor.b or currentColor[3] or 0
          local a = currentColor.a or currentColor[4] or 1

          -- Try to use the color picker from DotMaster_ColorPicker
          if DotMaster_ColorPicker and DotMaster_ColorPicker.CreateColorSwatch then
            -- Create color picker info
            local colorPickerInfo = {
              r = r,
              g = g,
              b = b,
              opacity = a,
              hasOpacity = true,

              -- When color is changed
              swatchFunc = function()
                -- Get the new color values
                local newR, newG, newB
                if ColorPickerFrame.GetColorRGB then
                  newR, newG, newB = ColorPickerFrame:GetColorRGB()
                else
                  newR, newG, newB = ColorPickerFrame:GetColorValues()
                end

                -- Get alpha value
                local newA = a
                if OpacitySliderFrame and OpacitySliderFrame.GetValue then
                  newA = OpacitySliderFrame:GetValue()
                elseif ColorPickerFrame.opacity then
                  newA = ColorPickerFrame.opacity
                end

                -- Get the current spec's combinations again to ensure we have the latest data
                local currentCombinations = DM:GetCurrentSpecCombinations()
                if currentCombinations and currentCombinations.data and currentCombinations.data[comboID] then
                  -- Update color in database
                  currentCombinations.data[comboID].color = {
                    r = newR, g = newG, b = newB, a = newA
                  }

                  -- Save the updated combinations data
                  DM:SaveCombinationsDB()

                  -- Apply immediate color updates to this row
                  row.colorTexture:SetColorTexture(newR, newG, newB, newA)
                  row.rowBg:SetColorTexture(newR * 0.2, newG * 0.2, newB * 0.2, 0.8)
                  row.nameText:SetTextColor(newR, newG, newB)

                  -- Use our refresh function to update all instances of this combo
                  if DM.RefreshCombinationColors then
                    DM:RefreshCombinationColors()
                  end
                end
              end,

              -- Standard color picker function
              func = function() end,

              -- When color picker is canceled
              cancelFunc = function()
                -- No need to do anything, the color hasn't changed
              end
            }

            -- Show the color picker
            ColorPickerFrame:Hide() -- Hide first to ensure a refresh

            -- Use appropriate API
            if ColorPickerFrame.SetupColorPickerAndShow then
              ColorPickerFrame:SetupColorPickerAndShow(colorPickerInfo)
            else
              -- Older method - manually set each property
              ColorPickerFrame.func = colorPickerInfo.swatchFunc
              ColorPickerFrame.swatchFunc = colorPickerInfo.swatchFunc
              ColorPickerFrame.cancelFunc = colorPickerInfo.cancelFunc
              ColorPickerFrame.opacityFunc = colorPickerInfo.swatchFunc
              ColorPickerFrame.hasOpacity = colorPickerInfo.hasOpacity
              ColorPickerFrame.opacity = colorPickerInfo.opacity
              ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

              -- Set colors based on available API
              if ColorPickerFrame.SetColorRGB then
                ColorPickerFrame:SetColorRGB(r, g, b)
              else
                -- Manually set RGB values for ElvUI
                ColorPickerFrame:SetColorAlpha(r, g, b, a)
              end

              -- Show the frame
              ColorPickerFrame:Show()
            end
          end
        end)

        -- Edit button - positioned at ACTIONS column
        local editButton = CreateFrame("Button", nil, row)
        editButton:SetSize(24, 24)
        editButton:SetPoint("LEFT", row, "LEFT", COLUMN_POSITIONS.ACTIONS, 0)
        editButton:SetFrameLevel(row:GetFrameLevel() + 5)

        -- Add edit icon texture
        local editIcon = editButton:CreateTexture(nil, "ARTWORK")
        editIcon:SetAllPoints()
        editIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
        editButton:SetNormalTexture(editIcon)

        -- Add highlight texture
        local editHighlight = editButton:CreateTexture(nil, "HIGHLIGHT")
        editHighlight:SetAllPoints()
        editHighlight:SetTexture("Interface\\Buttons\\UI-OptionsButton")
        editHighlight:SetBlendMode("ADD")
        editButton:SetHighlightTexture(editHighlight)

        row.editButton = editButton

        -- Add click handler for edit button
        editButton:SetScript("OnClick", function()
          -- Open edit dialog with the combo ID
          DM:ShowCombinationDialog(row.comboID)
        end)

        -- Delete button - positioned right after edit button
        local deleteButton = CreateFrame("Button", nil, row)
        deleteButton:SetSize(24, 24)
        deleteButton:SetPoint("LEFT", editButton, "RIGHT", 8, 0)
        deleteButton:SetFrameLevel(row:GetFrameLevel() + 5)

        -- Add delete icon texture
        local deleteIcon = deleteButton:CreateTexture(nil, "ARTWORK")
        deleteIcon:SetAllPoints()
        deleteIcon:SetTexture("Interface\\Buttons\\UI-StopButton")
        deleteButton:SetNormalTexture(deleteIcon)

        -- Add highlight texture
        local deleteHighlight = deleteButton:CreateTexture(nil, "HIGHLIGHT")
        deleteHighlight:SetAllPoints()
        deleteHighlight:SetTexture("Interface\\Buttons\\UI-StopButton")
        deleteHighlight:SetBlendMode("ADD")
        deleteButton:SetHighlightTexture(deleteHighlight)

        row.deleteButton = deleteButton

        -- Add click handler for delete button
        deleteButton:SetScript("OnClick", function()
          local comboID = row.comboID
          if not comboID then return end

          -- Get the current spec's combinations to get the combo name
          local currentCombinations = DM:GetCurrentSpecCombinations()
          if not currentCombinations or not currentCombinations.data or not currentCombinations.data[comboID] then
            return
          end

          local comboName = currentCombinations.data[comboID].name or "Unnamed"

          -- Ask for confirmation first
          StaticPopupDialogs["DOTMASTER_DELETE_COMBINATION"] = {
            text = "Delete combination '" .. comboName .. "'?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
              -- First clean up any spell frames for this combination
              if scrollContent then
                for _, child in pairs({ scrollContent:GetChildren() }) do
                  if child.combinationID and child.combinationID == comboID then
                    child:Hide()
                    child:SetParent(nil)
                  end
                end
              end

              -- Delete the combination
              if DM.DeleteCombination then
                DM:DeleteCombination(comboID)
                -- Refresh the list
                UpdateCombinationsList()
              end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show("DOTMASTER_DELETE_COMBINATION")
        end)

        -- Order buttons - positioned at ORDER column
        -- First DOWN arrow at ORDER position, then UP arrow (same as tracked spells tab)
        local downArrow = CreateFrame("Button", nil, row)
        downArrow:SetSize(20, 20)
        downArrow:SetPoint("LEFT", row, "LEFT", COLUMN_POSITIONS.ORDER, 0) -- Position at ORDER column
        downArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        downArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
        downArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        downArrow:SetFrameLevel(row:GetFrameLevel() + 5) -- Increase frame level to appear above row

        -- Disable down arrow for last item
        if index == #sortedCombos then
          downArrow:Disable()
          downArrow:SetAlpha(0.5)
        else
          downArrow:Enable()
          downArrow:SetAlpha(1.0)
        end

        -- Down arrow click handler
        downArrow:SetScript("OnClick", function()
          if index < #sortedCombos then
            local nextComboInfo = sortedCombos[index + 1]
            local currentComboID = comboInfo.id
            local nextComboID = nextComboInfo.id

            -- Get the current spec's combinations
            local currentCombinations = DM:GetCurrentSpecCombinations()
            if not currentCombinations or not currentCombinations.data then
              return
            end

            -- Get current priorities
            local currentPriority = currentCombinations.data[currentComboID].priority
            local nextPriority = currentCombinations.data[nextComboID].priority

            -- Swap priorities
            currentCombinations.data[currentComboID].priority = nextPriority
            currentCombinations.data[nextComboID].priority = currentPriority

            -- Save changes to database
            DM:SaveCombinationsDB()
            DM:DebugMsg(string.format("Swapped priority for combination %s (now %d) and %s (now %d)",
              currentComboID, nextPriority, nextComboID, currentPriority))

            -- Refresh the combinations list
            UpdateCombinationsList()
          end
        end)

        -- Up arrow (positioned to the right of down arrow with 2px gap)
        local upArrow = CreateFrame("Button", nil, row)
        upArrow:SetSize(20, 20)
        upArrow:SetPoint("LEFT", downArrow, "RIGHT", 2, 0) -- 2px gap between arrows
        upArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
        upArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
        upArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        upArrow:SetFrameLevel(row:GetFrameLevel() + 5) -- Increase frame level to appear above row

        -- Disable up arrow for first item
        if index == 1 then
          upArrow:Disable()
          upArrow:SetAlpha(0.5)
        else
          upArrow:Enable()
          upArrow:SetAlpha(1.0)
        end

        -- Up arrow click handler
        upArrow:SetScript("OnClick", function()
          if index > 1 then
            local prevComboInfo = sortedCombos[index - 1]
            local currentComboID = comboInfo.id
            local prevComboID = prevComboInfo.id

            -- Get the current spec's combinations
            local currentCombinations = DM:GetCurrentSpecCombinations()
            if not currentCombinations or not currentCombinations.data then
              return
            end

            -- Get current priorities
            local currentPriority = currentCombinations.data[currentComboID].priority
            local prevPriority = currentCombinations.data[prevComboID].priority

            -- Swap priorities
            currentCombinations.data[currentComboID].priority = prevPriority
            currentCombinations.data[prevComboID].priority = currentPriority

            -- Save changes to database
            DM:SaveCombinationsDB()
            DM:DebugMsg(string.format("Swapped priority for combination %s (now %d) and %s (now %d)",
              currentComboID, prevPriority, prevComboID, currentPriority))

            -- Refresh the combinations list
            UpdateCombinationsList()
          end
        end)

        -- Add click handler for the entire row for expansion/collapse
        row:SetScript("OnClick", function(self, button)
          if button == "LeftButton" then
            -- Toggle expanded state
            self.isExpanded = not self.isExpanded

            -- Get the current spec's combinations to update the database
            local currentCombinations = DM:GetCurrentSpecCombinations()
            if currentCombinations and currentCombinations.data and currentCombinations.data[self.comboID] then
              -- Update the isExpanded state in the database
              currentCombinations.data[self.comboID].isExpanded = self.isExpanded

              -- Debug expansion state
              DM:DebugMsg("Combo '" .. currentCombinations.data[self.comboID].name ..
                "' expanded state changed to: " .. tostring(self.isExpanded))

              -- Save the change to database
              DM:SaveCombinationsDB()
            end

            -- Update indicator texture
            if self.isExpanded then
              self.indicator:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
            else
              self.indicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
            end

            -- Update visibility of spell frames
            for _, spellFrame in ipairs(self.spellFrames or {}) do
              if self.isExpanded then
                spellFrame:Show()
              else
                spellFrame:Hide()
              end
            end

            -- Recalculate layout
            UpdateCombinationsLayout()
          elseif button == "RightButton" then
            -- Right-click also calls the edit function
            DM:ShowCombinationDialog(self.comboID)
          end
        end)

        combinationRows[index] = row

        -- Now handle all the settings for this row that were previously outside the if statement
        -- Position the row
        row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -yOffset)
        row:SetWidth(scrollContent:GetWidth()) -- Match scroll content width

        -- Store ID and data for later use
        row.comboID = id

        -- REMOVED: Duplicate expanded state code (conflicts with line 373)
        -- row.isExpanded = combo.isExpanded or true

        -- REMOVED: Duplicate indicator texture setting
        -- row.indicator:SetTexture(row.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
        --   "Interface\\Buttons\\UI-PlusButton-Up")

        -- Update background color with a dimmed version of the combination's color
        if not row.rowBg then
          local rowBg = row:CreateTexture(nil, "BACKGROUND")
          rowBg:SetAllPoints()
          row.rowBg = rowBg
        end

        if combo.color then
          local r = combo.color.r or combo.color[1] or 1
          local g = combo.color.g or combo.color[2] or 0
          local b = combo.color.b or combo.color[3] or 0
          -- Use 20% of the original color to create a dimmed background
          row.rowBg:SetColorTexture(r * 0.2, g * 0.2, b * 0.2, 0.8)
        else
          -- Fallback neutral dark grey if no color
          row.rowBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        end

        -- Update text fields - match class name style with combination color
        row.nameText:SetText(combo.name or "Unnamed")
        if combo.color then
          local r = combo.color.r or combo.color[1] or 1
          local g = combo.color.g or combo.color[2] or 0
          local b = combo.color.b or combo.color[3] or 0
          row.nameText:SetTextColor(r, g, b)       -- Use combination's color for text
        else
          row.nameText:SetTextColor(0.8, 0.8, 0.8) -- Default light grey
        end

        -- Update color swatch
        if combo.color then
          row.colorTexture:SetColorTexture(
            combo.color.r or combo.color[1] or 1,
            combo.color.g or combo.color[2] or 0,
            combo.color.b or combo.color[3] or 0,
            combo.color.a or combo.color[4] or 1
          )
        else
          row.colorTexture:SetColorTexture(0.7, 0.7, 0.7, 1)
        end

        -- Button handlers - replaced with comment to avoid duplicate click handlers
        --row.editButton:SetScript("OnClick", function()
        --  DM:ShowCombinationDialog(id)
        --end)

        -- Delete button click handler - REMOVE THIS DUPLICATE SECTION
        row.deleteButton:SetScript("OnClick", function()
          local comboID = row.comboID
          if not comboID then return end

          -- Get the current spec's combinations to get the combo name
          local currentCombinations = DM:GetCurrentSpecCombinations()
          if not currentCombinations or not currentCombinations.data or not currentCombinations.data[comboID] then
            return
          end

          local comboName = currentCombinations.data[comboID].name or "Unnamed"

          -- Ask for confirmation first
          StaticPopupDialogs["DOTMASTER_DELETE_COMBINATION"] = {
            text = "Delete combination '" .. comboName .. "'?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
              -- First clean up any spell frames for this combination
              if scrollContent then
                for _, child in pairs({ scrollContent:GetChildren() }) do
                  if child.combinationID and child.combinationID == comboID then
                    child:Hide()
                    child:SetParent(nil)
                  end
                end
              end

              -- Delete the combination
              if DM.DeleteCombination then
                DM:DeleteCombination(comboID)
                -- Refresh the list
                UpdateCombinationsList()
              end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show("DOTMASTER_DELETE_COMBINATION")
        end)

        -- Store the combo ID in the row for drag & drop
        row.comboID = id

        -- Setup click handling for expand/collapse
        row:SetScript("OnClick", function(self, button, down)
          if button == "LeftButton" then
            -- Toggle expanded state
            self.isExpanded = not self.isExpanded
            DM:DebugMsg("Toggling expand state for " ..
              combo.name .. " to: " .. tostring(self.isExpanded) .. ", spellFrames count: " .. #self.spellFrames)

            -- Get the current spec's combinations to update the database
            local currentCombinations = DM:GetCurrentSpecCombinations()
            if currentCombinations and currentCombinations.data and currentCombinations.data[id] then
              -- Update the isExpanded state in the database
              currentCombinations.data[id].isExpanded = self.isExpanded
            end

            -- Update indicator
            if self.isExpanded then
              self.indicator:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
            else
              self.indicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
            end

            -- Show/hide spell frames for this combination
            if self.spellFrames and #self.spellFrames > 0 then
              DM:DebugMsg("Processing " .. #self.spellFrames .. " spell frames")

              for i, frame in ipairs(self.spellFrames) do
                if frame and frame.SetShown then
                  frame:SetShown(self.isExpanded)
                  DM:DebugMsg("  - Setting spell frame " .. i .. " visibility to " .. tostring(self.isExpanded))
                else
                  DM:DebugMsg("  - Invalid spell frame at index " .. i)
                end
              end
            else
              DM:DebugMsg("No spell frames found for this combination")
            end

            -- Save changes to database
            DM:SaveCombinationsDB()

            -- Update layout
            if container and container.UpdateCombinationsLayout then
              container:UpdateCombinationsLayout()
            end
          end
        end)

        -- Show the row
        row:Show()

        -- Update yOffset for next row
        yOffset = yOffset + rowHeight

        -- Create spell frames for this combination
        if combo.spells and #combo.spells > 0 then
          -- Create frames for each spell in the combination
          local spellRowHeight = 25
          for i, spellID in ipairs(combo.spells) do
            local spellFrame = CreateFrame("Frame", nil, scrollContent)
            spellFrame:SetSize(scrollContent:GetWidth(), spellRowHeight)

            -- Tag this spell frame with its parent combination ID for tracking
            spellFrame.combinationID = id

            -- Add to tracking arrays - BUT ONLY ONCE (not again at the end of the loop)
            table.insert(row.spellFrames, spellFrame)
            table.insert(allSpellFrames, spellFrame)

            -- Hide spell frame initially if combination is collapsed, otherwise explicitly show it
            -- Important: Default to hidden for newly created combinations
            if row.isExpanded == false then
              spellFrame:Hide()
              self:DebugMsg("Hiding spell frame for collapsed combination: " .. combo.name)
            else
              -- Force showing spell frames for expanded combinations
              spellFrame:Show()
              self:DebugMsg("Showing spell frame for expanded combination: " .. combo.name ..
                " (isExpanded=" .. tostring(row.isExpanded) ..
                ", stored value=" .. tostring(combo.isExpanded) .. ")")
            end

            -- Set alternating background
            local bg = spellFrame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            -- Slightly darker shade for odd, lighter for even (for contrast)
            if i % 2 == 0 then
              bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)    -- Darker
            else
              bg:SetColorTexture(0.17, 0.17, 0.17, 0.7) -- Lighter
            end

            -- Spell icon - position indented from main row
            local icon = spellFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(spellRowHeight - 6, spellRowHeight - 6) -- Slightly smaller than row
            icon:SetPoint("LEFT", spellFrame, "LEFT", 25, 0)     -- Indented by 25px

            -- Get spell info and icon from current spec's profile
            local currentProfile = DM:GetCurrentSpecProfile()
            local spellName = "Unknown"
            local spellIcon = 134400 -- Default question mark

            -- Try to get data from current spec profile
            if currentProfile and currentProfile.spells and currentProfile.spells[spellID] then
              local spellData = currentProfile.spells[spellID]
              spellName = spellData.spellname or spellName
              spellIcon = spellData.spellicon or spellIcon
            else
              -- Fallback to API if not in profile
              local spellInfo = C_Spell.GetSpellInfo(spellID)
              if spellInfo then
                spellName = spellInfo.name or spellName
                spellIcon = spellInfo.iconFileID or spellIcon
              end
            end

            icon:SetTexture(spellIcon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim border

            -- Spell name text
            local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            nameText:SetPoint("RIGHT", spellFrame, "RIGHT", -5, 0)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(spellName .. " (" .. spellID .. ")")
            -- No spell action buttons needed in the collapsed view
          end
        end
      end

      -- Continue to next combination
    end

    -- Update scrolling frame content height
    scrollContent:SetHeight(math.max(yOffset, scrollContent:GetParent():GetHeight()))

    -- Store references for cleanup on next update
    container.allRows = allRows
    container.allSpellFrames = allSpellFrames
  end

  -- Store the update function
  container.UpdateCombinationsList = UpdateCombinationsList
  container.UpdateCombinationsLayout = UpdateCombinationsLayout

  -- Export functions to the main addon
  DM.GUI = DM.GUI or {}
  DM.GUI.UpdateCombinationsList = function()
    if container and container.UpdateCombinationsList then
      container:UpdateCombinationsList()
    end
  end
  DM.GUI.UpdateCombinationsLayout = function()
    if container and container.UpdateCombinationsLayout then
      container:UpdateCombinationsLayout()
    end
  end

  -- Setup drag & drop for reordering
  -- (This will be implemented with scrollable elements)

  -- Initial update after creation
  C_Timer.After(0.2, UpdateCombinationsList)

  -- Setup mouse wheel scrolling since scrollbars are hidden
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local currentScroll = self:GetVerticalScroll()
    local scrollRange = self:GetVerticalScrollRange()

    -- Calculate new scroll position (faster scrolling with higher step)
    local newPosition = currentScroll - (delta * 30)

    -- Clamp scroll position to valid range
    newPosition = math.max(0, math.min(newPosition, scrollRange))

    -- Apply the scroll
    self:SetVerticalScroll(newPosition)
  end)

  -- Initialize the tab
  C_Timer.After(0.2, UpdateCombinationsList)

  -- Add a second delayed refresh to handle reload cases
  C_Timer.After(2.0, function()
    if container and container.UpdateCombinationsList then
      self:DebugMsg("Performing delayed combinations list refresh")
      container:UpdateCombinationsList()

      -- Add a third refresh specifically for fixing color issues
      C_Timer.After(0.5, function()
        local currentCombinations = DM:GetCurrentSpecCombinations()
        if currentCombinations and currentCombinations.data and next(currentCombinations.data) then
          -- Force the update of each row's colors if it exists
          for id, combo in pairs(currentCombinations.data) do
            for _, row in ipairs(allRows or {}) do
              if row.comboID == id and row.rowBg and row.nameText and combo.color then
                -- Get color components
                local r = combo.color.r or combo.color[1] or 1
                local g = combo.color.g or combo.color[2] or 0
                local b = combo.color.b or combo.color[3] or 0

                -- Update background
                row.rowBg:SetColorTexture(r * 0.2, g * 0.2, b * 0.2, 0.8)

                -- Update text color
                row.nameText:SetTextColor(r, g, b)

                -- Update color swatch if it exists
                if row.colorTexture then
                  row.colorTexture:SetColorTexture(r, g, b, 1)
                end
              end
            end
          end
        end
      end)
    end
  end)

  -- Register functions with container and main GUI for external calls
  container.UpdateCombinationsList = UpdateCombinationsList

  return container
end

-- Combination Dialog
function DM:ShowCombinationDialog(comboID)
  -- Create dialog frame if it doesn't exist
  if not DM.GUI.combinationDialog then
    local dialog = CreateFrame("Frame", "DotMasterCombinationDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(350, 450) -- Match the spell selection window size

    -- Position dialog using screen dimensions for consistent placement
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", screenWidth * 0.3, screenHeight * 0.8)

    dialog:SetFrameStrata("DIALOG")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)

    -- Set backdrop
    dialog:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", -- Same as main window
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    dialog:SetBackdropColor(0.05, 0.05, 0.05, 0.95) -- Darker background to match main window

    -- Title - centered at top with more space
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -20)
    title:SetText("New Combination")
    title:SetWidth(dialog:GetWidth() - 40)
    title:SetJustifyH("CENTER")
    dialog.title = title

    -- Close button
    local closeButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetSize(28, 28)

    -- Form elements
    -- Name field
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOP", title, "BOTTOM", 0, -20)
    nameLabel:SetText("Combination Name:")
    nameLabel:SetJustifyH("CENTER")

    local nameEditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    nameEditBox:SetSize(190, 25) -- Match add spell button width
    nameEditBox:SetPoint("TOP", nameLabel, "BOTTOM", 0, -5)
    nameEditBox:SetAutoFocus(false)
    nameEditBox:SetMaxLetters(50)
    dialog.nameEditBox = nameEditBox

    -- Color picker - with equal spacing above and below
    local colorLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOP", nameEditBox, "BOTTOM", 0, -15)
    colorLabel:SetText("Combination Color:")
    colorLabel:SetJustifyH("CENTER")

    local colorButton = CreateFrame("Button", nil, dialog)
    colorButton:SetSize(30, 30)
    colorButton:SetPoint("TOP", colorLabel, "BOTTOM", 0, -8)

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

      -- Create a simpler color picker info table compatible with both standard and ElvUI
      local colorPickerInfo = {
        r = r,
        g = g,
        b = b,
        opacity = a,
        hasOpacity = true,

        -- When color is changed (swatchFunc is used by ElvUI)
        swatchFunc = function()
          -- Get the new color values - need to check which API is available
          local newR, newG, newB
          if ColorPickerFrame.GetColorRGB then -- Standard API
            newR, newG, newB = ColorPickerFrame:GetColorRGB()
          else                                 -- ElvUI may replace with these values
            newR, newG, newB = ColorPickerFrame:GetColorValues()
          end

          -- Get alpha value - need to handle ElvUI's modifications
          local newA = a -- Default to current alpha if we can't get a new one
          if OpacitySliderFrame and OpacitySliderFrame.GetValue then
            newA = OpacitySliderFrame:GetValue()
          elseif ColorPickerFrame.opacity then
            newA = ColorPickerFrame.opacity
          end

          -- Update selected color
          dialog.selectedColor = {
            r = newR,
            g = newG,
            b = newB,
            a = newA
          }

          -- Update color swatch
          dialog.colorTexture:SetColorTexture(newR, newG, newB, newA)
        end,

        -- Used by ElvUI or standard color picker
        func = function()
          -- This will be called too in some cases, but we handle everything in swatchFunc
        end,

        -- When color picker is canceled
        cancelFunc = function()
          -- Restore original color
          dialog.selectedColor = {
            r = r,
            g = g,
            b = b,
            a = a
          }

          -- Update color swatch
          dialog.colorTexture:SetColorTexture(r, g, b, a)
        end
      }

      -- Show the color picker
      ColorPickerFrame:Hide() -- Hide first to ensure a refresh

      -- Try the standard API first, fall back to old method if not available
      if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(colorPickerInfo)
      else
        -- Older method - manually set each property
        ColorPickerFrame.func = colorPickerInfo.swatchFunc
        ColorPickerFrame.swatchFunc = colorPickerInfo.swatchFunc
        ColorPickerFrame.cancelFunc = colorPickerInfo.cancelFunc
        ColorPickerFrame.opacityFunc = colorPickerInfo.swatchFunc
        ColorPickerFrame.hasOpacity = colorPickerInfo.hasOpacity
        ColorPickerFrame.opacity = colorPickerInfo.opacity
        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

        -- Set colors based on available API
        if ColorPickerFrame.SetColorRGB then
          ColorPickerFrame:SetColorRGB(r, g, b)
        else
          -- Manually set RGB values for ElvUI
          ColorPickerFrame:SetColorAlpha(r, g, b, a)
        end

        -- Show the frame
        ColorPickerFrame:Show()
      end
    end)

    -- Spell list - with equal spacing as above the color label
    local spellListLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellListLabel:SetPoint("TOP", colorButton, "BOTTOM", 0, -8)
    spellListLabel:SetText("Spells in this Combination:")
    spellListLabel:SetJustifyH("CENTER")

    -- Spells scroll frame
    local spellsFrame = CreateFrame("Frame", nil, dialog)
    spellsFrame:SetSize(310, 200) -- 350 (dialog width) - 20 (left margin) - 20 (right margin)
    spellsFrame:SetPoint("TOP", spellListLabel, "BOTTOM", 0, -5)

    local spellsScroll = CreateFrame("ScrollFrame", nil, spellsFrame, "UIPanelScrollFrameTemplate")
    spellsScroll:SetPoint("TOPLEFT", 0, 0)
    spellsScroll:SetPoint("BOTTOMRIGHT", 0, 0) -- No space reserved for scrollbar

    -- Hide scrollbar
    local scrollBar = nil
    if spellsScroll:GetName() then
      scrollBar = _G[spellsScroll:GetName() .. "ScrollBar"]
    else
      -- For frames without names, try to get scrollbar directly from children
      for _, child in pairs({ spellsScroll:GetChildren() }) do
        if child:IsObjectType("Slider") then
          scrollBar = child
          break
        end
      end
    end

    if scrollBar then
      scrollBar:SetWidth(0)
      scrollBar:SetAlpha(0)
    end

    local spellsContent = CreateFrame("Frame", nil, spellsScroll)
    spellsContent:SetSize(spellsScroll:GetWidth(), 300)
    spellsScroll:SetScrollChild(spellsContent)
    dialog.spellsContent = spellsContent

    -- Add spell button
    local addSpellButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    addSpellButton:SetSize(190, 25)
    addSpellButton:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 40)
    addSpellButton:SetText("Add Spell")

    addSpellButton:SetScript("OnClick", function()
      -- Show spell selection UI
      DM:ShowSpellSelectionForCombo(dialog)
    end)

    -- Save/Cancel buttons
    local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelButton:SetSize(90, 25)
    cancelButton:SetPoint("BOTTOMLEFT", addSpellButton, "BOTTOMLEFT", 0, -30)
    cancelButton:SetText("Cancel")

    cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)

    local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    saveButton:SetSize(90, 25)
    saveButton:SetPoint("BOTTOMRIGHT", addSpellButton, "BOTTOMRIGHT", 0, -30)
    saveButton:SetText("Save")

    saveButton:SetScript("OnClick", function()
      -- Save the combination
      local name = dialog.nameEditBox:GetText()
      local color = dialog.selectedColor
      local spells = dialog.selectedSpells or {}

      -- Validate
      if name == "" then
        -- Create warning popup for missing name
        StaticPopupDialogs["DOTMASTER_WARNING_NO_NAME"] = {
          text = "Please enter a name for the combination.",
          button1 = "OK",
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show("DOTMASTER_WARNING_NO_NAME")
        return
      end

      if #spells == 0 then
        -- Create warning popup for no spells
        StaticPopupDialogs["DOTMASTER_WARNING_NO_SPELLS"] = {
          text = "Please add at least one spell to the combination.",
          button1 = "OK",
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show("DOTMASTER_WARNING_NO_SPELLS")
        return
      end

      -- Check for duplicate name
      local isDuplicate = false
      -- Get the current spec's combinations
      local currentCombinations = DM:GetCurrentSpecCombinations()
      if currentCombinations and currentCombinations.data then
        for id, combo in pairs(currentCombinations.data) do
          -- Skip the current combo when editing
          if id ~= dialog.comboID and combo.name and combo.name:lower() == name:lower() then
            isDuplicate = true
            break
          end
        end
      end

      if isDuplicate then
        -- Create warning popup for duplicate name
        StaticPopupDialogs["DOTMASTER_WARNING_DUPLICATE_NAME"] = {
          text = "A combination with the name \"" .. name .. "\" already exists.\nPlease choose a different name.",
          button1 = "OK",
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show("DOTMASTER_WARNING_DUPLICATE_NAME")
        return
      end

      -- Check if we're editing or creating
      if dialog.comboID then
        -- Update existing
        DM:UpdateCombination(dialog.comboID, {
          name = name,
          color = color,
          spells = spells,
          isExpanded = dialog.isExpanded -- Preserve expanded state
        })
        self:DebugMsg("Updated combination with ID: " ..
          dialog.comboID .. ", isExpanded state preserved as: " .. tostring(dialog.isExpanded))
      else
        -- Create new
        local newID = DM:CreateCombination(name, spells, color)
        self:DebugMsg("Created new combination with ID: " .. tostring(newID) .. ", isExpanded set to false by default")

        -- Force immediate flag setting in case the UI refreshes before database is saved
        local currentCombinations = DM:GetCurrentSpecCombinations()
        if currentCombinations and currentCombinations.data and currentCombinations.data[newID] then
          currentCombinations.data[newID].isExpanded = false
          self:DebugMsg("Explicitly set isExpanded=false for new combination")
        end
      end

      -- Update the list
      if DM.GUI.UpdateCombinationsList then
        DM.GUI:UpdateCombinationsList()
      end

      -- Hide the dialog
      dialog:Hide()
    end)

    -- Store reference
    DM.GUI.combinationDialog = dialog

    -- Setup scrolling and hide scrollbars
    SetupScrollFrames(dialog)
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

  -- Also explicitly remove any FontStrings that might be attached directly
  for _, region in ipairs({ dialog.spellsContent:GetRegions() }) do
    if region:GetObjectType() == "FontString" then
      region:Hide()
      region:SetText("")
    end
  end

  -- If editing existing combo, load data
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if comboID and currentCombinations and currentCombinations.data and currentCombinations.data[comboID] then
    local combo = currentCombinations.data[comboID]

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

    -- Remember the expanded state
    dialog.isExpanded = combo.isExpanded

    -- Display the spells in the spell list
    DM:UpdateCombinationSpellList(dialog)
  else
    dialog.title:SetText("New Combination")
    dialog.comboID = nil

    -- Set default expanded state for new combinations
    dialog.isExpanded = false

    -- Show the empty state message
    DM:UpdateCombinationSpellList(dialog)
  end

  -- Show the dialog
  dialog:Show()

  -- Ensure positioning is correct when shown
  dialog:ClearAllPoints()

  -- Position dialog to the right of the main UI if it exists
  if DM.GUI and DM.GUI.frame and DM.GUI.frame:IsShown() then
    dialog:SetPoint("TOPLEFT", DM.GUI.frame, "TOPRIGHT", 5, 0)
    self:DebugMsg("Positioning combination dialog to the right of main UI")
  else
    -- Fallback - center on screen
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self:DebugMsg("Using fallback center position for combination dialog")
  end
end

-- Function to update the spell list in the combination dialog
function DM:UpdateCombinationSpellList(dialog)
  if not dialog or not dialog.spellsContent or not dialog.selectedSpells then
    self:DebugMsg("UpdateCombinationSpellList: Invalid dialog or missing components")
    return
  end

  -- First, make sure to clean up any previously created region (like FontStrings)
  for _, region in ipairs({ dialog.spellsContent:GetRegions() }) do
    if region:GetObjectType() == "FontString" then
      region:Hide()
      region:ClearAllPoints()
    end
  end

  -- Clean up any frame children as well
  for _, child in ipairs({ dialog.spellsContent:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end

  -- Exit if no spells
  if #dialog.selectedSpells == 0 then
    self:DebugMsg("UpdateCombinationSpellList: No spells in combination")
    local noSpellsText = dialog.spellsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noSpellsText:SetPoint("CENTER", dialog.spellsContent, "CENTER")
    noSpellsText:SetText("Add spells to the combination using the button below")
    noSpellsText:SetTextColor(1, 0.82, 0) -- Gold color for better visibility
    noSpellsText:SetWidth(dialog.spellsContent:GetWidth() - 20)
    noSpellsText:SetJustifyH("CENTER")
    return
  end

  self:DebugMsg("UpdateCombinationSpellList: Displaying " .. #dialog.selectedSpells .. " spells")

  -- Display each spell
  local yOffset = 5
  local rowHeight = 35 -- Slightly smaller rows

  for index, spellID in ipairs(dialog.selectedSpells) do
    self:DebugMsg("Processing spell ID: " .. spellID)

    -- Create spell row
    local row = CreateFrame("Frame", nil, dialog.spellsContent)
    row:SetSize(dialog.spellsContent:GetWidth(), rowHeight)
    row:SetPoint("TOPLEFT", dialog.spellsContent, "TOPLEFT", 0, -yOffset)

    -- Background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    -- Alternating row background
    if (index % 2 == 0) then
      bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)    -- Slightly darker
    else
      bg:SetColorTexture(0.15, 0.15, 0.15, 0.5) -- Slightly lighter
    end

    -- Spell icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(rowHeight - 6, rowHeight - 6) -- Slightly smaller icon
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)

    -- Get spell info safely
    local spellName = "Unknown"
    local spellIcon = 134400 -- Default question mark icon

    -- Try to get data from current spec profile
    local currentProfile = DM:GetCurrentSpecProfile()
    if currentProfile and currentProfile.spells and currentProfile.spells[spellID] then
      local spellData = currentProfile.spells[spellID]
      spellName = spellData.spellname or spellName
      spellIcon = spellData.spellicon or spellIcon
    else
      -- Fallback to API
      local spellInfo = C_Spell.GetSpellInfo(spellID)
      if spellInfo then
        spellName = spellInfo.name or spellName
        spellIcon = spellInfo.iconFileID or spellIcon
      end
    end

    icon:SetTexture(spellIcon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders

    -- Spell name with ID in parentheses
    local name = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -80, 0) -- Reserve space for remove button
    name:SetJustifyH("LEFT")
    name:SetText(string.format("%s (%d)", spellName, spellID))

    -- Remove button
    local removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    removeButton:SetSize(70, 22)
    removeButton:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    removeButton:SetText("Remove")

    removeButton:SetScript("OnClick", function()
      -- Remove this spell from the selectedSpells array
      for i, id in ipairs(dialog.selectedSpells) do
        if id == spellID then
          table.remove(dialog.selectedSpells, i)
          self:DebugMsg("Removed spell ID " .. spellID .. " from combination")
          break
        end
      end

      -- Update the display
      self:UpdateCombinationSpellList(dialog)
    end)

    row:Show()
    yOffset = yOffset + rowHeight + 2 -- 2 pixels spacing between rows
  end

  -- Update content height for proper scrolling
  dialog.spellsContent:SetHeight(math.max(yOffset, dialog.spellsContent:GetHeight()))
end

-- Function to show delete confirmation
function DM:ShowDeleteConfirmation(comboID, callback)
  -- Get the current spec's combinations
  local currentCombinations = DM:GetCurrentSpecCombinations()
  if not comboID or not currentCombinations or not currentCombinations.data or not currentCombinations.data[comboID] then
    return
  end

  local combo = currentCombinations.data[comboID]

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
  -- Verify parent exists and has the required properties
  if not parent then
    self:DebugMsg("ERROR: ShowSpellSelectionForCombo called with nil parent")
    return
  end

  if not parent.selectedSpells then
    self:DebugMsg("Initializing selectedSpells array in parent dialog")
    parent.selectedSpells = {}
  end

  -- Function to update the spell list display - defined outside the if condition
  local function UpdateSpellList(frame, selectedSpells)
    -- We need to find the scrollFrame and its content
    local scrollFrame = nil

    -- Find the scroll frame by searching through children
    for _, child in pairs({ frame:GetChildren() }) do
      if child:IsObjectType("ScrollFrame") then
        scrollFrame = child
        break
      end
    end

    if not scrollFrame then
      self:DebugMsg("ERROR: UpdateSpellList - scrollFrame not found")
      return
    end

    -- Get the scroll content
    local scrollContent = scrollFrame:GetScrollChild()
    if not scrollContent then
      self:DebugMsg("ERROR: UpdateSpellList - scrollContent not found")
      return
    end

    -- Clear existing spell buttons
    for _, child in ipairs({ scrollContent:GetChildren() }) do
      child:Hide()
    end

    -- If current spec profile isn't available, show error
    local currentProfile = DM:GetCurrentSpecProfile()
    if not currentProfile or not currentProfile.spells then
      local errorText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      errorText:SetPoint("CENTER", scrollContent, "CENTER", 0, 0)
      errorText:SetText("Current specialization spells not available")
      errorText:SetTextColor(1, 0.3, 0.3)
      return
    end

    -- Get parent dialog's already added spells for filtering
    local parentDialog = frame.parentDialog
    local existingSpells = {}
    if parentDialog and parentDialog.selectedSpells then
      for _, spellID in ipairs(parentDialog.selectedSpells) do
        existingSpells[spellID] = true
      end
    end

    -- Get player class
    local _, playerClass = UnitClass("player")

    -- Filter spells based on player class and exclude already added spells
    local filteredSpells = {}

    -- Get the current spec profile instead of using DM.dmspellsdb
    local currentProfile = DM:GetCurrentSpecProfile()
    if currentProfile and currentProfile.spells then
      for spellIDStr, spellData in pairs(currentProfile.spells) do
        local numericID = tonumber(spellIDStr)
        -- Check if tracked and not already in combination
        if numericID and spellData.tracked == 1 and not existingSpells[numericID] then
          -- Add to filtered list
          table.insert(filteredSpells, { id = numericID, data = spellData })
        end
      end
    end

    -- Sort spells by name
    table.sort(filteredSpells, function(a, b)
      local nameA = a.data.spellname or ""
      local nameB = b.data.spellname or ""
      return nameA < nameB
    end)

    -- Create UI elements for each spell
    local buttonHeight = 44
    local yOffset = 0

    -- Check if we have any spells after filtering and add guidance if none found
    if #filteredSpells == 0 then
      -- Create a help message frame
      local helpFrame = CreateFrame("Frame", nil, scrollContent)
      helpFrame:SetSize(scrollContent:GetWidth(), 120)
      helpFrame:SetPoint("TOP", scrollContent, "TOP", 0, -10)

      -- Add message text
      local helpText = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      helpText:SetPoint("TOP", helpFrame, "TOP", 0, 0)
      helpText:SetWidth(scrollContent:GetWidth() - 40)
      helpText:SetText(
        "No additional spells available.\n\nYou need to mark spells as 'tracked' for your current specialization in the Database tab.")
      helpText:SetTextColor(1, 0.82, 0)
      helpText:SetJustifyH("CENTER")
      helpText:SetJustifyV("TOP")
      helpText:SetSpacing(5)

      scrollContent:SetHeight(120)
      return
    end

    for index, spellInfo in ipairs(filteredSpells) do
      local spellID = spellInfo.id
      local spellData = spellInfo.data

      -- Create button for this spell
      local button = CreateFrame("Frame", nil, scrollContent)
      button:SetSize(scrollContent:GetWidth(), buttonHeight)
      button:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -yOffset)
      button:EnableMouse(true) -- Make the button clickable

      -- Background - consistent color instead of alternating
      local bg = button:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()

      -- Use a single consistent background color with selection highlighting
      local isSelected = selectedSpells[spellID] or false
      if isSelected then
        bg:SetColorTexture(0.3, 0.3, 0.3, 0.9) -- Brighter for selected
      else
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.9) -- Dark for unselected
      end

      -- Spell icon
      local iconSize = buttonHeight - 16
      local icon = button:CreateTexture(nil, "ARTWORK")
      icon:SetSize(iconSize, iconSize)
      icon:SetPoint("LEFT", button, "LEFT", 5, 0)

      -- Get spell icon
      local spellIcon = 134400 -- Default to question mark
      if currentProfile and currentProfile.spells and currentProfile.spells[spellID] and currentProfile.spells[spellID].spellicon then
        spellIcon = currentProfile.spells[spellID].spellicon
      end
      icon:SetTexture(spellIcon)

      -- Add checkbox
      local checkbox = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
      checkbox:SetSize(20, 20)
      checkbox:SetPoint("LEFT", icon, "RIGHT", 10, 0)
      checkbox:SetChecked(isSelected)

      -- Make row click toggle the checkbox
      button:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton == "LeftButton" then
          checkbox:Click()
        end
      end)

      -- Checkbox click handler
      checkbox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if isChecked then
          selectedSpells[spellID] = true
          -- Update background color when selected
          bg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
        else
          selectedSpells[spellID] = nil
          -- Restore normal background color
          bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
        end
      end)

      -- Spell name with ID in parentheses
      local name = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      name:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
      name:SetPoint("RIGHT", button, "RIGHT", -5, 0) -- Extend to the right edge with margin
      name:SetJustifyH("LEFT")
      name:SetText(string.format("%s (%d)", spellData.spellname or "Unknown", spellID))

      button:Show()
      yOffset = yOffset + buttonHeight
    end

    -- Update content height for proper scrolling
    scrollContent:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
  end

  -- Create spell selection frame if it doesn't exist
  if not DM.GUI.comboSpellSelectionFrame then
    local frame = CreateFrame("Frame", "DotMasterComboSpellSelection", UIParent, "BackdropTemplate")
    frame:SetSize(350, 450)
    -- Initial position using screen dimensions
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    frame:SetPoint("TOP", UIParent, "TOP", 0, -50)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Set backdrop
    local _, playerClass = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[playerClass] or RAID_CLASS_COLORS["PRIEST"]

    frame:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", -- Same as main window
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95) -- Darker background to match main window
    frame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1.0)

    -- Title - centered at top with more space
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Current Spec Tracked Spells")
    title:SetWidth(frame:GetWidth() - 40)
    title:SetJustifyH("CENTER")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetSize(28, 28)

    -- Header panel with title and search box
    local headerPanel = CreateFrame("Frame", nil, frame)
    headerPanel:SetSize(frame:GetWidth(), 30)
    headerPanel:SetPoint("TOP", frame, "TOP", 0, -25)

    -- Always filter by class (no checkbox)
    local showOnlyPlayerClass = true

    -- Main scroll frame for spells
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", headerPanel, "BOTTOM", 0, -5)
    scrollFrame:SetPoint("LEFT", frame, "LEFT", 20, 0)
    scrollFrame:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    scrollFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 45)

    -- Hide scrollbar
    local scrollBar = nil
    if scrollFrame:GetName() then
      scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    else
      -- For frames without names, try to get scrollbar directly from children
      for _, child in pairs({ scrollFrame:GetChildren() }) do
        if child:IsObjectType("Slider") then
          scrollBar = child
          break
        end
      end
    end

    if scrollBar then
      scrollBar:SetWidth(0)
      scrollBar:SetAlpha(0)
    end

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

    -- Add button handler
    addButton:SetScript("OnClick", function()
      -- Get the list of selected spell IDs
      local spellList = {}
      for spellID, _ in pairs(selectedSpells) do
        -- Ensure spell ID is numeric
        local numericID = tonumber(spellID)
        if numericID then
          table.insert(spellList, numericID)
          DM:DebugMsg("Selected spell: " .. numericID)
        end
      end

      -- Update the parent dialog using the stored reference
      local parentDialog = frame.parentDialog
      if parentDialog and parentDialog.selectedSpells then
        -- Merge with existing spells (avoid duplicates)
        for _, spellID in ipairs(spellList) do
          local isDuplicate = false
          for _, existingID in ipairs(parentDialog.selectedSpells) do
            if existingID == spellID then
              isDuplicate = true
              break
            end
          end

          if not isDuplicate then
            table.insert(parentDialog.selectedSpells, spellID)
            DM:DebugMsg("Added spell to combination: " .. spellID)
          end
        end

        DM:DebugMsg("Total spells in combination: " .. #parentDialog.selectedSpells)

        -- Update the display in the parent dialog
        DM:UpdateCombinationSpellList(parentDialog)
      else
        DM:DebugMsg("ERROR: Invalid parent reference or missing selectedSpells")
      end

      -- Hide the selection dialog
      frame:Hide()
    end)

    -- Initialize with all spells
    UpdateSpellList(frame, selectedSpells)

    -- Store the frame reference
    DM.GUI.comboSpellSelectionFrame = frame

    -- Setup scrolling and hide scrollbars
    SetupScrollFrames(frame)

    -- Store function for later access and persistent selected spells
    frame.UpdateSpellList = UpdateSpellList
    frame.selectedSpells = selectedSpells
  end

  local frame = DM.GUI.comboSpellSelectionFrame

  -- Store reference to parent dialog
  frame.parentDialog = parent

  -- Reset selected spells if parent has existing selections
  if parent and parent.selectedSpells then
    -- Make sure frame.selectedSpells exists before wiping
    if not frame.selectedSpells then
      frame.selectedSpells = {}
    else
      wipe(frame.selectedSpells)
    end

    -- Mark existing spells as selected
    for _, spellID in ipairs(parent.selectedSpells) do
      frame.selectedSpells[spellID] = true
    end

    -- Refresh the list
    if frame.UpdateSpellList then
      frame.UpdateSpellList(frame, frame.selectedSpells)
    else
      DM:DebugMsg("ERROR: UpdateSpellList function is not available")
    end
  end

  -- Show the frame
  frame:Show()

  -- Position relative to parent dialog or using screen dimensions
  frame:ClearAllPoints()

  -- Position to the right of the parent combination dialog
  if parent and parent:IsShown() then
    frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 5, 0)
    DM:DebugMsg("Positioning spell selection window to the right of combination dialog")
    -- Try to position relative to the main UI frame if no parent available
  elseif DM.GUI and DM.GUI.frame and DM.GUI.frame:IsShown() then
    -- Position far to the right of the main UI, leaving space for the combination dialog
    frame:SetPoint("TOPLEFT", DM.GUI.frame, "TOPRIGHT", 365, 0) -- 350 (combo width) + 10 (gap) + 5 (margin)
    DM:DebugMsg("Positioning spell selection window far right of main UI")
  else
    -- Fallback position - centered
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    DM:DebugMsg("Using fallback position for spell selection window")
  end
end
