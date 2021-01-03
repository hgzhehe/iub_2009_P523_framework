(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a1-wrapper.ss")
(load "tests1.ss")
(load "compiler-passes1.ss")
    
    
(load "a1.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a1-main.ss")
(test-all)
