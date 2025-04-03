---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework
local L = BFC.L

local TEMPLATE_MAX_BYTES = 100
local configFrame

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateConfigFrame()
    configFrame = AF.CreateFrame(BFCMainFrame, "BFCConfigFrame")
    AF.SetPoint(configFrame, "TOPLEFT", BFCMainFrame, 10, -40)
    AF.SetPoint(configFrame, "BOTTOMRIGHT", BFCMainFrame, -10, 10)

    -- whisper template
    local whisperTemplatePane = AF.CreateTitledPane(configFrame, L["Whisper Template"], nil, 170)
    AF.SetPoint(whisperTemplatePane, "TOPLEFT")
    AF.SetPoint(whisperTemplatePane, "RIGHT")

    local whisperTemplateEditBox = AF.CreateScrollEditBox(whisperTemplatePane, nil, nil, nil, 65)
    configFrame.whisperTemplateEditBox = whisperTemplateEditBox
    whisperTemplateEditBox:SetMaxBytes(TEMPLATE_MAX_BYTES + 1)
    AF.SetPoint(whisperTemplateEditBox, "TOPLEFT", 0, -25)
    AF.SetPoint(whisperTemplateEditBox, "TOPRIGHT", 0, -25)

    whisperTemplateEditBox:SetConfirmButton(function(text)
        BFC_DB.whisperTemplate = strtrim(text)
    end, nil, "BOTTOMRIGHT")

    local bytesText = AF.CreateFontString(whisperTemplatePane, TEMPLATE_MAX_BYTES, "gray", "AF_FONT_SMALL")
    AF.SetPoint(bytesText, "BOTTOMRIGHT", whisperTemplatePane.line, "BOTTOMRIGHT", 0, 2)
    whisperTemplateEditBox:SetOnTextChanged(function(text)
        bytesText:SetFormattedText("%d / %d", #text, TEMPLATE_MAX_BYTES)
    end)

    local tips = AF.CreateFontString(whisperTemplatePane, nil, "gray")
    AF.SetPoint(tips, "TOPLEFT", whisperTemplateEditBox, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(tips, "TOPRIGHT", whisperTemplateEditBox, "BOTTOMRIGHT", 0, -5)
    tips:SetJustifyH("LEFT")
    tips:SetSpacing(5)
    tips:SetText(AF.WrapTextInColor("[p] ", "yellow") .. L["recipe profession"] .. "\n"
        .. AF.WrapTextInColor("[f] ", "yellow") .. L["crafting fee"] .. "\n"
        .. AF.WrapTextInColor("[r] ", "yellow") .. L["recipe name"] .. "\n"
        .. AF.WrapTextInColor("[c] ", "yellow") .. L["crafter name"])
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFC_ShowFrame", function(which)
    if which == "Config" then
        if not configFrame then
            CreateConfigFrame()
        end
        configFrame.whisperTemplateEditBox:SetText(BFC_DB.whisperTemplate)
        configFrame:Show()
    else
        if configFrame then
            configFrame:Hide()
        end
    end
end)