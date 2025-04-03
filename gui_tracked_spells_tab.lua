-- DotMaster gui_tracked_spells_tab.lua
-- Content for the Tracked Spells Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Function to create the Tracked Spells tab content
function Components.CreateTrackedSpellsTab(parentFrame)
  DM:DatabaseDebug("Creating Tracked Spells Tab Content...")

  -- Button container at the bottom
  local buttonContainer = CreateFrame("Frame", nil, parentFrame)
  buttonContainer:SetSize(parentFrame:GetWidth() - 20, 50)
  buttonContainer:SetPoint("BOTTOM", 0, 10) -- Position at bottom

  -- Find My Dots button
  local findMyDotsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  findMyDotsButton:SetSize(150, 30)
  findMyDotsButton:SetPoint("RIGHT", buttonContainer, "CENTER", -5, 0)
  findMyDotsButton:SetText("Find My Dots")
  findMyDotsButton:SetScript("OnClick", function()
    DM:StartFindMyDots()
  end)

  -- Untrack All button
  local untrackAllButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  untrackAllButton:SetSize(150, 30)
  untrackAllButton:SetPoint("LEFT", buttonContainer, "CENTER", 5, 0)
  untrackAllButton:SetText("Untrack All")

  -- Add tooltip
  untrackAllButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Untrack All Spells", 1, 1, 1)
    GameTooltip:AddLine("Remove all spells from the tracked list", 1, 0.3, 0.3, true)
    GameTooltip:Show()
  end)

  untrackAllButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  untrackAllButton:SetScript("OnClick", function()
    -- Confirmation prompt
    StaticPopupDialogs["DOTMASTER_UNTRACK_ALL_CONFIRM"] = {
      text = "Are you sure you want to untrack all spells?\nThis will remove all spells from tracking.",
      button1 = "Yes, Untrack All",
      button2 = "Cancel",
      OnAccept = function()
        -- Set tracked=0 for all spells
        for spellID, config in pairs(DM.dmspellsdb) do
          config.tracked = 0
        end

        DM:SaveDMSpellsDB()

        -- Refresh the tracked spells tab
        GUI:RefreshTrackedSpellTabList()

        DM:DatabaseDebug("All spells have been untracked.")
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_UNTRACK_ALL_CONFIRM")
  end)

  -- Main scroll frame for the spell list (properly constrained within the parent)
  local scrollFrame = CreateFrame("ScrollFrame", "DotMasterTrackedScrollFrame", parentFrame, "UIPanelScrollFrameTemplate")
  -- Anchor scroll frame to the top of the parent frame now
  scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 15, -15)
  scrollFrame:SetPoint("BOTTOMRIGHT", buttonContainer, "TOPRIGHT", -5, 10) -- Adjusted right offset: -23 -> -5

  -- Forcefully hide the default scroll bar elements
  if scrollFrame.ScrollBar then
    scrollFrame.ScrollBar:Hide()
    scrollFrame.ScrollBar:SetAlpha(0)
    if scrollFrame.ScrollBar.ScrollUpButton then
      scrollFrame.ScrollBar.ScrollUpButton:Hide()
      scrollFrame.ScrollBar.ScrollUpButton:SetAlpha(0)
    end
    if scrollFrame.ScrollBar.ScrollDownButton then
      scrollFrame.ScrollBar.ScrollDownButton:Hide()
      scrollFrame.ScrollBar.ScrollDownButton:SetAlpha(0)
    end
  end

  -- Enable mouse wheel scrolling
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local scrollStep = 25 -- Use entryHeight as a base scroll step
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local newScroll = currentScroll - (delta * scrollStep) -- delta > 0 for wheel up, < 0 for down

    -- Clamp the new scroll value
    newScroll = math.max(0, math.min(newScroll, maxScroll))

    if newScroll ~= currentScroll then
      self:SetVerticalScroll(newScroll)
    end
  end)

  -- Create the scroll child (content container)
  local scrollChild = CreateFrame("Frame", "DotMasterTrackedScrollChild")
  scrollChild:SetWidth(scrollFrame:GetWidth() - 10) -- Adjusted width for no scrollbar, slight padding
  scrollChild:SetHeight(200)                        -- Give it an initial height
  scrollFrame:SetScrollChild(scrollChild)

  -- Anchor scrollChild TOPLEFT to scrollFrame TOPLEFT
  scrollChild:ClearAllPoints()
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  -- Width is set below based on scrollFrame width

  -- Simplified handling for fixed-size window
  parentFrame:HookScript("OnSizeChanged", function(self, width, height)
    -- Update container sizes with fixed width
    buttonContainer:SetWidth(width - 20)
    scrollFrame:SetPoint("BOTTOMRIGHT", buttonContainer, "TOPRIGHT", -5, 10) -- Adjusted right offset

    -- Update scrollChild width based on scrollFrame's potentially changed width
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)

    -- Force layout update
    GUI:UpdateTrackedSpellsLayout()
  end)

  -- Store references
  GUI.trackedScrollFrame = scrollFrame
  GUI.trackedScrollChild = scrollChild
  GUI.trackedClassFrames = {} -- To hold references for expand/collapse

  -- Initial population - use C_Timer to ensure UI is fully initialized
  C_Timer.After(0.2, function()
    GUI:RefreshTrackedSpellTabList()
    DM:DatabaseDebug("Initial tracked spells list refresh completed")
  end)
