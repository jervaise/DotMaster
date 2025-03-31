--[[
    DotMaster - Find My Dots Module
    Provides a window showing all active DoTs and their timers
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Initialize Find My Dots feature
function DotMaster:InitializeFindMyDots()
  -- Create the frame if it doesn't exist
  if not self.findMyDotsFrame then
    self:CreateFindMyDotsFrame()
  end

  -- Show the frame if enabled
  if self.db.profile.findMyDots.enabled then
    self.findMyDotsFrame:Show()
  else
    self.findMyDotsFrame:Hide()
  end

  -- Set up update timer
  if not self.findMyDotsTimer then
    self.findMyDotsTimer = self:ScheduleRepeatingTimer("UpdateFindMyDotsDisplay", 0.1)
  end

  self:Debug("DOT", "Find My Dots module initialized")
end

-- Disable Find My Dots feature
function DotMaster:DisableFindMyDots()
  -- Hide the frame
  if self.findMyDotsFrame then
    self.findMyDotsFrame:Hide()
  end

  -- Cancel update timer
  if self.findMyDotsTimer then
    self:CancelTimer(self.findMyDotsTimer)
    self.findMyDotsTimer = nil
  end

  self:Debug("DOT", "Find My Dots module disabled")
end

-- Create the Find My Dots frame
function DotMaster:CreateFindMyDotsFrame()
  local frame = CreateFrame("Frame", "DotMasterFindMyDots", UIParent, "BackdropTemplate")
  frame:SetFrameStrata("MEDIUM")
  frame:SetSize(300, 400)

  -- Set position (default to center)
  if self.db.profile.findMyDots.position then
    local pos = self.db.profile.findMyDots.position
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end

  -- Set scale and opacity
  frame:SetScale(self.db.profile.findMyDots.scale or 1.0)

  -- Make movable unless locked
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if not DotMaster.db.profile.findMyDots.lockPosition then
      self:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    DotMaster.db.profile.findMyDots.position = { point, relativePoint, xOfs, yOfs }
  end)

  -- Create background
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  frame:SetBackdropColor(0, 0, 0, self.db.profile.findMyDots.opacity or 1.0)

  -- Create header
  local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  header:SetHeight(30)
  header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  header:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Header",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  header:SetBackdropColor(0, 0, 0, 1)

  -- Create title
  local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", header, "TOP", 0, -10)
  title:SetText("Find My Dots")

  -- Create close button
  local closeButton = CreateFrame("Button", nil, header, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, -2)
  closeButton:SetScript("OnClick", function()
    frame:Hide()
    DotMaster.db.profile.findMyDots.enabled = false
  end)

  -- Create content frame
  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 8, 0)
  content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)

  -- Create scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -26, 0)

  -- Create scroll child
  local scrollChild = CreateFrame("Frame")
  scrollFrame:SetScrollChild(scrollChild)
  scrollChild:SetWidth(scrollFrame:GetWidth())
  scrollChild:SetHeight(1)   -- Will expand as needed

  -- Store references
  frame.header = header
  frame.title = title
  frame.content = content
  frame.scrollFrame = scrollFrame
  frame.scrollChild = scrollChild

  -- Hide by default
  frame:Hide()

  -- Store frame reference
  self.findMyDotsFrame = frame

  self:Debug("DOT", "Find My Dots frame created")
  return frame
end

