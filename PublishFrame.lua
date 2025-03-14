---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo

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

local GetProfessionInfo = GetProfessionInfo
local GetBaseProfessionInfo = C_TradeSkillUI.GetBaseProfessionInfo
local GetAllRecipeIDs = C_TradeSkillUI.GetAllRecipeIDs
local GetRecipeInfo = C_TradeSkillUI.GetRecipeInfo
local OpenTradeSkill = C_TradeSkillUI.OpenTradeSkill
local CloseTradeSkill = C_TradeSkillUI.CloseTradeSkill
local tinsert = tinsert

local publishFrame, charList, prof1, prof2

---------------------------------------------------------------------
-- recipes
---------------------------------------------------------------------
local function CacheRecipes()
    local professionInfo = GetBaseProfessionInfo()
    if not professionInfo then return end

    local childInfo = C_TradeSkillUI.GetChildProfessionInfo()

    local skillLineID = professionInfo.professionID
    BFC_DB.professions[skillLineID] = BFC_DB.professions[skillLineID] or {}

    local recipeIDs = GetAllRecipeIDs()
    if recipeIDs then
        wipe(BFC_DB.professions[skillLineID])
        for _, recipeID in ipairs(recipeIDs) do
            local professionID = C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID).professionID
            if childInfo.professionID == professionID then
                local recipeInfo = GetRecipeInfo(recipeID)
                if recipeInfo and not recipeInfo.learned then
                    tinsert(BFC_DB.professions[skillLineID], recipeID)
                end
            end
        end

    end
    CloseTradeSkill()
end

---------------------------------------------------------------------
-- cache
---------------------------------------------------------------------
local function CacheProfessions(prof)
    if prof then
        local name, _, _, _, _, _, skillLine = GetProfessionInfo(prof)
        OpenTradeSkill(skillLine)
        C_Timer.After(1, CacheRecipes)
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

    local taglineEditBox = AF.CreateScrollEditBox(taglinePane)
    taglineEditBox:SetMaxBytes(256)
    AF.SetPoint(taglineEditBox, "TOPLEFT", taglinePane, 0, -25)
    AF.SetPoint(taglineEditBox, "BOTTOMRIGHT", taglinePane)
    taglineEditBox:SetConfirmButton(function(text)
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

local function CreateCharacterPane()
    local pane = AF.CreateBorderedFrame(charList.slotFrame)

    -- name
    local nameText = AF.CreateFontString(pane, "name", "white")
    AF.SetPoint(nameText, "LEFT", pane, "TOPLEFT", 5, -10)
    AF.SetPoint(nameText, "RIGHT", pane, "TOPRIGHT", -5, -10)
    nameText:SetJustifyH("LEFT")

    -- prof1
    local prof1Button = AF.CreateButton(pane, "prof1", "accent_hover", nil, 20)
    AF.SetPoint(prof1Button, "BOTTOMLEFT")
    AF.SetPoint(prof1Button, "BOTTOMRIGHT", pane, "BOTTOM")
    prof1Button:SetJustifyH("LEFT")
    prof1Button:SetTextPadding(5)

    -- prof2
    local prof2Button = AF.CreateButton(pane, "prof2", "accent_hover", nil, 20)
    AF.SetPoint(prof2Button, "BOTTOMLEFT", prof1Button, "BOTTOMRIGHT", -1, 0)
    AF.SetPoint(prof2Button, "BOTTOMRIGHT")
    prof2Button:SetJustifyH("LEFT")
    prof2Button:SetTextPadding(5)

    -- load
    function pane:Load(t)
        nameText:SetText(t.name)
        prof1Button:SetText(t.prof1 ~= 0 and GetProfessionInfo(t.prof1) or TRADE_SKILLS_UNLEARNED_TAB)
        prof2Button:SetText(t.prof2 ~= 0 and GetProfessionInfo(t.prof2) or TRADE_SKILLS_UNLEARNED_TAB)
    end

    return pane
end

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
local LoadCharacters, CreateAddButton

local addButton
CreateAddButton = function()
    addButton = AF.CreateButton(charList.slotFrame, L["Add Current Character"], "accent_hover")

    addButton:SetOnClick(function()
        local prof1, prof2 = GetProfessions()
        local t = {
            name = AF.player.fullName,
            prof1 = prof1 or 0,
            prof2 = prof2 or 0,
            prof1Recipes = {},
            prof2Recipes = {},
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
        else
            tinsert(widgets, panes[i])
        end

        panes[i]:Load(t)
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
    for i = #widgets + 1, #panes do
        print("hide", i)
        panes[i]:Hide()
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFC_ShowFrame", function(which)
    if which == "Publish" then
        if not publishFrame then
            CreatePublishFrame()
            LoadCharacters()
        end
        publishFrame:Show()
    else
        if publishFrame then
            publishFrame:Hide()
        end
    end
end)