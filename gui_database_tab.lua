-- DotMaster gui_database_tab.lua
-- Content for the Database Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Placeholder function to create the Database tab content
function Components.CreateDatabaseTab(parentFrame)
  -- DM:DebugMsg("Creating Database Tab Content...") -- REMOVING

  -- Search Box
  local searchBox = CreateFrame("EditBox", "DotMasterDbSearchBox", parentFrame, "SearchBoxTemplate")
  searchBox:SetSize(200, 24)
  searchBox:SetPoint("TOPLEFT", 10, -10)
  searchBox:SetAutoFocus(false)
  searchBox:SetTextInsets(5, 5, 0, 0)
  searchBox.Instructions = "Search Spells..."

  searchBox:SetScript("OnTextChanged", function(self)
    local filter = self:GetText():lower()
    if filter == self.Instructions:lower() then filter = "" end
    -- Use a timer to avoid refreshing on every single key press
    if GUI.dbSearchTimer then GUI.dbSearchTimer:Cancel() end
    GUI.dbSearchTimer = C_Timer.NewTimer(0.3, function()
      GUI:RefreshDatabaseTabList(filter)
    end)
  end)
  searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  searchBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == self.Instructions then self:SetText("") end
    self:HighlightText()
  end)
  searchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then self:SetText(self.Instructions) end
  end)

  -- Scroll Frame for the list
  local scrollFrame = CreateFrame("ScrollFrame", "DotMasterDbScrollFrame", parentFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
  scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -25, 5) -- Leave space for scrollbar

  local scrollChild = CreateFrame("Frame", "DotMasterDbScrollChild")
  scrollChild:SetSize(scrollFrame:GetWidth() - 20, 10) -- Width adjusted for scrollbar
  scrollFrame:SetScrollChild(scrollChild)

  -- Store references
  GUI.dbSearchBox = searchBox
  GUI.dbScrollFrame = scrollFrame
  GUI.dbScrollChild = scrollChild
  GUI.dbClassFrames = {} -- To hold references for expand/collapse

  -- Constants for layout
  local PADDING = { OUTER = 5, INNER = 8, COLUMN = 10 }

  DM.GUI.databaseLayout = layout
  DM.GUI.databaseSpellFrames = {}

  -- DM:DebugMsg("Database Tab Content Created with Search and ScrollFrame") -- REMOVING

  -- Initial population
  GUI:RefreshDatabaseTabList()
end

-- Helper to group spells by Class -> Spec -> ID
function GUI:GetGroupedSpellDatabase()
  local grouped = {}
  if not DM.spellDatabase then return grouped end

  for id, data in pairs(DM.spellDatabase) do
    local className = data.class or "UNKNOWN"
    local specName = data.spec or "UNKNOWN"

    if not grouped[className] then grouped[className] = {} end
    if not grouped[className][specName] then grouped[className][specName] = {} end

    grouped[className][specName][tonumber(id)] = data
  end
  return grouped
end

