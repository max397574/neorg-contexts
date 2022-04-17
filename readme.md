# Neorg Contexts

Neorg Contexts is a neorg module that will display the headings you're currently inside at the top of the buffer.
This is really similar to [nvim-treesitter-context](https://github.com/romgrk/nvim-treesitter-context).
The reason why this is a separate repository is that this is specifically for neorg and would require a lot of changes in the code of nvim-treesitter-context.

![neorg_contexts](https://user-images.githubusercontent.com/81827001/163712934-a4eef3db-17bd-4d31-9146-fea345521b94.png)

You can use load this module by putting
```lua
["external.context"] = {},
```
into your setup.
