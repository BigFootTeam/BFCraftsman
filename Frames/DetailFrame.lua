---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local detailFrame
local updateRequired

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateDetailFrame()
    detailFrame = AF.CreateBorderedFrame(BFCBrowseFrame, "BFCDetailFrame", nil, nil, nil, "accent")
    AF.SetFrameLevel(detailFrame, 50)
    detailFrame:Hide()
    AF.SetInside(detailFrame, BFCBrowseFrameList, 5)

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
    local closeButton = AF.CreateCloseButton(detailFrame, nil, 20, 20)
    AF.SetPoint(closeButton, "TOPRIGHT")
    closeButton:SetBorderColor("accent")

    -- crafting fee
    local craftingFeeText = AF.CreateFontString(detailFrame)
    AF.SetPoint(craftingFeeText, "TOPLEFT", detailFrame, 10, -10)

    -- id
    local idEditBox = AF.CreateEditBox(detailFrame, nil, nil, 20)
    AF.SetPoint(idEditBox, "TOPLEFT", 10, -55)
    AF.SetPoint(idEditBox, "RIGHT", -60)
    idEditBox:SetNotUserChangable(true)
    idEditBox:SetTextColor(AF.GetColorRGB("gray"))

    local idText = AF.CreateFontString(detailFrame, "ID" .. AF.WrapTextInColor(" (" .. L["for reporting inappropriate user content"] .. ")", "darkgray"))
    AF.SetPoint(idText, "BOTTOMLEFT", idEditBox, "TOPLEFT", 2, 2)

    -- name
    -- local nameEditBox = AF.CreateEditBox(detailFrame, nil, nil, 20)
    -- AF.SetPoint(nameEditBox, "TOPLEFT", 10, -45)
    -- AF.SetPoint(nameEditBox, "RIGHT", -60)
    -- nameEditBox:SetNotUserChangable(true)

    -- local nameText = AF.CreateFontString(detailFrame, L["Name"])
    -- AF.SetPoint(nameText, "BOTTOMLEFT", nameEditBox, "TOPLEFT", 2, 2)

    -- favorite
    local favoriteButton = AF.CreateButton(detailFrame, nil, {"static", "sheet_cell_highlight"}, 20, 20)
    AF.SetPoint(favoriteButton, "TOPLEFT", idEditBox, "TOPRIGHT", 5, 0)
    favoriteButton:SetTexture(AF.GetIcon("Star1"), {16, 16})
    favoriteButton:SetOnClick(function()
        if BFC_DB.favorite[detailFrame.pane.id] then
            BFC_DB.favorite[detailFrame.pane.id] = nil
            favoriteButton:SetTexture(AF.GetIcon("Star1"))
            favoriteButton:SetTextureColor("darkgray")
        else
            BFC_DB.favorite[detailFrame.pane.id] = true
            favoriteButton:SetTexture(AF.GetIcon("Star2"))
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

    -- character list
    local charList = AF.CreateScrollList(detailFrame, nil, 2, 2, 7, 20, 1)
    AF.SetPoint(charList, "TOPLEFT", idEditBox, "BOTTOMLEFT", 0, -35)
    AF.SetPoint(charList, "RIGHT", -10)

    local characterListText = AF.CreateFontString(charList, L["Characters"])
    AF.SetPoint(characterListText, "BOTTOMLEFT", charList, "TOPLEFT", 2, 2)

    local charBtnPool = AF.CreateObjectPool(function()
        local eb = AF.CreateEditBox(charList.slotFrame, nil, nil, 20)
        eb:SetNotUserChangable(true)

        -- profession icons
        eb.prof = AF.CreateFontString(eb)
        AF.SetPoint(eb.prof, "RIGHT", -5, 0)

        return eb
    end)

    -- current character highlight
    local currentCharHighlight = AF.CreateGradientTexture(charList, "HORIZONTAL", "none", AF.GetColorTable("green", 0.3))

    -- tagline
    local taglineEditBox = AF.CreateScrollEditBox(detailFrame, nil, nil, nil, 120)
    AF.SetPoint(taglineEditBox, "TOPLEFT", charList, "BOTTOMLEFT", 0, -35)
    AF.SetPoint(taglineEditBox, "RIGHT", -10, 0)
    taglineEditBox:SetNotUserChangable(true)

    local taglineText = AF.CreateFontString(detailFrame, L["Tagline"])
    AF.SetPoint(taglineText, "BOTTOMLEFT", taglineEditBox, "TOPLEFT", 2, 2)

    -- last update
    local lastUpdateText = AF.CreateFontString(detailFrame)
    AF.SetPoint(lastUpdateText, "TOPLEFT", taglineEditBox, "BOTTOMLEFT", 0, -18)
    lastUpdateText:SetColor("darkgray")

    -- chat button
    local chatButton = AF.CreateButton(detailFrame, L["Send Whisper"], "accent", 120, 20)
    AF.SetPoint(chatButton, "TOPRIGHT", taglineEditBox, "BOTTOMRIGHT", 0, -15)
    chatButton:SetOnClick(function()
        BFC.SendWhisper(detailFrame.pane.t.name)
    end)

    -- load
    function detailFrame:Load(pane)
        detailFrame.pane = pane
        craftingFeeText:SetText(L["Crafting Fee: %s"]:format(pane.t.craftingFee or BFC.UNKNOWN_CRAFTING_FEE) .. AF.EscapeAtlas("Coin-Gold"))
        idEditBox:SetText(pane.id)
        idEditBox:SetCursorPosition(0)

        -- texplore(pane.t)
        charBtnPool:ReleaseAll()

        -- prepare characters
        local chars = {}
        for pid, pt in pairs(pane.t.professions) do
            for _, ct in pairs(pt) do
                local name = ct[1] .. ":" .. ct[2]
                if not chars[name] then
                    chars[name] = {}
                end
                chars[name][pid] = true
            end
        end

        -- prepare widgets
        local currentCharFound = false
        for k, profs in pairs(chars) do
            local w = charBtnPool:Acquire()
            local name, class = strsplit(":", k)
            w:SetText(AF.WrapTextInColor(name, class))
            w.prof:SetText(BFC.GetProfessionString(profs, 12))

            if name == pane.t.name then
                w.sortKey1 = 0 -- current character first
                currentCharFound = true
                currentCharHighlight:SetParent(w)
                AF.ClearPoints(currentCharHighlight)
                AF.SetPoint(currentCharHighlight, "TOPLEFT", w, "TOP", 0, -1)
                AF.SetPoint(currentCharHighlight, "BOTTOMRIGHT", w, -1, 1)
            else
                w.sortKey1 = 1
            end
            w.sortKey2 = w.prof:GetText() -- then sort by profession
        end
        currentCharHighlight:SetShown(currentCharFound)

        -- sort and set
        local widgets = charBtnPool:GetAllActives()
        AF.Sort(widgets, "sortKey1", "ascending", "sortKey2", "ascending")
        charList:SetWidgets(widgets)

        -- nameEditBox:SetText(pane.t.name)
        -- nameEditBox:SetTextColor(AF.GetClassColor(pane.t.class))
        taglineEditBox:SetText(pane.t.tagline)
        lastUpdateText:SetText(AF.FormatTime(pane.t.lastUpdate))

        favoriteButton:SetTexture(BFC_DB.favorite[pane.id] and AF.GetIcon("Star2") or AF.GetIcon("Star1"))
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

    -- AF.ClearPoints(detailFrame)
    -- if pane._slotIndex <= 11 then
    --     AF.SetPoint(detailFrame, "TOPLEFT", BFCBrowseFrameList.slotFrame)
    --     AF.SetPoint(detailFrame, "TOPRIGHT", BFCBrowseFrameList.slotFrame)
    -- else
    --     AF.SetPoint(detailFrame, "BOTTOMLEFT", BFCBrowseFrameList.slotFrame)
    --     AF.SetPoint(detailFrame, "BOTTOMRIGHT", BFCBrowseFrameList.slotFrame)
    -- end

    detailFrame:Load(pane)
    detailFrame:Show()
end