-- DotMaster gui_tracked_spells_tab.lua
-- Content for the Tracked Spells Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Function to create the Tracked Spells tab content
function Components.CreateTrackedSpellsTab(parentFrame)
  DM:DatabaseDebug("Creating Tracked Spells Tab Content...")

  -- Make sure database is loaded
  if not DM.dmspellsdb or next(DM.dmspellsdb) == nil then
    DM:DatabaseDebug("Database empty or not loaded, attempting to load it now")
    if DM.LoadDMSpellsDB then
      DM:LoadDMSpellsDB()
    end
  end

  -- Define layout constants for this tab (should match gui_spell_row.lua usage)
  -- Ensure DM.GUI exists
  DM.GUI = DM.GUI or {}
  -- Define layout if not already defined
  DM.GUI.layout = DM.GUI.layout or {
    padding = 5,
    columns = {
      ON = 10,
      ID = 40,     -- Start of Icon/Name
      NAME = 70,   -- Not directly used for start, combined with ID
      COLOR = 230, -- Moved left
      UP = 275,    -- Moved left (approx center of arrows)
      DOWN = 305,  -- Moved left
      DEL = 355    -- Moved left
    },
    widths = {
      ON = 24,
      ID = 24,    -- Icon width approx
      NAME = 160, -- Width for name text
      COLOR = 30,
      UP = 24,
      DOWN = 24,
      DEL = 70 -- Increased width slightly for Untrack
    }
  }
  local LAYOUT = DM.GUI.layout
  local COLUMN_POSITIONS = LAYOUT.columns
  local COLUMN_WIDTHS = LAYOUT.widths

  -- Create standardized info area
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    parentFrame,
    "Tracked Spells",
    "Enable/disable spells for tracking and nameplate coloring."
  )

  -- Button container at the bottom
  local buttonContainer = CreateFrame("Frame", nil, parentFrame)
  buttonContainer:SetSize(parentFrame:GetWidth() - 20, 50)
  buttonContainer:SetPoint("BOTTOM", 0, 10)

  -- Add from Database button (formerly Find My Dots)
  local addFromDatabaseButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  addFromDatabaseButton:SetSize(150, 30)
  addFromDatabaseButton:SetPoint("LEFT", buttonContainer, "CENTER", 5, 0)
  addFromDatabaseButton:SetText("Add from Database")
  addFromDatabaseButton:SetScript("OnClick", function()
    -- Simulate clicking the Database tab (ID 3)
    if _G["DotMasterTab3"] then
      _G["DotMasterTab3"]:Click()
      DM:GUIDebug("Switched to Database tab via 'Add from Database' button")
    else
      DM:GUIDebug("ERROR: Could not find Database tab button (DotMasterTab3)")
    end
  end)

  -- Untrack All button
  local untrackAllButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  untrackAllButton:SetSize(150, 30)
  untrackAllButton:SetPoint("RIGHT", buttonContainer, "CENTER", -5, 0)
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

  -- Create Header Frame (Centered, Fixed Width 430px)
  local headerFrame = CreateFrame("Frame", nil, parentFrame)
  headerFrame:SetSize(430, 20)                          -- Fixed width, Adjusted height to 20px
  headerFrame:SetPoint("TOP", infoArea, "BOTTOM", 0, 0) -- No top margin

  -- Add dark background to header
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints(headerFrame)
  headerBg:SetColorTexture(0, 0, 0, 0.6) -- Dark semi-transparent background

  -- Calculate positions for right-aligned elements
  local padding = LAYOUT.padding or 5
  local untrackWidth = 70                           -- Width of untrack button
  local untrackStart = 430 - padding - untrackWidth -- Right edge minus padding minus button width
  local arrowWidth = 20
  local arrowGap = 2
  local swatchWidth = 24

  -- Calculate positions from right to left
  local upArrowStart = untrackStart - 5 - arrowWidth                                      -- 5px gap from untrack button
  local downArrowStart = upArrowStart - arrowGap - arrowWidth                             -- 2px gap between arrows
  local arrowCenter = downArrowStart + ((upArrowStart + arrowWidth) - downArrowStart) / 2 -- Center between arrows
  local colorSwatchStart = downArrowStart - 10 - swatchWidth                              -- 10px gap from arrows

  -- Create header labels
  local function CreateHeaderLabel(text, justify, xOffset, yOffset)
    local label = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(text)
    if justify == "RIGHT" then
      label:SetPoint("RIGHT", headerFrame, "RIGHT", xOffset, yOffset or 0)
    elseif justify == "CENTER" then
      label:SetPoint("CENTER", headerFrame, "LEFT", xOffset, yOffset or 0)
    else
      label:SetPoint("LEFT", headerFrame, "LEFT", xOffset, yOffset or 0)
    end
    return label
  end

  -- Create labels in order from left to right
  CreateHeaderLabel("ON", "LEFT", COLUMN_POSITIONS.ON + (COLUMN_WIDTHS.ON / 2) - 16)
  CreateHeaderLabel("SPELL", "LEFT", COLUMN_POSITIONS.ID - 10)
  CreateHeaderLabel("COLOR", "LEFT", colorSwatchStart + (swatchWidth / 2) - 15) -- Center with color swatch
  CreateHeaderLabel("ORDER", "CENTER", arrowCenter + 5)                         -- Center with arrows, moved slightly right
  CreateHeaderLabel("TRACKED", "CENTER", untrackStart + (untrackWidth / 2) - 2) -- Center with untrack button, moved slightly left

  -- Main scroll frame setup
  local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetSize(430, 0)
  scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -2) -- Match database tab's 2px margin
  scrollFrame:SetPoint("BOTTOM", buttonContainer, "TOP", 0, 10)

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
  -- Width matches scrollFrame exactly
  scrollChild:SetWidth(430)
  scrollChild:SetHeight(200) -- Give it an initial height
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
    scrollChild:SetWidth(scrollFrame:GetWidth())

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

  -- Make sure we have access to the database
  if not DM.dmspellsdb then
    DM:DatabaseDebug("dmspellsdb is nil - attempting to load")

    -- Try to load database if it's missing
    if DM.LoadDMSpellsDB then
      DM:LoadDMSpellsDB()
    end

    -- If still missing, return empty results
    if not DM.dmspellsdb then
      DM:DatabaseDebug("Failed to load dmspellsdb")
      return grouped
    end
  end

  -- Check if database is empty
  local isEmpty = true
  for _ in pairs(DM.dmspellsdb) do
    isEmpty = false
    break
  end

  if isEmpty then
    DM:DatabaseDebug("dmspellsdb is empty")
    return grouped
  end

  local count = 0
  for idStr, data in pairs(DM.dmspellsdb) do
    -- Only include tracked spells (using tonumber for robustness)
    local tracked = tonumber(data.tracked)
    if tracked == 1 then
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

