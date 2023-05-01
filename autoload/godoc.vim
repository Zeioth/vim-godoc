" godoc.vim - Automatic godoc management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0




" Path helper methods {{{

function! godoc#chdir(path)
    if has('nvim')
        let chdir = haslocaldir() ? 'lcd' : haslocaldir(-1, 0) ? 'tcd' : 'cd'
    else
        let chdir = haslocaldir() ? ((haslocaldir() == 1) ? 'lcd' : 'tcd') : 'cd'
    endif
    execute chdir fnameescape(a:path)
endfunction

" Throw an exception message.
function! godoc#throw(message)
    throw "godoc: " . a:message
endfunction

" Show an error message.
function! godoc#error(message)
    let v:errmsg = "godoc: " . a:message
    echoerr v:errmsg
endfunction

" Show a warning message.
function! godoc#warning(message)
    echohl WarningMsg
    echom "godoc: " . a:message
    echohl None
endfunction

" Prints a message if debug tracing is enabled.
function! godoc#trace(message, ...)
    if g:godoc_trace || (a:0 && a:1)
        let l:message = "godoc: " . a:message
        echom l:message
    endif
endfunction

" Strips the ending slash in a path.
function! godoc#stripslash(path)
    return fnamemodify(a:path, ':s?[/\\]$??')
endfunction

" Normalizes the slashes in a path.
function! godoc#normalizepath(path)
    if exists('+shellslash') && &shellslash
        return substitute(a:path, '\v/', '\\', 'g')
    elseif has('win32')
        return substitute(a:path, '\v/', '\\', 'g')
    else
        return a:path
    endif
endfunction

" Shell-slashes the path (opposite of `normalizepath`).
function! godoc#shellslash(path)
    if exists('+shellslash') && !&shellslash
        return substitute(a:path, '\v\\', '/', 'g')
    else
        return a:path
    endif
endfunction

" Returns whether a path is rooted.
if has('win32') || has('win64')
    function! godoc#is_path_rooted(path) abort
        return len(a:path) >= 2 && (
                    \a:path[0] == '/' || a:path[0] == '\' || a:path[1] == ':')
    endfunction
else
    function! godoc#is_path_rooted(path) abort
        return !empty(a:path) && a:path[0] == '/'
    endfunction
endif

" }}}




" godoc helper methods {{{

" Finds the first directory with a project marker by walking up from the given
" file path.
function! godoc#get_project_root(path) abort
    if g:godoc_project_root_finder != ''
        return call(g:godoc_project_root_finder, [a:path])
    endif
    return godoc#default_get_project_root(a:path)
endfunction

" Default implementation for finding project markers... useful when a custom
" finder (`g:godoc_project_root_finder`) wants to fallback to the default
" behaviour.
function! godoc#default_get_project_root(path) abort
    let l:path = godoc#stripslash(a:path)
    let l:previous_path = ""
    let l:markers = g:godoc_project_root[:]
    while l:path != l:previous_path
        for root in l:markers
            if !empty(globpath(l:path, root, 1))
                let l:proj_dir = simplify(fnamemodify(l:path, ':p'))
                let l:proj_dir = godoc#stripslash(l:proj_dir)
                if l:proj_dir == ''
                    call godoc#trace("Found project marker '" . root .
                                \"' at the root of your file-system! " .
                                \" That's probably wrong, disabling " .
                                \"godoc for this file...",
                                \1)
                    call godoc#throw("Marker found at root, aborting.")
                endif
                for ign in g:godoc_exclude_project_root
                    if l:proj_dir == ign
                        call godoc#trace(
                                    \"Ignoring project root '" . l:proj_dir .
                                    \"' because it is in the list of ignored" .
                                    \" projects.")
                        call godoc#throw("Ignore project: " . l:proj_dir)
                    endif
                endfor
                return l:proj_dir
            endif
        endfor
        let l:previous_path = l:path
        let l:path = fnamemodify(l:path, ':h')
    endwhile
    call godoc#throw("Can't figure out what file to use for: " . a:path)
endfunction

" }}}




" ============================================================================
" YOU PROBABLY ONLY CARE FROM HERE
" ============================================================================

" godoc Setup {{{

