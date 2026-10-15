-- VS Code-like layout: file tree on the left, tabbed editor on the right.

vim.g.mapleader = " "

vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.linebreak = true
vim.opt.showtabline = 2
vim.opt.splitright = true
vim.opt.clipboard = "unnamedplus"
vim.opt.fillchars:append({ diff = "╱" }) -- hatched filler lines in diffs
vim.opt.undofile = true -- keep undo history after closing a file
vim.opt.ignorecase = true
vim.opt.smartcase = true -- case-sensitive search only when the query has a capital
-- Default indent; a project's .editorconfig overrides it.
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.filetype.add({ pattern = { [".*%.blade%.php"] = "blade" } })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Each Neovim tab page (Explorer, Source Control) keeps its own list of file tabs:
-- a file shows up only in the tab bar of the view it was opened in.
local tab_files = {} -- [tabpage] = { [bufnr] = true }

local function files_of(tab)
  tab_files[tab] = tab_files[tab] or {}
  return tab_files[tab]
end

-- Record every buffer shown in this tab page (neo-tree marks a file as listed only
-- after showing it); the tab bar itself only ever considers listed buffers.
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(args)
    files_of(vim.api.nvim_get_current_tabpage())[args.buf] = true
  end,
})
vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  callback = function(args)
    for _, files in pairs(tab_files) do files[args.buf] = nil end
  end,
})
vim.api.nvim_create_autocmd("TabClosed", {
  callback = function()
    for tab in pairs(tab_files) do
      if not vim.api.nvim_tabpage_is_valid(tab) then tab_files[tab] = nil end
    end
  end,
})

local function in_source_control()
  local ok, lib = pcall(require, "diffview.lib")
  return ok and lib.get_current_view() ~= nil
end

-- Close a tab without collapsing the editor window into the tree. The buffer itself
-- is deleted only when no other view still has it open.
local function close_buffer(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local tab = vim.api.nvim_get_current_tabpage()
  local files = files_of(tab)
  files[bufnr] = nil

  -- Source Control manages its own diff windows; just drop the tab there.
  if in_source_control() then return end

  local other
  for b in pairs(files) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
      other = b
      break
    end
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      if other then
        vim.api.nvim_win_set_buf(win, other)
      else
        vim.api.nvim_win_call(win, function() vim.cmd("enew") end)
      end
    end
  end

  for _, other_files in pairs(tab_files) do
    if other_files[bufnr] then return end
  end
  pcall(vim.cmd, "bdelete! " .. bufnr)
end

require("lazy").setup({
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    config = function()
      require("vscode").setup({ style = "dark" })
      vim.cmd.colorscheme("vscode")
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
    },
    opts = {
      close_if_last_window = true,
      window = {
        position = "left",
        width = 35,
        mappings = {
          -- Single click opens a file / expands a folder, like VS Code.
          ["<LeftRelease>"] = "open",
          ["<cr>"] = "open",
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_default",
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true, -- show dotfiles/ignored files dimmed, as in the screenshot
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },

  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        close_command = close_buffer,
        right_mouse_command = close_buffer,
        -- Show only this view's files, and hide the empty [No Name] placeholder
        -- (it shows up only once you type in it).
        custom_filter = function(bufnr)
          if vim.api.nvim_buf_get_name(bufnr) == "" then return vim.bo[bufnr].modified end
          return files_of(vim.api.nvim_get_current_tabpage())[bufnr] ~= nil
        end,
        show_buffer_close_icons = true,
        offsets = {
          { filetype = "neo-tree", text = "Explorer", text_align = "left", separator = true },
          { filetype = "DiffviewFiles", text = "Source Control", text_align = "left", separator = true },
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- "main" requires Neovim 0.12+
    lazy = false,
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "php", "blade", "html", "css", "javascript", "typescript", "tsx",
        "json", "yaml", "markdown", "markdown_inline", "bash", "lua",
      },
      highlight = { enable = true },
    },
  },

  {
    -- Live Markdown preview in the browser.
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = "cd app && npx --yes yarn install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Toggle Markdown preview" },
    },
  },

  {
    -- Render Markdown nicely inside the buffer.
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  {
    -- Change markers next to line numbers.
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("]c", function() gs.nav_hunk("next") end, "Next change")
        map("[c", function() gs.nav_hunk("prev") end, "Previous change")
        map("<leader>hp", gs.preview_hunk, "Preview change")
        map("<leader>hr", gs.reset_hunk, "Undo change")
        map("<leader>hs", gs.stage_hunk, "Stage change")
      end,
    },
  },

  {
    -- Source Control view: Staged/Changes list on the left, side-by-side diff on the right.
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose" },
    keys = {
      {
        "<leader>g",
        function()
          if require("diffview.lib").get_current_view() then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Toggle Source Control",
      },
    },
    config = function()
      local actions = require("diffview.actions")

      -- Diffview only refreshes on tab enter, saves inside Neovim and git index changes.
      -- Also watch the working tree so edits from other programs show up right away.
      local watcher, debounce
      local function stop_watching()
        if watcher then watcher:stop(); watcher:close(); watcher = nil end
        if debounce then debounce:stop(); debounce:close(); debounce = nil end
      end
      local function start_watching(root)
        stop_watching()
        watcher, debounce = vim.uv.new_fs_event(), vim.uv.new_timer()
        watcher:start(root, { recursive = true }, function(err, path)
          if err or not path or path:match("^%.git/") or path:match("node_modules/") then return end
          debounce:start(300, 0, vim.schedule_wrap(function()
            if require("diffview.lib").get_current_view() then vim.cmd("DiffviewRefresh") end
          end))
        end)
      end
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          if require("diffview.lib").get_current_view() then vim.cmd("DiffviewRefresh") end
        end,
      })

      require("diffview").setup({
        enhanced_diff_hl = true,
        view = {
          default = { layout = "diff2_horizontal" },
        },
        file_panel = {
          listing_style = "tree",
          win_config = { position = "left", width = 35 },
        },
        hooks = {
          -- Don't auto-open the first changed file; diffs open only when picked from the list.
          view_opened = function(view)
            if view.adapter then start_watching(view.adapter.ctx.toplevel) end
            local panel = view.panel
            if not (view.files and panel and panel.next_file) then return end
            local picked = false
            local panel_next_file = panel.next_file
            panel.next_file = function(...)
              if picked then return panel_next_file(...) end
            end
            for _, method in ipairs({ "set_file", "next_file", "prev_file" }) do
              local orig = view[method]
              view[method] = function(self, file, ...)
                if method ~= "set_file" or file then picked = true end
                return orig(self, file, ...)
              end
            end
          end,
          view_closed = stop_watching,
        },
        keymaps = {
          view = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Source Control" } },
          },
          file_panel = {
            { "n", "<LeftRelease>", actions.select_entry, { desc = "Open diff / toggle folder" } },
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Source Control" } },
          },
        },
      })
    end,
  },
})

-- Open the tree on startup. With no file to edit, focus the tree instead of the empty editor.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      vim.cmd("Neotree focus")
    else
      vim.cmd("Neotree show")
    end
  end,
})

-- Tab navigation
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next tab" })
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous tab" })
vim.keymap.set("n", "<leader>x", function() close_buffer(0) end, { desc = "Close tab" })
