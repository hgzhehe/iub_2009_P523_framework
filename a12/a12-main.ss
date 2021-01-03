(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a12-wrapper.ss")
(load "tests12.ss")
(load "compiler-passes12.ss")
    
    
(load "a12.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a12-main.ss")
(test-all)
