(language-wrapper
  (lambda (pass-name x)
    (case pass-name
      [(source verify-scheme)
       `(let ()
          (import (except scheme set!))
          (define int64-in-range?
            (lambda (x)
              (<= (- (expt 2 63)) x (- (expt 2 63) 1))))
          (define handle-overflow
            (lambda (x)
              (cond
                [(not (number? x)) x]
                [(int64-in-range? x) x]
                [(not (= x (logand 18446744073709551615 x)))
                 (handle-overflow (logand 18446744073709551615 x))]
                [(< x 0) (handle-overflow (+ x (expt 2 64)))]
                [else (handle-overflow (- x (expt 2 64)))])))
          (define-syntax set!
            (let ()
              (import scheme)
              (syntax-rules ()
                [(_ x expr) (set! x (handle-overflow expr))])))
          ,x
          rax)]
      [else x])))
