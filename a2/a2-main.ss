(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a2-wrapper.ss")
(load "tests2.ss")
(load "compiler-passes2.ss")
    
    
(load "a2.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a2-main.ss")
(test-all)
