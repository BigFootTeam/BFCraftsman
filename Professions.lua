---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework

local GetTradeSkillDisplayName = C_TradeSkillUI.GetTradeSkillDisplayName

BFC.validSkillLine = {
    [164] = true, -- Blacksmithing
    [165] = true, -- Leatherworking
    [171] = true, -- Alchemy
    [197] = true, -- Tailoring
    [202] = true, -- Engineering
    [333] = true, -- Enchanting
    [773] = true, -- Inscription
    [755] = true, -- Jewelcrafting
    -- [182] = true, -- Herbalism
    -- [186] = true, -- Mining
    -- [393] = true, -- Skinning
}

function BFC.GetProfessionList()
    local ret = {}
    for id in pairs(BFC.validSkillLine) do
        local name = GetTradeSkillDisplayName(id)
        tinsert(ret, {id, name})
    end
    sort(ret, function(a, b)
        return a[2] < b[2]
    end)
    return ret
end

BFC.learnedProfessions = {}

function BFC.UpdateLearnedProfessions()
    wipe(BFC.learnedProfessions)
    for _, t in pairs(BFC_DB.publish.characters) do
        if BFC.validSkillLine[t.prof1.id] then
            BFC.learnedProfessions[t.prof1.id] = t.prof1.allRecipesLearned
        end
        if BFC.validSkillLine[t.prof2.id] then
            BFC.learnedProfessions[t.prof2.id] = t.prof1.allRecipesLearned
        end
    end
end

function BFC.GetLearnedProfessionString()
    local ret = {}
    for id, allRecipesLearned in pairs(BFC.learnedProfessions) do
        tinsert(ret, allRecipesLearned and id .. "!" or id)
    end
    return AF.TableToString(ret, ",")
end