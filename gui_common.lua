-- DotMaster gui_common.lua
-- Contains common GUI functionality and components

local DM = DotMaster
DotMaster_Components = {}

-- Define component functions first (before they are used)
DotMaster_Components.CreateGeneralTab = function(parent)
  return DM:CreateGeneralTab(parent)
end

DotMaster_Components.CreateTrackedSpellsTab = function(parent)
  return DM:CreateTrackedSpellsTab(parent)
end

-- Add Database tab component function
DotMaster_Components.CreateDatabaseTab = function(parent)
  return Components.CreateDatabaseTab(parent)
end

-- Create the main GUI
function DM:CreateGUI()
  DM:DebugMsg("Creating GUI...")

  -- Main frame
  local frame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(480, 450) -- Wider frame for better content display
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Make frame resizable if supported
  if frame.SetResizable then
    frame:SetResizable(true)

    -- Set minimum size if supported
    if frame.SetMinResize then
      frame:SetMinResize(480, 300)
    else
      -- Alternative approach for versions that don't support SetMinResize
      frame:SetScript("OnSizeChanged", function(self, width, height)
        -- Enforce minimum size
        if width < 480 then self:SetWidth(480) end
        if height < 300 then self:SetHeight(300) end
      end)
    end
  end

  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  frame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)
  frame:Hide()

  -- Add resize button at bottom right
  local resizeBtn = CreateFrame("Button", nil, frame)
  resizeBtn:SetSize(16, 16)
  resizeBtn:SetPoint("BOTTOMRIGHT", -2, 2)
  resizeBtn:EnableMouse(true)

  -- Create an arrow texture for the resize button
  local resizeTexture = resizeBtn:CreateTexture(nil, "OVERLAY")
  resizeTexture:SetAllPoints()
  resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

  -- Highlight texture on hover
  local highlightTexture = resizeBtn:CreateTexture(nil, "HIGHLIGHT")
  highlightTexture:SetAllPoints()
  highlightTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

  -- Add on drag functionality
  resizeBtn:SetScript("OnMouseDown", function()
    if frame.StartSizing then
      frame:StartSizing("BOTTOMRIGHT")
    end
  end)

  resizeBtn:SetScript("OnMouseUp", function()
    if frame.StopMovingOrSizing then
      frame:StopMovingOrSizing()
    end
  end)

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

  for i = 1, 3 do
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
    text:SetText(i == 1 and "General" or i == 2 and "Tracked Spells" or "Database")
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

  -- Ensure functions exist before calling them
  if DM.CreateGeneralTab then
    DM:DebugMsg("Using DM:CreateGeneralTab directly")
    DM:CreateGeneralTab(tabFrames[1])
  elseif DotMaster_Components.CreateGeneralTab then
    DM:DebugMsg("Using DotMaster_Components.CreateGeneralTab")
    DotMaster_Components.CreateGeneralTab(tabFrames[1])
  else
    DM:DebugMsg("ERROR: CreateGeneralTab function not found!")
  end

  if DM.CreateTrackedSpellsTab then
    DM:DebugMsg("Using DM:CreateTrackedSpellsTab directly")
    DM:CreateTrackedSpellsTab(tabFrames[2])
  elseif DotMaster_Components.CreateTrackedSpellsTab then
    DM:DebugMsg("Using DotMaster_Components.CreateTrackedSpellsTab")
    DotMaster_Components.CreateTrackedSpellsTab(tabFrames[2])
  else
    DM:DebugMsg("ERROR: CreateTrackedSpellsTab function not found!")
  end

  -- Create Database tab content
  if DotMaster_Components.CreateDatabaseTab then
    DM:DebugMsg("Using DotMaster_Components.CreateDatabaseTab")
    DotMaster_Components.CreateDatabaseTab(tabFrames[3])
  else
    DM:DebugMsg("ERROR: CreateDatabaseTab function not found!")
  end

  -- Initialize spell list
  DM.GUI.frame = frame

  -- Try/catch for RefreshSpellList, in case it's not loaded yet
  if DM.GUI.RefreshSpellList then
    DM.GUI:RefreshSpellList()
  else
    DM:DebugMsg("WARNING: RefreshSpellList not found!")
  end

  -- Tooltip for resize button
  resizeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetText("Drag to resize", 1, 1, 1)
    GameTooltip:Show()
  end)

  resizeBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  -- Check ColorPickerFrame
  C_Timer.After(1, function()
    DM:DebugMsg("ColorPickerFrame check: exists = " .. (ColorPickerFrame ~= nil and "yes" or "no"))
    if ColorPickerFrame then
      DM:DebugMsg("ColorPickerFrame is a " .. type(ColorPickerFrame))
      DM:DebugMsg("ColorPickerFrame frame strata: " .. ColorPickerFrame:GetFrameStrata())
      DM:DebugMsg("ColorPickerFrame frame level: " .. ColorPickerFrame:GetFrameLevel())
      DM:DebugMsg("ColorPickerFrame parent: " ..
        (ColorPickerFrame:GetParent() and ColorPickerFrame:GetParent():GetName() or "none"))
    end
  end)

  DM:DebugMsg("GUI creation complete, frame exists: " .. (DM.GUI.frame and "Yes" or "No"))

  return frame
end
