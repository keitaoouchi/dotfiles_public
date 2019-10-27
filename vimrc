" ----------------------------------------
" 互換性設定
" ----------------------------------------

set nocompatible

" ----------------------------------------
" Display
" ----------------------------------------
set laststatus=2
set number
set ruler
set showcmd
set showmatch
set list
set listchars=tab:>-,trail:-
set encoding=utf-8
set fillchars+=stl:\ ,stlnc:\

" ----------------------------------------
" Edit
" ----------------------------------------
set autoindent smartindent
set expandtab
set tabstop=2 softtabstop=2 shiftwidth=2
set backspace=2
set fileformat=unix
set wildmenu
set wildmode=list:full
set noswapfile
set clipboard=unnamed,autoselect
set nobackup

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
"autocmd BufWritePre * :%s/\t/    /ge

"全角空白を目立たせる
scriptencoding utf-8

"ペーストモードを簡単に切り替える
let paste_mode = 0 "0:nopaste 1:paste
func! Toggle_paste_mode()
  if g:paste_mode == 0
    set paste
    let g:paste_mode = 1
  else
    set nopaste
    let g:paste_mode = 0
  endif
  return
endfunc
nnoremap <silent> <F6> :call Toggle_paste_mode()<CR>
set pastetoggle=<F6>

" ----------------------------------------
" 色関連
" ----------------------------------------
syntax on
set t_Co=256
set background=dark
highlight SpecialKey term=underline ctermfg=darkred guifg=darkred
" ----------------------------------------
" Search
" ----------------------------------------
set hlsearch
set incsearch

nnoremap n nzz
nnoremap N Nzz
nnoremap <Esc><Esc> :nohlsearch<CR>

" ----------------------------------------
" Align.vim
" ----------------------------------------
let g:Align_xstrlen = 3

" ----------------------------------------
" Key Mappings for Compatible with Emacs
" ----------------------------------------
inoremap <C-p> <Up>
inoremap <C-n> <Down>
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-e> <End>
inoremap <C-a> <Home>
inoremap <C-h> <Backspace>
inoremap <C-d> <Del>
" カーソル位置の行をウィンドウの中央に来るようにスルロール
inoremap <C-l> <C-o>zz
" カーソル以前の文字を削除
inoremap <C-u> <C-o>d0
" カーソル以降の文字を削除
inoremap <C-k> <C-o>D
" アンドゥ
inoremap <C-x>u <C-o>u
" 貼りつけ
inoremap <C-y> <C-o>P
" カーソルから単語末尾まで削除
inoremap <F1>d <C-o>dw
" ファイルの先頭に移動
inoremap <F1>< <Esc>ggI
" ファイルの末尾に移動
inoremap <F1>> <Esc>GA
" 下にスクロール
inoremap <C-v> <C-o><C-f>
" 上にスクロール
inoremap <F1>v <C-o><C-b>
" Ctrl-Space で補完
" Windowsは <Nul>でなく <C-Space> とする
inoremap <Nul> <C-n>

" ----------------------------------------
" その他キーマップ
" ----------------------------------------

"ウィンドウ移動
noremap <C-LEFT> <C-w><C-h>
noremap <C-UP> <C-w><C-k>
noremap <C-RIGHT> <C-w><C-l>
noremap <C-DOWN> <C-w><C-j>
