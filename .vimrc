." Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

if &compatible
 set nocompatible               " Be iMproved
endif

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Set this to 1 to use ultisnips for snippet handling
let s:using_snippets = 0

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes
" Plug 'junegunn/vim-github-dashboard'
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'
Plug 'Shougo/vimfiler'
Plug 'Shougo/neoyank.vim'
Plug 'mileszs/ack.vim'
Plug 'dense-analysis/ale'
Plug 'airblade/vim-gitgutter'
" Plug '/opt/homebrew/bin/fzf'
" Plug 'junegunn/fzf'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'easymotion/vim-easymotion'
Plug 'leafgarland/typescript-vim'
Plug 'HerringtonDarkholme/yats.vim'
" Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'keith/swift.vim'
Plug 'nickspoons/vim-sharpenup'
Plug 'vim-airline/vim-airline'
Plug 'OmniSharp/Omnisharp-vim'
Plug 'jlcrochet/vim-razor'
Plug 'tpope/vim-dispatch'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
" Autocompletion
Plug 'prabirshrestha/asyncomplete.vim'
" Statusline
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
" Snippet support
if s:using_snippets
  Plug 'sirver/ultisnips'
endif
" Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" Plug 'neoclide/coc.nvim', {'branch': 'release'}

" On-demand loading
" Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
" Plug 'kovisoft/paredit', { 'for': ['clojure', 'scheme', 'scala'] }

" Plug 'autozimu/LanguageClient-neovim', {
"     \ 'branch': 'next',
"     \ 'do': 'bash install.sh',
"     \ }

" Vim Packages
packadd! lightline

" let g:OmniSharp_server_stdio = 0
let g:OmniSharp_server_path = '/Users/jonathan.hicks/projects/omnisharp-osx-arm64-net6/OmniSharp'
" let g:OmniSharp_server_path = '/Users/jonathan.hicks/projects/omnisharp-osx/omnisharp/OmniSharp.exe'

" Vim colors
packadd! dracula
syntax enable
colorscheme dracula

" Plugin outside ~/.vim/plugged with post-update hook
"Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Initialize plugin system
call plug#end()

" Required for operations modifying multiple buffers like rename.
set hidden

" let g:LanguageClient_serverCommands = {
"     \ 'clojure': ['~/.bin/clojure-lsp'],
"     \ }

if executable('sourcekit-lsp')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'sourcekit-lsp',
        \ 'cmd': {server_info->['sourcekit-lsp']},
        \ 'whitelist': ['swift'],
        \ })
endif

" nnoremap <F5> :call LanguageClient_contextMenu()<CR>
" Or map each action separately
" nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
" nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
" nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>

" Required:
filetype indent plugin on

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set nobackup
set nowritebackup
set history=500
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set autowrite

" Don't use Ex mode, use Q for formatting
map Q gq

set hlsearch
set nowrap
set autoindent
set tabstop=2
set shiftwidth=2
set expandtab
set number
set smarttab
set smartindent 
set title

set hidden
set nofixendofline
set nostartofline
set splitbelow
set splitright

" Always display the status line
set laststatus=2

" \ is the leader character
" For any plugins that use this, make their keymappings use comma
let mapleader = ","
let maplocalleader = ","

" Sessions
nmap <Leader>s :source ./Session.vim<CR>

" FZF (replaces Ctrl-P, FuzzyFinder and Command-T)
"set rtp+=/opt/homebrew/bin/fzf
set rtp+=/opt/homebrew/opt/fzf
"set rtp+=~/.fzf
nmap ; :Buffers<CR>
nmap <Leader>r :Tags<CR>
nmap <Leader>t :Files<CR>
nmap <Leader>h :History<CR>

" FZF color scheme updater from https://github.com/junegunn/fzf.vim/issues/59
" function! s:update_fzf_colors()
"   let rules =
"   \ { 'fg':      [['Normal',       'fg']],
"     \ 'bg':      [['Normal',       'bg']],
"     \ 'hl':      [['String',       'fg']],
"     \ 'fg+':     [['CursorColumn', 'fg'], ['Normal', 'fg']],
"     \ 'bg+':     [['CursorColumn', 'bg']],
"     \ 'hl+':     [['String',       'fg']],
"     \ 'info':    [['PreProc',      'fg']],
"     \ 'prompt':  [['Conditional',  'fg']],
"     \ 'pointer': [['Exception',    'fg']],
"     \ 'marker':  [['Keyword',      'fg']],
"     \ 'spinner': [['Label',        'fg']],
"     \ 'header':  [['Comment',      'fg']] }
"   let cols = []
"   for [name, pairs] in items(rules)
"     for pair in pairs
"       let code = synIDattr(synIDtrans(hlID(pair[0])), pair[1])
"       if !empty(name) && code != ''
"         call add(cols, name.':'.code)
"         break
"       endif
"     endfor
"   endfor
"   let s:orig_fzf_default_opts = get(s:, 'orig_fzf_default_opts', $FZF_DEFAULT_OPTS)
"   let $FZF_DEFAULT_OPTS = s:orig_fzf_default_opts .
"         \ (empty(cols) ? '' : (' --color='.join(cols, ',')))
" endfunction
" 
" augroup _fzf
"   autocmd!
"   autocmd VimEnter,ColorScheme * call <sid>update_fzf_colors()
" augroup END
"
augroup ColorschemePreferences
  autocmd!
  " Link ALE sign highlights to similar equivalents without background colours
  autocmd ColorScheme * highlight link ALEErrorSign   WarningMsg
  autocmd ColorScheme * highlight link ALEWarningSign ModeMsg
  autocmd ColorScheme * highlight link ALEInfoSign    Identifier
