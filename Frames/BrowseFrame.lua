---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

BFC.UNKNOWN_CRAFTING_FEE = AF.WrapTextInColor("??", "darkgray")
if AF.isAsian then
    BFC.FormatFee = AF.FormatNumber_Asian
else
    BFC.FormatFee = AF.FormatNumber
end

local browseFrame, list, showStaleCB, showBlacklistedCB
local selectedProfession, keywords = 0, ""
local LoadList
local updateRequired

local ALL = _G.ALL

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateBrowseFrame()
    browseFrame = AF.CreateFrame(BFCMainFrame, "BFCBrowseFrame", nil, 400)
    AF.SetPoint(browseFrame, "TOPLEFT", BFCMainFrame, 10, -40)
    AF.SetPoint(browseFrame, "BOTTOMRIGHT", BFCMainFrame, -10, 10)
    browseFrame:SetScript("OnShow", function()
        if updateRequired then
            LoadList()
        end
    end)

    -- profession
    local professionDropdown = AF.CreateDropdown(browseFrame, 120, 9, nil, true, nil, "LEFT")
    AF.SetPoint(professionDropdown, "TOPLEFT")
    for _, p in pairs(BFC.GetProfessionList()) do
        professionDropdown:AddItem({
            ["text"] = p[2],
            ["value"] = p[1],
            ["icon"] = AF.GetProfessionIcon(p[1]),
            ["onClick"] = function(value)
                selectedProfession = value
                LoadList()
            end
        })
    end

    professionDropdown:AddItem({
        ["text"] = ALL,
        ["value"] = 0,
        ["onClick"] = function()
            selectedProfession = 0
            LoadList()
        end
    }, 1)

    professionDropdown:SetSelectedValue(0)

    -- search
    local searchBox = AF.CreateEditBox(browseFrame, _G.SEARCH, nil, 20)
    AF.SetPoint(searchBox, "TOPLEFT", professionDropdown, "TOPRIGHT", 10, 0)
    AF.SetPoint(searchBox, "RIGHT", browseFrame)
    searchBox:SetOnTextChanged(function(text)
        keywords = strlower(strtrim(text))
        LoadList()
    end)

    -- list
    list = AF.CreateScrollList(browseFrame, "BFCBrowseFrameList", 5, 5, 22, 20, 1)
    AF.SetPoint(list, "TOPLEFT", browseFrame, 0, -30)
    AF.SetPoint(list, "TOPRIGHT", browseFrame, 0, -30)

    -- show stale
    showStaleCB = AF.CreateCheckButton(browseFrame, L["Show Stale"], function(checked)
        BFC_DB.showStale = checked
        LoadList()
    end)
    AF.SetPoint(showStaleCB, "TOPLEFT", list, "BOTTOMLEFT", 0, -10)

    -- show blacklisted
    showBlacklistedCB = AF.CreateCheckButton(browseFrame, L["Show Blacklisted"], function(checked)
        BFC_DB.showBlacklisted = checked
        LoadList()
    end)
    AF.SetPoint(showBlacklistedCB, "TOPLEFT", showStaleCB, 165, 0)
end

---------------------------------------------------------------------
-- pane
---------------------------------------------------------------------
local panes = {}

