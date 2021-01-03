(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a8-wrapper.ss")
(load "tests8.ss")
(load "compiler-passes8.ss")
    
    
(load "a8.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a8-main.ss")
(test-all)
