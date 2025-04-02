-- DotMaster gui_database_tab.lua
-- Content for the Database Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Placeholder function to create the Database tab content
function Components.CreateDatabaseTab(parentFrame)
  DM:DatabaseDebug("Creating Database Tab Content...")

  -- Search Box at the top
  local searchBox = CreateFrame("EditBox", "DotMasterDbSearchBox", parentFrame, "SearchBoxTemplate")
  searchBox:SetSize(300, 24)
  searchBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 15, -15)
  searchBox:SetAutoFocus(false)
  searchBox:SetTextInsets(5, 5, 0, 0)

  -- Clear any default SearchBoxTemplate text and set our own
  searchBox:SetText("")
  searchBox:SetFontObject("GameFontNormal")

  -- Insert placeholder text
  local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  searchPlaceholder:SetPoint("LEFT", 20, 0) -- Increased spacing from magnifying glass
  searchPlaceholder:SetText("Search Spells...")
  searchPlaceholder:SetTextColor(0.7, 0.7, 0.7)
  searchBox.placeholder = searchPlaceholder

  -- Better search handling
  searchBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()

    -- Toggle placeholder visibility
    if text == "" then
      searchPlaceholder:Show()
    else
      searchPlaceholder:Hide()
    end

    -- Immediate filtering without timer
    GUI:RefreshDatabaseTabList(text:lower())
  end)

  searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  searchBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    searchPlaceholder:Show()
    self:ClearFocus()
    GUI:RefreshDatabaseTabList("")
  end)

  searchBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
  end)

  searchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
      searchPlaceholder:Show()
    end
  end)

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

  -- Reset Database button
  local resetButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  resetButton:SetSize(150, 30)
  resetButton:SetPoint("LEFT", buttonContainer, "CENTER", 5, 0)
  resetButton:SetText("Reset Database")

  -- Add tooltip
  resetButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Reset Database", 1, 1, 1)
    GameTooltip:AddLine("Clear all spells from the database. This cannot be undone!", 1, 0.3, 0.3, true)
    GameTooltip:Show()
  end)

  resetButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  resetButton:SetScript("OnClick", function()
    -- Confirmation prompt
    StaticPopupDialogs["DOTMASTER_RESET_DB_CONFIRM"] = {
      text = "Are you sure you want to reset the database?\nThis will remove ALL spells and cannot be undone!",
      button1 = "Yes, Reset",
      button2 = "Cancel",
      OnAccept = function()
        -- Reset the database
        DM:ResetDMSpellsDB()
        DM:SaveDMSpellsDB()

        -- Clear the UI display completely
        if GUI.dbScrollChild then
          local children = { GUI.dbScrollChild:GetChildren() }
          for _, child in pairs(children) do
            if type(child) == "table" and child.Hide then
              child:Hide()
              if child.SetParent then
                child:SetParent(nil)
              end
            end
          end
        end

        -- Reset and refresh internal structures
        GUI.dbClassFrames = {}
        GUI:RefreshDatabaseTabList()

        -- Also update tracked spells tab if needed
        if GUI.RefreshTrackedSpellList then
          GUI:RefreshTrackedSpellList()
        end

        DM:DatabaseDebug("Database has been reset and UI refreshed.")
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_RESET_DB_CONFIRM")
  end)

  -- Main scroll frame for the spell list (properly constrained within the parent)
  local scrollFrame = CreateFrame("ScrollFrame", "DotMasterDbScrollFrame", parentFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
  scrollFrame:SetPoint("BOTTOMRIGHT", buttonContainer, "TOPRIGHT", -23, 10) -- Leave space for scrollbar

  -- Create the scroll child (content container)
  local scrollChild = CreateFrame("Frame", "DotMasterDbScrollChild")
  scrollChild:SetWidth(scrollFrame:GetWidth() - 20) -- Width adjusted for scrollbar
  scrollChild:SetHeight(200)                        -- Give it an initial height
  scrollFrame:SetScrollChild(scrollChild)

  -- Center the scrollchild in the scrollframe
  scrollChild:ClearAllPoints()
  scrollChild:SetPoint("TOP", scrollFrame, "TOP", 0, 0)
  scrollChild:SetWidth(scrollFrame:GetWidth() - 30) -- Adjust width to give more horizontal margins

  -- Fix scrolling behavior on resize
  parentFrame:HookScript("OnSizeChanged", function(self, width, height)
    -- Prevent excessive resizing
    if width > 800 or height > 600 then
      self:SetSize(math.min(width, 800), math.min(height, 600))
      return
    end

    -- Update container sizes
    buttonContainer:SetWidth(width - 20)
    scrollFrame:SetPoint("BOTTOMRIGHT", buttonContainer, "TOPRIGHT", -23, 10)

    -- Center the scrollchild in the new scrollframe size
    scrollChild:SetWidth(scrollFrame:GetWidth() - 30)

    -- Force layout update
    GUI:UpdateDatabaseLayout()
  end)

  -- Store references
  GUI.dbSearchBox = searchBox
  GUI.dbScrollFrame = scrollFrame
  GUI.dbScrollChild = scrollChild
  GUI.dbClassFrames = {} -- To hold references for expand/collapse

  -- Initialize dmspellsdb if needed
  if not DM.dmspellsdb then
    DM:LoadDMSpellsDB() -- Try to load from saved variables

    if not DM.dmspellsdb or DM:TableCount(DM.dmspellsdb) == 0 then
      DM:DatabaseDebug("No saved dmspellsdb found, initialized new empty database.")
      DM.dmspellsdb = {} -- Initialize empty table if not loaded
    else
      DM:DatabaseDebug("Loaded dmspellsdb with " .. DM:TableCount(DM.dmspellsdb) .. " spells.")
    end
  end

  DM.GUI.databaseSpellFrames = {}

  -- Initial population - use C_Timer to ensure UI is fully initialized
  C_Timer.After(0.2, function()
    GUI:RefreshDatabaseTabList("")
    DM:DatabaseDebug("Initial database list refresh completed")
  end)
end

-- Helper to group spells by Class -> Spec -> ID
function GUI:GetGroupedSpellDatabase()
  local grouped = {}

  -- Use dmspellsdb instead of spellDatabase
  if not DM.dmspellsdb then
    DM:DatabaseDebug("dmspellsdb is nil or empty")
    return grouped
  end

  local count = 0
  for idStr, data in pairs(DM.dmspellsdb) do
    -- Convert string ID to number if needed
    local id = tonumber(idStr)
    count = count + 1

    if not id then
      DM:DatabaseDebug(string.format("WARNING: Invalid spell ID in dmspellsdb: %s", tostring(idStr)))
      -- Skip this entry
    else
      local className = data.wowclass or "UNKNOWN"
      local specName = data.wowspec or "UNKNOWN"

      if not grouped[className] then grouped[className] = {} end
      if not grouped[className][specName] then grouped[className][specName] = {} end

      grouped[className][specName][id] = data
    end
  end

  DM:DatabaseDebug("GetGroupedSpellDatabase processed " .. count .. " entries")
  return grouped
end

-- Function to refresh the database list UI
function GUI:RefreshDatabaseTabList(filter)
  DM:DatabaseDebug("Refreshing Database Tab List. Filter: '" .. (filter or "none") .. "'")

  local scrollChild = GUI.dbScrollChild
  if not scrollChild then
    DM:DatabaseDebug("ERROR: dbScrollChild is nil in RefreshDatabaseTabList")
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
  wipe(GUI.dbClassFrames)

  -- Set scroll child height to ensure visibility
  scrollChild:SetHeight(400)

  local groupedData = self:GetGroupedSpellDatabase()

  -- Log database stats
  local classCount, specCount, spellCount = 0, 0, 0
  for className, classData in pairs(groupedData) do
    classCount = classCount + 1
    for specName, specData in pairs(classData) do
      specCount = specCount + 1
      for _ in pairs(specData) do
        spellCount = spellCount + 1
      end
    end
  end
  DM:DatabaseDebug(string.format("Database structure: %d classes, %d specs, %d spells", classCount, specCount, spellCount))

  if spellCount == 0 then
    -- Create a "no spells found" message
    local noSpellsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noSpellsText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
    noSpellsText:SetText("No spells found in database. Use 'Find My Dots' to add spells.")
    noSpellsText:SetTextColor(1, 0.82, 0)
    scrollChild:SetHeight(200) -- Ensure there's space for the message
    scrollChild:Show()
    return
  end

  local yOffset = 5
  local entryHeight = 25                             -- Slightly increased for better spacing
  local headerHeight = 28                            -- Slightly increased for better visibility
  local spacing = 3                                  -- Increased spacing
  local effectiveWidth = scrollChild:GetWidth() - 20 -- Allow for margins

  -- Sort Classes (Put UNKNOWN last)
  local sortedClasses = {}
  for className in pairs(groupedData) do table.insert(sortedClasses, className) end
  table.sort(sortedClasses, function(a, b)
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
    classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset) -- Added left margin
    classFrame.isExpanded = true                                         -- Default expanded for better visibility
    classFrame.specFrames = {}
    classFrame:Show()                                                    -- Explicitly show the frame
    GUI.dbClassFrames[className] = classFrame

    -- Add mouseover highlight
    AddMouseoverHighlight(classFrame)

    -- Class Header Background/Text
    local bg = classFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Use class color if available
    if DM.classColors[className] then
      local color = DM.classColors[className]
      bg:SetColorTexture(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.8)
    end

    local text = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("LEFT", 10, 0)
    local displayName = DM:GetClassDisplayName(className) or className
    text:SetText(displayName)

    -- Expand/collapse indicator
    classFrame.indicator = CreateIndicator(classFrame, true)

    -- Set class color for text
    if DM.classColors[className] then
      local color = DM.classColors[className]
      text:SetTextColor(color.r, color.g, color.b)
    end

    yOffset = yOffset + headerHeight + spacing

    -- Sort Specs (Put UNKNOWN last)
    local sortedSpecs = {}
    for specName in pairs(classData) do table.insert(sortedSpecs, specName) end
    table.sort(sortedSpecs, function(a, b)
      if a == "UNKNOWN" then return false end
      if b == "UNKNOWN" then return true end
      return a < b
    end)

    for _, specName in ipairs(sortedSpecs) do
      local specData = classData[specName]
      local specFrame = CreateFrame("Button", nil, scrollChild)
      specFrame:SetSize(effectiveWidth - 20, headerHeight - 4)            -- Width reduced for indent
      specFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, -yOffset) -- Added left margin with indent
      specFrame.isExpanded = true                                         -- Default expanded
      specFrame.spellFrames = {}
      specFrame:Show()                                                    -- Explicitly show
      table.insert(classFrame.specFrames, specFrame)

      -- Add mouseover highlight
      AddMouseoverHighlight(specFrame)

      -- Spec Header Background/Text
      local specBg = specFrame:CreateTexture(nil, "BACKGROUND")
      specBg:SetAllPoints()
      specBg:SetColorTexture(0.15, 0.15, 0.15, 0.7)
      local specText = specFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      specText:SetPoint("LEFT", 10, 0)
      specText:SetText(specName)

      -- Expand/collapse indicator
      specFrame.indicator = CreateIndicator(specFrame, true)

      yOffset = yOffset + headerHeight - 2 + spacing

      -- Sort Spells by priority then name
      local sortedSpells = {}
      for id in pairs(specData) do table.insert(sortedSpells, id) end
      table.sort(sortedSpells, function(a, b)
        local spellA = specData[a]
        local spellB = specData[b]

        -- Sort by priority if both have priority
        if spellA.priority and spellB.priority then
          return spellA.priority < spellB.priority
        end

        -- Sort by name if no priority or equal priority
        local nameA = spellA.spellname or ""
        local nameB = spellB.spellname or ""
        return nameA < nameB
      end)

      local visibleSpellCount = 0

      for _, spellID in ipairs(sortedSpells) do
        local spellData = specData[spellID]
        local spellName = spellData.spellname or "Unknown"
        local spellNameLower = spellName:lower()

        -- Apply Filter
        local passes_filter = not filter or filter == "" or spellNameLower:find(filter, 1, true)

        if passes_filter then
          visibleSpellCount = visibleSpellCount + 1
          local spellFrame = CreateFrame("Frame", nil, scrollChild)
          spellFrame:SetSize(effectiveWidth - 40, entryHeight)                 -- Width reduced for indent
          spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 45, -yOffset) -- Added left margin with indent
          spellFrame:Show()                                                    -- Explicitly show

          -- Add alternating row background for better readability
          local rowBg = spellFrame:CreateTexture(nil, "BACKGROUND")
          rowBg:SetAllPoints()
          if (visibleSpellCount % 2 == 0) then
            rowBg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
          else
            rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)
          end

          table.insert(specFrame.spellFrames, spellFrame)

          -- Spell Icon
          local icon = spellFrame:CreateTexture(nil, "ARTWORK")
          icon:SetSize(20, 20)
          icon:SetPoint("LEFT", 5, 0)
          local iconPath = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark"
          icon:SetTexture(iconPath)
          icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

          -- Spell Name & ID
          local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
          nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
          nameText:SetWidth(spellFrame:GetWidth() - 110) -- Adjusted to leave room for Track label
          nameText:SetText(string.format("%s (%d)", spellName, spellID))
          nameText:SetJustifyH("LEFT")

          -- Track Checkbox
          local checkbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
          checkbox:SetSize(20, 20)
          checkbox:SetPoint("RIGHT", -5, 0)
          checkbox:SetChecked(spellData.tracked == 1)

          -- Add "Track" text label
          local trackLabel = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
          trackLabel:SetText("Track")
          trackLabel:SetPoint("RIGHT", checkbox, "LEFT", -2, 0)

          checkbox:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            local spellIDStr = tostring(spellID) -- Ensure we have string ID

            -- Make sure the entry exists before trying to modify it
            if not DM.dmspellsdb[spellIDStr] then
              DM:DatabaseDebug(string.format("Creating entry for spell %s in dmspellsdb", spellIDStr))
              DM.dmspellsdb[spellIDStr] = {
                spellname = spellData.spellname or "Unknown",
                spellicon = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark",
                wowclass = spellData.wowclass or "UNKNOWN",
                wowspec = spellData.wowspec or "UNKNOWN",
                color = { 1, 0, 0 }, -- Default red
                priority = 999,      -- Default priority
                enabled = 1          -- Default enabled
              }
            end

            -- Now safe to modify
            DM.dmspellsdb[spellIDStr].tracked = isChecked and 1 or 0
            DM:DatabaseDebug(string.format("Spell %s tracked status set to %d", spellIDStr,
            DM.dmspellsdb[spellIDStr].tracked))

            -- Also update the spellConfig for compatibility
            if isChecked then
              if not DM.spellConfig[spellID] then
                DM:DatabaseDebug("Creating default config for newly tracked spell: " .. spellIDStr)
                DM.spellConfig = DM.spellConfig or {}
                DM.spellConfig[spellID] = {
                  enabled = DM.dmspellsdb[spellIDStr].enabled == 1,
                  color = DM.dmspellsdb[spellIDStr].color or { 1, 0, 0 }, -- Use spell's color if exists
                  name = DM.dmspellsdb[spellIDStr].spellname,
                  priority = DM.dmspellsdb[spellIDStr].priority,
                  saved = true
                }
              end
            else
              if DM.spellConfig and DM.spellConfig[spellID] then
                DM:DatabaseDebug("Removing config for untracked spell: " .. spellIDStr)
                DM.spellConfig[spellID] = nil
              end
            end

            -- Refresh the other tab's list
            if GUI.RefreshTrackedSpellList then
              GUI:RefreshTrackedSpellList()
            end

            -- Save changes
            DM:SaveDMSpellsDB()
            DM:SaveSettings()
          end)

          yOffset = yOffset + entryHeight + spacing
        end
      end -- End Spell Loop

      -- Hide spec if no visible spells
      if visibleSpellCount == 0 and filter and filter ~= "" then
        specFrame:Hide()
      end

      -- Spec Header Click Handler (Expand/Collapse Spells)
      specFrame:SetScript("OnClick", function(self)
        self.isExpanded = not self.isExpanded

        -- Update indicator
        self.indicator:SetTexture(self.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
          "Interface\\Buttons\\UI-PlusButton-Up")

        for _, frame in ipairs(self.spellFrames) do
          if self.isExpanded then frame:Show() else frame:Hide() end
        end
        GUI:UpdateDatabaseLayout() -- Recalculate layout
      end)
    end                            -- End Spec Loop

    -- Class Header Click Handler (Expand/Collapse Specs)
    classFrame:SetScript("OnClick", function(self)
      self.isExpanded = not self.isExpanded

      -- Update indicator
      self.indicator:SetTexture(self.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
        "Interface\\Buttons\\UI-PlusButton-Up")

      for _, frame in ipairs(self.specFrames) do
        if self.isExpanded then
          frame:Show()
        else
          frame:Hide()
        end

        -- If class is collapsed, update spec indicators to match
        if not self.isExpanded then
          frame.isExpanded = false
          frame.indicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
          -- Also hide spells within the spec
          for _, spellF in ipairs(frame.spellFrames or {}) do spellF:Hide() end
        else
          -- When expanding, restore spec's own expanded state
          frame.isExpanded = true
          frame.indicator:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
          -- Show spells within the spec
          for _, spellF in ipairs(frame.spellFrames or {}) do spellF:Show() end
        end
      end
      GUI:UpdateDatabaseLayout()
    end)
  end -- End Class Loop

  -- Final layout update
  GUI:UpdateDatabaseLayout()
  scrollChild:Show()
