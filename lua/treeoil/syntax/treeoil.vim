if exists("b:current_syntax")
  finish
endif
syn match treeoilId /^#\d\{1,5} \s*/ conceal
let b:current_syntax = "treeoil"
