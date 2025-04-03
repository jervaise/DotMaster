-- DotMaster gui_common.lua
-- Contains common GUI functionality and components

local DM = DotMaster
DotMaster_Components = {}

-- Create standardized info area for tabs
local function CreateTabInfoArea(parentFrame, titleText, explanationText)
  -- Create info area container
  local infoArea = CreateFrame("Frame", nil, parentFrame)
  infoArea:SetSize(430, 75) -- 75px height
  infoArea:SetPoint("TOP", parentFrame, "TOP", 0, 0)

  -- Center container for text elements with equal top/bottom margins
  local textContainer = CreateFrame("Frame", nil, infoArea)
  textContainer:SetSize(430, 45)                             -- Reduced height to allow for margins
  textContainer:SetPoint("CENTER", infoArea, "CENTER", 0, 0) -- Centered vertically

  -- Info Area Title
  local infoTitle = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  infoTitle:SetPoint("TOP", textContainer, "TOP", 0, 0)
  infoTitle:SetText(titleText)
  infoTitle:SetTextColor(1, 0.82, 0) -- WoW Gold

  -- Info Area Explanation
  local infoExplanation = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoExplanation:SetPoint("TOP", infoTitle, "BOTTOM", 0, -2)
  infoExplanation:SetWidth(300)
  infoExplanation:SetJustifyH("CENTER")
  infoExplanation:SetText(explanationText)
  infoExplanation:SetTextColor(0.8, 0.8, 0.8)

  return infoArea
end

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

-- Store the info area creation function in the Components namespace
DotMaster_Components.CreateTabInfoArea = CreateTabInfoArea

-- Create the main GUI
function DM:CreateGUI()
  DM:DebugMsg("Creating GUI...")

  -- Main frame
  local frame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(500, 650) -- Increased frame size for better content display
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Make frame resizable if supported
  -- RESIZING FEATURE REMOVED

  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.8)             -- Darker background with better transparency
  frame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8) -- Keep the purple border
  frame:Hide()

  -- Define size constraints as fixed values now (no resizing)
  local minWidth, minHeight = 500, 650
  local maxWidth, maxHeight = 500, 650
  local isResizing = false

  -- Resize button and functionality removed

  -- Simple OnSizeChanged handler just to enforce fixed size
  frame:SetScript("OnSizeChanged", function(self, width, height)
    -- Always enforce our fixed size if it somehow changes
    if width ~= minWidth or height ~= minHeight then
      self:SetSize(minWidth, minHeight)
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
  author:SetPoint("BOTTOM", 0, 15) -- Keep increased bottom margin
  -- Read version from SavedVariables, fallback to defaults if not found
  local versionString = (DotMasterDB and DotMasterDB.version) or (DM.defaults and DM.defaults.version) or "N/A"
  author:SetText("by Jervaise - v" .. versionString)

  -- Create tab system
  local tabHeight = 30
  local tabFrames = {}
  local activeTab = 1

  -- Tab background
  local tabBg = frame:CreateTexture(nil, "BACKGROUND")
  tabBg:SetPoint("TOPLEFT", 8, -40)
  tabBg:SetPoint("TOPRIGHT", -8, -40)
  tabBg:SetHeight(tabHeight)
  tabBg:SetColorTexture(0, 0, 0, 0.6) -- Match debug window transparency

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
    normalTexture:SetColorTexture(0, 0, 0, 0.7) -- Darker background with better transparency

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
        tab:GetRegions():SetColorTexture(0, 0, 0, 0.7) -- Match debug window style
      end

      -- Show selected frame and highlight tab
      tabFrames[self.id]:Show()
      self:GetRegions():SetColorTexture(0.2, 0.2, 0.2, 0.8) -- Slightly lighter for selected tab
      activeTab = self.id

      -- Refresh appropriate tab content when clicked
      if self.id == 2 then -- Tracked Spells tab
        -- Refresh tracked spells tab
        if DM.GUI.RefreshTrackedSpellTabList then
          DM:DatabaseDebug("Refreshing Tracked Spells tab list")
          DM.GUI:RefreshTrackedSpellTabList("")
        end
      elseif self.id == 3 then -- Database tab
        -- Refresh database tab
        if DM.GUI.RefreshDatabaseTabList then
          DM:DatabaseDebug("Refreshing Database tab list")
          DM.GUI:RefreshDatabaseTabList("")
        end
      end
    end)

    -- Position tabs side by side with appropriate spacing
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

  -- Create Tracked Spells tab content
  if DotMaster_Components.CreateTrackedSpellsTab then
    DM:DatabaseDebug("Using DotMaster_Components.CreateTrackedSpellsTab")
    DotMaster_Components.CreateTrackedSpellsTab(tabFrames[2])
  else
    DM:DatabaseDebug("ERROR: CreateTrackedSpellsTab function not found!")
  end

  -- Create Database tab content
  if DotMaster_Components.CreateDatabaseTab then
    DM:DatabaseDebug("Using DotMaster_Components.CreateDatabaseTab")
    DotMaster_Components.CreateDatabaseTab(tabFrames[3])
  else
    DM:DatabaseDebug("ERROR: CreateDatabaseTab function not found!")
  end

  -- Initialize GUI frame
  DM.GUI.frame = frame

  DM:DebugMsg("GUI creation complete, frame exists: " .. (DM.GUI.frame and "Yes" or "No"))

  return frame
end