end

-- Helper to group tracked spells by Class -> ID
function GUI:GetGroupedTrackedSpells()
  local grouped = {}

  -- Use dmspellsdb but filter for tracked spells only
  if not DM.dmspellsdb then
    DM:DatabaseDebug("dmspellsdb is nil or empty")
    return grouped
  end

  local count = 0
  for idStr, data in pairs(DM.dmspellsdb) do
    -- Only include tracked spells (using tonumber for robustness)
    if tonumber(data.tracked) == 1 then
      -- Convert string ID to number if needed
      local id = tonumber(idStr)
      count = count + 1

      if not id then
        DM:DatabaseDebug(string.format("WARNING: Invalid spell ID in dmspellsdb: %s", tostring(idStr)))
        -- Skip this entry
      else
        local className = data.wowclass or "UNKNOWN"

        if not grouped[className] then grouped[className] = {} end
        grouped[className][id] = data
      end
    end
  end

  DM:DatabaseDebug("GetGroupedTrackedSpells processed " .. count .. " tracked entries")
  return grouped
end

-- Function to refresh the tracked spells list UI (no filter parameter needed)
function GUI:RefreshTrackedSpellTabList()
  DM:DatabaseDebug("Refreshing Tracked Spells Tab List.")

  local scrollChild = GUI.trackedScrollChild
  if not scrollChild then
    DM:DatabaseDebug("ERROR: trackedScrollChild is nil in RefreshTrackedSpellTabList")
    return
  end

  -- Clear existing content completely
  for _, child in pairs({ scrollChild:GetChildren() }) do
    if child and child.Hide then
      child:Hide()
    end
    if child and child.SetParent then
      child:SetParent(nil)
    end
  end
  wipe(GUI.trackedClassFrames)

  -- Set scroll child height to ensure visibility
  scrollChild:SetHeight(400)

  local groupedData = self:GetGroupedTrackedSpells()

  -- Log tracked spells stats
  local classCount, spellCount = 0, 0
  for className, classData in pairs(groupedData) do
    classCount = classCount + 1
    for _ in pairs(classData) do
      spellCount = spellCount + 1
    end
  end
  DM:DatabaseDebug(string.format("Tracked spells structure: %d classes, %d spells", classCount, spellCount))

  if spellCount == 0 then
    -- Create a "no spells found" message
    local noSpellsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noSpellsText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
    noSpellsText:SetText("No tracked spells found. Use the Database tab to track spells.")
    noSpellsText:SetTextColor(1, 0.82, 0)
    scrollChild:SetHeight(200) -- Ensure there's space for the message
    scrollChild:Show()
    return
  end

  local yOffset = 5
  local entryHeight = 40
  local headerHeight = 40
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth() - 20 -- Allow for margins (10px left, 10px right)

  -- Get player class token
  local _, playerClassToken = UnitClass("player")

  -- Sort Classes (Player class first, then UNKNOWN last, then alphabetically)
  local sortedClasses = {}
  for className in pairs(groupedData) do table.insert(sortedClasses, className) end
  table.sort(sortedClasses, function(a, b)
    if a == playerClassToken and b ~= playerClassToken then return true end
    if b == playerClassToken and a ~= playerClassToken then return false end
    if a == "UNKNOWN" then return false end
    if b == "UNKNOWN" then return true end
    return a < b
  end)

  -- Create expand/collapse indicators
  local function CreateIndicator(parent, expanded)
    local indicator = parent:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(16, 16)
    indicator:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    indicator:SetTexture(expanded and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
    return indicator
  end

  -- Highlight on mouseover
  local function AddMouseoverHighlight(frame)
    frame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local highlight = frame:GetHighlightTexture()
    highlight:SetAlpha(0.7)
  end

  for _, className in ipairs(sortedClasses) do
    local classData = groupedData[className]
    local classFrame = CreateFrame("Button", nil, scrollChild)
    classFrame:SetSize(effectiveWidth, headerHeight)
    classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset) -- Same overall position
    classFrame.isExpanded = (className == playerClassToken)
    classFrame.spellFrames = {}
    classFrame:Show()
    GUI.trackedClassFrames[className] = classFrame

    AddMouseoverHighlight(classFrame)

    -- Background remains the same
    local bg = classFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)
    if DM.classColors[className] then
      local color = DM.classColors[className]
      bg:SetColorTexture(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
    end

    -- Define layout constants (updated for swatch size)
    local padding = 5 -- General padding between elements
    local checkboxWidth = 20
    local iconSize = 25
    local colorSwatchSize = 24 -- Swatch size from gui_colorpicker.lua
    local arrowSize = 20
    local untrackWidth = 70
    local untrackHeight = 25

    -- 1. Collapse/Expand Indicator (Aligned with Checkbox)
    local indicator = classFrame:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(16, 16)
    -- Align left edge like the checkbox (padding from frame start)
    indicator:SetPoint("LEFT", classFrame, "LEFT", padding, 0)
    indicator:SetTexture(classFrame.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
      "Interface\\Buttons\\UI-PlusButton-Up")
    classFrame.indicator = indicator -- Store reference

    -- 3. Tracked Spell Count (Aligned Right with Untrack Button)
    local numSpells = 0
    for _ in pairs(classData) do numSpells = numSpells + 1 end
    local countText = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- Align right edge like the untrack button (padding from frame end)
    countText:SetPoint("RIGHT", classFrame, "RIGHT", -padding, 0)
    countText:SetText(string.format("(%d Spells)", numSpells))
    countText:SetTextColor(0.8, 0.8, 0.8) -- Greyish color
    countText:SetJustifyH("RIGHT")
    classFrame.countText = countText      -- Store reference if needed later

    -- 2. Class Name (Between Indicator and Count Text)
    local text = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    -- Align left edge like the spell icon (padding + checkboxWidth + padding)
    local classNameLeftOffset = padding + checkboxWidth + padding
    text:SetPoint("LEFT", classFrame, "LEFT", classNameLeftOffset, 0)
    -- Align right edge to the left of the count text
    text:SetPoint("RIGHT", countText, "LEFT", -padding, 0)
    local displayName = DM:GetClassDisplayName(className) or className
    text:SetText(displayName)
    text:SetJustifyH("LEFT")
    if DM.classColors[className] then
      local color = DM.classColors[className]
      text:SetTextColor(color.r, color.g, color.b)
    end

    yOffset = yOffset + headerHeight + spacing

    -- Priority reassignment logic (Fixing the debug message syntax error)
    local spellsInClassByPriority = {}
    for id, spellData in pairs(classData) do
      if not spellData.priority then
        DM.dmspellsdb[id].priority = 999
        DM:DatabaseDebug(string.format("Assigned default priority 999 to spell %d", id))
      end
      table.insert(spellsInClassByPriority, { id = id, priority = spellData.priority })
    end
    table.sort(spellsInClassByPriority, function(a, b)
      if a.priority == b.priority then return a.id < b.id end
      return a.priority < b.priority
    end)
    local prioritiesChanged = false
    local uniquePriorityCounter = 1
    for _, entry in ipairs(spellsInClassByPriority) do
      -- Check if priority needs reassignment
      if not DM.dmspellsdb[entry.id] or DM.dmspellsdb[entry.id].priority ~= uniquePriorityCounter then
        -- Ensure spell entry exists before modification (safety check)
        if DM.dmspellsdb[entry.id] then
          DM.dmspellsdb[entry.id].priority = uniquePriorityCounter
          DM:DatabaseDebug(string.format("Reassigned priority %d to spell %d for class %s", uniquePriorityCounter,
            entry.id, className))
          prioritiesChanged = true
        else
          DM:DatabaseDebug(string.format("WARNING: Tried to reassign priority for non-existent spell %d in dmspellsdb",
            entry.id))
        end
      end
      uniquePriorityCounter = uniquePriorityCounter + 1
    end
    if prioritiesChanged then DM:SaveDMSpellsDB() end

    -- Re-sort spells for display based on potentially updated priorities
    local sortedSpells = {}
    for id in pairs(classData) do table.insert(sortedSpells, id) end
    table.sort(sortedSpells, function(a, b)
      local spellA = classData[a]
      local spellB = classData[b]
      if spellA.priority and spellB.priority then
        if spellA.priority == spellB.priority then return (spellA.spellname or "") < (spellB.spellname or "") end
        return spellA.priority < spellB.priority
      elseif spellA.priority then
        return true
      elseif spellB.priority then
        return false
      else
        return (spellA.spellname or "") < (spellB.spellname or "")
      end
    end)

    local visibleSpellCount = 0

    for spellIndex, spellID in ipairs(sortedSpells) do
      local spellData = classData[spellID]
      visibleSpellCount = visibleSpellCount + 1
      local spellFrame = CreateFrame("Frame", nil, scrollChild)
      spellFrame:SetSize(effectiveWidth, entryHeight)
      spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
      if not classFrame.isExpanded then spellFrame:Hide() else spellFrame:Show() end

      local rowBg = spellFrame:CreateTexture(nil, "BACKGROUND")
      rowBg:SetAllPoints()
      if (visibleSpellCount % 2 == 0) then rowBg:SetColorTexture(0, 0, 0, 0.4) else rowBg:SetColorTexture(0, 0, 0, 0.2) end

      table.insert(classFrame.spellFrames, spellFrame)

      -- --- Layout using Anchors from Both Ends ---

      -- Left-Anchored Elements
      local currentLeftAnchor = spellFrame
      local currentLeftOffset = padding

      -- 1. Enabled Checkbox
      local enabledCheckbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
      enabledCheckbox:SetSize(checkboxWidth, checkboxWidth)
      enabledCheckbox:SetPoint("LEFT", currentLeftAnchor, "LEFT", currentLeftOffset, 0)
      if spellData.enabled == nil then DM.dmspellsdb[spellID].enabled = 1 end
      enabledCheckbox:SetChecked(DM.dmspellsdb[spellID].enabled == 1)
      enabledCheckbox:SetScript("OnClick", function(self)
        DM.dmspellsdb[spellID].enabled = self:GetChecked() and 1 or 0
        DM:SaveDMSpellsDB()
        DM:DatabaseDebug(string.format("Spell %d enabled status set to %d", spellID, DM.dmspellsdb[spellID].enabled))
      end)
      currentLeftAnchor = enabledCheckbox
      currentLeftOffset = padding

      -- 2. Spell Icon
      local icon = spellFrame:CreateTexture(nil, "ARTWORK")
      icon:SetSize(iconSize, iconSize)
      icon:SetPoint("LEFT", currentLeftAnchor, "RIGHT", currentLeftOffset, 0)
      local iconPath = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark"
      icon:SetTexture(iconPath)
      icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      currentLeftAnchor = icon
      currentLeftOffset = padding + 3

      -- Right-Anchored Elements (Reverse Order: Untrack -> Up -> Down -> Swatch)
      local currentRightAnchor = spellFrame
      local currentRightOffset = -padding

      -- 7. Untrack Button
      DM:DatabaseDebug(string.format("Before SetSize for UntrackButton (Spell %d): untrackWidth=%s, untrackHeight=%s",
        spellID, tostring(untrackWidth), tostring(untrackHeight)))
      local untrackButton = CreateFrame("Button", nil, spellFrame, "UIPanelButtonTemplate")
      untrackButton:SetSize(untrackWidth, untrackHeight)
      untrackButton:SetPoint("RIGHT", currentRightAnchor, "RIGHT", currentRightOffset, 0)
      untrackButton:SetText("Untrack")
      untrackButton:SetScript("OnClick", function()
        DM.dmspellsdb[spellID].tracked = 0
        DM:DatabaseDebug(string.format("Spell %d untracked", spellID))
        DM:SaveDMSpellsDB()
        GUI:RefreshTrackedSpellTabList()
      end)
      currentRightAnchor = untrackButton
      currentRightOffset = -padding

      -- 6. Up Arrow Button
      local upArrow = CreateFrame("Button", nil, spellFrame)
      upArrow:SetSize(arrowSize, arrowSize)
      upArrow:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)
      upArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
      upArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
      upArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
      if spellIndex == 1 then
        upArrow:Disable()
        upArrow:SetAlpha(0.5)
      else
        upArrow:Enable()
        upArrow:SetAlpha(1.0)
      end
      upArrow:SetScript("OnClick", function()
        if spellIndex > 1 then
          local prevSpellID = sortedSpells[spellIndex - 1]
          local currentPriority = DM.dmspellsdb[spellID].priority
          local prevPriority = DM.dmspellsdb[prevSpellID].priority
          DM.dmspellsdb[spellID].priority = prevPriority
          DM.dmspellsdb[prevSpellID].priority = currentPriority
          DM:DatabaseDebug(string.format("Swapped priority for %d (now %d) and %d (now %d)", spellID, prevPriority,
            prevSpellID, currentPriority))
          DM:SaveDMSpellsDB()
          GUI:RefreshTrackedSpellTabList()
        end
      end)
      currentRightAnchor = upArrow
      currentRightOffset = -padding

      -- 5. Down Arrow Button
      local downArrow = CreateFrame("Button", nil, spellFrame)
      downArrow:SetSize(arrowSize, arrowSize)
      downArrow:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)
      downArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
      downArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
      downArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
      if spellIndex == #sortedSpells then
        downArrow:Disable()
        downArrow:SetAlpha(0.5)
      else
        downArrow:Enable()
        downArrow:SetAlpha(1.0)
      end
      downArrow:SetScript("OnClick", function()
        if spellIndex < #sortedSpells then
          local nextSpellID = sortedSpells[spellIndex + 1]
          local currentPriority = DM.dmspellsdb[spellID].priority
          local nextPriority = DM.dmspellsdb[nextSpellID].priority
          DM.dmspellsdb[spellID].priority = nextPriority
          DM.dmspellsdb[nextSpellID].priority = currentPriority
          DM:DatabaseDebug(string.format("Swapped priority for %d (now %d) and %d (now %d)", spellID, nextPriority,
            nextSpellID, currentPriority))
          DM:SaveDMSpellsDB()
          GUI:RefreshTrackedSpellTabList()
        end
      end)
      currentRightAnchor = downArrow
      currentRightOffset = -padding

      -- 4. Color Swatch (Using DotMaster_CreateColorSwatch)
      local initialColor
      if spellData.color and type(spellData.color) == "table" and #spellData.color >= 3 then
        local r_check = tonumber(spellData.color[1]) or 1
        local g_check = tonumber(spellData.color[2]) or 1
        local b_check = tonumber(spellData.color[3]) or 1
        initialColor = { r_check, g_check, b_check }
      else
        DM:DatabaseDebug(string.format("Spell %d using default color (invalid/missing data: %s)", spellID,
          tostring(spellData.color)))
        initialColor = { 1, 1, 1 } -- Default to white
      end

      -- *** MODIFIED DEBUG: Use DM:DebugMsg with LAYOUT category ***
      local r_pre, g_pre, b_pre = unpack(initialColor)
      DM:DebugMsg("LAYOUT", string.format("Pre-Call Spell %d - initialColor: {%s,%s,%s} - unpacked: r=%s, g=%s, b=%s",
        spellID,
        tostring(initialColor[1]), tostring(initialColor[2]), tostring(initialColor[3]),
        tostring(r_pre), tostring(g_pre), tostring(b_pre)))

      local colorSwatch = DotMaster_CreateColorSwatch(spellFrame, r_pre, g_pre, b_pre,
        function(newR, newG, newB) -- Callback function for the custom picker
          if DM.dmspellsdb[spellID] then
            DM.dmspellsdb[spellID].color = { newR, newG, newB }
            DM:DatabaseDebug(string.format("Updated color for spell %d via custom picker", spellID))
          end
        end
      )
      -- We still need to position the swatch returned by the function
      colorSwatch:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)
      spellFrame.colorSwatch = colorSwatch -- Store reference if needed
      currentRightAnchor = colorSwatch     -- Name anchors to this swatch now
      currentRightOffset = -padding

      -- 3. Spell Name & ID (Anchored between Icon and Color Swatch)
      local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      nameText:SetPoint("LEFT", currentLeftAnchor, "RIGHT", currentLeftOffset, 0)
      nameText:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)
      nameText:SetHeight(entryHeight)
      nameText:SetText(string.format("%s (%d)", spellData.spellname or "Unknown", spellID))
      nameText:SetJustifyH("LEFT")
      nameText:SetJustifyV("MIDDLE")

      if classFrame.isExpanded then yOffset = yOffset + entryHeight + spacing end
    end -- End Spell Loop

    -- Class Header Click Handler
    classFrame:SetScript("OnClick", function(self)
      self.isExpanded = not self.isExpanded
      self.indicator:SetTexture(self.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
        "Interface\\Buttons\\UI-PlusButton-Up")
      for _, frame in ipairs(self.spellFrames) do
        if self.isExpanded then frame:Show() else frame:Hide() end
      end
      GUI:UpdateTrackedSpellsLayout()
    end)
  end -- End Class Loop

  GUI:UpdateTrackedSpellsLayout()
  scrollChild:Show()
