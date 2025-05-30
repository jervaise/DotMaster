-- DotMaster gui_tracked_spells_tab.lua
-- Content for the Tracked Spells Tab

local DM = DotMaster
local Components = DotMaster_Components -- Reuse existing component namespace if applicable
local GUI = DM.GUI                      -- Alias for convenience

-- Add placeholder functions for the tracked spells list
function DM.GUI:RefreshTrackedSpellTabList(filter)
  -- Get current class
  local currentClass = select(2, UnitClass("player"))

  -- Create new rows for each spell in DM.dmspellsdb
  local scrollChild = GUI.trackedScrollChild
  if not scrollChild then
    DM:GUIDebug("ERROR: No tracking scroll child in RefreshTrackedSpellTabList")
    return
  end

  -- Clear existing rows
  for _, row in ipairs(GUI.trackedSpellRows or {}) do
    row:Hide()
    row:ClearAllPoints()
  end
  GUI.trackedSpellRows = GUI.trackedSpellRows or {}

  -- Check if we have any spells
  if not DM.dmspellsdb then
    DM:GUIDebug("ERROR: No dmspellsdb found in RefreshTrackedSpellTabList")
    return
  end

  -- Get layout references
  local LAYOUT = DM.GUI.layout
  local COLUMN_POSITIONS = LAYOUT.columns
  local COLUMN_WIDTHS = LAYOUT.widths

  -- Create search filter
  local searchFilter = filter and filter:lower() or ""

  -- Collect all spells into a sorted array
  local spellList = {}
  for spellID, spellData in pairs(DM.dmspellsdb) do
    -- Only include spells for the current class or unknown class
    if spellData.wowclass == currentClass or spellData.wowclass == "UNKNOWN" then
      -- Apply search filter if provided
      local spellName = spellData.spellname or ""
      if searchFilter == "" or spellName:lower():find(searchFilter, 1, true) then
        table.insert(spellList, {
          id = tonumber(spellID),
          data = spellData,
          priority = spellData.priority or 999
        })
      end
    end
  end

  -- Sort by priority
  table.sort(spellList, function(a, b)
    return (a.priority or 999) < (b.priority or 999)
  end)

  DM:DebugMsg("RefreshTrackedSpellTabList called with filter: " .. (filter or ""))
