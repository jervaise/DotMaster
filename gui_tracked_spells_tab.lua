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
  -- Position scrollframe with equal padding on both sides - extend all the way to the right
  scrollFrame:SetPoint("TOPLEFT", spellListBg, "TOPLEFT", 10, -10)
  -- Use full width since we're hiding the scrollbar
  scrollFrame:SetPoint("BOTTOMRIGHT", spellListBg, "BOTTOMRIGHT", -10, 5)

  -- Hide scrollbar and enable mouse wheel scrolling
  local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
  if scrollBar then
    -- Always hide the scrollbar
    scrollBar:Hide()
    scrollFrame.ScrollBar = scrollBar

    -- Set up mouse wheel scrolling for the parent frame
    parent:EnableMouseWheel(true)
    parent:SetScript("OnMouseWheel", function(self, delta)
      if delta > 0 then
        -- Scroll up (one row per wheel click)
        local currentValue = scrollBar:GetValue()
        scrollBar:SetValue(math.max(currentValue - 38, 0))
      else
        -- Scroll down (one row per wheel click)
        local currentValue = scrollBar:GetValue()
        local maxValue = scrollBar:GetRange()
        scrollBar:SetValue(math.min(currentValue + 38, maxValue))
      end
    end)

    -- Set up mouse wheel scrolling for the scroll frame itself
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
      if delta > 0 then
        -- Scroll up (one row per wheel click)
        local currentValue = scrollBar:GetValue()
        scrollBar:SetValue(math.max(currentValue - 38, 0))
      else
        -- Scroll down (one row per wheel click)
        local currentValue = scrollBar:GetValue()
        local maxValue = scrollBar:GetRange()
        scrollBar:SetValue(math.min(currentValue + 38, maxValue))
      end
    end)
  end

  -- Modify the OnScrollRangeChanged to not show scrollbar anymore
  scrollFrame:HookScript("OnScrollRangeChanged", function(self, xrange, yrange)
    -- Even if there's scroll range, we keep the scrollbar hidden
    if scrollBar then
      scrollBar:Hide()
    end
  end)

  local scrollChild = CreateFrame("Frame")
  scrollFrame:SetScrollChild(scrollChild)

  -- Enable mouse wheel on scroll child as well
  scrollChild:EnableMouseWheel(true)
  scrollChild:SetScript("OnMouseWheel", function(self, delta)
    if scrollBar then
      if delta > 0 then
        -- Scroll up (one row per wheel click)
        local currentValue = scrollBar:GetValue()
        scrollBar:SetValue(math.max(currentValue - 38, 0))
      else
        -- Scroll down (one row per wheel click)
        local currentValue = scrollBar:GetValue()
        local maxValue = scrollBar:GetRange()
        scrollBar:SetValue(math.min(currentValue + 38, maxValue))
      end
    end
  end)

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
  headerFrame:SetSize(scrollChild:GetWidth(), 30)
  headerFrame:SetPoint("TOPLEFT", 0, -PADDING.INNER)

  -- Header background
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  -- Replace with sleeker, more transparent dark background
  headerBg:SetColorTexture(0.1, 0.1, 0.12, 0.9)

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

  -- Align Tracking header with the Remove button - centered
  headerTexts.UNTRACK = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  headerTexts.UNTRACK:SetPoint("CENTER", headerFrame, "LEFT", COLUMN_POSITIONS.DEL + (COLUMN_WIDTHS.DEL / 2) + 3, 0)
  headerTexts.UNTRACK:SetWidth(COLUMN_WIDTHS.DEL) -- Set exact width
  headerTexts.UNTRACK:SetJustifyH("CENTER")       -- Center the text over the Remove buttons
  headerTexts.UNTRACK:SetText("Tracking")
  headerTexts.UNTRACK:SetTextColor(1, 0.82, 0)

  -- Update header positions when size changes
  local function UpdateHeaderPositions()
    -- Use content width without scrollbar
    local width = scrollChild:GetWidth()
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

    -- Align Tracking header with the Remove button - centered
    headerTexts.UNTRACK:SetPoint("CENTER", headerFrame, "LEFT", positions.DEL + (widths.DEL / 2) + 3, 0)
    headerTexts.UNTRACK:SetWidth(widths.DEL)
    headerTexts.UNTRACK:SetJustifyH("CENTER") -- Ensure justification is maintained

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
end

