execute pathogen#infect()
syntax on
filetype plugin indent on

syntax enable
set background=dark
colorscheme material-theme
let &colorcolumn="120"
autocmd BufNewFile,BufRead *.json.jbuilder,*.god set syntax=ruby

" Spaces & Tabs {{{
set tabstop=2
set expandtab
set softtabstop=2
set shiftwidth=2
set modelines=1
set autoindent
autocmd FileType json.jbuilder,god setlocal shiftwidth=2 tabstop=2
" }}}:

" SYNTAX "
highlight Comment ctermfg=Gray
highlight Special ctermfg=DarkMagenta
highlight Constant ctermfg=Green
highlight Identifier ctermfg=Blue
highlight Function ctermfg=Blue
highlight Statement ctermfg=Magenta
highlight Keyword ctermfg=Magenta

" UI Config {{{
set number              " show line numbers
highlight LineNr ctermfg=Gray
highlight CursorLine ctermbg=DarkGray
set showcmd             " show command in bottom bar
set cursorline          " Highlight current line
set lazyredraw          " Performanc is jank af without this bad boy
set wildmenu            " show handy autocomplete menu
set nowrap              " turn off line wrapping
set laststatus=2
let mapleader = "\<Space>"
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /^\t*\zs \+/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
" }}}
" Keybindings {{{
" Copy to system clipboard
noremap <Leader>y "*y
noremap <Leader>p "*p
noremap <Leader>Y "*y$
noremap <Leader>P "*P
" Yank to end of line for Y
nnoremap Y y$
nnoremap <Leader>r ciw<C-r>0<esc>
" Skip switching to window mode for split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" No Ex Mode
nnoremap Q <Nop>
" }}}
" Mouse Config {{{
if has('mouse_sgr')
  set ttymouse=sgr
endif
set mouse=a
" }}}
" Searching and Tags {{{
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>. :CtrlPTag<CR>
" }}}
" File Handling {{{
set autoread            " Auto-reloads files if changed on disk in theory. Needs better solution
set hidden              " Allows buffers to be backgrounded without saving changes
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
" }}}
