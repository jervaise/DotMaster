-- DotMaster gui.lua
-- Ana GUI işlevselliği ve temel yapılar

local DM = DotMaster
DM.GUI = {}

-- Function to refresh the spell list
function DM.GUI:RefreshSpellList()
  if not DM.GUI.spellFrames then
    DM:DebugMsg("spellFrames not found in RefreshSpellList")
    return
  end

  for _, frame in ipairs(DM.GUI.spellFrames) do
    frame:Hide()
  end

  DM.GUI.spellFrames = {}
  local yOffset = 40 -- Start after header with more space
  local index = 0

  -- Add all spells
  for spellID, _ in pairs(DM.spellConfig) do
    index = index + 1
    DM:CreateSpellConfigRow(spellID, index, yOffset)
    yOffset = yOffset + 36 -- More space between rows
  end

  if DM.GUI.scrollChild and DM.GUI.scrollFrame then
    DM.GUI.scrollChild:SetHeight(math.max(yOffset + 10, DM.GUI.scrollFrame:GetHeight()))
  else
    DM:DebugMsg("scrollChild or scrollFrame not found in RefreshSpellList")
  end
end

-- Helper function to check if a spell ID already exists
function DM:SpellExists(spellID)
  -- Convert to number for comparison if needed
  local numericID = tonumber(spellID)
  if not numericID then return false end

  -- Check each spell config
  for existingID, _ in pairs(DM.spellConfig) do
    -- Direct ID match
    if tonumber(existingID) == numericID then
      return true
    end

    -- Check for IDs in comma-separated list
    if type(existingID) == "string" and existingID:find(",") then
      for id in string.gmatch(existingID, "%d+") do
        if tonumber(id) == numericID then
          return true
        end
      end
    end
  end

  return false
end

-- Main function to create the GUI
function DM:CreateGUI()
  DM:DebugMsg("Creating GUI...")

  -- Main frame
  local frame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(380, 450) -- Slightly larger frame
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  frame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)
  frame:Hide()

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("|cFFCC00FFDotMaster|r")

  -- Close Button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -3, -3)
  closeButton:SetSize(26, 26)

  -- Author credit
  local author = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  author:SetPoint("BOTTOM", 0, 10)
  author:SetText("by Jervaise")

  -- Create tab system
  local tabHeight = 30
  local tabFrames = {}
  local activeTab = 1

  -- Tab background
  local tabBg = frame:CreateTexture(nil, "BACKGROUND")
  tabBg:SetPoint("TOPLEFT", 8, -40)
  tabBg:SetPoint("TOPRIGHT", -8, -40)
  tabBg:SetHeight(tabHeight)
  tabBg:SetColorTexture(0.15, 0.15, 0.15, 0.6)

  for i = 1, 2 do
    -- Tab content frames
    tabFrames[i] = CreateFrame("Frame", "DotMasterTabFrame" .. i, frame)
    tabFrames[i]:SetPoint("TOPLEFT", 10, -(45 + tabHeight))
    tabFrames[i]:SetPoint("BOTTOMRIGHT", -10, 30)
    tabFrames[i]:Hide()

    -- Custom tab buttons
    local tabButton = CreateFrame("Button", "DotMasterTab" .. i, frame)
    tabButton:SetSize(100, tabHeight)

    -- Tab styling
    local normalTexture = tabButton:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetColorTexture(0.1, 0.1, 0.1, 0.7)

    -- Tab text
    local text = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(i == 1 and "General" or "Spells")
    text:SetTextColor(1, 0.82, 0)

    -- Store ID and script
    tabButton.id = i
    tabButton:SetScript("OnClick", function(self)
      -- Hide all frames and deselect all tabs
      for j, tabFrame in ipairs(tabFrames) do
        tabFrame:Hide()
        local tab = _G["DotMasterTab" .. j]
        tab:GetRegions():SetColorTexture(0.1, 0.1, 0.1, 0.7)
      end

      -- Show selected frame and highlight tab
      tabFrames[self.id]:Show()
      self:GetRegions():SetColorTexture(0.3, 0.3, 0.3, 0.8)
      activeTab = self.id
    end)

    -- Position tabs side by side with space between
    tabButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i - 1) * 105, -40)
  end

  -- Set initial active tab
  _G["DotMasterTab1"]:GetRegions():SetColorTexture(0.3, 0.3, 0.3, 0.8)
  tabFrames[1]:Show()

  -- General Tab Content
  DotMaster_Components.CreateGeneralTab(tabFrames[1])

  -- Spells Tab Content
  DotMaster_Components.CreateSpellsTab(tabFrames[2])

  -- Initialize spell list
  DM.GUI.frame = frame
  DM.GUI:RefreshSpellList()

  -- Check ColorPickerFrame
  C_Timer.After(1, function()
    print("|cFFCC00FFDotMaster Debug:|r ColorPickerFrame check: exists =", ColorPickerFrame ~= nil)
    if ColorPickerFrame then
      print("|cFFCC00FFDotMaster Debug:|r ColorPickerFrame is a", type(ColorPickerFrame))
      print("|cFFCC00FFDotMaster Debug:|r ColorPickerFrame frame strata:", ColorPickerFrame:GetFrameStrata())
      print("|cFFCC00FFDotMaster Debug:|r ColorPickerFrame frame level:", ColorPickerFrame:GetFrameLevel())
      print("|cFFCC00FFDotMaster Debug:|r ColorPickerFrame parent:",
        ColorPickerFrame:GetParent() and ColorPickerFrame:GetParent():GetName() or "none")
    end
  end)

  DM:DebugMsg("GUI creation complete, frame exists: " .. (DM.GUI.frame and "Yes" or "No"))

  return frame
end
