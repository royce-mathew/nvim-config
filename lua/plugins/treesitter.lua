return {
  -- nvim-treesitter: parser management and queries
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- Install desired parsers (async, no-op if already installed)
      require("nvim-treesitter").install({
        "c", "lua", "vim", "vimdoc", "query",
        "markdown", "markdown_inline",
        "javascript", "typescript", "tsx",
        "python", "rust", "html", "css", "json", "yaml", "toml",
      })

      -- Enable treesitter highlighting for all filetypes that have a parser
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      -- Enable treesitter-based indentation for all filetypes
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- mini.ai: treesitter-aware text objects (af/if, ac/ic, aa/ia, etc.)
  -- Replaces nvim-treesitter-textobjects which has Neovim 0.12 compatibility issues
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          -- Function textobject (af/if)
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          -- Class textobject (ac/ic)
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          -- Parameter/argument textobject (aa/ia)
          a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
          -- Block textobject (ao/io) — conditional, loop
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)

      -- Helper: pcall-wrapped move_cursor so missing parsers don't throw errors
      local function safe_move(side, ai_type, id, move_opts)
        local ok, err = pcall(require("mini.ai").move_cursor, side, ai_type, id, move_opts)
        if not ok and err then
          -- Only notify if it's NOT a missing parser error (those are expected for uninstalled languages)
          if not err:find("Can not get parser") then
            vim.notify(tostring(err), vim.log.levels.WARN)
          end
        end
      end

      -- Next/prev function
      vim.keymap.set({ "n", "x", "o" }, "]f", function() safe_move("left", "a", "f", { search_method = "next" }) end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function() safe_move("left", "a", "f", { search_method = "prev" }) end, { desc = "Prev function start" })
      vim.keymap.set({ "n", "x", "o" }, "]F", function() safe_move("right", "a", "f", { search_method = "next" }) end, { desc = "Next function end" })
      vim.keymap.set({ "n", "x", "o" }, "[F", function() safe_move("right", "a", "f", { search_method = "prev" }) end, { desc = "Prev function end" })

      -- Next/prev class
      vim.keymap.set({ "n", "x", "o" }, "]c", function() safe_move("left", "a", "c", { search_method = "next" }) end, { desc = "Next class start" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function() safe_move("left", "a", "c", { search_method = "prev" }) end, { desc = "Prev class start" })
      vim.keymap.set({ "n", "x", "o" }, "]C", function() safe_move("right", "a", "c", { search_method = "next" }) end, { desc = "Next class end" })
      vim.keymap.set({ "n", "x", "o" }, "[C", function() safe_move("right", "a", "c", { search_method = "prev" }) end, { desc = "Prev class end" })

      -- Next/prev parameter
      vim.keymap.set({ "n", "x", "o" }, "]a", function() safe_move("left", "a", "a", { search_method = "next" }) end, { desc = "Next parameter" })
      vim.keymap.set({ "n", "x", "o" }, "[a", function() safe_move("left", "a", "a", { search_method = "prev" }) end, { desc = "Prev parameter" })
    end,
  },

  -- Auto-close and auto-rename HTML/JSX tags
  { "windwp/nvim-ts-autotag", opts = {} },
}
