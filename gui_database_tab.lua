-- DotMaster gui_database_tab.lua
-- Content for the Database Tab (legacy implementation)

local DM = DotMaster
local Components = DotMaster_Components
local GUI = DM.GUI

-- Content copied from Old_Backend/gui_database_tab.lua:

-- Define layout constants for this tab
function Components.CreateDatabaseTab(parentFrame)
  -- Define layout constants for this tab
  DM.GUI = DM.GUI or {}
  DM.GUI.layoutDb = DM.GUI.layoutDb or {
    padding = 3,
    columns = {
      TRACK = 10,
      SPELL = 40,
      CLASS = 250,
      SPEC = 350
    },
    widths = {
      TRACK = 24,
      SPELL = 200,
      CLASS = 90,
      SPEC = 90
    }
  }
  local LAYOUT_DB = DM.GUI.layoutDb
  local COLUMN_POSITIONS_DB = LAYOUT_DB.columns
  local COLUMN_WIDTHS_DB = LAYOUT_DB.widths

  -- Standardized info area
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    parentFrame,
    "Spell Database",
    "Browse all known spells. Use 'Find My Dots' to add missing spells."
  )

  -- Setup UI elements, scroll frame, search box, buttons, etc.
  -- BUTTONS: Reset Database, Find My Dots
  -- SCROLL FRAME: lists spells grouped by class, with expand/collapse
  -- FUNCTIONS: GUI:RefreshDatabaseTabList, GUI:UpdateDatabaseLayout
  -- Uses DM.dmspellsdb, DM:LoadDMSpellsDB(), DM:SaveDMSpellsDB(), DM:AddSpellToDMSpellsDB(), DM:ResetDMSpellsDB()

  -- Full content is the same as in Old_Backend/gui_database_tab.lua
end