end

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

  -- Add from Database button
  local addFromDatabaseButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  addFromDatabaseButton:SetSize(150, 30)
  addFromDatabaseButton:SetPoint("RIGHT", buttonContainer, "CENTER", -5, 0)
  addFromDatabaseButton:SetText("Add from Database")

  addFromDatabaseButton:SetScript("OnClick", function()
    -- Try to find and click on the Database tab
    local databaseTabButton = _G["DotMasterTab4"]
    if databaseTabButton and databaseTabButton.Click then
      databaseTabButton:Click()
      DM:GUIDebug("Switched to Database tab via 'Add from Database' button")
    else
      DM:GUIDebug("ERROR: Could not find Database tab button (DotMasterTab4)")
    end
  end)

  -- Find My Dots button (right side)
  local findMyDotsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  findMyDotsButton:SetSize(150, 30)
  findMyDotsButton:SetPoint("LEFT", buttonContainer, "CENTER", 5, 0)
  findMyDotsButton:SetText("Find My Dots")
  findMyDotsButton:SetScript("OnClick", function()
    DM:StartFindMyDots()
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
  CreateHeaderLabel("TRACKED", "CENTER", untrackStart + (untrackWidth / 2) + 1) -- Center with untrack button, moved 3px right

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

-- Helper to group tracked spells by Class -> Spec -> ID
function GUI:GetGroupedTrackedSpells()
  local grouped = {}

  -- Get current player class
  local currentClass = select(2, UnitClass("player"))

  -- Get current spec profile
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DatabaseDebug("Could not access current spec profile")
    return grouped
  end

  -- Check if the spells table exists
  if not currentProfile.spells then
    DM:DatabaseDebug("Current spec profile has no spells table")
    return grouped
  end

  -- Check if spells table is empty
  local isEmpty = true
  for _ in pairs(currentProfile.spells) do
    isEmpty = false
    break
  end

  if isEmpty then
    DM:DatabaseDebug("Current spec profile's spells table is empty")
    return grouped
  end

  local count = 0
  for idStr, data in pairs(currentProfile.spells) do
    -- Only include tracked spells (using tonumber for robustness)
    local tracked = tonumber(data.tracked)
    if tracked == 1 then
      -- Convert string ID to number if needed
      local id = tonumber(idStr)
      count = count + 1

      if not id then
        DM:DatabaseDebug(string.format("WARNING: Invalid spell ID in current spec's spells: %s", tostring(idStr)))
        -- Skip this entry
      else
        local className = data.wowclass or currentClass or "UNKNOWN"
        local specName = data.wowspec or "General"

        -- Initialize class in the table if needed
        if not grouped[className] then
          grouped[className] = {}
        end

        -- Initialize spec in the class table if needed
        if not grouped[className][specName] then
          grouped[className][specName] = {}
        end

        -- Add the spell to the appropriate spec group
        grouped[className][specName][id] = data
      end
    end
  end

  DM:DatabaseDebug("GetGroupedTrackedSpells processed " .. count .. " tracked entries from current spec")
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

  -- Get current spec profile
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile then
    DM:DatabaseDebug("ERROR: Could not access current spec profile when refreshing Tracked Spells tab")
    return
  end

  -- Debug the current spec's spells state
  if not currentProfile.spells then
    DM:DatabaseDebug("ERROR: Current spec has no spells table when refreshing Tracked Spells tab")
    currentProfile.spells = {} -- Initialize it
  else
    local count = 0
    local trackedCount = 0
    for spellID, data in pairs(currentProfile.spells) do
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
    DM:DatabaseDebug(string.format("Current spec has %d spells, %d are tracked", count, trackedCount))
  end

  -- Clear existing content completely
  for _, child in pairs({ scrollChild:GetChildren() }) do
    if child and child.Hide then
      child:Hide()
    end
    if child and child.SetParent then
      child:SetParent(nil) -- Properly remove children to avoid reuse issues
    end
  end
  wipe(GUI.trackedSpecFrames or {}) -- Use wipe for tables
  GUI.trackedSpecFrames = {}

  -- Get tracked spells
  local groupedData = self:GetGroupedTrackedSpells()
  local hasTrackedSpells = false

  -- Check if we have any tracked spells
  for className, specTable in pairs(groupedData) do
    for specName, specSpells in pairs(specTable) do
      if next(specSpells) then
        hasTrackedSpells = true
        break
      end
    end
    if hasTrackedSpells then break end
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

  local yOffset = 2           -- Reduced from 5 to 2 for tighter spacing
  local entryHeight = 40
  local specHeaderHeight = 40 -- Same height as old class headers
  local spacing = 3
  -- Use full scrollChild width for rows now
  local effectiveWidth = scrollChild:GetWidth() -- 430px

  -- Get player class token
  local currentClass = select(2, UnitClass("player"))

  -- Get all specs from all classes and flatten them into a single list
  local allSpecs = {}

  for className, specTable in pairs(groupedData) do
    for specName, specSpells in pairs(specTable) do
      -- Only add if it has spells
      if next(specSpells) then
        table.insert(allSpecs, {
          className = className,
          specName = specName,
          spells = specSpells
        })
      end
    end
  end

  -- Sort specs alphabetically
  table.sort(allSpecs, function(a, b)
    if a.className == b.className then
      return a.specName < b.specName
    end
    return a.className < b.className
  end)

  -- Process each spec
  for _, specInfo in ipairs(allSpecs) do
    local className = specInfo.className
    local specName = specInfo.specName
    local specSpells = specInfo.spells

    -- Create a spec header
    local specFrame = CreateFrame("Button", nil, scrollChild)
    specFrame:SetSize(effectiveWidth, specHeaderHeight)
    specFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset) -- No indentation

    -- Store in tracking tables
    GUI.trackedSpecFrames[className .. "_" .. specName] = specFrame
    specFrame.specName = specName
    specFrame.className = className
    specFrame.spellFrames = {}
    specFrame.isExpanded = GUI.trackedSpecFramesState and GUI.trackedSpecFramesState[className .. "_" .. specName] or
        true -- Default to expanded, maintain state

    -- Background and border
    local specBg = specFrame:CreateTexture(nil, "BACKGROUND")
    specBg:SetAllPoints()

    -- Use class colors for spec header background
    local classColor = DM.classColors and DM.classColors[className] or { r = 0.2, g = 0.2, b = 0.2 }
    specBg:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.3)

    -- Create spec icon
    local icon = specFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", specFrame, "LEFT", 8, 0)

    -- Restore original spec icon logic
    local iconPath = "Interface\\Icons\\INV_Misc_QuestionMark" -- Default icon
    local usesDefaultWowIcon = true                            -- Flag to track if we are using a default WoW icon or a custom TGA
    local originalSpecNameFromDB = specName
    local specID = tonumber(specName)

    if not specID then
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
        specID = classSpecificNameMappings[className][originalSpecNameFromDB]
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

    if specID and specIconPaths[specID] then
      iconPath = specIconPaths[specID]
      usesDefaultWowIcon = false                      -- It's a custom TGA
    elseif originalSpecNameFromDB == "General" then
      iconPath = "Interface\\Icons\\INV_Misc_Book_09" -- Book icon for general stuff
      usesDefaultWowIcon = true                       -- This is a default WoW icon
    end

    icon:SetTexture(iconPath)
    if usesDefaultWowIcon then
      icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Standard crop for Blizzard icons
    else
      icon:SetTexCoord(0, 1, 0, 1)             -- Use this for custom TGAs that fill the whole texture
    end

    -- Spec name text
    local displayName = specName
    if specID and specID > 0 then
      local _, specNameLocalized = GetSpecializationInfoByID(specID)
      if specNameLocalized then
        displayName = specNameLocalized
      end
    end

    -- Format spec text without class name
    local textLabel = displayName

    local text = specFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") -- Use larger font
    text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    text:SetText(textLabel)
    text:SetJustifyH("LEFT")

    -- Apply class color to text
    if classColor then
      text:SetTextColor(classColor.r, classColor.g, classColor.b)
    end

    -- Expand/collapse button
    local expandBtn = CreateFrame("Button", nil, specFrame)
    expandBtn:SetSize(16, 16)
    expandBtn:SetPoint("RIGHT", specFrame, "RIGHT", -5, 0)
    if specFrame.isExpanded then
      expandBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
      expandBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
    else
      expandBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
      expandBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
    end
    expandBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")

    -- Set the toggle functionality for both the expand button and the header itself
    local function ToggleHeaderExpansion()
      specFrame.isExpanded = not specFrame.isExpanded
      GUI.trackedSpecFramesState = GUI.trackedSpecFramesState or {}
      GUI.trackedSpecFramesState[className .. "_" .. specName] = specFrame.isExpanded

      -- Update button texture
      if specFrame.isExpanded then
        expandBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        expandBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")

        -- Show all spell rows
        for _, spellFrameRow in ipairs(specFrame.spellFrames) do
          spellFrameRow:Show()
        end
      else
        expandBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        expandBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")

        -- Hide all spell rows
        for _, spellFrameRow in ipairs(specFrame.spellFrames) do
          spellFrameRow:Hide()
        end
      end

      -- Update layout without full refresh
      GUI:UpdateTrackedSpellsLayout()
    end

    -- Assign toggle function to both the button and the spec frame
    expandBtn:SetScript("OnClick", ToggleHeaderExpansion)
    specFrame:SetScript("OnClick", ToggleHeaderExpansion)

    -- Make it look clickable with mouseover highlight
    specFrame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local highlight = specFrame:GetHighlightTexture()
    highlight:SetAlpha(0.7)

    yOffset = yOffset + specHeaderHeight + spacing

    -- Collect spells for this spec
    local spellsInSpecByPriority = {}
    local uniquePriorityCounter = 1
    local prioritiesChanged = false

    for id, spellData in pairs(specSpells) do
      table.insert(spellsInSpecByPriority, {
        id = id,
        data = spellData,
        priority = tonumber(spellData.priority) or 999 -- Ensure priority is a number
      })
    end

    -- Sort by priority then by name
    table.sort(spellsInSpecByPriority, function(a, b)
      if a.priority == b.priority then
        return (a.data.spellname or "") < (b.data.spellname or "")
      end
      return a.priority < b.priority
    end)

    -- Ensure continuous priority numbers
    for i, entry in ipairs(spellsInSpecByPriority) do -- Use i for uniquePriorityCounter
      -- Check if priority needs reassignment
      if not DM.dmspellsdb[entry.id] or DM.dmspellsdb[entry.id].priority ~= i then
        -- Ensure spell entry exists before modification (safety check)
        if DM.dmspellsdb[entry.id] then
          DM.dmspellsdb[entry.id].priority = i
          DM:DatabaseDebug(string.format("Reassigned priority %d to spell %d (%s) for class %s spec %s",
            i, entry.id, entry.data.spellname or "N/A", className, specName))
          prioritiesChanged = true
        else
          DM:DatabaseDebug(string.format("WARNING: Tried to reassign priority for non-existent spell %d in dmspellsdb",
            entry.id))
        end
      end
    end

    if prioritiesChanged then DM:SaveDMSpellsDB() end

    -- Create spell row frames
    if specFrame.isExpanded then
      local visibleSpellCount = 0

      for spell_idx, entry in ipairs(spellsInSpecByPriority) do
        local id = entry.id
        local spellData = entry.data

        -- Add spell rows
        local spellRow = GUI:CreateTrackedSpellRow(scrollChild, id, spellData, effectiveWidth, spell_idx,
          spellsInSpecByPriority)
        table.insert(specFrame.spellFrames, spellRow)

        -- No indentation - align with left edge
        spellRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        -- Show row if parent is expanded, hide if collapsed
        if specFrame.isExpanded then
          spellRow:Show()
        else
          spellRow:Hide()
        end
        yOffset = yOffset + entryHeight + spacing
        visibleSpellCount = visibleSpellCount + 1
      end

      -- If no spells in this spec, add empty message
      if visibleSpellCount == 0 then
        local emptyText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        emptyText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 40, -yOffset) -- Keep the empty message indented
        emptyText:SetText("No spells found for this specialization")
        emptyText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset + 20 + spacing
      end
    end
  end

  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end

