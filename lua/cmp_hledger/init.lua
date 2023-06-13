local source = {}
local cmp = require('cmp')

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.accounts = nil
  self.descriptions = nil
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

local get_accounts = function(account_path)
  local ledgerFile = os.getenv('LEDGER_FILE')
  local ledgerFileInclude = ''
  if ledgerFile then ledgerFileInclude = ' --file ' .. tostring(ledgerFile) end
  local openPop = assert(io.popen(vim.b.hledger_bin .. ' accounts --file ' .. account_path .. ledgerFileInclude))
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

local get_descriptions = function(account_path)
  local ledgerFile = os.getenv('LEDGER_FILE')
  local ledgerFileInclude = ''
  if ledgerFile then ledgerFileInclude = ' --file ' .. tostring(ledgerFile) end
  local openPop = assert(io.popen(vim.b.hledger_bin .. ' descriptions --file ' .. account_path .. ledgerFileInclude))
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
    vim.b.hledger_bin = "hledger --ignore-assertions"
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

  local items = {}
  local input = ltrim(request.context.cursor_before_line):lower()
  if string.match(input, '%d*[-/.]?%d%d[-/.]%d%d%s*[|!%*]?%s+%w+') then
    if not self.descriptions then
      self.descriptions = get_descriptions(account_path)
    end

    local _, _, payee_label = string.find(input, '%d*[-/.]?%d%d[-/.]%d%d%s*[|!%*]?%s+(%w+)')
    local payee_pattern = string.format('.*%s.*', payee_label)

    for _, item in ipairs(self.descriptions) do
      if string.match(item.label:lower(), payee_pattern) then
        table.insert(items, {
          word = item.label,
          label = item.label,
          kind = item.kind,
          textExit = {
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
    end
  else
    local prefixes = split(input, ":")
    local account_pattern = ''

    for i, prefix in ipairs(prefixes) do
      if i == 1 then
        account_pattern = string.format('%s[%%w%%-]*', prefix:lower())
      else
        account_pattern = string.format('%s:%s[%%w%%-]*', account_pattern, prefix:lower())
      end
    end
    local prefix_mode = false
    if #prefixes > 1 and account_pattern ~= '' then
      prefix_mode = true
    end

    if not self.accounts then
      self.accounts = get_accounts(account_path)
    end

    for _, item in ipairs(self.accounts) do
      if prefix_mode then
        if string.match(item.label:lower(), account_pattern) then
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
  end
  callback(items)
end

return source
