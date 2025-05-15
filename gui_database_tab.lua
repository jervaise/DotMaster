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

  -- Reset Database Button (left side)
  local resetDbButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  resetDbButton:SetSize(150, 30)
  resetDbButton:SetPoint("RIGHT", buttonContainer, "CENTER", -5, 0)
  resetDbButton:SetText("Reset Database")

  -- Reset database button tooltip and click handler
  resetDbButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Reset Database", 1, 1, 1)
    GameTooltip:AddLine("Clear all spells from the database. This cannot be undone!", 1, 0.3, 0.3, true)
    GameTooltip:Show()
  end)

  resetDbButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  resetDbButton:SetScript("OnClick", function()
    -- Confirmation prompt
    StaticPopupDialogs["DOTMASTER_RESET_DB_CONFIRM"] = {
      text = "Are you sure you want to reset the database?\nThis will remove ALL spells and cannot be undone!",
      button1 = "Yes, Reset",
      button2 = "Cancel",
      OnAccept = function()
        DM:DatabaseDebug("Resetting Database from Database Tab")
        DM:ResetDMSpellsDB()
        -- Refresh relevant UI
        if DM.GUI and DM.GUI.RefreshDatabaseTabList then
          DM.GUI:RefreshDatabaseTabList()
        end
        if DM.GUI and DM.GUI.RefreshTrackedSpellTabList then
          DM.GUI:RefreshTrackedSpellTabList()
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

  -- Find My Dots button (right side)
  local findMyDotsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  findMyDotsButton:SetSize(150, 30)
  findMyDotsButton:SetPoint("LEFT", buttonContainer, "CENTER", 5, 0)
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

  -- Main scroll frame setup
  local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame)
  scrollFrame:SetSize(430, 0)
  scrollFrame:SetPoint("TOP", searchContainer, "BOTTOM", 0, -3)
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

  -- Initial population after a short delay to ensure UI is ready
  C_Timer.After(0.2, function()
    GUI:RefreshDatabaseTabList()
    DM:DatabaseDebug("Initial database list refresh completed")
  end)
end

-- Helper to group spells by Class -> Spec -> ID
function GUI:GetGroupedSpellDatabase()
  local grouped = {}
  local processedSpells = {} -- Track already processed spells to avoid duplicates

  -- Iterate through class profiles to get all specs
  if not DotMasterDB or not DotMasterDB.classProfiles then
    DM:DatabaseDebug("DotMasterDB or classProfiles is nil or empty")
    return grouped
  end

  local count = 0

  -- Iterate through all class profiles
  for className, classData in pairs(DotMasterDB.classProfiles) do
    if not grouped[className] then
      grouped[className] = {}
    end

    -- Iterate through specs within this class
    for specID, specData in pairs(classData) do
      local specName = select(2, GetSpecializationInfoByID(specID)) or "Unknown"

      -- Skip the "Unknown" category if we already have a proper spec for this class
      if specName ~= "Unknown" or next(grouped[className]) == nil then
        if not grouped[className][specID] then
          grouped[className][specID] = {
            spells = {},
            specName = specName -- Store spec name for display
          }
        end

        -- Add spells from this spec to the grouped data
        if specData.spells then
          for spellID, spellData in pairs(specData.spells) do
            -- If we're in an "Unknown" spec and the spell exists in another spec for this class, skip it
            local spellKey = className .. ":" .. spellID
            if specName ~= "Unknown" or not processedSpells[spellKey] then
              grouped[className][specID].spells[spellID] = spellData
              processedSpells[spellKey] = true
              count = count + 1
            end
          end
        end
      end
    end

    -- If we have a valid spec with spells, remove any "Unknown" spec that might exist
    local hasValidSpec = false
    for specID, specData in pairs(grouped[className]) do
      local specName = specData.specName
      if specName ~= "Unknown" and next(specData.spells) then
        hasValidSpec = true
        break
      end
    end

    if hasValidSpec then
      -- Find and remove any "Unknown" spec
      for specID, specData in pairs(grouped[className]) do
        if specData.specName == "Unknown" then
          grouped[className][specID] = nil
          break
        end
      end
    end
  end

  DM:DatabaseDebug("GetGroupedSpellDatabase processed " .. count .. " entries")
  return grouped
end

-- Function to refresh the database list UI
function GUI:RefreshDatabaseTabList(query)
  query = query and query:lower() or ""
  DM:DatabaseDebug(string.format("Refreshing Database Tab List with query: '%s'", query))

  local scrollChild = GUI.dbScrollChild
  if not scrollChild then
    DM:DatabaseDebug("ERROR: dbScrollChild is nil in RefreshDatabaseTabList")
    return
  end

  -- Clear existing content
  for _, child in pairs({ scrollChild:GetChildren() }) do
    if child and child.Hide then
      child:Hide()
    end
    if child and child.SetParent then
      child:SetParent(nil)
    end
  end
  wipe(GUI.dbClassFrames or {})

  -- Hide any existing friendly message
  if scrollChild.friendlyMessage then
    scrollChild.friendlyMessage:Hide()
  end

  -- Set scroll child height to ensure visibility
  scrollChild:SetHeight(400)

  local groupedData = self:GetGroupedSpellDatabase()

  -- Check if database is empty
  local hasAnySpells = false
  for className, classSpecs in pairs(groupedData) do
    for specID, specData in pairs(classSpecs) do
      if next(specData.spells) then
        hasAnySpells = true
        break
      end
    end
    if hasAnySpells then break end
  end

  if not hasAnySpells then
    -- Show friendly message for empty database
    if not scrollChild.friendlyMessage then
      scrollChild.friendlyMessage = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      scrollChild.friendlyMessage:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
      scrollChild.friendlyMessage:SetText("No spells found in database. Use 'Find My Dots' to discover spells.")
      scrollChild.friendlyMessage:SetTextColor(1, 0.82, 0)
    end
    scrollChild.friendlyMessage:Show()
    scrollChild:SetHeight(200)
    return
  end

  -- Filter spells based on search query
  if query ~= "" then
    local filteredData = {}
    for className, classSpecs in pairs(groupedData) do
      local filteredSpecs = {}
      -- Check if class name matches the query
      local displayClassName = (DM:GetClassDisplayName(className) or className):lower()
      local classNameMatches = displayClassName:find(query, 1, true)

      for specID, specData in pairs(classSpecs) do
        local filteredSpells = {}
        local specName = specData.specName:lower()
        local specNameMatches = specName:find(query, 1, true)

        for spellID, spellData in pairs(specData.spells) do
          -- Search in spell name, ID, class name, and spec name
          local spellName = (spellData.spellname or ""):lower()
          local spellIDStr = tostring(spellID)
          local nameMatch = spellName:find(query, 1, true)
          local idMatch = spellIDStr:find(query, 1, true)

          if nameMatch or idMatch or classNameMatches or specNameMatches then
            filteredSpells[spellID] = spellData
          end
        end

        if next(filteredSpells) then
          filteredSpecs[specID] = {
            spells = filteredSpells,
            specName = specData.specName
          }
        end
      end

      if next(filteredSpecs) then
        filteredData[className] = filteredSpecs
      end
    end
    groupedData = filteredData
  end

  -- Log database stats
  local classCount, specCount, spellCount = 0, 0, 0
  for className, classSpecs in pairs(groupedData) do
    classCount = classCount + 1
    for specID, specData in pairs(classSpecs) do
      specCount = specCount + 1
      for _ in pairs(specData.spells) do
        spellCount = spellCount + 1
      end
    end
  end
  DM:DatabaseDebug(string.format("Database structure: %d classes, %d specs, %d spells (filtered by: '%s')",
    classCount, specCount, spellCount, query))

  -- Show search results message if no matches found
  if spellCount == 0 and query ~= "" then
    if not scrollChild.friendlyMessage then
      scrollChild.friendlyMessage = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      scrollChild.friendlyMessage:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
    end
    scrollChild.friendlyMessage:SetText(string.format("No spells found matching '%s'", query))
    scrollChild.friendlyMessage:SetTextColor(1, 0.82, 0)
    scrollChild.friendlyMessage:Show()
    scrollChild:SetHeight(200)
    return
  end

  local yOffset = 0
  local entryHeight = 25
  local headerHeight = 40
  local specHeaderHeight = 30
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth()

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
    indicator:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
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
    local classSpecs = groupedData[className]

    -- First check if this class has any specs with spells
    local classHasAnySpells = false
    for specID, specData in pairs(classSpecs) do
      if next(specData.spells) then
        classHasAnySpells = true
        break
      end
    end

    -- Skip creating the class frame if it has no specs with spells
    if not classHasAnySpells then
      DM:DatabaseDebug("Skipping empty class: " .. className)
    else
      -- Create class header frame
      local classFrame = CreateFrame("Button", nil, scrollChild)
      classFrame:SetSize(effectiveWidth, headerHeight)
      classFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
      classFrame.isExpanded = true -- Default expand all in DB tab
      classFrame.specFrames = {}
      classFrame:Show()
      GUI.dbClassFrames[className] = classFrame

      -- Add mouseover highlight
      AddMouseoverHighlight(classFrame)

      -- Class Header Background/Text
      local bg = classFrame:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0, 0, 0, 0.8)
      if DM.classColors[className] then
        local color = DM.classColors[className]
        bg:SetColorTexture(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
      end

      local text = classFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
      text:SetPoint("LEFT", 20, 0)
      local displayName = DM:GetClassDisplayName(className) or className
      text:SetText(displayName)

      -- Expand/collapse indicator
      classFrame.indicator = CreateIndicator(classFrame, classFrame.isExpanded)
      if DM.classColors[className] then
        local color = DM.classColors[className]
        text:SetTextColor(color.r, color.g, color.b)
      end

      yOffset = yOffset + headerHeight + spacing

      -- Sort specs by name
      local sortedSpecs = {}
      for specID in pairs(classSpecs) do table.insert(sortedSpecs, specID) end
      table.sort(sortedSpecs, function(a, b)
        local specNameA = classSpecs[a].specName or ""
        local specNameB = classSpecs[b].specName or ""
        return specNameA < specNameB
      end)

      for _, specID in ipairs(sortedSpecs) do
        local specData = classSpecs[specID]

        -- Skip specs with no spells
        if next(specData.spells) then
          -- Create spec header frame
          local specFrame = CreateFrame("Button", nil, scrollChild)
          specFrame:SetSize(effectiveWidth, specHeaderHeight)
          specFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
          specFrame.isExpanded = true -- Default expand all specs
          specFrame.spellFrames = {}
          specFrame:Show()

          -- Hide spec frame initially if class is collapsed
          if not classFrame.isExpanded then
            specFrame:Hide()
          end

          -- Add to class frame's spec frames
          table.insert(classFrame.specFrames, specFrame)

          -- Add mouseover highlight
          AddMouseoverHighlight(specFrame)

          -- Spec Header Background/Text
          local specBg = specFrame:CreateTexture(nil, "BACKGROUND")
          specBg:SetAllPoints()
          specBg:SetColorTexture(0.1, 0.1, 0.1, 0.7)

          -- Create spec icon (smaller size)
          local icon = specFrame:CreateTexture(nil, "ARTWORK")
          icon:SetSize(26, 26) -- Reduced from 32x32
          icon:SetPoint("LEFT", specFrame, "LEFT", 8, 0)

          -- Set spec icon based on specID
          local iconPath = "Interface\\Icons\\INV_Misc_QuestionMark" -- Default icon
          local usesDefaultWowIcon = true                            -- Flag to track if we are using a default WoW icon or a custom TGA
          local originalSpecNameFromDB = specData.specName
          local numericSpecID = tonumber(specID)

          if not numericSpecID then
            local classSpecificNameMappings = {
              DEATHKNIGHT = { Blood = 250, Frost = 251, Unholy = 252 },
              DEMONHUNTER = { Havoc = 577, Vengeance = 581 },
              DRUID = { Balance = 102, Feral = 103, Guardian = 104, Restoration = 105 },
              EVOKER = { Devastation = 1467, Preservation = 1468, Augmentation = 1473 },
              HUNTER = { ["Beast Mastery"] = 253, Marksmanship = 254, Survival = 255, BM = 253, MM = 254 },
              MAGE = { Arcane = 62, Fire = 63, Frost = 64 },
              MONK = { Brewmaster = 268, Windwalker = 269, Mistweaver = 270 },
              PALADIN = { Holy = 65, Protection = 66, Retribution = 70 },
              PRIEST = { Discipline = 256, Holy = 257, Shadow = 258 },
              ROGUE = { Assassination = 259, Outlaw = 260, Subtlety = 261 },
              SHAMAN = { Elemental = 262, Enhancement = 263, Restoration = 264 },
              WARLOCK = { Affliction = 265, Demonology = 266, Destruction = 267 },
              WARRIOR = { Arms = 71, Fury = 72, Protection = 73 }
            }
            if classSpecificNameMappings[className] and classSpecificNameMappings[className][originalSpecNameFromDB] then
              numericSpecID = classSpecificNameMappings[className][originalSpecNameFromDB]
            end
          end

          local specIconPaths = {
            [250] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dk_blood.tga",
            [251] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dk_frost.tga",
            [252] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dk_unholy.tga",
            [577] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dh_havoc.tga",
            [581] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dh_vengeance.tga",
            [102] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\balance__2025_05_14_06_35_06_UTC_.tga",
            [103] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\feral__2025_05_14_06_35_06_UTC_.tga",
            [104] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\guardian__2025_05_14_06_35_06_UTC_.tga",
            [105] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\restoration__2025_05_14_06_35_06_UTC_.tga",
            [1467] = "Interface\\AddOns\\DotMaster\\Media\\spec\\evoker_devestation.tga",
            [1468] = "Interface\\AddOns\\DotMaster\\Media\\spec\\evoker_preservation.tga",
            [1473] = "Interface\\AddOns\\DotMaster\\Media\\spec\\evoker_augmentation.tga",
            [253] = "Interface\\AddOns\\DotMaster\\Media\\spec\\hunter_bm.tga",
            [254] = "Interface\\AddOns\\DotMaster\\Media\\spec\\hunter_mm.tga",
            [255] = "Interface\\AddOns\\DotMaster\\Media\\spec\\hunter_survival.tga",
            [62] = "Interface\\AddOns\\DotMaster\\Media\\spec\\mage_arcane.tga",
            [63] = "Interface\\AddOns\\DotMaster\\Media\\spec\\mage_fire.tga",
            [64] = "Interface\\AddOns\\DotMaster\\Media\\spec\\mage_frost.tga",
            [268] = "Interface\\AddOns\\DotMaster\\Media\\spec\\monk_brewmaster.tga",
            [269] = "Interface\\AddOns\\DotMaster\\Media\\spec\\monk_ww.tga",
            [270] = "Interface\\AddOns\\DotMaster\\Media\\spec\\monk_mistweaver.tga",
            [65] = "Interface\\AddOns\\DotMaster\\Media\\spec\\paladin_holy.tga",
            [66] = "Interface\\AddOns\\DotMaster\\Media\\spec\\paladin_protection.tga",
            [70] = "Interface\\AddOns\\DotMaster\\Media\\spec\\paladin_ret.tga",
            [256] = "Interface\\AddOns\\DotMaster\\Media\\spec\\priest_disc.tga",
            [257] = "Interface\\AddOns\\DotMaster\\Media\\spec\\priest_holy.tga",
            [258] = "Interface\\AddOns\\DotMaster\\Media\\spec\\priest_shadow.tga",
            [259] = "Interface\\AddOns\\DotMaster\\Media\\spec\\rogue_assa.tga",
            [260] = "Interface\\AddOns\\DotMaster\\Media\\spec\\rogue_outlaw.tga",
            [261] = "Interface\\AddOns\\DotMaster\\Media\\spec\\rogue_sub.tga",
            [262] = "Interface\\AddOns\\DotMaster\\Media\\spec\\shaman_elem.tga",
            [263] = "Interface\\AddOns\\DotMaster\\Media\\spec\\shaman_enhancement.tga",
            [264] = "Interface\\AddOns\\DotMaster\\Media\\spec\\shaman_resto.tga",
            [265] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warlock_affli.tga",
            [266] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warlock_demono.tga",
            [267] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warlock_destru.tga",
            [71] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warrior_arms.tga",
            [72] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warrior_fury.tga",
            [73] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warrior_prot.tga",
          }

          if numericSpecID and specIconPaths[numericSpecID] then
            iconPath = specIconPaths[numericSpecID]
            usesDefaultWowIcon = false
          end

          icon:SetTexture(iconPath)

          -- Set proper texture coordinates for WoW icons (not needed for TGA files)
          if usesDefaultWowIcon then
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
          end

          local specText = specFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
          specText:SetPoint("LEFT", icon, "RIGHT", 8, 0) -- Position text next to icon
          specText:SetText(specData.specName)

          -- Expand/collapse indicator for spec
          specFrame.indicator = CreateIndicator(specFrame, specFrame.isExpanded)

          yOffset = yOffset + specHeaderHeight + spacing

          -- Sort Spells by priority then name
          local sortedSpells = {}
          for spellID in pairs(specData.spells) do table.insert(sortedSpells, spellID) end
          table.sort(sortedSpells, function(a, b)
            local spellA = specData.spells[a]
            local spellB = specData.spells[b]
            if spellA.priority and spellB.priority then
              return spellA.priority < spellB.priority
            end
            local nameA = spellA.spellname or ""
            local nameB = spellB.spellname or ""
            return nameA < nameB
          end)

          local visibleSpellCount = 0

          for _, spellID in ipairs(sortedSpells) do
            local spellData = specData.spells[spellID]

            visibleSpellCount = visibleSpellCount + 1
            local spellFrame = CreateFrame("Frame", nil, scrollChild)
            -- Align spell frame with indentation
            spellFrame:SetSize(effectiveWidth, entryHeight)
            spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)

            -- Hide spell frame initially if spec is collapsed
            if not specFrame.isExpanded or not classFrame.isExpanded then
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

            table.insert(specFrame.spellFrames, spellFrame) -- Add to specFrame.spellFrames

            -- Spell Icon (less indentation)
            local icon = spellFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", 45, 0) -- Reduced indentation from 60 to 45
            local iconPath = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark"
            icon:SetTexture(iconPath)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Spell Name & ID
            local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameText:SetWidth(spellFrame:GetWidth() - 160) -- Wider for indentation
            nameText:SetText(string.format("%s (%d)", spellData.spellname or "Unknown", spellID))
            nameText:SetJustifyH("LEFT")

            -- Track Checkbox for this spec - align with toggle button
            local checkbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
            checkbox:SetSize(20, 20)
            checkbox:SetPoint("RIGHT", -16, 0) -- Align with toggle buttons
            checkbox:SetChecked(spellData.tracked == 1)

            local trackLabel = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            trackLabel:SetText("Track")
            trackLabel:SetPoint("RIGHT", checkbox, "LEFT", -6, 0) -- Increased spacing from -2 to -6

            -- Store the class and spec ID with the checkbox for later reference
            checkbox.className = className
            checkbox.specID = specID
            checkbox.spellID = spellID

            checkbox:SetScript("OnClick", function(self)
              local isChecked = self:GetChecked()

              -- Get the relevant profile from DotMasterDB
              if not DotMasterDB.classProfiles[self.className] or
                  not DotMasterDB.classProfiles[self.className][self.specID] then
                DM:PrintMessage("Error: Could not find profile for " .. self.className .. "-" .. self.specID)
                return
              end

              local profile = DotMasterDB.classProfiles[self.className][self.specID]

              -- Make sure spells table exists
              if not profile.spells then
                profile.spells = {}
              end

              -- Update the tracked status
              if profile.spells[self.spellID] then
                profile.spells[self.spellID].tracked = isChecked and 1 or 0
                DM:DatabaseDebug(string.format("Spell %d tracked status set to %d for %s-%s",
                  self.spellID, profile.spells[self.spellID].tracked, self.className, specData.specName))
              end

              -- If this is the current player's spec, push changes to Plater
              local currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
              if currentClass == self.className and currentSpecID == self.specID and
                  DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
                DM.ClassSpec:PushConfigToPlater()
              end

              -- Refresh the tracked spells tab
              if GUI.RefreshTrackedSpellTabList then
                GUI:RefreshTrackedSpellTabList()
              end
            end)

            -- Only increment yOffset if the spell is actually visible
            if specFrame.isExpanded and classFrame.isExpanded then
              yOffset = yOffset + entryHeight + spacing
            end
          end -- End Spell Loop

          -- Spec Header Click Handler (Expand/Collapse Spells)
          specFrame:SetScript("OnClick", function(self)
            self.isExpanded = not self.isExpanded

            -- Update indicator
            self.indicator:SetTexture(self.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
              "Interface\\Buttons\\UI-PlusButton-Up")

            -- Toggle visibility of spellFrames
            for _, frame in ipairs(self.spellFrames) do
              if self.isExpanded and classFrame.isExpanded then
                frame:Show()
              else
                frame:Hide()
              end
            end
            GUI:UpdateDatabaseLayout()
          end)
        else
          DM:DatabaseDebug("Skipping empty spec: " .. specData.specName .. " for class " .. className)
        end
      end -- End Spec Loop

      -- Class Header Click Handler (Expand/Collapse Specs and Spells)
      classFrame:SetScript("OnClick", function(self)
        self.isExpanded = not self.isExpanded

        -- Update indicator
        self.indicator:SetTexture(self.isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or
          "Interface\\Buttons\\UI-PlusButton-Up")

        -- Toggle visibility of specFrames
        for _, specFrame in ipairs(self.specFrames) do
          if self.isExpanded then
            specFrame:Show()
            -- Also show spell frames if spec is expanded
            if specFrame.isExpanded then
              for _, spellFrame in ipairs(specFrame.spellFrames) do
                spellFrame:Show()
              end
            end
          else
            specFrame:Hide()
            -- Hide all spell frames when class is collapsed
            for _, spellFrame in ipairs(specFrame.spellFrames) do
              spellFrame:Hide()
            end
          end
        end
        GUI:UpdateDatabaseLayout()
      end)
    end
  end -- End Class Loop

  -- Final layout update (will reposition based on initial visibility)
  GUI:UpdateDatabaseLayout()
  scrollChild:Show()