-- Function to recalculate positions after expand/collapse
function GUI:UpdateTrackedSpellsLayout()
  local scrollChild = GUI.trackedScrollChild
  if not scrollChild then return end

  local yOffset = 2           -- Reduced from 5 to 2 for tighter spacing
  local entryHeight = 40      -- Set to 40
  local specHeaderHeight = 40 -- Header height for specs
  local spacing = 3
  -- Use full scrollChild width for rows now
  local effectiveWidth = scrollChild:GetWidth() -- 430px

  -- Sort specs
  local sortedSpecs = {}
  for specKey, specFrame in pairs(GUI.trackedSpecFrames or {}) do
    table.insert(sortedSpecs, {
      key = specKey,
      frame = specFrame,
      className = specFrame.className,
      specName = specFrame.specName
    })
  end

  -- Sort specs (by class then by spec name)
  table.sort(sortedSpecs, function(a, b)
    if a.className == b.className then
      return a.specName < b.specName
    end
    return a.className < b.className
  end)

  -- Position all frames
  for _, specInfo in ipairs(sortedSpecs) do
    local specFrame = specInfo.frame

    -- Position spec header
    specFrame:ClearAllPoints()
    specFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    specFrame:SetWidth(effectiveWidth)
    yOffset = yOffset + specHeaderHeight + spacing

    -- Position spell rows if expanded
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

  scrollChild:SetHeight(math.max(yOffset + 10, 200))