-- Update the Find My Dots display
function DotMaster:UpdateFindMyDotsDisplay()
  -- Skip if the frame doesn't exist or isn't visible
  if not self.findMyDotsFrame or not self.findMyDotsFrame:IsShown() then
    return
  end

  local scrollChild = self.findMyDotsFrame.scrollChild

  -- Clear existing content
  for _, child in pairs({ scrollChild:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end

  -- Get all active DoTs
  local activeDoTs = self:GetAllActiveDoTs()

  -- Group DoTs by target for better organization
  local dotsByTarget = {}
  for _, dot in ipairs(activeDoTs) do
    if not dotsByTarget[dot.targetName] then
      dotsByTarget[dot.targetName] = {}
    end
    table.insert(dotsByTarget[dot.targetName], dot)
  end

  -- Sort targets by name
  local sortedTargets = {}
  for targetName, _ in pairs(dotsByTarget) do
    table.insert(sortedTargets, targetName)
  end
  table.sort(sortedTargets)

  -- Track Y position for each element
  local yOffset = 5

  -- Show message if no DoTs are active
  if #activeDoTs == 0 then
    local noDotsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noDotsText:SetPoint("TOP", scrollChild, "TOP", 0, -yOffset)
    noDotsText:SetText("No active DoTs found")
    noDotsText:SetTextColor(1, 1, 1)

    yOffset = yOffset + 20
  else
    -- Create elements for each target
    for _, targetName in ipairs(sortedTargets) do
      local dots = dotsByTarget[targetName]

      -- Create target header
      local targetHeader = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
      targetHeader:SetHeight(25)
      targetHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
      targetHeader:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
      targetHeader:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
      })
      targetHeader:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

      local targetText = targetHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      targetText:SetPoint("LEFT", targetHeader, "LEFT", 8, 0)
      targetText:SetText(targetName)
      targetText:SetTextColor(1, 1, 1)

      yOffset = yOffset + 25

      -- Sort DoTs by time remaining (shortest first)
      table.sort(dots, function(a, b)
        return a.timeLeft < b.timeLeft
      end)

      -- Add each DoT
      for _, dot in ipairs(dots) do
        local dotFrame = CreateFrame("Frame", nil, scrollChild)
        dotFrame:SetHeight(24)
        dotFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, -yOffset)
        dotFrame:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -8, -yOffset)

        -- Add spell icon if enabled
        if self.db.profile.findMyDots.showIcon then
          local icon = dotFrame:CreateTexture(nil, "ARTWORK")
          icon:SetSize(20, 20)
          icon:SetPoint("LEFT", dotFrame, "LEFT", 0, 0)
          icon:SetTexture(dot.icon)
          icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)           -- Remove icon border

          -- Add count if > 1 and enabled
          if dot.count and dot.count > 1 and self.db.profile.findMyDots.showCount then
            local countText = dotFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            countText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
            countText:SetText(dot.count)
          end
        end

        -- Add spell name if enabled
        if self.db.profile.findMyDots.showName then
          local nameText = dotFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
          nameText:SetPoint("LEFT", dotFrame, "LEFT", self.db.profile.findMyDots.showIcon and 25 or 5, 0)
          nameText:SetText(dot.name)
        end

        -- Add timer if enabled
        if self.db.profile.findMyDots.showTimer then
          local timerText = dotFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
          timerText:SetPoint("RIGHT", dotFrame, "RIGHT", -5, 0)

          -- Color based on time remaining
          local r, g, b = 1, 1, 1
          if dot.timeLeft < 3 then
            r, g, b = 1, 0, 0               -- Red for about to expire
          elseif dot.timeLeft < 6 then
            r, g, b = 1, 0.5, 0             -- Orange for expiring soon
          elseif dot.timeLeft < 10 then
            r, g, b = 0, 1, 0               -- Green for good duration
          end

          timerText:SetTextColor(r, g, b)
          timerText:SetText(self:FormatTime(dot.timeLeft))

          -- Update timer text on each frame
          dotFrame:SetScript("OnUpdate", function(self, elapsed)
            self.updateTimer = (self.updateTimer or 0) + elapsed
            if self.updateTimer >= 0.1 then
              self.updateTimer = 0
              dot.timeLeft = dot.expirationTime - GetTime()
              if dot.timeLeft <= 0 then
                self:Hide()
                DotMaster:UpdateFindMyDotsDisplay()
                return
              end

              -- Update timer text
              timerText:SetText(DotMaster:FormatTime(dot.timeLeft))

              -- Update color based on time remaining
              if dot.timeLeft < 3 then
                r, g, b = 1, 0, 0                   -- Red for about to expire
              elseif dot.timeLeft < 6 then
                r, g, b = 1, 0.5, 0                 -- Orange for expiring soon
              elseif dot.timeLeft < 10 then
                r, g, b = 0, 1, 0                   -- Green for good duration
              else
                r, g, b = 1, 1, 1                   -- White for long duration
              end

              timerText:SetTextColor(r, g, b)
            end
          end)
        end

        yOffset = yOffset + 24
      end

      -- Add spacing between targets
      yOffset = yOffset + 5
    end
  end

  -- Update scroll child height
  scrollChild:SetHeight(math.max(1, yOffset))
end

-- Toggle Find My Dots visibility
function DotMaster:ToggleFindMyDots()
  if not self.findMyDotsFrame then
    self:InitializeFindMyDots()
  end

  if self.findMyDotsFrame:IsShown() then
    self.findMyDotsFrame:Hide()
    self.db.profile.findMyDots.enabled = false
  else
    self.findMyDotsFrame:Show()
    self.db.profile.findMyDots.enabled = true
  end

  self:Debug("DOT", "Find My Dots visibility toggled to " .. (self.db.profile.findMyDots.enabled and "shown" or "hidden"))
end

-- Apply settings to Find My Dots frame
function DotMaster:ApplyFindMyDotsSettings()
  if not self.findMyDotsFrame then return end

  -- Apply scale
  self.findMyDotsFrame:SetScale(self.db.profile.findMyDots.scale or 1.0)

  -- Apply opacity
  self.findMyDotsFrame:SetBackdropColor(0, 0, 0, self.db.profile.findMyDots.opacity or 1.0)

  -- Show/hide based on settings
  if self.db.profile.findMyDots.enabled then
    self.findMyDotsFrame:Show()
  else
    self.findMyDotsFrame:Hide()
  end

  -- Force refresh of content
  self:UpdateFindMyDotsDisplay()

  self:Debug("DOT", "Find My Dots settings applied")
end

-- Format time for display
function DotMaster:FormatTime(seconds)
  if seconds < 0 then seconds = 0 end

  if seconds < 60 then
    return string.format("%.1fs", seconds)
  else
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
  end
end
