;; Assignment 1: x86-64 Compiler - First Steps
;; This file implements verify-scheme and generate-x86-64 passes

(load "../match.ss")
(load "../helpers.ss")
(case-sensitive #t)
(optimize-level 2)



(define verify-scheme
  (lambda (x)
    (match x
      [(begin ,[s] ,[s*] ...) x]
      [(set! ,v1 ,n)
       (guard (and (register? v1) (int64? n)))
       x]
      [(set! ,v1 ,v2)
       (guard (and (register? v1) (register? v2)))
       x]
      [(set! ,v1 (,binop ,v1 ,n))
       (guard (and (register? v1) (memq binop '(+ - *)) (int32? n)))
       x]
      [(set! ,v1 (,binop ,v2 ,v3))
       (guard (and (register? v1) (memq binop '(+ - *))
                  (register? v2) (register? v3) (eq? v1 v2)))
       x]
      [,other (error 'verify-scheme "invalid program ~s" other)])))

(define generate-x86-64
  (lambda (x)
    (define (gen x)
     (match x
       [(begin ,s* ...)
	(begin
	  (emit '.globl "_scheme_entry")
	  (emit-label "_scheme_entry")
	  (gen s*)
	  (emit 'ret))]
       [(set! ,v1 (+ ,v1 ,n))
	(emit 'addq n v1)]
       [(set! ,v1 (- ,v1 ,n))
	(emit 'subq n v1)]
       [(set! ,v1 (* ,v1 ,n))
	(emit 'imulq n v1)]
       [(set! ,v1 (+ ,v1 ,v2))
	(emit 'addq v2 v1)]
       [(set! ,v1 (- ,v1 ,v2))
	(emit 'subq v2 v1)]
       [(set! ,v1 (* ,v1 ,v2))
	(emit 'imulq v2 v1)]
       [(set! ,v1 ,n)
	(emit 'movq n v1)]
       [(set! ,v1 ,v2)
	(emit 'movq v2 v1)]
       [(,s ,s* ...) (begin (gen s) (gen `(,s* ...)))]
       [() (void)]))
    (gen x)))



#!eof

(load "a1.ss")



(generate-x86-64
 (verify-scheme
  '(begin (set! r11 10) (set! rax -10) (set! rax (* rax r11)))))

