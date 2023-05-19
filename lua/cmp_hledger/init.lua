local source = {}
local cmp = require('cmp')

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.items = nil
  return self
end

source.get_trigger_characters = function()
  return {
    'Ex',
    'In',
    'As',
    'Li',
    'Eq',
    'E:',
    'I:',
    'A:',
    'L:',
  }
end

local ltrim = function(s)
  return s:match('^%s*(.*)')
end

local split = function(str, sep)
  local t = {}
  for s in string.gmatch(str, '([^' .. sep .. ']+)') do
    table.insert(t, s)
  end
  return t
end

local get_items = function(account_path)
  local openPop = assert(io.popen(vim.b.hledger_bin .. ' accounts -f ' .. account_path))
  local output = openPop:read('*all')
  openPop:close()
  local t = split(output, "\n")

  local items = {}
  for _, s in pairs(t) do
    table.insert(items, {
      label = s,
      kind = cmp.lsp.CompletionItemKind.Property,
    })
  end

  return items
end

source.complete = function(self, request, callback)
  if vim.bo.filetype ~= 'ledger' then
    callback()
    return
  end
  if vim.fn.executable("hledger") == 1 then
    vim.b.hledger_bin = "hledger"
  elseif vim.fn.executable("ledger") == 1 then
    vim.b.hledger_bin = "ledger"
  else
    vim.api.nvim_echo({
      { 'cmp_hledger',                         'ErrorMsg' },
      { ' ' .. 'Can\'t find hledger or ledger' },
    }, true, {})
    callback()
    return
  end
  local account_path = vim.api.nvim_buf_get_name(0)
  if not self.items then
    self.items = get_items(account_path)
  end

  local prefix_mode = false
  local input = ltrim(request.context.cursor_before_line):lower()
  local prefixes = split(input, ":")
  local pattern = ''

  for i, prefix in ipairs(prefixes) do
    if i == 1 then
      pattern = string.format('%s[%%w%%-]*', prefix:lower())
    else
      pattern = string.format('%s:%s[%%w%%-]*', pattern, prefix:lower())
    end
  end
  if #prefixes > 1 and pattern ~= '' then
    prefix_mode = true
  end

  local items = {}
  for _, item in ipairs(self.items) do
    if prefix_mode then
      if string.match(item.label:lower(), pattern) then
        table.insert(items, {
          word = item.label,
          label = item.label,
          kind = item.kind,
          textEdit = {
            filterText = input,
            newText = item.label,
            range = {
              start = {
                line = request.context.cursor.row - 1,
                character = request.offset - string.len(input),
              },
              ['end'] = {
                line = request.context.cursor.row - 1,
                character = request.context.cursor.col - 1,
              },
            },
          },
        })
      end
    else
      if vim.startswith(item.label:lower(), input) then
        table.insert(items, item)
      end
    end
  end
  callback(items)
end

return source
