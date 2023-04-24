" godoc.vim - Automatic godoc management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0




" Globals - Boiler plate {{{

if (&cp || get(g:, 'godoc_dont_load', 0))
    finish
endif

if v:version < 704
    echoerr "godoc: this plugin requires vim >= 7.4."
    finish
endif

let g:godoc_debug = get(g:, 'godoc_debug', 0)

if (exists('g:loaded_godoc') && !g:godoc_debug)
    finish
endif
if (exists('g:loaded_godoc') && g:godoc_debug)
    echom "Reloaded godoc."
endif
let g:loaded_godoc = 1

let g:godoc_trace = get(g:, 'godoc_trace', 0)

let g:godoc_enabled = get(g:, 'godoc_enabled', 1)

" }}}




" Globals - For border cases {{{


let g:godoc_project_root = get(g:, 'godoc_project_root', ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout'])

let g:godoc_project_root_finder = get(g:, 'godoc_project_root_finder', '')

let g:godoc_exclude_project_root = get(g:, 'godoc_exclude_project_root', 
            \['/usr/local', '/opt/homebrew', '/home/linuxbrew/.linuxbrew'])

let g:godoc_include_filetypes = get(g:, 'godoc_include_filetypes', ['go'])
let g:godoc_resolve_symlinks = get(g:, 'godoc_resolve_symlinks', 0)
let g:godoc_generate_on_new = get(g:, 'godoc_generate_on_new', 1)
let g:godoc_generate_on_write = get(g:, 'godoc_generate_on_write', 1)
let g:godoc_generate_on_empty_buffer = get(g:, 'godoc_generate_on_empty_buffer', 0)

let g:godoc_init_user_func = get(g:, 'godoc_init_user_func', 
            \get(g:, 'godoc_enabled_user_func', ''))

let g:godoc_define_advanced_commands = get(g:, 'godoc_define_advanced_commands', 0)


" }}}




" Globals - The important stuff {{{

" godoc - Auto regen
let g:godoc_auto_regen = get(g:, 'godoc_auto_regen', 1)
let g:godoc_cmd = get(g:, 'godoc_cmd', 'godoc -html ./ > ./docs/index.html')

" godoc - Open on browser
let g:godoc_browser_cmd = get(g:, 'godoc_browser_cmd', 'xdg-open')
let g:godoc_browser_file = get(g:, 'godoc_browser_file', './docs/index.html')

" godoc - Verbose
let g:godoc_verbose_manual_regen = get(g:, 'godoc_verbose_open', '1')
let g:godoc_verbose_open = get(g:, 'godoc_verbose_open', '1')


" }}}




" godoc Setup {{{

augroup godoc_detect
    autocmd!
    autocmd BufNewFile,BufReadPost *  call godoc#setup_godoc()
    autocmd VimEnter               *  if expand('<amatch>')==''|call godoc#setup_godoc()|endif
augroup end

" }}}




" Misc Commands {{{

if g:godoc_define_advanced_commands
    command! GodocToggleEnabled :let g:godoc_enabled=!g:godoc_enabled
    command! GodocToggleTrace   :call godoc#toggletrace()
endif

" }}}

