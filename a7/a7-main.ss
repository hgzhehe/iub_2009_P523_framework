(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a7-wrapper.ss")
(load "tests7.ss")
(load "compiler-passes7.ss")
    
    
(load "a7.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a7-main.ss")
(test-all)
