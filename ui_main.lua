--[[
  DotMaster - UI Main Module

  File: ui_main.lua
  Purpose: Main UI creation and management for the addon

  Functions:
    CreateMainFrame(): Creates the main UI frame
    ShowGUI(): Shows the main UI
    HideGUI(): Hides the main UI
    ToggleGUI(): Toggles the UI visibility

  Dependencies:
    DotMaster core
    ui_tabs.lua

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create UI main module
local UIMain = {}
DM.UIMain = UIMain

-- UI elements
local mainFrame = nil
local tabSystem = nil

-- Create the main frame
function UIMain:CreateMainFrame()
  if mainFrame then return mainFrame end

  DM:DebugMsg("Creating main UI frame...")

  -- Main frame
  mainFrame = CreateFrame("Frame", "DotMasterOptionsFrame", UIParent, "BackdropTemplate")
  mainFrame:SetSize(480, 450) -- Wider frame for better content display
  mainFrame:SetPoint("CENTER")
  mainFrame:SetFrameStrata("HIGH")
  mainFrame:SetMovable(true)
  mainFrame:EnableMouse(true)
  mainFrame:RegisterForDrag("LeftButton")
  mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
  mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

  -- Make frame resizable if supported
  if mainFrame.SetResizable then
    mainFrame:SetResizable(true)

    -- Set minimum size if supported
    if mainFrame.SetMinResize then
      mainFrame:SetMinResize(480, 300)
    else
      -- Alternative approach for versions that don't support SetMinResize
      mainFrame:SetScript("OnSizeChanged", function(self, width, height)
        -- Enforce minimum size
        if width < 480 then self:SetWidth(480) end
        if height < 300 then self:SetHeight(300) end
      end)
    end
  end

  mainFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  mainFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  mainFrame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.8)
  mainFrame:Hide()

  -- Add resize button at bottom right
  local resizeBtn = CreateFrame("Button", nil, mainFrame)
  resizeBtn:SetSize(16, 16)
  resizeBtn:SetPoint("BOTTOMRIGHT", -2, 2)
  resizeBtn:EnableMouse(true)

  -- Create an arrow texture for the resize button
  local resizeTexture = resizeBtn:CreateTexture(nil, "OVERLAY")
  resizeTexture:SetAllPoints()
  resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

  -- Highlight texture on hover
  local highlightTexture = resizeBtn:CreateTexture(nil, "HIGHLIGHT")
  highlightTexture:SetAllPoints()
  highlightTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

  -- Add on drag functionality
  resizeBtn:SetScript("OnMouseDown", function()
    if mainFrame.StartSizing then
      mainFrame:StartSizing("BOTTOMRIGHT")
    end
  end)

  resizeBtn:SetScript("OnMouseUp", function()
    if mainFrame.StopMovingOrSizing then
      mainFrame:StopMovingOrSizing()
    end
  end)

  -- Title
  local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("|cFFCC00FFDotMaster|r")

  -- Close Button
  local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -3, -3)
  closeButton:SetSize(26, 26)

  -- Author credit
  local author = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  author:SetPoint("BOTTOM", 0, 10)
  author:SetText("by Jervaise")

  -- Create tab system if available
  if DM.UITabs and DM.UITabs.CreateTabSystem then
    tabSystem = DM.UITabs:CreateTabSystem(mainFrame)
  else
    DM:DebugMsg("Warning: UITabs module not available")
  end

  -- Store references
  self.frame = mainFrame
  self.tabSystem = tabSystem

  DM:DebugMsg("Main UI frame created")
  return mainFrame
end

-- Show the GUI
function UIMain:ShowGUI()
  if not mainFrame then
    self:CreateMainFrame()
  end

  mainFrame:Show()
end

-- Hide the GUI
function UIMain:HideGUI()
  if mainFrame then
    mainFrame:Hide()
  end
end

-- Toggle GUI visibility
function UIMain:ToggleGUI()
  if not mainFrame then
    self:CreateMainFrame()
    mainFrame:Show()
    return
  end

  if mainFrame:IsShown() then
    mainFrame:Hide()
  else
    mainFrame:Show()
  end
end

-- Get the main frame
function UIMain:GetMainFrame()
  return mainFrame
end

-- Get the tab system
function UIMain:GetTabSystem()
  return tabSystem
end

-- Debug message function with module name
function UIMain:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[UIMain] " .. message)
  end
end

-- Connect to DM namespace for backward compatibility
function UIMain:ConnectToDMNamespace()
  -- Add legacy functions to DM namespace
  DM.OpenConfigGUI = function(self) UIMain:ShowGUI() end
  DM.CloseConfigGUI = function(self) UIMain:HideGUI() end
  DM.ToggleConfigGUI = function(self) UIMain:ToggleGUI() end
end

-- Initialize the module
function UIMain:Initialize()
  self:ConnectToDMNamespace()
  UIMain:DebugMsg("UI Main module initialized")
end

-- Return the module
return UIMain
