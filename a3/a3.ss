
(load "../match.ss")
(load "../helpers.ss")
(case-sensitive #t)
(optimize-level 2)

(define (id x) x)

(define verify-scheme
  (lambda (x)
    (define Uvar id)
    (define (Body x)
      (match x
	[(locate ([,[Uvar -> uvar] ,[Loc -> loc]] ...) ,[Tail -> tail])
	 x]
	[,other (error 'verify-scheme "invalid body")]))
    (define (Tail x)
      (match x
	[(begin ,[Effect -> e] ... ,[tail]) x]
	[(if ,[Pred -> pred] ,[conseq] ,[alt]) x]
	[(,[Triv -> triv]) x]
	[,other (error 'verify-scheme "invalid tail")]))
    (define (Pred x)
      (match x
	[(begin ,[Effect -> e] ,[pred]) x]
	[(if ,[test] ,[conseq] ,[alt]) x]
	[(,relop ,[Triv -> t1] ,[Triv -> t2]) x]
	[(true) x]
	[(false) x]
	[,other (error 'verify-scheme "invalid pred")]))
    (define (Effect x)
      (match x
	[(begin ,[e*] ... ,[e]) x]
	[(if ,[Pred -> pred] ,[conseq] ,[alt]) x]
	[(set! ,[Var -> var] (,binop ,[Triv -> t1] ,[Triv -> t2])) x]
	[(set! ,[Var -> var] ,[Triv -> t]) x]
	[(nop) x]
	[,other (error 'verify-scheme "invalid Effect")]))
    (define Loc
      (lambda (x)
	(unless (or (register? x) (frame-var? x))
	  (error 'verify-scheme "invalid Loc"))
	x))
    (define Var
      (lambda (x)
	(unless (or (uvar? x) (register? x) (frame-var? x))
	  (error 'verify-scheme "invalid Var"))
	x))
    (define Triv
      (lambda (x)
	(unless (or (uvar? x) (register? x) (frame-var? x) (integer? x) (label? x))
	  (error 'verify-scheme "invalid Triv"))
	x))
    (match x
      [(letrec ([,label (lambda () ,[Body -> body*])] ...) ,[Body -> body])
       (let ([ls `(,label ...)])
         (unless (set? ls)
           (error 'verify-scheme "duplicate label")))
       x]     
      [,other (error 'verify-scheme "invalid program")])))

(define finalize-locations
  (lambda (x)
    (define (rep-loc loc-map x)
      (match loc-map
	[() x]
	[([,a ,b] . ,rst)
	 (if (eq? a x) b
	     (rep-loc rst x))]))
    (define (rember-tail loc-map x)
      (define (rem x)
	(match x
	  [(begin ,[e] ... ,[tail]) `(begin ,e ... ,tail)]
	  [(if ,[pred] ,[conseq] ,[alt]) `(if ,pred ,conseq ,alt)]
	  [(,[triv]) `(,triv)]
	  [(set! ,[var] (,binop ,[t1] ,[t2])) `(set! ,var (,binop ,t1 ,t2))]
	  [(set! ,[var] ,[t]) `(set! ,var ,t)]
	  [(,relop ,[v1] ,[v2]) `(,relop ,v1 ,v2)]
	  [(nop) '(nop)]
	  [,uv (guard (uvar? uv)) (rep-loc loc-map uv)]
	  [,p p]))
      (rem x))
    (define (expose x)
      (match x
	[(letrec ([,label (lambda () ,[body*])] ...) ,[body])
	 `(letrec ([,label (lambda () ,body*)] ...) ,body)]
	[(locate ,loc-map ,tail)
	 (rember-tail loc-map tail)]
	[,p p]))
    (expose x)))

(define expose-frame-var
  (lambda (x)
    (define (expose x)
      (match x
	[(letrec ([,label (lambda () ,[tail*])] ...) ,[tail])
	 `(letrec ([,label (lambda () ,tail*)] ...) ,tail)]
	[(begin ,[e*] ... ,[tail])
	 `(begin ,e* ... ,tail)]
	[(if ,[pred] ,[conseq] ,[alt])
	 `(if ,pred ,conseq ,alt)]
	[(set! ,[var] (,binop ,[v2] ,[v3]))
	 `(set! ,var (,binop ,v2 ,v3))]
	[(set! ,[var] ,[value])
	 `(set! ,var ,value)]
	[(,relop ,[v1] ,[v2])
	 `(,relop ,v1 ,v2)]
	[(,[triv]) `(,triv)]
	[,fv (guard (frame-var? fv)) (make-disp-opnd 'rbp (* 8 (frame-var->index fv)))]
	[,p p]))
    (expose x)))

(define expose-basic-blocks
  (lambda (x)
    (define *enable-optimize-jumps* #t)
    (define new-def* '())
    (define add-def
      (lambda (def)
        (set! new-def* (union `(,def) new-def*))))
    (define shortcut
      (lambda (seq)
        (define cut
          (lambda (p)
            (match p
              [(if (true) ,a ,b) a]
              [(if (false) ,a ,b) b]
              [,p p])))
        (map cut seq)))
    (define make-def
      (lambda (l seq)
        (match (shortcut seq)
          [() '()]
          [((,triv)) (guard (and *enable-optimize-jumps* (label? triv)))
           `((,triv))]
          [,seq
           (let ([label (if (label? l) l (unique-label l))])
             (add-def `(,label (lambda () ,(make-begin seq))))
             `((,label)))])))
    (define expose1 (lambda (x) (make-begin (expose `(,x) id))))
    (define expose
      (lambda (seq C)
        (match seq
          [(letrec ([,label* (lambda () ,[expose1 -> e1*])] ...) ,[expose1 -> e2*])
           `(letrec ((,label* (lambda () ,e1*)) ... ,new-def* ...) ,e2*)]
          [((begin ,s ...)) (expose `(,s ...) C)]
          [((if ,test ,conseq ,alt) ,t* ...)
           (let* ([er* (if (null? t*) '() (make-def 'j (expose `(,t* ...) C)))]
                  [C^ (if (null? t*) C (lambda (eh*) (C `(,@eh* ,@er*))))]
                  [ec* (make-def 'c (expose `(,conseq) C^))]
                  [ea* (make-def 'a (expose `(,alt) C^))])
             (expose `(,test) (lambda (et*)
                                (shortcut `((if ,@et* ,@ec* ,@ea*))))))]
          [(,h ,t ,t* ...)
           (expose `(,h) (lambda (eh*) `(,@eh* ,@(expose `(,t ,t* ...) C))))]
          [((nop)) (C '())]
          [,other (C other)])))
    (expose x id)))



(define flatten-program
  (lambda (p)
    (define flatten
      (lambda (p next-l)
        (match p
          [(letrec ,[flatten-defs -> def*] ,[tail])
           (let ([tail (cond
                        [(null? def*) tail]
                        [else
                         (match tail
                           [(,st* ... (jump ,tail)) (guard (eq? tail (caar def*)))
                            `(,st* ...)]
                           [,tail tail])])])
             `(code ,@tail ,def* ... ...))]
          [(,label* (lambda () ,[tail*])) `(,label* ,@tail*)]
          [(begin ,[ef*] ... ,[tail]) `(,ef* ... ... ,@tail)]
          [(if ,test (,conseq) (,alt))
           (cond [(eq? conseq next-l)
                  `((if (not ,test) (jump ,alt)))]
                 [(eq? alt next-l)
                  `((if ,test (jump ,conseq)))]
                 [else `((if ,test (jump ,conseq)) (jump ,alt))])]
          [(set! ,a ,b) `((set! ,a ,b))]
          [(,[triv]) (if (eq? triv next-l) '() `((jump ,triv)))]
          [,p p])))
    (define flatten-defs
      (lambda (defs)
        (match defs
          [() '()]
          [([,lab (lambda () ,body)]) `(,(flatten `(,lab (lambda () ,body)) #f))]
          [([,lab1 (lambda () ,body1)]
            [,lab2 (lambda () ,body2)]
            [,lab3 (lambda () ,body3)] ...)
           `(,(flatten `(,lab1 (lambda () ,body1)) lab2)
             ,@(flatten-defs `([,lab2 (lambda () ,body2)]
                               [,lab3 (lambda () ,body3)]...)))])))
    (flatten p #f)))


(define generate-x86-64
  (lambda (p)
    (define binop?
      (lambda (x)
	(memq x '(+ - * logand logor sra))))
    (define relop?
      (lambda (x)
	(memq x '(= < <= >= >))))
    (define binop-lookup
      (lambda (op)
        (let ([op-map '([+      . addq  ]
                        [-      . subq  ]
                        [*      . imulq ]
                        [sra    . sarq  ]
                        [logand . andq  ]
                        [logor  . orq   ])])
          (cond
           [(assq op op-map) => cdr]
           [else (error 'binop-lookup "unsupported operator ~s" op)]))))
    (define relop-lookup
      (lambda (op pos?)
        (let ([op-map '([=  . (je  jne ) ]
                        [>  . (jg  jle ) ]
                        [>= . (jge jl  ) ]
                        [<  . (jl  jge ) ]
                        [<= . (jle jg  ) ])])
          (if pos?
              (car (cdr (assq op op-map)))
              (cadr (cdr (assq op op-map)))))))
    (define emit-test
      (lambda (test v)
        (match test
          [(,op ,a ,b)
           (emit 'cmpq b a)
           (emit-jump (relop-lookup op #t) v)]
          [(not (,op ,a ,b))
           (emit 'cmpq b a)
           (emit-jump (relop-lookup op #f) v)])))
    (define code-gen
      (lambda (p)
        (match p
          [(code ,stmt* ...) (for-each code-gen stmt*)]
          [(set! ,x (,op ,y ,z)) (guard (binop? op))
           (emit (binop-lookup op) (rand->x86-64-arg z) (rand->x86-64-arg y))]
          [(set! ,x ,y)
           (if (label? y)
               (emit 'leaq (rand->x86-64-arg y) (rand->x86-64-arg x))
               (emit 'movq (rand->x86-64-arg y) (rand->x86-64-arg x)))]          
          [(if ,test (jump ,v)) (emit-test test v)]
          [(jump ,v) (emit-jump 'jmp v)]
          [,x (guard (label? x)) (emit-label x)]
          [,p (error 'code-gen "invalid statement ~a" p)])))
    (emit-program
     (code-gen p))))


#!eof
