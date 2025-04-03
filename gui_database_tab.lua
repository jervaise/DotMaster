-- DotMaster gui_database_tab.lua
-- Content for the Database Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Placeholder function to create the Database tab content
function Components.CreateDatabaseTab(parentFrame)
  DM:DatabaseDebug("Creating Database Tab Content...")

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
        if GUI.RefreshTrackedSpellTabList then
          GUI:RefreshTrackedSpellTabList()
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
  -- Anchor scroll frame to the top of the parent frame now
  scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 15, -15)
  scrollFrame:SetPoint("BOTTOMRIGHT", buttonContainer, "TOPRIGHT", -5, 10) -- Adjusted offset for no scrollbar

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
  local scrollChild = CreateFrame("Frame", "DotMasterDbScrollChild")
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
    scrollFrame:SetPoint("BOTTOMRIGHT", buttonContainer, "TOPRIGHT", -5, 10) -- Adjusted offset for no scrollbar

    -- Update scrollChild width based on scrollFrame's potentially changed width
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)

    -- Force layout update
    GUI:UpdateDatabaseLayout()
  end)

  -- Store references
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

-- Function to refresh the database list UI (no filter parameter, no spec layer)
function GUI:RefreshDatabaseTabList()
  DM:DatabaseDebug("Refreshing Database Tab List.")

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

  -- Log database stats (Removed specCount)
  local classCount, spellCount = 0, 0
  for className, classData in pairs(groupedData) do
    classCount = classCount + 1
    for _ in pairs(classData) do
      spellCount = spellCount + 1
    end
  end
  DM:DatabaseDebug(string.format("Database structure: %d classes, %d spells", classCount, spellCount))

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
  local entryHeight = 25
  local headerHeight = 28
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth() - 20 -- Allow for margins

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
    classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
    -- Set initial expanded state based on player class
    classFrame.isExpanded = (className == playerClassToken)
    classFrame.spellFrames = {} -- Changed from specFrames
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
    text:SetPoint("LEFT", 10, 0)
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
      visibleSpellCount = visibleSpellCount + 1
      local spellFrame = CreateFrame("Frame", nil, scrollChild)
      -- Align spell frame with class frame
      spellFrame:SetSize(effectiveWidth, entryHeight)
      spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
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
      trackLabel:SetPoint("RIGHT", checkbox, "LEFT", -2, 0)

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
        DM:DatabaseDebug(string.format("Spell %d tracked status set to %d", numericID, DM.dmspellsdb[numericID].tracked))

        if GUI.RefreshTrackedSpellTabList then
          GUI:RefreshTrackedSpellTabList()
        end

        DM:SaveDMSpellsDB()
      end)

      -- Only increment yOffset if the spell is actually visible (class is expanded)
      if classFrame.isExpanded then
        yOffset = yOffset + entryHeight + spacing
      end
    end -- End Spell Loop

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

  local yOffset = 5
  local entryHeight = 25
  local headerHeight = 28
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth() - 20 -- Allow for margins

  -- Get player class token
  local _, playerClassToken = UnitClass("player")

  -- Iterate through sorted classes (Player class first, UNKNOWN last, then alphabetically)
  local sortedClasses = {}
  for className in pairs(GUI.dbClassFrames or {}) do table.insert(sortedClasses, className) end
  table.sort(sortedClasses, function(a, b)
    if a == playerClassToken and b ~= playerClassToken then return true end
    if b == playerClassToken and a ~= playerClassToken then return false end
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
        -- Position spell frames directly under the class
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

  -- Update scroll child height to accommodate all content
  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end
