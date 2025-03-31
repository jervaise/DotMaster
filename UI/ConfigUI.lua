--[[
    DotMaster - Configuration UI Module
    Handles settings UI for the addon
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Initialize configuration
function DotMaster:InitializeConfig()
  -- Create options table for AceConfig
  local options = {
    name = "DotMaster",
    type = "group",
    args = {
      general = {
        name = "General",
        type = "group",
        order = 1,
        args = {
          enabled = {
            name = "Enable addon",
            desc = "Enable or disable the addon",
            type = "toggle",
            width = "full",
            get = function() return self.db.profile.enabled end,
            set = function(info, val)
              self.db.profile.enabled = val
              if val then
                self:OnEnable()
              else
                self:OnDisable()
              end
            end,
            order = 1
          },
          minimapIconHeader = {
            name = "Minimap Icon",
            type = "header",
            order = 10
          },
          showMinimapIcon = {
            name = "Show minimap icon",
            desc = "Show or hide the minimap icon",
            type = "toggle",
            get = function() return self.db.profile.minimapIcon.show end,
            set = function(info, val)
              self.db.profile.minimapIcon.show = val
              if val then
                self:CreateMinimapButton()
              elseif self.minimapIcon then
                self.minimapIcon:Hide()
              end
            end,
            order = 11
          },
          resetHeader = {
            name = "Reset Options",
            type = "header",
            order = 90
          },
          reset = {
            name = "Reset all settings",
            desc = "Reset all addon settings to defaults",
            type = "execute",
            func = function() self:ResetAllSettings() end,
            confirm = true,
            confirmText = "Are you sure you want to reset all settings to defaults?",
            order = 91
          }
        }
      },
      nameplate = {
        name = "Nameplate",
        type = "group",
        order = 2,
        args = {
          enabled = {
            name = "Enable nameplate indicators",
            desc = "Enable or disable DoT indicators on nameplates",
            type = "toggle",
            width = "full",
            get = function() return self.db.profile.nameplate.enabled end,
            set = function(info, val)
              self.db.profile.nameplate.enabled = val
              if val then
                self:InitializeNameplateTracker()
              else
                self:DisableNameplateTracker()
              end
            end,
            order = 1
          },
          displayHeader = {
            name = "Display Options",
            type = "header",
            order = 10
          },
          size = {
            name = "Size",
            desc = "Adjust the size of DoT indicators",
            type = "range",
            min = 0.5,
            max = 2.0,
            step = 0.1,
            get = function() return self.db.profile.nameplate.size end,
            set = function(info, val)
              self.db.profile.nameplate.size = val
              self:ApplyNameplateSettings()
            end,
            order = 11
          },
          position = {
            name = "Position",
            desc = "Set the position of DoT indicators relative to nameplates",
            type = "select",
            values = {
              TOP = "Top",
              BOTTOM = "Bottom",
              LEFT = "Left",
              RIGHT = "Right",
              TOPLEFT = "Top Left",
              TOPRIGHT = "Top Right",
              BOTTOMLEFT = "Bottom Left",
              BOTTOMRIGHT = "Bottom Right",
              CENTER = "Center"
            },
            get = function() return self.db.profile.nameplate.position end,
            set = function(info, val)
              self.db.profile.nameplate.position = val
              self:ApplyNameplateSettings()
            end,
            order = 12
          },
          showIcon = {
            name = "Show spell icon",
            desc = "Show spell icon on DoT indicators",
            type = "toggle",
            get = function() return self.db.profile.nameplate.showIcon end,
            set = function(info, val)
              self.db.profile.nameplate.showIcon = val
              self:ApplyNameplateSettings()
            end,
            order = 13
          },
          showTimer = {
            name = "Show timer",
            desc = "Show remaining time on DoT indicators",
            type = "toggle",
            get = function() return self.db.profile.nameplate.showTimer end,
            set = function(info, val)
              self.db.profile.nameplate.showTimer = val
              self:ApplyNameplateSettings()
            end,
            order = 14
          }
        }
      },
      filter = {
        name = "Filtering",
        type = "group",
        order = 3,
        args = {
          trackOnlyMyDoTs = {
            name = "Only track my DoTs",
            desc = "Only track DoTs cast by you",
            type = "toggle",
            width = "full",
            get = function() return self.db.profile.filter.trackOnlyMyDoTs end,
            set = function(info, val)
              self.db.profile.filter.trackOnlyMyDoTs = val
              self:ApplyFilterSettings()
            end,
            order = 1
          },
          trackFriendlyTargets = {
            name = "Track friendly targets",
            desc = "Track DoTs on friendly targets",
            type = "toggle",
            width = "full",
            get = function() return self.db.profile.filter.trackFriendlyTargets end,
            set = function(info, val)
              self.db.profile.filter.trackFriendlyTargets = val
              self:ApplyFilterSettings()
            end,
            order = 2
          }
        }
      },
      tracking = {
        name = "DoT Tracking",
        type = "group",
        order = 4,
        args = {
          description = {
            name = "Enable or disable tracking for specific DoT spells",
            type = "description",
            order = 1
          },
          spellList = {
            name = "Spells",
            type = "group",
            inline = true,
            order = 2,
            args = {}
          },
          resetHeader = {
            name = "Reset Options",
            type = "header",
            order = 90
          },
          reset = {
            name = "Reset spell settings",
            desc = "Reset all spell settings to defaults",
            type = "execute",
            func = function()
              self:ResetSpellSettings()
              self:RefreshConfig()
            end,
            confirm = true,
            confirmText = "Are you sure you want to reset all spell settings to defaults?",
            order = 91
          }
        }
      },
      findMyDots = {
        name = "Find My Dots",
        type = "group",
        order = 5,
        args = {
          enabled = {
            name = "Enable Find My Dots",
            desc = "Enable or disable the Find My Dots window",
            type = "toggle",
            width = "full",
            get = function() return self.db.profile.findMyDots.enabled end,
            set = function(info, val)
              self.db.profile.findMyDots.enabled = val
              if val then
                self:InitializeFindMyDots()
              else
                self:DisableFindMyDots()
              end
            end,
            order = 1
          },
          displayHeader = {
            name = "Display Options",
            type = "header",
            order = 10
          },
          scale = {
            name = "Scale",
            desc = "Adjust the scale of the Find My Dots window",
            type = "range",
            min = 0.5,
            max = 2.0,
            step = 0.1,
            get = function() return self.db.profile.findMyDots.scale end,
            set = function(info, val)
              self.db.profile.findMyDots.scale = val
              self:ApplyFindMyDotsSettings()
            end,
            order = 11
          },
          opacity = {
            name = "Opacity",
            desc = "Adjust the opacity of the Find My Dots window",
            type = "range",
            min = 0.1,
            max = 1.0,
            step = 0.1,
            get = function() return self.db.profile.findMyDots.opacity end,
            set = function(info, val)
              self.db.profile.findMyDots.opacity = val
              self:ApplyFindMyDotsSettings()
            end,
            order = 12
          },
          showCount = {
            name = "Show stack count",
            desc = "Show stack count for DoTs",
            type = "toggle",
            get = function() return self.db.profile.findMyDots.showCount end,
            set = function(info, val)
              self.db.profile.findMyDots.showCount = val
              self:ApplyFindMyDotsSettings()
            end,
            order = 13
          },
          showName = {
            name = "Show spell name",
            desc = "Show spell name in the list",
            type = "toggle",
            get = function() return self.db.profile.findMyDots.showName end,
            set = function(info, val)
              self.db.profile.findMyDots.showName = val
              self:ApplyFindMyDotsSettings()
            end,
            order = 14
          },
          showIcon = {
            name = "Show spell icon",
            desc = "Show spell icon in the list",
            type = "toggle",
            get = function() return self.db.profile.findMyDots.showIcon end,
            set = function(info, val)
              self.db.profile.findMyDots.showIcon = val
              self:ApplyFindMyDotsSettings()
            end,
            order = 15
          },
          showTimer = {
            name = "Show timer",
            desc = "Show remaining time in the list",
            type = "toggle",
            get = function() return self.db.profile.findMyDots.showTimer end,
            set = function(info, val)
              self.db.profile.findMyDots.showTimer = val
              self:ApplyFindMyDotsSettings()
            end,
            order = 16
          },
          positionHeader = {
            name = "Position",
            type = "header",
            order = 20
          },
          lockPosition = {
            name = "Lock position",
            desc = "Lock the position of the Find My Dots window",
            type = "toggle",
            get = function() return self.db.profile.findMyDots.lockPosition end,
            set = function(info, val)
              self.db.profile.findMyDots.lockPosition = val
            end,
            order = 21
          },
          resetPosition = {
            name = "Reset position",
            desc = "Reset the position of the Find My Dots window",
            type = "execute",
            func = function()
              self.db.profile.findMyDots.position = nil
              if self.findMyDotsFrame then
                self.findMyDotsFrame:ClearAllPoints()
                self.findMyDotsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
              end
            end,
            order = 22
          }
        }
      },
      database = {
        name = "Database",
        type = "group",
        order = 6,
        args = {
          description = {
            name = "Browse the DoT spell database",
            type = "description",
            order = 1
          },
          search = {
            name = "Search",
            desc = "Search for a spell by name",
            type = "input",
            get = function() return self.dbSearchText or "" end,
            set = function(info, val)
              self.dbSearchText = val
              self:RefreshDatabaseList()
            end,
            order = 2
          },
          classFilter = {
            name = "Class Filter",
            desc = "Filter spells by class",
            type = "select",
            values = {
              ALL = "All Classes",
              DEATHKNIGHT = "Death Knight",
              DEMONHUNTER = "Demon Hunter",
              DRUID = "Druid",
              EVOKER = "Evoker",
              HUNTER = "Hunter",
              MAGE = "Mage",
              MONK = "Monk",
              PALADIN = "Paladin",
              PRIEST = "Priest",
              ROGUE = "Rogue",
              SHAMAN = "Shaman",
              WARLOCK = "Warlock",
              WARRIOR = "Warrior"
            },
            get = function() return self.dbClassFilter or "ALL" end,
            set = function(info, val)
              self.dbClassFilter = val
              self:RefreshDatabaseList()
            end,
            order = 3
          },
          spellList = {
            name = "Database Spells",
            type = "group",
            inline = true,
            order = 4,
            args = {}
          }
        }
      },
      debug = {
        name = "Debug",
        type = "group",
        order = 7,
        args = {
          enabled = {
            name = "Enable Debug Mode",
            desc = "Enable or disable debug mode",
            type = "toggle",
            width = "full",
            get = function() return self.db.profile.debug.enabled end,
            set = function(info, val)
              self.db.profile.debug.enabled = val
            end,
            order = 1
          },
          level = {
            name = "Debug Level",
            desc = "Set the debug level",
            type = "select",
            values = {
              ERROR = "Error",
              WARNING = "Warning",
              INFO = "Info",
              DEBUG = "Debug",
              TRACE = "Trace"
            },
            get = function() return self.db.profile.debug.level end,
            set = function(info, val)
              self:SetDebugLevel(val)
            end,
            order = 2
          },
          printToChat = {
            name = "Print to chat",
            desc = "Print debug messages to chat",
            type = "toggle",
            get = function() return self.db.profile.debug.printToChat end,
            set = function(info, val)
              self.db.profile.debug.printToChat = val
            end,
            order = 3
          },
          categoriesHeader = {
            name = "Debug Categories",
            type = "header",
            order = 10
          }
        }
      },
      profiles = {
        name = "Profiles",
        type = "group",
        order = 8,
        args = {}
      }
    }
  }

  -- Add debug categories
  local index = 11
  for category, _ in pairs(self.DEBUG_CATEGORIES) do
    options.args.debug.args[category:lower()] = {
      name = category,
      desc = "Enable or disable " .. category .. " debugging",
      type = "toggle",
      get = function() return self.db.profile.debug.categories[category] end,
      set = function(info, val)
        self:ToggleDebugCategory(category, val)
      end,
      order = index
    }
    index = index + 1
  end

  -- Store the options table for reference in other parts of the addon
  self.fullOptionsTable = options

  -- Register options table
  LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)

  -- Add to Blizzard Interface Options
  self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, "DotMaster")

  -- Add profile panel to config
  options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  -- Refresh database and tracking lists
  self:RefreshDatabaseList()
  self:RefreshTrackingList()

  self:Debug("GUI", "Configuration UI initialized")
