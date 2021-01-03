(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a15-wrapper.ss")
(load "tests15.ss")
(load "compiler-passes15.ss")
    
    
(load "a15.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a15-main.ss")
(test-all)
