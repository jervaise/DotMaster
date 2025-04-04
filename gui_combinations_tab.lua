-- DotMaster gui_combinations_tab.lua
-- Combinations Tab for combining multiple DoTs on nameplates

local DM = DotMaster

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

  -- Create header labels with similar style to tracked spells tab
  local function CreateHeaderLabel(text, xPosition)
    local label = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", headerFrame, "LEFT", xPosition, 0)
    label:SetText(text)
    label:SetTextColor(1, 0.82, 0) -- Gold text color
    return label
  end

  -- Header text - match tracked spells positioning
  CreateHeaderLabel("COMBINATION NAME", 10)
  CreateHeaderLabel("COLOR", 240)
  CreateHeaderLabel("ORDER", 290)
  CreateHeaderLabel("ACTIONS", 350)

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
  addButton:SetSize(200, 25)
  addButton:SetText("Create New Combination")
  addButton:SetPoint("CENTER", contentFrame, "BOTTOM", 0, 10) -- Center align at bottom

  addButton:SetScript("OnClick", function()
    DM:ShowCombinationDialog()
  end)

  -- Store references to the UI elements
  local combinationRows = {}

  -- Function to update the combinations list
  local function UpdateCombinationsList()
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

    -- Get combinations and sort them by priority
    local combos = {}
    if DM.combinations and DM.combinations.data then
      for id, data in pairs(DM.combinations.data) do
        table.insert(combos, { id = id, data = data })
      end
    end

    -- Normalize priorities to ensure sequential ordering
    table.sort(combos, function(a, b)
      if a.data.priority and b.data.priority then
        return a.data.priority < b.data.priority
      elseif a.data.priority then
        return true
      elseif b.data.priority then
        return false
      else
        return a.data.name < b.data.name
      end
    end)

    -- Reassign priorities to ensure they are consecutive numbers
    local prioritiesChanged = false
    for i, combo in ipairs(combos) do
      -- Ensure every combination has a valid priority
      if not combo.data.priority then
        DM.combinations.data[combo.id].priority = i
        prioritiesChanged = true
        -- Check if priority needs reassignment to maintain consecutive order
      elseif combo.data.priority ~= i then
        DM.combinations.data[combo.id].priority = i
        prioritiesChanged = true
      end
    end

    -- Save if priorities were changed
    if prioritiesChanged then
      DM:SaveCombinationsDB()
      self:DebugMsg("Normalized combination priorities")
    end

    -- Re-sort with potentially updated priorities
    local sortedCombos = {}
    if DM.combinations and DM.combinations.data then
      for id, data in pairs(DM.combinations.data) do
        table.insert(sortedCombos, { id = id, data = data })
      end
    end

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

    -- Create or update rows for each combination
    local rowHeight = 30
    local yOffset = 2 -- Changed from 0 to 2 to match tracked spells tab's spacing

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

        -- Order text (was Priority text)
        local orderText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        orderText:SetPoint("LEFT", row, "LEFT", 290, 0)
        row.orderText = orderText

        -- Add Up Arrow Button
        local upArrow = CreateFrame("Button", nil, row)
        upArrow:SetSize(20, 20) -- Match tracked spells tab size
        upArrow:SetPoint("RIGHT", orderText, "RIGHT", 15, 0)
        upArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
        upArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
        upArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

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

            -- Get current priorities
            local currentPriority = DM.combinations.data[currentComboID].priority
            local prevPriority = DM.combinations.data[prevComboID].priority

            -- Swap priorities
            DM.combinations.data[currentComboID].priority = prevPriority
            DM.combinations.data[prevComboID].priority = currentPriority

            -- Save changes to database
            DM:SaveCombinationsDB()
            self:DebugMsg(string.format("Swapped priority for combination %s (now %d) and %s (now %d)",
              currentComboID, prevPriority, prevComboID, currentPriority))

            -- Refresh the combinations list
            UpdateCombinationsList()
          end
        end)

        -- Add Down Arrow Button
        local downArrow = CreateFrame("Button", nil, row)
        downArrow:SetSize(20, 20)                           -- Match tracked spells tab size
        downArrow:SetPoint("RIGHT", upArrow, "LEFT", -2, 0) -- 2px gap between arrows
        downArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        downArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
        downArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

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

            -- Get current priorities
            local currentPriority = DM.combinations.data[currentComboID].priority
            local nextPriority = DM.combinations.data[nextComboID].priority

            -- Swap priorities
            DM.combinations.data[currentComboID].priority = nextPriority
            DM.combinations.data[nextComboID].priority = currentPriority

            -- Save changes to database
            DM:SaveCombinationsDB()
            self:DebugMsg(string.format("Swapped priority for combination %s (now %d) and %s (now %d)",
              currentComboID, nextPriority, nextComboID, currentPriority))

            -- Refresh the combinations list
            UpdateCombinationsList()
          end
        end)

        -- Color swatch
        local colorSwatch = CreateFrame("Button", nil, row)
        colorSwatch:SetSize(20, 20)
        colorSwatch:SetPoint("LEFT", row, "LEFT", 240, 0)

        local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
        colorTexture:SetAllPoints()
        row.colorTexture = colorTexture
        row.colorSwatch = colorSwatch

        -- Add click handler for the color swatch that was missing
        colorSwatch:SetScript("OnClick", function()
          -- Store the combo ID for reference
          local comboID = row.comboID
          if not comboID or not DM.combinations.data[comboID] then return end

          local combo = DM.combinations.data[comboID]
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

                -- Update color in database
                DM.combinations.data[comboID].color = {
                  r = newR, g = newG, b = newB, a = newA
                }

                -- Update the color swatch
                row.colorTexture:SetColorTexture(newR, newG, newB, newA)

                -- Save the updated combinations data
                DM:SaveCombinationsDB()
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

        -- Edit button
        local editButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        editButton:SetSize(60, 20)
        editButton:SetPoint("LEFT", row, "LEFT", 350, 0)
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
      row:SetWidth(scrollContent:GetWidth()) -- Match scroll content width

      -- Background color (alternating)
      local rowBg = row:GetRegions()
      rowBg:SetColorTexture(index % 2 == 0 and 0.2 or 0.15, index % 2 == 0 and 0.2 or 0.15,
        index % 2 == 0 and 0.2 or 0.15, 0.8)

      -- Update text fields
      row.nameText:SetText(combo.name or "Unnamed")
      row.orderText:SetText(combo.priority or "")

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

    -- Display the spells in the spell list
    DM:UpdateCombinationSpellList(dialog)
  else
    dialog.title:SetText("New Combination")
    dialog.comboID = nil

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
  local rowHeight = 44

  for index, spellID in ipairs(dialog.selectedSpells) do
    self:DebugMsg("Processing spell ID: " .. spellID)

    -- Create spell row
    local row = CreateFrame("Frame", nil, dialog.spellsContent)
    row:SetSize(dialog.spellsContent:GetWidth(), rowHeight)
    row:SetPoint("TOPLEFT", dialog.spellsContent, "TOPLEFT", 0, -yOffset)
    row:EnableMouse(true) -- Make the row clickable

    -- Background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(
      index % 2 == 0 and 0.2 or 0.15,
      index % 2 == 0 and 0.2 or 0.15,
      index % 2 == 0 and 0.2 or 0.15,
      0.8
    )

    -- Try different ways to look up the spell
    local spellName, spellIcon

    -- Method 1: Look up by number directly
    if DM.dmspellsdb and DM.dmspellsdb[spellID] then
      local spellData = DM.dmspellsdb[spellID]
      spellName = spellData.spellname
      spellIcon = spellData.spellicon
      self:DebugMsg("Found spell using numeric ID: " .. spellName)
      -- Method 2: Look up by string ID
    elseif DM.dmspellsdb and DM.dmspellsdb[tostring(spellID)] then
      local spellData = DM.dmspellsdb[tostring(spellID)]
      spellName = spellData.spellname
      spellIcon = spellData.spellicon
      self:DebugMsg("Found spell using string ID: " .. spellName)
      -- Method 3: Use WoW API as fallback
    else
      self:DebugMsg("Spell not in database, using API for: " .. spellID)
      local spellInfo = C_Spell.GetSpellInfo(spellID)
      if spellInfo then
        spellName = spellInfo.name
        spellIcon = spellInfo.iconFileID
        self:DebugMsg("Found using API: " .. spellName)
      else
        spellName = "Unknown Spell"
        spellIcon = 134400 -- question mark
        self:DebugMsg("Spell not found by any method: " .. spellID)
      end
    end

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(rowHeight - 6, rowHeight - 6)
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    icon:SetTexture(spellIcon or 134400) -- Default to question mark if no icon

    -- Spell name with ID in parentheses
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetJustifyH("LEFT")
    name:SetText(spellName .. " (" .. spellID .. ")")

    -- Position centered with icon
    name:ClearAllPoints()
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    name:SetPoint("TOP", row, "TOP", 0, -2)
    name:SetPoint("BOTTOM", row, "BOTTOM", 0, 2)

    -- Remove button
    local removeButton = CreateFrame("Button", nil, row)
    removeButton:SetSize(24, 24)                        -- Increased from 16x16 to 24x24
    removeButton:SetPoint("RIGHT", row, "RIGHT", -8, 0) -- Better positioning
    removeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    removeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")

    -- Make row exclude the remove button area for clicking
    row:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" then
        local x, y = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        x, y = x / scale, y / scale

        -- Convert to frame coordinates
        local left, bottom, width, height = self:GetRect()
        local mouseX, mouseY = x - left, y - bottom

        -- Check if click is not in remove button area
        if mouseX < (width - 30) then -- Adjusted for larger button (was 20)
          -- Remove spell on row click
          for i, id in ipairs(dialog.selectedSpells) do
            if id == spellID then
              table.remove(dialog.selectedSpells, i)
              break
            end
          end

          -- Update the display
          DM:UpdateCombinationSpellList(dialog)
        end
      end
    end)

    removeButton:SetScript("OnClick", function()
      -- Remove the spell
      for i, id in ipairs(dialog.selectedSpells) do
        if id == spellID then
          table.remove(dialog.selectedSpells, i)
          break
        end
      end

      -- Update the display
      DM:UpdateCombinationSpellList(dialog)
    end)

    yOffset = yOffset + rowHeight
  end

  -- Set content height
  dialog.spellsContent:SetHeight(math.max(yOffset + 5, 100))
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

    -- If spell database isn't available, show error
    if not DM.dmspellsdb then
      local errorText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      errorText:SetPoint("CENTER", scrollContent, "CENTER", 0, 0)
      errorText:SetText("Spell database not available")
      errorText:SetTextColor(1, 0.3, 0.3)
      return
    end

    -- Get player class
    local _, playerClass = UnitClass("player")

    -- Filter spells based on player class
    local filteredSpells = {}

    for spellIDStr, spellData in pairs(DM.dmspellsdb) do
      -- Class match check (player class or ALL) AND tracked=1
      if (spellData.wowclass and (spellData.wowclass == playerClass or spellData.wowclass == "ALL") and spellData.tracked == 1) then
        -- Add to filtered list
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
        "No tracked spells available.\n\nYou need to mark spells as 'tracked' in the Database tab, or use Find My Dots to add spells to your database.")
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

      -- Background
      local bg = button:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()

      -- Set background color - much darker for unselected rows
      local isSelected = selectedSpells[spellID] or false
      local baseColor = index % 2 == 0 and 0.12 or 0.08 -- Much darker base colors
      local bgColor = isSelected and 0.3 or baseColor   -- Bright for selected, dark for unselected
      bg:SetColorTexture(bgColor, bgColor, bgColor, 0.9)

      -- Checkbox
      local checkbox = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
      checkbox:SetSize(20, 20)
      checkbox:SetPoint("LEFT", button, "LEFT", 5, 0)
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
          bg:SetColorTexture(baseColor + 0.1, baseColor + 0.1, baseColor + 0.1, 0.9)
        else
          selectedSpells[spellID] = nil
          -- Restore normal background color
          bg:SetColorTexture(baseColor, baseColor, baseColor, 0.9)
        end
      end)

      -- Spell icon
      local iconSize = buttonHeight - 16
      local icon = button:CreateTexture(nil, "ARTWORK")
      icon:SetSize(iconSize, iconSize)
      icon:SetPoint("LEFT", checkbox, "RIGHT", 10, 0)

      -- Get spell icon
      if spellData.spellicon then
        icon:SetTexture(spellData.spellicon)
      else
        icon:SetTexture(134400) -- Question mark
      end

      -- Spell name with ID in parentheses
      local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      name:SetJustifyH("LEFT")
      name:SetText(spellData.spellname .. " (" .. spellID .. ")")

      -- Position centered with icon
      name:ClearAllPoints()
      name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
      name:SetPoint("RIGHT", button, "RIGHT", -5, 0)
      name:SetPoint("TOP", button, "TOP", 0, -2)
      name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)

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
    frame:SetMovable(true)
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
    title:SetText("Tracked Spells Available")
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