end

-- Function to recalculate positions after expand/collapse
function GUI:UpdateDatabaseLayout()
  local scrollChild = GUI.dbScrollChild
  if not scrollChild then return end

  local yOffset = 0
  local entryHeight = 25
  local headerHeight = 40
  local specHeaderHeight = 30
  local spacing = 3
  local effectiveWidth = scrollChild:GetWidth()

  -- Iterate through sorted classes
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
        -- Position spec frames under the class
        for _, specFrame in ipairs(classFrame.specFrames or {}) do
          specFrame:ClearAllPoints()
          specFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
          specFrame:SetWidth(effectiveWidth)
          specFrame:Show()
          yOffset = yOffset + specHeaderHeight + spacing

          -- If spec is expanded, position spell frames under it
          if specFrame.isExpanded then
            for _, spellFrame in ipairs(specFrame.spellFrames or {}) do
              spellFrame:ClearAllPoints()
              spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
              spellFrame:SetWidth(effectiveWidth)
              spellFrame:Show()
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

-- Updated reset function that clears all class profiles
function DM:ResetDMSpellsDB()
  -- Clear all spells from all class profiles
  if DotMasterDB and DotMasterDB.classProfiles then
    for className, classData in pairs(DotMasterDB.classProfiles) do
      for specID, specData in pairs(classData) do
        -- Clear spells and combinations for this spec
        specData.spells = {}
        specData.combinations = {}
      end
    end
    DM:PrintMessage("Database has been reset - all spells removed.")
  end

  -- For legacy compatibility
  DM.dmspellsdb = {}

  -- SPECIAL HANDLING: Explicitly remove any problematic spell with ID=1
  -- Try to access the specific Death Knight Unholy profile that shows in the screenshot
  if DotMasterDB and DotMasterDB.classProfiles and DotMasterDB.classProfiles["DEATHKNIGHT"] then
    for specID, specData in pairs(DotMasterDB.classProfiles["DEATHKNIGHT"]) do
      -- Check if this is the Unholy spec (252)
      if specID == "252" and specData.spells then
        -- Additional debug output
        for spellID, spellData in pairs(specData.spells) do
          DM:PrintMessage(string.format("Found spell in DK Unholy: ID=%s, Name=%s",
            tostring(spellID), spellData.spellname or "Unknown"))
        end
        -- Remove any Unknown or ID=1 spell directly
        specData.spells[1] = nil
        specData.spells["1"] = nil
        -- Look for anything with "Unknown" in name
        for spellID, spellData in pairs(specData.spells) do
          if spellData.spellname and spellData.spellname:find("Unknown") then
            DM:PrintMessage(string.format("Removed problematic spell: %s (%s)",
              spellData.spellname, tostring(spellID)))
            specData.spells[spellID] = nil
          end
        end
      end
    end
  end

  -- CUSTOM FIX: Direct deep-cleaning of the saved variables table
  DM:PrintMessage("Performing deep database cleanup")

  -- 1. Clean the legacy database structure completely
  if DotMasterDB then
    DotMasterDB.dmspellsdb = nil
    DotMasterDB.spellConfig = nil
  end

  -- 2. Extra removal step: force rebuild Death Knight profiles from scratch
  if DotMasterDB and DotMasterDB.classProfiles and DotMasterDB.classProfiles["DEATHKNIGHT"] then
    DM:PrintMessage("Rebuilding Death Knight profiles")
    DotMasterDB.classProfiles["DEATHKNIGHT"] = {}

    -- Initialize a clean Unholy spec structure
    DotMasterDB.classProfiles["DEATHKNIGHT"]["252"] = {
      settings = {},
      spells = {},
      combinations = {}
    }
  end

  -- Push changes to Plater
  if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
    DM.ClassSpec:PushConfigToPlater()
  end

  -- Force UI refresh
  if GUI and GUI.RefreshDatabaseTabList then
    GUI:RefreshDatabaseTabList()
  end
  if GUI and GUI.RefreshTrackedSpellTabList then
    GUI:RefreshTrackedSpellTabList()
  end
end
