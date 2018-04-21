fu! github#get(owner, repo)
  if !exists('s:get_result')
    let s:get_result = {}
  endif
  if !has_key(s:get_result, a:owner)
    let s:get_result[a:owner] = {}
  endif
  if has_key(s:get_result[a:owner], a:repo)
    return s:get_result[a:owner][a:repo]
  else
    let reply = webapi#http#get(g:github_api_url.'/repos/'.a:owner.'/'.a:repo)
    let content = webapi#json#decode(reply.content)
    let s:get_result[a:owner][a:repo] = content
    return content
  endif
endfu

fu! github#clone(url)
  if executable('ghq')
    let cmd = 'ghq get '.a:url
    call system(cmd)
  elseif executable('git')
    let dest = input('Where to clone? ')
    let cmd = 'git clone '.a:url.' '.dest
    call system(cmd)
  endif
endfu

fu! github#clone_handler(chan, msg)
  echo a:msg
endfu

fu! github#browse(url)
  if has('mac')
    call system('open '.a:url)
  elseif has('unix')
    call system('xdg-open '.a:url)
  elseif has('win32unix')
    call system('cygstart '.a:url)
  else
    call system('rundll32 url.dll,FileProtocolHandler '.a:url)
  endif
endfu
