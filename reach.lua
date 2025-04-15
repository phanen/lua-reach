local M = {}

M.reach = function(from, to)
  local reverse = function(t)
    for i = 1, math.floor(#t / 2), 1 do
      t[i], t[#t - i + 1] = t[#t - i + 1], t[i]
    end
    return t
  end

  local X = {
    { val = from, prev = nil, by = "." },
    -- [_G] = true,
  }
  for _, node in ipairs(X) do
    local val = node.val ---@type function|table
    if val == to then
      local stk = {}
      while true do
        stk[#stk + 1] = ("%-20s = (%s)"):format(node.by, tostring(node.val))
        node = node.prev
        if not node then
          return table.concat(reverse(stk), "\n")
        end
      end
    end
    if X[val] then
      goto continue
    end
    X[val] = true
    if type(val) == "function" then
      local i = 1
      while true do
        local k, v = debug.getupvalue(val, i)
        if not k then break end
        if type(v) == "table" or type(v) == "function" then
          X[#X + 1] = { val = v, prev = node, by = ("u[%s]"):format(tostring(k)) }
        end
        i = i + 1
      end
      goto continue
    end
    if type(val) ~= "table" then
      goto continue
    end
    local mt = getmetatable(val)
    if not mt or type(mt.__mode) ~= "string" or not mt.__mode:find("[kv]") then
      for k, v in pairs(val) do
        if type(v) == "table" or type(v) == "function" then
          X[#X + 1] = { val = v, prev = node, by = (".[%s]"):format(tostring(k)) }
        end
        if type(k) == "table" or type(k) == "function" then
          X[#X + 1] = { val = k, prev = node, by = ("k[%s]"):format(tostring(k)) }
        end
      end
      goto continue
    end
    if not mt.__mode:find("v") then
      for k, v in pairs(val) do
        if type(v) == "table" or type(v) == "function" then
          X[#X + 1] = { val = v, prev = node, by = (".[%s]"):format(tostring(k)) }
        end
      end
    end
    if not mt.__mode:find("k") then
      for k, _ in pairs(val) do
        if type(k) == "table" or type(k) == "function" then
          X[#X + 1] = { val = k, prev = node, by = ("k[%s]"):format(tostring(k)) }
        end
      end
    end
    X[#X + 1] = { val = mt, prev = node, key = "mt" }
    ::continue::
  end
  return false
end

return M
