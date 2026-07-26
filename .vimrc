" The basics
filetype plugin indent on
syntax on
set background=dark
colorscheme lunaperche

" Native Editing
set backspace=indent,eol,start " Allow backspacing over autoindent, line breaks, etc.
set scrolloff=3                " Keep lines visible above/below the cursor

" Window Splitting
set splitbelow     " Force horizontal splits to open below the current window
set splitright     " Force vertical splits to open to the right of the current window
" Sensible formatting 
set expandtab       " Convert all tabs into raw spaces
set tabstop=4       " Tabs are 4 spaces wide
set shiftwidth=4    " Autoindentation increments are also 4 spaces wide
set smartindent     " Indent after opening code blocks, such as with {
set smarttab        " Make tab at the start of the line insert shiftwidth spaces
set shiftround      " Round shift increments to the nearest multiple of shiftwidth 
set nowrap          " Avoid soft line wraps

" Clean UI and navigation
set number         " Show absolute line numbers
set relativenumber " Show relative anywhere else
set incsearch      " Show search matches instantly
set hlsearch       " Highlight all search matches
set ignorecase     " Ignore case when searching...
set smartcase      " ...unless containing a capital letter

" Statusbar 
set laststatus=2        " Always show the statusline
set statusline=%3c      " Show the column number (padded to 3 chars)
set statusline+=\ >\ %f " Show '> filename'

" Ctags (Code Navigation)
set tags=tags;/  " Tell Vim to look for a 'tags' file in the current dir, and search upwards
" Command to silently regenerate the codebase index, ignoring common bloated dirs
command! MakeTags silent !ctags -R --exclude=.git --exclude=.venv . | redraw!

set wildmenu    " Enhanced command-line completion
set wildoptions=pum
" Speed up completion by scanning only active buffers and tags
set complete=.,w,b,t
" Modern, predictable menu behavior without intrusive previews
set completeopt=menuone,noinsert,noselect

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
    autocmd FileType markdown setlocal formatprg=mdformat\ --wrap\ 80\ -
augroup END
