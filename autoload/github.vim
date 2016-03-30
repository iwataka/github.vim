let s:save_cpo = &cpoptions
set cpoptions&vim

let s:github_api_url = 'https://api.github.com'
let s:github_prefix = 'github://'

fu! github#readme(...)
  if a:0 == 1
    let segs = split(a:1, '/')
    if len(segs) == 1
      let search = s:search(segs[0])
      let owner = search.items[0].owner.login
      let repo = a:1
    else
      let [owner, repo] = segs
    endif
  elseif a:0 == 2
    let owner = a:1
    let repo = a:2
  endif
  let readme = s:readme(owner, repo)

  let fname = s:github_prefix.owner.'/'.repo.'/'.readme['name']
  if bufexists(fname)
    exe 'edit '.fname
  else
    enew
    setlocal buftype=nofile
    silent exe 'file '.s:github_prefix.owner.'/'.repo.'/'.readme['name']
    let b:github_owner = owner
    let b:github_repo = repo

    let ext = fnamemodify(readme['name'], ':e')
    if ext =~ '\vmd|markdown'
      setlocal ft=markdown
    elseif ext =~ '\vadoc|asciidoc'
      setlocal ft=asciidoc
    elseif ext =~ '\vrst'
      setlocal ft=rst
    endif

    " See http://vim.wikia.com/wiki/Newlines_and_nulls_in_Vim_script
    setlocal modifiable
    setlocal noreadonly
    if line('$') != 0
      let content = substitute(readme.content, '\n', '', 'g')
      if readme.encoding == 'base64'
        let content = webapi#base64#b64decode(content)
      endif
      call append(0, split(content, '\n'))
      normal! gg
    endif

    setlocal nomodifiable
    setlocal readonly

    nnoremap <buffer> O :call github#readme2browser(b:github_owner, b:github_repo)<cr>
    nnoremap <buffer> R :call github#readme2releases(b:github_owner, b:github_repo)<cr>
  endif
endfu

fu! github#readme2releases(owner, repo)
  call github#releases(a:owner, a:repo)
endfu

fu! github#readme2browser(owner, repo)
  call s:open_url(s:readme_result[a:owner][a:repo].html_url)
endfu

fu! github#search(...)
  let query = join(a:000, '+')
  let search = s:search(query)

  let fname = s:github_prefix.'search?='.query
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
      call append(0, s:format_search_items(search.items))
      normal! gg
    endif

    setlocal nomodifiable
    setlocal readonly
    setlocal nolist
    call s:github_search_syntax()
    nnoremap <buffer> <cr> :call github#search2readme(b:github_query, line('.'))<cr>
    nnoremap <buffer> O :call github#search2browser(b:github_query, line('.'))<cr>

    echo 'Enter to open README, O to open in your browser'
  endif
endfu

fu! s:github_search_syntax()
  syn match githubRepoFullName "\v^\S+/\S+" contained
  syn match githubRepoStar "\v^\S+/\S+\s+\d+" contains=githubRepoFullName contained
  syn match githubRepoDesc "\v^\S+/\S+\s+\d+.+" contains=githubRepoStar
  hi link githubRepoFullName Identifier
  hi link githubRepoStar Number
  hi link githubRepoDesc Comment
endfu

fu! github#search2readme(query, line)
  let item = s:search_result[a:query].items[a:line - 1]
  call github#readme(item.full_name)
endfu

fu! github#search2browser(query, line)
  let item = s:search_result[a:query].items[a:line - 1]
  call s:open_url(item.html_url)
endfu

fu! github#releases(...)
  if a:0 == 1
    let [owner, repo] = split(a:1, '/')
  elseif a:0 == 2
    let owner = a:1
    let repo = a:2
  endif
  let releases = s:releases(owner, repo)

  let fname = s:github_prefix.'repos/'.owner.'/'.repo.'/releases'
  if bufexists(fname)
    exe 'edit '.fname
  else
    enew
    setlocal buftype=nofile
    silent exe 'file '.fname
    let b:github_owner = owner
    let b:github_repo = repo

    setlocal modifiable
    setlocal noreadonly
    if line('$') != 0
      call append(0, s:format_releases(releases))
      normal! gg
    endif

    setlocal nomodifiable
    setlocal readonly

    nnoremap <buffer> <cr> :call github#releases_assets(b:github_owner, b:github_repo, getline('.'))<cr>
  endif
endfu

fu! github#releases_assets(owner, repo, tag_name)
  let releases = s:releases(a:owner, a:repo)
  let assets = []
  for release in releases
    if release.tag_name == a:tag_name
      let assets = release.assets
    endif
  endfor
  if empty(release)
    return
  else
    let fname = s:github_prefix.'repos/'.a:owner.'/'.a:repo.'/releases/'.a:tag_name
    if bufexists(fname)
      exe 'edit '.fname
    else
      enew
      setlocal buftype=nofile
      silent exe 'file '.fname
      let b:github_owner = a:owner
      let b:github_repo = a:repo

      setlocal modifiable
      setlocal noreadonly
      if line('$') != 0
        call append(0, s:format_releases_assets(assets))
        normal! gg
      endif

      setlocal nomodifiable
      setlocal readonly
    endif
  endif
endfu

fu! s:readme(owner, repo)
  if !exists('s:readme_result')
    let s:readme_result = {}
  endif
  if !has_key(s:readme_result, a:owner)
    let s:readme_result[a:owner] = {}
  endif
  if has_key(s:readme_result[a:owner], a:repo)
    return s:readme_result[a:owner][a:repo]
  else
    let reply = webapi#http#get(s:github_api_url.'/repos/'.a:owner.'/'.a:repo.'/readme')
    let content = webapi#json#decode(reply.content)
    let s:readme_result[a:owner][a:repo] = content
    return content
  endif
endfu

fu! s:search(query)
  if !exists('s:search_result')
    let s:search_result = {}
  endif
  if has_key(s:search_result, a:query)
    return s:search_result[a:query]
  else
    let getdata = {
          \ 'q': a:query
          \ }
    let reply = webapi#http#get(s:github_api_url.'/search/repositories', getdata)
    let content = webapi#json#decode(reply.content)
    let s:search_result[a:query] = content
    return content
  endif
endfu

fu! s:format_search_items(items)
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

fu! s:releases(owner, repo)
  if !exists('s:releases_result')
    let s:releases_result = {}
  endif
  if !has_key(s:releases_result, a:owner)
    let s:releases_result[a:owner] = {}
  endif
  if has_key(s:releases_result[a:owner], a:repo)
    return s:releases_result[a:owner][a:repo]
  else
    let reply = webapi#http#get(s:github_api_url.'/repos/'.a:owner.'/'.a:repo.'/releases')
    let content = webapi#json#decode(reply.content)
    let s:releases_result[a:owner][a:repo] = content
    return content
  endif
endfu

fu! s:format_releases(releases)
  let result = []
  for release in a:releases
    call add(result, release.tag_name)
  endfor
  return result
endfu

fu! s:format_releases_assets(assets)
  let result = []
  for asset in a:assets
    call add(result, asset.name)
  endfor
  return result
endfu

fu! s:open_url(url)
  if has('unix')
    call system('xdg-open '.a:url)
  elseif has('mac')
    call system('open '.a:url)
  elseif has('win32unix')
    call system('cygstart '.a:url)
  else
    call system('rundll32 url.dll,FileProtocolHandler '.a:url)
  endif
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
