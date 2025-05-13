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

-- Store the info area creation function in the Components namespace
DotMaster_Components.CreateTabInfoArea = CreateTabInfoArea

-- Create the main GUI
function DM:CreateGUI()
  -- Get the player's class color
  local playerClass = select(2, UnitClass("player"))
  local classColor = RAID_CLASS_COLORS[playerClass] or { r = 0.6, g = 0.2, b = 1.0 }

  -- Track border thickness changes
  if not DM.originalBorderThickness then
    local settings = DM.API:GetSettings()
    DM.originalBorderThickness = settings.borderThickness
  end

  -- Create main frame
  local frame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(500, 600)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  -- Register with UI special frames to enable Escape key closing
  tinsert(UISpecialFrames, "DotMasterOptionsFrame")

  -- Add a backdrop
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

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

  -- Add force push on close
  closeButton:HookScript("OnClick", function()
    -- Force push to bokmaster with current settings
    if DM.InstallPlaterMod then
      DM:PrintMessage("Force pushing settings to bokmaster before closing...")
      DM:InstallPlaterMod()
    end
  end)

  -- Also hook the escape key closing
  frame:HookScript("OnHide", function()
    -- Get current settings from both DotMasterDB and API
    local settings = DM.API:GetSettings()

    -- Force refresh settings from DotMasterDB to ensure we have the latest values
    if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness then
      settings.borderThickness = DotMasterDB.settings.borderThickness
      print("|cFFFF9900DotMaster-Debug: Refreshed border thickness from DotMasterDB: " ..
        settings.borderThickness .. "|r")
    end

    -- Force push to bokmaster with current settings when window is closed by any means
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
    end

    -- Direct check for border thickness change to ensure popup appears
    if DM.originalBorderThickness and settings.borderThickness and
        DM.originalBorderThickness ~= settings.borderThickness then
      print("|cFFFF9900DotMaster-Debug: Border thickness changed from " ..
        DM.originalBorderThickness .. " to " .. settings.borderThickness .. " - showing popup|r")

      -- Create popup directly
      StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"] = {
        text = "Border thickness has changed from " .. DM.originalBorderThickness ..
            " to " .. settings.borderThickness ..
            ".\n\nReload UI to fully apply this change?",
        button1 = "Reload Now",
        button2 = "Later",
        OnAccept = function()
          ReloadUI()
        end,
        OnCancel = function()
          DM:PrintMessage("Remember to reload your UI to fully apply border thickness changes.")
          -- Update the stored original value to prevent repeated prompts
          DM.originalBorderThickness = settings.borderThickness
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("DOTMASTER_RELOAD_CONFIRM")
    else
      print("|cFFFF9900DotMaster-Debug: Final thickness check - Original: " ..
        (DM.originalBorderThickness or "nil") .. " Current: " ..
        (settings.borderThickness or "nil") .. "|r")

      -- Use the standard function as a fallback
      if DM.ShowReloadUIPopupForBorderThickness then
        DM:ShowReloadUIPopupForBorderThickness()
      end
    end
  end)

  -- Author credit
  local author = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  author:SetPoint("BOTTOM", 0, 12) -- Increase from 5 to 12 to add more space
  -- Read version from API first, then SavedVariables, fallback to defaults if not found
  local versionString = (DM.API and DM.API.GetVersion and DM.API:GetVersion()) or
      (DotMasterDB and DotMasterDB.version) or
      (DM.defaults and DM.defaults.version) or "N/A"
  author:SetText("by Jervaise - v" .. versionString)

  -- Create a footer frame that will contain global buttons
  local footerFrame = CreateFrame("Frame", "DotMasterFooterFrame", frame)
  footerFrame:SetHeight(45)                                       -- Increased from 40 to 45
  footerFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 25) -- Increased y-offset from 20 to 25
  footerFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 25)

  -- Add a subtle separator line at the top of the footer
  local separator = footerFrame:CreateTexture(nil, "ARTWORK")
  separator:SetHeight(1)
  separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
  separator:SetPoint("TOPLEFT", footerFrame, "TOPLEFT", 0, 0)
  separator:SetPoint("TOPRIGHT", footerFrame, "TOPRIGHT", 0, 0)

  -- Create the save button in the footer with class-colored styling
  local saveButton = CreateFrame("Button", "DotMasterSaveButton", footerFrame, "UIPanelButtonTemplate")
  saveButton:SetSize(140, 24)
  saveButton:SetPoint("CENTER", footerFrame, "CENTER", 0, 0) -- Centered vertically in the footer
  saveButton:SetText("Save Settings")
  saveButton:Hide()                                          -- Hide the save button since we're auto-saving

  -- Add a status message text in place of the save button
  local statusMessage = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  statusMessage:SetPoint("CENTER", footerFrame, "CENTER", 0, 0)
  statusMessage:SetText("Auto-saving: Enabled")
  statusMessage:SetTextColor(0.7, 0.7, 0.7)
  DM.GUI.statusMessage = statusMessage -- Store reference for later updates

  -- Add a subtle class-colored glow to the save button
  if classColor then
    local normalTexture = saveButton:GetNormalTexture()
    if normalTexture then
      normalTexture:SetVertexColor(
        classColor.r * 0.7 + 0.3,
        classColor.g * 0.7 + 0.3,
        classColor.b * 0.7 + 0.3
      )
    end
  end

  saveButton:SetScript("OnClick", function()
    -- Save DotMaster configuration
    DM.API:SaveSettings(DM.API:GetSettings())

    -- Push to Plater
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
    end

    -- Update class/spec specific settings
    if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
      DM.ClassSpec:SaveCurrentSettings()
    end

    DM:PrintMessage("Settings saved and pushed to Plater")
  end)

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
    tabFrames[i]:SetPoint("BOTTOMRIGHT", -10, 60) -- Increased from 30 to 60 to make room for footer
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
          DM.GUI:RefreshTrackedSpellTabList("")
        end
      elseif self.id == 4 then -- Database tab (now index 4 instead of 3)
        -- Refresh database tab
        if DM.GUI.RefreshDatabaseTabList then
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
    DM:CreateGeneralTab(tabFrames[1])
  elseif DotMaster_Components.CreateGeneralTab then
    DotMaster_Components.CreateGeneralTab(tabFrames[1])
  else
    print("Error: CreateGeneralTab function not found!")
  end

  -- Create Tracked Spells tab content
  if DotMaster_Components.CreateTrackedSpellsTab then
    DotMaster_Components.CreateTrackedSpellsTab(tabFrames[2])
  else
    print("Error: CreateTrackedSpellsTab function not found!")
  end

  -- Create Combinations tab content
  if DotMaster_Components.CreateCombinationsTab then
    DotMaster_Components.CreateCombinationsTab(tabFrames[3])
  else
    print("Error: CreateCombinationsTab function not found!")
  end

  -- Create Database tab content (now index 4 instead of 3)
  if DotMaster_Components.CreateDatabaseTab then
    DotMaster_Components.CreateDatabaseTab(tabFrames[4])
  else
    print("Error: CreateDatabaseTab function not found!")
  end

  -- Initialize GUI frame
  DM.GUI.frame = frame

  return frame
end
