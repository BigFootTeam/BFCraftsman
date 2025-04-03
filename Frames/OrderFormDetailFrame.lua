---@class BFC
local BFC = select(2, ...)
local L = BFC.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local detailFrame
local checkTimer

---------------------------------------------------------------------
-- CHAT_MSG_SYSTEM
---------------------------------------------------------------------
-- local ERR_CHAT_PLAYER_NOT_FOUND_S = ERR_CHAT_PLAYER_NOT_FOUND_S
-- local PLAYER_OFFLINE = PLAYER_OFFLINE

-- local function CHAT_MSG_SYSTEM(_, _, msg)
--     if not BFC_DB.list[detailFrame.id] then return end
--     local name = BFC_DB.list[detailFrame.id].name
--     local msg1 = ERR_CHAT_PLAYER_NOT_FOUND_S:format(name)
--     local msg2 = ERR_CHAT_PLAYER_NOT_FOUND_S:format(AF.ToShortName(name))
--     if msg == msg1 or msg == msg2 then
--         if checkTimer then checkTimer:Cancel() end
--         detailFrame.sendWhisperButton:SetText(PLAYER_OFFLINE)
--         detailFrame.sendWhisperButton:SetColor("red")
--     end
-- end

---------------------------------------------------------------------
-- crafter list
---------------------------------------------------------------------
local crafterPanePool = AF.CreateObjectPool(function()
    local f = AF.CreateFrame(detailFrame, nil, nil, 20)

    local b = AF.CreateButton(f, nil, "green", 20, 20)
    b:SetTexture(AF.GetIcon("ArrowLeft1"))
    b:SetPoint("TOPLEFT")
    b:SetClickSound("bell")
    b:SetOnClick(function()
        local t = BFC_DB.list[detailFrame.id]
        if t then
            ProfessionsCustomerOrdersFrame.Form.OrderRecipientTarget:SetText(f.name)
            ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.GoldBox:SetText(t.craftingFee or 0)
        end
    end)

    local eb = AF.CreateEditBox(f, nil, nil, 20)
    AF.SetPoint(eb, "TOPLEFT", b, "TOPRIGHT", -1, 0)
    AF.SetPoint(eb, "BOTTOMRIGHT")

    function f:Load(t)
        f.name = t[1]
        eb:SetText(AF.WrapTextInColor(t[1], t[2]))
        eb:SetCursorPosition(0)
    end

    return f
end, function(_, f)
    f:Hide()
end)

local function ShowCrafters(crafters)
    if not crafters then return end

    for _, t in pairs(crafters) do
        local f = crafterPanePool:Acquire()
        f:Load(t)
    end

    local widgets = crafterPanePool:GetAllActives()
    AF.AnimatedResize(detailFrame, nil, 85 + #widgets * 25, nil, nil, nil, function()
        detailFrame.separator:Show()
        for i, f in pairs(widgets) do
            AF.ClearPoints(f)
            AF.SetPoint(f, "RIGHT", -5, 0)
            if i == 1 then
                AF.SetPoint(f, "TOPLEFT", detailFrame.separator, "BOTTOMLEFT", 0, -5)
            else
                AF.SetPoint(f, "TOPLEFT", widgets[i - 1], "BOTTOMLEFT", 0, -5)
            end
            f:Show()
        end
    end)
