(compiler-passes '(
  verify-scheme
  remove-complex-opera*
  flatten-set!
  impose-calling-conventions
  uncover-frame-conflict
  pre-assign-frame
  assign-new-frame
  (iterate
    finalize-frame-locations ;;Note. This comes first now since we need to finalize frame locs from
                             ;; previous assign-new-frame pass.
    select-instructions
    uncover-register-conflict
    assign-registers
    (break when everybody-home?)
    assign-frame)
  discard-call-live
  finalize-locations
  expose-frame-var
  expose-basic-blocks
  flatten-program
  generate-x86-64
))