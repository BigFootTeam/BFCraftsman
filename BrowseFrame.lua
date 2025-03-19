---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local browseFrame, list
local LoadList
local updateRequired

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

    list = AF.CreateScrollList(browseFrame, nil, nil, 5, 5, 22, 20, 1)
    AF.SetPoint(list, "TOPLEFT", browseFrame, 0, -30)
    AF.SetPoint(list, "TOPRIGHT", browseFrame, 0, -30)
end

---------------------------------------------------------------------
-- create pane
---------------------------------------------------------------------
local panes = {}

local function Pane_Load(pane, id, t)
    pane.id = id
    pane.t = t
    pane.isSelf = BFC.battleTag == id

    local recentlyUpdated = time() - t.lastUpdate < 1800

    -- name
    pane.nameButton:SetText(AF.ToShortName(t.name))
    pane.nameButton:SetTextColor((BFC_DB.blacklist[pane.id] or not recentlyUpdated) and "darkgray" or t.class)

    -- professions
    local text = ""
    if not BFC_DB.blacklist[pane.id] and recentlyUpdated then
        for id in pairs(t.profession) do
            local icon = AF.GetProfessionIcon(id)
            text = text .. AF.EscapeIcon(icon, 12)
        end
    end
    pane.professionText:SetText(text)

    -- favorite
    pane.favoriteButton:SetTexture(BFC_DB.favorite[pane.id] and AF.GetIcon("Star_Filled") or AF.GetIcon("Star"))
    pane.favoriteButton:SetTextureColor(BFC_DB.favorite[pane.id] and "gold" or "darkgray")

    -- block
    pane.blockButton:SetTextureColor(BFC_DB.blacklist[pane.id] and "red" or "darkgray")
end

local function Pane_OnEnter(pane)
    if not BFC_DB.blacklist[pane.id] then
        AF.ShowTooltips(pane, "BOTTOMLEFT", 0, -1, {
            AF.WrapTextInColor(pane.t.name, pane.t.class),
            L["Last updated: %s"]:format(AF.WrapTextInColor(AF.FormatRelativeTime(pane.t.lastUpdate), "yellow")),
            pane.t.tagline
        })
    end
end

local function CreatePane()
    local pane = AF.CreateBorderedFrame(list.slotFrame)
    pane:SetOnEnter(Pane_OnEnter)
    pane:SetOnLeave(AF.HideTooltips)

    -- name
    local nameButton = AF.CreateButton(pane, "name", "gray_hover", 165, 20)
    pane.nameButton = nameButton
    AF.SetPoint(nameButton, "TOPLEFT", pane)
    nameButton:SetJustifyH("LEFT")
    nameButton:SetTextPadding(5)
    nameButton:HookOnEnter(function() Pane_OnEnter(pane) end)
    nameButton:HookOnLeave(AF.HideTooltips)

    -- professions
    local professionText = AF.CreateFontString(pane)
    pane.professionText = professionText
    AF.SetPoint(professionText, "LEFT", nameButton, "RIGHT", 5, 0)

    -- block
    local blockButton = AF.CreateButton(pane, nil, "gray_hover", 20, 20)
    pane.blockButton = blockButton
    AF.SetPoint(blockButton, "TOPRIGHT", pane)
    blockButton:SetTexture(AF.GetIcon("Unavailable"), {15, 15})
    blockButton:SetTextureColor("darkgray")
    blockButton:SetOnClick(function()
        if BFC_DB.blacklist[pane.id] then
            BFC_DB.blacklist[pane.id] = nil
        else
            BFC_DB.blacklist[pane.id] = true
        end
        LoadList()
    end)
    blockButton:HookOnEnter(function() Pane_OnEnter(pane) end)
    blockButton:HookOnLeave(AF.HideTooltips)

    -- favorite
    local favoriteButton = AF.CreateButton(pane, nil, "gray_hover", 20, 20)
    pane.favoriteButton = favoriteButton
    AF.SetPoint(favoriteButton, "TOPRIGHT", blockButton, "TOPLEFT", 1, 0)
    favoriteButton:SetTexture(AF.GetIcon("Star"), {15, 15})
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
    favoriteButton:HookOnLeave(AF.HideTooltips)

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

LoadList = function()
    updateRequired = false

    local widgets = {}
    local i = 1
    for id, t in pairs(BFC_DB.list) do
        if not AF.IsEmpty(t.profession) then
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
    if browseFrame and browseFrame:IsShown() then
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
        browseFrame:Show()
    else
        if browseFrame then
            browseFrame:Hide()
        end
    end
end)