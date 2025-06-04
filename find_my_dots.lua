-- DotMaster find_my_dots.lua
-- Automatic dot detection and tracking system

local DM = DotMaster

-- Dot recording system state
DM.recordingDots = false
DM.detectedDots = {}

-- Start dot recording mode
function DM:StartFindMyDots()
  -- If already active, exit
  if self.recordingDots then return end

  -- Hide main GUI
  if DM.GUI and DM.GUI.frame and DM.GUI.frame:IsShown() then
    DM.GUI.frame:Hide()
  end

  -- Reset shown notifications
  self.shownNotifications = {}
  self.totalDotsFound = 0

  self.recordingDots = true
  self.detectedDots = {}

  -- Show visual feedback
  self:ShowRecordingIndicator()

  -- Set time limit (30 seconds)
  self.recordingTimer = C_Timer.NewTimer(30, function()
    self:StopFindMyDots(true) -- true = indicates automatic stopping
  end)

  -- User information message
  DM:DebugMsg("Dot recording mode active! Cast your spells on targets (30 seconds).")

  -- Create special event handler and register it
  self:RegisterEvent("UNIT_AURA")

  -- Update event handler
  self:HookScript("OnEvent", function(self, event, ...)
    if event == "UNIT_AURA" and self.recordingDots then
      self:RecordDots(...)
    end
  end)
end

-- Stop dot recording mode
function DM:StopFindMyDots(automatic, finished)
  if not self.recordingDots then return end

  self.recordingDots = false

  -- No need to keep checking UNIT_AURA
  -- (We don't unregister the event as it's used by main functions)

  if self.recordingTimer then
    self.recordingTimer:Cancel()
    self.recordingTimer = nil
  end

  -- Remove visual indicator
  self:HideRecordingIndicator()

  -- Show results
  local count = 0
  if self.detectedDots then
    count = self:TableCount(self.detectedDots)
  end

  if count > 0 then
    if finished then
      DM:DebugMsg(string.format("%d dots detected! Recording completed.", count))
    else
      DM:DebugMsg(string.format("%d dots detected! Do you want to add them?", count))
    end
    self:ShowDotsConfirmationDialog(self.detectedDots)
  else
    if automatic then
      DM:DebugMsg("Time expired! No dots detected.")
    elseif finished then
      DM:DebugMsg("Recording completed. No dots detected.")
    else
      DM:DebugMsg("Dot recording mode canceled. No dots detected.")
    end
    -- Show main GUI and select Database tab if no dots found or cancelled early
    if DM.ToggleGUI then
      DM:ToggleGUI()
      if DM.GUI and DM.GUI.SelectTab then
        -- Set activeTabID to Database tab
        DM.GUI.activeTabID = 4
        -- Select the tab
        DM.GUI:SelectTab(4) -- Database tab is ID 4
      end
    end
  end
end

-- Record dots
function DM:RecordDots(unitToken)
  if not self.recordingDots then return end
  if not unitToken or not unitToken:match("^nameplate") then return end

  AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(name, _, _, _, _, _, source, _, _, id)
    -- Only record player's own debuffs and if not already detected
    if source == "player" and id and not self.detectedDots[id] then
      -- Skip if name is nil
      if not name or name == "" then
        DM:DebugMsg(string.format("RecordDots: Skipping spell with ID %d due to missing name", id))
        return
      end

      -- Check if the spell already exists in database
      local isExisting = self:SpellExists(id)

      -- Record detailed info with safety
      self.detectedDots[id] = {
        name = name or "Unknown",
        id = id,
        timestamp = GetTime(),
        isExisting = isExisting -- Mark if it's already in the database
      }

      -- DEBUG: Print the exact spell ID detected by UNIT_AURA
      DM:DebugMsg(string.format("RecordDots: Detected Spell ID: %d, Name: %s from UNIT_AURA (Already in DB: %s)",
        id, name, tostring(isExisting)))

      -- Update dot counter - only count new dots
      if not isExisting then
        self.newDotsFound = (self.newDotsFound or 0) + 1
        if self.dotsFoundText then
          self.dotsFoundText:SetText(string.format("%d new dots found", self.newDotsFound))
        end
      end

      -- Update total counter regardless
      self.totalDotsFound = (self.totalDotsFound or 0) + 1

      -- Inform user
      DM:DebugMsg(string.format("Dot detected: %s (ID: %d)", name, id))

      -- Show visual feedback
      self:ShowDetectedDotNotification(name, id, isExisting)
    end
  end)
