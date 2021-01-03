(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a5-wrapper.ss")
(load "tests5.ss")
(load "compiler-passes5.ss")
    
    
(load "a5.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a5-main.ss")
(test-all)
