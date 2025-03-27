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
    listFrame = AF.CreateHeaderedFrame(ProfessionsCustomerOrdersFrame, "BFCOrderFormListFrame", L["Craftsmen List"], 150)
    AF.SetPoint(listFrame, "TOPLEFT", ProfessionsCustomerOrdersFrame, "TOPRIGHT", 5, -20)
    listFrame:SetMovable(false)
    listFrame:SetTitleJustify("LEFT")
    AF.SetListHeight(listFrame, 20, 20, 1, 4)

    listFrame:SetOnHide(function()
        listFrame:Hide()
    end)

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
    b:SetTexture(AF.GetIcon("Star2"), {15, 15}, {"RIGHT", -2, 0}, nil, nil, "RIGHT")
    b:SetTextureColor("gold")
    b:SetOnClick(function()
        BFC.ShowOrderFormDetailFrame(b.id)
    end)
    return b
end
local pool = AF.CreateObjectPool(CreateButton)

---------------------------------------------------------------------
-- current order
---------------------------------------------------------------------
local GetProfessionInfoByRecipeID = C_TradeSkillUI.GetProfessionInfoByRecipeID

local currentRecipeID, currentProfessionID

function BFC.HandleOrderData(form)
    currentRecipeID = form.order.spellID
    local info = GetProfessionInfoByRecipeID(currentRecipeID)
    if info then
        currentProfessionID = info.parentProfessionID
    end
end

function BFC.GetOrderRecipeID()
    return currentRecipeID
end

function BFC.GetOrderProfessionID()
    return currentProfessionID
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

    if currentRecipeID and currentProfessionID then
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