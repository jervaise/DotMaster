-- DotMaster gui_tracked_spells_tab.lua
-- Contains the Tracked Spells tab functionality for the GUI

local DM = DotMaster

-- Create Tracked Spells tab content
function DM:CreateTrackedSpellsTab(parent)
  DM:DebugMsg("Creating Tracked Spells Tab") -- Updated debug message

  -- Constants for professional layout
  local PADDING = {
    OUTER = 5,  -- Outside frame padding (base padding value X)
    INNER = 10, -- Inner content padding
    COLUMN = 15 -- Space between columns
  }

  -- Percentage-based column widths - keeping row elements exactly as they are
  local COLUMN_WIDTH_PCT = {
    ON = 0.06,    -- 6% Checkbox
    ID = 0.13,    -- 13% Icon area
    NAME = 0.45,  -- 45% Name area (increased from 42% for more width)
    COLOR = 0.09, -- 9% Color
    ORDER = 0.11, -- 11% Order buttons
    DEL = 0.14    -- 14% Tracking button
  }

  -- Add another 50px to the entire width (total 150px added from original)
  local frameWidth = 700    -- Increased from 650 to 700
  local scrollBarWidth = 20 -- Standard WoW scrollbar width

  -- Create UpdateLayout function with adjusted right spacing
  local function UpdateColumnPositions(width)
    -- Calculate available width for content - keeping proportions the same
    local contentWidth = width - (PADDING.OUTER * 9) - scrollBarWidth
    width = math.min(contentWidth, 600) -- Keep this the same to maintain element sizing

    local positions = {}
    local widths = {}

    -- Calculate inner padding needed on each side for symmetry
    local innerLeftPadding = 10   -- Increased left padding (was 5)
    local innerRightPadding = 10  -- Equal right padding for symmetry

    local xPos = innerLeftPadding -- Start content with symmetrical inner padding

    -- Calculate positions
    positions.ON = xPos
    widths.ON = width * COLUMN_WIDTH_PCT.ON
    xPos = xPos + widths.ON

    positions.ID = xPos + 12
    widths.ID = width * COLUMN_WIDTH_PCT.ID
    xPos = xPos + widths.ID + 12

    positions.NAME = xPos
    widths.NAME = width * COLUMN_WIDTH_PCT.NAME
    xPos = xPos + widths.NAME

    positions.COLOR = xPos
    widths.COLOR = width * COLUMN_WIDTH_PCT.COLOR
    xPos = xPos + widths.COLOR + PADDING.COLUMN

    positions.UP = xPos
    widths.UP = (width * COLUMN_WIDTH_PCT.ORDER) / 2
    xPos = xPos + widths.UP

    positions.DOWN = xPos
    widths.DOWN = (width * COLUMN_WIDTH_PCT.ORDER) / 2
    xPos = xPos + widths.DOWN + PADDING.COLUMN

    positions.DEL = xPos
    widths.DEL = width * COLUMN_WIDTH_PCT.DEL

    -- Return both positions and widths
    return positions, widths
  end

  -- Calculate initial positions
  local COLUMN_POSITIONS, COLUMN_WIDTHS = UpdateColumnPositions(frameWidth)

  -- Set the parent frame size - increase by another 50px width
  if parent.SetSize then
    local currentWidth, currentHeight = parent:GetSize()
    parent:SetSize(currentWidth + 50, currentHeight)
  end

  -- Spells Tab Header - move down slightly within its space
  local spellTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  spellTitle:SetPoint("TOP", 0, -25) -- Changed from -15 to -25 to move title down
  spellTitle:SetText("Configure Spell Tracking")

  -- Instructions - maintain same spacing from title
  local instructions = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  instructions:SetPoint("TOP", spellTitle, "BOTTOM", 0, -5)
  instructions:SetText("Configure your spell tracking settings")
  instructions:SetTextColor(1, 0.82, 0)

  -- Fix the background extending issue once and for all
  -- Make margins exactly the same on both sides
  local backgroundPadding = 15                     -- Equal padding for both left and right sides
  local backgroundPaddingLeft = backgroundPadding  -- Set left padding
  local backgroundPaddingRight = backgroundPadding -- Set right padding (same as left)

  -- Create the background texture first - it should extend fully with specified padding
  local spellListBg = parent:CreateTexture(nil, "BACKGROUND")
  -- Position relative to parent frame edges with adjusted padding
  spellListBg:SetPoint("TOPLEFT", parent, "TOPLEFT", backgroundPaddingLeft, -80)
  spellListBg:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -backgroundPaddingRight, 80)
  spellListBg:SetColorTexture(0, 0, 0, 0.5)

  -- Scrollframe positioned ON TOP of background with adjusted inset
  local scrollFrame = CreateFrame("ScrollFrame", "DotMasterSpellScrollFrame", parent, "UIPanelScrollFrameTemplate")
  -- Position scrollframe with equal padding on both sides
  scrollFrame:SetPoint("TOPLEFT", spellListBg, "TOPLEFT", 10, -10)
  -- Ensure scrollbar fits completely inside the gray background with proper spacing
  scrollFrame:SetPoint("BOTTOMRIGHT", spellListBg, "BOTTOMRIGHT", -2, 5)

  -- Hide scrollbar until needed
  local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
  if scrollBar then
    scrollBar:Hide()
    scrollFrame.ScrollBar = scrollBar

    -- Hook the OnSizeChanged of the scroll child to show/hide scrollbar as needed
    scrollFrame:HookScript("OnScrollRangeChanged", function(self, xrange, yrange)
      if yrange > 0 then
        scrollBar:Show()
      else
        scrollBar:Hide()
      end
    end)
  end

  local scrollChild = CreateFrame("Frame")
  scrollFrame:SetScrollChild(scrollChild)

  -- Set content width to match the scrollframe width
  scrollChild:SetWidth(scrollFrame:GetWidth())
  scrollChild:SetHeight(500) -- Extra height for content

  -- Store references in GUI namespace
  DM.GUI.scrollFrame = scrollFrame
  DM.GUI.scrollChild = scrollChild
  DM.GUI.spellFrames = {}

  -- Save layout constants for spell row creation
  DM.GUI.layout = {
    padding = PADDING,
    columns = COLUMN_POSITIONS,
    widths = COLUMN_WIDTHS
  }

  -- Create header row with professional styling
  local headerFrame = CreateFrame("Frame", nil, scrollChild)
  -- Set width to match the content width with adjusted inner padding
  headerFrame:SetSize(scrollChild:GetWidth() - (PADDING.INNER * 2), 30)
  headerFrame:SetPoint("TOPLEFT", PADDING.INNER, -PADDING.INNER)

  -- Header background
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  headerBg:SetColorTexture(0, 0, 0, 0.8)

  -- Kolon başlıkları
  local headerTexts = {}

  -- Helper function for creating column headers
  local function CreateHeaderText(name, position, width)
    local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerText:SetPoint("LEFT", position, 0)
    headerText:SetWidth(width)
    headerText:SetJustifyH("LEFT")
    headerText:SetText(name)
    headerText:SetTextColor(1, 0.82, 0)
    return headerText
  end

  -- Create column headers with precise positioning
  -- Center the "On" header over the checkbox
  headerTexts.ON = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  headerTexts.ON:SetPoint("CENTER", headerFrame, "LEFT", COLUMN_POSITIONS.ON + (COLUMN_WIDTHS.ON / 2), 0)
  headerTexts.ON:SetText("On")
  headerTexts.ON:SetTextColor(1, 0.82, 0)

  -- Position Spell header where the spell icon starts
  headerTexts.SPELL = CreateHeaderText("Spell", COLUMN_POSITIONS.ID, COLUMN_WIDTHS.ID + COLUMN_WIDTHS.NAME)

  headerTexts.COLOR = CreateHeaderText("Color", COLUMN_POSITIONS.COLOR, COLUMN_WIDTHS.COLOR)

  -- Order header should be centered over the two arrows
  local orderText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local orderX = COLUMN_POSITIONS.UP + (COLUMN_WIDTHS.UP + COLUMN_WIDTHS.DOWN) / 2
  orderText:SetPoint("CENTER", headerFrame, "LEFT", orderX, 0)
  orderText:SetText("Order")
  orderText:SetTextColor(1, 0.82, 0)
  headerTexts.ORDER = orderText

  -- Align Tracking header with the Remove button
  headerTexts.UNTRACK = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  headerTexts.UNTRACK:SetPoint("CENTER", headerFrame, "LEFT", COLUMN_POSITIONS.DEL + 30, 0) -- Center over the Remove button
  headerTexts.UNTRACK:SetText("Tracking")
  headerTexts.UNTRACK:SetTextColor(1, 0.82, 0)

  -- Update header positions when size changes
  local function UpdateHeaderPositions()
    -- Use content width without scrollbar
    local width = scrollChild:GetWidth() - (PADDING.INNER * 2)
    local positions, widths = UpdateColumnPositions(width)

    -- Center the "On" header over the checkbox position
    headerTexts.ON:SetPoint("CENTER", headerFrame, "LEFT", positions.ON + (widths.ON / 2), 0)

    -- Align Spell header with the spell icon
    headerTexts.SPELL:SetPoint("LEFT", positions.ID, 0)
    headerTexts.SPELL:SetWidth(widths.ID + widths.NAME)

    headerTexts.COLOR:SetPoint("LEFT", positions.COLOR, 0)
    headerTexts.COLOR:SetWidth(widths.COLOR)

    -- Center Order header over the two arrows
    local orderX = positions.UP + (widths.UP + widths.DOWN) / 2
    headerTexts.ORDER:SetPoint("CENTER", headerFrame, "LEFT", orderX, 0)

    -- Align Tracking header with the Remove button (center it over the button)
    headerTexts.UNTRACK:SetPoint("CENTER", headerFrame, "LEFT", positions.DEL + 30, 0)

    -- Update frame sizes
    headerFrame:SetWidth(width)

    -- Save and transmit to rows
    DM.GUI.layout.columns = positions
    DM.GUI.layout.widths = widths

    -- Update existing rows
    for _, frame in ipairs(DM.GUI.spellFrames) do
      if frame.UpdatePositions then
        frame.UpdatePositions(positions, widths)
      end
    end
  end

  headerFrame.UpdatePositions = UpdateHeaderPositions

  -- Button container frame - move up for more space above buttons
  local buttonContainer = CreateFrame("Frame", nil, parent)
  buttonContainer:SetSize(320, 40)
  buttonContainer:SetPoint("BOTTOM", 0, 15) -- Changed from 5 to 15 to move buttons up

  -- Find My Dots button with improved styling
  local findDotsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  findDotsButton:SetSize(150, 30)
  findDotsButton:SetPoint("LEFT", 0, 0)
  findDotsButton:SetText("Find My Dots")

  -- Enhance button visual appearance
  findDotsButton:SetNormalFontObject("GameFontNormal")
  findDotsButton:SetHighlightFontObject("GameFontHighlight")

  -- Add tooltip
  findDotsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Find My Dots", 1, 1, 1)
    GameTooltip:AddLine("Cast spells on enemies to automatically detect your dots.", 1, 0.82, 0, true)
    GameTooltip:Show()
  end)

  findDotsButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  findDotsButton:SetScript("OnClick", function()
    -- Check if already in recording mode
    if DM.recordingDots then
      DM:StopFindMyDots()
      return
    end

    -- Start dot recording mode
    DM:StartFindMyDots()
  end)

  -- Add From Database button with improved styling
  local addButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
  addButton:SetSize(150, 30)
  addButton:SetPoint("RIGHT", 0, 0)
  addButton:SetText("Add From Database")

  -- Add tooltip
  addButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Add From Database", 1, 1, 1)
    GameTooltip:AddLine("Add spells from your detected spell database.", 1, 0.82, 0, true)
    GameTooltip:AddLine("Use Find My Dots first to detect your spells.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
  end)

  addButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  -- Enhance button visual appearance
  addButton:SetNormalFontObject("GameFontNormal")
  addButton:SetHighlightFontObject("GameFontHighlight")

  addButton:SetScript("OnClick", function()
    local count = DM:TableCount(DM.spellConfig)

    if count >= DM.MAX_CUSTOM_SPELLS then
      DM:PrintMessage("Maximum spells reached (" .. DM.MAX_CUSTOM_SPELLS .. ").")
      return
    end

    -- Check if we have spells in database
    if not DM.spellDatabase or DM:TableCount(DM.spellDatabase) == 0 then
      -- No spells detected yet, show prompt
      DM:ShowFindMyDotsPrompt()
    else
      -- Show spell selection dialog
      DM:ShowSpellSelectionDialog()
    end
  end)

  -- Make sure background maintains position on resize
  parent:HookScript("OnSizeChanged", function()
    -- Re-anchor background with adjusted padding
    spellListBg:ClearAllPoints()
    spellListBg:SetPoint("TOPLEFT", parent, "TOPLEFT", backgroundPaddingLeft, -80)
    spellListBg:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -backgroundPaddingRight, 80)

    -- Update scrollframe and content
    scrollChild:SetWidth(scrollFrame:GetWidth())
    UpdateHeaderPositions()
  end)

  -- Handle scrollChild resize events
  scrollChild:HookScript("OnSizeChanged", function()
    UpdateHeaderPositions()
  end)

  -- Class-specific tracking
  local classGroups = {}
  local classFrames = {}
  local isClassExpanded = {}

  -- Class color constants (RGB values using WoW class colors)
  local CLASS_COLORS = {
    ["DEATHKNIGHT"] = { 0.77, 0.12, 0.23 },
    ["DEMONHUNTER"] = { 0.64, 0.19, 0.79 },
    ["DRUID"] = { 1.00, 0.49, 0.04 },
    ["HUNTER"] = { 0.67, 0.83, 0.45 },
    ["MAGE"] = { 0.41, 0.80, 0.94 },
    ["MONK"] = { 0.00, 1.00, 0.59 },
    ["PALADIN"] = { 0.96, 0.55, 0.73 },
    ["PRIEST"] = { 1.00, 1.00, 1.00 },
    ["ROGUE"] = { 1.00, 0.96, 0.41 },
    ["SHAMAN"] = { 0.00, 0.44, 0.87 },
    ["WARLOCK"] = { 0.58, 0.51, 0.79 },
    ["WARRIOR"] = { 0.78, 0.61, 0.43 },
    ["OTHER"] = { 0.60, 0.60, 0.60 } -- Default for uncategorized spells
  }

  -- Class icon texture coordinates for the class circle textures
  local CLASS_ICON_TCOORDS = {
    ["WARRIOR"]     = { 0, 0.25, 0, 0.25 },
    ["MAGE"]        = { 0.25, 0.49609375, 0, 0.25 },
    ["ROGUE"]       = { 0.49609375, 0.7421875, 0, 0.25 },
    ["DRUID"]       = { 0.7421875, 0.98828125, 0, 0.25 },
    ["HUNTER"]      = { 0, 0.25, 0.25, 0.5 },
    ["SHAMAN"]      = { 0.25, 0.49609375, 0.25, 0.5 },
    ["PRIEST"]      = { 0.49609375, 0.7421875, 0.25, 0.5 },
    ["WARLOCK"]     = { 0.7421875, 0.98828125, 0.25, 0.5 },
    ["PALADIN"]     = { 0, 0.25, 0.5, 0.75 },
    ["DEATHKNIGHT"] = { 0.25, 0.49609375, 0.5, 0.75 },
    ["MONK"]        = { 0.49609375, 0.7421875, 0.5, 0.75 },
    ["DEMONHUNTER"] = { 0.7421875, 0.98828125, 0.5, 0.75 },
  }

  -- Function to get class color by class name
  local function GetClassColor(className)
    className = className and string.upper(className) or "OTHER"
    return CLASS_COLORS[className] or CLASS_COLORS["OTHER"]
  end

  -- Create a collapsible class header
  local function CreateClassHeader(className, order)
    local color = GetClassColor(className)
    local displayName = className and className:gsub("^%l", string.upper) or "Other"

    local headerFrame = CreateFrame("Button", nil, scrollChild)
    headerFrame:SetSize(scrollChild:GetWidth() - 20, 25)
    headerFrame:SetPoint("TOPLEFT", 10, -(80 + (order * 30)))

    -- Header background
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.8)

    -- Class icon (placeholder - could be replaced with actual class icons)
    local classIcon = headerFrame:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("LEFT", 5, 0)
    classIcon:SetTexture("Interface\\TARGETINGFRAME\\UI-Classes-Circles")
    local coords = CLASS_ICON_TCOORDS[className:upper()]
    if coords then
      classIcon:SetTexCoord(unpack(coords))
    else
      classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Class name text
    local classText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classText:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
    classText:SetText(displayName)
    classText:SetTextColor(color[1], color[2], color[3])

    -- Expand/collapse indicator
    local expandIcon = headerFrame:CreateTexture(nil, "OVERLAY")
    expandIcon:SetSize(16, 16)
    expandIcon:SetPoint("RIGHT", -5, 0)
    expandIcon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")

    -- Set initial state (expanded)
    isClassExpanded[className] = true

    -- Click handler for expand/collapse
    headerFrame:SetScript("OnClick", function()
      isClassExpanded[className] = not isClassExpanded[className]

      -- Update the expand/collapse icon
      if isClassExpanded[className] then
        expandIcon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
      else
        expandIcon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
      end

      -- Show/hide spell rows for this class
      for _, frame in ipairs(classGroups[className] or {}) do
        frame:SetShown(isClassExpanded[className])
      end

      -- Update positions of all frames
      DM:UpdateSpellRowPositions()
    end)

    -- Mouse interaction feedback
    headerFrame:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")

    return headerFrame
  end

  -- Define a global variable to store the sort order of classes
  local spellOrder = {}

  -- Replace the RefreshTrackedSpellList function with our LoadTrackedSpells
  function DM:RefreshTrackedSpellList()
    DM:LoadTrackedSpells()
  end

  -- Modify the LoadTrackedSpells function to use any existing spell row frames
  function DM:LoadTrackedSpells()
    local firstLoad = (DM.GUI.spellFrames == nil)

    -- Initialize spellFrames if needed
    if firstLoad then
      DM.GUI.spellFrames = {}
    else
      -- Hide existing spell frames
      for _, frame in ipairs(DM.GUI.spellFrames) do
        frame:Hide()
      end
    end

    -- Clear class groups
    classGroups = {}
    classFrames = {}
    spellOrder = {}

    -- Organize spells by class
    local spellsByClass = {}

    -- Get all tracked spells from the database
    local spellsFromDB = DM:GetTrackedSpells()
    DM:DebugMsg("Loading tracked spells: " .. (DM:TableCount(spellsFromDB) or 0) .. " spells found")

    -- Sort spells by class and priority
    for id, spellData in pairs(spellsFromDB) do
      local className = spellData.wowclass or "OTHER"
      className = string.upper(className)
      if not spellsByClass[className] then
        spellsByClass[className] = {}
        table.insert(spellOrder, className)
      end
      table.insert(spellsByClass[className], { id = id, data = spellData })
    end

    -- Sort classes by name
    table.sort(spellOrder)

    -- Sort spells within each class by priority
    for className, spells in pairs(spellsByClass) do
      table.sort(spells, function(a, b)
        return (tonumber(a.data.priority) or 0) < (tonumber(b.data.priority) or 0)
      end)
    end

    -- Track total rows for scrollframe sizing
    local totalRows = 0

    -- Create headers and spell rows
    for i, className in ipairs(spellOrder) do
      -- Create class header if it doesn't exist
      if not classFrames[className] then
        classFrames[className] = CreateClassHeader(className, i - 1)
      end

      -- Initialize class group
      classGroups[className] = {}
      totalRows = totalRows + 1 -- Count header as a row

      -- Create spell rows for this class
      for j, spellInfo in ipairs(spellsByClass[className]) do
        -- Reuse existing frame or create new one
        local frameIndex = #DM.GUI.spellFrames + 1
        local frame

        if frameIndex <= #(DM.GUI.spellFrames or {}) then
          -- Reuse existing frame
          frame = DM.GUI.spellFrames[frameIndex]
          DM:UpdateSpellRow(frame, spellInfo.id, spellInfo.data)
          frame:Show()
        else
          -- Create new frame
          frame = DM:CreateSpellRow(spellInfo.id, spellInfo.data)
          table.insert(DM.GUI.spellFrames, frame)
        end

        -- Add to class group
        table.insert(classGroups[className], frame)
        totalRows = totalRows + 1
      end
    end

    -- Hide any unused frames
    for i = totalRows + 1, #(DM.GUI.spellFrames or {}) do
      if DM.GUI.spellFrames[i] then
        DM.GUI.spellFrames[i]:Hide()
      end
    end

    -- Update positions of all frames
    DM:UpdateSpellRowPositions()

    DM:DebugMsg("RefreshTrackedSpellList: displayed spells in " .. #spellOrder .. " class groups")
  end

  -- Update the positions of all spell rows based on class grouping
  function DM:UpdateSpellRowPositions()
    local yOffset = 10 -- Starting Y offset

    -- Process each class group in order
    for i, className in ipairs(spellOrder or {}) do
      local headerFrame = classFrames[className]
      if headerFrame then
        -- Position the header
        headerFrame:ClearAllPoints()
        headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -yOffset)
        yOffset = yOffset + 30 -- Add space after header

        -- Position spell rows if class is expanded
        if isClassExpanded[className] then
          for j, spellFrame in ipairs(classGroups[className] or {}) do
            spellFrame:ClearAllPoints()
            spellFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            spellFrame:Show()
            yOffset = yOffset + spellFrame:GetHeight() + 2 -- Add a small gap
          end
        end
      end
    end

    -- Update scrollChild height
    scrollChild:SetHeight(math.max(yOffset + 20, scrollFrame:GetHeight()))
  end

  -- Initial load of spells
  DM:LoadTrackedSpells()

  -- Update on resize
  scrollFrame:HookScript("OnSizeChanged", function()
    DM:UpdateSpellRowPositions()
  end)
