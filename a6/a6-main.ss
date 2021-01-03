(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a6-wrapper.ss")
(load "tests6.ss")
(load "compiler-passes6.ss")
    
    
(load "a6.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a6-main.ss")
(test-all)
