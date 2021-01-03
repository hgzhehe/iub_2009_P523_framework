(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)

(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a4-wrapper.ss")
(load "tests4.ss")
(load "compiler-passes4.ss")
    
    
(load "a4.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a4-main.ss")
(test-all)
