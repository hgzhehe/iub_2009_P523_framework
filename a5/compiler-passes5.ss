(compiler-passes '(
  verify-scheme
  uncover-frame-conflict
  introduce-allocation-forms
  (iterate
    select-instructions
    uncover-register-conflict
    assign-registers
    (break when everybody-home?)
    assign-frame
    finalize-frame-locations)
  discard-call-live
  finalize-locations
  expose-frame-var
  expose-basic-blocks
  flatten-program
  generate-x86-64
))