end

-- Helper function to get tracked spells from the database
function DM:GetTrackedSpells()
  local trackedSpells = {}

  -- Get spells marked for tracking from dmspellsdb
  if DM.dmspellsdb then
    for id, data in pairs(DM.dmspellsdb) do
      if data.tracked == 1 then
        trackedSpells[id] = data
      end
    end
  end

  -- If no tracked spells found, return default test data
  if next(trackedSpells) == nil then
    -- Test data for UI development
    trackedSpells = {
      ["589"] = {
        spellid = "589",
        spellname = "Shadow Word: Pain",
        wowclass = "PRIEST",
        wowspec = "Shadow",
        color = { 0, 1, 0 },
        priority = 10,
        tracked = 1,
        enabled = 1,
        spellicon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain"
      },
      ["34914"] = {
        spellid = "34914",
        spellname = "Vampiric Touch",
        wowclass = "PRIEST",
        wowspec = "Shadow",
        color = { 1, 0, 0 },
        priority = 20,
        tracked = 1,
        enabled = 1,
        spellicon = "Interface\\Icons\\Spell_Holy_Stoicism"
      },
      ["980"] = {
        spellid = "980",
        spellname = "Agony",
        wowclass = "WARLOCK",
        wowspec = "Affliction",
        color = { 0.5, 0, 0.5 },
        priority = 15,
        tracked = 1,
        enabled = 1,
        spellicon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras"
      }
    }
  end

  return trackedSpells
