---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local validSkillLine = {
    [171] = true, -- Alchemy
    [164] = true, -- Blacksmithing
    [333] = true, -- Enchanting
    [202] = true, -- Engineering
    -- [182] = true, -- Herbalism
    [755] = true, -- Jewelcrafting
    [165] = true, -- Leatherworking
    -- [186] = true, -- Mining
    -- [393] = true, -- Skinning
    [197] = true, -- Tailoring
}

local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo
local GetTradeSkillDisplayName = C_TradeSkillUI.GetTradeSkillDisplayName
local GetBaseProfessionInfo = C_TradeSkillUI.GetBaseProfessionInfo
local GetChildProfessionInfo = C_TradeSkillUI.GetChildProfessionInfo
local GetProfessionInfoByRecipeID = C_TradeSkillUI.GetProfessionInfoByRecipeID
local GetAllRecipeIDs = C_TradeSkillUI.GetAllRecipeIDs
local GetRecipeInfo = C_TradeSkillUI.GetRecipeInfo
local OpenTradeSkill = C_TradeSkillUI.OpenTradeSkill
local CloseTradeSkill = C_TradeSkillUI.CloseTradeSkill
local tinsert = tinsert

local publishFrame, taglineEditBox, charList
local LoadCharacters, CreateAddButton

---------------------------------------------------------------------
-- recipes
---------------------------------------------------------------------
local function GetRecipes()
    local professionInfo = GetBaseProfessionInfo()
    if not professionInfo then return end

    local childInfo = GetChildProfessionInfo()

    local ret = {}
    local recipeIDs = GetAllRecipeIDs()
    if recipeIDs then
        for _, recipeID in ipairs(recipeIDs) do
            local professionID = GetProfessionInfoByRecipeID(recipeID).professionID
            if childInfo.professionID == professionID then
                local recipeInfo = GetRecipeInfo(recipeID)
                if recipeInfo and recipeInfo.learned then
                    tinsert(ret, recipeID)
                end
            end
        end
    end
    CloseTradeSkill()
    return ret
end

---------------------------------------------------------------------
-- cache
---------------------------------------------------------------------
local function CacheProfessions(prof)
    if prof.id ~= 0 then
        OpenTradeSkill(prof.id)
        C_Timer.After(1, function()
            prof.recipes = GetRecipes()
            prof.lastScaned = time()
            AF.HideMask(charList)
        end)
    end
end

---------------------------------------------------------------------
-- create frame
---------------------------------------------------------------------
local function CreatePublishFrame()
    publishFrame = AF.CreateFrame(BFCMainFrame, "BFCPublishFrame")
    -- AF.ApplyDefaultBackdropWithColors(publishFrame, {0, 1, 0, 0.1}, "none")
    AF.SetPoint(publishFrame, "TOPLEFT", BFCMainFrame, 10, -45)
    AF.SetPoint(publishFrame, "BOTTOMRIGHT", BFCMainFrame, -10, 10)
    publishFrame:Hide()

    -- tagline
    local taglinePane = AF.CreateTitledPane(publishFrame, L["Tagline"], nil, 90)
    AF.SetPoint(taglinePane, "TOPLEFT", publishFrame)
    AF.SetPoint(taglinePane, "TOPRIGHT", publishFrame)

    taglineEditBox = AF.CreateScrollEditBox(taglinePane)
    taglineEditBox:SetMaxBytes(256)
    AF.SetPoint(taglineEditBox, "TOPLEFT", taglinePane, 0, -25)
    AF.SetPoint(taglineEditBox, "BOTTOMRIGHT", taglinePane)
    taglineEditBox:SetConfirmButton(function(text)
        BFC_DB.tagline = text
    end)

    -- characters and professions
    local charProfPane = AF.CreateTitledPane(publishFrame, L["Characters and Professions"])
    AF.SetPoint(charProfPane, "TOPLEFT", taglinePane, "BOTTOMLEFT", 0, -20)
    AF.SetPoint(charProfPane, "BOTTOMRIGHT")

    charList = AF.CreateScrollList(charProfPane, nil, nil, 10, 10, 6, 40, 10)
    AF.SetPoint(charList, "TOPLEFT", charProfPane, 0, -25)
    AF.SetPoint(charList, "TOPRIGHT", charProfPane, 0, -25)
end

---------------------------------------------------------------------
-- create character pane
---------------------------------------------------------------------
local panes = {}

