-- debug.lua
-- DotMaster Debug System

local DM = DotMaster -- reference to main addon
local Debug = {}     -- local table for module functions
DM.Debug = Debug     -- expose to addon namespace

-- Debug category constants
Debug.CATEGORY = {
  GENERAL = "General",
  DATABASE = "Database",
  PERFORMANCE = "Performance",
  UI = "UI Events",
  LOADING = "Loading/Init",
  API = "API Calls",
  COMBAT = "Combat",
  ERROR = "Errors"
}

-- Settings
local defaults = {
  enabled = true,
  maxEntries = 500,
  categories = {
    [Debug.CATEGORY.GENERAL] = true,
    [Debug.CATEGORY.DATABASE] = true,
    [Debug.CATEGORY.PERFORMANCE] = true,
    [Debug.CATEGORY.UI] = true,
    [Debug.CATEGORY.LOADING] = true,
    [Debug.CATEGORY.API] = true,
    [Debug.CATEGORY.COMBAT] = false,
    [Debug.CATEGORY.ERROR] = true
  },
  autoScrollToBottom = true,
  showTimestamps = true,
  filterString = ""
}

-- Local variables
local messageQueue = {}
local messageCount = 0
local throttleTimers = {}
local pendingMsgCount = 0
local MAX_PENDING_MSGS = 20

-- Color schemes for different categories
local COLORS = {
  [Debug.CATEGORY.GENERAL] = { r = 1.0, g = 1.0, b = 1.0 },
  [Debug.CATEGORY.DATABASE] = { r = 0.0, g = 0.7, b = 1.0 },
  [Debug.CATEGORY.PERFORMANCE] = { r = 1.0, g = 0.7, b = 0.0 },
  [Debug.CATEGORY.UI] = { r = 0.7, g = 1.0, b = 0.7 },
  [Debug.CATEGORY.LOADING] = { r = 0.7, g = 0.7, b = 1.0 },
  [Debug.CATEGORY.API] = { r = 1.0, g = 0.5, b = 1.0 },
  [Debug.CATEGORY.COMBAT] = { r = 1.0, g = 0.3, b = 0.3 },
  [Debug.CATEGORY.ERROR] = { r = 1.0, g = 0.0, b = 0.0 },
  TIMESTAMP = { r = 0.5, g = 0.5, b = 0.5 }
}

-- Forward declaration for the frame (will be created in gui_debug_console.lua)
local debugFrame = nil

-- Local helper functions
local function getCategoryColor(category)
  return COLORS[category] or COLORS[Debug.CATEGORY.GENERAL]
end

local function formatTimestamp()
  local timestamp = date("%H:%M:%S")
  return timestamp
end

local function applyMessageFilter(message, filter)
  if not filter or filter == "" then
    return true
  end

  return string.find(message.text:lower(), filter:lower()) ~= nil
end

local function processMessageQueue()
  if not DM.debugFrame or pendingMsgCount == 0 then
    return
  end

  local filter = Debug.GetSettings().filterString
  local processedCount = 0

  for i = 1, math.min(pendingMsgCount, MAX_PENDING_MSGS) do
    local msg = table.remove(messageQueue, 1)
    if msg and applyMessageFilter(msg, filter) then
      DM.debugFrame:AddMessage(msg)
      processedCount = processedCount + 1
    end
  end

  pendingMsgCount = pendingMsgCount - processedCount

  if pendingMsgCount > 0 then
    C_Timer.After(0.1, processMessageQueue)
  end
end

-- Public API

-- Add a message to the debug console
function Debug:Log(category, text, ...)
  if not self:IsCategoryEnabled(category) then
    return
  end

  -- Format the text if there are additional parameters
  if ... then
    text = string.format(text, ...)
  end

  -- Create message object
  local message = {
    text = text,
    category = category or Debug.CATEGORY.GENERAL,
    timestamp = formatTimestamp(),
    colorRGB = getCategoryColor(category)
  }

  -- Add to message queue
  table.insert(messageQueue, message)
  pendingMsgCount = pendingMsgCount + 1
  messageCount = messageCount + 1

  -- Process the queue if this is the first message
  if pendingMsgCount == 1 then
    C_Timer.After(0.01, processMessageQueue)
  end

  -- Prune old messages if we're over the limit
  if messageCount > Debug.GetSettings().maxEntries then
    if #messageQueue > Debug.GetSettings().maxEntries then
      local toRemove = #messageQueue - Debug.GetSettings().maxEntries
      for i = 1, toRemove do
        table.remove(messageQueue, 1)
        pendingMsgCount = pendingMsgCount - 1
      end
    end
  end
