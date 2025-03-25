---@class BFC
local BFC = select(2, ...)
local L = BFC.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local listFrame

---------------------------------------------------------------------
-- create frame
---------------------------------------------------------------------
local function CreateListFrame()
    listFrame = AF.CreateHeaderedFrame(AF.UIParent, "BFCOrderFormListFrame", L["Craftsmen List"], 150, 420)
    AF.SetPoint(listFrame, "TOPLEFT", ProfessionsCustomerOrdersFrame, "TOPRIGHT", 5, -20)
    listFrame:SetMovable(false)
    listFrame:SetTitleJustify("LEFT")

    local list = AF.CreateScrollList(listFrame, nil, nil, 2, 2, 20, 20, 1, "none", "none")
    listFrame.list = list
    AF.SetPoint(list, "TOPLEFT", listFrame)
    AF.SetPoint(list, "TOPRIGHT", listFrame)
end

---------------------------------------------------------------------
-- create button
---------------------------------------------------------------------
local function CreateButton()
    local b = AF.CreateButton(listFrame.list.slotFrame, "", "gray_hover", nil, nil, nil, nil, "")
    b:SetTextJustifyH("LEFT")
    b:SetTexture(AF.GetIcon("Star_Filled"), {15, 15}, {"RIGHT", -2, 0}, nil, nil, "RIGHT")
    b:SetTextureColor("gold")
    return b
end
local pool = AF.CreateObjectPool(CreateButton)

---------------------------------------------------------------------
-- prepare
---------------------------------------------------------------------
local GetProfessionInfoByRecipeID = C_TradeSkillUI.GetProfessionInfoByRecipeID

local currentProfessionID
function BFC.PrepareListData(form)
    local recipeID = form.order.spellID
    local info = GetProfessionInfoByRecipeID(recipeID)
    if info then
        currentProfessionID = info.parentProfessionID
    end
end

---------------------------------------------------------------------
-- sort
---------------------------------------------------------------------
local function Comparator(a, b)
    if a.isSelf ~= b.isSelf then
        return a.isSelf
    end
    if a.isFavorite ~= b.isFavorite then
        return a.isFavorite
    end
    if a.isStale ~= b.isStale then
        return not a.isStale
    end
    return a.id < b.id
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
function BFC.ShowListFrame()
    if not listFrame then
        CreateListFrame()
    end

    pool:ReleaseAll()

    if currentProfessionID then
        for id, t in pairs(BFC_DB.list) do
            if not BFC_DB.blacklist[id] and type(t.professions[currentProfessionID]) == "boolean" then
                local b = pool:Acquire()
                b.id = id
                b.isFavorite = BFC_DB.favorite[id]
                b.isSelf = id == BFC.battleTag
                b.isStale = BFC.IsStale(t.lastUpdate)

                b:SetText(AF.ToShortName(t.name))
                b:SetTextColor(b.isStale and "darkgray" or t.class)

                if b.isFavorite then
                    b:ShowTexture()
                else
                    b:HideTexture()
                end
            end
        end
    end

    local widgets = pool:GetAllActives()
    sort(widgets, Comparator)

    listFrame.list:SetWidgets(widgets)

    listFrame:Show()
end

---------------------------------------------------------------------
-- hide
---------------------------------------------------------------------
function BFC.HideListFrame()
    if listFrame then
        listFrame:Hide()
    end
end