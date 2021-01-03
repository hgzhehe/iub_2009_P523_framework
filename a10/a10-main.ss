(eval-when (compile load eval)
    (optimize-level 2)
    (case-sensitive #t)
)
    
(load "../match.ss")
(load "../helpers.ss")
(load "../fmts.pretty")     ;inform pretty-print about new forms
(load "../driver.ss")
(load "a10-wrapper.ss")
(load "tests10.ss")
(load "compiler-passes10.ss")
    
    
(load "a10.ss")
#!eof
(tracer #f)
(tracer #t)
    
(load "a10-main.ss")
(test-all)
