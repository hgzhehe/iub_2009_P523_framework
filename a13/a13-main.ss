(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a13-wrapper.ss")
(load "tests13.ss")
(load "compiler-passes13.ss")
    
    
(load "a13.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a13-main.ss")
(test-all)
