(load "../match.ss")
(load "../helpers.ss")
(case-sensitive #t)
(optimize-level 2)

(define (id x) x)

(define verify-scheme
  (lambda (x)
    (define (Uvar x)
      (unless (uvar? x)
	(error 'verify-scheme "invalid Uvar"))
      x)
    (define (Body x)
      (match x
	[(locals (,[Uvar -> uvar] ...) ,[Tail -> tail])
	 x]
	[,other (error 'verify-scheme "invalid body")]))
    (define (Tail x)
      (match x
	[(begin ,[Effect -> e] ... ,[tail]) x]
	[(if ,[Pred -> pred] ,[conseq] ,[alt]) x]
	[(,[Triv -> triv] ,[Loc -> loc] ...) x]
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


(define (make-empty-graph vars)
  (map (lambda (v) (cons v '())) vars))

;; ====================  Live Set 操作 ====================
(define (add-live item live)
  (if (or (register? item) (uvar? item))
      (set-cons item live)
      live))

(define (kill item live)
  (difference live (list item)))

;; ====================  Conflict Graph 操作 ====================
(define (add-conflict var1 var2 graph)
  (define (update v item g)
    (map (lambda (entry)
           (if (eq? (car entry) v)
               (cons v (union (cdr entry) (list item)))
               entry))
         g))  
  ;; 依次更新 var1 和 var2，确保双向连线
  (let* ([g1 (if (uvar? var1) (update var1 var2 graph) graph)]
         [g2 (if (uvar? var2) (update var2 var1 g1) g1)])
    g2))

(define (union-conflict-graphs g1 g2)
  (fold-left (lambda (g entry)
               (fold-left (lambda (gg item)
                            (add-conflict (car entry) item gg))
                          g (cdr entry)))
             g1 g2))

(define (kill-and-record-conflicts lhs live graph is-move?)
  (if (or (not (uvar? lhs)) is-move?)
      (values (kill lhs live) graph)
      (let* ((live-after-kill (kill lhs live)) ; ← 先 kill
             (live-items (filter (lambda (x) (or (uvar? x) (register? x))) live-after-kill))
             (new-graph (fold-left (lambda (g item)
                                     (add-conflict lhs item g))
                                   graph live-items)))
        (values live-after-kill new-graph))))

(define relop?
      (lambda (x)
	(memq x '(= < <= >= >))))

(define unc
  (lambda (live conf-graph x)
    (match x
      [(nop) (values live conf-graph)]	
      [(begin ,e ... ,tail)
       (let-values ([(l cg) (unc live conf-graph tail)])
	 (unc l cg `(begin ,e ...)))]
      [(if ,pred ,conseq ,alt)
       (let-values
	   ([(cl ccg) (unc live conf-graph conseq)]
	    [(al acg) (unc live conf-graph alt)])
	 (unc (union cl al) (union-conflict-graphs ccg acg) pred))]
      [(set! ,var (,binop ,t1 ,t2))
       (let-values ([(nlive ngraph) 
		     (kill-and-record-conflicts var live conf-graph #f)])
	 (values (add-live t1 (add-live t2 nlive))
		ngraph))]
      [(set! ,var ,t)
       (guard (not (list? t)))
       (let-values ([(nlive ngraph) 
		     (kill-and-record-conflicts var live conf-graph #f)])
	 (values (add-live t nlive)
		ngraph))]
      [(,relop ,v1 ,v2) (guard (relop? relop))
       (values (add-live v2
			 (add-live v1 live))
	       conf-graph)]
      [(,triv ,loc ...)
       (guard (or (uvar? x) (register? triv)))
       (let* ([nlive (union x live)])		   
	 (values nlive conf-graph))]
      [,p (values live conf-graph)])))

(define uncover-register-conflict
  (lambda (x)
    (define (uncover uvars x)
      (letrec
	  ([live '()]
	   [conf-graph (make-empty-graph uvars)]
	   )
	(unc live conf-graph x)))    
    (define (expose x)
      (match x
	[(letrec ([,label (lambda () ,[body*])] ...) ,[body])
	`(letrec ([,label (lambda () ,body*)] ...) ,body)]
	[(locals ,uvars ,tail)
	 (let-values ([(live cgraph) (uncover uvars tail)])
	   `(locals ,uvars
		    (register-conflict ,cgraph ,tail)))]
	[,p p]))
    (expose x)))



(define (calc-assign-registers vars conflict-graph)
  (define available-regs '(rbx rcx rdx rsi rdi r8 r9 r10 r11 r12 r13 r14)) ; 假设这些可用
  (define reg? register?)
  ;; 安全获取冲突列表
  (define (get-conflicts var graph)
    (cond ((assq var graph) => cdr)
          (else '())))
  (define (degree var graph)
    (length (get-conflicts var graph)))
  (define (low-degree? var graph)
    (<= (degree var graph) (length available-regs)))
  ;; 选变量：优先低度，无则任意（第一个）
  (define (pick-variable vars graph)
    (or (find (lambda (v) (low-degree? v graph)) vars)
        (car vars)))			; 假设 vars 非空
  ;; 移除变量：删除其 entry，并从其他变量的冲突列表中移除它
  (define (remove-var var graph)
    (filter (lambda (entry) (not (eq? (car entry) var)))
            (map (lambda (entry)
                   (cons (car entry) (remq var (cdr entry))))
                 graph)))
  ;; 选寄存器：避免自身冲突寄存器 + 冲突变量（邻居）已分配的寄存器
  (define (select-reg var graph assignments)
    (let* ((my-conflicts (get-conflicts var graph)) ; 自身冲突列表（含寄存器和变量）
           ;; 找到所有冲突变量的已分配寄存器
           (neighbor-assigned-regs
            (map cdr
                 (filter (lambda (assign)
                           (memq (car assign) my-conflicts)) ; car 是变量，是否在我的冲突列表中
                         assignments))))
      (let ((forbidden (append (filter reg? my-conflicts) ; 只取寄存器冲突
                               neighbor-assigned-regs)))
        (find (lambda (reg) (not (memq reg forbidden)))
              available-regs))))
  ;; 主递归
  (if (null? vars)
      '()
      (let* ((pick (pick-variable vars conflict-graph))
             (new-graph (remove-var pick conflict-graph))
             (new-vars (remq pick vars))
             (sub-assignments (calc-assign-registers new-vars new-graph))
             (reg (select-reg pick conflict-graph sub-assignments)))
        (if reg
            (cons (cons pick reg) sub-assignments)
            sub-assignments))))  ; 失败返回部分赋值（后续可 error）



(define alist-to-plist
  (lambda (l)
    (match l
      [() '()]
      [((,a . ,d) . ,[rst]) `((,a ,d) . ,rst)])))


(define assign-registers
  (lambda (x)
    (match x
      [(letrec ([,label (lambda () ,[body*])] ...) ,[body])
       `(letrec ([,label (lambda () ,body*)] ...) ,body)]
      [(locals ,uvars
	       (register-conflict ,conflict-graph ,tail))
       (let ([assign-res (alist-to-plist (calc-assign-registers uvars conflict-graph))])
	 `(locate ,assign-res ,tail))])))


(define discard-call-live
  (lambda (x)
    (define Tail
      (lambda (x)
	(match x
	  [(if ,pred ,[t1] ,[t2])
	  `(if ,pred ,t1 ,t2)]
	  [(begin ,e ... ,[tail])
	  `(begin ,e ... ,tail)]
	  [(,triv ,loc ...) `(,triv)])))
    (match x
      [(letrec ([,label (lambda () ,[body*])] ...) ,[body])
       `(letrec ([,label (lambda () ,body*)] ...) ,body)]
      [(locate ,uvars ,[Tail -> tail])
       `(locate ,uvars ,tail)])))


#!eof

(load "a4.ss")

(let-values (((new-live new-graph)
              (kill-and-record-conflicts 'c.3 example-live example-graph #f)))
  (list new-live new-graph))
((rbp r15 b.2) ((a.1) (b.2) (c.3 rbp r15 c.3 b.2)))

(define case
  '(letrec
       ()
     (locals (a.0 b.1 c.2)
      (begin
	(set! a.0 r8)
	(set! b.1 fv0)
	(set! c.2 (+ a.0 2))
	(if (< c.2 0) (nop) (set! c.2 (+ c.2 b.1)))
	(set! rax (+ c.2 1))
	(r15 rax rbp)))))



(calc-assign-registers
 '(a.0 b.1 c.2)
 '((a.0 b.1 r15 rbp) (b.1 c.2 r15 rbp a.0) (c.2 r15 rbp b.1))
      )


'((a.0 . rbx) (b.1 . rcx) (c.2 . rbx))

(discard-call-live
 (assign-registers
  (uncover-register-conflict
   (verify-scheme case))))


(assign-registers

 '(letrec ()
    (locals
     (a.0 b.1 c.2)
     (register-conflict
      ((a.0 b.1 r15 rbp) (b.1 c.2 r15 rbp a.0) (c.2 r15 rbp b.1))
      (begin
	(set! a.0 r8)
	(set! b.1 fv0)
	(set! c.2 (+ a.0 2))
	(if (< c.2 0) (nop) (set! c.2 (+ c.2 b.1)))
	(set! rax (+ c.2 1))
	(r15 rax rbp))))))
