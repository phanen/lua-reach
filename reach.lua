local M = {}

M.reach = function(from, to)
  local X = {
    { val = from, prev = nil, key = nil },
    -- [_G] = true,
  }
  for _, node in ipairs(X) do
    local val = node.val
    if val == to then
      local stk = {}
      while true do
        stk[#stk + 1] = node.key .. " (" .. tostring(node.val) .. ")"
        node = node.prev
        if not node or not node.key then
          table.sort(stk, function(a, b) return a > b end)
          return table.concat(stk, "\n")
        end
      end
    end
    if X[val] then goto continue end
    ---@diagnostic disable-next-line: assign-type-mismatch
    X[val] = true
    if type(val) == "function" then
      local i = 1
      while true do
        local n, v = debug.getupvalue(val, i)
        if not n then break end
        if type(v) == "table" or type(v) == "function" then
          X[#X + 1] = { val = v, prev = node, key = ("-(up.%s)->"):format(tostring(n)) }
        end
        i = i + 1
      end
    elseif type(val) == "table" then
      for k, v in pairs(val) do
        if type(v) == "table" or type(v) == "function" then
          X[#X + 1] = { val = v, prev = node, key = k }
        end
      end
    end
    local mt = getmetatable(val)
    if not mt then goto continue end
    X[#X + 1] = { val = mt, prev = node, key = "-(mt)->" }
    ::continue::
  end
  return false
end

return M
