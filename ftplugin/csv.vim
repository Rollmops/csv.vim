" Filetype plugin for editing CSV files. "{{{
" Author:  Christian Brabandt <cb@256bit.org>
" Version: 0.6
" Script:  http://www.vim.org/scripts/script.php?script_id=2830
" License: VIM License
" Last Change: Wed, 16 Feb 2011 00:00:45 +0100
" Documentation: see :help ft_csv.txt
" GetLatestVimScripts: 2830 5 :AutoInstall: csv.vim
"
" Some ideas are take from the wiki http://vim.wikia.com/wiki/VimTip667
" though, implementation differs.
if v:version < 700 || exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1 "}}}

fu! <SID>GetDelimiter() "{{{
    let _cur = getpos('.')
    let Delim={0: ';', 1:  ','}
    let temp={}
    for i in  values(Delim)
	redir => temp[i]
	    exe "silent! %s/" . i . "/&/nge"
	redir END
    endfor
    let Delim = map(temp, 'matchstr(substitute(v:val, "\n", "", ""), "^\\d\\+")')

    let result=[]
    for [key, value] in items(Delim)
	if get(result,0) < value
	    call add(result, key)
	    call add(result, value)
	endif
    endfor
    call setpos('.', _cur)
    if !empty(result)
	return result[0]
    else
	return ''
    endif
endfu "}}}
fu! <SID>HiCol(colnr) "{{{
    if a:colnr > <SID>MaxColumns()
	call <SID>echoWarn("There exists no column " . a:colnr)
	return 1
    endif
    "let colpat='\%(\%("[^"]\+"' . b:delimiter . '\)\|\([^' . b:delimiter . ']\+' . b:delimiter . '\)\)'
    "let b:col= '\%(\%([^' . b:delimiter . ']*"[^"]*"[^' . b:delimiter . ']*' . b:delimiter . '\)\|\%([^' . b:delimiter . ']*\%(' . b:delimiter . '\|$\)\)\)'
    "let colpat='\%(\%([^' . b:delimiter . ']*\%("[^"]*"\)\?\)[^' . b:delimiter . ']*' . b:delimiter . '\?\)'
    "let pat='^' . <SID>GetColPat(0,a:colnr) . '\zs[^' . b:delimiter . ']*' . b:delimiter . '\?'
    "let pat='^' . <SID>GetColPat(0,a:colnr) . '\zs' . b:col
    if empty(a:colnr)
       let colnr=<sid>WColumn()
    else
       let colnr=a:colnr
    endif

    if colnr==1
	let pat='^'. <SID>GetColPat(colnr,0)
    else
	let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
    endif

    if exists("*matchadd")
	let matchlist=getmatches()
	call filter(matchlist, 'v:val["group"] !~ s:hiGroup')
	call setmatches(matchlist)
	let s:matchid=matchadd(s:hiGroup, pat, 0)
    else
        exe ":2match " . s:hiGroup . ' /' . pat . '/'
    endif