-- Function to refresh the database list UI
function GUI:RefreshDatabaseTabList(filter)
  -- DM:DebugMsg("Refreshing Database Tab List. Filter: '" .. (filter or "none") .. "'") -- REMOVING

  local scrollChild = GUI.dbScrollChild
  if not scrollChild then return end

  -- Clear existing content
  scrollChild:Hide()
  for _, frame in pairs(GUI.dbClassFrames or {}) do
    -- TODO: Proper cleanup if frames are reused
  end
  GUI.dbClassFrames = {}
  scrollChild:SetHeight(10)

  local groupedData = GUI:GetGroupedSpellDatabase()
  local yOffset = 5
  local entryHeight = 22
  local headerHeight = 24
  local spacing = 2

  -- Sort Classes (Put UNKNOWN last)
  local sortedClasses = {}
  for className in pairs(groupedData) do table.insert(sortedClasses, className) end
  table.sort(sortedClasses, function(a, b)
    if a == "UNKNOWN" then return false end
    if b == "UNKNOWN" then return true end
    return a < b
  end)

  for _, className in ipairs(sortedClasses) do
    local classData = groupedData[className]
    local classFrame = CreateFrame("Button", nil, scrollChild)
    classFrame:SetSize(scrollChild:GetWidth() - 10, headerHeight)
    classFrame:SetPoint("TOPLEFT", 5, -yOffset)
    classFrame.isExpanded = false -- Default collapsed
    classFrame.specFrames = {}
    GUI.dbClassFrames[className] = classFrame

    -- Class Header Background/Text
    local bg = classFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    local text = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("LEFT", 10, 0)
    text:SetText((DM:GetClassDisplayName(className) or className)) -- Use helper for display name

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
      specFrame:SetSize(scrollChild:GetWidth() - 25, headerHeight)
      specFrame:SetPoint("TOPLEFT", 20, -yOffset)
      specFrame.isExpanded = false
      specFrame.spellFrames = {}
      specFrame:Hide() -- Hide initially
      table.insert(classFrame.specFrames, specFrame)

      -- Spec Header Background/Text
      local specBg = specFrame:CreateTexture(nil, "BACKGROUND")
      specBg:SetAllPoints()
      specBg:SetColorTexture(0.15, 0.15, 0.15, 0.7)
      local specText = specFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      specText:SetPoint("LEFT", 10, 0)
      specText:SetText(specName)

      yOffset = yOffset + headerHeight + spacing

      -- Sort Spells by ID
      local sortedSpells = {}
      for id in pairs(specData) do table.insert(sortedSpells, id) end
      table.sort(sortedSpells)

      for _, spellID in ipairs(sortedSpells) do
        local spellData = specData[spellID]
        local spellNameLower = spellData.name and spellData.name:lower() or ""

        -- Apply Filter
        if not filter or filter == "" or spellNameLower:find(filter, 1, true) then
          local spellFrame = CreateFrame("Frame", nil, scrollChild)
          spellFrame:SetSize(scrollChild:GetWidth() - 40, entryHeight)
          spellFrame:SetPoint("TOPLEFT", 35, -yOffset)
          spellFrame:Hide() -- Hide initially
          table.insert(specFrame.spellFrames, spellFrame)

          -- Spell Icon
          local icon = spellFrame:CreateTexture(nil, "ARTWORK")
          icon:SetSize(18, 18)
          icon:SetPoint("LEFT", 0, 0)
          local iconID = spellData.icon or 0
          if iconID ~= 0 then
            icon:SetTexture(iconID)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)                         -- Adjust coords if needed
          else
            icon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain") -- Fallback
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
          end

          -- Spell Name & ID
          local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
          nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
          nameText:SetText(string.format("%s (%d)", spellData.name or "Unknown", spellID))
          nameText:SetJustifyH("LEFT")

          -- Track Checkbox
          local checkbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
          checkbox:SetSize(20, 20)
          checkbox:SetPoint("RIGHT", -5, 0)
          checkbox:SetChecked(spellData.tracked == 1)
          checkbox:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            DM.spellDatabase[spellID].tracked = isChecked and 1 or 0
            -- DM:DebugMsg(string.format("Spell %d tracked status set to %d", spellID, DM.spellDatabase[spellID].tracked)) -- REMOVING

            -- Also update the spellConfig
            if isChecked then
              if not DM.spellConfig[spellID] then
                -- DM:DebugMsg("Creating default config for newly tracked spell: " .. spellID) -- REMOVING
                DM.spellConfig = DM.spellConfig or {}
                DM.spellConfig[spellID] = {
                  enabled = true,
                  color = { 1, 1, 1 }, -- Default white
                  order = 999          -- Will be normalized on next refresh
                }
              end
            else
              if DM.spellConfig and DM.spellConfig[spellID] then
                -- DM:DebugMsg("Removing config for untracked spell: " .. spellID) -- REMOVING
                DM.spellConfig[spellID] = nil
              end
            end

            -- Refresh the other tab's list
            if GUI.RefreshTrackedSpellList then
              GUI:RefreshTrackedSpellList()
            end
            -- Save changes
            DM:SaveSettings() -- Save immediately
            -- DM:AutoSave() -- Or use auto-save
          end)

          yOffset = yOffset + entryHeight + spacing
        end
      end -- End Spell Loop

      -- Spec Header Click Handler (Expand/Collapse Spells)
      specFrame:SetScript("OnClick", function(self)
        self.isExpanded = not self.isExpanded
        for _, frame in ipairs(self.spellFrames) do
          if self.isExpanded then frame:Show() else frame:Hide() end
        end
        GUI:UpdateDatabaseLayout() -- Recalculate layout
      end)
    end                            -- End Spec Loop

    -- Class Header Click Handler (Expand/Collapse Specs)
    classFrame:SetScript("OnClick", function(self)
      self.isExpanded = not self.isExpanded
      for _, frame in ipairs(self.specFrames) do
        if self.isExpanded then
          frame:Show()
        else
          frame:Hide(); frame.isExpanded = false
        end -- Collapse specs too
        -- Also hide spells within the spec if collapsing class
        if not self.isExpanded then
          for _, spellF in ipairs(frame.spellFrames or {}) do spellF:Hide() end
        end
      end
      GUI:UpdateDatabaseLayout()
    end)
  end -- End Class Loop

  -- Final layout update
  GUI:UpdateDatabaseLayout()
  scrollChild:Show()
  -- DM:DebugMsg("Database Tab List Refresh Complete") -- REMOVING
