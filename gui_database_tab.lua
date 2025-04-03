-- DotMaster gui_database_tab.lua
-- Content for the Database Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Placeholder function to create the Database tab content
function Components.CreateDatabaseTab(parentFrame)
  DM:DatabaseDebug("Creating Database Tab Content...")

  -- Define layout constants for this tab
  DM.GUI = DM.GUI or {}
  DM.GUI.layoutDb = DM.GUI.layoutDb or {
    padding = 3,
    columns = {
      TRACK = 10,  -- Start Checkbox area
      SPELL = 40,  -- Start Icon
      CLASS = 250, -- Start Class text
      SPEC = 350   -- Start Spec text
    },
    widths = {
      TRACK = 24,  -- Checkbox width
      SPELL = 200, -- Icon(24)+Name(170)+pad
      CLASS = 90,  -- Width Class text
      SPEC = 90    -- Width Spec text
    }
  }
  local LAYOUT_DB = DM.GUI.layoutDb
  local COLUMN_POSITIONS_DB = LAYOUT_DB.columns
  local COLUMN_WIDTHS_DB = LAYOUT_DB.widths

  -- Create standardized info area
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    parentFrame,
    "Spell Database",
    "Browse all known spells. Use 'Find My Dots' to add missing spells."
  )

  -- Button container at the bottom
  local buttonContainer = CreateFrame("Frame", nil, parentFrame)
  buttonContainer:SetSize(parentFrame:GetWidth() - 20, 50)
  buttonContainer:SetPoint("BOTTOM", 0, 10)

  -- Find My Dots button (Now Centered)
  local findMyDotsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  findMyDotsButton:SetSize(150, 30)
  findMyDotsButton:SetPoint("CENTER", 0, 0) -- Changed from RIGHT to CENTER
  findMyDotsButton:SetText("Find My Dots")
  findMyDotsButton:SetScript("OnClick", function()
    DM:StartFindMyDots()
  end)

  -- Create the custom search box container
  local searchContainer = CreateFrame("Frame", nil, parentFrame)
  searchContainer:SetSize(430, 20)
  searchContainer:SetPoint("TOP", infoArea, "BOTTOM", 0, 0)

  -- Create the background
  local searchBg = searchContainer:CreateTexture(nil, "BACKGROUND")
  searchBg:SetAllPoints()
  searchBg:SetColorTexture(0, 0, 0, 0.5)

  -- Create the search icon
  local searchIcon = searchContainer:CreateTexture(nil, "ARTWORK")
  searchIcon:SetSize(16, 16)
  searchIcon:SetPoint("LEFT", searchContainer, "LEFT", 5, 0)
  searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
  searchIcon:SetVertexColor(0.6, 0.6, 0.6, 1)

  -- Create the EditBox
  local searchBox = CreateFrame("EditBox", nil, searchContainer)
  searchBox:SetSize(400, 20)
  searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 5, 0)
  searchBox:SetPoint("RIGHT", searchContainer, "RIGHT", -5, 0)
  searchBox:SetFontObject("GameFontHighlight")
  searchBox:SetAutoFocus(false)
  searchBox:SetMaxLetters(50)
  searchBox:SetTextInsets(0, 5, 0, 0)

  -- Create placeholder text
  local placeholderText = searchContainer:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  placeholderText:SetText("Search")
  placeholderText:SetPoint("LEFT", searchIcon, "RIGHT", 5, 0)
  placeholderText:SetPoint("RIGHT", searchContainer, "RIGHT", -5, 0)
  placeholderText:SetJustifyH("LEFT")

  -- Handle focus and text changes
  searchBox:SetScript("OnEditFocusGained", function(self)
    placeholderText:Hide()
  end)

  searchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
      placeholderText:Show()
    end
  end)

  searchBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if text ~= "" then
      placeholderText:Hide()
    else
      if not self:HasFocus() then
        placeholderText:Show()
      end
    end
    -- Call refresh with the search text
    GUI:RefreshDatabaseTabList(text)
  end)

  -- Handle escape to clear focus
  searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    self:SetText("")
    placeholderText:Show()
    GUI:RefreshDatabaseTabList("")
  end)

  -- Handle enter to clear focus
  searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  -- Store reference to search box
  GUI.dbSearchBox = searchBox

  -- Main scroll frame setup (no margin)
  local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame)
  scrollFrame:SetSize(430, 0)
  scrollFrame:SetPoint("TOP", searchContainer, "BOTTOM", 0, -3) -- Reduced to 3px margin below search bar
  scrollFrame:SetPoint("BOTTOM", buttonContainer, "TOP", 0, 10)

  -- Create the scroll child
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(430, 200)
  scrollFrame:SetScrollChild(scrollChild)

  -- Position scrollChild exactly at the top with no spacing
  scrollChild:ClearAllPoints()
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)

  -- Enable mouse wheel scrolling
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local scrollStep = 25
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local newScroll = currentScroll - (delta * scrollStep)
    newScroll = math.max(0, math.min(newScroll, maxScroll))
    if newScroll ~= currentScroll then
      self:SetVerticalScroll(newScroll)
    end
  end)

  -- Store references
  GUI.dbScrollFrame = scrollFrame
  GUI.dbScrollChild = scrollChild
  GUI.dbClassFrames = {}

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
    GUI:RefreshDatabaseTabList()
    DM:DatabaseDebug("Initial database list refresh completed")
  end)