end

-- Get player class and specialization
function DM:GetPlayerClassAndSpec()
  -- Class bilgisini al
  local className = select(2, UnitClass("player")) or "UNKNOWN"

  -- Varsayılan spec adı
  local specName = "General"

  -- Aktif spec index'ini al
  local specIndex = GetSpecialization()

  -- Spec index varsa, spec bilgisini al
  if specIndex then
    -- GetSpecializationInfo daha fazla değer döndürür, ama bize sadece name lazım
    local _, name = GetSpecializationInfo(specIndex)

    -- name bilgisi varsa kullan
    if name and name ~= "" then
      specName = name
    end
  end

  return className, specName
end

-- Visual feedback functions
function DM:ShowRecordingIndicator()
  if not self.recordingFrame then
    -- Create recording frame with modern WoW style and match main UI style
    self.recordingFrame = CreateFrame("Frame", "DotMasterRecordingFrame", UIParent, "BackdropTemplate")
    self.recordingFrame:SetSize(450, 30) -- Wider to prevent overlap
    self.recordingFrame:SetPoint("TOP", 0, -50)

    -- Match the main UI backdrop style
    self.recordingFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.recordingFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    self.recordingFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8) -- Purple border

    -- Mode text
    self.recordingText = self.recordingFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
    self.recordingText:SetPoint("LEFT", 20, 0)
    self.recordingText:SetText("DOT RECORDING MODE ACTIVE")
    self.recordingText:SetTextColor(1, 0.82, 0) -- Gold color

    -- Time indicator
    self.recordingTime = self.recordingFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormalSmall"))
    self.recordingTime:SetPoint("LEFT", self.recordingText, "RIGHT", 10, 0)
    self.recordingTime:SetText("30s")
    self.recordingTime:SetTextColor(1, 1, 1)

    -- Initialize counters
    self.totalDotsFound = 0
    self.newDotsFound = 0

    -- New dots counter with English text
    self.dotsFoundText = self.recordingFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
    self.dotsFoundText:SetPoint("LEFT", self.recordingTime, "RIGHT", 15, 0) -- Position after time
    self.dotsFoundText:SetText("0 new dots found")
    self.dotsFoundText:SetTextColor(0.3, 1, 0.3)                            -- Green color

    -- Button container on far right
    local buttonContainer = CreateFrame("Frame", nil, self.recordingFrame)
    buttonContainer:SetSize(80, 22)
    buttonContainer:SetPoint("RIGHT", -10, 0)

    -- Finish button
    self.finishButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    self.finishButton:SetSize(70, 22)
    self.finishButton:SetPoint("CENTER", 0, 0)
    self.finishButton:SetText("Finish")

    self.finishButton:SetScript("OnClick", function()
      self:StopFindMyDots(false, true) -- Marked as finished
    end)
  end

  -- Reset counters
  self.totalDotsFound = 0
  self.newDotsFound = 0
  self.dotsFoundText:SetText("0 new dots found")

  -- Make visible
  self.recordingFrame:Show()

  -- Update remaining time
  self.recordingTimeLeft = 30

  -- Timer
  if self.recordingTicker then
    self.recordingTicker:Cancel()
  end

  self.recordingTicker = C_Timer.NewTicker(1, function()
    self.recordingTimeLeft = self.recordingTimeLeft - 1
    if self.recordingTime then
      self.recordingTime:SetText(string.format("%ds", self.recordingTimeLeft))

      -- Color change based on time remaining
      if self.recordingTimeLeft <= 5 then
        self.recordingTime:SetTextColor(1, 0, 0)   -- Red when time is running out
      elseif self.recordingTimeLeft <= 10 then
        self.recordingTime:SetTextColor(1, 0.5, 0) -- Orange when time is getting low
      else
        self.recordingTime:SetTextColor(1, 1, 1)   -- White otherwise
      end
    end
  end)
end

function DM:HideRecordingIndicator()
  if self.recordingFrame and self.recordingFrame.Hide then
    self.recordingFrame:Hide()
  end

  if self.recordingTicker then
    self.recordingTicker:Cancel()
    self.recordingTicker = nil
  end
end

