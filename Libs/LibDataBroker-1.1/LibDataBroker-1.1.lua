--[[
LibDataBroker-1.1

Provides a dataobject framework for Lua addons to share data and
build mini-map icons and launcher buttons.

$Revision: 1 $
$Date: 2011-04-11 11:31:40 +0000 (Mon, 11 Apr 2011) $
@project-version@
]]

local MAJOR, MINOR = "LibDataBroker-1.1", 4
assert(LibStub, MAJOR .. " requires LibStub")
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {},
    lib.proxystorage or {}
local attributestorage, namestorage, callbacks = lib.attributestorage, lib.namestorage, lib.callbacks

if not lib.domt then
  lib.domt = {
    __metatable = "access denied",
    __index = function(self, key) return attributestorage[self] and attributestorage[self][key] end,
  }
end

if not lib.domp then
  lib.domp = {
    __metatable = "access denied",
    __index = function(self, key) return lib.proxystorage[self] and lib.proxystorage[self][key] end,
    __newindex = function(self, key, value)
      if not lib.proxystorage[self] then lib.proxystorage[self] = {} end
      lib.proxystorage[self][key] = value
      return lib.proxystorage[self][key]
    end,
  }
end

function lib:NewDataObject(name, dataobj)
  if self.proxystorage[dataobj] then return end

  if dataobj then
    assert(type(dataobj) == "table", "Invalid dataobj, must be nil or a table")
    self.attributestorage[dataobj] = {}
    for i, v in pairs(dataobj) do
      self.attributestorage[dataobj][i] = v
      dataobj[i] = nil
    end
  end

  dataobj = setmetatable(dataobj or {}, self.domt)
  self.proxystorage[dataobj] = {}
  self.namestorage[dataobj] = name

  if dataobj.OnTooltipShow then
    dataobj.tooltip = defaultTooltipFields
  end

  if dataobj.datatext then
    dataobj.text = ""
  end

  self.callbacks:Fire("LibDataBroker_DataObjectCreated", dataobj, name)
  return dataobj
end

if oldminor < 3 then
  lib.proxystorage = {}
  lib:UpdateCallbacks()
end