end

-- Helper to group spells by Class -> ID (Removed Spec)
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
      -- Removed specName grouping

      if not grouped[className] then grouped[className] = {} end
      -- Directly assign spell data under class
      grouped[className][id] = data
    end
  end

  DM:DatabaseDebug("GetGroupedSpellDatabase processed " .. count .. " entries")
  return grouped
end

-- Function to refresh the database list UI (Added query parameter)
function GUI:RefreshDatabaseTabList(query)
  query = query and query:lower() or ""
  DM:DatabaseDebug(string.format("Refreshing Database Tab List with query: '%s'", query))

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

  -- Filter spells based on search query
  if query ~= "" then
    local filteredData = {}
    for className, classSpells in pairs(groupedData) do
      local filteredSpells = {}
      -- Check if class name matches the query
      local displayName = (DM:GetClassDisplayName(className) or className):lower()
      local classNameMatches = displayName:find(query)

      for spellID, spellData in pairs(classSpells) do
        -- Search in spell name and ID
        local spellName = (spellData.spellname or ""):lower()
        local spellIDStr = tostring(spellID)
        if spellName:find(query) or spellIDStr:find(query) or classNameMatches then
          filteredSpells[spellID] = spellData
        end
      end
      if next(filteredSpells) then
        filteredData[className] = filteredSpells
      end
    end
    groupedData = filteredData
  end

  -- Log database stats
  local classCount, spellCount = 0, 0
  for className, classData in pairs(groupedData) do
    classCount = classCount + 1
    for _ in pairs(classData) do
      spellCount = spellCount + 1
    end
  end
  DM:DatabaseDebug(string.format("Database structure: %d classes, %d spells (filtered by: '%s')", classCount, spellCount,
    query))

  if spellCount == 0 then
    -- Create a "no spells found" message
    local noSpellsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noSpellsText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
    if query ~= "" then
      noSpellsText:SetText(string.format("No spells found matching '%s'", query))
    else
      noSpellsText:SetText("No spells found in database. Use 'Find My Dots' to discover spells.")
    end
    noSpellsText:SetTextColor(1, 0.82, 0)
    scrollChild:SetHeight(200) -- Ensure there's space for the message
    scrollChild:Show()
    return
  end

  local yOffset = 0 -- Start at 0
  local entryHeight = 25
  local headerHeight = 40
  local spacing = 3                             -- Reduced from 5 to 3 for tighter spacing
  local effectiveWidth = scrollChild:GetWidth() -- Should now be 430px

  -- Sort Classes Alphabetically (UNKNOWN last)
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
    indicator:SetPoint("RIGHT", parent, "RIGHT", -16, 0) -- Increased right margin to 16px
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
    classFrame.isExpanded = true -- Default expand all in DB tab
    classFrame.spellFrames = {}
    classFrame:Show()
    GUI.dbClassFrames[className] = classFrame

    -- Add mouseover highlight
    AddMouseoverHighlight(classFrame)

    -- Class Header Background/Text (same as before)
    local bg = classFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)
    if DM.classColors[className] then
      local color = DM.classColors[className]
      bg:SetColorTexture(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
    end
    local text = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("LEFT", 20, 0) -- Added 10px more left margin
    local displayName = DM:GetClassDisplayName(className) or className
    text:SetText(displayName)
    -- Expand/collapse indicator - set initial texture based on expanded state
    classFrame.indicator = CreateIndicator(classFrame, classFrame.isExpanded)
    if DM.classColors[className] then
      local color = DM.classColors[className]
      text:SetTextColor(color.r, color.g, color.b)
    end

    yOffset = yOffset + headerHeight + spacing

    -- Sort Spells by priority then name (using classData)
    local sortedSpells = {}
    for id in pairs(classData) do table.insert(sortedSpells, id) end
    table.sort(sortedSpells, function(a, b)
      local spellA = classData[a]
      local spellB = classData[b]
      if spellA.priority and spellB.priority then
        return spellA.priority < spellB.priority
      end
      local nameA = spellA.spellname or ""
      local nameB = spellB.spellname or ""
      return nameA < nameB
    end)

    local visibleSpellCount = 0

    for _, spellID in ipairs(sortedSpells) do
      local spellData = classData[spellID]

      -- Filter based on query (match name or ID)
      local nameMatch = spellData.spellname and spellData.spellname:lower():find(query, 1, true)
      local idMatch = tostring(spellID):find(query, 1, true)

      if query == "" or nameMatch or idMatch then
        visibleSpellCount = visibleSpellCount + 1
        local spellFrame = CreateFrame("Frame", nil, scrollChild)
        -- Align spell frame with class frame
        spellFrame:SetSize(effectiveWidth, entryHeight)
        spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        -- Hide spell frame initially if class is collapsed
        if not classFrame.isExpanded then
          spellFrame:Hide()
        else
          spellFrame:Show()
        end

        -- Add alternating row background
        local rowBg = spellFrame:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        if (visibleSpellCount % 2 == 0) then
          rowBg:SetColorTexture(0, 0, 0, 0.3)
        else
          rowBg:SetColorTexture(0, 0, 0, 0.2)
        end

        table.insert(classFrame.spellFrames, spellFrame) -- Add to classFrame.spellFrames

        -- Spell Icon (same as before)
        local icon = spellFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 5, 0)
        local iconPath = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark"
        icon:SetTexture(iconPath)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Spell Name & ID (same as before)
        local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameText:SetWidth(spellFrame:GetWidth() - 110)
        nameText:SetText(string.format("%s (%d)", spellData.spellname or "Unknown", spellID))
        nameText:SetJustifyH("LEFT")

        -- Track Checkbox (same as before, but refresh calls updated)
        local checkbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("RIGHT", -5, 0)
        checkbox:SetChecked(spellData.tracked == 1)

        local trackLabel = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        trackLabel:SetText("Track")
        trackLabel:SetPoint("RIGHT", checkbox, "LEFT", -12, 0) -- Increased left margin to 12px

        checkbox:SetScript("OnClick", function(self)
          local isChecked = self:GetChecked()
          local numericID = spellID

          if not DM.dmspellsdb[numericID] then
            DM:DatabaseDebug(string.format("Creating entry for spell %d in dmspellsdb", numericID))
            DM.dmspellsdb[numericID] = {
              spellname = spellData.spellname or "Unknown",
              spellicon = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark",
              wowclass = spellData.wowclass or "UNKNOWN",
              wowspec = spellData.wowspec or "UNKNOWN",
              color = { 1, 0, 0 },
              priority = 999,
              enabled = 1
            }
          end

          DM.dmspellsdb[numericID].tracked = isChecked and 1 or 0
          DM:DatabaseDebug(string.format("Spell %d tracked status set to %d", numericID, DM.dmspellsdb[numericID]
            .tracked))

          if GUI.RefreshTrackedSpellTabList then
            GUI:RefreshTrackedSpellTabList()
          end

          DM:SaveDMSpellsDB()
        end)

        -- Only increment yOffset if the spell is actually visible (class is expanded)
        if classFrame.isExpanded then
          yOffset = yOffset + entryHeight + spacing
        end
      end -- End filter check
    end   -- End Spell Loop

    -- Class Header Click Handler (Expand/Collapse Spells)
    classFrame:SetScript("OnClick", function(self)
      self.isExpanded = not self.isExpanded

      -- Update indicator
      self.indicator:SetTexture(self.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
        "Interface\\Buttons\\UI-PlusButton-Up")

      -- Toggle visibility of spellFrames directly
      for _, frame in ipairs(self.spellFrames) do
        if self.isExpanded then
          frame:Show()
        else
          frame:Hide()
        end
      end
      GUI:UpdateDatabaseLayout()
    end)
  end -- End Class Loop

  -- Final layout update (will reposition based on initial visibility)
  GUI:UpdateDatabaseLayout()
  scrollChild:Show()
end

-- Function to recalculate positions after expand/collapse (Removed Spec Logic)
function GUI:UpdateDatabaseLayout()
  local scrollChild = GUI.dbScrollChild
  if not scrollChild then return end

  local yOffset = 0
  local entryHeight = 25
  local headerHeight = 40
  local spacing = 3 -- Reduced from 5 to 3 for tighter spacing
  local effectiveWidth = scrollChild:GetWidth()

  -- Iterate through sorted classes (Alphabetically, UNKNOWN last)
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
      classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
      classFrame:SetWidth(effectiveWidth)
      yOffset = yOffset + headerHeight + spacing

      if classFrame.isExpanded then
        -- Position spell frames directly under the class
        for _, spellFrame in ipairs(classFrame.spellFrames or {}) do
          spellFrame:ClearAllPoints()
          spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
          spellFrame:SetWidth(effectiveWidth)
          spellFrame:Show()
          yOffset = yOffset + entryHeight + spacing
        end
      end
    end
  end

  -- Update scroll child height to accommodate all content
  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end
