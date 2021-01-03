(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a11-wrapper.ss")
(load "tests11.ss")
(load "compiler-passes11.ss")
    
    
(load "a11.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a11-main.ss")
(test-all)
