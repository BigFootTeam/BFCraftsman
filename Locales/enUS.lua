-- self == L
-- rawset(t, key, value)
-- Sets the value associated with a key in a table without invoking any metamethods
-- t - A table (table)
-- key - A key in the table (cannot be nil) (value)
-- value - New value to set for the key (value)
select(2, ...).L = setmetatable({

}, {
    __index = function(self, key)
        if (key ~= nil) then
           rawset(self, key, key)
           return key
        end
    end
})