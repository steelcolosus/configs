vim.cmd([[
  augroup auto_reload
    autocmd!
    autocmd BufEnter,BufWinEnter,FocusGained,CursorHold * checktime
  augroup END
]])
