---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework

BFC.validSkillLine = {
    [164] = true, -- Blacksmithing
    [165] = true, -- Leatherworking
    [171] = true, -- Alchemy
    [197] = true, -- Tailoring
    [202] = true, -- Engineering
    [333] = true, -- Enchanting
    [755] = true, -- Jewelcrafting
    -- [182] = true, -- Herbalism
    -- [186] = true, -- Mining
    -- [393] = true, -- Skinning
}

BFC.learnedProfessions = {}

function BFC.UpdateLearnedProfessions()
    wipe(BFC.learnedProfessions)
    for _, t in pairs(BFC_DB.publish.characters) do
        if BFC.validSkillLine[t.prof1.id] then
            BFC.learnedProfessions[t.prof1.id] = true
        end
        if BFC.validSkillLine[t.prof2.id] then
            BFC.learnedProfessions[t.prof2.id] = true
        end
    end
end

function BFC.GetLearnedProfessionString()
    local ret = {}
    for id in pairs(BFC.learnedProfessions) do
        tinsert(ret, id)
    end
    return AF.TableToString(ret, ",")
end