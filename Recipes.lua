---@class BFC
local BFC = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework

BFC.learnedRecipes = {}

local GetRecipeInfo = C_TradeSkillUI.GetRecipeInfo

local function ProcessRecipes(recipes)
    if not recipes then return end
    for _, recipeID in pairs(recipes) do
        local info = GetRecipeInfo(recipeID)
        if info then
            BFC.learnedRecipes[info.name] = true
        end
    end
end

function BFC.UpdateLearnedRecipes()
    wipe(BFC.learnedRecipes)
    for _, t in pairs(BFC_DB.characters) do
        ProcessRecipes(t.prof1.recipes)
        ProcessRecipes(t.prof2.recipes)
    end
end

local executor

---@param callback function
function BFC.UpdateLearnedRecipesWithCallback(callback)
    wipe(BFC.learnedRecipes)

    if not executor then
        executor = AF.BuildOnUpdateExecutor(function(_, recipeID, remaining, total)
            local info = GetRecipeInfo(recipeID)
            if info then
                BFC.learnedRecipes[info.name] = true
            end
            callback(remaining, total)
        end)
    end

    for _, t in pairs(BFC_DB.characters) do
        for _, recipeID in pairs(t.prof1.recipes) do
            executor:AddTask(recipeID)
        end
        for _, recipeID in pairs(t.prof2.recipes) do
            executor:AddTask(recipeID)
        end
    end

    executor:Execute()
end