local function Pane_Load(pane, id, t)
    pane.id = id
    pane.t = t
    pane.isSelf = BFC.battleTag == id

    -- name
    pane.nameButton:SetText(AF.ToShortName(t.name))
    -- pane.nameButton:SetTextColor((BFC_DB.blacklist[pane.id] or BFC.IsStale(t.lastUpdate)) and "darkgray" or t.class)
    pane.nameButton:SetTextColor(BFC_DB.blacklist[pane.id] and "darkgray" or t.class)

    -- fee
    pane.craftingFeeText:SetText(t.craftingFee and BFC.FormatFee(t.craftingFee) or BFC.UNKNOWN_CRAFTING_FEE)

    -- professions
    if BFC_DB.blacklist[pane.id] then
        pane.professionText:SetText(AF.WrapTextInColor(L["Blacklisted"], "red"))
    elseif BFC.IsStale(t.lastUpdate) then
        pane.professionText:SetText(AF.WrapTextInColor(L["Stale"], "darkgray"))
    else
        pane.professionText:SetText(BFC.GetProfessionString(t.professions, 12))
    end

    -- favorite
    pane.favoriteButton:SetTexture(BFC_DB.favorite[pane.id] and AF.GetIcon("Star2") or AF.GetIcon("Star1"))
    pane.favoriteButton:SetTextureColor(BFC_DB.favorite[pane.id] and "gold" or "darkgray")

    -- block
    pane.blockButton:SetTextureColor(BFC_DB.blacklist[pane.id] and "red" or "darkgray")

    --@debug@
    if id == BFC.battleTag then
        pane.nameButton:SetText("Abcdefghjkmn")
        pane.professionText:SetText(BFC.GetProfessionString(BFC.validSkillLine, 12))
    end
    --@end-debug@
end

local function Pane_OnEnter(pane)
    pane:SetBackdropColor(AF.GetColorRGB("sheet_row_highlight"))
    if not BFC_DB.blacklist[pane.id] then
        AF.ShowTooltips(pane, "BOTTOMLEFT", 0, -1, {
            AF.WrapTextInColor(pane.t.name, pane.t.class),
            L["Crafting Fee: %s"]:format(AF.WrapTextInColor(pane.t.craftingFee or BFC.UNKNOWN_CRAFTING_FEE, "gold")) .. AF.EscapeAtlas("Coin-Gold"),
            L["Last updated: %s"]:format(AF.WrapTextInColor(AF.FormatRelativeTime(pane.t.lastUpdate), "yellow")),
            pane.t.tagline
        })
    end
end

local function Pane_OnLeave(pane)
    pane:SetBackdropColor(AF.GetColorRGB("sheet_bg2"))
    AF.HideTooltips()
end

local function CreatePane()
    local pane = AF.CreateBorderedFrame(list.slotFrame, nil, nil, nil, "sheet_bg2")
    pane:SetOnEnter(Pane_OnEnter)
    pane:SetOnLeave(Pane_OnLeave)

    -- name
    local nameButton = AF.CreateButton(pane, "name", "gray_hover", 110, 20, nil, nil, "", nil, "AF_FONT_CHAT")
    pane.nameButton = nameButton
    AF.SetPoint(nameButton, "TOPLEFT", pane)
    nameButton:SetTextJustifyH("LEFT")
    nameButton:SetTextPadding(5)
    nameButton:HookOnEnter(function() Pane_OnEnter(pane) end)
    nameButton:HookOnLeave(function() Pane_OnLeave(pane) end)
    nameButton:SetOnClick(function()
        BFC.ShowDetailFrame(pane)
    end)

    -- crafting fee
    local craftingFeeText = AF.CreateFontString(pane, nil, "gold")
    pane.craftingFeeText = craftingFeeText
    AF.SetPoint(craftingFeeText, "RIGHT", pane, "LEFT", 160, 0)
    craftingFeeText:SetJustifyH("RIGHT")

    -- sep
    local sep = AF.CreateSeparator(pane, 20, 1, "black", true, true)
    AF.SetPoint(sep, "TOPLEFT", 165)

    -- professions
    local professionText = AF.CreateFontString(pane)
    pane.professionText = professionText
    AF.SetPoint(professionText, "LEFT", 170, 0)
    professionText:SetJustifyH("LEFT")
    professionText:SetJustifyV("MIDDLE")

    -- block
    local blockButton = AF.CreateButton(pane, nil, "gray_hover", 20, 20, nil, nil, "")
    pane.blockButton = blockButton
    AF.SetPoint(blockButton, "TOPRIGHT", pane)
    blockButton:SetTexture(AF.GetIcon("Unavailable"), {15, 15})
    blockButton:SetTextureColor("darkgray")
    blockButton:SetOnClick(function()
        if IsAltKeyDown() then
            BFC_DB.blacklist[pane.id] = true
            BFC_DB.list[pane.id] = nil
        else
            if BFC_DB.blacklist[pane.id] then
                BFC_DB.blacklist[pane.id] = nil
            else
                BFC_DB.blacklist[pane.id] = true
            end
        end
        LoadList()
    end)
    blockButton:HookOnEnter(function() Pane_OnEnter(pane) end)
    blockButton:HookOnLeave(function() Pane_OnLeave(pane) end)

    -- favorite
    local favoriteButton = AF.CreateButton(pane, nil, "gray_hover", 20, 20, nil, nil, "")
    pane.favoriteButton = favoriteButton
    AF.SetPoint(favoriteButton, "TOPRIGHT", blockButton, "TOPLEFT", 1, 0)
    favoriteButton:SetTexture(AF.GetIcon("Star1"), {15, 15})
    favoriteButton:SetTextureColor("darkgray")
    favoriteButton:SetOnClick(function()
        if BFC_DB.favorite[pane.id] then
            BFC_DB.favorite[pane.id] = nil
        else
            BFC_DB.favorite[pane.id] = true
        end
        LoadList()
    end)
    favoriteButton:HookOnEnter(function() Pane_OnEnter(pane) end)
    favoriteButton:HookOnLeave(function() Pane_OnLeave(pane) end)

    -- load
    pane.Load = Pane_Load

    return pane
