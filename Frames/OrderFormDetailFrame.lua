---@class BFC
local BFC = select(2, ...)
local L = BFC.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local detailFrame
local checkTimer

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateDetailFrame()
    detailFrame = AF.CreateHeaderedFrame(BFCOrderFormListFrame, "BFCOrderFormListDetailFrame", L["Details"], 150, 80)
    AF.SetPoint(detailFrame, "TOPLEFT", BFCOrderFormListFrame, "TOPRIGHT", 5, 0)
    detailFrame:SetMovable(false)
    detailFrame:SetTitleJustify("LEFT")

    detailFrame:SetOnHide(function()
        detailFrame:Hide()
    end)

    -- name editbox
    local nameEditBox = AF.CreateEditBox(detailFrame, nil, nil, 20)
    AF.SetPoint(nameEditBox, "TOPLEFT", detailFrame, 5, -5)
    AF.SetPoint(nameEditBox, "TOPRIGHT", detailFrame, -5, -5)

    -- check button
    local checkButton = AF.CreateButton(detailFrame, L["Can Craft?"], "yellow", nil, 20)
    detailFrame.checkButton = checkButton
    AF.SetPoint(checkButton, "TOPLEFT", nameEditBox, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(checkButton, "TOPRIGHT", nameEditBox, "BOTTOMRIGHT", 0, -5)
    checkButton:SetOnClick(function()
        if type(detailFrame.canCraft) == "boolean" then
            return
        end

        detailFrame.canCraft = false
        checkButton:SetText(L["Checking..."])
        if checkTimer then checkTimer:Cancel() end

        checkTimer = C_Timer.NewTimer(5, function()
            checkButton:SetText(L["Timeout"])
            checkButton:SetColor("red")
        end)
        BFC.CheckCanCraft(detailFrame.id, detailFrame.recipeID)
    end)

    -- send whisper button
    local whisperButton = AF.CreateButton(detailFrame, L["Send Whisper"], {"static", "sheet_cell_highlight"}, nil, 20)
    detailFrame.whisperButton = whisperButton
    AF.SetPoint(whisperButton, "TOPLEFT", checkButton, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(whisperButton, "TOPRIGHT", checkButton, "BOTTOMRIGHT", 0, -5)
    whisperButton:SetOnClick(function()
        if BFC_DB.list[detailFrame.id] then
            BFC.SendWhisper(BFC_DB.list[detailFrame.id].name)
        end
    end)

    -- load
    function detailFrame:Load(id)
        if checkTimer then checkTimer:Cancel() end
        if not BFC_DB.list[id] then
            detailFrame:Hide()
            return
        end

        detailFrame.id = id
        detailFrame.recipeID = BFC.GetOrderRecipeID()
        detailFrame.canCraft = BFC_DB.list[id].learnedRecipes[detailFrame.recipeID]

        nameEditBox:SetText(BFC_DB.list[id].name)
        nameEditBox:SetTextColor(AF.GetClassColor(BFC_DB.list[id].class))
        nameEditBox:SetCursorPosition(0)

        if type(detailFrame.canCraft) == "boolean" then
            if detailFrame.canCraft then
                checkButton:SetText(L["Can Craft"])
                checkButton:SetColor("green")
                whisperButton:SetEnabled(true)
            else
                checkButton:SetText(L["Cannot Craft"])
                checkButton:SetColor("red")
                whisperButton:SetEnabled(false)
            end
        else
            checkButton:SetText(L["Can Craft?"])
            checkButton:SetColor("yellow")
            whisperButton:SetEnabled(false)
        end
    end
end

---------------------------------------------------------------------
-- comm
---------------------------------------------------------------------
function BFC.NotifyCanCraft(id, recipeID, canCraft)
    if not (detailFrame and detailFrame.id == id) then return end
    if checkTimer then checkTimer:Cancel() end

    detailFrame.canCraft = canCraft and true or false

    if canCraft then
        detailFrame.checkButton:SetText(L["Can Craft"])
        detailFrame.checkButton:SetColor("green")
        detailFrame.whisperButton:SetEnabled(true)
    else
        detailFrame.checkButton:SetText(L["Cannot Craft"])
        detailFrame.checkButton:SetColor("red")
        detailFrame.whisperButton:SetEnabled(false)
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
function BFC.ShowOrderFormDetailFrame(id)
    if not detailFrame then
        CreateDetailFrame()
    end
    detailFrame:Load(id)
    detailFrame:Show()
end