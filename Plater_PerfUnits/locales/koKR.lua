do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "koKR")
    local L = languageTable

------------------------------------------------------------
--[[Translation missing --]]
L["ADD_NPC_FAIL"] = "Failed to add the npc id."
--[[Translation missing --]]
L["ENTER_NPCID"] = "Enter the NPC ID"
--[[Translation missing --]]
L["INSTALL_FAIL"] = "Plater Performance Units plugin failed to install."
--[[Translation missing --]]
L["PERF_UNIT_WHATISIT"] = "When a unit is considered a performance unit, the nameplate won't show cast bars, run scripts and mods."

end