end

---------------------------------------------------------------------
-- update
---------------------------------------------------------------------
local function Comparator(a, b)
    if a.isSelf ~= b.isSelf then
        return a.isSelf
    end
    if BFC_DB.favorite[a.id] ~= BFC_DB.favorite[b.id] then
        return BFC_DB.favorite[a.id]
    end
    if BFC_DB.blacklist[a.id] ~= BFC_DB.blacklist[b.id] then
        return not BFC_DB.blacklist[a.id]
    end
    if a.t.lastUpdate ~= b.t.lastUpdate then
        return a.t.lastUpdate > b.t.lastUpdate
    end
    return a.id < b.id
end

local function ShouldShow(id, t)
    local names = {}
    for _, prof in pairs(t.professions) do
        for _, char in pairs(prof) do
            names[char[1]] = true
        end
    end
    names = AF.TableToString(names, " ", true)

    if BFC.battleTag == id then
        -- always show self
        return true
    end

    return (BFC_DB.showStale or not BFC.IsStale(t.lastUpdate) or BFC_DB.favorite[id] or BFC_DB.blacklist[id]) -- stale
        and (BFC_DB.showBlacklisted or not BFC_DB.blacklist[id]) -- blacklisted
        and not AF.IsEmpty(t.professions) -- has professions
        and (selectedProfession == 0 or type(t.professions[selectedProfession]) == "boolean") -- match selected profession
        and (keywords == "" or (strfind(strlower(t.name), keywords) or strfind(strlower(t.tagline), keywords) or strfind(names, keywords))) -- match keyword
end

LoadList = function()
    updateRequired = false

    local widgets = {}
    local i = 1
    for id, t in pairs(BFC_DB.list) do
        if ShouldShow(id, t) then
            if not panes[i] then
                panes[i] = CreatePane()
            end

            tinsert(widgets, panes[i])
            panes[i]:Load(id, t)

            i = i + 1
        end
    end

    sort(widgets, Comparator)
    list:SetWidgets(widgets)
end

function BFC.UpdateList()
    -- no update while browsing
    if browseFrame and not browseFrame:IsShown() then
        LoadList()
    else
        updateRequired = true
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFC_ShowFrame", function(which)
    if which == "Browse" then
        if not browseFrame then
            CreateBrowseFrame()
            LoadList()
        end
        -- AF.SetHeight(BFCMainFrame, 650)
        showStaleCB:SetChecked(BFC_DB.showStale)
        showBlacklistedCB:SetChecked(BFC_DB.showBlacklisted)
        browseFrame:Show()
    else
        if browseFrame then
            browseFrame:Hide()
        end
    end
end)