end

-- Function to recalculate positions after expand/collapse
function GUI:UpdateDatabaseLayout()
  local scrollChild = GUI.dbScrollChild
  if not scrollChild then return end

  local yOffset = 5
  local entryHeight = 25 -- Match the increased values from RefreshDatabaseTabList
  local headerHeight = 28
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth() - 20 -- Allow for margins

  -- Iterate through sorted classes again (ensure consistent order)
  local sortedClasses = {}
  for className in pairs(GUI.dbClassFrames or {}) do table.insert(sortedClasses, className) end
  table.sort(sortedClasses, function(a, b)
    if a == "UNKNOWN" then return false end
    if b == "UNKNOWN" then return true end
    return a < b
  end)

  for _, className in ipairs(sortedClasses) do
    local classFrame = GUI.dbClassFrames[className]
    if classFrame then
      classFrame:ClearAllPoints()
      classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
      classFrame:SetWidth(effectiveWidth)
      yOffset = yOffset + headerHeight + spacing

      if classFrame.isExpanded then
        -- Iterate through sorted specs again
        local sortedSpecs = {}
        for _, specFrame in ipairs(classFrame.specFrames or {}) do
          table.insert(sortedSpecs, specFrame)
        end

        for _, specFrame in ipairs(sortedSpecs) do
          specFrame:ClearAllPoints()
          specFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, -yOffset)
          specFrame:SetWidth(effectiveWidth - 20)
          specFrame:Show() -- Ensure visible if class is expanded
          yOffset = yOffset + headerHeight - 2 + spacing

          if specFrame.isExpanded then
            for _, spellFrame in ipairs(specFrame.spellFrames or {}) do
              spellFrame:ClearAllPoints()
              spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 45, -yOffset)
              spellFrame:SetWidth(effectiveWidth - 40)
              spellFrame:Show() -- Ensure visible
              yOffset = yOffset + entryHeight + spacing
            end
          end
        end
      end
    end
  end

  -- Update scroll child height to accommodate all content
  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end
