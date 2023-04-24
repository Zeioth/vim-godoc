# vim-godoc
Out of the box, this plugin automatically regenerates your godoc
documentation. Currently, this plugin is in highly experimental state.

## Dependencies
You need to have intalled the package
```
godoc
```

## Documentation
Please use <:h godoc> on vim to read the [full documentation](https://github.com/Zeioth/vim-godoc/blob/main/doc/godoc.txt).

## How to use
Copy this in your vimconfig:

```
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim godoc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Enable it for the next languages
let g:godoc_include_filetypes = ['go']

" Enable the keybindings for the languages in g:godoc_include_filetypes
augroup godoc_mappings
  for ft in g:godoc_include_filetypes
    execute 'autocmd FileType ' . ft . ' nnoremap <buffer> <C-h> :<C-u>GodocOpen<CR>'
    "execute 'autocmd FileType ' . ft . ' nnoremap <buffer> <C-k> :<C-u>GodocRegen<CR>'
  endfor
augroup END
```

## Most frecuent options users customize

Enable automated doc generation on save (optional)
```
" Enabled by default for the languages defined in g:godoc_include_filetypes
let g:godoc_auto_regen = 1
```

Change the way the documentation is opened (optional)
```
" godoc - Open on browser
let g:godoc_browser_cmd = get(g:, 'godoc_browser_cmd', 'xdg-open')
let g:godoc_browser_file = get(g:, 'godoc_browser_file', './docs/index.html')
```

Custom command to generate the godoc documentation (optional)

```
let g:godoc_cmd = 'godoc -html ./ > ./docs/index.html'
```

Change the way the root of the project is detected (optional)

```
" By default, we detect the root of the project where the first .git file is found
let g:godoc_project_root = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout']
```

## Final notes

Please have in mind that you are responsable for adding your godoc directory to the .gitignore if you don't want it to be pushed by accident.

It is also possible to disable this plugin for a single project. For that, create .nogodoc file in the project root directory.

## Credits
This project started as a hack of [vim-doxygen](https://github.com/Zeioth/vim-doxygen), which started as a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We use its boiler plate functions to manage directories in vimscript with good compatibility across operative systems. So please support its author too if you can!
