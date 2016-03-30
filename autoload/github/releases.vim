fu! github#releases#open(...)
  if a:0 == 1
    let [owner, repo] = split(a:1, '/')
  elseif a:0 == 2
    let owner = a:1
    let repo = a:2
  endif
  let releases = s:releases(owner, repo)

  let fname = g:github_file_prefix.'repos/'.owner.'/'.repo.'/releases'
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
      call append(0, s:format(releases))
      normal! gg
    endif

    setlocal nomodifiable
    setlocal readonly
    call s:mappings()
  endif
endfu

fu! s:mappings()
    nnoremap <buffer> <silent> <cr>
          \ :call github#releases#open_assets(b:github_owner, b:github_repo, getline('.'))<cr>
endfu

fu! github#releases#open_assets(owner, repo, tag_name)
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
    let fname = g:github_file_prefix.'repos/'.a:owner.'/'.a:repo.'/releases/'.a:tag_name
    if bufexists(fname)
      exe 'edit '.fname
    else
      enew
      setlocal buftype=nofile
      silent exe 'file '.fname
      let b:github_owner = a:owner
      let b:github_repo = a:repo
      let b:github_tag_name = a:tag_name

      setlocal modifiable
      setlocal noreadonly
      if line('$') != 0
        call append(0, s:format_assets(assets))
        normal! gg
      endif

      setlocal nomodifiable
      setlocal readonly
      call s:mappings_assets()
    endif
  endif
endfu

fu! s:format_assets(assets)
  let result = []
  for asset in a:assets
    call add(result, asset.name)
  endfor
  return result
endfu

fu! s:mappings_assets()
  nnoremap <buffer> <silent> D
        \ :call github#releases#browse_asset(b:github_owner, b:github_repo, b:github_tag_name, getline('.'))<cr>
endfu

fu! github#releases#browse_asset(owner, repo, tag_name, line)
  let assets = s:assets(a:owner, a:repo, a:tag_name)
  for asset in assets
    if asset.name == a:line
      call github#browse(asset.browser_download_url)
      break
    endif
  endfor
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
    let reply = webapi#http#get(g:github_api_url.'/repos/'.a:owner.'/'.a:repo.'/releases')
    let content = webapi#json#decode(reply.content)
    let s:releases_result[a:owner][a:repo] = content
    return content
  endif
endfu

fu! s:assets(owner, repo, tag_name)
  let releases = s:releases(a:owner, a:repo)
  for release in releases
    if release.tag_name == a:tag_name
      return release.assets
    endif
  endfor
  return []
endfu

fu! s:format(releases)
  let result = []
  for release in a:releases
    call add(result, release.tag_name)
  endfor
  return result
endfu
