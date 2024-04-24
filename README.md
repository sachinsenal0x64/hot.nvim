<div align="center">

<p align="center">
  
  <img alt="Hot" src="https://sachinsenal0x64.github.io/picx-images-hosting/Background.92pxhcjiab.webp">
  
  <h1 align="center">Hot</h1>
  🔥 A hot reloader for Neovim that works with any programming language.
</p>

</div>

<br>

## 💕 Community

> 🍻 Join the community:  <a href="https://discord.gg/EbfftZ5Dd4">Discord</a>
> [![](https://cdn.statically.io/gh/sachinsenal0x64/picx-images-hosting@master/discord.72y8nlaw5mdc.webp)](https://discord.gg/EbfftZ5Dd4)

<br>

## ✨ Features

- Zero Dependencies
- Highly Customizable
- Multiple Languages & Unittest Reloader on the fly
- Start | Stop | Silent | Real Time Debug | Buffer Open / Close  Reload on Auto Save
- Notifications
- Custom Healthchecker
- Lualine (Status Bar) Plugin

  <br>
  
## 📦 Installation

Install the plugin with your preferred package manager:

### 💤 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua

    {
      'sachinsenal0x64/hot.nvim',
      config = function()
        local opts = require('hot.params').opts

        -- Update the Lualine Status

        Reloader = opts.tweaks.default

        -- You need a global variable if you want to use the Lualine Status

        Reloader = '🧼'

        opts.tweaks.start = '🚀'
        opts.tweaks.stop = '💤'
        opts.tweaks.test = '🧪'
        opts.tweaks.test_done = '🧪.✅'
        opts.tweaks.test_fail = '🧪.❌'
        opts.tweaks.langs = {
			      "python",
      			"go",
        },

        --- If the 'main.*' file doesn't exist, it will fall back to 'index.*'

        custom_file = "index",
        

        -- Add Languages

        opts.set.languages.python = {
    				cmd = "python3",
    				desc = "Run Python file asynchronously",
    				kill_desc = "Kill the running Python file",
    				emoji = "🐍",
    				test = "python -m unittest",
    				ext = { ".py" },
    				pattern = { "*.py" },
    			},
    
        opts.set.languages.go = {
    				cmd = "go run",
    				desc = "Run Go file asynchronously",
    				kill_desc = "Kill the running Go file",
    				emoji = "🐹",
    				test = "go test",
    				ext = { ".go" },
    				pattern = { "*.go" },
    			},

        -- Thot Health Check

        vim.api.nvim_set_keymap('n', 'ho', '<Cmd>lua require("thot").check()<CR>', { noremap = true, silent = true })

        -- Keybinds

        -- Start

        vim.api.nvim_set_keymap('n', '<F3>', '<Cmd>lua require("hot").restart()<CR>', { noremap = true, silent = true })

      end,
    },

```
