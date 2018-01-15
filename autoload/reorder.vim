fu! reorder#op(type) abort "{{{1
    let s:type = a:type

    if a:type ==# 'line' || a:type ==# 'V'
        call s:reorder_lines()
    else
        let cb_save  = &cb
        let sel_save = &selection
        let reg_save = [ '"', getreg('"'), getregtype('"') ]
        try
            set cb-=unnamed cb-=unnamedplus
            set selection=inclusive

            if s:type ==# 'char'
                norm! `[v`]y
            elseif s:type ==# 'v'
                norm! `<v`>y
            elseif s:type ==# "\<c-v>"
                norm! gvy
            elseif s:type ==# 'block'
                exe "norm! `[\<c-v>`]y"
            endif

            call s:paste_new_text(s:reorder_non_linewise_text())
        catch
            return lg#catch_error()
        finally
            let &cb  = cb_save
            let &sel = sel_save
            call call('setreg', reg_save)
        endtry
    endif

    " don't delete `s:how`, it would break the dot command
    unlet! s:type
endfu

fu! s:paste_new_text(contents) abort "{{{1
    let reg_type = (s:type ==# 'block' || s:type ==# "\<c-v>") ? 'b' : ''
    call setreg('"', a:contents, reg_type)
    norm! gv""p
endfu

fu! s:reorder_lines() abort "{{{1
    let range      = s:type ==# 'line' ? "'[,']" : "'<,'>"
    let first_line = s:type ==# 'line' ? line("'[") - 1 : line("'<") - 1

    if s:how ==# 'sort'
        exe range.'sort'

    elseif s:how ==# 'reverse'
        let fen_save = &l:fen
        let &l:fen   = 0
        exe 'keepj keepp '.range.'g/^/m '.first_line
        let &l:fen = fen_save

    elseif s:how ==# 'shuf'
        exe 'keepj keepp '.range.'!shuf'
    endif
endfu

fu! s:reorder_non_linewise_text() abort "{{{1
    if s:type ==# 'block' || s:type ==# "\<c-v>"
        let texts_to_reorder = split(@")
        let sep = "\n"
        "   │
        "   └─ separator which will be added between 2 consecutive texts

    elseif s:type ==# 'char' || s:type ==# 'v'
        " Try to guess what is the separator between the texts we want to
        " sort. Could be a comma, a semicolon, or spaces.
        let regex_sep = @" =~# '[,;]'
        \?                  matchstr(@", '[,;]').'\s*'
        \:                  '\s\+'

        let texts_to_reorder = split(@", regex_sep)
        call map(texts_to_reorder, { i,v -> matchstr(v, '\s*\zs.*\ze\s*')})

        " `join()` doesn't interpret its 2nd argument the same way `split()` does:
        "
        "         split():    regex
        "         join():     literal string
        let sep = substitute(regex_sep, '^\\s\\+$\|\\s\*$', ' ', '')
    endif

    return s:how ==# 'sort'
    \?         join(sort(texts_to_reorder), sep)
    \:     s:how ==# 'reverse'
    \?         join(reverse(texts_to_reorder), sep)
    \:         join(systemlist('shuf', texts_to_reorder), sep)
endfu

fu! reorder#set_how(order_type) abort "{{{1
    let s:how = a:order_type
endfu
