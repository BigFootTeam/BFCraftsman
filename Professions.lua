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

local professionOrder = {164, 165, 171, 197, 202, 333, 773, 755}
function BFC.GetProfessionString(profs, size)
    local text = ""
    for _, id in pairs(professionOrder) do
        if profs[id] ~= nil then
            local icon = AF.GetProfessionIcon(id)
            text = text .. AF.EscapeIcon(icon, size)
        end
    end
    return text
end

BFC.learnedProfessions = {}

local function Update(id, name, class)
    if BFC.validSkillLine[id] then
        if not BFC.learnedProfessions[id] then
            BFC.learnedProfessions[id] = {}
        end
        tinsert(BFC.learnedProfessions[id], {name, class})
    end
end

function BFC.UpdateLearnedProfessions()
    wipe(BFC.learnedProfessions)
    for _, t in pairs(BFC_DB.publish.characters) do
        Update(t.prof1.id, t.name, t.class)
        Update(t.prof2.id, t.name, t.class)
    end
end