end

-- Function to recalculate positions after expand/collapse
function GUI:UpdateDatabaseLayout()
  local scrollChild = GUI.dbScrollChild
  if not scrollChild then return end

  local yOffset = 5
  local entryHeight = 22
  local headerHeight = 24
  local spacing = 2

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
      classFrame:SetPoint("TOPLEFT", 5, -yOffset)
      yOffset = yOffset + headerHeight + spacing

      if classFrame.isExpanded then
        -- Iterate through sorted specs again
        local sortedSpecs = {}
        for _, specFrame in ipairs(classFrame.specFrames or {}) do
          -- Retrieve specName if needed (could store it on the frame)
          table.insert(sortedSpecs, specFrame)
        end
        -- TODO: Sort specFrames based on their name if needed for consistency

        for _, specFrame in ipairs(sortedSpecs) do
          specFrame:ClearAllPoints()
          specFrame:SetPoint("TOPLEFT", 20, -yOffset)
          specFrame:Show() -- Ensure visible if class is expanded
          yOffset = yOffset + headerHeight + spacing

          -- << TEMPORARILY REMOVED isExpanded check to force spell positioning >>
          -- if specFrame.isExpanded then
          -- <<< ADD DEBUG PRINT HERE >>>
          DM:DebugMsg(string.format("DEBUG Layout: Preparing to position spells for %s/(SpecFrame). Initial yOffset: %d",
            className, yOffset))
          -- <<< END DEBUG PRINT >>>

          for i, spellFrame in ipairs(specFrame.spellFrames or {}) do -- Use ipairs for index
            -- <<< ADD DEBUG PRINT HERE >>>
            local spellDesc = "Spell " .. i
            DM:DebugMsg(string.format("DEBUG Layout: Positioning %s at yOffset %d", spellDesc, yOffset))
            -- <<< END DEBUG PRINT >>>

            spellFrame:ClearAllPoints()
            spellFrame:SetPoint("TOPLEFT", 35, -yOffset)
            spellFrame:Show() -- Ensure visible
            yOffset = yOffset + entryHeight + spacing

            -- <<< ADD DEBUG PRINT HERE >>>
            DM:DebugMsg(string.format("DEBUG Layout: Incremented yOffset after %s to %d", spellDesc, yOffset))
            -- <<< END DEBUG PRINT >>>
          end
          -- end -- << End of temporarily removed isExpanded check >>
        end
      end
    end
  end

  scrollChild:SetHeight(math.max(yOffset, GUI.dbScrollFrame:GetHeight()))
end