endfu "}}}
fu! <SID>WColumn() "{{{
    " Return on which column the cursor is
    let _cur = getpos('.')
    let line=getline('.')
    " If the cursor is on the field delimiter,
    " match will return the next column
    " so we move one char left
    if line[col('.')-1] == b:delimiter
       norm! h
    endif
    call search(b:col, 'e', line('.'))
    let end=col('.')-1
    call search(b:col, 'b', line('.'))
    let start=col('.')-1
    let i=escape(line[start : end], '\')
    let fields=(split(line,b:col.'\zs'))
    call setpos('.',_cur)
    return strlen(substitute(line[0:start], b:col, '-', 'g'))
    "let i=escape(line[start : end], '\')
    "let fields=(split(line,b:col.'\zs'))
    "call setpos('.',_cur)
    "return match(fields, '\V'.i)+1
endfu "}}}
fu! <SID>MaxColumns() "{{{
    "return maximum number of columns in first 10 lines
    let l=getline(1,10)
    let fields=[]
    let result=0
    for item in l
	let temp=len(split(item, b:col.'\zs'))
	let result=(temp>result ? temp : result)
    endfor
    return result
endfu "}}}
fu! <SID>echoWarn(mess) "{{{
    echohl WarningMsg
    echomsg a:mess
    echohl Normal
endfu "}}}
fu! <SID>SearchColumn(arg) "{{{
    let arglist=split(a:arg)
    let colnr=arglist[0]
    let pat=substitute(arglist[1], '^\(.\)\(.*\)\1$', '\2', '')
    let maxcolnr = <SID>MaxColumns()
    if colnr > maxcolnr
	call <SID>echoWarn("There exists no column " . colnr)
	return 1
    endif
    "let @/=<SID>GetColPat(colnr) . '*\zs' . pat . '\ze\([^' . b:delimiter . ']*' . b:delimiter .'\)\?' . <SID>GetColPat(maxcolnr-colnr-1)
    " GetColPat(nr) returns a pattern containing '\zs' if nr > 1,
    " therefore, we need to clear that flag again ;(
    " TODO:
    " Is there a better way, than running a substitute command on '\zs', may be using a flag
    " with GetColPat(zsflag, colnr)?
    if colnr > 1
	"let @/=<SID>GetColPat(colnr-1,0) . '*\zs' . pat . '\ze\([^' . b:delimiter . ']*' . b:delimiter .'\)\?' . <SID>GetColPat(maxcolnr-colnr-1,0)
	"let @/= '^' . <SID>GetColPat(colnr-1,0) . '[^' . b:delimiter . ']*\zs' . pat . '\ze[^' . b:delimiter . ']*'.b:delimiter . <SID>GetColPat(maxcolnr-colnr,0) . '$'
	"let @/= '^' . <SID>GetColPat(colnr-1,0) . b:col1 . '\?\zs' . pat . '\ze' . b:col1 .'\?' . <SID>GetColPat(maxcolnr-colnr,0) " . '$'
	let @/= '^' . <SID>GetColPat(colnr-1,0) . '\%([^' . b:delimiter .']*\)\?\zs' . pat . '\ze' . '\%([^' . b:delimiter .']*\)\?' . b:delimiter . <SID>GetColPat(maxcolnr-colnr,0)  . '$'
    else
	"let @/= '^\zs' . pat . '\ze' . substitute((<SID>GetColPat(maxcolnr - colnr)), '\\zs', '', 'g')
	"let @/= '^\zs' . b:col1 . '\?' . pat . '\ze' . b:col1 . '\?' .  <SID>GetColPat(maxcolnr,0) . '$'
	let @/= '^' . '\%([^' . b:delimiter . ']*\)\?\zs' . pat . '\ze\%([^' . b:delimiter . ']*\)\?' . b:delimiter .  <SID>GetColPat(maxcolnr-1,0) . '$'
    endif
    norm! n
endfu "}}}
fu! <SID>DelColumn(colnr) "{{{
    let maxcolnr = <SID>MaxColumns()
    if a:colnr > maxcolnr
	call <SID>echoWarn("There exists no column " . a:colnr)
	return 
    endif
    if a:colnr != '1'
	let pat= '^' . <SID>GetColPat(a:colnr-1,1) . b:col
    else
	let pat= '^' . <SID>GetColPat(a:colnr,0) 
    endif
    "let @/ = pat
    "echo pat
    exe ':%s/' . escape(pat, '/') . '//'
endfu "}}}
fu! <SID>ColWidth(colnr) "{{{
    " Return the width of a column
    let list=getline(1,'$')
    let width=20 "Fallback (wild guess)
    try
	" we have a list of the first 10 rows
	" Now transform it to a list of field a:colnr
	" and then return the maximum strlen
	" We could do it with 1 line, but that would look ugly
	call map(list, 'split(v:val, b:col."\\zs")[a:colnr-1]')
	call map(list, 'substitute(v:val, ".", "x", "g")')
	call map(list, 'strlen(v:val)')
	"call map(list, 'strlen(substitute((split(v:val, b:col."\\zs")[a:colnr-1]), '.', 'x', 'g')')
	return max(list)
    catch
        return  width
    endtry
endfu "}}}
fu! <SID>ArrangeCol() range "{{{
   let _cur=getpos('.')

   "exe ':%s/' . (b:col) . '/\=printf("%.' . (<SID>ColWidth(<SID>WColumn())+1) . 's", submatch(0).repeat(" ", (<SID>ColWidth(<SID>WColumn())-strlen(submatch(0)))))/g'
"   echo ':%s/' . (b:col) . '/\=printf("%*.*s",'  (col_width[<SID>WColumn()-1]+1) ", ". (col_width[<SID>WColumn()-1]+1) . ", submatch(0))"/g'
   "exe ':%s/' . (b:col) . '/\=printf("%*.*s",' . (col_width[<SID>WColumn()-1]+1) . ", " . (col_width[<SID>WColumn()-1]+1) . ", submatch(0))/g"
   "exe ':%s/' . (b:col) . '/\=printf("%*.*s",  (<SID>ColWidth(<SID>WColumn())+1) ,  (<SID>ColWidth(<SID>WColumn())+1) , submatch(0))/g'
   "exe ':%s/' . (b:col) . '/\=printf("%-*.*s", (col_width[<SID>WColumn()-1]+1) ,  (col_width[<SID>WColumn()-1]+1) , submatch(0))/g'
   exe ':%s/' . (b:col) . '/\=<SID>Columnize(submatch(0))/g'
   " If delimiter is a <Tab>, replace it by Space
   "if b:delimiter ==? "\t"
   "    %s/\t/ /g
   "endif
   call setpos('.', _cur)