-- Create a header row for a class
function DM:CreateClassHeaderRow(className, yOffset)
  -- Ensure we have a valid class name
  if not className then className = "UNKNOWN" end

  DM:DebugMsg("Creating class header for class: " .. tostring(className) .. " at offset " .. tostring(yOffset))

  -- Check if this is the current player's class
  local playerClass = select(1, DM:GetPlayerClassAndSpec()) or "UNKNOWN"
  local isCurrentClass = (className == playerClass)

  -- Get class color or default to gray if not found
  local classColor = DM.classColors[className] or DM.classColors["UNKNOWN"]

  -- Create the header frame
  local headerFrame = CreateFrame("Frame", nil, DM.GUI.scrollChild)
  -- Set exact width to match the background/container
  local parentWidth = DM.GUI.scrollChild:GetWidth()
  headerFrame:SetSize(parentWidth, 38) -- Match the height of spell rows (38px)
  -- Consistent spacing - no extra padding
  headerFrame:SetPoint("TOPLEFT", 0, -yOffset)

  -- Header background with subtle class color tint
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  -- Dark background with a subtle class color tint (10% class color)
  headerBg:SetColorTexture(
    0.1 + (classColor.r * 0.1),
    0.1 + (classColor.g * 0.1),
    0.12 + (classColor.b * 0.1),
    0.9
  )

  -- Add bottom border
  local headerBorder = headerFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
  headerBorder:SetPoint("BOTTOMLEFT", 0, 0)
  headerBorder:SetPoint("BOTTOMRIGHT", 0, 0)
  headerBorder:SetColorTexture(0.2, 0.2, 0.22, 0.9)
  headerBorder:SetHeight(1)

  -- Add highlight effect on hover (just like in the database tab)
  local highlight = headerFrame:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
  highlight:SetBlendMode("ADD")

  -- Make the header clickable to trigger the collapse/expand
  headerFrame:EnableMouse(true)

  -- Get localized class name
  local displayName = className

  -- Map of class names to class IDs
  local classNameToID = {
    ["WARRIOR"] = 1,
    ["PALADIN"] = 2,
    ["HUNTER"] = 3,
    ["ROGUE"] = 4,
    ["PRIEST"] = 5,
    ["DEATHKNIGHT"] = 6,
    ["SHAMAN"] = 7,
    ["MAGE"] = 8,
    ["WARLOCK"] = 9,
    ["MONK"] = 10,
    ["DRUID"] = 11,
    ["DEMONHUNTER"] = 12,
    ["EVOKER"] = 13
  }

  -- Get class ID from name and use GetClassInfo if possible
  local classID = classNameToID[className]

  if classID and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
    DM:DebugMsg("Attempting to get class info for ID: " .. tostring(classID))
    local classInfo = C_CreatureInfo.GetClassInfo(classID)
    if classInfo and classInfo.className then
      displayName = classInfo.className
      DM:DebugMsg("Got localized class name: " .. displayName)
    else
      DM:DebugMsg("Failed to get class info for ID: " .. tostring(classID))
    end
  else
    -- Fallback formatting if GetClassInfo isn't available or class not recognized
    if className ~= "UNKNOWN" then
      displayName = className:sub(1, 1) .. className:sub(2):lower()
      DM:DebugMsg("Using fallback class name formatting: " .. displayName)
    end
  end

  -- Set the initial collapsed state - player class is never collapsed
  if not DM.GUI.classCollapseState then DM.GUI.classCollapseState = {} end

  -- Determine collapsed state - always showing player class
  if isCurrentClass then
    DM.GUI.classCollapseState[className] = false
  elseif DM.GUI.classCollapseState[className] == nil then
    DM.GUI.classCollapseState[className] = true -- Default collapsed for non-player classes
  end

  local collapsed = DM.GUI.classCollapseState[className]
  DM:DebugMsg("Initial collapse state for " .. className .. ": " .. (collapsed and "collapsed" or "expanded"))

  -- Toggle button for collapse/expand - align with checkboxes
  local toggleButton = CreateFrame("Button", nil, headerFrame)
  toggleButton:SetSize(16, 16)
  -- Center the button in the same position as the checkbox column
  local COLUMN_POSITIONS = DM.GUI.layout.columns
  local COLUMN_WIDTHS = DM.GUI.layout.widths
  toggleButton:SetPoint("CENTER", headerFrame, "LEFT", COLUMN_POSITIONS.ON + (COLUMN_WIDTHS.ON / 2), 0)

  -- Set appropriate texture
  local toggleTexture = toggleButton:CreateTexture(nil, "ARTWORK")
  toggleTexture:SetAllPoints()
  toggleTexture:SetTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or
    "Interface\\Buttons\\UI-MinusButton-Up")

  -- For non-current classes, desaturate the button
  if not isCurrentClass then
    toggleTexture:SetDesaturated(true)
    toggleButton:SetEnabled(false)
  end

  toggleButton.texture = toggleTexture

  -- Class name text - align with spell icon position
  local nameText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  nameText:SetPoint("LEFT", COLUMN_POSITIONS.ID, 0) -- Align with the spell icon position
  nameText:SetText(displayName)

  -- Always use the class color for text, but adjust brightness
  if isCurrentClass then
    nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
  else
    nameText:SetTextColor(classColor.r * 0.7, classColor.g * 0.7, classColor.b * 0.7)
  end

  -- Spell count text - centered exactly over the Remove button
  local countText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  countText:SetPoint("CENTER", headerFrame, "LEFT", COLUMN_POSITIONS.DEL + (COLUMN_WIDTHS.DEL / 2) + 3, 0)
  countText:SetWidth(COLUMN_WIDTHS.DEL)
  countText:SetJustifyH("CENTER")    -- Center the text over the Remove button
  countText:SetText("")
  countText:SetTextColor(1, 0.82, 0) -- Match the gold color of column headers
  headerFrame.countText = countText

  -- Toggle function to be used by both the button and the header click
  local function ToggleCollapseState()
    if isCurrentClass then
      -- Get current collapse state
      local currentState = DM.GUI.classCollapseState[className]
      DM:DebugMsg("Toggle for class " .. className .. " - Current state: " ..
        (currentState and "collapsed" or "expanded"))

      -- Toggle the state - true means collapsed
      DM.GUI.classCollapseState[className] = not currentState

      -- Update button texture immediately
      toggleTexture:SetTexture(DM.GUI.classCollapseState[className] and
        "Interface\\Buttons\\UI-PlusButton-Up" or
        "Interface\\Buttons\\UI-MinusButton-Up")

      -- Save the settings immediately
      DM:SaveSettings()

      -- Call simplified refresh with just the toggle state (no full rebuild)
      DM.GUI:ToggleClassSpells(className, DM.GUI.classCollapseState[className])
    end
  end

  -- Set click handlers for both the button and the header
  toggleButton:SetScript("OnClick", ToggleCollapseState)

  -- Make the entire header clickable to toggle collapse state
  -- Check if SetScript is supported
  if headerFrame.SetScript then
    -- Create a click handler for the header
    headerFrame:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" then
        ToggleCollapseState()
      end
    end)
  end

  -- Highlight on hover for current class only
  if isCurrentClass then
    toggleButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  end

  -- Store references
  headerFrame.toggleButton = toggleButton
  headerFrame.className = className
  headerFrame.isCurrentClass = isCurrentClass

  -- Return the header and the new offset - use exact consistent spacing (38px) to match spell rows
  return headerFrame, yOffset + 38
