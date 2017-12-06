if exists('g:loaded_reorder')
    finish
endif
let g:loaded_reorder = 1

" Mappings {{{1

nno <silent><unique>  gr   :<c-u>call reorder#set_how('reverse')<bar>set opfunc=reorder#op<cr>g@
nno <silent><unique>  grr  :<c-u>call reorder#set_how('reverse')<bar>set opfunc=reorder#op
                           \<bar>exe 'norm! '.v:count1.'g@_'<cr>
xno <silent><unique>  gr   :<c-u>call reorder#set_how('reverse')<bar>exe reorder#op(visualmode())<cr>

nno <silent><unique>  gs   :<c-u>call reorder#set_how('sort')<bar>set opfunc=reorder#op<cr>g@
nno <silent><unique>  gss  :<c-u>call reorder#set_how('sort')<bar>set opfunc=reorder#op<bar>exe 'norm! '.v:count1.'g@_'<cr>
xno <silent><unique>  gs   :<c-u>call reorder#set_how('sort')<bar>exe reorder#op(visualmode())<cr>

nno <silent><unique>  gS   :<c-u>call reorder#set_how('shuf')<bar>set opfunc=reorder#op<cr>g@
nno <silent><unique>  gSS  :<c-u>call reorder#set_how('shuf')<bar>set opfunc=reorder#op<bar>exe 'norm! '.v:count1.'g@_'<cr>
xno <silent><unique>  gS   :<c-u>call reorder#set_how('shuf')<bar>exe reorder#op(visualmode())<cr>

" Usage: {{{1

"     gs          operator to sort
"     gr          operator to reverse the order
"     gS          "           randomize the order
"
"     gsip        sort paragraph
"     5gss        sort 5 lines
"     gsib        sort text between parentheses


" When we call the operators with a characterwise motion / text-object,
" they try to guess what's the separator between the texts to sort.
" Indeed, in this case, the separator is probably not a newline, but a comma,
" a semicolon, a colon or a space.


" Sample texts to test the operators:

"     (b; c; a)    gsib
"     (b  c  a)    gsib

"     b    3gss ou gsip
"     c
"     a
