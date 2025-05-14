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

-- Function to update Plater Integration status in the footer
function DM:UpdatePlaterStatusFooter()
  if not DM.GUI.statusMessage then return end -- Safety check

  local Plater = _G["Plater"]
  local statusText = "Plater Integration: "
  local r, g, b = 1, 0, 0 -- Default to red (error color)
  local showButton = false

  if Plater and Plater.db and Plater.db.profile and Plater.db.profile.hook_data then
    local dotMasterIntegrationFound = false
    -- Iterate through Plater hook_data, which can be an array or a table
    local hookData = Plater.db.profile.hook_data
    if type(hookData) == "table" then
      for modName, modData in pairs(hookData) do
        -- Check if the mod name is "DotMaster Integration" or if the modData itself has a Name field (for array-like tables)
        if modName == "DotMaster Integration" or (type(modData) == "table" and modData.Name == "DotMaster Integration") then
          local actualMod = type(modData) == "table" and modData or hookData -- Get the actual mod table
          if actualMod.Hooks and actualMod.Hooks["Nameplate Updated"] then
            if type(actualMod.Hooks["Nameplate Updated"]) == "string" and string.find(actualMod.Hooks["Nameplate Updated"], "envTable.DM_SPELLS", 1, true) then
              dotMasterIntegrationFound = true
              break
            end
          end
        end
      end
      -- Fallback for array-like structure if not found as direct keys
      if not dotMasterIntegrationFound then
        for i, mod in ipairs(hookData) do
          if mod.Name == "DotMaster Integration" and mod.Hooks and mod.Hooks["Nameplate Updated"] then
            if type(mod.Hooks["Nameplate Updated"]) == "string" and string.find(mod.Hooks["Nameplate Updated"], "envTable.DM_SPELLS", 1, true) then
              dotMasterIntegrationFound = true
              break
            end
          end
        end
      end
    end

    if dotMasterIntegrationFound then
      statusText = statusText .. "Active"
      r, g, b = 1, 1, 1 -- White for active
      showButton = false
    else
      statusText = statusText .. "Error (DotMaster Integration mod not found or misconfigured)"
      --showButton = true -- Original behavior was error text, now we show button
      r, g, b = 1, 0, 0 -- Error color for the text (though it might be hidden)
      showButton = true
    end
  else
    statusText = statusText .. "Error (Plater AddOn not detected or profile inaccessible)"
    showButton = false
  end

  DM.GUI.statusMessage:SetText(statusText)
  DM.GUI.statusMessage:SetTextColor(r, g, b)

  if showButton then
    DM.GUI.statusMessage:Hide()
    if DM.GUI.platerIntegrationButton then
      DM.GUI.platerIntegrationButton:Show()
    end
  else
    DM.GUI.statusMessage:Show()
    if DM.GUI.platerIntegrationButton then
      DM.GUI.platerIntegrationButton:Hide()
    end
  end
