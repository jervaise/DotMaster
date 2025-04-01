--[[
Name: DBIcon-1.0
Revision: $Rev: 15 $
Author(s): Rabbit (rabbit.magtheridon@gmail.com)
Description: Minimap icon library for LibDataBroker-1.1 data objects.
Dependencies: LibStub, LibDataBroker-1.1
License: GPL v2 or later
]]

local DBICON10 = "LibDBIcon-1.0"
local DBICON10_MINOR = 34 -- Bump on changes
if not LibStub then error(DBICON10 .. " requires LibStub.") end
local ldb = LibStub("LibDataBroker-1.1", true)
if not ldb then error(DBICON10 .. " requires LibDataBroker-1.1.") end
local lib = LibStub:NewLibrary(DBICON10, DBICON10_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or nil
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.radius = lib.radius or 80
lib.tooltip = lib.tooltip or GameTooltip
local next, Minimap, CreateFrame = next, Minimap, CreateFrame
lib.tooltip:SetClampedToScreen(true)

function lib:IconCallback(event, name, key, value, dataobj)
  if lib.objects[name] then
    lib.objects[name].icon:SetTexture(dataobj.icon)
  end
end

function lib:Embed(target)
  target.dbIcon = target.dbIcon or {}
  for k, v in pairs(lib) do
    if type(v) == "function" then
      target.dbIcon[k] = v
    end
  end
  return target
end

function lib:IsRegistered(name)
  return self.objects[name] and true or false
end

local function getAnchors(frame)
  local x, y = frame:GetCenter()
  if not x or not y then return "CENTER" end
  local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
  local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
  return vhalf .. hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf
end

local function onEnter(self)
  if self.isMoving then return end
  local obj = self.dataObject
  if obj.OnTooltipShow then
    lib.tooltip:SetOwner(self, "ANCHOR_NONE")
    lib.tooltip:SetPoint(getAnchors(self))
    obj.OnTooltipShow(lib.tooltip)
    lib.tooltip:Show()
  elseif obj.OnEnter then
    obj.OnEnter(self)
  end
end

local function onLeave(self)
  local obj = self.dataObject
  lib.tooltip:Hide()
  if obj.OnLeave then obj.OnLeave(self) end
end

--------------------------------------------------------------------------------

local onClick, onMouseUp, onMouseDown, onDragStart, onDragStop, updatePosition

do
  local minimapShapes = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
  }

  local rad, cos, sin, sqrt, max, min = math.rad, math.cos, math.sin, math.sqrt, math.max, math.min
  function updatePosition(button, position)
    local angle = rad(position or 225)
    local x, y, q = cos(angle), sin(angle), 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadTable = minimapShapes[minimapShape]
    local w = (Minimap:GetWidth() / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    if quadTable[q] then
      x, y = x * w, y * h
    else
      local diagRadiusW = sqrt(2 * (w) ^ 2) - 10
      local diagRadiusH = sqrt(2 * (h) ^ 2) - 10
      x = max(-w, min(x * diagRadiusW, w))
      y = max(-h, min(y * diagRadiusH, h))
    end
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end
end

function onClick(self, b) -- Minimap:OnClick
  local obj = self.dataObject
  if obj.OnClick then
    obj.OnClick(self, b)
  end
end

function onMouseDown(self) -- Minimap Icon:OnMouseDown
  self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
end

function onMouseUp(self) -- Minimap Icon:OnMouseUp
  self.icon:SetTexCoord(0, 1, 0, 1)
end

function onDragStart(self)
  self:LockHighlight()
  self.icon:SetTexCoord(0, 1, 0, 1)
  self:SetScript("OnUpdate", function(self)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    local position = 225
    if self.db then
      position = math.deg(math.atan2(py - my, px - mx)) % 360
      self.db.minimapPos = position
    else
      position = math.deg(math.atan2(py - my, px - mx)) % 360
      self.minimapPos = position
    end
    updatePosition(self, position)
  end)
  self.isMoving = true
  GameTooltip:Hide()
end

function onDragStop(self)
  self:SetScript("OnUpdate", nil)
  self.icon:SetTexCoord(0, 1, 0, 1)
  self:UnlockHighlight()
  self.isMoving = nil
end

---------------------------------------------------------------------------

local methods = {
  Register = function(self, dataObject, optDatabase)
    if self:IsRegistered(dataObject.name) then return false end

    if not optDatabase then
      optDatabase = self.defaultDatabase or LibStub("AceDB-3.0", true) and LibStub("AceDB-3.0"):New(self.name .. "DB", {
        profile = {
          minimap = {
            hide = false,
            minimapPos = 220,
          }
        }
      })
    end

    local button = CreateFrame("Button", "LibDBIcon10_" .. dataObject.name, Minimap)
    button.dataObject = dataObject
    button.db = optDatabase
    button:SetFrameStrata("MEDIUM")
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameLevel(8)
    button:RegisterForClicks("anyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetTexture(dataObject.icon)
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetPoint("TOPLEFT", 7, -6)
    button.icon = icon
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnDragStop", onDragStop)
    button:SetScript("OnMouseDown", onMouseDown)
    button:SetScript("OnMouseUp", onMouseUp)

    self.objects[dataObject.name] = button

    if not optDatabase.minimapPos then
      optDatabase.minimapPos = 225 -- default position of 225 degrees
    end
    updatePosition(button, optDatabase.minimapPos)
    if optDatabase.hide then
      button:Hide()
    else
      button:Show()
    end
    lib.callbacks:Fire("LibDBIcon_IconCreated", button, dataObject)

    return button
  end,

  Show = function(self, name)
    if not self:IsRegistered(name) then return end
    self.objects[name]:Show()
    if self.objects[name].db then self.objects[name].db.hide = false end
    lib.callbacks:Fire("LibDBIcon_IconShown", self.objects[name], self.objects[name].dataObject)
  end,

  Hide = function(self, name)
    if not self:IsRegistered(name) then return end
    self.objects[name]:Hide()
    if self.objects[name].db then self.objects[name].db.hide = true end
    lib.callbacks:Fire("LibDBIcon_IconHidden", self.objects[name], self.objects[name].dataObject)
  end,

  IsShown = function(self, name)
    if not self:IsRegistered(name) then return end
    return self.objects[name]:IsShown()
  end,

  GetMinimapButton = function(self, name)
    return self.objects[name]
  end,
}

lib.ShowDB = lib.Show
lib.HideDB = lib.Hide
lib.IsShownDB = lib.IsShown
lib.GetMinimapButtonDB = lib.GetMinimapButton

lib:SetScript("OnUpdate", function(self, elapsed)
  if not ldb or not ldb.RegisterCallback then return end

  ldb.RegisterCallback(self, "LibDataBroker_AttributeChanged__icon", "IconCallback")
  ldb.RegisterCallback(self, "LibDataBroker_AttributeChanged__iconCoords", "IconCallback")

  for name, obj in next, ldb:GetDataObjectList() do
    if not lib.objects[name] and obj.icon then
      lib:Register(obj)
    end
  end

  self:SetScript("OnUpdate", nil)
  self.callbackRegistered = true
end)

for name, method in pairs(methods) do
  lib[name] = method
end
