-- DotMaster gui_spell_selection.lua
-- Spell selection dialog for adding spells from database

local DM = DotMaster

-- Function to show spell selection dialog
function DM:ShowSpellSelectionDialog()
  -- Check if database is empty
  if not self.spellDatabase or self:TableCount(self.spellDatabase) == 0 then
    self:ShowFindMyDotsPrompt()
    return
  end

  if not self.spellSelectionFrame then
    -- Spell selection dialog - made movable
    self.spellSelectionFrame = CreateFrame("Frame", "DotMasterSpellSelection", UIParent, "BackdropTemplate")
    self.spellSelectionFrame:SetFrameStrata("DIALOG")
    self.spellSelectionFrame:SetSize(450, 400)
    self.spellSelectionFrame:SetPoint("CENTER")
    self.spellSelectionFrame:SetMovable(true)
    self.spellSelectionFrame:EnableMouse(true)
    self.spellSelectionFrame:RegisterForDrag("LeftButton")
    self.spellSelectionFrame:SetScript("OnDragStart", self.spellSelectionFrame.StartMoving)
    self.spellSelectionFrame:SetScript("OnDragStop", self.spellSelectionFrame.StopMovingOrSizing)

    -- Background
    self.spellSelectionFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.spellSelectionFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    self.spellSelectionFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)

    -- Title bar for better dragging
    local titleBar = CreateFrame("Frame", nil, self.spellSelectionFrame)
    titleBar:SetHeight(25)
    titleBar:SetPoint("TOPLEFT", 8, -8)
    titleBar:SetPoint("TOPRIGHT", -8, -8)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() self.spellSelectionFrame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() self.spellSelectionFrame:StopMovingOrSizing() end)

    -- Title bar background
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.15, 0.15, 0.15, 0.8)

    -- Title
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 0)
    title:SetText("Select Spells From Database")

    -- Class filter container for better layout
    local filterContainer = CreateFrame("Frame", nil, self.spellSelectionFrame)
    filterContainer:SetSize(410, 30)
    filterContainer:SetPoint("TOP", titleBar, "BOTTOM", 0, -10)

    -- Class filter
    local classFilterLabel = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classFilterLabel:SetPoint("LEFT", 10, 0)
    classFilterLabel:SetText("Class Filter:")
    classFilterLabel:SetTextColor(1, 0.82, 0) -- Gold color

    -- Create dropdown frame for class filter with improved styling
    local classDropdown = CreateFrame("Frame", "DotMasterSpellClassDropdown", filterContainer, "UIDropDownMenuTemplate")
    classDropdown:SetPoint("LEFT", classFilterLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(classDropdown, 150)
    UIDropDownMenu_JustifyText(classDropdown, "LEFT")

    -- Search box with improved styling
    local searchBox = CreateFrame("EditBox", nil, filterContainer, "SearchBoxTemplate")
    searchBox:SetSize(180, 20)
    searchBox:SetPoint("RIGHT", -10, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("Search...")
    searchBox:SetMaxLetters(50)

    -- Filter text on typing
    searchBox:SetScript("OnTextChanged", function(self)
      DM:FilterSpellList(self:GetText())
    end)

    -- Clear default text on focus
    searchBox:SetScript("OnEditFocusGained", function(self)
      if self:GetText() == "Search..." then
        self:SetText("")
      end
    end)

    -- Restore default text if empty on focus lost
    searchBox:SetScript("OnEditFocusLost", function(self)
      if self:GetText() == "" then
        self:SetText("Search...")
      end
    end)

    -- Scroll frame for spell list
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.spellSelectionFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(380, 250)
    scrollFrame:SetPoint("TOP", self.spellSelectionFrame, "TOP", 0, -80)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(360, 10) -- Dynamic height

    -- Buttons at the bottom with improved styling
    local buttonContainer = CreateFrame("Frame", nil, self.spellSelectionFrame)
    buttonContainer:SetSize(380, 40)
    buttonContainer:SetPoint("BOTTOM", 0, 15)

    -- Button background for better visibility
    local buttonBg = buttonContainer:CreateTexture(nil, "BACKGROUND")
    buttonBg:SetAllPoints()
    buttonBg:SetColorTexture(0.1, 0.1, 0.1, 0.4)

    -- Select All button with WoW styling
    local selectAllButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    selectAllButton:SetSize(115, 26)
    selectAllButton:SetPoint("LEFT", 10, 0)
    selectAllButton:SetText("Select All")
    selectAllButton:SetNormalFontObject("GameFontNormalSmall")
    selectAllButton:GetNormalTexture():SetVertexColor(0.7, 0.7, 0.7)

    -- Select None button with WoW styling
    local selectNoneButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    selectNoneButton:SetSize(115, 26)
    selectNoneButton:SetPoint("CENTER", 0, 0)
    selectNoneButton:SetText("Select None")
    selectNoneButton:SetNormalFontObject("GameFontNormalSmall")
    selectNoneButton:GetNormalTexture():SetVertexColor(0.7, 0.7, 0.7)

    -- Add Selected button with WoW styling - green tint to indicate action
    local addSelectedButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    addSelectedButton:SetSize(115, 26)
    addSelectedButton:SetPoint("RIGHT", -10, 0)
    addSelectedButton:SetText("Add Selected")
    addSelectedButton:SetNormalFontObject("GameFontNormalSmall")
    -- Give it a slight green tint to indicate it's the action button
    for i, region in ipairs({ addSelectedButton:GetRegions() }) do
      if region:GetObjectType() == "Texture" then
        region:SetVertexColor(0.8, 1.0, 0.8)
      end
    end

    -- Close button at top right
    local closeButton = CreateFrame("Button", nil, self.spellSelectionFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)
    closeButton:SetScript("OnClick", function()
      self.spellSelectionFrame:Hide()
    end)

    -- Store references
    self.spellSearchBox = searchBox
    self.spellScrollChild = scrollChild
    self.spellScrollFrame = scrollFrame
    self.spellClassDropdown = classDropdown
    self.addSelectedButton = addSelectedButton
    self.selectAllButton = selectAllButton
    self.selectNoneButton = selectNoneButton

    -- Select All functionality
    selectAllButton:SetScript("OnClick", function()
      for id, checkbox in pairs(self.spellCheckboxes or {}) do
        checkbox:SetChecked(true)
      end
    end)

    -- Select None functionality
    selectNoneButton:SetScript("OnClick", function()
      for id, checkbox in pairs(self.spellCheckboxes or {}) do
        checkbox:SetChecked(false)
      end
    end)

    -- Add Selected button handler
    addSelectedButton:SetScript("OnClick", function()
      local added = 0

      for id, checkbox in pairs(self.spellCheckboxes or {}) do
        if checkbox:GetChecked() then
          -- Only add if not already exists
          if not self:SpellExists(id) then
            local spellData = self.spellDatabase[tonumber(id)]

            if spellData then
              -- Add to dmspellsdb with default settings
              local numericID = tonumber(id)
              self:AddSpellToDMSpellsDB(
                numericID,
                spellData.name,
                "Interface\\Icons\\INV_Misc_QuestionMark", -- Default icon, can be updated later
                spellData.class or "UNKNOWN",
                spellData.spec or "General"
              )

              -- Enable tracking for this spell
              self.dmspellsdb[numericID].tracked = 1
              self.dmspellsdb[numericID].priority = self:GetNextPriority()

              added = added + 1
            end
          end
        end
      end

      -- Update GUI and save settings
      if added > 0 then
        if self.GUI and self.GUI.RefreshSpellList then
          self.GUI:RefreshSpellList()
        end

        self:SaveDMSpellsDB()
        self:PrintMessage(string.format("%d spells successfully added!", added))
      else
        self:PrintMessage("No new spells added.")
      end

      self.spellSelectionFrame:Hide()
    end)

    -- Initialize dropdown menu
    UIDropDownMenu_SetWidth(classDropdown, 150)
    UIDropDownMenu_SetText(classDropdown, "All Classes")
  end

  -- Initialize dropdown menu content
  UIDropDownMenu_Initialize(self.spellClassDropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()

    -- First, add "All Classes" option
    info.text = "All Classes"
    info.value = "ALL"
    info.func = function()
      UIDropDownMenu_SetText(DM.spellClassDropdown, "All Classes")
      DM.selectedDatabaseClass = "ALL"
      DM:PopulateSpellList()
    end
    UIDropDownMenu_AddButton(info)

    -- Get all available classes from database
    local availableClasses = { ["ALL"] = "All Classes" }
    for _, spellData in pairs(DM.spellDatabase) do
      if spellData.class then
        availableClasses[spellData.class] = DM:GetClassDisplayName(spellData.class)
      end
    end

    -- Add each available class
    for className, displayName in pairs(availableClasses) do
      if className ~= "ALL" then
        info.text = displayName
        info.value = className
        info.func = function()
          UIDropDownMenu_SetText(DM.spellClassDropdown, displayName)
          DM.selectedDatabaseClass = className
          DM:PopulateSpellList()
        end
        UIDropDownMenu_AddButton(info)
      end
    end
  end)

  -- Store selected class
  self.selectedDatabaseClass = "ALL"
  self.spellCheckboxes = {}

  -- Populate spell list
  self:PopulateSpellList()

  -- Show the frame
  self.spellSelectionFrame:Show()
end

-- Function to populate spell list in selection dialog
function DM:PopulateSpellList()
  if not self.spellScrollChild then return end

  -- Clear existing children
  local children = { self.spellScrollChild:GetChildren() }
  for _, child in pairs(children) do
    pcall(function() child:Hide() end)
    pcall(function() child:SetParent(nil) end)
  end

  -- Get filter text
  local searchText = ""
  if self.spellSearchBox then
    searchText = self.spellSearchBox:GetText()
    if searchText == "Search..." then searchText = "" end
  end

  -- Get filtered spells
  local filteredSpells
  if searchText and searchText ~= "" then
    filteredSpells = self:SearchSpellsByName(searchText)
  else
    filteredSpells = self:GetSpellsForClass(self.selectedDatabaseClass)
  end

  -- Group by class and spec
  local spellsByClass = {}

  for id, spellData in pairs(filteredSpells) do
    local className = spellData.class or "UNKNOWN"
    local specName = spellData.spec or "General"

    -- If class filter is active, only show matching class
    if self.selectedDatabaseClass == "ALL" or className == self.selectedDatabaseClass then
      -- Create class entry if it doesn't exist
      if not spellsByClass[className] then
        spellsByClass[className] = {}
      end

      -- Create spec entry if it doesn't exist
      if not spellsByClass[className][specName] then
        spellsByClass[className][specName] = {}
      end

      -- Add spell to appropriate class and spec
      spellsByClass[className][specName][id] = spellData
    end
  end

  -- Display spells grouped by class and spec
  local yOffset = 10

  -- Sort classes alphabetically
  local classes = {}
  for className in pairs(spellsByClass) do
    table.insert(classes, className)
  end
  table.sort(classes, function(a, b)
    return self:GetClassDisplayName(a) < self:GetClassDisplayName(b)
  end)

  -- Create expandable sections for each class
  for _, className in ipairs(classes) do
    -- Class header
    local classHeader = CreateFrame("Button", nil, self.spellScrollChild)
    classHeader:SetSize(330, 25)
    classHeader:SetPoint("TOPLEFT", 5, -yOffset)

    -- Class background
    local classBg = classHeader:CreateTexture(nil, "BACKGROUND")
    classBg:SetAllPoints()
    classBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Class name
    local classText = classHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    classText:SetPoint("LEFT", 5, 0)
    classText:SetText("+ " .. self:GetClassDisplayName(className))

    -- Make class header expandable
    classHeader.expanded = true
    classHeader.specFrames = {}

    classHeader:SetScript("OnClick", function(self)
      self.expanded = not self.expanded
      -- Update text indicator
      classText:SetText((self.expanded and "- " or "+ ") .. DM:GetClassDisplayName(className))

      -- Toggle visibility of all specs under this class
      for _, specFrame in ipairs(self.specFrames) do
        if self.expanded then
          pcall(function() specFrame:Show() end)
        else
          pcall(function() specFrame:Hide() end)
        end
      end

      -- Recalculate scroll child height
      DM:UpdateSpellListHeight()
    end)

    yOffset = yOffset + 30

    -- Sort specs alphabetically
    local specs = {}
    for specName in pairs(spellsByClass[className]) do
      table.insert(specs, specName)
    end
    table.sort(specs)

    -- Create sections for each spec
    for _, specName in ipairs(specs) do
      -- Spec container
      local specFrame = CreateFrame("Frame", nil, self.spellScrollChild)
      specFrame:SetSize(330, 30) -- Height will be adjusted based on content
      specFrame:SetPoint("TOPLEFT", 15, -yOffset)

      -- Add to class header's spec frames
      table.insert(classHeader.specFrames, specFrame)

      -- Spec header
      local specHeader = CreateFrame("Frame", nil, specFrame)
      specHeader:SetSize(315, 25)
      specHeader:SetPoint("TOPLEFT", 0, 0)

      -- Spec background
      local specBg = specHeader:CreateTexture(nil, "BACKGROUND")
      specBg:SetAllPoints()
      specBg:SetColorTexture(0.15, 0.15, 0.15, 0.6)

      -- Spec name
      local specText = specHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      specText:SetPoint("LEFT", 5, 0)
      specText:SetText(specName)
      specText:SetTextColor(1, 0.82, 0)

      yOffset = yOffset + 30
      local specHeight = 30

      -- Add spells for this spec
      local specSpells = spellsByClass[className][specName]
      local spellIDs = {}

      -- Collect spell IDs for sorting
      for id in pairs(specSpells) do
        table.insert(spellIDs, id)
      end

      -- Sort spells by name
      table.sort(spellIDs, function(a, b)
        local nameA = specSpells[a].name or ""
        local nameB = specSpells[b].name or ""
        return nameA < nameB
      end)

      -- Create a row for each spell
      for _, id in ipairs(spellIDs) do
        local spellData = specSpells[id]

        -- Don't show spells that are already added to the addon
        if not self:SpellExists(id) then
          -- Create row
          local row = CreateFrame("Frame", nil, specFrame)
          row:SetSize(315, 30)
          row:SetPoint("TOPLEFT", 0, -specHeight)

          -- Row background for alternating colors
          local rowBg = row:CreateTexture(nil, "BACKGROUND")
          rowBg:SetAllPoints()
          if specHeight % 60 < 30 then
            rowBg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
          else
            rowBg:SetColorTexture(0.12, 0.12, 0.12, 0.4)
          end

          -- Checkbox
          local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
          checkbox:SetSize(24, 24)
          checkbox:SetPoint("LEFT", 5, 0)
          checkbox:SetChecked(true)

          -- Store in checkboxes table
          self.spellCheckboxes[tostring(id)] = checkbox

          -- Spell name and ID
          local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
          text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
          text:SetText(string.format("%s (ID: %d)", spellData.name, id))

          specHeight = specHeight + 30
          yOffset = yOffset + 30
        end
      end

      -- Update spec frame height if we added spells
      if specHeight > 30 then
        specFrame:SetHeight(specHeight)
      else
        -- No spells in this spec that aren't already added
        yOffset = yOffset - 30 -- Undo the yOffset increase from spec header
        specFrame:Hide()       -- Hide empty spec frame

        -- Also remove from class header's spec frames
        for i, frame in ipairs(classHeader.specFrames) do
          if frame == specFrame then
            table.remove(classHeader.specFrames, i)
            break
          end
        end
      end
    end

    -- If no specs have any spells, hide class header too
    if #classHeader.specFrames == 0 then
      classHeader:Hide()
      yOffset = yOffset - 30 -- Undo the yOffset increase from class header
    end
  end

  -- Update scroll child height
  self:UpdateSpellListHeight()
end

-- Function to filter spell list by search text
function DM:FilterSpellList(searchText)
  -- Just call PopulateSpellList - it handles the filtering
  self:PopulateSpellList()
end

-- Helper function to update spell list height
function DM:UpdateSpellListHeight()
  if not self.spellScrollChild or not self.spellScrollFrame then return end

  -- Calculate total height based on visible elements
  local totalHeight = 10 -- starting offset
  local children = { self.spellScrollChild:GetChildren() }

  for _, child in pairs(children) do
    -- Safe checks for all operations
    if child and type(child) == "table" then
      local isButton = false
      local isShown = false
      local height = 30 -- Default height

      -- Safely check object type
      pcall(function()
        if child.GetObjectType and child:GetObjectType() == "Button" then
          isButton = true
        end
      end)

      -- Safely check if shown
      pcall(function()
        if child.IsShown and child:IsShown() then
          isShown = true
        end
      end)

      -- Safely get height
      pcall(function()
        if child.GetHeight then
          height = child:GetHeight()
        end
      end)

      if isButton and isShown then
        -- This is a class header
        totalHeight = totalHeight + height

        -- If expanded, add height of visible spec frames
        local isExpanded = false
        pcall(function() isExpanded = child.expanded end)

        if isExpanded then
          local specFrames = {}
          pcall(function() specFrames = child.specFrames or {} end)

          for _, specFrame in ipairs(specFrames) do
            local isSpecShown = false
            pcall(function()
              if specFrame.IsShown and specFrame:IsShown() then
                isSpecShown = true
              end
            end)

            if isSpecShown then
              local specHeight = 30 -- Default spec height
              pcall(function()
                if specFrame.GetHeight then
                  specHeight = specFrame:GetHeight()
                end
              end)
              totalHeight = totalHeight + specHeight
            end
          end
        end
      elseif isShown then
        -- Non-button frames that are shown
        totalHeight = totalHeight + height
      end
    end
  end

  -- Add bottom padding
  totalHeight = totalHeight + 20

  -- Set height, ensuring it's at least as tall as the scroll frame
  local scrollHeight = 180 -- Default scroll frame height
  pcall(function()
    if self.spellScrollFrame.GetHeight then
      scrollHeight = self.spellScrollFrame:GetHeight()
    end
  end)

  if self.spellScrollChild.SetHeight then
    self.spellScrollChild:SetHeight(math.max(totalHeight, scrollHeight))
  end
end

-- Show prompt to use Find My Dots first
function DM:ShowFindMyDotsPrompt()
  -- Information window
  if not self.promptFrame then
    self.promptFrame = CreateFrame("Frame", "DotMasterPromptFrame", UIParent, "BackdropTemplate")
    self.promptFrame:SetFrameStrata("DIALOG")
    self.promptFrame:SetSize(400, 200)
    self.promptFrame:SetPoint("CENTER")

    -- Background
    self.promptFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.promptFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    self.promptFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)

    -- Title
    local title = self.promptFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("No Spells Detected Yet")

    -- Description
    local desc = self.promptFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -20)
    desc:SetWidth(350)
    desc:SetText(
      "Please use 'Find My Dots' first to detect your class spells. Target enemies and use your abilities to automatically build your spell database.")
    desc:SetJustifyH("CENTER")

    -- Button
    local button = CreateFrame("Button", nil, self.promptFrame, "UIPanelButtonTemplate")
    button:SetSize(160, 30)
    button:SetPoint("BOTTOM", 0, 20)
    button:SetText("Start Find My Dots")

    button:SetScript("OnClick", function()
      if self.promptFrame.Hide then
        self.promptFrame:Hide()
      end
      self:StartFindMyDots()
    end)

    -- Close button
    local closeButton = CreateFrame("Button", nil, self.promptFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)
  end

  if self.promptFrame.Show then
    self.promptFrame:Show()
  end
end
