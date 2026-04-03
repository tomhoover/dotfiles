-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<Tab>", function()
--   local line = vim.fn.line(".")
--   if vim.fn.foldlevel(line) > 0 then
--     return "za"
--   else
--     return "<Tab>"
--   end
-- end, { expr = true, silent = true })

-- Smart <Tab> for folds without breaking jumplist
vim.keymap.set("n", "<Tab>", function()
  if vim.fn.foldclosed(".") ~= -1 then
    return "zo" -- open fold
  elseif vim.fn.foldlevel(".") > 0 then
    return "zc" -- close fold
  else
    return "<Tab>" -- preserve jumplist
  end
end, { expr = true, silent = true })

-- <S-Tab> for recursive open/close folds
vim.keymap.set("n", "<S-Tab>", "zA", { silent = true })

-- -- Toggle coPilot ghost text (<leader>uP)
-- vim.keymap.set("n", "<leader>uP", function()
--   local copilot = require("copilot.command")
--   local client = vim.lsp.get_clients({ name = "copilot" })[1]
--   if client then
--     copilot.disable()
--     vim.notify("Copilot disabled", vim.log.levels.INFO)
--   else
--     copilot.enable()
--     vim.notify("Copilot enabled", vim.log.levels.INFO)
--   end
-- end, { desc = "Toggle coPilot ghost text" })
