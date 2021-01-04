# iub_2009_P523_framework
This is my rearrangement of IUB 2009 P523 uploaded files opensourced on github in different repos.
All copyright belongs to R. Kent/A. Keep and IUB faulty.I'll delete this repo immediately if there was any copyright issue.
Compiler passes and wrappers copied from https://github.com/esaliya/SchemeStack
Helpers copied from https://github.com/tiancaiamao/yscheme

To use this framework.under every a{i} folder,implement a{i}.ss containing all the functions needed by compiler_passes{i}.ss.Then load the a{i}_main.ss and (test-all) or (test-all-invalid).
Feel free to modify compiler-passes.It's just a helper anyway.
More useful functions and documentation can be found in driver.ss

I only partially tested this framework I collected under ChezScheme 9.5

For every assignment done.You will get a working little scheme compiler that compiles a tiny language to assembly code.
Finally,the tiny language will be a subset of scheme in assignment 15.


More related resources are
https://github.com/akeep/nanopass-framework
A Nanopass Framework for Compiler Education
A nanopass framework for commercial compiler development
https://github.com/yinwang0/yscheme
https://github.com/keyz/p423-compiler
