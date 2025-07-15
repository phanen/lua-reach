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
    local val = node.val ---@type any
    local ty = type(val)
    if ty ~= "function" and ty ~= 'thread' and ty ~= 'table' then
      local mt = getmetatable(val)
      if mt then X[#X + 1] = { val = mt, prev = node, by = "mt" } end
      goto continue
    end
    if val == to then
      local stk = {}
      while true do
        stk[#stk + 1] = ("%-20s = (%s)"):format(node.by, tostring(node.val))
        node = node.prev
        if not node then return table.concat(reverse(stk), "\n") end
      end
    end
    if X[val] then
      goto continue
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    X[val] = true
    local mt = getmetatable(val)
    if ty == "function" then
      local i = 1
      while true do
        local k, v = debug.getupvalue(val, i)
        if not k then break end
        if v then
          X[#X + 1] = { val = v, prev = node, by = ("u(%s)"):format(tostring(k)) }
        end
        i = i + 1
      end
      if mt then X[#X + 1] = { val = mt, prev = node, by = "mt" } end
      goto continue
    end
    if ty == 'thread' then
      -- https://stackoverflow.com/questions/28826225/getting-function-used-to-create-coroutine-thread-in-lua
      local info = debug.getinfo(val, 1)
      if info and info.func then
        X[#X + 1] = { val = info.func, prev = node, by = ("t(%s)"):format(tostring(val)) }
      end
      if mt then X[#X + 1] = { val = mt, prev = node, by = "mt" } end
      goto continue
    end
    if not mt or type(mt.__mode) ~= "string" or not mt.__mode:find("[kv]") then
      for k, v in pairs(val) do
        X[#X + 1] = { val = v, prev = node, by = (".(%s)"):format(tostring(k)) }
        X[#X + 1] = { val = k, prev = node, by = ("k(%s)"):format(tostring(k)) }
      end
      if mt then X[#X + 1] = { val = mt, prev = node, by = "mt" } end
      goto continue
    end
    if not mt.__mode:find("v") then
      for k, v in pairs(val) do
        X[#X + 1] = { val = v, prev = node, by = (".(%s)"):format(tostring(k)) }
      end
    end
    if not mt.__mode:find("k") then
      for k in pairs(val) do
        X[#X + 1] = { val = k, prev = node, by = ("k(%s)"):format(tostring(k)) }
      end
    end
    X[#X + 1] = { val = mt, prev = node, by = "mt" }
    ::continue::
  end
  return false
end

return M
