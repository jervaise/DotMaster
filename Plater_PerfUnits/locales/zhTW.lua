do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "zhTW")
    local L = languageTable

------------------------------------------------------------
L["ADD_NPC_FAIL"] = "NPC ID 添加失敗。"
L["ENTER_NPCID"] = "輸入 NPC ID"
L["INSTALL_FAIL"] = "Plater Performance Units 安裝失敗"
L["PERF_UNIT_WHATISIT"] = "當單位被加入效能模組的白名單，該單位名條將不顯示施法條，也不運行腳本和模組。"

end