-- Show minimal, clean visual feedback when a spell is detected
function DM:ShowDetectedDotNotification(name, id, isExisting)
  -- Skip already shown notifications for this session
  if not self.shownNotifications then self.shownNotifications = {} end
  if self.shownNotifications[id] then return end

  -- Mark as shown
  self.shownNotifications[id] = true

  -- Main notification container with larger size
  if not self.dotAlertContainer then
    self.dotAlertContainer = CreateFrame("Frame", "DotMasterAlertContainer", UIParent)
    self.dotAlertContainer:SetSize(350, 120) -- Increased width for better text display

    -- Position below the recording frame
    if self.recordingFrame then
      self.dotAlertContainer:SetPoint("TOP", self.recordingFrame, "BOTTOM", 0, -5)
    else
      self.dotAlertContainer:SetPoint("TOP", UIParent, "TOP", 0, -80)
    end

    self.dotAlertContainer.frames = {}
    self.dotAlertContainer.maxDisplayed = 3 -- Maximum 3 notifications
  end

  -- Notification dimensions
  local NOTIFICATION_HEIGHT = 42 -- Increased height
  local NOTIFICATION_SPACING = 4

  -- Maximum number of displayed notifications
  local maxDisplayed = self.dotAlertContainer.maxDisplayed or 3

  -- Remove oldest notification if we have too many
  if #self.dotAlertContainer.frames >= maxDisplayed then
    local oldestFrame = self.dotAlertContainer.frames[#self.dotAlertContainer.frames]

    -- Exit animation for old notification
    local exitAnimGroup = oldestFrame:CreateAnimationGroup()
    local fadeOut = exitAnimGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("OUT")

    exitAnimGroup:SetScript("OnFinished", function()
      oldestFrame:Hide()
      table.remove(self.dotAlertContainer.frames, #self.dotAlertContainer.frames)
    end)

    exitAnimGroup:Play()
  end

  -- Create a new alert frame for this spell
  local alertFrame = CreateFrame("Frame", nil, self.dotAlertContainer, "BackdropTemplate")
  alertFrame:SetSize(330, NOTIFICATION_HEIGHT) -- Increased width and height

  -- Position the notification
  if #self.dotAlertContainer.frames == 0 then
    alertFrame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0, 0)
  else
    alertFrame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0,
      -(#self.dotAlertContainer.frames * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
  end

  -- Match the main UI backdrop style
  alertFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  alertFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  alertFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8) -- Purple border to match DotMaster style

  -- Add to container at the beginning of the array
  table.insert(self.dotAlertContainer.frames, 1, alertFrame)

  -- Update positions of all notifications
  for i, frame in ipairs(self.dotAlertContainer.frames) do
    if frame and frame:IsShown() then
      frame:ClearAllPoints()
      frame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0, -((i - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
    end
  end

  -- Retrieve the correct spell icon
  local spellIcon = DM:GetSpellIcon(id)

  -- Debug message for spell icon with safety checks
  if name and name ~= "" then
    DM:DebugMsg(string.format("Retrieved icon for %s (ID: %d): %s, Existing: %s",
      name, id, spellIcon or "nil", tostring(isExisting)))
  else
    DM:DebugMsg(string.format("Retrieved icon for unknown spell (ID: %d): %s",
      id, spellIcon or "nil"))
  end

  -- Spell icon
  local icon = alertFrame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(32, 32) -- Larger icon
  icon:SetPoint("LEFT", 12, 0)
  icon:SetTexture(spellIcon)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

  -- If existing spell, desaturate the icon
  if isExisting then
    icon:SetDesaturated(true)
  end

  -- Icon border - red for existing, green for new
  local borderColor = isExisting and { r = 1, g = 0.3, b = 0.3 } or { r = 0.3, g = 1, b = 0.3 }

  local border = alertFrame:CreateTexture(nil, "BORDER")
  border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
  border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  border:SetBlendMode("ADD")
  border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, 1.0)

  -- Spell name with larger font
  local spellText = alertFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormalLarge"))
  spellText:SetPoint("LEFT", icon, "RIGHT", 12, 4)
  spellText:SetText(name)
  spellText:SetTextColor(1, 0.82, 0) -- Gold

  -- Make sure text fits within frame - limit width and add ellipsis if needed
  spellText:SetWidth(220)
  spellText:SetWordWrap(false)
  spellText:SetNonSpaceWrap(false)

  -- Spell ID
  local idText = alertFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
  idText:SetPoint("TOPLEFT", spellText, "BOTTOMLEFT", 0, -2)
  idText:SetText("ID: " .. id)
  idText:SetTextColor(0.7, 0.7, 0.7) -- Gray

  -- Add status text (New/Known)
  local statusText = alertFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormalSmall"))
  statusText:SetPoint("RIGHT", alertFrame, "RIGHT", -12, 0)
  if isExisting then
    statusText:SetText("Known")
    statusText:SetTextColor(1, 0.3, 0.3) -- Red for existing
  else
    statusText:SetText("New")
    statusText:SetTextColor(0.3, 1, 0.3) -- Green for new
  end

  -- Fade in animation setup
  alertFrame:SetAlpha(0)
  alertFrame:Show()

  -- Create animation group for entrance
  local animGroup = alertFrame:CreateAnimationGroup()

  -- Fade in animation
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

  -- Glow in animation
  local glowAnim = animGroup:CreateAnimation("Alpha")
  glowAnim:SetTarget(glow)
  glowAnim:SetFromAlpha(0)
  glowAnim:SetToAlpha(0.7)
  glowAnim:SetDuration(0.3)
  glowAnim:SetSmoothing("IN")

  -- Glow out animation
  local glowFadeOut = animGroup:CreateAnimation("Alpha")
  glowFadeOut:SetTarget(glow)
  glowFadeOut:SetStartDelay(0.3)
  glowFadeOut:SetFromAlpha(0.7)
  glowFadeOut:SetToAlpha(0)
  glowFadeOut:SetDuration(0.5)
  glowFadeOut:SetSmoothing("OUT")

  -- Animation finished callback
  animGroup:SetScript("OnFinished", function()
    alertFrame:SetAlpha(1)
  end)

  -- Start animation
  animGroup:Play()

  -- Schedule removal after 4 seconds
  C_Timer.After(4, function()
    if not alertFrame or not alertFrame:IsShown() then return end

    local exitAnimGroup = alertFrame:CreateAnimationGroup()

    -- Fade out animation
    local fadeOut = exitAnimGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("OUT")

    -- Animation finished callback
    exitAnimGroup:SetScript("OnFinished", function()
      alertFrame:Hide()

      -- Remove from container
      for i, frame in ipairs(self.dotAlertContainer.frames) do
        if frame == alertFrame then
          table.remove(self.dotAlertContainer.frames, i)

          -- Update positions of remaining notifications
          for j, remainingFrame in ipairs(self.dotAlertContainer.frames) do
            if remainingFrame and remainingFrame:IsShown() then
              remainingFrame:ClearAllPoints()
              remainingFrame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0,
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

-- Add debug messages to verify spell data
function DM:ShowDotsConfirmationDialog(dots)
  for id, dotInfo in pairs(dots) do
    DM:DebugMsg(string.format("Detected Dot - ID: %d, Name: %s", id, dotInfo.name))
  end

  -- Confirmation dialog for detected dots
  if not self.dotsConfirmFrame then
    self.dotsConfirmFrame = CreateFrame("Frame", "DotMasterDotsConfirm", UIParent, "BackdropTemplate")
    self.dotsConfirmFrame:SetFrameStrata("DIALOG")
    self.dotsConfirmFrame:SetSize(400, 300)
    self.dotsConfirmFrame:SetPoint("CENTER")

    -- Simple background
    self.dotsConfirmFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.dotsConfirmFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    self.dotsConfirmFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)

    -- Title
    local title = self.dotsConfirmFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormalLarge"))
    title:SetPoint("TOP", 0, -15)
    title:SetText("Detected Dots")

    -- Subtitle
    local desc = self.dotsConfirmFrame:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Select dots you want to add")
    desc:SetTextColor(1, 0.82, 0)

    -- Scroll frame for dots list
    local scrollFrame = CreateFrame("ScrollFrame", "DotMasterDotsScrollFrame", self.dotsConfirmFrame,
      "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(370, 180)
    scrollFrame:SetPoint("TOP", desc, "BOTTOM", 0, -15)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(350, 10) -- Will be adjusted dynamically

    -- Button at the bottom
    local addButton = CreateFrame("Button", nil, self.dotsConfirmFrame, "UIPanelButtonTemplate")
    addButton:SetSize(100, 25)
    addButton:SetPoint("BOTTOM", 0, 15)
    addButton:SetText("OK")

    -- Store reference to the save button
    self.saveButton = addButton

    -- Close button at the top right
    local closeButton = CreateFrame("Button", nil, self.dotsConfirmFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    -- Hide frame
    closeButton:SetScript("OnClick", function()
      self.dotsConfirmFrame:Hide()
      -- Show main GUI and select Database tab when closing confirmation
      if DM.ToggleGUI then
        DM:ToggleGUI()
        if DM.GUI and DM.GUI.SelectTab then
          -- Set activeTabID to Database tab
          DM.GUI.activeTabID = 4
          -- Select the tab
          DM.GUI:SelectTab(4) -- Database tab is ID 4
        end
      end
    end)

    -- Add selected dots or just close the window
    addButton:SetScript("OnClick", function()
      -- Check if there are any new dots to add
      local hasNewDots = false
      for id, checkbox in pairs(self.dotCheckboxes or {}) do -- Ensure self.dotCheckboxes exists
        if checkbox:GetChecked() then                        -- Ensure checkbox itself is valid before GetChecked
          local dotInfo = self.detectedDots[tonumber(id)]
          if dotInfo and not self:SpellExists(id) then
            hasNewDots = true
            break
          end
        end
      end

      -- If no new dots, just close the window and show main GUI
      if not hasNewDots then
        DM:DebugMsg("No new dots to add - closing window")
        self.dotsConfirmFrame:Hide()
        if DM.ToggleGUI then
          DM:ToggleGUI()
          if DM.GUI and DM.GUI.SelectTab then
            -- Set activeTabID to Database tab
            DM.GUI.activeTabID = 4
            -- Select the tab
            DM.GUI:SelectTab(4) -- Database tab is ID 4
          end
        end
        return
      end

      -- Otherwise proceed with adding dots
      DM:DatabaseDebug("Add to Database button clicked.")
      local added = 0

      -- Collect all spells to add
      local spellsToAdd = {}
      for id, checkbox in pairs(self.dotCheckboxes or {}) do
        if checkbox:GetChecked() then
          local dotInfo = self.detectedDots[tonumber(id)]
          -- Only add if it doesn't already exist in database
          if dotInfo and not self:SpellExists(id) then
            spellsToAdd[id] = dotInfo
          end
        end
      end

      -- Get current spec profile
      local currentProfile = self:GetCurrentSpecProfile()
      if not currentProfile then
        DM:PrintMessage("Error: Could not access current spec profile. Dots not added.")
        return
      end

      -- Ensure spells table exists
      if not currentProfile.spells then
        currentProfile.spells = {}
      end

      -- Then add all spells to current spec's spells array
      for id, dotInfo in pairs(spellsToAdd) do
        DM:DebugMsg(string.format("Processing Dot - ID: %d, Name: %s", id, dotInfo.name))
        local spellIcon = DM:GetSpellIcon(id)
        local className, specName = self:GetPlayerClassAndSpec()

        -- Add to current spec's database
        currentProfile.spells[tonumber(id)] = {
          spellname = dotInfo.name,
          spellicon = spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
          wowclass = className or "UNKNOWN",
          wowspec = specName or "General",
          color = { r = 1, g = 0, b = 0, a = 1 }, -- Red
          priority = 50,
          tracked = 1,
          enabled = 1
        }

        added = added + 1
      end

      -- Push updated configuration to Plater
      if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
        DM.ClassSpec:PushConfigToPlater()
      end

      -- Add a small delay before refreshing UI to ensure database changes are complete
      C_Timer.After(0.1, function()
        -- Only refresh UI if spells were added
        if added > 0 then
          -- Refresh both tabs
          if self.GUI then
            if self.GUI.RefreshDatabaseTabList then
              self.GUI:RefreshDatabaseTabList()
              DM:DatabaseDebug("Database tab refreshed after adding dots")
            end
            if self.GUI.RefreshTrackedSpellTabList then
              self.GUI:RefreshTrackedSpellTabList()
              DM:DatabaseDebug("Tracked spells tab refreshed after adding dots")
            end
          end
        end

        DM:DebugMsg(string.format("%d dots successfully added!", added))
      end)

      self.dotsConfirmFrame:Hide()

      -- Show main GUI and select Database tab
      if DM.ToggleGUI then
        DM:ToggleGUI()
        if DM.GUI and DM.GUI.SelectTab then
          -- Set activeTabID to Database tab
          DM.GUI.activeTabID = 4
          -- Select the tab
          DM.GUI:SelectTab(4) -- Database tab is ID 4
        end
      end
    end)

    -- Make the window movable
    self.dotsConfirmFrame:SetMovable(true)
    self.dotsConfirmFrame:EnableMouse(true)
    self.dotsConfirmFrame:RegisterForDrag("LeftButton")
    self.dotsConfirmFrame:SetScript("OnDragStart", self.dotsConfirmFrame.StartMoving)
    self.dotsConfirmFrame:SetScript("OnDragStop", self.dotsConfirmFrame.StopMovingOrSizing)

    -- Store references
    self.dotsScrollChild = scrollChild
    self.scrollFrame = scrollFrame
  end

  -- Clear dot list
  if self.dotsScrollChild then
    local children = { self.dotsScrollChild:GetChildren() }
    for _, child in pairs(children) do
      if type(child) == "table" then
        pcall(function() child:Hide() end)
        pcall(function() child:SetParent(nil) end)
      end
    end
  end

  -- Clear checkboxes
  self.dotCheckboxes = {}

  -- Display dots in a simple list
  local yOffset = 10

  -- Sort dots by name with safety checks and check for new dots
  local sortedDots = {}
  local hasNewDots = false

  for id, dotInfo in pairs(dots) do
    -- Ensure dotInfo has a name before adding to sortedDots
    if dotInfo and dotInfo.name then
      local isExisting = dotInfo.isExisting or self:SpellExists(id)
      -- Track if we have at least one new dot
      if not isExisting then
        hasNewDots = true
      end
      table.insert(sortedDots, { id = id, name = dotInfo.name, info = dotInfo, isExisting = isExisting })
    else
      -- Log the issue
      DM:DebugMsg(string.format("Warning: Dot with ID %s has missing or invalid data", tostring(id)))
    end
  end

  -- Only sort if we have valid dots
  if #sortedDots > 0 then
    table.sort(sortedDots, function(a, b)
      return a.name < b.name
    end)
  end

  -- Update button text based on whether we have new dots
  if self.saveButton then
    self.saveButton:SetText(hasNewDots and "Add Selected" or "OK")
  end

  -- Simple message if no new dots or no dots at all
  if #sortedDots == 0 then
    -- No dots detected message
    local messageText = self.dotsScrollChild:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontHighlight"))
    messageText:SetPoint("TOP", self.dotsScrollChild, "TOP", 0, -10)
    messageText:SetText("No dots have been detected.\n\nTry again and cast your DoT abilities on enemies.")
    messageText:SetWidth(340)
    messageText:SetJustifyH("CENTER")

    yOffset = yOffset + 60
  elseif not hasNewDots then
    -- All dots are known message
    local messageText = self.dotsScrollChild:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontHighlight"))
    messageText:SetPoint("TOP", self.dotsScrollChild, "TOP", 0, -10)
    messageText:SetText("All detected dots are already in your database.")
    messageText:SetWidth(340)
    messageText:SetJustifyH("CENTER")

    yOffset = yOffset + 30
  end

  -- Create a row for each dot
  for _, dotData in ipairs(sortedDots) do
    local id = dotData.id
    local dotInfo = dotData.info
    local isExisting = dotData.isExisting or self:SpellExists(id)

    -- Retrieve the correct spell icon
    local spellIcon = DM:GetSpellIcon(id)

    -- Create row
    local row = CreateFrame("Frame", nil, self.dotsScrollChild)
    row:SetSize(350, 24)
    row:SetPoint("TOPLEFT", 5, -yOffset)

    -- Row background for alternating colors
    local rowBg = row:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints()
    if yOffset % 48 < 24 then
      rowBg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    else
      rowBg:SetColorTexture(0.12, 0.12, 0.12, 0.4)
    end

    -- Checkbox - only check by default if it's a new spell
    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", 5, 0)
    checkbox:SetChecked(not isExisting) -- Only check new spells by default

    -- Store in checkboxes table
    self.dotCheckboxes[tostring(id)] = checkbox

    -- Spell icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    icon:SetTexture(spellIcon)

    -- Desaturate if existing
    if isExisting then
      icon:SetDesaturated(true)
    end

    -- Spell name and ID
    local text = row:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontHighlight"))
    text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    text:SetText(string.format("%s (ID: %d)", dotInfo.name, id))
    text:SetWidth(230)

    -- Status label
    local statusText = row:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontHighlightSmall"))
    statusText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    statusText:SetText(isExisting and "Known" or "New")
    statusText:SetTextColor(isExisting and 1 or 0, isExisting and 0 or 1, 0)

    yOffset = yOffset + 24
  end

  -- Update scroll child height
  self.dotsScrollChild:SetHeight(math.max(yOffset + 10, 100))

  -- Reset scroll position to top
  if self.scrollFrame then
    self.scrollFrame:SetVerticalScroll(0)
  end

  -- Show confirmation dialog
  if self.dotsConfirmFrame then
    pcall(function() self.dotsConfirmFrame:Show() end)
  end
end

-- Helper function to update scroll child height
function DM:UpdateScrollChildHeight()
  if not self.dotsScrollChild or not self.scrollFrame then return end

  -- Calculate total height based on visible elements
  local totalHeight = 10 -- starting offset
  local children = { self.dotsScrollChild:GetChildren() }

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
      end
    end
  end

  -- Add bottom padding
  totalHeight = totalHeight + 20

  -- Set height, ensuring it's at least as tall as the scroll frame
  local scrollHeight = 180 -- Default scroll frame height
  pcall(function()
    if self.scrollFrame.GetHeight then
      scrollHeight = self.scrollFrame:GetHeight()
    end
  end)

  if self.dotsScrollChild.SetHeight then
    self.dotsScrollChild:SetHeight(math.max(totalHeight, scrollHeight))
  end
end

-- Helper function to get class display name
function DM:GetClassDisplayName(className)
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

-- Ensure nameplate debugger section loads unchecked by default
function DM:CreateNameplateDebuggerSection()
  -- Existing code for creating the nameplate debugger section
  -- ...

  -- Set default state to unchecked
  self.nameplateDebuggerCheckbox:SetChecked(false)
end

-- Helper function to get spell icon with fallback methods
function DM:GetSpellIcon(spellID)
  -- Default icon for fallback
  local defaultIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

  -- Method 1: C_Spell.GetSpellInfo (preferred modern method)
  local spellInfo = C_Spell.GetSpellInfo(spellID)
  if spellInfo then
    -- Check for different possible icon fields
    if spellInfo.iconID and spellInfo.iconID ~= 0 then
      DM:DebugMsg(string.format("Icon for spell %d found via C_Spell.GetSpellInfo.iconID: %s", spellID, spellInfo.iconID))
      return spellInfo.iconID
    elseif spellInfo.originalIconID and spellInfo.originalIconID ~= 0 then
      DM:DebugMsg(string.format("Icon for spell %d found via C_Spell.GetSpellInfo.originalIconID: %s", spellID,
        spellInfo.originalIconID))
      return spellInfo.originalIconID
    elseif spellInfo.iconFileID and spellInfo.iconFileID ~= 0 then
      DM:DebugMsg(string.format("Icon for spell %d found via C_Spell.GetSpellInfo.iconFileID: %s", spellID,
        spellInfo.iconFileID))
      return spellInfo.iconFileID
    end
  end

  -- Method 2: Classic GetSpellInfo
  local _, _, icon = GetSpellInfo(spellID)
  if icon and icon ~= "" then
    DM:DebugMsg(string.format("Icon for spell %d found via GetSpellInfo: %s", spellID, icon))
    return icon
  end

  -- Fallback to default if all methods fail
  DM:DebugMsg(string.format("No icon found for spell %d, using default", spellID))
  return defaultIcon
end

-- Get the current spec's profile
function DM:GetCurrentSpecProfile()
  if not DM.ClassSpec then return nil end

  local currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()

  if not DotMasterDB or not DotMasterDB.classProfiles or
      not DotMasterDB.classProfiles[currentClass] or
      not DotMasterDB.classProfiles[currentClass][currentSpecID] then
    return nil
  end

  return DotMasterDB.classProfiles[currentClass][currentSpecID]
end

-- Check if a spell exists in the current spec's database
function DM:SpellExists(spellID)
  if not spellID then return false end

  -- Convert to number
  local numericID = tonumber(spellID)
  if not numericID then return false end

  -- Get current spec profile
  local currentProfile = self:GetCurrentSpecProfile()
  if not currentProfile or not currentProfile.spells then return false end

  -- Check if spell exists in current spec's spells
  return currentProfile.spells[numericID] ~= nil
end

-- Remove problematic "Unknown (1)" entry from all class profiles
function DM:RemoveUnknownSpellID1()
  DM:DatabaseDebug("Attempting to remove Unknown (1) spell from all class profiles...")

  if not DotMasterDB or not DotMasterDB.classProfiles then
    DM:DatabaseDebug("No class profiles found to clean")
    return
  end

  local count = 0

  -- Loop through all class profiles
  for className, classData in pairs(DotMasterDB.classProfiles) do
    -- Loop through all specs within each class
    for specID, specData in pairs(classData) do
      -- Check if spells table exists
      if specData.spells then
        -- Check for numeric key 1
        if specData.spells[1] then
          DM:DatabaseDebug(string.format("Removing Unknown (1) from %s spec %s (numeric key)", className, specID))
          specData.spells[1] = nil
          count = count + 1
        end

        -- Check for string key "1"
        if specData.spells["1"] then
          DM:DatabaseDebug(string.format("Removing Unknown (1) from %s spec %s (string key)", className, specID))
          specData.spells["1"] = nil
          count = count + 1
        end

        -- Special check for any spell with name "Unknown" and ID close to 1
        for spellID, spellData in pairs(specData.spells) do
          -- Convert to number safely
          local numID = tonumber(spellID)
          -- Check if ID is 1 or close to 1, or if the spell name contains "Unknown"
          if (numID and numID < 10) or
              (spellData.spellname and spellData.spellname:find("Unknown")) then
            DM:DatabaseDebug(string.format("Removing suspicious spell %s from %s spec %s",
              tostring(spellID), className, specID))
            specData.spells[spellID] = nil
            count = count + 1
          end
        end
      end
    end
  end

  -- Also clean from legacy data structure if it exists
  if DM.dmspellsdb then
    -- Check for numeric key 1
    if DM.dmspellsdb[1] then
      DM.dmspellsdb[1] = nil
      count = count + 1
      DM:DatabaseDebug("Removed Unknown (1) from legacy database (numeric key)")
    end

    -- Check for string key "1"
    if DM.dmspellsdb["1"] then
      DM.dmspellsdb["1"] = nil
      count = count + 1
      DM:DatabaseDebug("Removed Unknown (1) from legacy database (string key)")
    end

    -- Clean any suspicious spell entries
    for spellID, spellData in pairs(DM.dmspellsdb) do
      local numID = tonumber(spellID)
      if (numID and numID < 10) or
          (spellData.spellname and spellData.spellname:find("Unknown")) then
        DM.dmspellsdb[spellID] = nil
        count = count + 1
        DM:DatabaseDebug(string.format("Removed suspicious spell %s from legacy database", tostring(spellID)))
      end
    end
  end

  -- Specifically target the Death Knight Unholy spec based on the screenshot
  if DotMasterDB.classProfiles["DEATHKNIGHT"] then
    for specID, specData in pairs(DotMasterDB.classProfiles["DEATHKNIGHT"]) do
      if specData.spells then
        -- Look for any spell with Unknown in the name
        for spellID, spellData in pairs(specData.spells) do
          if spellData.spellname and spellData.spellname:find("Unknown") then
            DM:DatabaseDebug(string.format("Removing Unknown spell %s from Death Knight spec %s",
              tostring(spellID), specID))
            specData.spells[spellID] = nil
            count = count + 1
          end
        end
      end
    end
  end

  -- Push changes to Plater if we removed any instances
  if count > 0 and DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
    DM.ClassSpec:PushConfigToPlater()
    DM:DatabaseDebug(string.format("Removed problematic spells from %d locations and pushed changes to Plater", count))

    -- Refresh UI
    if DM.GUI then
      if DM.GUI.RefreshDatabaseTabList then
        DM.GUI:RefreshDatabaseTabList()
      end
      if DM.GUI.RefreshTrackedSpellTabList then
        DM.GUI:RefreshTrackedSpellTabList()
      end
    end
  end
end

-- Call the function to remove Unknown (1) on initialization
C_Timer.After(2, function()
  DM:RemoveUnknownSpellID1()
end)

-- Add a function that can be called from slash commands to force cleanup
function DM:CleanupUnknownSpells()
  DM:PrintMessage("Cleaning up problematic Unknown spells...")
  DM:RemoveUnknownSpellID1()
  DM:PrintMessage("Cleanup complete. UI refreshed.")
end