local function Pane_ShowCacheInfo(button)
    local lastScaned = button.t.lastScaned
    if lastScaned == 0 then
        lastScaned = L["never"]
    else
        lastScaned = AF.FormatRelativeTime(lastScaned)
    end
    lastScaned = AF.WrapTextInColor(lastScaned, "yellow")

    AF.ShowTooltips(button, "BOTTOMLEFT", 0, -1, {
        L["Scan Recipes"],
        L["Click to scan recipes"],
        L["Scan only available for current character"],
        L["Learned recipes: %s"]:format(AF.WrapTextInColor(#button.t.recipes, "yellow")),
        L["Last scanned: %s"]:format(lastScaned),
    })
end

local function Pane_HideCacheInfo(button)
    AF.HideTooltips()
end

local function Pane_Scan(button)
    if not button.parent.isCurrentCharacter then return end

    AF.ShowMask(charList, L["Scanning..."])
    CacheProfessions(button.t)
end

local function Pane_UpdateButton(button, t)
    button.t = t
    if t.id == 0 then
        button:SetText(TRADE_SKILLS_UNLEARNED_TAB)
        button:HideTexture()
        button:SetEnabled(false)
    else
        button:SetText(GetTradeSkillDisplayName(t.id))
        button:SetTexture(AF.GetProfessionIcon(t.id), {14, 14}, {"LEFT", 5, 0})
        button:SetEnabled(validSkillLine[t.id])
    end
end

local function Pane_Load(pane, i, t, isCurrentCharacter)
    pane.index = i
    pane.t = t
    pane.isCurrentCharacter = isCurrentCharacter

    pane.nameText:SetText(t.name)
    pane.nameText:SetTextColor(AF.GetClassColor(t.class))

    Pane_UpdateButton(pane.prof1Button, t.prof1)
    Pane_UpdateButton(pane.prof2Button, t.prof2)
end

local function CreateCharacterPane()
    local pane = AF.CreateBorderedFrame(charList.slotFrame)

    -- name
    local nameText = AF.CreateFontString(pane, "name", "white")
    pane.nameText = nameText
    AF.SetPoint(nameText, "LEFT", pane, "TOPLEFT", 5, -10)
    AF.SetPoint(nameText, "RIGHT", pane, "TOPRIGHT", -5, -10)
    nameText:SetJustifyH("LEFT")

    -- prof1
    local prof1Button = AF.CreateButton(pane, "prof1", "accent_hover", nil, 20)
    prof1Button.parent = pane
    pane.prof1Button = prof1Button
    AF.SetPoint(prof1Button, "BOTTOMLEFT")
    AF.SetPoint(prof1Button, "BOTTOMRIGHT", pane, "BOTTOM")
    prof1Button:SetJustifyH("LEFT")
    prof1Button:SetTextPadding(5)
    prof1Button:HookOnEnter(Pane_ShowCacheInfo)
    prof1Button:HookOnLeave(Pane_HideCacheInfo)
    prof1Button:SetOnClick(Pane_Scan)

    -- prof2
    local prof2Button = AF.CreateButton(pane, "prof2", "accent_hover", nil, 20)
    prof2Button.parent = pane
    pane.prof2Button = prof2Button
    AF.SetPoint(prof2Button, "BOTTOMLEFT", prof1Button, "BOTTOMRIGHT", -1, 0)
    AF.SetPoint(prof2Button, "BOTTOMRIGHT")
    prof2Button:SetJustifyH("LEFT")
    prof2Button:SetTextPadding(5)
    prof2Button:HookOnEnter(Pane_ShowCacheInfo)
    prof2Button:HookOnLeave(Pane_HideCacheInfo)
    prof2Button:SetOnClick(Pane_Scan)

    -- delete
    local delButton = AF.CreateButton(pane, nil, "red_hover", 21, 21)
    delButton:SetTexture(AF.GetIcon("Close"), {16, 16}, {"CENTER", 0, 0})
    AF.SetPoint(delButton, "TOPRIGHT", pane)
    AF.SetTooltips(delButton, "TOPRIGHT", 0, 1, L["Delete Character"], L["Alt-Click to delete"])
    delButton:SetOnClick(function()
        if IsAltKeyDown() then
            tremove(BFC_DB.characters, pane.index)
            LoadCharacters()
        end
    end)

    -- load
    pane.Load = Pane_Load

    return pane
end

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
local addButton
CreateAddButton = function()
    addButton = AF.CreateButton(charList.slotFrame, L["Add Current Character"], "accent_hover")

    addButton:SetOnClick(function()
        local prof1, prof2 = GetProfessions()
        if prof1 then
            prof1 = select(7, GetProfessionInfo(prof1))
        end
        if prof2 then
            prof2 = select(7, GetProfessionInfo(prof2))
        end

        local t = {
            name = AF.player.fullName,
            class = AF.player.class,
            prof1 = {
                id = prof1 or 0,
                lastScaned = 0,
                recipes = {},
            },
            prof2 = {
                id = prof2 or 0,
                lastScaned = 0,
                recipes = {},
            },
        }
        tinsert(BFC_DB.characters, t)
        LoadCharacters()
    end)
end


LoadCharacters = function()
    local widgets = {}
    local currentCharacterFound = false

    for i, t in pairs(BFC_DB.characters) do
        if not panes[i] then
            panes[i] = CreateCharacterPane()
        end

        if t.name == AF.player.fullName then
            currentCharacterFound = true
            -- current player always first
            tinsert(widgets, 1, panes[i])
            panes[i]:Load(i, t, true)
        else
            tinsert(widgets, panes[i])
            panes[i]:Load(i, t, false)
        end
    end

    -- current player not found
    if not currentCharacterFound then
        if not addButton then CreateAddButton() end
        tinsert(widgets, 1, addButton)
    elseif addButton then
        addButton:Hide()
    end

    -- set
    charList:SetWidgets(widgets)

    -- hide unused
    -- for i = #widgets + 1, #panes do
    --     print("hide", i)
    --     panes[i]:Hide()
    -- end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFC_ShowFrame", function(which)
    if which == "Publish" then
        if not publishFrame then
            CreatePublishFrame()
            taglineEditBox:SetText(BFC_DB.tagline)
            LoadCharacters()
        end
        publishFrame:Show()
    else
        if publishFrame then
            publishFrame:Hide()
        end
    end
end)