end

-- Helper function to update an existing spell row
function DM:UpdateSpellRow(frame, spellID, spellData)
  if not frame or not spellID or not spellData then return end

  -- Update the spell data in the frame
  frame.spellID = spellID

  -- Update visual elements
  local spellName = spellData.spellname or "Unknown Spell"
  local iconPath = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark"
  local isEnabled = spellData.enabled and tonumber(spellData.enabled) == 1
  local color = spellData.color or { 1, 0, 0 } -- Default to red

  -- Update spell icon
  if frame.icon then
    frame.icon:SetTexture(iconPath)
  end

  -- Update spell name text
  if frame.name then
    frame.name:SetText(spellData.spellname .. " (" .. spellID .. ")")
  end

  -- Update enabled checkbox
  if frame.enabledCheckbox then
    frame.enabledCheckbox:SetChecked(isEnabled)
  end

  -- Update color swatch
  if frame.colorSwatch then
    frame.colorSwatch:SetColorTexture(unpack(color))
  end

  return frame
end

-- Utility function to count table entries
function DM:TableCount(tbl)
  if not tbl then return 0 end
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

-- Function to create a new spell row
function DM:CreateSpellRow(spellID, spellData)
  if not spellID or not spellData then return nil end

  -- Get data from the spell
  local spellName = spellData.spellname or "Unknown Spell"
  local iconPath = spellData.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark"
  local isEnabled = spellData.enabled and tonumber(spellData.enabled) == 1
  local color = spellData.color or { 1, 0, 0 } -- Default to red

  -- Create a new frame for this spell row
  local frame = CreateFrame("Button", nil, DM.GUI.scrollChild)
  frame:SetSize(DM.GUI.scrollChild:GetWidth(), 36)
  frame.spellID = spellID

  -- Row background for highlighting
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.15, 0.15, 0.15, 0.4)

  -- Add the on/off checkbox
  local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  checkbox:SetSize(24, 24)
  checkbox:SetPoint("LEFT", DM.GUI.layout.columns.ON, 0)
  checkbox:SetChecked(isEnabled)

  checkbox:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    -- Update the spell's enabled status in the database
    if DM.dmspellsdb and DM.dmspellsdb[spellID] then
      DM.dmspellsdb[spellID].enabled = isChecked and 1 or 0
      DM:DebugMsg("Set spell " .. spellID .. " enabled: " .. (isChecked and "true" or "false"))
    end
  end)

  frame.enabledCheckbox = checkbox

  -- Spell icon
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(32, 32)
  icon:SetPoint("LEFT", DM.GUI.layout.columns.ID, 0)
  icon:SetTexture(iconPath)
  frame.icon = icon

  -- Spell name
  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  name:SetWidth(DM.GUI.layout.widths.NAME - 32) -- Account for the icon
  name:SetJustifyH("LEFT")
  name:SetText(spellName .. " (" .. spellID .. ")")
  frame.name = name

  -- Color swatch
  local colorSwatch = frame:CreateTexture(nil, "ARTWORK")
  colorSwatch:SetSize(24, 24)
  colorSwatch:SetPoint("LEFT", DM.GUI.layout.columns.COLOR, 0)
  colorSwatch:SetColorTexture(unpack(color))
  frame.colorSwatch = colorSwatch

  -- Color picker button
  local colorPickerButton = CreateFrame("Button", nil, frame)
  colorPickerButton:SetSize(24, 24)
  colorPickerButton:SetPoint("CENTER", colorSwatch, "CENTER", 0, 0)
  colorPickerButton:SetScript("OnClick", function()
    -- Store reference to current row for the color picker
    DM.currentColorRow = frame

    -- Setup and show the color picker
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = color
    ColorPickerFrame.func = function()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      colorSwatch:SetColorTexture(r, g, b)

      -- Update color in database
      if DM.dmspellsdb and DM.dmspellsdb[spellID] then
        DM.dmspellsdb[spellID].color = { r, g, b }
        DM:DebugMsg("Set spell " .. spellID .. " color: " .. r .. ", " .. g .. ", " .. b)
      end
    end

    ColorPickerFrame.cancelFunc = function()
      local prev = ColorPickerFrame.previousValues
      colorSwatch:SetColorTexture(prev[1], prev[2], prev[3])
    end

    ColorPickerFrame:SetColorRGB(unpack(color))
    ColorPickerFrame:Show()
  end)

  -- Order Up button
  local upButton = CreateFrame("Button", nil, frame)
  upButton:SetSize(24, 24)
  upButton:SetPoint("LEFT", DM.GUI.layout.columns.UP, 0)
  upButton:SetNormalTexture("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Up")
  upButton:SetPushedTexture("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Down")
  upButton:SetHighlightTexture("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Highlight", "ADD")

  upButton:SetScript("OnClick", function()
    -- Decrease priority value (higher on the list)
    if DM.dmspellsdb and DM.dmspellsdb[spellID] then
      local currentPriority = tonumber(DM.dmspellsdb[spellID].priority) or 999
      DM.dmspellsdb[spellID].priority = currentPriority - 1
      DM:RefreshTrackedSpellList()
    end
  end)

  frame.upButton = upButton

  -- Order Down button
  local downButton = CreateFrame("Button", nil, frame)
  downButton:SetSize(24, 24)
  downButton:SetPoint("LEFT", DM.GUI.layout.columns.DOWN, 0)
  downButton:SetNormalTexture("Interface\\BUTTONS\\UI-ScrollBar-ScrollDownButton-Up")
  downButton:SetPushedTexture("Interface\\BUTTONS\\UI-ScrollBar-ScrollDownButton-Down")
  downButton:SetHighlightTexture("Interface\\BUTTONS\\UI-ScrollBar-ScrollDownButton-Highlight", "ADD")

  downButton:SetScript("OnClick", function()
    -- Increase priority value (lower on the list)
    if DM.dmspellsdb and DM.dmspellsdb[spellID] then
      local currentPriority = tonumber(DM.dmspellsdb[spellID].priority) or 999
      DM.dmspellsdb[spellID].priority = currentPriority + 1
      DM:RefreshTrackedSpellList()
    end
  end)

  frame.downButton = downButton

  -- Remove button (untrack)
  local removeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  removeButton:SetSize(70, 24)
  removeButton:SetPoint("LEFT", DM.GUI.layout.columns.DEL, 0)
  removeButton:SetText("Remove")
  removeButton:SetNormalFontObject("GameFontNormalSmall")

  removeButton:SetScript("OnClick", function()
    -- Set tracked to 0 in database
    if DM.dmspellsdb and DM.dmspellsdb[spellID] then
      DM.dmspellsdb[spellID].tracked = 0
      DM:DebugMsg("Removed spell " .. spellID .. " from tracking")
      DM:RefreshTrackedSpellList()
    end
  end)

  -- Add update function to reposition elements based on layout changes
  frame.UpdatePositions = function(positions, widths)
    checkbox:SetPoint("LEFT", positions.ON, 0)
    icon:SetPoint("LEFT", positions.ID, 0)
    name:SetWidth(widths.NAME - 40)
    colorSwatch:SetPoint("LEFT", positions.COLOR, 0)
    upButton:SetPoint("LEFT", positions.UP, 0)
    downButton:SetPoint("LEFT", positions.DOWN, 0)
    removeButton:SetPoint("LEFT", positions.DEL, 0)
  end

  -- Add highlight on mouseover
  frame:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")

  return frame
end
