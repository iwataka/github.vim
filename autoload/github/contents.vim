fu! github#contents#open(...)
  let path = ''
  if a:0 == 1
    let segs = split(a:1, '/')
    if len(segs) == 1
      let search = github#search#get(segs[0])
      let owner = search.items[0].owner.login
      let repo = a:1
    else
      let owner = segs[0]
      let repo = segs[1]
      let path = join(segs[2:], '/')
    endif
  elseif a:0 >= 2
    let owner = a:1
    let repo = a:2
    if a:0 >= 3
      let path = a:3
    endif
  endif
  let content = github#contents#get(owner, repo, path)
  let get = github#get(owner, repo)

  let fname = g:github_file_prefix.owner.'/'.repo.'/'.content['path']
  if bufexists(fname)
    exe 'buffer '.fname
  else
    noswapfile enew
    setlocal buftype=nofile
    silent exe 'file '.fname
    let b:github_owner = owner
    let b:github_repo = repo
    let b:github_html_url = get.html_url

    let ext = fnamemodify(content['name'], ':e')
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
      call append(0, github#contents#decode(content))
      normal! gg
    endif

    setlocal nomodifiable
    setlocal readonly
    call s:mappings()
  endif
endfu

fu! github#contents#decode(content)
  let content = substitute(a:content.content, '\n', '', 'g')
  if a:content.encoding == 'base64'
    let content = webapi#base64#b64decode(content)
  endif
  return split(content, '\n')
endfu

fu! github#contents#get(owner, repo, path)
  if !exists('s:contents_result')
    let s:contents_result = {}
  endif
  if !has_key(s:contents_result, a:owner)
    let s:contents_result[a:owner] = {}
  endif
  if !has_key(s:contents_result[a:owner], a:repo)
    let s:contents_result[a:owner][a:repo] = {}
  endif

  if has_key(s:contents_result[a:owner][a:repo], a:path)
    return s:contents_result[a:owner][a:repo][a:path]
  else
    if empty(a:path)
      let url = g:github_api_url.'/repos/'.a:owner.'/'.a:repo.'/readme'
    else
      let url = printf('%s/repos/%s/%s/contents/%s', g:github_api_url, a:owner, a:repo, a:path)
    endif
    let reply = webapi#http#get(url)
    let content = webapi#json#decode(reply.content)
    let s:contents_result[a:owner][a:repo][content.path] = content
    return content
  endif
endfu

fu! s:mappings()
    nnoremap <buffer> <silent> O
          \ :call github#browse(b:github_html_url)<cr>
    nnoremap <buffer> <silent> R
          \ :call github#releases#open(b:github_owner, b:github_repo)<cr>
    nnoremap <buffer> <silent> C
          \ :call github#clone(b:github_html_url)<cr>
endfu