-- Function to refresh the tracked spells list UI
function GUI:RefreshTrackedSpellTabList()
  DM:DatabaseDebug("Refreshing Tracked Spells Tab List")

  local scrollChild = GUI.trackedScrollChild
  if not scrollChild then
    DM:DatabaseDebug("ERROR: trackedScrollChild is nil in RefreshTrackedSpellTabList")
    return
  end

  -- Debug the database state
  if not DM.dmspellsdb then
    DM:DatabaseDebug("ERROR: dmspellsdb is nil when refreshing Tracked Spells tab")
  else
    local count = 0
    local trackedCount = 0
    for spellID, data in pairs(DM.dmspellsdb) do
      count = count + 1
      if data.tracked == 1 then
        trackedCount = trackedCount + 1
        -- Show some sample data for debugging
        if trackedCount <= 3 then
          DM:DatabaseDebug(string.format("Sample tracked spell: ID=%s, Name=%s, Class=%s",
            tostring(spellID), tostring(data.spellname), tostring(data.wowclass)))
        end
      end
    end
    DM:DatabaseDebug(string.format("Database has %d spells, %d are tracked", count, trackedCount))
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

  -- Get tracked spells
  local groupedData = self:GetGroupedTrackedSpells()
  local hasTrackedSpells = false

  -- Check if we have any tracked spells
  for className, classSpells in pairs(groupedData) do
    if next(classSpells) then
      hasTrackedSpells = true
      break
    end
  end

  -- Handle friendly message
  if not hasTrackedSpells then
    -- Create or show friendly message
    if not scrollChild.friendlyMessage then
      scrollChild.friendlyMessage = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      scrollChild.friendlyMessage:SetPoint("TOP", scrollChild, "TOP", 0, -50)
      scrollChild.friendlyMessage:SetText(
        "No spells are currently being tracked.\nUse the 'Add from Database' button to start tracking spells.")
      scrollChild.friendlyMessage:SetJustifyH("CENTER")
      scrollChild.friendlyMessage:SetTextColor(0.7, 0.7, 0.7)
    else
      scrollChild.friendlyMessage:Show()
    end
    scrollChild:SetHeight(200) -- Set minimum height
    return
  else
    -- Hide friendly message if it exists
    if scrollChild.friendlyMessage then
      scrollChild.friendlyMessage:Hide()
    end
  end

  -- Set scroll child height to ensure visibility
  scrollChild:SetHeight(400)

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
    noSpellsText:SetText("No tracked spells found. Use 'Find My Dots' in the Database tab to add spells.")
    noSpellsText:SetTextColor(1, 0.82, 0)
    scrollChild:SetHeight(200) -- Ensure there's space for the message
    scrollChild:Show()
    return
  end

  local yOffset = 2 -- Reduced from 5 to 2 for tighter spacing
  local entryHeight = 40
  local headerHeight = 40
  local spacing = 3
  -- Use full scrollChild width for rows now
  local effectiveWidth = scrollChild:GetWidth() -- 430px

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
    -- Position at scrollChild's top-left corner (0 offset)
    classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    classFrame.isExpanded = (className == playerClassToken)
    classFrame.spellFrames = {}
    classFrame:Show()
    GUI.trackedClassFrames[className] = classFrame

    AddMouseoverHighlight(classFrame)

    -- Background remains the same
    local bg = classFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    -- bg:SetColorTexture(0, 0, 0, 0.8) -- Original Black Fallback
    if DM.classColors[className] then
      local color = DM.classColors[className]
      bg:SetColorTexture(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8) -- Dimmed class color
    else
      bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)                               -- Neutral Dark Grey Fallback
    end

    -- Define layout constants (updated for swatch size)
    local padding = GUI.layout.padding or 5 -- Access layout via GUI table
    local checkboxWidth = 20
    local iconSize = 25
    local colorSwatchSize = 24 -- Swatch size from gui_colorpicker.lua
    local arrowSize = 20
    local untrackWidth = 70    -- Match layout width
    local untrackHeight = 25

    -- 1. Collapse/Expand Indicator (Aligned with Checkbox)
    local indicator = classFrame:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(16, 16)
    -- Align left edge like the checkbox (padding from frame start)
    indicator:SetPoint("LEFT", classFrame, "LEFT", padding, 0)
    indicator:SetTexture(classFrame.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
      "Interface\\Buttons\\UI-PlusButton-Up")
    classFrame.indicator = indicator -- Store reference

    -- 3. Tracked Spell Count (Centered with Untrack Button)
    local spellCountText = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    spellCountText:SetPoint("CENTER", classFrame, "RIGHT", -(padding + untrackWidth / 2), 0) -- Center with untrack button
    spellCountText:SetJustifyH("CENTER")
    local spellCount = 0
    for _ in pairs(classData or {}) do spellCount = spellCount + 1 end
    spellCountText:SetText(string.format("(%d Spells)", spellCount))

    -- 2. Class Name (Between Indicator and Count Text, adjusted for proper spacing)
    local text = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("LEFT", classFrame, "LEFT", padding + checkboxWidth + padding, 0)
    text:SetPoint("RIGHT", spellCountText, "LEFT", -padding, 0)
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
      -- Position at scrollChild's top-left corner (0 offset)
      spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
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
      local currentRightOffset = -padding -- Standard right padding

      -- 7. Untrack Button
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
      -- Next element anchors to the left of this one
      currentRightAnchor = untrackButton
      currentRightOffset = -5 -- Gap between Untrack and Up arrow

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
      -- Next element anchors to the left of this one
      currentRightAnchor = upArrow
      currentRightOffset = -2 -- Gap between Up and Down arrow

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
      -- Next element anchors to the left of this one
      currentRightAnchor = downArrow
      currentRightOffset = -10 -- Gap between Down arrow and Swatch

      -- 4. Color Swatch
      local initialColor
      if spellData.color and type(spellData.color) == "table" and #spellData.color >= 3 then
        local r_check = tonumber(spellData.color[1]) or 1
        local g_check = tonumber(spellData.color[2]) or 0
        local b_check = tonumber(spellData.color[3]) or 0
        initialColor = { r_check, g_check, b_check }
      else
        DM:DatabaseDebug(string.format("Spell %d using default color (invalid/missing data: %s)", spellID,
          tostring(spellData.color)))
        initialColor = { 1, 0, 0 } -- Default to red
      end

      -- Debug the state of the color data and colorpicker function
      DM:DatabaseDebug(string.format("Creating color swatch for spell %d with color: R=%.2f, G=%.2f, B=%.2f",
        spellID, initialColor[1], initialColor[2], initialColor[3]))

      -- Get reference to the colorpicker function directly from DotMaster_ColorPicker
      local colorSwatchFunc = _G["DotMaster_CreateColorSwatch"]
      if not colorSwatchFunc then
        DM:DatabaseDebug(
          "ERROR: DotMaster_CreateColorSwatch function not available, trying to get from DotMaster_ColorPicker")
        colorSwatchFunc = DotMaster_ColorPicker and DotMaster_ColorPicker.CreateColorSwatch
      end

      -- Create the color swatch with proper error handling
      local colorSwatch
      if colorSwatchFunc then
        -- Call with pcall to catch any errors
        local success, result = pcall(function()
          return colorSwatchFunc(
            spellFrame,
            initialColor[1],
            initialColor[2],
            initialColor[3],
            function(newR, newG, newB) -- Callback for when color changes
              DM:DatabaseDebug(string.format("Color changed for spell %d: R=%.2f, G=%.2f, B=%.2f",
                spellID, newR, newG, newB))

              if DM.dmspellsdb[spellID] then
                DM.dmspellsdb[spellID].color = { newR, newG, newB }
                DM:SaveDMSpellsDB() -- Make sure to save the database
                DM:DatabaseDebug(string.format("Updated color for spell %d in database", spellID))
              end
            end
          )
        end)

        if success and result then
          colorSwatch = result
          DM:DatabaseDebug(string.format("Successfully created color swatch for spell %d", spellID))
        else
          DM:DatabaseDebug(string.format("Error creating color swatch: %s", tostring(result)))
          -- Create fallback if function call failed
          colorSwatch = CreateFrame("Button", nil, spellFrame)
        end
      else
        -- Create a basic fallback swatch if the function doesn't exist
        DM:DatabaseDebug("Creating fallback color swatch (colorpicker function not found)")
        colorSwatch = CreateFrame("Button", nil, spellFrame)
      end

      -- Set up the fallback appearance if needed
      if not colorSwatchFunc or not colorSwatch.GetColor then
        colorSwatch:SetSize(24, 24)
        local texture = colorSwatch:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints()
        texture:SetColorTexture(initialColor[1], initialColor[2], initialColor[3])
      end

      -- Position the swatch
      colorSwatch:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)
      spellFrame.colorSwatch = colorSwatch
      currentRightAnchor = colorSwatch
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

  local yOffset = 2       -- Reduced from 5 to 2 for tighter spacing
  local entryHeight = 40  -- Set to 40
  local headerHeight = 40 -- Set to 40
  local spacing = 3
  -- Use full scrollChild width for rows now
  local effectiveWidth = scrollChild:GetWidth() -- 430px

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
      -- Position at scrollChild's top-left corner (0 offset)
      classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
      classFrame:SetWidth(effectiveWidth)
      yOffset = yOffset + headerHeight + spacing

      if classFrame.isExpanded then
        for _, spellFrame in ipairs(classFrame.spellFrames or {}) do
          spellFrame:ClearAllPoints()
          -- Position at scrollChild's top-left corner (0 offset)
          spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
          spellFrame:SetWidth(effectiveWidth)
          spellFrame:Show()
          yOffset = yOffset + entryHeight + spacing
        end
      end
    end
  end

  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end