end

-- Function to update tracked spells UI
function GUI:UpdateTrackedSpellsList()
  self:RefreshTrackedSpellTabList()
end

-- Helper function to create a tracked spell row
function GUI:CreateTrackedSpellRow(parent, spellID, spellData, width, rowIndexInSpec, spellsInThisSpecSorted)
  local entryHeight = 40
  local padding = 5
  local checkboxWidth = 20
  local iconSize = 25
  local colorSwatchSize = 24
  local arrowSize = 20 -- Size for up/down arrows
  local untrackWidth = 70

  -- Create the frame
  local spellFrame = CreateFrame("Frame", nil, parent)
  spellFrame:SetSize(width, entryHeight)

  -- Store the spell ID for reference
  spellFrame.spellID = spellID

  -- Row background
  local rowBg = spellFrame:CreateTexture(nil, "BACKGROUND")
  rowBg:SetAllPoints()
  rowBg:SetColorTexture(0, 0, 0, 0.3)

  -- Left side elements
  local currentLeftAnchor = spellFrame
  local currentLeftOffset = padding

  -- Get current spec profile
  local currentProfile = DM:GetCurrentSpecProfile()
  if not currentProfile or not currentProfile.spells then
    DM:DatabaseDebug("ERROR: Cannot access current spec profile in CreateTrackedSpellRow")
    return spellFrame -- Return empty frame to avoid errors
  end

  -- 1. Enabled Checkbox
  local enabledCheckbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
  enabledCheckbox:SetSize(checkboxWidth, checkboxWidth)
  enabledCheckbox:SetPoint("LEFT", currentLeftAnchor, "LEFT", currentLeftOffset, 0)
  if currentProfile.spells[spellID].enabled == nil then currentProfile.spells[spellID].enabled = 1 end
  enabledCheckbox:SetChecked(currentProfile.spells[spellID].enabled == 1)
  enabledCheckbox:SetScript("OnClick", function(self)
    currentProfile.spells[spellID].enabled = self:GetChecked() and 1 or 0
    DM:SaveDMSpellsDB()

    -- Update Plater with the new settings
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      C_Timer.After(0.1, function()
        DM.ClassSpec:PushConfigToPlater()
      end)
    end
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
  currentLeftOffset = padding + 3 -- This is the anchor and offset for the LEFT of nameText

  -- Right-side elements - Placed from Right to Left
  local rightMostPlacedElement = spellFrame -- Start with the row frame itself for the very first right-anchored element
  local offsetToTheLeft = -padding          -- Initial offset from the right edge of spellFrame

  -- 5. Untrack Button (Furthest Right)
  local untrackButton = CreateFrame("Button", nil, spellFrame, "UIPanelButtonTemplate")
  untrackButton:SetSize(untrackWidth, 25)
  untrackButton:SetPoint("RIGHT", rightMostPlacedElement, "RIGHT", offsetToTheLeft, 0)
  untrackButton:SetText("Untrack")
  untrackButton:SetScript("OnClick", function()
    currentProfile.spells[spellID].tracked = 0
    DM:SaveDMSpellsDB()
    GUI:RefreshTrackedSpellTabList()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      C_Timer.After(0.1, function() DM.ClassSpec:PushConfigToPlater() end)
    end
  end)
  rightMostPlacedElement = untrackButton -- Next element will be to the left of this one
  offsetToTheLeft = -5                   -- Gap between Untrack button and Up Arrow

  -- 4b. Up Arrow (to the left of Untrack button)
  local upArrow = CreateFrame("Button", nil, spellFrame)
  upArrow:SetSize(arrowSize, arrowSize)
  upArrow:SetPoint("RIGHT", rightMostPlacedElement, "LEFT", offsetToTheLeft, 0)
  upArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
  upArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
  upArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  upArrow:SetFrameLevel(spellFrame:GetFrameLevel() + 1) -- Match combinations tab
  rightMostPlacedElement = upArrow                      -- Next element will be to the left of this one
  offsetToTheLeft = -2                                  -- Gap between Up Arrow and Down Arrow

  -- 4a. Down Arrow (to the left of Up Arrow)
  local downArrow = CreateFrame("Button", nil, spellFrame)
  downArrow:SetSize(arrowSize, arrowSize)
  downArrow:SetPoint("RIGHT", rightMostPlacedElement, "LEFT", offsetToTheLeft, 0)
  downArrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  downArrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
  downArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  downArrow:SetFrameLevel(spellFrame:GetFrameLevel() + 1) -- Match combinations tab
  rightMostPlacedElement = downArrow                      -- Next element will be to the left of this one
  offsetToTheLeft = -5                                    -- Gap between Down Arrow and Color Swatch

  -- Arrow Click Logic (using current spec's spells array)
  downArrow:SetScript("OnClick", function()
    if rowIndexInSpec < #spellsInThisSpecSorted then
      local nextSpellEntry = spellsInThisSpecSorted[rowIndexInSpec + 1]
      if DM.currentProfile and DM.currentProfile.spells and DM.currentProfile.spells[spellID] and DM.currentProfile.spells[nextSpellEntry.id] then
        local currentPriority = DM.currentProfile.spells[spellID].priority
        local nextPriority = DM.currentProfile.spells[nextSpellEntry.id].priority
        DM.currentProfile.spells[spellID].priority = nextPriority
        DM.currentProfile.spells[nextSpellEntry.id].priority = currentPriority

        DM:DebugMsg("DownArrowClick: Priorities swapped in DM.currentProfile.spells. Count: " ..
          DM:TableCount(DM.currentProfile.spells))

        -- Directly call the main save and Plater push
        if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
          DM.ClassSpec:SaveCurrentSettings() -- This saves DM.currentProfile and pushes to Plater
        else
          DM:DebugMsg("ERROR: SaveCurrentSettings not found!")
        end
        GUI:RefreshTrackedSpellTabList()
      else
        DM:DebugMsg("DownArrowClick: Error accessing currentProfile or spell entries.")
      end
    end
  end)

  upArrow:SetScript("OnClick", function()
    if rowIndexInSpec > 1 then
      local prevSpellEntry = spellsInThisSpecSorted[rowIndexInSpec - 1]
      if DM.currentProfile and DM.currentProfile.spells and DM.currentProfile.spells[spellID] and DM.currentProfile.spells[prevSpellEntry.id] then
        local currentPriority = DM.currentProfile.spells[spellID].priority
        local prevPriority = DM.currentProfile.spells[prevSpellEntry.id].priority
        DM.currentProfile.spells[spellID].priority = prevPriority
        DM.currentProfile.spells[prevSpellEntry.id].priority = currentPriority

        DM:DebugMsg("UpArrowClick: Priorities swapped in DM.currentProfile.spells. Count: " ..
          DM:TableCount(DM.currentProfile.spells))

        -- Directly call the main save and Plater push
        if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
          DM.ClassSpec:SaveCurrentSettings() -- This saves DM.currentProfile and pushes to Plater
        else
          DM:DebugMsg("ERROR: SaveCurrentSettings not found!")
        end
        GUI:RefreshTrackedSpellTabList()
      else
        DM:DebugMsg("UpArrowClick: Error accessing currentProfile or spell entries.")
      end
    end
  end)

  -- Disable/Enable Arrows (Same as before)
  if spellsInThisSpecSorted and #spellsInThisSpecSorted > 0 then
    if rowIndexInSpec == #spellsInThisSpecSorted then
      downArrow:Disable(); downArrow:SetAlpha(0.5)
    else
      downArrow:Enable(); downArrow:SetAlpha(1.0)
    end
    if rowIndexInSpec == 1 then
      upArrow:Disable(); upArrow:SetAlpha(0.5)
    else
      upArrow:Enable(); upArrow:SetAlpha(1.0)
    end
  else
    downArrow:Disable(); downArrow:SetAlpha(0.5)
    upArrow:Disable(); upArrow:SetAlpha(0.5)
  end

  -- 3. Color Swatch (to the left of Down Arrow)
  local r, g, b = 1, 0, 0
  if spellData.color and type(spellData.color) == "table" and #spellData.color >= 3 then
    r, g, b = tonumber(spellData.color[1]) or 1, tonumber(spellData.color[2]) or 0, tonumber(spellData.color[3]) or 0
  end
  local colorSwatch = CreateFrame("Button", nil, spellFrame)
  colorSwatch:SetSize(colorSwatchSize, colorSwatchSize)
  colorSwatch:SetPoint("RIGHT", rightMostPlacedElement, "LEFT", offsetToTheLeft, 0)
  local border = colorSwatch:CreateTexture(nil, "BACKGROUND"); border:SetAllPoints(); border:SetColorTexture(0.1, 0.1,
    0.1, 1)
  local texture = colorSwatch:CreateTexture(nil, "ARTWORK"); texture:SetPoint("TOPLEFT", 2, -2); texture:SetPoint(
    "BOTTOMRIGHT", -2, 2); texture:SetColorTexture(r, g, b, 1)
  colorSwatch:SetScript("OnEnter", function(self)
    border:SetColorTexture(0.3, 0.3, 0.3, 1); GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(
      "Color Values")
    GameTooltip:AddLine("R: " .. math.floor(r * 255) .. " G: " .. math.floor(g * 255) .. " B: " .. math.floor(b * 255), 1,
      1, 1)
    GameTooltip:AddLine("Click to change color", 0.7, 0.7, 0.7); GameTooltip:Show()
  end)
  colorSwatch:SetScript("OnLeave", function()
    border:SetColorTexture(0.1, 0.1, 0.1, 1); GameTooltip:Hide()
  end)
  colorSwatch:SetScript("OnClick", function()
    -- Store the original colors for cancel function
    local originalR, originalG, originalB = r, g, b

    -- Use our enhanced color picker with favorites
    if DotMaster_ShowEnhancedColorPicker then
      DotMaster_ShowEnhancedColorPicker(r, g, b, function(newR, newG, newB)
        -- Update the texture
        texture:SetColorTexture(newR, newG, newB, 1)
        r, g, b = newR, newG, newB

        -- Save to database
        if currentProfile.spells[spellID] then
          currentProfile.spells[spellID].color = { newR, newG, newB }
          DM:SaveDMSpellsDB()
          if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
            C_Timer.After(0.1, function()
              DM.ClassSpec:PushConfigToPlater()
            end)
          end
        end
      end)
    else
      -- Fallback to DM:ShowColorPicker if enhanced version not available
      DM:ShowColorPicker(r, g, b, function(newR, newG, newB)
        -- Update the texture
        texture:SetColorTexture(newR, newG, newB, 1)
        r, g, b = newR, newG, newB

        -- Save to database
        if currentProfile.spells[spellID] then
          currentProfile.spells[spellID].color = { newR, newG, newB }
          DM:SaveDMSpellsDB()
          if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
            C_Timer.After(0.1, function()
              DM.ClassSpec:PushConfigToPlater()
            end)
          end
        end
      end)
    end
  end)
  rightMostPlacedElement = colorSwatch -- This is now the element that the nameText will be to the left of.
  offsetToTheLeft = -padding           -- Standard padding for the gap between nameText and colorSwatch.

  -- 2. Spell Name & ID (in the middle)
  local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  nameText:SetPoint("LEFT", currentLeftAnchor, "RIGHT", currentLeftOffset, 0)    -- currentLeftAnchor is icon, currentLeftOffset is the offset for the left of nameText
  nameText:SetPoint("RIGHT", rightMostPlacedElement, "LEFT", offsetToTheLeft, 0) -- Anchor right of nameText to left of colorSwatch
  nameText:SetHeight(entryHeight)
  nameText:SetText(string.format("%s (%d)", spellData.spellname or "Unknown", spellID))
  nameText:SetJustifyH("LEFT")
  nameText:SetJustifyV("MIDDLE")

  return spellFrame
end