end

-- Throttled logging - only logs once every X seconds for the same key
function Debug:LogThrottled(key, interval, category, text, ...)
  if not key or not interval then return end

  local now = GetTime()
  if not throttleTimers[key] or (now - throttleTimers[key] > interval) then
    throttleTimers[key] = now
    self:Log(category, text, ...)
  end
end

-- Performance logging
function Debug:LogPerformance(label, fn, ...)
  if not self:IsCategoryEnabled(Debug.CATEGORY.PERFORMANCE) then
    return fn(...)
  end

  local startTime = debugprofilestop()
  local result = { fn(...) }
  local endTime = debugprofilestop()

  self:Log(Debug.CATEGORY.PERFORMANCE, "%s: %.2fms", label, endTime - startTime)

  return unpack(result)
end

-- Error logging
function Debug:LogError(text, ...)
  self:Log(Debug.CATEGORY.ERROR, text, ...)
end

-- Clear the console
function Debug:Clear()
  messageQueue = {}
  pendingMsgCount = 0
  messageCount = 0

  if DM.debugFrame then
    DM.debugFrame:Clear()
  end
end

-- Check if a category is enabled
function Debug:IsCategoryEnabled(category)
  if not category then return false end
  if not Debug.GetSettings().enabled then return false end
  return Debug.GetSettings().categories[category] or false
end

-- Enable/disable a category
function Debug:SetCategoryEnabled(category, enabled)
  local settings = Debug.GetSettings()
  if settings.categories[category] ~= nil then
    settings.categories[category] = enabled
    Debug.SaveSettings(settings)
  end
end

-- Toggle a category on/off
function Debug:ToggleCategory(category)
  local settings = Debug.GetSettings()
  if settings.categories[category] ~= nil then
    settings.categories[category] = not settings.categories[category]
    Debug.SaveSettings(settings)
  end
end

-- Enable/disable all categories
function Debug:SetAllCategories(enabled)
  local settings = Debug.GetSettings()
  for category, _ in pairs(settings.categories) do
    settings.categories[category] = enabled
  end
  Debug.SaveSettings(settings)
end

-- Get debug settings from SavedVariables
function Debug.GetSettings()
  if not DM.db or not DM.db.debug then
    return defaults
  end
  return DM.db.debug
end

-- Save debug settings to SavedVariables
function Debug.SaveSettings(settings)
  if not DM.db then return end

  DM.db.debug = DM.db.debug or {}

  -- Only save what's in defaults
  for k, v in pairs(settings) do
    if defaults[k] ~= nil then
      if type(v) == "table" then
        DM.db.debug[k] = DM.db.debug[k] or {}
        for subk, subv in pairs(v) do
          if type(defaults[k]) == "table" and defaults[k][subk] ~= nil then
            DM.db.debug[k][subk] = subv
          end
        end
      else
        DM.db.debug[k] = v
      end
    end
  end
end

-- Initialize the debug system
function Debug:Initialize()
  -- Initialize settings
  if DM.db and not DM.db.debug then
    DM.db.debug = CopyTable(defaults)
  end

  -- Log initialization
  self:Log(Debug.CATEGORY.LOADING, "Debug system initialized")

  -- Register for events if needed
  -- ...

  return self
end

-- Convenience logging functions for each category
function Debug:General(text, ...) self:Log(Debug.CATEGORY.GENERAL, text, ...) end

function Debug:Database(text, ...) self:Log(Debug.CATEGORY.DATABASE, text, ...) end

function Debug:Performance(text, ...) self:Log(Debug.CATEGORY.PERFORMANCE, text, ...) end

function Debug:UI(text, ...) self:Log(Debug.CATEGORY.UI, text, ...) end

function Debug:Loading(text, ...) self:Log(Debug.CATEGORY.LOADING, text, ...) end

function Debug:API(text, ...) self:Log(Debug.CATEGORY.API, text, ...) end

function Debug:Combat(text, ...) self:Log(Debug.CATEGORY.COMBAT, text, ...) end

function Debug:Error(text, ...) self:Log(Debug.CATEGORY.ERROR, text, ...) end

return Debug
