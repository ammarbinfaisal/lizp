# lizp

a lisp compiler in zig

## Features

-   can compile epilogue and prologue of a function only
-   move_reg_imm32 results in segfault :P

## TODO

-   unary primitives (add1, sub1, etc)
-   binary primitives (\*, -, /, %, =, etc)
-   local variables
-   conditional expressions
-   heap allocations
-   procedure calls
-   closures
-   tail call optimization

## References

-   [An Incremental Approach to Compiler Construction](https://github.com/namin/inc/blob/master/docs/paper.pdf?raw=true)
-   [Max Bernstein's series](https://bernsteinbear.com/blog/compiling-a-lisp-0/)
