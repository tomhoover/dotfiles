-- ~/.config/nvim/lua/plugins/blink.lua
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    local orig_enabled = opts.enabled
    opts.enabled = function(...)
      -- Hard-disable completion for markdown buffers
      if vim.bo.filetype == "markdown" then
        return false
      end
      -- Preserve whatever LazyVim already configured
      if type(orig_enabled) == "function" then
        return orig_enabled(...)
      end
      -- Fallback to blink's documented default condition
      return vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
    end
  end,
}
