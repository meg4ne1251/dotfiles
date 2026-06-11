" ~/.vimrc

set nocompatible

" --- Encoding ---------------------------------------------------------------
set encoding=utf-8
scriptencoding utf-8
" Auto-detect Japanese encodings (UTF-8 / EUC-JP / Shift_JIS) when reading.
set fileencodings=utf-8,euc-jp,cp932,iso-2022-jp,latin1
set fileformats=unix,dos,mac

" --- Display ----------------------------------------------------------------
syntax on
set number
set relativenumber
set cursorline
set ruler
set showcmd
set laststatus=2
set wildmenu
set scrolloff=3
set sidescrolloff=5
set display=lastline
set list
set listchars=tab:>-,trail:~,extends:>,precedes:<

" --- Indentation ------------------------------------------------------------
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent

" Two-space indentation for these filetypes.
augroup indent_overrides
  autocmd!
  autocmd FileType yaml,json,html,css,scss,sass,javascript,typescript,vue,ruby,lua
        \ setlocal tabstop=2 shiftwidth=2 softtabstop=2
augroup END

" --- Search -----------------------------------------------------------------
set incsearch
set hlsearch
set ignorecase
set smartcase
" Clear search highlight quickly.
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" --- Editing ----------------------------------------------------------------
set backspace=indent,eol,start
set hidden
set autoread
set mouse=a
set history=10000
set undolevels=1000
if has('clipboard')
  set clipboard=unnamedplus
endif

" jj returns to normal mode.
inoremap jj <Esc>

" --- Leader (Space) mappings ------------------------------------------------
let mapleader = "\<Space>"
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>s :split<CR>
nnoremap <Leader>v :vsplit<CR>
nnoremap <Leader>t :tabnew<CR>
nnoremap <Leader>n :bnext<CR>
nnoremap <Leader>p :bprevious<CR>

" Move between windows with Ctrl+hjkl.
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" --- Persistent undo --------------------------------------------------------
if has('persistent_undo')
  let s:undodir = expand('~/.vim/undo')
  if !isdirectory(s:undodir)
    call mkdir(s:undodir, 'p', 0700)
  endif
  let &undodir = s:undodir
  set undofile
endif

" --- Strip trailing whitespace on save --------------------------------------
augroup strip_trailing_whitespace
  autocmd!
  autocmd BufWritePre * let s:view = winsaveview()
        \ | keeppatterns %s/\s\+$//e
        \ | call winrestview(s:view)
augroup END

filetype plugin indent on
