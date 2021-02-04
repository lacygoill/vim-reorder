vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

import {Catch, Opfunc} from 'lg.vim'
const SID: string = execute('fu Opfunc')->matchstr('\C\<def\s\+\zs<SNR>\d\+_')

# Interface {{{1
def reorder#setup(order_type: string): string #{{{2
    how = order_type
    &opfunc = SID .. 'Opfunc'
    g:opfunc = {core: 'reorder#op'}
    return 'g@'
enddef

var how: string

def reorder#op(arg_type: string) #{{{2
    stype = arg_type

    if arg_type == 'line'
        ReorderLines()
    else
        ReorderNonLinewiseText()->PasteNewText()
    endif

    # don't delete/reset `how`, it would break the dot command
    stype = ''
enddef

var stype: string
#}}}1
# Core {{{1
def PasteNewText(contents: list<string>) #{{{2
    var reg_save: dict<any> = getreginfo('"')
    var cb_save: string = &cb
    var sel_save: string = &sel

    var new: dict<any> = deepcopy(reg_save)
    var type: string = stype == 'block' ? 'b' : 'c'
    extend(new, {regcontents: contents, regtype: type})

    try
        setreg('"', new)
        set cb= sel=inclusive
        norm! gvp`[
    catch
        Catch()
        return
    finally
        [&cb, &sel] = [cb_save, sel_save]
        setreg('"', reg_save)
    endtry
enddef

def ReorderLines() #{{{2
    var range: string = ":'[,']"
    var firstline: number = line("'[")
    var lastline: number = line("']")

    if how == 'sort'
        var lines: list<string> = getline(firstline, lastline)
        var flag: string = ContainsOnlyDigits(lines) ? ' n' : ''
        exe range .. 'sort' .. flag

    elseif how == 'reverse'
        var fen_save: bool = &l:fen
        var winid: number = win_getid()
        var bufnr: number = bufnr('%')
        [fen_save, winid, bufnr] = [&l:fen, win_getid(), bufnr('%')]
        try
            &l:fen = 0
            exe 'keepj keepp ' .. range .. 'g/^/m ' .. (firstline - 1)
        finally
            if winbufnr(winid) == bufnr
                var tabnr: number
                var winnr: number
                [tabnr, winnr] = win_id2tabwin(winid)
                settabwinvar(tabnr, winnr, '&fen', fen_save)
            endif
        endtry

    elseif how == 'shuf'
        # Alternative:
        #     exe 'sil keepj keepp ' .. range .. '!shuf'
        var randomized: list<string> = getline(firstline, lastline)->Randomize()
        setline(firstline, randomized)
    endif
enddef

def ReorderNonLinewiseText(): list<string> #{{{2
    var text: list<string> = getreg('"', true, true)
    if len(text) == 0
        return []
    endif

    var sep_join: string
    var texts_to_reorder: list<string>
    if stype == 'block'
        # `text` is a list of possibly multiple strings
        # We write the splitting pattern explicitly to preserve possible NULs.{{{
        #
        # NULs are translated  into newlines; and, without  a pattern, `split()`
        # splits at newlines (the default pattern is probably: `\_s\+`).
        #}}}
        texts_to_reorder = mapnew(text, (_, v) => split(v, '\s\+'))->flattennew()

    elseif stype == 'char'
        # `text` is a list containing a single string
        var text_inside: string = text[0]
        # Try to guess what is the separator between the texts we want to sort.{{{
        # Could be a comma, a semicolon, or spaces.
        # We want a pattern, so `sep_split` may be:
        #
        #     ',\s*'
        #     ';\s*'
        #     '\s\+'
        #}}}
        var sep_split: string = text_inside =~ '[,;]'
            ?     matchstr(text_inside, '[,;]') .. '\s*'
            :     '\s\+'

        texts_to_reorder = split(text_inside, sep_split)
        # remove surrounding whitespace
        map(texts_to_reorder, (_, v) => trim(v))

        # `join()` doesn't interpret its 2nd argument the same way `split()` does:{{{
        #
        #     split():  regex
        #     join():   literal string
        #
        # `sep_join` may be:
        #
        #     ', '
        #     '; '
        #     ' '
        #     ','
        #     ';'
        #     ';'
        #}}}
        var pat: string = '^\\s\\+$\|\\s\*$'
        var rep: string = text_inside =~ '\s' ? ' ' : ''
        # separator which will be added between 2 consecutive texts
        sep_join = substitute(sep_split, pat, rep, '')
    endif

    var sorted: list<string>
    if how == 'sort'
        var func: string = ContainsOnlyDigits(texts_to_reorder) ? 'N' : ''
        sorted = sort(texts_to_reorder, func)
    elseif how == 'reverse'
        sorted = reverse(texts_to_reorder)
    else
        sorted = Randomize(texts_to_reorder)
    endif

    if stype == 'block'
        return reduce(sorted, (a, v) => a + [v], [])
    else
        return [join(sorted, sep_join)]
    endif
enddef
#}}}1
# Utility {{{1
def ContainsOnlyDigits(to_reorder: list<string>): bool #{{{2
    # if  the text  contains  only  digits, we  want  a  numerical sorting  (not
    # lexicographic)

    # Vim passes a variable to a function by reference not by copy,
    # and we don't want `map()` nor `filter()` to alter the text.
    var texts: list<string> = deepcopy(to_reorder)
        ->map((_, v) => matchstr(v, '\D'))
        ->filter((_, v) => v != '')
    return empty(texts)
enddef

def Randomize(list: list<string>): list<string> #{{{2
    # Alternative:
    #     sil return systemlist('shuf', a:list)
    return len(list)
        ->range()
        ->mapnew((_, v) => remove(list, srand()->rand() % len(list)))
enddef

