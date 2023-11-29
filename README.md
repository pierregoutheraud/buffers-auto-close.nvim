# Buffers auto close

Keep a maximum of X buffers opened at any time.  
Least recently used buffer will be closed if you have more than X buffers opened.  
Visible and modified buffers will never be closed.

## Setup

```lua
{
    "pierregoutheraud/buffers-auto-close.nvim",
    config = function()
        require("buffers-auto-close").setup({
            max_buffers = 5,
        })
    end,
}
```

## Example (max_buffers = 5)

In the video, buffers list is display at the bottom of neovim.  
When opening many buffers (I am using oil.nvim to do so), buffers list only displays a maximum of 5 buffers.

https://github.com/pierregoutheraud/buffers-auto-close.nvim/assets/1341781/c7df0c27-f70c-43bf-a986-b8b82d01aba6