end

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateDetailFrame()
    detailFrame = AF.CreateHeaderedFrame(BFCOrderFormListFrame, "BFCOrderFormListDetailFrame", L["Details"], 170, 80)
    AF.SetPoint(detailFrame, "TOPLEFT", BFCOrderFormListFrame, "TOPRIGHT", 5, 0)
    detailFrame:SetMovable(false)
    detailFrame:SetTitleJustify("LEFT")

    detailFrame:SetOnHide(function()
        detailFrame:Hide()
        AF.SetHeight(detailFrame, 80)
        -- detailFrame:UnregisterEvent("CHAT_MSG_SYSTEM")
    end)

    -- name editbox
    local nameEditBox = AF.CreateEditBox(detailFrame, nil, nil, 20)
    AF.SetPoint(nameEditBox, "TOPLEFT", detailFrame, 5, -5)
    AF.SetPoint(nameEditBox, "TOPRIGHT", detailFrame, -5, -5)
    nameEditBox:SetNotUserChangable(true)

    -- send whisper button
    local sendWhisperButton = AF.CreateButton(detailFrame, L["Send Whisper"], {"static", "sheet_cell_highlight"}, nil, 20)
    detailFrame.sendWhisperButton = sendWhisperButton
    AF.SetPoint(sendWhisperButton, "TOPLEFT", nameEditBox, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(sendWhisperButton, "TOPRIGHT", nameEditBox, "BOTTOMRIGHT", 0, -5)
    sendWhisperButton:SetOnClick(function()
        if BFC_DB.list[detailFrame.id] then
            BFC.SendWhisper(BFC_DB.list[detailFrame.id].name)
        end
    end)

    -- check button
    local checkButton = AF.CreateButton(detailFrame, L["Can Craft?"], "yellow", nil, 20)
    detailFrame.checkButton = checkButton
    AF.SetPoint(checkButton, "TOPLEFT", sendWhisperButton, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(checkButton, "TOPRIGHT", sendWhisperButton, "BOTTOMRIGHT", 0, -5)
    checkButton:SetOnClick(function()
        if not IsAltKeyDown() and type(detailFrame.canCraft) == "boolean" then
            return
        end

        detailFrame.canCraft = false
        checkButton:SetText(L["Checking..."])
        checkButton:SetColor("yellow")
        if checkTimer then checkTimer:Cancel() end

        checkTimer = C_Timer.NewTimer(5, function()
            checkButton:SetText(L["Timeout"])
            checkButton:SetColor("red")
        end)
        BFC.CheckCanCraft(detailFrame.id, detailFrame.recipeID)
    end)

    -- separator
    local separator = AF.CreateSeparator(detailFrame, nil, 1)
    detailFrame.separator = separator
    separator:Hide()
    AF.SetPoint(separator, "TOPLEFT", checkButton, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(separator, "TOPRIGHT", checkButton, "BOTTOMRIGHT", 0, -5)

    -- load
    function detailFrame:Load(id)
        if checkTimer then checkTimer:Cancel() end
        if not BFC_DB.list[id] then
            detailFrame:Hide()
            return
        end

        separator:Hide()
        crafterPanePool:ReleaseAll()
        AF.SetHeight(detailFrame, 80)

        detailFrame.id = id
        detailFrame.recipeID = BFC.GetOrderRecipeID()
        detailFrame.crafters = BFC_DB.list[id].learnedRecipes[detailFrame.recipeID]
        detailFrame.canCraft = detailFrame.crafters and true

        if BFC_DB.list[id].professions[BFC.GetOrderProfessionID()] == true then
            -- NOTE: learned all recipes
            detailFrame.canCraft = true
        end

        nameEditBox:SetText(BFC_DB.list[id].name)
        nameEditBox:SetTextColor(AF.GetClassColor(BFC_DB.list[id].class))
        nameEditBox:SetCursorPosition(0)

        if detailFrame.canCraft == true then
            checkButton:SetText(L["Can Craft"])
            checkButton:SetColor("green")
            -- templateWhisperButton:SetEnabled(true)
        else
            checkButton:SetText(L["Can Craft?"])
            checkButton:SetColor("yellow")
            -- templateWhisperButton:SetEnabled(false)
        end

        -- detailFrame:RegisterEvent("CHAT_MSG_SYSTEM")
        C_Timer.After(0.25, function()
            ShowCrafters(detailFrame.crafters)
        end)
    end
end

---------------------------------------------------------------------
-- comm
---------------------------------------------------------------------
function BFC.NotifyCanCraft(id, recipeID, crafters)
    if not (detailFrame and detailFrame.id == id) then return end
    if checkTimer then checkTimer:Cancel() end

    detailFrame.canCraft = crafters and true or false

    if detailFrame.canCraft then
        detailFrame.checkButton:SetText(L["Can Craft"])
        detailFrame.checkButton:SetColor("green")
        -- detailFrame.templateWhisperButton:SetEnabled(true)

        detailFrame.separator:Hide()
        crafterPanePool:ReleaseAll()
        ShowCrafters(crafters)
    else
        detailFrame.checkButton:SetText(L["Cannot Craft"])
        detailFrame.checkButton:SetColor("red")
        -- detailFrame.templateWhisperButton:SetEnabled(false)
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