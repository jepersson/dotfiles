" The basics
filetype plugin indent on
syntax on
set background=dark

" Load the master theme first
colorscheme quiet

" Adjust markup with alabaster tweaks
hi String ctermfg=cyan
hi Constant ctermfg=cyan

" Native Editing
set backspace=indent,eol,start " Allow backspacing over autoindent, line breaks, etc.
set scrolloff=3                " Keep lines visible above/below the cursor
set wildmenu                   " Enhanced command-line completion

" Window Splitting
set splitbelow     " Force horizontal splits to open below the current window
set splitright     " Force vertical splits to open to the right of the current window

" Sensible spacing 
set expandtab       " Convert all tabs into raw spaces
set tabstop=4       " Tabs are 4 spaces wide
set shiftwidth=4    " Autoindentation increments are also 4 spaces wide
set smartindent     " Indent after opening code blocks, such as with {
set smarttab        " Make tab at the start of the line insert shiftwidth spaces
set shiftround      " Round shift increments to the nearest multiple of shiftwidth 

" Clean UI and navigation
set number         " Show absolute line numbers
set relativenumber " Show relative anywhere else
set incsearch      " Show search matches instantly as you type
set hlsearch       " Highlight all search matches
set ignorecase     " Ignore case when searching...
set smartcase      " ...unless the search contains a capital letter

" Statusbar 
set laststatus=2               " Always show the statusline
set statusline=%3c             " Show the column number (padded to 3 chars)
set statusline+=\ >\ %f\ %m    " Show '> filename [modified flag]'
set statusline+=%=             " Right-align everything after this point
set statusline+=%y\            " Show the filetype, e.g. [python]

" Ctags (Code Navigation)
set tags=tags;/  " Tell Vim to look for a 'tags' file in the current dir, and search upwards
" Command to silently regenerate the codebase index, ignoring common bloated dirs
command! MakeTags silent !ctags -R --exclude=.git --exclude=.venv . | redraw!

" Python Configuration 
augroup PythonNativeSetup
    autocmd!

    " Linting: Set :make to run Ruff against the current file buffer
    autocmd FileType python setlocal makeprg=ruff\ check\ --output-format=text\ %

    " Quickfix: Tell Vim exactly how to parse Ruff's error output
    autocmd FileType python setlocal errorformat=%f:%l:%c:\ %m

    " Formatting: Hook Ruff into Vim's native 'gq' operator (reading stdin/stdout)
    autocmd FileType python setlocal formatprg=ruff\ format\ --quiet\ -
augroup END

" Markdown Configuration 
augroup MarkdownNativeSetup
    autocmd!

    " Enable spell checking strictly for markdown documentation
    autocmd FileType markdown setlocal spell spelllang=en_us

    " Formatting: Hook mdformat into Vim's native 'gq' operator
    autocmd FileType markdown setlocal formatprg=mdformat\ -
augroup END
