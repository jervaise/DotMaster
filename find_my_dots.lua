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
  end
end

-- Record dots
function DM:RecordDots(unitToken)
  if not self.recordingDots then return end
  if not unitToken or not unitToken:match("^nameplate") then return end

  AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(name, _, _, _, _, _, source, _, _, id)
    -- Only record player's own debuffs and if not already detected
    if source == "player" and not self.detectedDots[id] then
      -- Record detailed info
      self.detectedDots[id] = {
        name = name,
        id = id,
        timestamp = GetTime()
      }
      -- DEBUG: Print the exact spell ID detected by UNIT_AURA
      DM:DebugMsg(string.format("RecordDots: Detected Spell ID: %d, Name: %s from UNIT_AURA", id, name))

      -- Update spell database with class and spec info
      local className, specName = self:GetPlayerClassAndSpec()

      -- Do not save to database here
      -- DM:AddSpellToDMSpellsDB(id, name, "Interface\\Icons\\Spell_Nature_HealingTouch", className, specName)

      -- Also add to spell config automatically if not exists
      if not self:SpellExists(id) then
        -- Do not create a new spell config entry
        -- self.spellConfig[tostring(id)] = {
        --   enabled = true,
        --   color = { 1, 0, 0 }, -- Default red color
        --   name = name,
        --   priority = self:GetNextPriority(),
        --   saved = true
        -- }

        -- Refresh GUI if open
        if self.GUI and self.GUI.RefreshSpellList then
          self.GUI:RefreshSpellList()
        end

        -- Do not save settings here
        -- self:SaveSettings()
      end

      -- Update dot counter
      self.totalDotsFound = (self.totalDotsFound or 0) + 1
      if self.dotsFoundText then
        self.dotsFoundText:SetText(self.totalDotsFound .. " DOT BULUNDU")
      end

      -- Inform user
      DM:DebugMsg(string.format("Dot detected: %s (ID: %d)", name, id))

      -- Show visual feedback
      self:ShowDetectedDotNotification(name, id)
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
    -- Create recording frame with modern WoW style
    self.recordingFrame = CreateFrame("Frame", "DotMasterRecordingFrame", UIParent, "BackdropTemplate")
    self.recordingFrame:SetSize(400, 30)
    self.recordingFrame:SetPoint("TOP", 0, -50)

    -- Background with gradient
    local bg = self.recordingFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)

    -- Purple border like DotMaster main UI
    self.recordingFrame:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
      edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.recordingFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    self.recordingFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8) -- Purple border to match DotMaster style

    -- Text with better layout
    self.recordingText = self.recordingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.recordingText:SetPoint("LEFT", 20, 0)
    self.recordingText:SetText("DOT RECORDING MODE ACTIVE")
    self.recordingText:SetTextColor(1, 0.82, 0) -- Gold color like WoW UI

    -- Time indicator
    self.recordingTime = self.recordingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.recordingTime:SetPoint("LEFT", self.recordingText, "RIGHT", 10, 0)
    self.recordingTime:SetText("30s")
    self.recordingTime:SetTextColor(1, 1, 1)

    -- Dot counter - tek bir sayaç ekleyelim
    self.totalDotsFound = 0
    self.dotsFoundText = self.recordingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.dotsFoundText:SetPoint("RIGHT", self.recordingFrame, "RIGHT", -100, 0)
    self.dotsFoundText:SetText("0 DOT BULUNDU")
    self.dotsFoundText:SetTextColor(0.3, 1, 0.3) -- Yeşil renkte

    -- Button container for better layout
    local buttonContainer = CreateFrame("Frame", nil, self.recordingFrame)
    buttonContainer:SetSize(170, 22)
    buttonContainer:SetPoint("RIGHT", -10, 0)

    -- Finish button with WoW style
    self.finishButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    self.finishButton:SetSize(80, 22)
    self.finishButton:SetPoint("LEFT", 0, 0)
    self.finishButton:SetText("Finish")

    self.finishButton:SetScript("OnClick", function()
      -- Stop recording but don't mark as automatic/canceled
      self:StopFindMyDots(false, true) -- Pass true as second param to indicate finished
    end)

    -- Cancel button with WoW style
    self.cancelButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    self.cancelButton:SetSize(80, 22)
    self.cancelButton:SetPoint("RIGHT", 0, 0)
    self.cancelButton:SetText("Cancel")
    self.cancelButton:SetScript("OnClick", function() self:StopFindMyDots() end)
  end

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
function DM:ShowDetectedDotNotification(name, id)
  -- Skip already shown notifications for this session
  if not self.shownNotifications then self.shownNotifications = {} end
  if self.shownNotifications[id] then return end

  -- Mark as shown
  self.shownNotifications[id] = true

  -- Main notification container - timer çubuğunun altında konumlanacak
  if not self.dotAlertContainer then
    self.dotAlertContainer = CreateFrame("Frame", "DotMasterAlertContainer", UIParent)
    self.dotAlertContainer:SetSize(300, 120) -- 3 satır için daha fazla alan

    -- Find My Dots timer çubuğunun altına hizala
    if self.recordingFrame then
      self.dotAlertContainer:SetPoint("TOP", self.recordingFrame, "BOTTOM", 0, -5)
    else
      self.dotAlertContainer:SetPoint("TOP", UIParent, "TOP", 0, -80)
    end

    self.dotAlertContainer.frames = {}
    self.dotAlertContainer.maxDisplayed = 3 -- Maksimum 3 satır göster
  end

  -- Move existing notifications up
  local NOTIFICATION_HEIGHT = 36
  local NOTIFICATION_SPACING = 4

  -- Maksimum görüntülenecek bildirim sayısı
  local maxDisplayed = self.dotAlertContainer.maxDisplayed or 3

  -- Toplam bulunan dot sayısını güncelle
  self.totalDotsFound = self.totalDotsFound or 0
  self.totalDotsFound = self.totalDotsFound + 1

  -- Recording frame üzerinde dot sayacını güncelle
  if self.recordingFrame and self.dotsFoundText then
    self.dotsFoundText:SetText(self.totalDotsFound .. " dot bulundu")
  end

  -- Eski bildirimleri yukarı kaydırmak yerine en eski olanı kaldır
  if #self.dotAlertContainer.frames >= maxDisplayed then
    local oldestFrame = self.dotAlertContainer.frames[#self.dotAlertContainer.frames]

    -- Eski bildirim için çıkış animasyonu
    local exitAnimGroup = oldestFrame:CreateAnimationGroup()

    -- Sadece fade out (yana kayma olmadan)
    local fadeOut = exitAnimGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("OUT")

    exitAnimGroup:SetScript("OnFinished", function()
      oldestFrame:Hide()

      -- Containerdan kaldır
      table.remove(self.dotAlertContainer.frames, #self.dotAlertContainer.frames)
    end)

    exitAnimGroup:Play()
  end

  -- Create a new alert frame for this spell
  local alertFrame = CreateFrame("Frame", nil, self.dotAlertContainer, "BackdropTemplate")
  alertFrame:SetSize(280, NOTIFICATION_HEIGHT)

  -- İlk bildirim en üstte, diğerleri onun altında olacak
  if #self.dotAlertContainer.frames == 0 then
    alertFrame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0, 0)
  else
    -- Ekrandaki en son bildirimin altına hizala
    alertFrame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0,
      -(#self.dotAlertContainer.frames * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
  end

  -- Yeni modern tasarım için arkaplan
  alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  -- Sınıf renk ayarları
  local className = select(2, UnitClass("player")) or "UNKNOWN"
  local classColor = self.classColors[className] or { r = 0.5, g = 0, b = 0.7 }

  alertFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  alertFrame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.8)

  -- Modern görünüm için hafif bir arka plan glow efekti
  local bgGlow = alertFrame:CreateTexture(nil, "BACKGROUND")
  bgGlow:SetPoint("TOPLEFT", -2, 2)
  bgGlow:SetPoint("BOTTOMRIGHT", 2, -2)
  bgGlow:SetTexture("Interface\\GLUES\\MODELS\\UI_Tauren\\gradientCircle")
  bgGlow:SetBlendMode("ADD")
  bgGlow:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.1)

  -- Add to container at the beginning of the array
  table.insert(self.dotAlertContainer.frames, 1, alertFrame)

  -- Tüm bildirimlerin pozisyonlarını güncelle
  for i, frame in ipairs(self.dotAlertContainer.frames) do
    if frame and frame:IsShown() then
      frame:ClearAllPoints()
      frame:SetPoint("TOP", self.dotAlertContainer, "TOP", 0, -((i - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_SPACING)))
    end
  end

  -- Spell ikonu için ikonların sınıf rengine göre hazırlanması
  local spellIcon = DM:GetSpellIcon(id)

  -- Debug message for spell icon
  DM:DebugMsg(string.format("Retrieved icon for %s (ID: %d): %s", name, id, spellIcon))

  -- Spell ikonu olarak standart mor ikonu kullan (spell ID'ye göre)
  local icon = alertFrame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(28, 28)
  icon:SetPoint("LEFT", 8, 0)
  icon:SetTexture(spellIcon)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop out the border

  -- İkon çerçevesi ekle
  local border = alertFrame:CreateTexture(nil, "BORDER")
  border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
  border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  border:SetBlendMode("ADD")
  border:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)

  -- Yazılar için daha iyi yerleşim
  local spellText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  spellText:SetPoint("LEFT", icon, "RIGHT", 10, 4)
  spellText:SetText(name)
  spellText:SetTextColor(1, 0.82, 0) -- Gold

  -- Spell ID daha düzenli konum
  local idText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  idText:SetPoint("TOPLEFT", spellText, "BOTTOMLEFT", 0, -2)
  idText:SetText("ID: " .. id)
  idText:SetTextColor(0.7, 0.7, 0.7) -- Gray
  -- Remove old alerts if we have too many
  if #self.dotAlertContainer.frames > 5 then
    for i = 6, #self.dotAlertContainer.frames do
      local oldFrame = self.dotAlertContainer.frames[i]
      if oldFrame and oldFrame:IsShown() then
        oldFrame:Hide()
      end
    end

    -- Truncate the array
    for i = #self.dotAlertContainer.frames, 6, -1 do
      self.dotAlertContainer.frames[i] = nil
    end
  end

  -- Sadece fade in (hareket etmeden)
  alertFrame:SetAlpha(0)
  alertFrame:Show()

  -- Alpha ile giriş animasyonu
  local animGroup = alertFrame:CreateAnimationGroup()

  -- Alpha animasyonu (fade in)
  local fadeIn = animGroup:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.3)
  fadeIn:SetSmoothing("IN_OUT")

  -- Glow efekti ekle
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
    -- Orijinal konumda tam görünürlükte bırak
    alertFrame:SetAlpha(1)
  end)

  -- Animasyonu başlat
  animGroup:Play()

  -- 4 saniye sonra çıkış animasyonu
  C_Timer.After(4, function()
    if not alertFrame or not alertFrame:IsShown() then return end

    local exitAnimGroup = alertFrame:CreateAnimationGroup()

    -- Sadece fade out (hareket etmeden)
    local fadeOut = exitAnimGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("OUT")

    exitAnimGroup:SetScript("OnFinished", function()
      alertFrame:Hide()

      -- Frameyi containerdan kaldır
      for i, frame in ipairs(self.dotAlertContainer.frames) do
        if frame == alertFrame then
          table.remove(self.dotAlertContainer.frames, i)
          -- Kalan bildirimlerin pozisyonlarını güncelle
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
    self.dotsConfirmFrame:SetSize(450, 350) -- Increased size for better layout
    self.dotsConfirmFrame:SetPoint("CENTER")

    -- Background and border
    self.dotsConfirmFrame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.dotsConfirmFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    self.dotsConfirmFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)

    -- Title
    local title = self.dotsConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Detected Dots")

    -- Description
    local desc = self.dotsConfirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Select dots you want to add")
    desc:SetTextColor(1, 0.82, 0)

    -- Scroll frame for dots list
    local scrollFrame = CreateFrame("ScrollFrame", nil, self.dotsConfirmFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(400, 200) -- Wider scroll frame
    scrollFrame:SetPoint("TOP", desc, "BOTTOM", 0, -20)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(380, 10) -- Will be adjusted dynamically

    -- Buttons at the bottom
    local buttonContainer = CreateFrame("Frame", nil, self.dotsConfirmFrame)
    buttonContainer:SetSize(400, 25)
    buttonContainer:SetPoint("BOTTOM", 0, 15)

    -- Add Selected button
    local addButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    addButton:SetSize(120, 25)
    addButton:SetPoint("CENTER", 0, 0)
    addButton:SetText("Save to Database")

    -- Close button at the top right
    local closeButton = CreateFrame("Button", nil, self.dotsConfirmFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    -- Hide frame
    closeButton:SetScript("OnClick", function()
      self.dotsConfirmFrame:Hide()
    end)

    -- Add selected dots
    addButton:SetScript("OnClick", function()
      DM:DatabaseDebug("Add to Database button clicked.")
      local added = 0

      -- First, collect all spells to add
      local spellsToAdd = {}
      for id, checkbox in pairs(self.dotCheckboxes) do
        if checkbox:GetChecked() then
          local dotInfo = self.detectedDots[tonumber(id)]
          if dotInfo and not self:SpellExists(id) then
            spellsToAdd[id] = dotInfo
          end
        end
      end

      -- Then add all spells in one batch
      for id, dotInfo in pairs(spellsToAdd) do
        DM:DebugMsg(string.format("Processing Dot - ID: %d, Name: %s", id, dotInfo.name))
        local spellIcon = DM:GetSpellIcon(id)
        local className, specName = self:GetPlayerClassAndSpec()

        -- Add to database with all properties in one call
        DM:AddSpellToDMSpellsDB(id, dotInfo.name, spellIcon, className, specName)
        added = added + 1
      end

      -- Force an immediate database save
      DM:SaveDMSpellsDB()

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
    end)

    -- Make the window movable
    self.dotsConfirmFrame:SetMovable(true)
    self.dotsConfirmFrame:EnableMouse(true)
    self.dotsConfirmFrame:RegisterForDrag("LeftButton")
    self.dotsConfirmFrame:SetScript("OnDragStart", self.dotsConfirmFrame.StartMoving)
    self.dotsConfirmFrame:SetScript("OnDragStop", self.dotsConfirmFrame.StopMovingOrSizing)

    -- Fix the scrollbar
    scrollFrame:SetScript("OnSizeChanged", function(self)
      local height = scrollChild:GetHeight()
      scrollFrame:SetVerticalScroll(0)
      scrollFrame:UpdateScrollChildRect()
      scrollFrame:SetVerticalScroll(height)
    end)

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

    -- Retrieve the correct spell icon
    local spellIcon = DM:GetSpellIcon(id)

    -- Debug message for spell icon
    DM:DebugMsg(string.format("Retrieved icon for %s (ID: %d): %s", dotInfo.name, id, spellIcon))

    -- Create row
    local row = CreateFrame("Frame", nil, self.dotsScrollChild)
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
    self.dotCheckboxes[tostring(id)] = checkbox

    -- Spell icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    icon:SetTexture(spellIcon)

    -- Spell name and ID
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    text:SetText(string.format("%s (ID: %d)", dotInfo.name, id))

    yOffset = yOffset + 30
  end

  -- Update scroll child height
  self.dotsScrollChild:SetHeight(math.max(yOffset + 10, 180))

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
