---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_DeactivateChat = ChatEdit_DeactivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend


local detailFrame
local updateRequired

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateDetailFrame()
    detailFrame = AF.CreateBorderedFrame(BFCBrowseFrame, "BFCDetailFrame", nil, 250, nil, "accent")
    AF.SetFrameLevel(detailFrame, 50)
    detailFrame:Hide()

    detailFrame:SetOnShow(function()
        AF.ShowMask(BFCBrowseFrame, nil, 0, 0, 0, 0)
    end)

    detailFrame:SetOnHide(function()
        detailFrame:Hide()
        AF.HideMask(BFCBrowseFrame)
        if updateRequired then
            updateRequired = false
            BFC.UpdateList()
        end
    end)

    -- close
    local closeButton = AF.CreateCloseButton(detailFrame)
    AF.SetPoint(closeButton, "TOPRIGHT")
    closeButton:SetBorderColor("accent")

    -- professions
    local professionText = AF.CreateFontString(detailFrame)
    AF.SetPoint(professionText, "TOPLEFT", 10, -10)

    -- name
    local nameEditBox = AF.CreateEditBox(detailFrame, nil, nil, 20)
    AF.SetPoint(nameEditBox, "TOPLEFT", 10, -45)
    AF.SetPoint(nameEditBox, "RIGHT", -60)
    nameEditBox:SetNotUserChangable(true)

    local nameText = AF.CreateFontString(detailFrame, L["Name"])
    AF.SetPoint(nameText, "BOTTOMLEFT", nameEditBox, "TOPLEFT", 2, 2)

    -- tagline
    local taglineEditBox = AF.CreateScrollEditBox(detailFrame, nil, nil, nil, 65)
    AF.SetPoint(taglineEditBox, "TOPLEFT", nameEditBox, "BOTTOMLEFT", 0, -30)
    AF.SetPoint(taglineEditBox, "RIGHT", -10)
    taglineEditBox:SetNotUserChangable(true)

    local taglineText = AF.CreateFontString(detailFrame, L["Tagline"])
    AF.SetPoint(taglineText, "BOTTOMLEFT", taglineEditBox, "TOPLEFT", 2, 2)

    -- id
    local idEditBox = AF.CreateEditBox(detailFrame, nil, nil, 20)
    AF.SetPoint(idEditBox, "TOPLEFT", taglineEditBox, "BOTTOMLEFT", 0, -30)
    AF.SetPoint(idEditBox, "RIGHT", -10)
    idEditBox:SetNotUserChangable(true)

    local idText = AF.CreateFontString(detailFrame, L["ID"] .. AF.WrapTextInColor(" (" .. L["for reporting inappropriate user content"] .. ")", "darkgray"))
    AF.SetPoint(idText, "BOTTOMLEFT", idEditBox, "TOPLEFT", 2, 2)

    -- favorite
    local favoriteButton = AF.CreateButton(detailFrame, nil, {"static", "sheet_cell_highlight"}, 20, 20)
    AF.SetPoint(favoriteButton, "TOPLEFT", nameEditBox, "TOPRIGHT", 5, 0)
    favoriteButton:SetTexture(AF.GetIcon("Star"), {16, 16})
    favoriteButton:SetOnClick(function()
        if BFC_DB.favorite[detailFrame.pane.id] then
            BFC_DB.favorite[detailFrame.pane.id] = nil
            favoriteButton:SetTexture(AF.GetIcon("Star"))
            favoriteButton:SetTextureColor("darkgray")
        else
            BFC_DB.favorite[detailFrame.pane.id] = true
            favoriteButton:SetTexture(AF.GetIcon("Star_Filled"))
            favoriteButton:SetTextureColor("gold")
        end
        updateRequired = true
    end)

    -- block
    local blockButton = AF.CreateButton(detailFrame, nil, {"static", "sheet_cell_highlight"}, 20, 20)
    AF.SetPoint(blockButton, "TOPLEFT", favoriteButton, "TOPRIGHT", 5, 0)
    blockButton:SetTexture(AF.GetIcon("Unavailable"), {16, 16})
    blockButton:SetOnClick(function()
        if IsAltKeyDown() then
            BFC_DB.blacklist[detailFrame.pane.id] = true
            BFC_DB.list[detailFrame.pane.id] = nil
            detailFrame:Hide()
        else
            if BFC_DB.blacklist[detailFrame.pane.id] then
                BFC_DB.blacklist[detailFrame.pane.id] = nil
                blockButton:SetTextureColor("darkgray")
            else
                BFC_DB.blacklist[detailFrame.pane.id] = true
                blockButton:SetTextureColor("red")
            end
        end
        updateRequired = true
    end)

    AF.SetTooltips(blockButton, "BOTTOMRIGHT", 0, -1,
        L["Blacklist"],
        L["The blacklist button in the list has the same functionality"],
        " ",
        {AF.L["Left Click"], L["add to blacklist"]},
        {"Alt + " .. AF.L["Left Click"], L["also remove from list"]}
    )

    -- last update
    local lastUpdateText = AF.CreateFontString(detailFrame)
    AF.SetPoint(lastUpdateText, "TOPLEFT", idEditBox, "BOTTOMLEFT", 0, -15)
    lastUpdateText:SetColor("darkgray")

    -- chat button
    local chatButton = AF.CreateButton(detailFrame, L["Send Whisper"], "accent", 120, 20)
    AF.SetPoint(chatButton, "TOPRIGHT", idEditBox, "BOTTOMRIGHT", 0, -12)
    chatButton:SetOnClick(function()
        local editBox = ChatEdit_ChooseBoxForSend()
        ChatEdit_DeactivateChat(editBox)
        ChatEdit_ActivateChat(editBox)
        editBox:SetText("/w " .. detailFrame.pane.t.name .. " ")
    end)

    -- load
    function detailFrame:Load(pane)
        detailFrame.pane = pane
        professionText:SetText(BFC.GetProfessionString(pane.t.professions, 14))
        nameEditBox:SetText(pane.t.name)
        nameEditBox:SetTextColor(AF.GetClassColor(pane.t.class))
        taglineEditBox:SetText(pane.t.tagline)
        idEditBox:SetText(pane.id)
        lastUpdateText:SetText(AF.FormatTime(pane.t.lastUpdate))

        favoriteButton:SetTexture(BFC_DB.favorite[pane.id] and AF.GetIcon("Star_Filled") or AF.GetIcon("Star"))
        favoriteButton:SetTextureColor(BFC_DB.favorite[pane.id] and "gold" or "darkgray")

        blockButton:SetTextureColor(BFC_DB.blacklist[pane.id] and "red" or "darkgray")
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
function BFC.ShowDetailFrame(pane)
    if not detailFrame then
        CreateDetailFrame()
    end

    AF.ClearPoints(detailFrame)
    if pane._slotIndex <= 11 then
        AF.SetPoint(detailFrame, "TOPLEFT", pane)
        AF.SetPoint(detailFrame, "TOPRIGHT", pane)
    else
        AF.SetPoint(detailFrame, "BOTTOMLEFT", pane)
        AF.SetPoint(detailFrame, "BOTTOMRIGHT", pane)
    end

    detailFrame:Load(pane)
    detailFrame:Show()
end