--[[
Widget for AceGUI-3.0 that leverages LibSharedMedia-3.0
]]

local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- Basic implementation of font selector
do
  local Type = "LSM30_Font"
  local Version = 1

  local function Constructor()
    local self = AceGUI:Create("Dropdown")
    self.type = Type

    local function GetFontList()
      local list = {}
      for k in pairs(LSM:HashTable("font")) do
        list[k] = k
      end
      return list
    end

    self.SetList = function(self)
      self.dropdown:SetList(GetFontList())
    end

    return self
  end

  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Basic implementation of statusbar selector
do
  local Type = "LSM30_Statusbar"
  local Version = 1

  local function Constructor()
    local self = AceGUI:Create("Dropdown")
    self.type = Type

    local function GetStatusbarList()
      local list = {}
      for k in pairs(LSM:HashTable("statusbar")) do
        list[k] = k
      end
      return list
    end

    self.SetList = function(self)
      self.dropdown:SetList(GetStatusbarList())
    end

    return self
  end

  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Basic implementation of sound selector
do
  local Type = "LSM30_Sound"
  local Version = 1

  local function Constructor()
    local self = AceGUI:Create("Dropdown")
    self.type = Type

    local function GetSoundList()
      local list = {}
      for k in pairs(LSM:HashTable("sound")) do
        list[k] = k
      end
      return list
    end

    self.SetList = function(self)
      self.dropdown:SetList(GetSoundList())
    end

    return self
  end

  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Basic implementation of border selector
do
  local Type = "LSM30_Border"
  local Version = 1

  local function Constructor()
    local self = AceGUI:Create("Dropdown")
    self.type = Type

    local function GetBorderList()
      local list = {}
      for k in pairs(LSM:HashTable("border")) do
        list[k] = k
      end
      return list
    end

    self.SetList = function(self)
      self.dropdown:SetList(GetBorderList())
    end

    return self
  end

  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Basic implementation of background selector
do
  local Type = "LSM30_Background"
  local Version = 1

  local function Constructor()
    local self = AceGUI:Create("Dropdown")
    self.type = Type

    local function GetBackgroundList()
      local list = {}
      for k in pairs(LSM:HashTable("background")) do
        list[k] = k
      end
      return list
    end

    self.SetList = function(self)
      self.dropdown:SetList(GetBackgroundList())
    end

    return self
  end

  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
