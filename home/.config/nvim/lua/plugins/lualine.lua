return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- 12-hour clock instead of LazyVim's 24-hour default
      opts.sections.lualine_z = {
        function()
          return " " .. os.date("%l:%M %p")
        end,
      }
    end,
  },
}
