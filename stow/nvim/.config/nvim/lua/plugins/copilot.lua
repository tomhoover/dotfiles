return {
  {
    "zbirenbaum/copilot.lua",
    event = { "BufReadPost", "BufNewFile" },
    requires = {
      "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
    },
    cmd = "Copilot",
    -- event = "InsertEnter",
    config = function()
      require("copilot").setup({
        -- copilot_model = "", -- default: gpt-41-copilot, enter :Copilot model list
      })
    end,
  },
}