end

-- Open config UI
function DotMaster:OpenConfigUI()
  -- If the configuration hasn't been initialized yet, do it now
  if not self.optionsFrame then
    self:InitializeConfig()
  end

  -- Open to the config panel
  InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
  InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) -- Call twice to workaround a Blizzard bug

  self:Debug("GUI", "Configuration UI opened")
end

-- Open specific config tab by name
function DotMaster:OpenConfigTab(tabName)
  -- If the configuration hasn't been initialized yet, do it now
  if not self.optionsFrame then
    self:InitializeConfig()
  end

  -- Open config to specific tab
  InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
  LibStub("AceConfigDialog-3.0"):SelectGroup(ADDON_NAME, tabName)

  self:Debug("GUI", "Configuration tab " .. tabName .. " opened")
end

-- Open tracking UI
function DotMaster:OpenTrackingUI()
  self:OpenConfigTab("tracking")
end

-- Open database UI
function DotMaster:OpenDatabaseUI()
  self:OpenConfigTab("database")
end

-- Refresh configuration
function DotMaster:RefreshConfig()
  self:RefreshDatabaseList()
  self:RefreshTrackingList()

  -- Inform AceConfig about the refresh
  LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)

  self:Debug("GUI", "Configuration refreshed")
end

-- Refresh database list
function DotMaster:RefreshDatabaseList()
  -- Get options table
  local options = LibStub("AceConfigRegistry-3.0"):GetOptionsTable(ADDON_NAME)
  if not options then return end

  -- Clear existing spell list
  options.args.database.args.spellList.args = {}

  -- Get filtered spells
  local spells = self:GetFilteredSpells(self.dbSearchText, self.dbClassFilter)

  -- Add spells to list
  for i, spell in ipairs(spells) do
    local spellInfo = self:GetSpellInfo(spell.spellID)
    local spellName = spellInfo.name or "Unknown Spell"

    options.args.database.args.spellList.args["spell" .. spell.spellID] = {
      name = spellName,
      desc = "Spell ID: " .. spell.spellID .. ", Class: " .. spell.class,
      type = "toggle",
      get = function() return spell.enabled end,
      set = function(info, val)
        self:SetSpellEnabled(spell.spellID, val)
        self:RefreshTrackingList()
      end,
      order = i
    }
  end

  -- Notify config registry of the change
  LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)

  self:Debug("GUI", "Database list refreshed with " .. #spells .. " spells")
end

-- Refresh tracking list
function DotMaster:RefreshTrackingList()
  -- Get options table
  local options = LibStub("AceConfigRegistry-3.0"):GetOptionsTable(ADDON_NAME)
  if not options then return end

  -- Clear existing spell list
  options.args.tracking.args.spellList.args = {}

  -- Get enabled spells
  local spells = self:GetEnabledSpells()

  -- Add spells to list
  for i, spell in ipairs(spells) do
    local spellInfo = self:GetSpellInfo(spell.spellID)
    local spellName = spellInfo.name or "Unknown Spell"

    -- Add main toggle
    options.args.tracking.args.spellList.args["spell" .. spell.spellID] = {
      name = spellName,
      desc = "Spell ID: " .. spell.spellID .. ", Class: " .. spell.class,
      type = "toggle",
      get = function() return spell.enabled end,
      set = function(info, val)
        self:SetSpellEnabled(spell.spellID, val)
      end,
      order = i * 10
    }

    -- Add color picker
    options.args.tracking.args.spellList.args["color" .. spell.spellID] = {
      name = "Color",
      desc = "Set the color for " .. spellName,
      type = "color",
      hasAlpha = false,
      get = function()
        return spell.color.r, spell.color.g, spell.color.b
      end,
      set = function(info, r, g, b)
        spell.color.r = r
        spell.color.g = g
        spell.color.b = b
        self:SaveSpellSettings()
      end,
      order = i * 10 + 1
    }
  end

  -- Notify config registry of the change
  LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)

  self:Debug("GUI", "Tracking list refreshed with " .. #spells .. " spells")
end

-- Get filtered spells
function DotMaster:GetFilteredSpells(searchText, classFilter)
  -- Start with all spells
  local spells = self.spellDB

  -- Apply class filter
  if classFilter and classFilter ~= "ALL" then
    local filtered = {}
    for _, spell in ipairs(spells) do
      if spell.class == classFilter then
        table.insert(filtered, spell)
      end
    end
    spells = filtered
  end

  -- Apply search filter
  if searchText and searchText ~= "" then
    local filtered = {}
    searchText = string.lower(searchText)

    for _, spell in ipairs(spells) do
      local spellInfo = self:GetSpellInfo(spell.spellID)
      local spellName = spellInfo.name or ""

      if string.find(string.lower(spellName), searchText) then
        table.insert(filtered, spell)
      end
    end

    spells = filtered
  end

  return spells
end

-- Create minimap button
function DotMaster:CreateMinimapButton()
  if not self.db.profile.minimapIcon.show then
    if self.minimapIcon then
      self.minimapIcon:Hide()
    end
    return
  end

  -- If LibDBIcon is available, use it to create the minimap button
  if not LibStub or not LibStub("LibDataBroker-1.1", true) or not LibStub("LibDBIcon-1.0", true) then
    self:Warning("GUI", "Required libraries not found for minimap button")
    return
  end

  -- Create data broker object
  local LDB = LibStub("LibDataBroker-1.1")
  local minimapLDB = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = "DotMaster",
    icon = "Interface\\Icons\\spell_shadow_unstableaffliction_3",
    OnClick = function(_, button)
      if button == "LeftButton" then
        self:OpenConfigUI()
      elseif button == "RightButton" then
        -- Toggle addon
        if self.db.profile.enabled then
          self.db.profile.enabled = false
          self:OnDisable()
        else
          self.db.profile.enabled = true
          self:OnEnable()
        end
      end
    end,
    OnTooltipShow = function(tooltip)
      tooltip:AddLine("DotMaster")
      tooltip:AddLine("Left-click to open configuration", 1, 1, 1)
      tooltip:AddLine("Right-click to toggle addon", 1, 1, 1)
    end
  })

  -- Initialize icon
  local minimapIcon = LibStub("LibDBIcon-1.0")
  minimapIcon:Register(ADDON_NAME, minimapLDB, self.db.profile.minimapIcon)

  -- Store reference
  self.minimapIcon = minimapIcon

  self:Debug("GUI", "Minimap button created")
end
