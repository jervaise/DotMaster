-- DotMaster gui_tracked_spells_tab.lua
-- Contains the Tracked Spells tab functionality for the GUI

local DM = DotMaster

-- Create Tracked Spells tab content
function DM:CreateTrackedSpellsTab(parent)
  DM:DebugMsg("Creating Tracked Spells Tab") -- Updated debug message

  -- Constants for professional layout
  local PADDING = {
    OUTER = 5,  -- Outside frame padding
    INNER = 8,  -- Inner content padding
    COLUMN = 12 -- Space between columns
  }

  -- Yüzde tabanlı kolon genişlikleri
  local COLUMN_WIDTH_PCT = {
    ON = 0.06,    -- %6 Checkbox
    ID = 0.13,    -- %13 ID alanı
    NAME = 0.40,  -- %40 İsim alanı
    COLOR = 0.09, -- %9 Renk
    SAVE = 0.09,  -- %9 Kaydet
    ORDER = 0.13, -- %13 Sıralama butonları
    DEL = 0.10    -- %10 Silme butonu
  }

  -- Default positioning
  local frameWidth = parent:GetWidth() - (PADDING.OUTER * 2)

  -- Create UpdateLayout function - frame resize olduğunda pozisyonları günceller
  local function UpdateColumnPositions(width)
    local positions = {}
    local widths = {}
    local xPos = PADDING.INNER

    -- Calculate positions
    positions.ON = xPos
    widths.ON = width * COLUMN_WIDTH_PCT.ON
    xPos = xPos + widths.ON

    positions.ID = xPos
    widths.ID = width * COLUMN_WIDTH_PCT.ID
    xPos = xPos + widths.ID

    positions.NAME = xPos
    widths.NAME = width * COLUMN_WIDTH_PCT.NAME
    xPos = xPos + widths.NAME

    positions.COLOR = xPos
    widths.COLOR = width * COLUMN_WIDTH_PCT.COLOR
    xPos = xPos + widths.COLOR

    positions.SAVE = xPos
    widths.SAVE = width * COLUMN_WIDTH_PCT.SAVE
    xPos = xPos + widths.SAVE

    positions.UP = xPos
    widths.UP = (width * COLUMN_WIDTH_PCT.ORDER) / 2
    xPos = xPos + widths.UP

    positions.DOWN = xPos
    widths.DOWN = (width * COLUMN_WIDTH_PCT.ORDER) / 2
    xPos = xPos + widths.DOWN

    positions.DEL = xPos
    widths.DEL = width * COLUMN_WIDTH_PCT.DEL

    -- Return both positions and widths
    return positions, widths
  end

  -- İlk pozisyonları hesapla
  local COLUMN_POSITIONS, COLUMN_WIDTHS = UpdateColumnPositions(frameWidth)

  -- Spells Tab Header
  local spellTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  spellTitle:SetPoint("TOP", 0, -10)
  spellTitle:SetText("Configure Spell Tracking")

  -- Instructions
  local instructions = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  instructions:SetPoint("TOP", spellTitle, "BOTTOM", 0, -10)
  instructions:SetText("Enter spell ID, click checkmark to save")
  instructions:SetTextColor(1, 0.82, 0)

  -- Spell list background for better visuals
  local spellListBg = parent:CreateTexture(nil, "BACKGROUND")
  spellListBg:SetPoint("TOPLEFT", PADDING.OUTER, -70)
  spellListBg:SetPoint("BOTTOMRIGHT", -PADDING.OUTER, 40)
  spellListBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

  -- Scrollframe for spell list
  local scrollFrame = CreateFrame("ScrollFrame", "DotMasterSpellScrollFrame", parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", PADDING.OUTER + PADDING.INNER, -80)
  scrollFrame:SetPoint("BOTTOMRIGHT", -(PADDING.OUTER + 20), 45) -- 20px for scrollbar

  local scrollChild = CreateFrame("Frame")
  scrollFrame:SetScrollChild(scrollChild)
  scrollChild:SetSize(scrollFrame:GetWidth(), 500) -- Extra width for content

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
  headerFrame:SetSize(scrollChild:GetWidth() - (PADDING.INNER * 2), 30)
  headerFrame:SetPoint("TOPLEFT", PADDING.INNER, -PADDING.INNER)

  -- Header background
  local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetAllPoints()
  headerBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

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
  headerTexts.ON = CreateHeaderText("On", COLUMN_POSITIONS.ON, COLUMN_WIDTHS.ON)
  headerTexts.ID = CreateHeaderText("ID", COLUMN_POSITIONS.ID, COLUMN_WIDTHS.ID)
  headerTexts.NAME = CreateHeaderText("Spell Name", COLUMN_POSITIONS.NAME, COLUMN_WIDTHS.NAME)
  headerTexts.COLOR = CreateHeaderText("Color", COLUMN_POSITIONS.COLOR, COLUMN_WIDTHS.COLOR)
  headerTexts.SAVE = CreateHeaderText("Save", COLUMN_POSITIONS.SAVE, COLUMN_WIDTHS.SAVE)

  -- Order başlığını ortala
  local orderText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local orderX = COLUMN_POSITIONS.UP + (COLUMN_WIDTHS.UP + COLUMN_WIDTHS.DOWN) / 2
  orderText:SetPoint("CENTER", headerFrame, "LEFT", orderX - 8, 0) -- Ortalama için offset
  orderText:SetText("Order")
  orderText:SetTextColor(1, 0.82, 0)
  headerTexts.ORDER = orderText

  headerTexts.DEL = CreateHeaderText("Del", COLUMN_POSITIONS.DEL, COLUMN_WIDTHS.DEL)

  -- Update başlık pozisyonlarını güncelleme fonksiyonu
  local function UpdateHeaderPositions()
    local width = scrollChild:GetWidth() - (PADDING.INNER * 2)
    local positions, widths = UpdateColumnPositions(width)

    headerTexts.ON:SetPoint("LEFT", positions.ON, 0)
    headerTexts.ON:SetWidth(widths.ON)

    headerTexts.ID:SetPoint("LEFT", positions.ID, 0)
    headerTexts.ID:SetWidth(widths.ID)

    headerTexts.NAME:SetPoint("LEFT", positions.NAME, 0)
    headerTexts.NAME:SetWidth(widths.NAME)

    headerTexts.COLOR:SetPoint("LEFT", positions.COLOR, 0)
    headerTexts.COLOR:SetWidth(widths.COLOR)

    headerTexts.SAVE:SetPoint("LEFT", positions.SAVE, 0)
    headerTexts.SAVE:SetWidth(widths.SAVE)

    -- Order başlığını ortala
    local orderX = positions.UP + (widths.UP + widths.DOWN) / 2
    headerTexts.ORDER:SetPoint("CENTER", headerFrame, "LEFT", orderX - 8, 0)

    headerTexts.DEL:SetPoint("LEFT", positions.DEL, 0)
    headerTexts.DEL:SetWidth(widths.DEL)

    -- Update frame sizes
    headerFrame:SetWidth(width)

    -- Kaydet ve satırlara iletin
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

  -- Button container frame
  local buttonContainer = CreateFrame("Frame", nil, parent)
  buttonContainer:SetSize(320, 40)
  buttonContainer:SetPoint("BOTTOM", 0, 5)

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

  -- Parent frame'in boyutu değiştiğinde çağrılacak fonksiyon
  parent:HookScript("OnSizeChanged", function()
    scrollChild:SetWidth(scrollFrame:GetWidth())
    UpdateHeaderPositions()
  end)

  -- Scrollchild'ın boyutu değiştiğinde çağrılacak fonksiyon
  scrollChild:HookScript("OnSizeChanged", function()
    UpdateHeaderPositions()
  end)
end

-- Function to refresh the tracked spells list with class/spec grouping
function DM.GUI:RefreshTrackedSpellList()
  -- Ensure the necessary GUI elements exist
  if not DM.GUI.scrollChild or not DM.GUI.scrollFrame then
    DM:DatabaseDebug("Required GUI elements (scrollChild or scrollFrame) not found in RefreshTrackedSpellList")
    return
  end

  -- Clear existing frames
  if not DM.GUI.spellFrames then DM.GUI.spellFrames = {} end
  for _, frame in ipairs(DM.GUI.spellFrames) do
    frame:Hide()
    -- Consider pooling frames here instead of destroying if performance is an issue
  end
  DM.GUI.spellFrames = {}

  local yOffset = 40 -- Start after header
  local index = 0

  -- Ensure DM.dmspellsdb exists and has data
  if not DM.dmspellsdb or not next(DM.dmspellsdb) then
    DM:DatabaseDebug("dmspellsdb is empty or nil, nothing to display in Tracked Spells.")
    DM.GUI.scrollChild:SetHeight(DM.GUI.scrollFrame:GetHeight()) -- Set height to default if empty
    return
  end

  -- Group spells by class and spec from dmspellsdb
  local spellsByClassSpec = {}
  local playerClass, playerSpec = DM:GetPlayerClassAndSpec()
  playerClass = playerClass or "UNKNOWN"
  playerSpec = playerSpec or "General"

  -- Always create entry for player's class/spec to ensure it appears first
  spellsByClassSpec[playerClass] = spellsByClassSpec[playerClass] or {}
  spellsByClassSpec[playerClass][playerSpec] = {}

  -- Iterate through dmspellsdb and filter for tracked spells
  for spellIDStr, config in pairs(DM.dmspellsdb) do
    -- IMPORTANT: Filter for tracked spells
    if config.tracked and tonumber(config.tracked) == 1 then
      local class = config.wowclass or "Unknown"
      local spec = config.wowspec or "General"

      -- Initialize tables if needed
      spellsByClassSpec[class] = spellsByClassSpec[class] or {}
      spellsByClassSpec[class][spec] = spellsByClassSpec[class][spec] or {}

      -- Add spell to appropriate group
      table.insert(spellsByClassSpec[class][spec], {
        id = spellIDStr, -- Keep ID as string from dmspellsdb
        priority = config.priority or 999,
        config = config  -- Pass the full config from dmspellsdb
      })
    end
  end

  -- Sort all spell groups by priority
  for class, specs in pairs(spellsByClassSpec) do
    for spec, spells in pairs(specs) do
      table.sort(spells, function(a, b) return (a.priority or 999) < (b.priority or 999) end)
    end
  end

  -- Clear the scroll child before adding new content
  DM.GUI.scrollChild:Hide()

  -- Function to create and add rows for a given list of spells
  local function addSpellRows(spellList, class, spec)
    for _, spellData in ipairs(spellList) do
      index = index + 1
      -- Call the (currently basic) row creation function
      local row = DM:CreateSpellConfigRow(spellData.id, index, yOffset)
      if row then
        row.spellID = spellData.id -- Store spellID (string) in the frame
        row.class = class
        row.spec = spec
        table.insert(DM.GUI.spellFrames, row) -- Keep track of the created frame
        yOffset = yOffset + 38                -- Spacing for the next row (adjust as needed)
      end
    end
  end

  -- First add player's class/spec if it has tracked spells
  if playerClass and playerSpec and spellsByClassSpec[playerClass] and spellsByClassSpec[playerClass][playerSpec] then
    addSpellRows(spellsByClassSpec[playerClass][playerSpec], playerClass, playerSpec)
    -- Remove this class/spec after processing to avoid duplication
    spellsByClassSpec[playerClass][playerSpec] = nil
    if not next(spellsByClassSpec[playerClass]) then
      spellsByClassSpec[playerClass] = nil
    end
  end

  -- Then add remaining specs
  for class, specs in pairs(spellsByClassSpec) do
    for spec, spells in pairs(specs) do
      if #spells > 0 then -- Only add if there are spells
        addSpellRows(spells, class, spec)
      end
    end
  end

  -- Show the scroll child again with new content
  DM.GUI.scrollChild:Show()

  -- Update scroll child height for scrolling
  DM.GUI.scrollChild:SetHeight(math.max(yOffset + 20, DM.GUI.scrollFrame:GetHeight()))

  -- Debug log of tracked spells count
  DM:DatabaseDebug(string.format("RefreshTrackedSpellList: displayed %d tracked spells", index))
end
