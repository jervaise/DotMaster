do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "ptBR")
    local L = languageTable

------------------------------------------------------------
L["ADD_NPC_FAIL"] = "Não foi possível adicionar o ID do PNJ"
L["ENTER_NPCID"] = "Insira o ID do PNJ"
L["INSTALL_FAIL"] = "Erro ao instalar o plugin Plater Performance Units"
L["PERF_UNIT_WHATISIT"] = "Quando uma unidade é considerada uma unidade de desempenho, sua placa de identificação não mostrará barras, rodará scripts e mods."

end