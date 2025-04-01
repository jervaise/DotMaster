--[[
  DotMaster - Find My Dots UI Module

  File: fmd_ui.lua
  Purpose: User interface components for Find My Dots functionality

  Functions:
    ShowRecordingIndicator(): Creates and shows the recording UI
    HideRecordingIndicator(): Hides the recording UI
    ShowDetectedDotNotification(): Shows notification when a dot is detected
    ShowDotsConfirmationDialog(): Shows confirmation dialog for detected dots
    ShowFindMyDotsPrompt(): Shows initial help prompt if no spells detected
    UpdateScrollChildHeight(): Helper function to update scroll child height
    GetClassDisplayName(): Helper function to get class display name

  Dependencies:
    DotMaster core
    fmd_core.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster
local FindMyDots = DM.FindMyDots

-- Create UI module table
local FindMyDotsUI = {}
DM.FindMyDotsUI = FindMyDotsUI

-- UI Elements
local recordingFrame = nil
local recordingText = nil
local recordingTime = nil
local dotsFoundText = nil
local finishButton = nil
local cancelButton = nil
local recordingTicker = nil
local dotAlertContainer = nil
local dotsConfirmFrame = nil
local dotCheckboxes = {}
local dotsScrollChild = nil
local scrollFrame = nil

-- Visual feedback functions
function FindMyDotsUI:ShowRecordingIndicator()
  if not recordingFrame then
    -- Create recording frame with modern WoW style
    recordingFrame = CreateFrame("Frame", "DotMasterRecordingFrame", UIParent, "BackdropTemplate")
    recordingFrame:SetSize(400, 30)
    recordingFrame:SetPoint("TOP", 0, -50)

    -- Background with gradient
    local bg = recordingFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)

    -- Purple border like DotMaster main UI
    recordingFrame:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
      edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    recordingFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    recordingFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8) -- Purple border to match DotMaster style

    -- Text with better layout
    recordingText = recordingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recordingText:SetPoint("LEFT", 20, 0)
    recordingText:SetText("DOT RECORDING MODE ACTIVE")
    recordingText:SetTextColor(1, 0.82, 0) -- Gold color like WoW UI

    -- Time indicator
    recordingTime = recordingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    recordingTime:SetPoint("LEFT", recordingText, "RIGHT", 10, 0)
    recordingTime:SetText("30s")
    recordingTime:SetTextColor(1, 1, 1)

    -- Dot counter
    dotsFoundText = recordingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dotsFoundText:SetPoint("RIGHT", recordingFrame, "RIGHT", -100, 0)
    dotsFoundText:SetText("0 DOT BULUNDU")
    dotsFoundText:SetTextColor(0.3, 1, 0.3) -- Green color

    -- Button container for better layout
    local buttonContainer = CreateFrame("Frame", nil, recordingFrame)
    buttonContainer:SetSize(170, 22)
    buttonContainer:SetPoint("RIGHT", -10, 0)

    -- Finish button with WoW style
    finishButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    finishButton:SetSize(80, 22)
    finishButton:SetPoint("LEFT", 0, 0)
    finishButton:SetText("Finish")

    finishButton:SetScript("OnClick", function()
      -- Stop recording but don't mark as automatic/canceled
      FindMyDots:StopFindMyDots(false, true) -- Pass true as second param to indicate finished
    end)

    -- Cancel button with WoW style
    cancelButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 22)
    cancelButton:SetPoint("RIGHT", 0, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function() FindMyDots:StopFindMyDots() end)
  end

  -- Make visible
  recordingFrame:Show()

  -- Update remaining time
  local recordingTimeLeft = 30

  -- Timer
  if recordingTicker then
    recordingTicker:Cancel()
  end

  recordingTicker = C_Timer.NewTicker(1, function()
    recordingTimeLeft = recordingTimeLeft - 1
    if recordingTime then
      recordingTime:SetText(string.format("%ds", recordingTimeLeft))

      -- Color change based on time remaining
      if recordingTimeLeft <= 5 then
        recordingTime:SetTextColor(1, 0, 0)   -- Red when time is running out
      elseif recordingTimeLeft <= 10 then
        recordingTime:SetTextColor(1, 0.5, 0) -- Orange when time is getting low
      else
        recordingTime:SetTextColor(1, 1, 1)   -- White otherwise
      end
    end
  end)
end

function FindMyDotsUI:HideRecordingIndicator()
  if recordingFrame and recordingFrame.Hide then
    recordingFrame:Hide()
  end

  if recordingTicker then
    recordingTicker:Cancel()
    recordingTicker = nil
  end
end

