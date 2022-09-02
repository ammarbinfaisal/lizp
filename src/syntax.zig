pub const ExprType = enum {
    enil,
    eint,
    echar,
    ebool
    // econs,
    // esymbol
};

pub const Expr = union(ExprType) {
    enil: void,
    eint: i64,
    echar: u8,
    ebool: bool
    // econs: *Cons,
    // esymbol: []u8,
};

pub const Cons = struct { car: *Expr, cdr: *Expr };
