(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a9-wrapper.ss")
(load "tests9.ss")
(load "compiler-passes9.ss")
    
    
(load "a9.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a9-main.ss")
(test-all)