end

-- Create a header row for a spec
function DM:CreateSpecHeaderRow(specName, className, yOffset, indent)
  -- Ensure we have valid names
  if not specName then specName = "General" end
  if not className then className = "UNKNOWN" end

  DM:DebugMsg("Creating spec header for spec: " ..
    tostring(specName) .. " in class: " .. tostring(className) .. " at offset " .. tostring(yOffset))

  -- Get class color or default to gray if not found
  local classColor = DM.classColors[className] or DM.classColors["UNKNOWN"]

  -- Create the header frame
  local headerFrame = CreateFrame("Frame", nil, DM.GUI.scrollChild)
  -- Make the header slightly smaller than class headers
  headerFrame:SetSize(DM.GUI.scrollChild:GetWidth() - (DM.GUI.layout.padding.INNER) - indent, 25)
  headerFrame:SetPoint("TOPLEFT", DM.GUI.scrollChild, "TOPLEFT", indent, -yOffset)

  -- Header background with lighter class color
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  -- Use class color with 15% opacity (lighter than class header)
  headerBg:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.15)

  -- Add bottom border
  local headerBorder = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBorder:SetPoint("BOTTOMLEFT", 0, 0)
  headerBorder:SetPoint("BOTTOMRIGHT", 0, 0)
  headerBorder:SetColorTexture(classColor.r * 0.5, classColor.g * 0.5, classColor.b * 0.5, 0.5)
  headerBorder:SetHeight(1)

  -- Format spec name nicely
  local displayName = specName
  if specName == "General" then
    displayName = "General Spells"
  end

  DM:DebugMsg("Using display name for spec: " .. displayName)

  -- Spec name text
  local nameText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameText:SetPoint("LEFT", 10, 0) -- Indented from left
  nameText:SetText(displayName)
  -- Slightly darker than the bg but still clearly colored
  nameText:SetTextColor(classColor.r * 0.9, classColor.g * 0.9, classColor.b * 0.9)

  -- Spell count text (will be set later)
  local countText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  countText:SetPoint("RIGHT", -10, 0) -- Indented from right
  countText:SetText("")
  headerFrame.countText = countText

  -- Store references
  headerFrame.specName = specName
  headerFrame.className = className

  -- Return the header and the new offset
  return headerFrame, yOffset + 30