" Setup godoc for the current buffer.
function! godoc#setup_godoc() abort
    if exists('b:godoc_files') && !g:godoc_debug
        " This buffer already has godoc support.
        return
    endif

    " Don't setup godoc for anything that's not a normal buffer
    " (so don't do anything for help buffers and quickfix windows and
    "  other such things)
    " Also don't do anything for the default `[No Name]` buffer you get
    " after starting Vim.
    if &buftype != '' || 
          \(bufname('%') == '' && !g:godoc_generate_on_empty_buffer)
        return
    endif

    " We only want to use vim-godoc in the filetypes supported by godoc
    if index(g:godoc_include_filetypes, &filetype) == -1
        return
    endif

    " Let the user specify custom ways to disable godoc.
    if g:godoc_init_user_func != '' &&
                \!call(g:godoc_init_user_func, [expand('%:p')])
        call godoc#trace("Ignoring '" . bufname('%') . "' because of " .
                    \"custom user function.")
        return
    endif

    " Try and find what file we should manage.
    call godoc#trace("Scanning buffer '" . bufname('%') . "' for godoc setup...")
    try
        let l:buf_dir = expand('%:p:h', 1)
        if g:godoc_resolve_symlinks
            let l:buf_dir = fnamemodify(resolve(expand('%:p', 1)), ':p:h')
        endif
        if !exists('b:godoc_root')
            let b:godoc_root = godoc#get_project_root(l:buf_dir)
        endif
        if !len(b:godoc_root)
            call godoc#trace("no valid project root.. no godoc support.")
            return
        endif
        if filereadable(b:godoc_root . '/.nogodoc')
            call godoc#trace("'.nogodoc' file found... no godoc support.")
            return
        endif

        let b:godoc_files = {}
        " for module in g:godoc_modules
        "     call call("godoc#".module."#init", [b:godoc_root])
        " endfor
    catch /^godoc\:/
        call godoc#trace("No godoc support for this buffer.")
        return
    endtry

    " We know what file to manage! Now set things up.
    call godoc#trace("Setting godoc for buffer '".bufname('%')."'")

    " Autocommands for updating godoc on save.
    " We need to pass the buffer number to the callback function in the rare
    " case that the current buffer is changed by another `BufWritePost`
    " callback. This will let us get that buffer's variables without causing
    " errors.
    let l:bn = bufnr('%')
    execute 'augroup godoc_buffer_' . l:bn
    execute '  autocmd!'
    execute '  autocmd BufWritePost <buffer=' . l:bn . '> call s:write_triggered_update_godoc(' . l:bn . ')'
    execute 'augroup end'

    " Miscellaneous commands.
    command! -buffer -bang GodocRegen :call s:manual_godoc_regen(<bang>0)
    command! -buffer -bang GodocOpen :call s:godoc_open()

endfunction

" }}}




"  godoc Management {{{

" (Re)Generate the docs for the current project.
function! s:manual_godoc_regen(bufno) abort
    if g:godoc_enabled == 1
      "visual feedback"
      if g:godoc_verbose_manual_regen == 1
        echo 'Manually regenerating godoc documentation.'
      endif

      " Run async
      call s:update_godoc(a:bufno , 0, 2)
    endif
endfunction

" Open godoc in the browser.
function! s:godoc_open() abort
    try
        let l:bn = bufnr('%')
        let l:proj_dir = getbufvar(l:bn, 'godoc_root')

        "visual feedback"
        if g:godoc_verbose_open == 1
          echo g:godoc_browser_cmd . ' ' . l:proj_dir . g:godoc_browser_file
        endif
        call job_start(['sh', '-c', g:godoc_browser_cmd . ' ' . l:proj_dir . g:godoc_browser_file], {})
    endtry
endfunction

" (re)generate godoc for a buffer that just go saved.
function! s:write_triggered_update_godoc(bufno) abort
    if g:godoc_enabled && g:godoc_generate_on_write
      call s:update_godoc(a:bufno, 0, 2)
    endif
    silent doautocmd user godocupdating
endfunction

" update godoc for the current buffer's file.
" write_mode:
"   0: update godoc if it exists, generate it otherwise.
"   1: always generate (overwrite) godoc.
"
" queue_mode:
"   0: if an update is already in progress, report it and abort.
"   1: if an update is already in progress, abort silently.
"   2: if an update is already in progress, queue another one.
function! s:update_godoc(bufno, write_mode, queue_mode) abort
    " figure out where to save.
    let l:proj_dir = getbufvar(a:bufno, 'godoc_root')

    " Switch to the project root to make the command line smaller, and make
    " it possible to get the relative path of the filename.
    let l:prev_cwd = getcwd()
    call godoc#chdir(l:proj_dir)
    try
        
        " Generate the godoc docs where specified.
        if g:godoc_auto_regen == 1
          call job_start(['sh', '-c', g:godoc_cmd], {})

        endif       

    catch /^godoc\:/
        echom "Error while generating ".a:module." file:"
        echom v:exception
    finally
        " Restore the current directory...
        call godoc#chdir(l:prev_cwd)
    endtry
endfunction

" }}}
