---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local TAGLINE_MAX_BYTES = 150

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

local publishFrame, progressBar
local enableCheckBox, taglineEditBox, charList, addButton
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
            AF.ShowMask(charList, L["Saving..."])
            prof.lastScaned = time()
            BFC.UpdateLearnedRecipesWithCallback(function(remaining, total)
                progressBar:SetSmoothedValue((total - remaining) / total * 100)
                if remaining == 0 then
                    C_Timer.After(0.5, function()
                        AF.HideMask(charList)
                    end)
                end
            end)
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

    -- enable
    enableCheckBox = AF.CreateCheckButton(publishFrame, L["Enable Publishing"], function(checked)
        BFC_DB.publish.enabled = checked
        if BFC_DB.publish.enabled then
            AF.HideMask(publishFrame)
        else
            AF.ShowMask(publishFrame, L["Publishing is disabled"], 0, -20)
        end
        BFC.CancelNextSync()
        BFC.ScheduleNextSync(true)
    end)
    AF.SetPoint(enableCheckBox, "TOPLEFT", publishFrame)
    AF.SetTooltips(enableCheckBox, "TOPLEFT", 0, 1,
        L["Enable Publishing"],
        L["Syncs automatically every few minutes instead of in real time"]
    )

    -- tagline
    local taglinePane = AF.CreateTitledPane(publishFrame, L["Tagline"], nil, 90)
    AF.SetPoint(taglinePane, "TOPLEFT", publishFrame, 0, -25)
    AF.SetPoint(taglinePane, "TOPRIGHT", publishFrame, 0, -25)

    taglineEditBox = AF.CreateScrollEditBox(taglinePane)
    taglineEditBox:SetMaxBytes(TAGLINE_MAX_BYTES + 1)
    AF.SetPoint(taglineEditBox, "TOPLEFT", taglinePane, 0, -25)
    AF.SetPoint(taglineEditBox, "BOTTOMRIGHT", taglinePane)

    taglineEditBox:SetConfirmButton(function(text)
        BFC_DB.publish.tagline = text
        BFC.CancelNextSync()
        BFC.UpdateSendingData()
        BFC.ScheduleNextSync(true)
    end)

    local bytesText = AF.CreateFontString(taglinePane, TAGLINE_MAX_BYTES, "gray", "AF_FONT_SMALL")
    AF.SetPoint(bytesText, "BOTTOMRIGHT", taglinePane.line, "BOTTOMRIGHT", 0, 2)
    taglineEditBox:SetOnTextChanged(function(text)
        bytesText:SetFormattedText("%d / %d", #text, TAGLINE_MAX_BYTES)
    end)

    -- characters and professions
    local charProfPane = AF.CreateTitledPane(publishFrame, L["Characters and Professions"])
    AF.SetPoint(charProfPane, "TOPLEFT", taglinePane, "BOTTOMLEFT", 0, -20)
    AF.SetPoint(charProfPane, "BOTTOMRIGHT")

    charList = AF.CreateScrollList(charProfPane, nil, nil, 10, 10, 7, 40, 10)
    AF.SetPoint(charList, "TOPLEFT", charProfPane, 0, -25)
    AF.SetPoint(charList, "TOPRIGHT", charProfPane, 0, -25)
end

local function LoadConfigs()
    enableCheckBox:SetChecked(BFC_DB.publish.enabled)
    taglineEditBox:SetText(BFC_DB.publish.tagline)

    if BFC_DB.publish.enabled then
        AF.HideMask(publishFrame)
    else
        AF.ShowMask(publishFrame, L["Publishing is disabled"], 0, -20)
    end
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
    if not progressBar then
        progressBar = AF.CreateBlizzardStatusBar(charList.mask, 0, 100, 70, 5, "accent")
        AF.SetPoint(progressBar, "TOP", charList.mask.text, "BOTTOM", 0, -5)
    end
    progressBar:ResetSmoothedValue(0)
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
        button:SetEnabled(BFC.validSkillLine[t.id])
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
            tremove(BFC_DB.publish.characters, pane.index)
            LoadCharacters()

            BFC.UpdateLearnedProfessions()
            BFC.CancelNextSync()
            BFC.UpdateSendingData()
            BFC.ScheduleNextSync(true)
        end
    end)

    -- load
    pane.Load = Pane_Load

    return pane
end

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
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
        tinsert(BFC_DB.publish.characters, t)

        LoadCharacters()

        BFC.UpdateLearnedProfessions()
        BFC.CancelNextSync()
        BFC.UpdateSendingData()
        BFC.ScheduleNextSync(true)
    end)
end


LoadCharacters = function()
    local widgets = {}
    local currentCharacterFound = false

    for i, t in pairs(BFC_DB.publish.characters) do
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
            LoadConfigs()
            LoadCharacters()
        end
        -- AF.SetHeight(BFCMainFrame, 575)
        publishFrame:Show()
    else
        if publishFrame then
            publishFrame:Hide()
        end
    end
end)