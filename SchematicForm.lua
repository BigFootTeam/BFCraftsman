---@class BFC
local BFC = select(2, ...)
local L = BFC.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local GetCraftingReagentCount = ItemUtil.GetCraftingReagentCount
local GetCraftingReagentCountUnlocked = function() return 999 end

local forms
local currentForm
local function SetCurrentForm(frame)
    currentForm = frame
end

---------------------------------------------------------------------
-- unlock button
---------------------------------------------------------------------
local unlockButton

local function UpdateUnlockState(trigger)
    if trigger == unlockButton then
        unlockButton._unlocked = not unlockButton._unlocked
    else
        unlockButton._unlocked = nil
    end

    if unlockButton._unlocked then
        AF.RainbowText_Start(unlockButton.text)
        ItemUtil.GetCraftingReagentCount = GetCraftingReagentCountUnlocked
    else
        AF.RainbowText_Stop(unlockButton.text)
        ItemUtil.GetCraftingReagentCount = GetCraftingReagentCount
    end

    if currentForm and currentForm:IsVisible() then
        currentForm:UpdateAllSlots()
    end
end


local function UpdateUnlockButton(frame)
    if not unlockButton then
        unlockButton = AF.CreateButton(BFCMainFrame, L["Unlock All Reagents (For Simulation)"], "accent_hover", 200, 18)
        unlockButton:SetOnClick(UpdateUnlockState)
    end

    local label = frame.Label
    if label and label:IsVisible() then
        unlockButton:SetParent(frame)
        AF.ClearPoints(unlockButton)
        AF.SetPoint(unlockButton, "LEFT", label, label:GetWrappedWidth() + 10, 0)
        unlockButton:Show()
        AF.ResizeToFitText(unlockButton, unlockButton.text, 5)
    else
        unlockButton:Hide()
    end
end

---------------------------------------------------------------------
-- setup schematic simulation
---------------------------------------------------------------------
function BFC.SetupSchematicSimulation()
    forms = {
        _G.ProfessionsFrame.CraftingPage.SchematicForm,
        _G.ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm
    }

    _G.ProfessionsFrame:HookScript("OnHide", UpdateUnlockState)

    for _, form in next, forms do
        if not form._BFCHooked then
            form._BFCHooked = true
            form:HookScript("OnShow", SetCurrentForm)
            -- form:HookScript("OnHide", UpdateUnlockState)
            if form.Reagents then
                form.Reagents:HookScript("OnShow", UpdateUnlockButton)
            end
        end
    end
end