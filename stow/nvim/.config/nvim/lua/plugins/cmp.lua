-- -- In your nvim-cmp configuration
-- local cmp = require("cmp")
-- cmp.setup({
--   mapping = {
--     ["<Tab>"] = cmp.mapping(function(fallback)
--       if LazyVim.cmp.actions.ai_accept() then
--         return
--       else
--         fallback()
--       end
--     end, { "i", "s" }),
--     ["<CR>"] = cmp.mapping.confirm({ select = true }),
--   },
-- })

-- ~/.config/nvim/lua/plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true):sub(col, col):match("%s") == nil
    end

    local cmp = require("cmp")
    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<Tab>"] = cmp.mapping(function(fallback)
        if LazyVim.cmp.actions.ai_accept() then
          return
        else
          fallback()
        end
      end, { "i", "s" }),
    })
  end,
}
