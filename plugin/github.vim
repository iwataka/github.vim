if &compatible || (exists('g:loaded_github') && g:loaded_github)
  finish
endif
let g:loaded_github = 1

let g:github_api_url = 'https://api.github.com'
let g:github_file_prefix = 'github://'

com! -nargs=+ GHOpen call github#contents#open(<f-args>)
com! -nargs=+ GHSearch call github#search#open(<f-args>)
com! -nargs=+ GHReleases call github#releases#open(<f-args>)
