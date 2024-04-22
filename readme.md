# telescope-spring.nvim

A Telescope picker to quickly api endpoint finder in spring(boot) project

## 🖥️ Demo

![demo](https://github.com/zerochae/telescope-spring.nvim/assets/84373490/2ec7c4d3-d91d-458d-a42d-06dbbff9d541)

## ✨ Features

> Search value and method in RequestMapping

![search by request mapping value](https://github.com/zerochae/telescope-spring.nvim/assets/84373490/90bd05c7-87ee-4a4d-a1bc-d7a55f4a9cea)

> Search variable value

![Search in variable path](https://github.com/zerochae/telescope-spring.nvim/assets/84373490/3622ea76-096a-4eb4-8e49-c328798fbbb7)

## 📦 Installation

```lua
-- lazy.nvim
  {
    "zerochae/telescope-spring.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("spring").setup()
    end,
  }
```

## ⚡️ Requirements
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## ⚙️ Configuration

```lua
{
  prompt_title = " Endpoint",  -- common prompt title
  preview_title = "  Preview", -- common preview title
  get = {
    prompt_title = "",  -- get prompt title
    preview_title = "", -- get preview title
  },
  post = {
    prompt_title = "",  -- post prompt title
    preview_title = "", -- post preview title
  },
  put = {
    prompt_title = "",  -- put prompt title
    preview_title = "", -- put preview title
  },
  delete = {
    prompt_title = "",  -- delete prompt title
    preview_title = "", -- delete preview title
  },
}
```