endfu "}}}
fu! <SID>Columnize(field) "{{{
   if !exists("b:col_width")
	let b:col_width=[]
	let max_cols=<SID>MaxColumns()
	for i in range(1,max_cols)
	    call add(b:col_width, <SID>ColWidth(i))
	endfor
   endif
   " convert zero indexed list to 1 indexed list,
   " add one as delimiter
   let width=b:col_width[<SID>WColumn()-1]
   let a = split(a:field, '\zs')
   let add = eval(join(map(a, 'len(v:val)'), '+'))
   let add -= len(a)
   
   " Add one for as a frame
   " add additional width for multibyte chars
   let width = width + add  + 1

   return printf("%*s", width ,  a:field)
endfun "}}}
fu! <SID>GetColPat(colnr, zs_flag) "{{{
    if a:colnr > 1
	"let pat='\%(\%("\%([^"]\|""\)*"\)\|\%([^' . b:delimiter . '"]*\)\)\{' . (a:colnr-1) . '\}'
	"let pat='\%(\%([^' . b:delimiter . ']*\%("[^"]*"\)\?\)[^' . b:delimiter . ']*'.b:delimiter . '\)\{' . (a:colnr-1) . '\}'
	"    let pat=b:col . '\{' . (a:colnr) . '\}' . (a:zs_flag ? '\zs' : '') " . b:col
	let pat=b:col . '\{' . (a:colnr) . '\}' 
        "let pat='\%([^'.b:delimiter . ']*' . b:delimiter . '\)\{' . (a:colnr-1) . '\}'
	"if a:startofline
	"    let pat.= '[^' . b:delimiter . ']'
	"endif
    else
	"colnr = 1
        "let pat='[^' . b:delimiter . ']'
        let pat=b:col 
    endif
    "return (a:startofline ? '^' : '') . pat
    return pat . (a:zs_flag ? '\zs' : '')
endfu "}}}
fu! <SID>SplitHeaderLine(lines, bang) "{{{
    if !a:bang && !exists("b:CSV_SplitWindow")
	" Split Window
	let _stl = &l:stl
	let _sbo = &sbo
	setl scrollopt=hor scrollbind
	let lines = empty(a:lines) ? 1 : a:lines
	noa sp
	1
	exe "resize" . lines
	setl scrollopt=hor scrollbind
	"let &l:stl=repeat(' ', winwidth(0))
	let &l:stl="%#Normal#".repeat(' ',winwidth(0))
	" Highlight first row
	call matchadd("Type", b:col)
	let b:CSV_SplitWindow = winnr()
	exe "noa wincmd p"
    else
	" Close split window
	if !exists("b:CSV_SplitWindow")
	    return
	endif
	exe "noa" b:CSV_SplitWindow "wincmd w"
	unlet b:CSV_SplitWindow
	if exists("_stl")
	    let &l_stl = _stl
	endif
	if exists("_sbo")
	    let &sbo = _sbo
	endif
	setl noscrollbind
	wincmd c
    endif
endfu "}}}
fu! <SID>Col(forward) "{{{
    let colnr=<SID>WColumn()
    let maxcol=<SID>MaxColumns()
    if colnr - v:count1 >= 1 && !a:forward
	let colnr -= v:count1
    elseif colnr - v:count1 < 1 && !a:forward
	let colnr = 0
    elseif colnr + v:count1 <= <SID>MaxColumns() && a:forward
	let colnr += v:count1
    elseif colnr + v:count1 > <SID>MaxColumns() && a:forward
	let colnr = maxcol + 1
    endif
    if colnr == 1
	let pat='^'. <SID>GetColPat(colnr-1,0) 
	"let pat='^' . '\%' . line('.') . 'l'
    elseif colnr == 0
	let pat='^' . '\%' . line('.') . 'l'
    elseif colnr == maxcol + 1
	let pat='\%' . line('.') . 'l$'
    else
	let pat='^'. <SID>GetColPat(colnr-1,1) . b:col
	let pat = pat . '\%' . line('.') . 'l'
    endif
    if a:forward
	call search(pat, 'cW')
    else
	call search(pat, 'bWe')
    endif
endfun "}}}
fu! <SID>Init() "{{{
    " Hilight Group for Columns
    if exists("g:csv_hiGroup")
	let s:hiGroup = g:csv_hiGroup
    else
	let s:hiGroup="WildMenu"
    endif
    " Determine default Delimiter
    if !exists("g:csv_delim")
	let b:delimiter=<SID>GetDelimiter()
    else
	let b:delimiter=g:csv_delim
    endif
    if empty(b:delimiter)
	echohl WarningMsg
	echomsg "CSV: No delimiter found. See :h csv-delimiter to set it manually!"
	echohl Normal
    endif
    " Pattern for matching a single column
    let b:col='\%(\%([^' . b:delimiter . ']*"[^"]*"[^' . b:delimiter . ']*' . b:delimiter . '\)\|\%([^' . b:delimiter . ']*\%(' . b:delimiter . '\|$\)\)\)'
    command! -buffer WhatColumn :echo <SID>WColumn()
    command! -buffer NrColumns :echo <SID>MaxColumns()
    command! -buffer -nargs=? HiColumn :call <SID>HiCol(<q-args>)
    command! -buffer -nargs=* SearchInColumn :call <SID>SearchColumn(<q-args>)
    command! -buffer -nargs=1 DeleteColumn :call <SID>DelColumn(<args>)
    command! -buffer ArrangeColumn :call <SID>ArrangeCol()
    command! -buffer InitCSV :call <SID>Init()
    command! -buffer -bang -nargs=? Header :call <SID>SplitHeaderLine(<q-args>,<bang>0)
    " undo when setting a new filetype
    let b:undo_ftplugin = "setlocal sol< tw< wrap<"
	\ . "| unlet b:delimiter b:col"
    " CSV specific mappings
    nnoremap <silent> <buffer> W :<C-U>call <sid>Col(1)<CR>
    nnoremap <silent> <buffer> E :<C-U>call <sid>Col(0)<CR>
    nnoremap <silent> <buffer> <C-Right> :<C-U>call <sid>Col(1)<CR>
    nnoremap <silent> <buffer> <C-Left> :<C-U> call <sid>Col(0)<CR>
    " CSV local settings
    setl nostartofline tw=0 nowrap
endfu "}}}

:call <SID>Init()

" vim: set foldmethod=marker: 