augroup END

" Use truecolor in the terminal, when it is supported
if has('termguicolors')
  set termguicolors
endif

let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" Tell ack.vim to use ag (the Silver Searcher) instead
let g:ackprg = 'ag --vimgrep'

" nerdtree stuff
"autocmd vimenter * NERDTree
map <Leader>n :NERDTreeToggle<CR>
"autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

" Use ctrl-[hjkl] to select the active split
nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>

" ALE
let g:ale_sign_warning = '▲'
let g:ale_sign_error = '✗'
let g:ale_sign_info = '·'
let g:ale_completion_enabled = 1
highlight link ALEWarningSign String
highlight link ALEErrorSign Title

let g:ale_linters = {
\  'javascript': ['eslint'],
\  'typescript': ['eslint'],
\  'go': ['vim-go'],
\  'cs': ['OmniSharp']
\}

let g:ale_fixers = {
\    'javascript': ['eslint'],
\    'typescript': ['prettier'],
\    'scss': ['prettier'],
\    'html': ['prettier']
\}
"let g:ale_fix_on_save = 1

" Asyncomplete: {{{
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 0
" }}}

" Sharpenup: {{{
" All sharpenup mappings will begin with `<Space>os`, e.g. `<Space>osgd` for
" :OmniSharpGotoDefinition
let g:sharpenup_map_prefix = '<Space>os'

let g:sharpenup_statusline_opts = { 'Text': '%s (%p/%P)' }
let g:sharpenup_statusline_opts.Highlight = 0

augroup OmniSharpIntegrations
  autocmd!
  autocmd User OmniSharpProjectUpdated,OmniSharpReady call lightline#update()
augroup END
" }}}

" Lightline
let g:lightline = {
\ 'colorscheme': 'wombat',
\ 'active': {
\   'left': [['mode', 'paste'], ['filename', 'modified']],
\   'right': [['lineinfo'], ['percent'], ['readonly', 'linter_warnings', 'linter_errors', 'linter_ok']]
\ },
\ 'component_expand': {
\   'linter_warnings': 'LightlineLinterWarnings',
\   'linter_errors': 'LightlineLinterErrors',
\   'linter_ok': 'LightlineLinterOK'
\ },
\ 'inactive': {
\   'right': [['lineinfo'], ['percent'], ['sharpenup']]
\ },
\ 'component': {
\   'sharpenup': sharpenup#statusline#Build()
\ },
\ 'component_type': {
\   'readonly': 'error',
\   'linter_warnings': 'warning',
\   'linter_errors': 'error'
\ },
\ }

" Use unicode chars for ale indicators in the statusline
let g:lightline#ale#indicator_checking = "\uf110 "
let g:lightline#ale#indicator_infos = "\uf129 "
let g:lightline#ale#indicator_warnings = "\uf071 "
let g:lightline#ale#indicator_errors = "\uf05e "
let g:lightline#ale#indicator_ok = "\uf00c "
" }}}

function! LightlineLinterWarnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ◆', all_non_errors)
endfunction

function! LightlineLinterErrors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ✗', all_errors)
endfunction

function! LightlineLinterOK() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '✓ ' : ''
endfunction

autocmd User ALELint call s:MaybeUpdateLightline()

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! s:MaybeUpdateLightline()
  if exists('#lightline')
    call lightline#update()
  end
endfunction

" Coc
let g:coc_global_extensions = ['coc-json', 'coc-git', 'coc-go', 'coc-tsserver']

" vim-go

" Go syntax highlighting
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_operators = 1

" Auto formatting and importing
let g:go_fmt_autosave = 1
let g:go_fmt_command = "goimports"

" Status line types/signatures
let g:go_auto_type_info = 1

" Run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

" OmniSharp: {{{
let g:OmniSharp_popup_position = 'peek'
if has('nvim')
  let g:OmniSharp_popup_options = {
  \ 'winblend': 30,
  \ 'winhl': 'Normal:Normal,FloatBorder:ModeMsg',
  \ 'border': 'rounded'
  \}
else
  let g:OmniSharp_popup_options = {
  \ 'highlight': 'Normal',
  \ 'padding': [0],
  \ 'border': [1],
  \ 'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
  \ 'borderhighlight': ['ModeMsg']
  \}
endif
let g:OmniSharp_popup_mappings = {
\ 'sigNext': '<C-n>',
\ 'sigPrev': '<C-p>',
\ 'pageDown': ['<C-f>', '<PageDown>'],
\ 'pageUp': ['<C-b>', '<PageUp>']
\}

if s:using_snippets
  let g:OmniSharp_want_snippet = 1
endif

let g:OmniSharp_highlight_groups = {
\ 'ExcludedCode': 'NonText'
\}
" }}}

" Use MacOS clipboard
vnoremap \y y:call system("pbcopy", getreg("\""))<CR>
nnoremap \p :call setreg("\"", system("pbpaste"))<CR>p

noremap YY "+y<CR>
noremap P "+gP<CR>
noremap XX "+x<CR>

" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