-- Show minimal, clean visual feedback when a spell is detected
function FindMyDotsUI:ShowDetectedDotNotification(name, id)
  -- Skip already shown notifications for this session
  if not self.shownNotifications then self.shownNotifications = {} end
  if self.shownNotifications[id] then return end

  -- Mark as shown
  self.shownNotifications[id] = true

  -- Main notification container
  if not dotAlertContainer then
    dotAlertContainer = CreateFrame("Frame", "DotMasterAlertContainer", UIParent)
    dotAlertContainer:SetSize(300, 120) -- Space for 3 rows

    -- Position below the Find My Dots timer bar
    if recordingFrame then
      dotAlertContainer:SetPoint("TOP", recordingFrame, "BOTTOM", 0, -5)
    else
      dotAlertContainer:SetPoint("TOP", UIParent, "TOP", 0, -80)
    end

    dotAlertContainer.frames = {}
    dotAlertContainer.maxDisplayed = 3 -- Max 3 rows display
  end

  -- Notification dimensions
  local NOTIFICATION_HEIGHT = 36
  local NOTIFICATION_SPACING = 4

  -- Maximum number of notifications to display
  local maxDisplayed = dotAlertContainer.maxDisplayed or 3

  -- Remove oldest notification if we're at max
  if #dotAlertContainer.frames >= maxDisplayed then
    local oldestFrame = dotAlertContainer.frames[#dotAlertContainer.frames]

    -- Exit animation for old notification
    local exitAnimGroup = oldestFrame:CreateAnimationGroup()

    -- Fade out animation
    local fadeOut = exitAnimGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("OUT")

    exitAnimGroup:SetScript("OnFinished", function()
      oldestFrame:Hide()

      -- Remove from container
      table.remove(dotAlertContainer.frames, #dotAlertContainer.frames)
    end)

    exitAnimGroup:Play()
  end

  -- Create a new alert frame for this spell
  local alertFrame = CreateFrame("Frame", nil, dotAlertContainer, "BackdropTemplate")
  alertFrame:SetSize(280, NOTIFICATION_HEIGHT)

  -- Position first notification at top, others below
  if #dotAlertContainer.frames == 0 then
    alertFrame:SetPoint("TOP", dotAlertContainer, "TOP", 0, 0)
  else
    -- Position below last visible notification
    alertFrame:SetPoint("TOP", dotAlertContainer, "TOP", 0,
      -(#dotAlertContainer.frames * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
  end

  -- Modern design background
  alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })

  -- Class color settings
  local className = select(2, UnitClass("player")) or "UNKNOWN"
  local classColor = DM.classColors[className] or { r = 0.5, g = 0, b = 0.7 }

  alertFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  alertFrame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.8)

  -- Add subtle glow effect
  local bgGlow = alertFrame:CreateTexture(nil, "BACKGROUND")
  bgGlow:SetPoint("TOPLEFT", -2, 2)
  bgGlow:SetPoint("BOTTOMRIGHT", 2, -2)
  bgGlow:SetTexture("Interface\\GLUES\\MODELS\\UI_Tauren\\gradientCircle")
  bgGlow:SetBlendMode("ADD")
  bgGlow:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.1)

  -- Add to container at the beginning of the array
  table.insert(dotAlertContainer.frames, 1, alertFrame)

  -- Update positions of all notifications
  for i, frame in ipairs(dotAlertContainer.frames) do
    if frame and frame:IsShown() then
      frame:ClearAllPoints()
      frame:SetPoint("TOP", dotAlertContainer, "TOP", 0, -((i - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
    end
  end

  -- Spell icon
  local icon = alertFrame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(28, 28)
  icon:SetPoint("LEFT", 8, 0)

  -- Use standard purple icon
  icon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

  -- Add icon border
  local border = alertFrame:CreateTexture(nil, "BORDER")
  border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
  border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  border:SetBlendMode("ADD")
  border:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)

  -- Spell text layout
  local spellText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  spellText:SetPoint("LEFT", icon, "RIGHT", 10, 4)
  spellText:SetText(name)
  spellText:SetTextColor(1, 0.82, 0) -- Gold

  -- Spell ID text
  local idText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  idText:SetPoint("TOPLEFT", spellText, "BOTTOMLEFT", 0, -2)
  idText:SetText("ID: " .. id)
  idText:SetTextColor(0.7, 0.7, 0.7) -- Gray

  -- Fade in animation
  alertFrame:SetAlpha(0)
  alertFrame:Show()

  local animGroup = alertFrame:CreateAnimationGroup()

  -- Alpha animation (fade in)
  local fadeIn = animGroup:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.3)
  fadeIn:SetSmoothing("IN_OUT")

  -- Add glow effect
  local glow = alertFrame:CreateTexture(nil, "OVERLAY")
  glow:SetPoint("TOPLEFT", -5, 5)
  glow:SetPoint("BOTTOMRIGHT", 5, -5)
  glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
  glow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
  glow:SetAlpha(0)
  glow:SetBlendMode("ADD")

  local glowAnim = animGroup:CreateAnimation("Alpha")
  glowAnim:SetTarget(glow)
  glowAnim:SetFromAlpha(0)
  glowAnim:SetToAlpha(0.7)
  glowAnim:SetDuration(0.3)
  glowAnim:SetSmoothing("IN")

  local glowFadeOut = animGroup:CreateAnimation("Alpha")
  glowFadeOut:SetTarget(glow)
  glowFadeOut:SetStartDelay(0.3)
  glowFadeOut:SetFromAlpha(0.7)
  glowFadeOut:SetToAlpha(0)
  glowFadeOut:SetDuration(0.5)
  glowFadeOut:SetSmoothing("OUT")

  animGroup:SetScript("OnFinished", function()
    -- Leave at full visibility
    alertFrame:SetAlpha(1)
  end)

  -- Start animation
  animGroup:Play()

  -- Fade out after 4 seconds
  C_Timer.After(4, function()
    if not alertFrame or not alertFrame:IsShown() then return end

    local exitAnimGroup = alertFrame:CreateAnimationGroup()

    -- Fade out animation
    local fadeOut = exitAnimGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("OUT")

    exitAnimGroup:SetScript("OnFinished", function()
      alertFrame:Hide()

      -- Remove frame from container
      for i, frame in ipairs(dotAlertContainer.frames) do
        if frame == alertFrame then
          table.remove(dotAlertContainer.frames, i)
          -- Update positions of remaining notifications
          for j, remainingFrame in ipairs(dotAlertContainer.frames) do
            if remainingFrame and remainingFrame:IsShown() then
              remainingFrame:ClearAllPoints()
              remainingFrame:SetPoint("TOP", dotAlertContainer, "TOP", 0,
                -((j - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
            end
          end
          break
        end
      end
    end)

    exitAnimGroup:Play()
  end)
end

function FindMyDotsUI:ShowDotsConfirmationDialog(dots)
  -- Confirmation dialog for detected dots
  if not dotsConfirmFrame then
    dotsConfirmFrame = CreateFrame("Frame", "DotMasterDotsConfirm", UIParent, "BackdropTemplate")
    dotsConfirmFrame:SetFrameStrata("DIALOG")
    dotsConfirmFrame:SetSize(450, 350) -- Increased size for better layout
    dotsConfirmFrame:SetPoint("CENTER")

    -- Background and border
    dotsConfirmFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    dotsConfirmFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    dotsConfirmFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)

    -- Title
    local title = dotsConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Detected Dots")

    -- Description
    local desc = dotsConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Select dots you want to add")
    desc:SetTextColor(1, 0.82, 0)

    -- Scroll frame for dots list
    scrollFrame = CreateFrame("ScrollFrame", nil, dotsConfirmFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(400, 200) -- Wider scroll frame
    scrollFrame:SetPoint("TOP", desc, "BOTTOM", 0, -20)

    dotsScrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(dotsScrollChild)
    dotsScrollChild:SetSize(380, 10) -- Will be adjusted dynamically

    -- Buttons at the bottom
    local buttonContainer = CreateFrame("Frame", nil, dotsConfirmFrame)
    buttonContainer:SetSize(400, 25)
    buttonContainer:SetPoint("BOTTOM", 0, 15)

    -- Select All button
    local selectAllButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    selectAllButton:SetSize(120, 25)
    selectAllButton:SetPoint("LEFT", 20, 0)
    selectAllButton:SetText("Select All")

    -- Select None button
    local selectNoneButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    selectNoneButton:SetSize(120, 25)
    selectNoneButton:SetPoint("CENTER", 0, 0)
    selectNoneButton:SetText("Select None")

    -- Add Selected button
    local addButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    addButton:SetSize(120, 25)
    addButton:SetPoint("RIGHT", -20, 0)
    addButton:SetText("Add Selected")

    -- Close button at the top right
    local closeButton = CreateFrame("Button", nil, dotsConfirmFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    -- Hide frame
    closeButton:SetScript("OnClick", function()
      dotsConfirmFrame:Hide()
    end)

    -- Select All functionality
    selectAllButton:SetScript("OnClick", function()
      for id, checkbox in pairs(dotCheckboxes) do
        checkbox:SetChecked(true)
      end
    end)

    -- Select None functionality
    selectNoneButton:SetScript("OnClick", function()
      for id, checkbox in pairs(dotCheckboxes) do
        checkbox:SetChecked(false)
      end
    end)

    -- Add selected dots
    addButton:SetScript("OnClick", function()
      local added = 0

      for id, checkbox in pairs(dotCheckboxes) do
        if checkbox:GetChecked() then
          local dotInfo = dots[tonumber(id)]
          if dotInfo and not DM:SpellExists(id) then
            -- Create new dot configuration
            DM.spellConfig[tostring(id)] = {
              enabled = true,
              color = { 1, 0, 0 }, -- Default red color
              name = dotInfo.name,
              priority = DM:GetNextPriority()
            }
            added = added + 1
          end
        end
      end

      -- Update GUI and save settings
      if DM.GUI and DM.GUI.RefreshSpellList then
        DM.GUI:RefreshSpellList()
      end

      DM:SaveSettings()
      DM:PrintMessage(string.format("%d dots successfully added!", added))
      dotsConfirmFrame:Hide()
    end)
  end

  -- Clear dot list
  if dotsScrollChild then
    local children = { dotsScrollChild:GetChildren() }
    for _, child in pairs(children) do
      if type(child) == "table" then
        pcall(function() child:Hide() end)
        pcall(function() child:SetParent(nil) end)
      end
    end
  end

  -- Clear checkboxes
  dotCheckboxes = {}

  -- Display dots in a simple list
  local yOffset = 10

  -- Sort dots by name
  local sortedDots = {}
  for id, dotInfo in pairs(dots) do
    table.insert(sortedDots, { id = id, name = dotInfo.name, info = dotInfo })
  end

  table.sort(sortedDots, function(a, b)
    return a.name < b.name
  end)

  -- Create a row for each dot
  for _, dotData in ipairs(sortedDots) do
    local id = dotData.id
    local dotInfo = dotData.info

    -- Create row
    local row = CreateFrame("Frame", nil, dotsScrollChild)
    row:SetSize(370, 30)
    row:SetPoint("TOPLEFT", 5, -yOffset)

    -- Row background for alternating colors
    local rowBg = row:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints()
    if yOffset % 60 < 30 then
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
    dotCheckboxes[tostring(id)] = checkbox

    -- Spell name and ID
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    text:SetText(string.format("%s (ID: %d)", dotInfo.name, id))

    yOffset = yOffset + 30
  end

  -- Update scroll child height
  dotsScrollChild:SetHeight(math.max(yOffset + 10, 180))

  -- Show confirmation dialog
  if dotsConfirmFrame then
    pcall(function() dotsConfirmFrame:Show() end)
  end
end

-- Show prompt for first-time users
function FindMyDotsUI:ShowFindMyDotsPrompt()
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
      FindMyDots:StartFindMyDots()
    end)

    -- Close button
    local closeButton = CreateFrame("Button", nil, self.promptFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)
  end

  if self.promptFrame.Show then
    self.promptFrame:Show()
  end
end

-- Helper function to get class display name
function FindMyDotsUI:GetClassDisplayName(className)
  local classNames = {
    ["DEATHKNIGHT"] = "Death Knight",
    ["DEMONHUNTER"] = "Demon Hunter",
    ["DRUID"] = "Druid",
    ["HUNTER"] = "Hunter",
    ["MAGE"] = "Mage",
    ["MONK"] = "Monk",
    ["PALADIN"] = "Paladin",
    ["PRIEST"] = "Priest",
    ["ROGUE"] = "Rogue",
    ["SHAMAN"] = "Shaman",
    ["WARLOCK"] = "Warlock",
    ["WARRIOR"] = "Warrior",
    ["EVOKER"] = "Evoker",
    ["UNKNOWN"] = "Other Spells"
  }

  return classNames[className] or className
end

-- Initialize the module
function FindMyDotsUI:Initialize()
  -- Connect to core module
  FindMyDots.ShowRecordingIndicator = function(self) FindMyDotsUI:ShowRecordingIndicator() end
  FindMyDots.HideRecordingIndicator = function(self) FindMyDotsUI:HideRecordingIndicator() end
  FindMyDots.ShowDetectedDotNotification = function(self, name, id) FindMyDotsUI:ShowDetectedDotNotification(name, id) end
  FindMyDots.ShowDotsConfirmationDialog = function(self, dots) FindMyDotsUI:ShowDotsConfirmationDialog(dots) end

  -- Add to DM namespace for access from other modules
  DM.ShowFindMyDotsPrompt = function(self) FindMyDotsUI:ShowFindMyDotsPrompt() end

  DM:DebugMsg("Find My Dots UI module initialized")
end

-- Return the module
return FindMyDotsUI