end

-- Function to recalculate positions after expand/collapse
function GUI:UpdateTrackedSpellsLayout()
  local scrollChild = GUI.trackedScrollChild
  if not scrollChild then return end

  local yOffset = 5
  local entryHeight = 40                             -- Set to 40
  local headerHeight = 40                            -- Set to 40
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth() - 20 -- Allow for margins

  local _, playerClassToken = UnitClass("player")

  local sortedClasses = {}
  for className in pairs(GUI.trackedClassFrames or {}) do table.insert(sortedClasses, className) end
  table.sort(sortedClasses, function(a, b)
    if a == playerClassToken and b ~= playerClassToken then return true end
    if b == playerClassToken and a ~= playerClassToken then return false end
    if a == "UNKNOWN" then return false end
    if b == "UNKNOWN" then return true end
    return a < b
  end)

  for _, className in ipairs(sortedClasses) do
    local classFrame = GUI.trackedClassFrames[className]
    if classFrame then
      classFrame:ClearAllPoints()
      classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
      classFrame:SetWidth(effectiveWidth)
      yOffset = yOffset + headerHeight + spacing

      if classFrame.isExpanded then
        for _, spellFrame in ipairs(classFrame.spellFrames or {}) do
          spellFrame:ClearAllPoints()
          spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
          spellFrame:SetWidth(effectiveWidth)
          spellFrame:Show()
          yOffset = yOffset + entryHeight + spacing
        end
      end
    end
  end

  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end
