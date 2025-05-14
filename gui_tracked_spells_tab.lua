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

  -- Get current player class
  local currentClass = select(2, UnitClass("player"))

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
    -- Only include tracked spells (using tonumber for robustness) AND only for current class
    local tracked = tonumber(data.tracked)
    if tracked == 1 and (data.wowclass == currentClass or data.wowclass == "UNKNOWN") then
      -- Convert string ID to number if needed
      local id = tonumber(idStr)
      count = count + 1

      if not id then
        DM:DatabaseDebug(string.format("WARNING: Invalid spell ID in dmspellsdb: %s", tostring(idStr)))
        -- Skip this entry
      else
        local className = data.wowclass or "UNKNOWN"
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
  wipe(GUI.trackedSpecFrames or {})
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
    specFrame.isExpanded = true -- Default to expanded

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

    -- Try to get the spec icon
    local iconPath = "Interface\\Icons\\INV_Misc_QuestionMark" -- Default icon
    local originalSpecNameFromDB = specName                    -- Preserve the original specName from the database
    local specID = tonumber(specName)                          -- Try direct conversion first

    -- If direct conversion failed (e.g., specName was "Shadow" instead of "258")
    -- try to map it using common spec names for the current class.
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
        -- DM:DebugMsg(string.format("Mapped %s spec '%s' to ID %d for icon lookup.", className, originalSpecNameFromDB, specID))
      end
    end

    -- Hardcoded mapping from SpecID to TGA file path
    local specIconPaths = {
      -- Death Knight
      [250] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dk_blood.tga",                                     -- Blood
      [251] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dk_frost.tga",                                     -- Frost
      [252] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dk_unholy.tga",                                    -- Unholy
      -- Demon Hunter
      [577] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dh_havoc.tga",                                     -- Havoc
      [581] = "Interface\\AddOns\\DotMaster\\Media\\spec\\dh_vengeance.tga",                                 -- Vengeance
      -- Druid
      [102] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\balance__2025_05_14_06_35_06_UTC_.tga",     -- Balance
      [103] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\feral__2025_05_14_06_35_06_UTC_.tga",       -- Feral
      [104] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\guardian__2025_05_14_06_35_06_UTC_.tga",    -- Guardian
      [105] = "Interface\\AddOns\\DotMaster\\Media\\spec\\druid\\restoration__2025_05_14_06_35_06_UTC_.tga", -- Restoration
      -- Evoker
      [1467] = "Interface\\AddOns\\DotMaster\\Media\\spec\\evoker_devestation.tga",                          -- Devastation
      [1468] = "Interface\\AddOns\\DotMaster\\Media\\spec\\evoker_preservation.tga",                         -- Preservation
      [1473] = "Interface\\AddOns\\DotMaster\\Media\\spec\\evoker_augmentation.tga",                         -- Augmentation
      -- Hunter
      [253] = "Interface\\AddOns\\DotMaster\\Media\\spec\\hunter_bm.tga",                                    -- Beast Mastery
      [254] = "Interface\\AddOns\\DotMaster\\Media\\spec\\hunter_mm.tga",                                    -- Marksmanship
      [255] = "Interface\\AddOns\\DotMaster\\Media\\spec\\hunter_survival.tga",                              -- Survival
      -- Mage
      [62] = "Interface\\AddOns\\DotMaster\\Media\\spec\\mage_arcane.tga",                                   -- Arcane
      [63] = "Interface\\AddOns\\DotMaster\\Media\\spec\\mage_fire.tga",                                     -- Fire
      [64] = "Interface\\AddOns\\DotMaster\\Media\\spec\\mage_frost.tga",                                    -- Frost
      -- Monk
      [268] = "Interface\\AddOns\\DotMaster\\Media\\spec\\monk_brewmaster.tga",                              -- Brewmaster
      [269] = "Interface\\AddOns\\DotMaster\\Media\\spec\\monk_ww.tga",                                      -- Windwalker
      [270] = "Interface\\AddOns\\DotMaster\\Media\\spec\\monk_mistweaver.tga",                              -- Mistweaver
      -- Paladin
      [65] = "Interface\\AddOns\\DotMaster\\Media\\spec\\paladin_holy.tga",                                  -- Holy
      [66] = "Interface\\AddOns\\DotMaster\\Media\\spec\\paladin_protection.tga",                            -- Protection
      [70] = "Interface\\AddOns\\DotMaster\\Media\\spec\\paladin_ret.tga",                                   -- Retribution
      -- Priest
      [256] = "Interface\\AddOns\\DotMaster\\Media\\spec\\priest_disc.tga",                                  -- Discipline
      [257] = "Interface\\AddOns\\DotMaster\\Media\\spec\\priest_holy.tga",                                  -- Holy
      [258] = "Interface\\AddOns\\DotMaster\\Media\\spec\\priest_shadow.tga",                                -- Shadow
      -- Rogue
      [259] = "Interface\\AddOns\\DotMaster\\Media\\spec\\rogue_assa.tga",                                   -- Assassination
      [260] = "Interface\\AddOns\\DotMaster\\Media\\spec\\rogue_outlaw.tga",                                 -- Outlaw
      [261] = "Interface\\AddOns\\DotMaster\\Media\\spec\\rogue_sub.tga",                                    -- Subtlety
      -- Shaman
      [262] = "Interface\\AddOns\\DotMaster\\Media\\spec\\shaman_elem.tga",                                  -- Elemental
      [263] = "Interface\\AddOns\\DotMaster\\Media\\spec\\shaman_enhancement.tga",                           -- Enhancement
      [264] = "Interface\\AddOns\\DotMaster\\Media\\spec\\shaman_resto.tga",                                 -- Restoration
      -- Warlock
      [265] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warlock_affli.tga",                                -- Affliction
      [266] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warlock_demono.tga",                               -- Demonology
      [267] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warlock_destru.tga",                               -- Destruction
      -- Warrior
      [71] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warrior_arms.tga",                                  -- Arms
      [72] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warrior_fury.tga",                                  -- Fury
      [73] = "Interface\\AddOns\\DotMaster\\Media\\spec\\warrior_prot.tga",                                  -- Protection
    }

    if specID and specIconPaths[specID] then
      iconPath = specIconPaths[specID]
    elseif originalSpecNameFromDB == "General" then   -- Ensure to check originalSpecNameFromDB for "General"
      iconPath = "Interface\\Icons\\INV_Misc_Book_09" -- Book icon for general stuff
    end

    icon:SetTexture(iconPath)
    -- Reset any texture coordinates, TGA files usually don't need cropping like default spell icons
    icon:SetTexCoord(0, 1, 0, 1)

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
    expandBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
    expandBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
    expandBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")

    -- Set the toggle functionality for both the expand button and the header itself
    local function ToggleHeaderExpansion()
      specFrame.isExpanded = not specFrame.isExpanded

      -- Update button texture
      if specFrame.isExpanded then
        expandBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        expandBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")

        -- Show all spell rows
        for _, spellFrame in ipairs(specFrame.spellFrames) do
          spellFrame:Show()
        end
      else
        expandBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        expandBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")

        -- Hide all spell rows
        for _, spellFrame in ipairs(specFrame.spellFrames) do
          spellFrame:Hide()
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
        priority = tonumber(spellData.priority) or 999
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
    for _, entry in ipairs(spellsInSpecByPriority) do
      -- Check if priority needs reassignment
      if not DM.dmspellsdb[entry.id] or DM.dmspellsdb[entry.id].priority ~= uniquePriorityCounter then
        -- Ensure spell entry exists before modification (safety check)
        if DM.dmspellsdb[entry.id] then
          DM.dmspellsdb[entry.id].priority = uniquePriorityCounter
          DM:DatabaseDebug(string.format("Reassigned priority %d to spell %d for class %s spec %s",
            uniquePriorityCounter, entry.id, className, specName))
          prioritiesChanged = true
        else
          DM:DatabaseDebug(string.format("WARNING: Tried to reassign priority for non-existent spell %d in dmspellsdb",
            entry.id))
        end
      end
      uniquePriorityCounter = uniquePriorityCounter + 1
    end

    if prioritiesChanged then DM:SaveDMSpellsDB() end

    -- Create spell row frames
    if specFrame.isExpanded then
      local visibleSpellCount = 0

      for _, entry in ipairs(spellsInSpecByPriority) do
        local id = entry.id
        local spellData = entry.data

        -- Add spell rows
        local spellRow = GUI:CreateTrackedSpellRow(scrollChild, id, spellData, effectiveWidth)
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
function GUI:CreateTrackedSpellRow(parent, spellID, spellData, width)
  local entryHeight = 40
  local padding = 5
  local checkboxWidth = 20
  local iconSize = 25
  local colorSwatchSize = 24
  local arrowSize = 20
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

  -- 1. Enabled Checkbox
  local enabledCheckbox = CreateFrame("CheckButton", nil, spellFrame, "UICheckButtonTemplate")
  enabledCheckbox:SetSize(checkboxWidth, checkboxWidth)
  enabledCheckbox:SetPoint("LEFT", currentLeftAnchor, "LEFT", currentLeftOffset, 0)
  if spellData.enabled == nil then DM.dmspellsdb[spellID].enabled = 1 end
  enabledCheckbox:SetChecked(DM.dmspellsdb[spellID].enabled == 1)
  enabledCheckbox:SetScript("OnClick", function(self)
    DM.dmspellsdb[spellID].enabled = self:GetChecked() and 1 or 0
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
  currentLeftOffset = padding + 3

  -- Right-side elements
  local currentRightAnchor = spellFrame
  local currentRightOffset = -padding

  -- 5. Untrack Button
  local untrackButton = CreateFrame("Button", nil, spellFrame, "UIPanelButtonTemplate")
  untrackButton:SetSize(untrackWidth, 25)
  untrackButton:SetPoint("RIGHT", currentRightAnchor, "RIGHT", currentRightOffset, 0)
  untrackButton:SetText("Untrack")
  untrackButton:SetScript("OnClick", function()
    DM.dmspellsdb[spellID].tracked = 0
    DM:SaveDMSpellsDB()
    GUI:RefreshTrackedSpellTabList()

    -- Update Plater after untracking
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      C_Timer.After(0.1, function()
        DM.ClassSpec:PushConfigToPlater()
      end)
    end
  end)
  currentRightAnchor = untrackButton
  currentRightOffset = -10

  -- 4. Color Swatch
  -- Get the initial color or use default
  local r, g, b = 1, 0, 0 -- Default red color
  if spellData.color and type(spellData.color) == "table" then
    if #spellData.color >= 3 then
      r = tonumber(spellData.color[1]) or 1
      g = tonumber(spellData.color[2]) or 0
      b = tonumber(spellData.color[3]) or 0
    end
  end

  -- Create the color swatch
  local colorSwatch = CreateFrame("Button", nil, spellFrame)
  colorSwatch:SetSize(colorSwatchSize, colorSwatchSize)
  colorSwatch:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)

  -- Create border for better visibility
  local border = colorSwatch:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(0.1, 0.1, 0.1, 1)

  -- Create a texture for the color with slight inner border
  local texture = colorSwatch:CreateTexture(nil, "ARTWORK")
  texture:SetPoint("TOPLEFT", 2, -2)
  texture:SetPoint("BOTTOMRIGHT", -2, 2)
  texture:SetColorTexture(r, g, b, 1)

  -- Color picker functionality
  colorSwatch:SetScript("OnEnter", function(self)
    border:SetColorTexture(0.3, 0.3, 0.3, 1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Color Values")
    GameTooltip:AddLine(
      "R: " .. math.floor(r * 255) .. " G: " .. math.floor(g * 255) .. " B: " .. math.floor(b * 255), 1, 1, 1)
    GameTooltip:AddLine("Click to change color", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  colorSwatch:SetScript("OnLeave", function()
    border:SetColorTexture(0.1, 0.1, 0.1, 1)
    GameTooltip:Hide()
  end)

  -- Color picker click handler
  colorSwatch:SetScript("OnClick", function()
    -- Use standard WoW color picker
    local function colorFunc()
      -- Get color values using the appropriate API for the client version
      local newR, newG, newB
      if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
        newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
      else
        -- Fallback for other API versions
        newR, newG, newB = ColorPickerFrame:GetColorRGB()
      end

      -- Update texture
      texture:SetColorTexture(newR, newG, newB, 1)
      -- Update values
      r, g, b = newR, newG, newB
      -- Save to database
      if DM.dmspellsdb[spellID] then
        DM.dmspellsdb[spellID].color = { newR, newG, newB }
        DM:SaveDMSpellsDB()

        -- Update Plater with the new color
        if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
          C_Timer.After(0.1, function()
            DM.ClassSpec:PushConfigToPlater()
          end)
        end
      end
    end

    local function cancelFunc()
      local prevR, prevG, prevB = unpack(ColorPickerFrame.previousValues)
      texture:SetColorTexture(prevR, prevG, prevB, 1)
    end

    -- Use the modern or legacy API as appropriate
    if ColorPickerFrame.SetupColorPickerAndShow then
      local info = {}
      info.swatchFunc = colorFunc
      info.cancelFunc = cancelFunc
      info.r = r
      info.g = g
      info.b = b
      info.opacity = 1
      info.hasOpacity = false
      ColorPickerFrame:SetupColorPickerAndShow(info)
    else
      -- Legacy method
      ColorPickerFrame.func = colorFunc
      ColorPickerFrame.cancelFunc = cancelFunc
      ColorPickerFrame.opacityFunc = nil
      ColorPickerFrame.hasOpacity = false
      ColorPickerFrame.previousValues = { r, g, b }

      -- Set color via Content if available
      if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
      end

      ColorPickerFrame:Show()
    end
  end)
  currentRightAnchor = colorSwatch
  currentRightOffset = -padding

  -- 3. Spell Name & ID (in the middle)
  local nameText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  nameText:SetPoint("LEFT", currentLeftAnchor, "RIGHT", currentLeftOffset, 0)
  nameText:SetPoint("RIGHT", currentRightAnchor, "LEFT", currentRightOffset, 0)
  nameText:SetHeight(entryHeight)
  nameText:SetText(string.format("%s (%d)", spellData.spellname or "Unknown", spellID))
  nameText:SetJustifyH("LEFT")
  nameText:SetJustifyV("MIDDLE")

  return spellFrame
end