end

-- New function to just toggle the visibility of spell rows for a class
-- This avoids the expensive full refresh process
function DM.GUI:ToggleClassSpells(className, isCollapsed)
  DM:DebugMsg("ToggleClassSpells for " .. className .. ": " .. (isCollapsed and "Hiding" or "Showing") .. " spells")

  -- Find all spell rows for this class and toggle visibility
  for _, frame in ipairs(DM.GUI.spellFrames) do
    if frame.class == className then
      if isCollapsed then
        frame:Hide()
      else
        frame:Show()
      end
    end
  end
end

-- Function to refresh the tracked spells list with class/spec grouping
function DM.GUI:RefreshTrackedSpellList()
  -- Ensure the necessary GUI elements exist
  if not DM.GUI.scrollChild or not DM.GUI.scrollFrame then
    DM:DatabaseDebug("Required GUI elements (scrollChild or scrollFrame) not found in RefreshTrackedSpellList")
    return
  end

  DM:DebugMsg("RefreshTrackedSpellList started")

  -- Clear existing frames
  if not DM.GUI.spellFrames then DM.GUI.spellFrames = {} end
  for _, frame in ipairs(DM.GUI.spellFrames) do
    frame:Hide()
  end
  DM.GUI.spellFrames = {}

  -- Also clear class header frames if they exist
  if DM.GUI.classHeaderFrames then
    for _, frame in ipairs(DM.GUI.classHeaderFrames) do
      frame:Hide()
    end
  end
  DM.GUI.classHeaderFrames = {}

  local yOffset = 40 -- Start after header
  local index = 0

  -- Ensure DM.dmspellsdb exists and has data
  if not DM.dmspellsdb or not next(DM.dmspellsdb) then
    DM:DatabaseDebug("dmspellsdb is empty or nil, nothing to display in Tracked Spells.")
    DM.GUI.scrollChild:SetHeight(DM.GUI.scrollFrame:GetHeight()) -- Set height to default if empty
    return
  end

  -- Initialize collapse state table if needed
  if not DM.GUI.classCollapseState then
    DM:DebugMsg("Class collapse state table was nil - initializing empty table")
    DM.GUI.classCollapseState = {}
  end

  -- Group spells by class from dmspellsdb
  local spellsByClass = {}
  local playerClass, playerSpec = DM:GetPlayerClassAndSpec()
  playerClass = playerClass or "UNKNOWN"
  playerSpec = playerSpec or "General"

  DM:DebugMsg("Player class: " .. playerClass .. ", spec: " .. playerSpec)

  -- Always create entry for player's class to ensure it appears first
  spellsByClass[playerClass] = {}

  local trackedCount = 0

  -- Iterate through dmspellsdb and filter for tracked spells
  for spellIDStr, config in pairs(DM.dmspellsdb) do
    -- IMPORTANT: Filter for tracked spells
    if config.tracked and tonumber(config.tracked) == 1 then
      trackedCount = trackedCount + 1
      local class = config.wowclass or "Unknown"

      DM:DebugMsg("Found tracked spell: " ..
        tostring(spellIDStr) .. " (" .. (config.spellname or "Unknown") .. ") - Class: " .. class)

      -- Initialize tables if needed
      spellsByClass[class] = spellsByClass[class] or {}

      -- Add spell to appropriate group
      table.insert(spellsByClass[class], {
        id = spellIDStr, -- Keep ID as string from dmspellsdb
        priority = config.priority or 999,
        config = config  -- Pass the full config from dmspellsdb
      })
    end
  end

  DM:DebugMsg("Found " .. trackedCount .. " total tracked spells")

  -- Sort all spell groups by priority
  for class, spells in pairs(spellsByClass) do
    table.sort(spells, function(a, b) return (a.priority or 999) < (b.priority or 999) end)
  end

  -- Create a sorted list of classes
  local sortedClasses = {}
  for class, _ in pairs(spellsByClass) do
    table.insert(sortedClasses, class)
  end

  DM:DebugMsg("Found " .. #sortedClasses .. " classes with tracked spells")

  -- Always put player class first, then sort others alphabetically
  table.sort(sortedClasses, function(a, b)
    if a == playerClass then return true end
    if b == playerClass then return false end
    return a < b
  end)

  -- Current player class should always be expanded
  DM.GUI.classCollapseState[playerClass] = false

  -- Clear the scroll child before adding new content
  DM.GUI.scrollChild:Hide()

  -- Use local reference to PADDING to avoid nil reference error
  local PADDING = DM.GUI.layout.padding

  -- Function to create and add rows for a given list of spells
  local function addSpellRows(spellList, class, isCurrentClass)
    local totalSpells = #spellList

    DM:DebugMsg("Adding " .. totalSpells .. " spell rows for class " .. class)

    for i, spellData in ipairs(spellList) do
      index = index + 1
      -- Call the row creation function
      DM:DebugMsg("Creating row " .. i .. " for spell ID " .. tostring(spellData.id))

      local row = DM:CreateSpellConfigRow(spellData.id, index, yOffset)
      if row then
        row.spellID = spellData.id            -- Store spellID (string) in the frame
        row.class = class                     -- Store class name for filtering
        table.insert(DM.GUI.spellFrames, row) -- Keep track of the created frame
        yOffset = yOffset + 38                -- Consistent spacing exactly matching the row height

        -- If this is not the current class, desaturate and disable all buttons
        if not isCurrentClass then
          -- Desaturate row elements
          for _, texture in pairs(row.textures or {}) do
            if texture.SetDesaturated then
              texture:SetDesaturated(true)
            end
          end

          -- Disable color swatch
          if row.colorSwatch and row.colorSwatch.SetEnabled then
            row.colorSwatch:SetEnabled(false)
          end

          -- Disable checkbox
          if row.enableCheckbox and row.enableCheckbox.SetEnabled then
            row.enableCheckbox:SetEnabled(false)
          end

          -- Disable buttons
          if row.removeButton and row.removeButton.SetEnabled then
            row.removeButton:SetEnabled(false)
            row.removeButton:GetNormalTexture():SetDesaturated(true)
            row.removeButton:GetPushedTexture():SetDesaturated(true)
          end

          -- Disable up/down buttons
          if row.upButton then
            row.upButton:Disable()
            row.upButton:GetNormalTexture():SetDesaturated(true)
            row.upButton:GetPushedTexture():SetDesaturated(true)
          end

          if row.downButton then
            row.downButton:Disable()
            row.downButton:GetNormalTexture():SetDesaturated(true)
            row.downButton:GetPushedTexture():SetDesaturated(true)
          end

          -- Add desaturated overlay
          if not row.desaturatedOverlay then
            local overlay = row:CreateTexture(nil, "OVERLAY")
            overlay:SetAllPoints()
            overlay:SetColorTexture(0.3, 0.3, 0.3, 0.3)
            overlay:SetBlendMode("MOD")
            row.desaturatedOverlay = overlay
          end
        else
          -- Disable up button for first spell in the group
          if i == 1 and row.upButton then
            row.upButton:Disable()
            row.upButton:GetNormalTexture():SetDesaturated(true)
            row.upButton:GetPushedTexture():SetDesaturated(true)
          end

          -- Disable down button for last spell in the group
          if i == totalSpells and row.downButton then
            row.downButton:Disable()
            row.downButton:GetNormalTexture():SetDesaturated(true)
            row.downButton:GetPushedTexture():SetDesaturated(true)
          end
        end

        -- Initially hide if collapsed
        if DM.GUI.classCollapseState[class] then
          row:Hide()
        end
      else
        DM:DebugMsg("Error: Failed to create row for spell " .. spellData.id)
      end
    end

    return totalSpells
  end

  -- Process each class and create headers/rows
  for _, class in ipairs(sortedClasses) do
    -- Count total spells for this class
    local classSpellCount = #spellsByClass[class]
    local isCurrentClass = (class == playerClass)

    DM:DebugMsg("Processing class " .. class .. " with " .. classSpellCount .. " spells")

    -- Skip empty classes
    if classSpellCount > 0 then
      -- Get collapse state for this class
      local isCollapsed = DM.GUI.classCollapseState[class]

      -- If nil, default to expanded for player class, collapsed for others
      if isCollapsed == nil then
        isCollapsed = not isCurrentClass
        DM.GUI.classCollapseState[class] = isCollapsed
      end

      -- Add additional spacing above class headers (5px of extra space - reduced from 10px)
      yOffset = yOffset + 5

      -- Create class header
      local headerFrame, newOffset = DM:CreateClassHeaderRow(class, yOffset)
      yOffset = newOffset

      -- Add additional spacing below class headers (5px of extra space)
      yOffset = yOffset + 5

      table.insert(DM.GUI.classHeaderFrames, headerFrame)

      -- Enable mouse wheel scrolling on the header frame
      headerFrame:EnableMouseWheel(true)
      headerFrame:SetScript("OnMouseWheel", function(self, delta)
        -- Pass mouse wheel event to the parent scroll frame
        if scrollFrame and scrollFrame:GetScript("OnMouseWheel") then
          scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta)
        end
      end)

      -- Set spell count on header
      headerFrame.countText:SetText(classSpellCount .. " " .. (classSpellCount == 1 and "spell" or "spells"))

      -- Update toggle button texture to match current state
      if headerFrame.toggleButton and headerFrame.toggleButton.texture then
        headerFrame.toggleButton.texture:SetTexture(isCollapsed and
          "Interface\\Buttons\\UI-PlusButton-Up" or
          "Interface\\Buttons\\UI-MinusButton-Up")
      end

      -- If non-player class, ensure toggle button is disabled
      if not isCurrentClass and headerFrame.toggleButton then
        headerFrame.toggleButton:SetEnabled(false)
        headerFrame.toggleButton.texture:SetDesaturated(true)
      end

      -- Add spells (always create them but hide if collapsed)
      addSpellRows(spellsByClass[class], class, isCurrentClass)
    end
  end

  -- Show the scroll child again with new content
  DM.GUI.scrollChild:Show()

  -- Update scroll child height for scrolling - add a little more bottom padding
  DM.GUI.scrollChild:SetHeight(math.max(yOffset + 30, DM.GUI.scrollFrame:GetHeight()))

  -- Debug log of tracked spells count
  DM:DatabaseDebug(string.format("RefreshTrackedSpellList: displayed %d tracked spells", index))
  DM:DebugMsg("RefreshTrackedSpellList complete with yOffset = " .. yOffset)
