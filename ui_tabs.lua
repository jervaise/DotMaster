--[[
  DotMaster - UI Tabs Module

  File: ui_tabs.lua
  Purpose: Handles tab creation and management for the GUI

  Functions:
    CreateTabSystem(): Creates the tab system in the main frame
    SwitchToTab(): Switches to a specific tab
    AddTab(): Adds a new tab to the tab system

  Dependencies:
    DotMaster core

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create UI tabs module
local UITabs = {}
DM.UITabs = UITabs

-- Tab frame references
local tabFrames = {}
local tabButtons = {}
local activeTab = 1
local tabHeight = 30

-- Create tab system for the main frame
function UITabs:CreateTabSystem(parentFrame)
  -- Tab background
  local tabBg = parentFrame:CreateTexture(nil, "BACKGROUND")
  tabBg:SetPoint("TOPLEFT", 8, -40)
  tabBg:SetPoint("TOPRIGHT", -8, -40)
  tabBg:SetHeight(tabHeight)
  tabBg:SetColorTexture(0.15, 0.15, 0.15, 0.6)

  -- Store reference
  self.parentFrame = parentFrame
  self.tabBackground = tabBg
  self.tabCount = 0

  return self
end

-- Add a new tab to the system
function UITabs:AddTab(title, contentCreationFunc)
  local i = self.tabCount + 1
  self.tabCount = i

  -- Tab content frame
  tabFrames[i] = CreateFrame("Frame", "DotMasterTabFrame" .. i, self.parentFrame)
  tabFrames[i]:SetPoint("TOPLEFT", 10, -(45 + tabHeight))
  tabFrames[i]:SetPoint("BOTTOMRIGHT", -10, 30)
  tabFrames[i]:Hide()

  -- Custom tab button
  local tabButton = CreateFrame("Button", "DotMasterTab" .. i, self.parentFrame)
  tabButton:SetSize(100, tabHeight)

  -- Tab styling
  local normalTexture = tabButton:CreateTexture(nil, "BACKGROUND")
  normalTexture:SetAllPoints()
  normalTexture:SetColorTexture(0.1, 0.1, 0.1, 0.7)

  -- Tab text
  local text = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("CENTER")
  text:SetText(title)
  text:SetTextColor(1, 0.82, 0)

  -- Store ID and script
  tabButton.id = i
  tabButton:SetScript("OnClick", function(self)
    UITabs:SwitchToTab(self.id)
  end)

  -- Position tab
  tabButton:SetPoint("TOPLEFT", self.parentFrame, "TOPLEFT", 10 + (i - 1) * 105, -40)

  -- Store reference
  tabButtons[i] = tabButton

  -- Initialize content if function provided
  if contentCreationFunc then
    contentCreationFunc(tabFrames[i])
  end

  -- If this is the first tab, make it active
  if i == 1 then
    self:SwitchToTab(1)
  end

  return tabFrames[i]
end

-- Switch to a specific tab
function UITabs:SwitchToTab(tabIndex)
  -- Hide all frames and deselect all tabs
  for j, tabFrame in ipairs(tabFrames) do
    tabFrame:Hide()
    if tabButtons[j] and tabButtons[j].GetRegions then
      tabButtons[j]:GetRegions():SetColorTexture(0.1, 0.1, 0.1, 0.7)
    end
  end

  -- Show selected frame and highlight tab
  if tabFrames[tabIndex] then
    tabFrames[tabIndex]:Show()
  end

  if tabButtons[tabIndex] and tabButtons[tabIndex].GetRegions then
    tabButtons[tabIndex]:GetRegions():SetColorTexture(0.3, 0.3, 0.3, 0.8)
  end

  activeTab = tabIndex
end

-- Get active tab index
function UITabs:GetActiveTabIndex()
  return activeTab
end

-- Get tab frame by index
function UITabs:GetTabFrame(index)
  return tabFrames[index]
end

-- Debug message function with module name
function UITabs:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[UITabs] " .. message)
  end
end

-- Initialize the module
function UITabs:Initialize()
  UITabs:DebugMsg("UI Tabs module initialized")
end

-- Return the module
return UITabs
