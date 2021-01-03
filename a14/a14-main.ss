(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a14-wrapper.ss")
(load "tests14.ss")
(load "compiler-passes14.ss")
    
    
(load "a14.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a14-main.ss")
(test-all)
