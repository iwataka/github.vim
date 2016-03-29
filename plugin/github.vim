if &compatible || (exists('g:loaded_github') && g:loaded_github)
  finish
endif
let g:loaded_github = 1

com! -nargs=+ Greadme call github#readme(<f-args>)
com! -nargs=+ Gsearch call github#search(<f-args>)
com! -nargs=+ Greleases call github#releases(<f-args>)
