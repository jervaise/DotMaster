do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "enUS")
    local L = languageTable

L["INSTALL_FAIL"] = "Plater Performance Units plugin failed to install."
L["ADD_NPC_FAIL"] = "Failed to add the npc id."
L["PERF_UNIT_WHATISIT"] = "When a unit is considered a performance unit, the nameplate won't show cast bars, track threat or auras."
L["ENTER_NPCID"] = "Enter the NPC ID"

L["BYPASS_SETTINGS"] = "Bypass Settings"
L["ADD"] = "Add"

L["THREAT"] = "Threat"
L["AURA"] = "Aura"
L["CASTBAR"] = "Cast Bar"

------------------------------------------------------------
L["ADD_NPC_FAIL"] = "Failed to add the npc id."
L["ENTER_NPCID"] = "Enter the NPC ID"
L["INSTALL_FAIL"] = "Plater Performance Units plugin failed to install."
L["PERF_UNIT_WHATISIT"] = "When a unit is considered a performance unit, the nameplate won't show cast bars, run scripts and mods."

end