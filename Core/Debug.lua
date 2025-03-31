--[[
    DotMaster - Debug Module
    Comprehensive debug system for monitoring and troubleshooting
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Debug log storage
DotMaster.debugLog = {}

-- Performance metrics
DotMaster.performanceMetrics = {
  functionCalls = {},
  memoryUsage = {},
  frameRate = {}
}

-- Initialize debug system
function DotMaster:InitializeDebug()
  -- Create debug frame if it doesn't exist
  if not self.debugFrame then
    self.debugFrame = CreateFrame("Frame")
  end

  -- Set up debug level
  self.currentDebugLevel = self.DEBUG_LEVELS[self.db.profile.debug.level] or self.DEBUG_LEVELS.INFO

  -- Reset debug log
  self.debugLog = {}

  -- Set up performance monitoring if enabled
  if self.db.profile.debug.categories.PERFORMANCE then
    self:SetupPerformanceMonitoring()
  end

  self:Debug("CORE", "Debug system initialized")
end

-- Main debug function
function DotMaster:Debug(category, message, level)
  -- Convert level string to number if provided as string
  if type(level) == "string" and self.DEBUG_LEVELS[level] then
    level = self.DEBUG_LEVELS[level]
  end

  -- Default to DEBUG level if not specified
  level = level or self.DEBUG_LEVELS.DEBUG

  -- Check if debugging is enabled and the level is appropriate
  if not self.db.profile.debug.enabled or level > self.currentDebugLevel then
    return
  end

  -- Check if the specific category is enabled
  if category and not self.db.profile.debug.categories[category] then
    return
  end

  -- Format the debug message
  local levelName = "UNKNOWN"
  for k, v in pairs(self.DEBUG_LEVELS) do
    if v == level then
      levelName = k
      break
    end
  end

  local timestamp = date("%H:%M:%S.%f")
  local formattedMessage = string.format("[%s][%s][%s]: %s",
    timestamp, category, levelName, message)

  -- Add to debug log with limit on size
  table.insert(self.debugLog, {
    timestamp = timestamp,
    category = category,
    level = level,
    levelName = levelName,
    message = message,
    formattedMessage = formattedMessage
  })

  -- Trim log if it exceeds max size
  if #self.debugLog > self.PERFORMANCE.MAX_DEBUG_LOG_SIZE then
    table.remove(self.debugLog, 1)
  end

  -- Print to chat if dev mode is enabled
  if self.db.profile.debug.printToChat then
    -- Use different colors for different levels
    local color = "|cffffffff"     -- Default white
    if level == self.DEBUG_LEVELS.ERROR then
      color = "|cffff0000"         -- Red
    elseif level == self.DEBUG_LEVELS.WARNING then
      color = "|cffffaa00"         -- Orange
    elseif level == self.DEBUG_LEVELS.INFO then
      color = "|cff00aaff"         -- Blue
    elseif level == self.DEBUG_LEVELS.DEBUG then
      color = "|cff00ff00"         -- Green
    elseif level == self.DEBUG_LEVELS.TRACE then
      color = "|cffaa00ff"         -- Purple
    end

    -- Print to chat
    print(color .. formattedMessage .. "|r")
  end
end

-- Debug error level convenience function
function DotMaster:Error(category, message)
  self:Debug(category, message, self.DEBUG_LEVELS.ERROR)
end

-- Debug warning level convenience function
function DotMaster:Warning(category, message)
  self:Debug(category, message, self.DEBUG_LEVELS.WARNING)
end

-- Debug info level convenience function
function DotMaster:Info(category, message)
  self:Debug(category, message, self.DEBUG_LEVELS.INFO)
end

-- Debug trace level convenience function
function DotMaster:Trace(category, message)
  self:Debug(category, message, self.DEBUG_LEVELS.TRACE)
end

-- Set debug level
function DotMaster:SetDebugLevel(level)
  if type(level) == "string" then
    if self.DEBUG_LEVELS[level] then
      self.currentDebugLevel = self.DEBUG_LEVELS[level]
      self.db.profile.debug.level = level
      self:Debug("CORE", "Debug level set to " .. level, self.DEBUG_LEVELS.INFO)
    else
      self:Error("CORE", "Invalid debug level: " .. level)
    end
  elseif type(level) == "number" then
    -- Find level name for this number
    for k, v in pairs(self.DEBUG_LEVELS) do
      if v == level then
        self.currentDebugLevel = level
        self.db.profile.debug.level = k
        self:Debug("CORE", "Debug level set to " .. k, self.DEBUG_LEVELS.INFO)
        return
      end
    end
    self:Error("CORE", "Invalid debug level number: " .. level)
  end
end

-- Toggle debug category
function DotMaster:ToggleDebugCategory(category, enabled)
  if not self.DEBUG_CATEGORIES[category] then
    self:Error("CORE", "Invalid debug category: " .. category)
    return
  end

  -- If enabled is not provided, toggle the current state
  if enabled == nil then
    enabled = not self.db.profile.debug.categories[category]
  end

  self.db.profile.debug.categories[category] = enabled
  self:Debug("CORE", "Debug category " .. category .. " " .. (enabled and "enabled" or "disabled"),
    self.DEBUG_LEVELS.INFO)

  -- Special handling for performance monitoring
  if category == "PERFORMANCE" then
    if enabled then
      self:SetupPerformanceMonitoring()
    else
      self:DisablePerformanceMonitoring()
    end
  end
end

-- Setup performance monitoring
function DotMaster:SetupPerformanceMonitoring()
  -- Reset performance metrics
  self.performanceMetrics = {
    functionCalls = {},
    memoryUsage = {},
    frameRate = {}
  }

  -- Start memory tracking
  self.lastMemoryCheck = GetTime()
  self.debugFrame:SetScript("OnUpdate", function(_, elapsed)
    self:UpdatePerformanceMetrics(elapsed)
  end)

  self:Debug("PERFORMANCE", "Performance monitoring enabled")
end

-- Disable performance monitoring
function DotMaster:DisablePerformanceMonitoring()
  self.debugFrame:SetScript("OnUpdate", nil)
  self:Debug("PERFORMANCE", "Performance monitoring disabled")
end

-- Update performance metrics
function DotMaster:UpdatePerformanceMetrics(elapsed)
  -- Only check periodically (every 5 seconds)
  local currentTime = GetTime()
  if not self.lastMemoryCheck or (currentTime - self.lastMemoryCheck) > 5 then
    -- Memory usage
    local memoryUsage = collectgarbage("count")
    table.insert(self.performanceMetrics.memoryUsage, {
      time = currentTime,
      usage = memoryUsage
    })

    -- Trim history to last 20 readings
    if #self.performanceMetrics.memoryUsage > 20 then
      table.remove(self.performanceMetrics.memoryUsage, 1)
    end

    self.lastMemoryCheck = currentTime
    self:Debug("PERFORMANCE", string.format("Memory usage: %.2f KB", memoryUsage), self.DEBUG_LEVELS.TRACE)
  end

  -- Frame rate
  if self.lastFrameRateCheck then
    local fps = 1 / elapsed
    table.insert(self.performanceMetrics.frameRate, {
      time = currentTime,
      fps = fps
    })

    -- Trim history to last 100 readings
    if #self.performanceMetrics.frameRate > 100 then
      table.remove(self.performanceMetrics.frameRate, 1)
    end
  end
  self.lastFrameRateCheck = currentTime
end

-- Performance-wrapped function call
function DotMaster:ProfileFunction(category, funcName, func, ...)
  if not self.db.profile.debug.enabled or
      not self.db.profile.debug.categories.PERFORMANCE then
    -- If performance monitoring is disabled, just call the function
    return func(...)
  end

  local startTime = GetTime()
  local results = { func(...) }
  local endTime = GetTime()
  local executionTime = (endTime - startTime) * 1000   -- Convert to ms

  -- Record function call
  table.insert(self.performanceMetrics.functionCalls, {
    category = category,
    name = funcName,
    time = executionTime,
    timestamp = endTime
  })

  -- Trim history to last 100 calls
  if #self.performanceMetrics.functionCalls > 100 then
    table.remove(self.performanceMetrics.functionCalls, 1)
  end

  -- Log if execution time is high
  if executionTime > 10 then   -- 10ms is considered high for a single function
    self:Debug("PERFORMANCE", string.format("Function %s.%s took %.2f ms to execute",
      category, funcName, executionTime), self.DEBUG_LEVELS.WARNING)
  elseif self.db.profile.debug.verbose then
    self:Debug("PERFORMANCE", string.format("Function %s.%s took %.2f ms to execute",
      category, funcName, executionTime), self.DEBUG_LEVELS.TRACE)
  end

  return unpack(results)
end

-- Handle specific debug commands
function DotMaster:HandleDebugCommand(...)
  local args = { ... }

  if #args == 0 then
    -- Open debug UI if no args
    self:OpenDebugUI()
    return
  end

  local subcommand = args[1]

  if subcommand == "toggle" then
    -- Toggle master debug
    self.db.profile.debug.enabled = not self.db.profile.debug.enabled
    self:Print("Debug mode " .. (self.db.profile.debug.enabled and "enabled" or "disabled"))
  elseif subcommand == "level" and args[2] then
    -- Set debug level
    self:SetDebugLevel(args[2])
  elseif subcommand == "category" and args[2] then
    -- Toggle debug category
    local category = args[2]
    local enabled = args[3] == "on" and true or args[3] == "off" and false or nil
    self:ToggleDebugCategory(category, enabled)
  elseif subcommand == "list" then
    -- List all categories
    self:Print("Debug categories:")
    for category, _ in pairs(self.DEBUG_CATEGORIES) do
      local status = self.db.profile.debug.categories[category] and "on" or "off"
      self:Print(string.format("  %s: %s", category, status))
    end
  elseif subcommand == "stats" then
    -- Print performance stats
    self:PrintPerformanceStats()
  elseif subcommand == "dump" then
    -- Export debug log
    self:ExportDebugLog()
  elseif subcommand == "clear" then
    -- Clear debug log
    self.debugLog = {}
    self:Print("Debug log cleared")
  elseif subcommand == "help" then
    -- Show debug command help
    self:PrintDebugHelp()
  else
    self:Print("Unknown debug command: " .. subcommand)
    self:PrintDebugHelp()
  end
end

-- Print debug command help
function DotMaster:PrintDebugHelp()
  self:Print("Debug commands:")
  self:Print("/dm debug - Open debug UI")
  self:Print("/dm debug toggle - Toggle master debug mode")
  self:Print("/dm debug level [ERROR|WARNING|INFO|DEBUG|TRACE] - Set debug level")
  self:Print("/dm debug category [CATEGORY] [on|off] - Toggle specific category")
  self:Print("/dm debug list - List all debug categories")
  self:Print("/dm debug stats - Show performance statistics")
  self:Print("/dm debug dump - Export debug log")
  self:Print("/dm debug clear - Clear debug log")
  self:Print("/dm debug help - Show this help")
end

-- Print performance statistics
function DotMaster:PrintPerformanceStats()
  if not self.db.profile.debug.categories.PERFORMANCE then
    self:Print("Performance monitoring is not enabled")
    return
  end

  -- Memory usage
  local memoryUsage = collectgarbage("count")
  self:Print(string.format("Current memory usage: %.2f KB", memoryUsage))

  -- Average FPS if available
  if #self.performanceMetrics.frameRate > 0 then
    local totalFps = 0
    for _, frame in ipairs(self.performanceMetrics.frameRate) do
      totalFps = totalFps + frame.fps
    end
    local avgFps = totalFps / #self.performanceMetrics.frameRate
    self:Print(string.format("Average FPS: %.1f", avgFps))
  end

  -- Function call stats
  if #self.performanceMetrics.functionCalls > 0 then
    -- Group by function name
    local funcStats = {}
    for _, call in ipairs(self.performanceMetrics.functionCalls) do
      local key = call.category .. "." .. call.name
      if not funcStats[key] then
        funcStats[key] = {
          count = 0,
          totalTime = 0,
          maxTime = 0
        }
      end

      funcStats[key].count = funcStats[key].count + 1
      funcStats[key].totalTime = funcStats[key].totalTime + call.time
      funcStats[key].maxTime = math.max(funcStats[key].maxTime, call.time)
    end

    -- Sort by total time
    local sortedFuncs = {}
    for name, stats in pairs(funcStats) do
      table.insert(sortedFuncs, {
        name = name,
        count = stats.count,
        totalTime = stats.totalTime,
        avgTime = stats.totalTime / stats.count,
        maxTime = stats.maxTime
      })
    end

    table.sort(sortedFuncs, function(a, b) return a.totalTime > b.totalTime end)

    -- Print top 5 functions
    self:Print("Top 5 functions by execution time:")
    for i = 1, math.min(5, #sortedFuncs) do
      local func = sortedFuncs[i]
      self:Print(string.format("%d. %s - %d calls, %.2f ms total, %.2f ms avg, %.2f ms max",
        i, func.name, func.count, func.totalTime, func.avgTime, func.maxTime))
    end
  end
end

-- Export debug log
function DotMaster:ExportDebugLog()
  if #self.debugLog == 0 then
    self:Print("Debug log is empty")
    return
  end

  -- Create a string with the log content
  local logText = "DotMaster Debug Log - " .. date("%Y-%m-%d %H:%M:%S") .. "\n\n"
  for _, entry in ipairs(self.debugLog) do
    logText = logText .. entry.formattedMessage .. "\n"
  end

  -- Display in UI for copying
  self:ShowExportFrame(logText)
end

-- Show export frame with text
function DotMaster:ShowExportFrame(text)
  -- Create frame if it doesn't exist
  if not self.exportFrame then
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("DotMaster Debug Log")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetSize(scrollFrame:GetSize())
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    scrollFrame:SetScrollChild(editBox)

    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(100, 25)
    button:SetPoint("BOTTOM", 0, 10)
    button:SetText("Close")
    button:SetScript("OnClick", function() frame:Hide() end)

    frame.title = title
    frame.scrollFrame = scrollFrame
    frame.editBox = editBox
    frame.button = button

    self.exportFrame = frame
  end

  -- Set text and show frame
  self.exportFrame.editBox:SetText(text)
  self.exportFrame.editBox:HighlightText()
  self.exportFrame:Show()
end
