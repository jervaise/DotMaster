do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "zhCN")
    local L = languageTable

------------------------------------------------------------
L["ADD_NPC_FAIL"] = "添加NPC ID失败"
L["ENTER_NPCID"] = "输入NPC ID"
L["INSTALL_FAIL"] = "Plater Performance Units插件无法安装。"
L["PERF_UNIT_WHATISIT"] = "当单位被加入效能模组的白名单，姓名板将不显示施法条，也不运行脚本和模组。"

end