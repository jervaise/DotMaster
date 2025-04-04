-- DotMaster gui_common.lua
-- Contains common GUI functionality and components

local DM = DotMaster
DotMaster_Components = {}

-- Create standardized info area for tabs
local function CreateTabInfoArea(parentFrame, titleText, explanationText)
  -- Create info area container
  local infoArea = CreateFrame("Frame", nil, parentFrame)
  infoArea:SetSize(430, 85) -- Increased height from 75px to 85px to accommodate more spacing
  infoArea:SetPoint("TOP", parentFrame, "TOP", 0, 0)

  -- Center container for text elements with equal top/bottom margins
  local textContainer = CreateFrame("Frame", nil, infoArea)
  textContainer:SetSize(430, 55)                             -- Increased height from 45px to 55px
  textContainer:SetPoint("CENTER", infoArea, "CENTER", 0, 0) -- Centered vertically

  -- Info Area Title
  local infoTitle = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  infoTitle:SetPoint("TOP", textContainer, "TOP", 0, 0)
  infoTitle:SetText(titleText)
  infoTitle:SetTextColor(1, 0.82, 0) -- WoW Gold

  -- Info Area Explanation
  local infoExplanation = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoExplanation:SetPoint("TOP", infoTitle, "BOTTOM", 0, -10) -- Increased spacing from -2 to -10
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

-- Add Combinations tab component function
DotMaster_Components.CreateCombinationsTab = function(parent)
  return DM:CreateCombinationsTab(parent)
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

  -- Check if Plater is missing and show a simplified error UI if so
  if DM.platerMissing then
    DM:DebugMsg("Showing simplified GUI due to missing Plater dependency")

    -- Create a simple error frame
    local frame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 200)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Register with UI special frames to enable Escape key closing
    tinsert(UISpecialFrames, "DotMasterOptionsFrame")

    -- Add a backdrop
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(1, 0, 0, 0.8) -- Red border for error
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("|cFFFF0000DotMaster Error|r")

    -- Error message
    local message = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -20)
    message:SetWidth(360)
    message:SetText(
      "This addon requires |cFFFF6A00Plater Nameplates|r to function.\n\nPlease install and enable Plater from CurseForge, WoWInterface, or Wago.")
    message:SetJustifyH("CENTER")

    -- Close Button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)
    closeButton:SetSize(26, 26)

    -- OK Button
    local okButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    okButton:SetSize(100, 25)
    okButton:SetPoint("BOTTOM", 0, 20)
    okButton:SetText("OK")
    okButton:SetScript("OnClick", function() frame:Hide() end)

    -- Store the frame reference
    DM.GUI.frame = frame
    return frame
  end

  -- Get the player's class color
  local playerClass = select(2, UnitClass("player"))
  local classColor = RAID_CLASS_COLORS[playerClass] or
      { r = 0.6, g = 0.2, b = 1.0 } -- Default to purple if no class color found

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

  -- Register with UI special frames to enable Escape key closing
  tinsert(UISpecialFrames, "DotMasterOptionsFrame")

  -- Make frame resizable if supported
  -- RESIZING FEATURE REMOVED

  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.8)                                        -- Darker background with better transparency
  frame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.8) -- Use class color for border
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
  -- Use class color for the title text
  title:SetText(string.format("|cFF%02x%02x%02xDotMaster|r",
    classColor.r * 255,
    classColor.g * 255,
    classColor.b * 255))

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

  for i = 1, 4 do
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
    if i == 1 then
      text:SetText("General")
    elseif i == 2 then
      text:SetText("Tracked Spells")
    elseif i == 3 then
      text:SetText("Combinations")
    else
      text:SetText("Database")
    end
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
      elseif self.id == 4 then -- Database tab (now index 4 instead of 3)
        -- Refresh database tab
        if DM.GUI.RefreshDatabaseTabList then
          DM:DatabaseDebug("Refreshing Database tab list")
          DM.GUI:RefreshDatabaseTabList("")
        end
      end
    end)

    -- Position tabs side by side with appropriate spacing
    -- Adjust width to fit 4 tabs
    local tabWidth = 115
    tabButton:SetSize(tabWidth, tabHeight)
    tabButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i - 1) * (tabWidth + 5), -40)
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

  -- Create Combinations tab content
  if DotMaster_Components.CreateCombinationsTab then
    DM:DatabaseDebug("Using DotMaster_Components.CreateCombinationsTab")
    DotMaster_Components.CreateCombinationsTab(tabFrames[3])
  else
    DM:DatabaseDebug("ERROR: CreateCombinationsTab function not found!")
  end

  -- Create Database tab content (now index 4 instead of 3)
  if DotMaster_Components.CreateDatabaseTab then
    DM:DatabaseDebug("Using DotMaster_Components.CreateDatabaseTab")
    DotMaster_Components.CreateDatabaseTab(tabFrames[4])
  else
    DM:DatabaseDebug("ERROR: CreateDatabaseTab function not found!")
  end

  -- Initialize GUI frame
  DM.GUI.frame = frame

  DM:DebugMsg("GUI creation complete, frame exists: " .. (DM.GUI.frame and "Yes" or "No"))

  return frame
end
