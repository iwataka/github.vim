fu! github#readme#open(...)
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
  let get = github#get(owner, repo)

  let fname = g:github_file_prefix.owner.'/'.repo.'/'.readme['name']
  if bufexists(fname)
    exe 'edit '.fname
  else
    enew
    setlocal buftype=nofile
    silent exe 'file '.g:github_file_prefix.owner.'/'.repo.'/'.readme['name']
    let b:github_owner = owner
    let b:github_repo = repo
    let b:github_html_url = get.html_url

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
    call s:mappings()
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
    let url = g:github_api_url.'/repos/'.a:owner.'/'.a:repo.'/readme'
    let reply = webapi#http#get(url)
    let content = webapi#json#decode(reply.content)
    let s:readme_result[a:owner][a:repo] = content
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