end

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
    -- Force push to DotMaster Integration with current settings
    if DM.InstallPlaterMod then
      DM:PrintMessage("Force pushing settings to DotMaster Integration before closing...")
      DM:InstallPlaterMod()
      -- Update footer after attempting to install
      if DM.UpdatePlaterStatusFooter then DM:UpdatePlaterStatusFooter() end
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

    -- Force push to DotMaster Integration with current settings when window is closed by any means
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
      -- Update footer after attempting to install, before GUI fully hides
      if DM.UpdatePlaterStatusFooter then DM:UpdatePlaterStatusFooter() end
    end

    -- Make sure original settings are initialized (safety check)
    if not DM.originalBorderThickness then
      DM.originalBorderThickness = settings.borderThickness
      print("|cFFFF9900DotMaster-Debug: No original thickness - initializing to " .. settings.borderThickness .. "|r")
    end

    if not DM.originalBorderOnly then
      DM.originalBorderOnly = settings.borderOnly and true or false
      print("|cFFFF9900DotMaster-Debug: No original border-only - initializing to " ..
        (settings.borderOnly and "ENABLED" or "DISABLED") .. "|r")
    end

    if not DM.originalEnabled then
      DM.originalEnabled = settings.enabled and true or false
      print("|cFFFF9900DotMaster-Debug: No original enabled - initializing to " ..
        (settings.enabled and "ENABLED" or "DISABLED") .. "|r")
    end

    -- Use the standard function with improved checks to show popup if needed
    if DM.ShowReloadUIPopupForBorderThickness then
      DM:ShowReloadUIPopupForBorderThickness()
    else
      print("|cFFFF9900DotMaster-Debug: ShowReloadUIPopupForBorderThickness function not available|r")
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
  -- Initial text will be set by UpdatePlaterStatusFooter
  statusMessage:SetText("Plater Integration: Initializing...")
  statusMessage:SetTextColor(0.7, 0.7, 0.7) -- Neutral color initially
  DM.GUI.statusMessage = statusMessage      -- Store reference for later updates

  -- Create Plater Integration button (initially hidden)
  local platerIntegrationButton = CreateFrame("Button", "DotMasterPlaterIntegrationButton", footerFrame,
    "UIPanelButtonTemplate")
  platerIntegrationButton:SetSize(160, 24) -- Adjusted size to be more prominent
  platerIntegrationButton:SetPoint("CENTER", footerFrame, "CENTER", 0, 0)
  platerIntegrationButton:SetText("Plater Integration")
  platerIntegrationButton:SetScript("OnClick", function()
    local modString =
    "!PLATER:2!PY/BasJAFEUr+BN11UW3lhitibsOnSixhNqF0EWgPGZe4pA4b5gZg3U139OF39ikSJeXey6ce2WzPSdfgPNoH3LtsbbgFWnuvw3yA1HD5i8s/pwPna1AYMmkfNeu/J+VBUoFpSR//MtTJUg/+RrY8+TwOLZssdui7UDJBqdvcLlAw5IRW47ZKrD0Z+2hRe1DVls6mZCJFpwLmyOYLyVd4JZaDLnpzI3jzqAIGVSVOocCtaDToHaDe8Hwus/5R3RepvEiWsziZJVGSZpuPYkOrevPTe5G1/sMpCS93rXQrzdkhtcu/AI="

    if _G["Plater"] then
      if type(_G["Plater"].ImportScriptString) == "function" then
        DM:PrintMessage("Attempting to import DotMaster Integration mod into Plater using Plater.ImportScriptString...")
        -- Calling Plater.ImportScriptString(text, ignoreRevision, overrideTriggers, showDebug, keepExisting)
        local success, importedObject, wasEnabled = _G["Plater"].ImportScriptString(modString, true, false, true, false)

        if success and importedObject then
          DM:PrintMessage("DotMaster Integration mod import reported success by Plater. Imported object name: " ..
            (importedObject.Name or "Unknown Name"))

          -- Ensure the mod is enabled
          if not importedObject.Enabled then
            if type(_G["Plater"].EnableHook) == "function" then
              _G["Plater"].EnableHook(importedObject) -- Try to enable it
              DM:PrintMessage("Attempted to enable the imported Plater mod as it was not enabled.")
              -- Plater might require a recompile after enabling a hook
              if type(_G["Plater"].CompileHook) == "function" then
                _G["Plater"].CompileHook(importedObject)
                DM:PrintMessage("Attempted to recompile the Plater mod.")
              elseif type(_G["Plater"].CompileAllHooksAndScripts) == "function" then
                _G["Plater"].CompileAllHooksAndScripts()
                DM:PrintMessage("Attempted to recompile all Plater hooks and scripts.")
              end
            else
              DM:PrintMessage("Imported mod is not enabled, and Plater.EnableHook function not found.")
            end
          else
            DM:PrintMessage("Imported Plater mod is already enabled.")
          end

          -- Refresh the footer status immediately after successful import and enabling attempt
          if DM.UpdatePlaterStatusFooter then
            DM:UpdatePlaterStatusFooter()
          end

          -- After a short delay, call InstallPlaterMod to push current settings to the newly imported/updated Plater mod
          C_Timer.After(0.5, function()
            if DM.InstallPlaterMod then
              DM:PrintMessage(
                "DotMaster: Delay finished. Running InstallPlaterMod to sync settings with the Plater mod.")
              DM:InstallPlaterMod()
              -- After InstallPlaterMod, refresh the footer again to ensure it reflects the latest state.
              if DM.UpdatePlaterStatusFooter then
                DM:PrintMessage("DotMaster: Refreshing footer status after InstallPlaterMod.")
                DM:UpdatePlaterStatusFooter()
              end
            else
              DM:PrintMessage("DotMaster: DM.InstallPlaterMod function not found. Cannot sync settings after delay.")
            end
          end)
        else
          DM:PrintMessage(
            "Plater.ImportScriptString executed, but it did not return success or a valid imported object. Plater's internal debug messages (if any) might provide more details.")
        end
      else
        DM:PrintMessage(
          "Plater addon IS LOADED, but its ImportScriptString function was not found or is not a function. This is the primary function needed for import.")
      end
    else
      DM:PrintMessage(
        "Plater addon IS NOT LOADED (or _G[\"Plater\"] is nil). Cannot import DotMaster Integration mod. Please ensure Plater is enabled.")
    end
  end)
  platerIntegrationButton:Hide()
  DM.GUI.platerIntegrationButton = platerIntegrationButton

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

  -- Call initial status update after GUI elements are created
  if DM.UpdatePlaterStatusFooter then
    DM:UpdatePlaterStatusFooter()
  end

  return frame
end
