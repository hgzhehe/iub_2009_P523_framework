;; Assignment 2: x86-64 Compiler - verify-scheme pass

(load "../match.ss")
(load "../helpers.ss")
(case-sensitive #t)
(optimize-level 2)

(define verify-scheme
  (lambda (x)
    (define Tail
      (lambda (x)
	(match x
	  [(begin ,[Effect -> e] ... ,[tail]) x]
	  [,v (guard (or (register? v) (frame-var? v))) x]
	  [,l (guard (label? l)) x]
	  [(,[triv]) x]
	  [,other (error 'verify-scheme "invalid tail")])))
    (define Effect
      (lambda (x)
	(match x
	  [(set! ,v (,op ,v ,t))
	   (guard (or (register? v) (frame-var? v))
		  (memq op '(+ - * logand logor sra)))
	   (when (label? t) (error 'verify-scheme "label as binop operand"))
	   (when (eq? op 'sra)
             (unless (and (integer? t) (uint6? t))
               (error 'verify-scheme "invalid sra shift")))
	   (when (eq? op '*) (unless (register? v) (error 'verify-scheme "* to fvar")))
	   x]
	  [(set! ,v ,t)
	   (guard (or (register? v) (frame-var? v)))
	   (when (label? t) (unless (register? v) (error 'verify-scheme "label to fvar")))
	   x]	  
	  [,other (error 'verify-scheme "invalid effect")])))
    (match x
      [(letrec ([,l (lambda () ,[Tail -> t*])] ...) ,[Tail -> t])
       (let ([ls `(,l ...)])
         (unless (set? ls)
           (error 'verify-scheme "duplicate label")))
       x]
      [,other (error 'verify-scheme "invalid program")])))



(define expose-frame-var
  (lambda (x)
    (define (expose x)
      (match x
	[(letrec ([,l (lambda () ,[t*])] ...) ,[t])
	 `(letrec ([,l (lambda () ,t*)] ...) ,t)]
	[(begin ,[e*] ... ,[t])
	 `(begin ,e* ... ,t)]
	[(set! ,[var1] (,binop ,[var2] ,[var3]))
	 `(set! ,var1 (,binop ,var2 ,var3))]      
	[(set! ,[var1] ,[var2])
	 `(set! ,var1 ,var2)]
	[(,[triv]) `(,triv)]
	[,fv (guard (frame-var? fv)) (make-disp-opnd 'rbp (* 8 (frame-var->index fv)))]
	[,p p]))
    (expose x)))

(define flatten-program
  (lambda (x)
    (define (flat x)
     (match x
       [(letrec ,defs ,[tail])
	`(code ,@tail ,@(flat-defs defs))]
       [(begin ,e* ... ,[tail]) `(,e* ... ,@tail)]     
       [(,triv) `((jump ,triv))]
       [,p p]))
    (define (flat-defs defs)
      (match defs
	[() '()]
	[([,label (lambda () ,tail)] . ,[rst])
	 `(,label ,@(flat tail) . ,rst)]))
    (flat x)))

(define generate-x86-64
  (lambda (x)
    (define binop-map `((+ . addq) (- . subq) (* . imulq) (logand . andq) (logor . orq) (sra . shrq)))
    (define (gen x)
      (match x
	[(code ,codes ...)
	 (begin
	   (emit '.globl "_scheme_entry")
	   (emit-label "_scheme_entry")
	   (printf "pushq %rbx
pushq %rbp
pushq %r12
pushq %r13
pushq %r14
pushq %r15
movq %rdi, %rbp
leaq _scheme_exit(%rip), %r15~n")
	   (gen codes)
	   (printf "_scheme_exit:
popq %r15
popq %r14
popq %r13
popq %r12
popq %rbp
popq %rbx
ret~n"))]
	[(set! ,v1 (,binop ,v1 ,n)) (let ([b (cdr (assq binop binop-map))])
				      (emit b (rand->x86-64-arg n) (rand->x86-64-arg v1)))]
	[(set! ,desc ,src)
	 (emit (if (label? src) 'leaq 'movq) (rand->x86-64-arg src) (rand->x86-64-arg desc))]
	[,l (guard (label? l)) (emit-label l)]
	[(jump ,dst) (emit-jump 'jmp dst)]
	[(,s ,s* ...) (begin (gen s) (gen `(,s* ...)))]
	[() (void)]))
    (gen x)))