end

-- Create a row for spell configuration
function DM:CreateSpellConfigRow(spellID, index, yOffset)
  -- Ensure scroll child exists
  if not DM.GUI.scrollChild then
    DM:GUIDebug("scrollChild not found in CreateSpellConfigRow")
    return nil
  end

  -- Make sure spellID is numeric
  local numericID = tonumber(spellID)
  if not numericID then
    DM:DatabaseDebug(string.format("Invalid non-numeric spell ID: %s", tostring(spellID)))
    return nil
  end

  -- Fetch the config from dmspellsdb
  local config = DM.dmspellsdb and DM.dmspellsdb[numericID]
  if not config then
    DM:DatabaseDebug(string.format("Config not found in dmspellsdb for spell ID: %d", numericID))
    return nil
  end

  -- Get layout info
  local LAYOUT = DM.GUI.layout
  if not LAYOUT then
    DM:GUIDebug("Layout information not found in CreateSpellConfigRow")
    return nil
  end

  local COLUMN_POSITIONS = LAYOUT.columns
  local COLUMN_WIDTHS = LAYOUT.widths
  local PADDING = LAYOUT.padding

  -- Basic frame creation
  local scrollChild = DM.GUI.scrollChild
  local spellRow = CreateFrame("Frame", "DotMasterSpellRow" .. index, scrollChild)

  -- Calculate row width to match exactly the scrollChild width
  local rowWidth = scrollChild:GetWidth()
  local rowHeight = 38 -- Define row height to match class headers

  -- Set the row size and position with consistent spacing
  spellRow:SetSize(rowWidth, rowHeight)
  spellRow:SetPoint("TOPLEFT", 0, -yOffset)
  spellRow.spellID = numericID -- Store the spellID (numeric) reference

  -- Create background for the row - full width
  local bg = spellRow:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(spellRow)
  if index % 2 == 0 then
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5) -- Darker
  else
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)    -- Lighter
  end

  -- Highlight effect on hover
  local highlight = spellRow:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints(spellRow)
  highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
  highlight:SetBlendMode("ADD")

  -- Enable mouse interaction for highlight effect
  spellRow:EnableMouse(true)

  -- Enable mouse wheel scrolling on the spell row
  spellRow:EnableMouseWheel(true)
  spellRow:SetScript("OnMouseWheel", function(self, delta)
    -- Pass mouse wheel event to the parent scroll frame
    local scrollFrame = DM.GUI.scrollFrame
    if scrollFrame and scrollFrame:GetScript("OnMouseWheel") then
      scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta)
    end
  end)

  -- ON: Enable/Disable Checkbox
  local enableCheckbox = CreateFrame("CheckButton", nil, spellRow, "UICheckButtonTemplate")
  enableCheckbox:SetSize(24, 24)
  -- Center the checkbox in its column for better alignment
  enableCheckbox:SetPoint("CENTER", spellRow, "LEFT", COLUMN_POSITIONS.ON + (COLUMN_WIDTHS.ON / 2), 0)
  enableCheckbox:SetChecked(config.enabled == 1)

  enableCheckbox:SetScript("OnClick", function(self)
    local isChecked = self:GetChecked()
    DM:DatabaseDebug(string.format("Updating enabled status for %d to %s", numericID, tostring(isChecked)))
    DM.dmspellsdb[numericID].enabled = isChecked and 1 or 0

    -- Save the changes
    DM:SaveDMSpellsDB()
  end)

  -- SPELL: Combined spell icon, name and ID in a single section
  local spellContainer = CreateFrame("Frame", nil, spellRow)
  spellContainer:SetPoint("LEFT", COLUMN_POSITIONS.ID, 0)
  spellContainer:SetSize(COLUMN_WIDTHS.ID + COLUMN_WIDTHS.NAME, rowHeight)

  -- Spell Icon
  local iconSize = 24
  local icon = spellContainer:CreateTexture(nil, "ARTWORK")
  icon:SetSize(iconSize, iconSize)
  icon:SetPoint("LEFT", 0, 0)
  icon:SetTexture(config.spellicon or "Interface\\Icons\\INV_Misc_QuestionMark")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

  -- Create a frame for the icon border
  local iconBorder = CreateFrame("Frame", nil, spellContainer, "BackdropTemplate")
  iconBorder:SetSize(iconSize + 2, iconSize + 2)
  iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
  iconBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  iconBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  -- Spell Name and ID Text
  local nameText = spellContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  -- Allow more space for name by using most of the available width
  nameText:SetWidth(COLUMN_WIDTHS.NAME + COLUMN_WIDTHS.ID - iconSize - 20)
  nameText:SetJustifyH("LEFT")
  local spellName = config.spellname or "Unknown Name"
  nameText:SetText(string.format("%s (%d)", spellName, numericID))

  -- COLOR: Color Picker button using the colorpicker module
  local r, g, b = 1, 0, 0 -- Default red
  if config.color and config.color[1] and config.color[2] and config.color[3] then
    r, g, b = config.color[1], config.color[2], config.color[3]
  end

  -- Create color swatch using DotMaster_CreateColorSwatch
  local colorSwatch = DotMaster_CreateColorSwatch(spellRow, r, g, b, function(newR, newG, newB)
    -- Update color in database
    DM.dmspellsdb[numericID].color = { newR, newG, newB }

    -- Save changes immediately
    DM:SaveDMSpellsDB()

    DM:DatabaseDebug(string.format("Updated color for spell %d to RGB(%f, %f, %f)",
      numericID, newR, newG, newB))
  end)
  colorSwatch:SetPoint("LEFT", COLUMN_POSITIONS.COLOR, 0)

  -- ORDER: Up/Down buttons for priority
  local orderContainer = CreateFrame("Frame", nil, spellRow)
  orderContainer:SetSize(COLUMN_WIDTHS.UP + COLUMN_WIDTHS.DOWN, rowHeight)
  orderContainer:SetPoint("LEFT", COLUMN_POSITIONS.UP, 0)

  -- Calculate centered position for the buttons with reduced spacing
  local buttonAreaWidth = COLUMN_WIDTHS.UP + COLUMN_WIDTHS.DOWN
  local buttonsWidth = 24 + 2 + 24 -- button + spacing + button
  local leftPadding = (buttonAreaWidth - buttonsWidth) / 2

  -- Down Button (left) - Standard WoW arrow
  local downButton = CreateFrame("Button", nil, orderContainer)
  downButton:SetSize(24, 24)
  downButton:SetPoint("LEFT", leftPadding, 0)
  downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
  downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

  -- UP Button (right) - Standard WoW arrow - reduced spacing
  local upButton = CreateFrame("Button", nil, orderContainer)
  upButton:SetSize(24, 24)
  upButton:SetPoint("LEFT", downButton, "RIGHT", 2, 0) -- Reduced from 5px to 2px
  upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
  upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
  upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

  -- Store reference to buttons in the row for later access
  spellRow.upButton = upButton
  spellRow.downButton = downButton
  spellRow.index = index -- Store index for checking first/last position

  -- Store references to UI elements for desaturation
  spellRow.icon = icon
  spellRow.colorSwatch = colorSwatch
  spellRow.enableCheckbox = enableCheckbox
  spellRow.textures = {
    icon = icon,
    bg = bg,
    highlight = highlight
  }

  upButton:SetScript("OnClick", function()
    local currentPriority = DM.dmspellsdb[numericID].priority or 999
    local newPriority = math.max(1, currentPriority - 10)

    if newPriority ~= currentPriority then
      DM:DatabaseDebug(string.format("Changing priority for %d from %d to %d",
        numericID, currentPriority, newPriority))

      DM.dmspellsdb[numericID].priority = newPriority

      -- Save and refresh
      DM:SaveDMSpellsDB()
      DM.GUI:RefreshTrackedSpellList()
    end
  end)

  downButton:SetScript("OnClick", function()
    local currentPriority = DM.dmspellsdb[numericID].priority or 999
    local newPriority = currentPriority + 10

    DM:DatabaseDebug(string.format("Changing priority for %d from %d to %d",
      numericID, currentPriority, newPriority))

    DM.dmspellsdb[numericID].priority = newPriority

    -- Save and refresh
    DM:SaveDMSpellsDB()
    DM.GUI:RefreshTrackedSpellList()
  end)

  -- Create UNTRACK/Remove button with proper spacing and sizing
  local untrackButton = CreateFrame("Button", nil, spellRow, "UIPanelButtonTemplate")
  untrackButton:SetSize(60, 24) -- Maintain size for consistency
  untrackButton:SetPoint("CENTER", spellRow, "LEFT", COLUMN_POSITIONS.DEL + (COLUMN_WIDTHS.DEL / 2), 0)
  untrackButton:SetText("Remove")

  -- Make button red to stand out
  untrackButton.Left:SetVertexColor(0.8, 0.2, 0.2)
  untrackButton.Middle:SetVertexColor(0.8, 0.2, 0.2)
  untrackButton.Right:SetVertexColor(0.8, 0.2, 0.2)

  -- Store reference to untrack button
  spellRow.removeButton = untrackButton

  untrackButton:SetScript("OnClick", function()
    -- Update tracked flag to 0 to "remove" from tracking
    DM:DatabaseDebug(string.format("Removing %d from tracked spells", numericID))

    if DM.dmspellsdb[numericID] then
      DM.dmspellsdb[numericID].tracked = 0
    end

    -- Save and refresh
    DM:SaveDMSpellsDB()
    DM.GUI:RefreshTrackedSpellList()
  end)

  -- Update positions when resize happens
  function spellRow.UpdatePositions(positions, widths)
    if not positions or not widths then return end

    -- Update row width to match content area
    spellRow:SetWidth(scrollChild:GetWidth())

    -- Update positioned elements
    enableCheckbox:SetPoint("CENTER", spellRow, "LEFT", positions.ON + (widths.ON / 2), 0)

    spellContainer:SetPoint("LEFT", positions.ID, 0)
    spellContainer:SetSize(widths.ID + widths.NAME, rowHeight)

    -- Update nameText width
    nameText:SetWidth(widths.NAME + widths.ID - iconSize - 20)

    colorSwatch:SetPoint("LEFT", positions.COLOR, 0)

    orderContainer:SetPoint("LEFT", positions.UP, 0)
    orderContainer:SetSize(widths.UP + widths.DOWN, rowHeight)

    -- Update arrow buttons position
    local buttonAreaWidth = widths.UP + widths.DOWN
    local buttonsWidth = 24 + 2 + 24 -- button + spacing + button
    local leftPadding = (buttonAreaWidth - buttonsWidth) / 2
    downButton:SetPoint("LEFT", leftPadding, 0)
    upButton:SetPoint("LEFT", downButton, "RIGHT", 2, 0)

    -- Position Remove button
    untrackButton:SetPoint("CENTER", spellRow, "LEFT", positions.DEL + (widths.DEL / 2), 0)
    -- With increased window width, we can use full button width
    untrackButton:SetWidth(60)
  end

  return spellRow
end
