fu! github#search#open(...)
  let query = join(a:000, '+')
  let search = github#search#get(query)

  let fname = g:github_file_prefix.'search?='.query
  if bufexists(fname)
    exe 'edit '.fname
  else
    enew
    setlocal buftype=nofile
    silent exe 'file '.fname
    let b:github_query = query

    setlocal modifiable
    setlocal noreadonly
    if line('$') != 0
      call append(0, s:format(search.items))
      normal! gg
    endif

    setlocal nomodifiable
    setlocal readonly
    setlocal nolist
    call s:syntax()

    call s:mappings()
    echo 'Enter to open README, O to open in your browser'
  endif
endfu

fu! github#search#get(query)
  if !exists('s:search_result')
    let s:search_result = {}
  endif
  if has_key(s:search_result, a:query)
    return s:search_result[a:query]
  else
    let getdata = {
          \ 'q': a:query
          \ }
    let reply = webapi#http#get(g:github_api_url.'/search/repositories', getdata)
    let content = webapi#json#decode(reply.content)
    let s:search_result[a:query] = content
    return content
  endif
endfu

fu! s:syntax()
  syn match githubRepoFullName "\v^\S+/\S+" contained
  syn match githubRepoStar "\v^\S+/\S+\s+\d+" contains=githubRepoFullName contained
  syn match githubRepoDesc "\v^\S+/\S+\s+\d+.+" contains=githubRepoStar
  hi link githubRepoFullName Identifier
  hi link githubRepoStar Number
  hi link githubRepoDesc Comment
endfu

fu! s:format(items)
  let fullname_maxlen = 0
  let stargazer_count_maxlen = 0
  for item in a:items
    if len(item.full_name) > fullname_maxlen
      let fullname_maxlen = len(item.full_name)
    endif
    if len(item.stargazers_count) > stargazer_count_maxlen
      let stargazer_count_maxlen = len(item.stargazers_count)
    endif
  endfor
  let result = []
  for item in a:items
    call add(result, printf('%-'.(fullname_maxlen + 2).'s%-'.(stargazer_count_maxlen + 2).'s%s',
          \ item.full_name, item.stargazers_count, item.description))
  endfor
  return result
endfu

fu! s:mappings()
    nnoremap <buffer> <silent> <cr>
          \ :call github#search#readme(b:github_query, line('.'))<cr>
    nnoremap <buffer> <silent> O
          \ :call github#search2browser(b:github_query, line('.'))<cr>
endfu

fu! github#search#readme(query, line)
  let item = s:search_result[a:query].items[a:line - 1]
  call github#readme#open(item.full_name)
endfu

fu! github#search#browser(query, line)
  let item = s:search_result[a:query].items[a:line - 1]
  call github#browse(item.html_url)
endfu
