if exists('g:loaded_reorder')
    finish
endif
let g:loaded_reorder = 1

" Mappings {{{1

nno <expr><unique> gr  reorder#setup('reverse')
nno <expr><unique> grr reorder#setup('reverse')..'_'
xno <expr><unique> gr  reorder#setup('reverse')

nno <expr><unique> gs  reorder#setup('sort')
nno <expr><unique> gss reorder#setup('sort')..'_'
xno <expr><unique> gs  reorder#setup('sort')

nno <expr><unique> gS  reorder#setup('shuf')
nno <expr><unique> gSS reorder#setup('shuf')..'_'
xno <expr><unique> gS  reorder#setup('shuf')

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

"     b    3gss or gsip
"     c
"     a
