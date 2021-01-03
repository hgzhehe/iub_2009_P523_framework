(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a3-wrapper.ss")
(load "tests3.ss")
(load "compiler-passes3.ss")
    
    
(load "a3.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a3-main.ss")
(test-all)
