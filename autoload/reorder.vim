" Interface {{{1
fu reorder#setup(order_type) abort "{{{2
    let s:how = a:order_type
    let &opfunc = 'reorder#op'
    return 'g@'
endfu

fu reorder#op(type) abort "{{{2
    let s:type = a:type

    if a:type is# 'line'
        call s:reorder_lines()
    else
        let [cb_save, sel_save] = [&cb, &sel]
        let reg_save = getreginfo('"')
        try
            set cb-=unnamed cb-=unnamedplus sel=inclusive

            if s:type is# 'char'
                norm! `[v`]y
            elseif s:type is# 'block'
                exe "norm! `[\<c-v>`]y"
            endif

            call s:paste_new_text(s:reorder_non_linewise_text())
        catch
            return lg#catch()
        finally
            let [&cb, &sel] = [cb_save, sel_save]
            call setreg('"', reg_save)
        endtry
    endif

    " don't delete `s:how`, it would break the dot command
    unlet! s:type
endfu
"}}}1
" Core {{{1
fu s:paste_new_text(contents) abort "{{{2
    let reg_save = getreginfo('"')
    let new = deepcopy(reg_save)
    let contents = a:contents
    let type = s:type is# 'block' ? 'b' : 'c'
    call extend(new, #{regcontents: a:contents, regtype: type})
    call setreg('"', new)
    let [cb_save, sel_save] = [&cb, &sel]
    try
        set cb-=unnamed cb-=unnamedplus sel=inclusive
        norm! gvp
    catch
        return lg#catch()
    finally
        let [&cb, &sel] = [cb_save, sel_save]
        call setreg('"', reg_save)
    endtry
endfu

fu s:reorder_lines() abort "{{{2
    let range = "'[,']"
    let firstline = line("'[")
    let lastline = line("']")

    if s:how is# 'sort'
        let lines = getline(firstline, lastline)
        let flag = s:contains_only_digits(lines) ? ' n' : ''
        exe range..'sort'..flag

    elseif s:how is# 'reverse'
        let [fen_save, winid, bufnr] = [&l:fen, win_getid(), bufnr('%')]
        try
            let &l:fen = 0
            exe 'keepj keepp '..range..'g/^/m '..(firstline - 1)
        finally
            if winbufnr(winid) == bufnr
                let [tabnr, winnr] = win_id2tabwin(winid)
                call settabwinvar(tabnr, winnr, '&fen', fen_save)
            endif
        endtry

    elseif s:how is# 'shuf'
        exe 'sil keepj keepp '..range..'!shuf'
    endif
endfu

fu s:reorder_non_linewise_text() abort "{{{2
    let text = getreg('"', 1, 1)
    if len(text) == 0 | return [] | endif

    if s:type is# 'block'
        " `text` is a list of possibly multiple strings
        " We write the splitting pattern explicitly to preserve possible NULs.{{{
        "
        " NULs are translated  into newlines; and, without  a pattern, `split()`
        " splits at newlines (the default pattern is probably: `\_s\+`).
        "}}}
        let texts_to_reorder = map(text, {_,v -> split(v, '\s\+')})->flatten()

    elseif s:type is# 'char'
        " `text` is a list containing a single string
        let text = text[0]
        " Try to guess what is the separator between the texts we want to sort.{{{
        " Could be a comma, a semicolon, or spaces.
        " We want a pattern, so `sep_split` may be:
        "
        "     ',\s*'
        "     ';\s*'
        "     '\s\+'
        "}}}
        let sep_split = text =~# '[,;]'
                    \ ?     matchstr(text, '[,;]')..'\s*'
                    \ :     '\s\+'

        let texts_to_reorder = split(text, sep_split)
        " remove surrounding whitespace
        call map(texts_to_reorder, 'trim(v:val)')

        " `join()` doesn't interpret its 2nd argument the same way `split()` does:{{{
        "
        "     split():  regex
        "     join():   literal string
        "
        " `sep_join` may be:
        "
        "     ', '
        "     '; '
        "     ' '
        "     ','
        "     ';'
        "     ';'
        "}}}
        let pat = '^\\s\\+$\|\\s\*$'
        let rep = text =~# '\s' ? ' ' : ''
        let sep_join = substitute(sep_split, pat, rep, '')
        "   │
        "   └ separator which will be added between 2 consecutive texts
    endif

    if s:how is# 'sort'
        let func = s:contains_only_digits(texts_to_reorder) ? 'N' : ''
        let sorted = sort(texts_to_reorder, func)
    elseif s:how is# 'reverse'
        let sorted = reverse(texts_to_reorder)
    else
        sil let sorted = systemlist('shuf', texts_to_reorder)
    endif

    if s:type is 'block'
        return reduce(sorted, {a,v -> a + [v]}, [])
    else
        return [join(sorted, sep_join)]
    endif
endfu
"}}}1
" Utility {{{1
fu s:contains_only_digits(...) abort "{{{2
    " if  the text  contains  only  digits, we  want  a  numerical sorting  (not
    " lexicographic)

    " Vim passes a variable to a function by reference not by copy,
    " and we don't want `map()` and `filter()` to alter the text.
    let texts = deepcopy(a:1)
    call map(texts, {_,v -> matchstr(v, '\D')})
    call filter(texts, {_,v -> v != ''})
    return empty(texts)
endfu

