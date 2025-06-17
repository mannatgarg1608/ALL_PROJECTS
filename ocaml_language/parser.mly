%{
open Ast
exception SyntaxError of string
%}


%token <int> INT
%token <float> FLOAT
%token <float list> VECTOR_FLOAT
%token <int list> VECTOR_INT
%token <float list list> MATRIX_FLOAT
%token <int list list> MATRIX_INT
%token <string> ID
%token <bool> BOOL
%token <int> INT_MIN
%token <int> INT_MAX
%token <string> PRINT_OUT
%token <string> INPUT_FILE
%token INT_TYPE FLOAT_TYPE VECTOR_INT_TYPE VECTOR_FLOAT_TYPE MATRIX_INT_TYPE MATRIX_FLOAT_TYPE BOOL_TYPE
%token IF THEN ELSE ELSEIF FOR WHILE INPUT PRINT 
%token EQ NEQ LT GT LEQ GEQ
%token PLUS MINUS TIMES DIVIDE POW ASSIGN SEMICOLON COMMA SQRT REM
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token AND OR NOT 
%token ABS DOT MAG DIM TRANS DETERMINANT ANG MINOR
%token EOF

// operator precedence and assosciativity

%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE REM
%right POW
%left DOT
%left NOT 


(* Unary minus precedence *)
%nonassoc UMINUS


(* Start symbol and types for parsing *)
%start main
%type <Ast.program> main
%type <Ast.return_cmd> cmd
%type <Ast.return_cmd list> cmds
%type <Ast.return_expr> expr
%type <Ast.return_expr> literal
%type <Ast.return_expr> vector
%type <Ast.return_expr> matrix



%%

(* Main entry point for the parser *)
main:
  | cmds EOF { $1 }
;

(* Parse a list of commands *)
cmds:
  | cmd SEMICOLON cmds { $1 :: $3 }
  | cmd { [$1] }  
  | { [] }  /* Allow empty command list */
  ;

(* Parse individual commands *)
cmd:
  | INT_TYPE ID ASSIGN INPUT { Hashtbl.add var_table $2 TInt; InputAssign($2, TInt) }  (* Integer input assignment *)
  | FLOAT_TYPE ID ASSIGN INPUT { Hashtbl.add var_table $2 TFloat; InputAssign($2, TFloat) }  (* Float input assignment *)
  | VECTOR_INT_TYPE INT ID ASSIGN INPUT { Hashtbl.add var_table $3 (TVectorInt $2); InputAssign($3, TVectorInt $2) }  (* Integer vector input assignment *)
  | VECTOR_FLOAT_TYPE INT ID ASSIGN INPUT { Hashtbl.add var_table $3 (TVectorFloat $2); InputAssign($3, TVectorFloat $2) }  (* Float vector input assignment *)
  | MATRIX_INT_TYPE INT COMMA INT ID ASSIGN INPUT { Hashtbl.add var_table $5 (TMatrixInt ($2, $4)); InputAssign($5, TMatrixInt ($2, $4)) }  (* Integer matrix input assignment *)
  | MATRIX_FLOAT_TYPE INT COMMA INT ID ASSIGN INPUT { Hashtbl.add var_table $5 (TMatrixFloat ($2, $4)); InputAssign($5, TMatrixFloat ($2, $4)) }  (* Float matrix input assignment *)
  | BOOL_TYPE ID ASSIGN INPUT { Hashtbl.add var_table $2 TBool; InputAssign($2, TBool) }  (* Boolean input assignment *)

  | INT_TYPE ID ASSIGN INPUT_FILE { Hashtbl.add var_table $2 TInt; InputFileAssign($2, TInt, $4) }  (* Integer input file assignment *)
  | FLOAT_TYPE ID ASSIGN INPUT_FILE { Hashtbl.add var_table $2 TFloat; InputFileAssign($2, TFloat, $4) }  (* Float input file assignment *)
  | VECTOR_INT_TYPE INT ID ASSIGN INPUT_FILE { Hashtbl.add var_table $3 (TVectorInt $2); InputFileAssign($3, TVectorInt $2, $5) }  (* Integer vector input file assignment *)
  | VECTOR_FLOAT_TYPE INT ID ASSIGN INPUT_FILE { Hashtbl.add var_table $3 (TVectorFloat $2); InputFileAssign($3, TVectorFloat $2, $5) }  (* Float vector input file assignment *)
  | MATRIX_INT_TYPE INT COMMA INT ID ASSIGN INPUT_FILE { Hashtbl.add var_table $5 (TMatrixInt ($2, $4)); InputFileAssign($5, TMatrixInt ($2, $4), $7) }  (* Integer matrix input file assignment *)
  | MATRIX_FLOAT_TYPE INT COMMA INT ID ASSIGN INPUT_FILE { Hashtbl.add var_table $5 (TMatrixFloat ($2, $4)); InputFileAssign($5, TMatrixFloat ($2, $4), $7) }  (* Float matrix input file assignment *)
  | BOOL_TYPE ID ASSIGN INPUT_FILE { Hashtbl.add var_table $2 TBool; InputFileAssign($2, TBool, $4) }  (* Boolean input file assignment *)


  | INT_TYPE ID ASSIGN expr {
      if type_of var_table $4 = TInt then (
        Hashtbl.add var_table $2 TInt;
        Assign($2, $4)
      ) else raise (TypeError "Type mismatch: Expected int")
    }
  | FLOAT_TYPE ID ASSIGN expr {
      if type_of var_table $4 = TFloat then (
        Hashtbl.add var_table $2 TFloat;
        Assign($2, $4)
      ) else raise (TypeError "Type mismatch: Expected float")
    }
  | VECTOR_INT_TYPE INT ID ASSIGN expr {
      if type_of var_table $5 = TVectorInt($2) then (
        Hashtbl.add var_table $3 (TVectorInt $2);
        Assign($3, $5)
      ) else raise (TypeError "Type mismatch: Expected vector_int")
    }
  | VECTOR_FLOAT_TYPE INT ID ASSIGN expr {
      if type_of var_table $5 = TVectorFloat($2) then (
        Hashtbl.add var_table $3 (TVectorFloat $2);
        Assign($3, $5)
      ) else raise (TypeError "Type mismatch: Expected vector_float")
    }
  | MATRIX_INT_TYPE INT COMMA INT ID ASSIGN expr {
      if type_of var_table $7 = TMatrixInt($2, $4) then (
        Hashtbl.add var_table $5 (TMatrixInt ($2, $4));
        Assign($5, $7)
      ) else raise (TypeError "Type mismatch: Expected matrix_int")
    }
  | MATRIX_FLOAT_TYPE INT COMMA INT ID ASSIGN expr {
      if type_of var_table $7 = TMatrixFloat($2, $4) then (
        Hashtbl.add var_table $5 (TMatrixFloat ($2, $4));
        Assign($5, $7)
      ) else raise (TypeError "Type mismatch: Expected matrix_float")
    }
  | BOOL_TYPE ID ASSIGN expr {
      if type_of var_table $4 = TBool then (
        Hashtbl.add var_table $2 TBool;
        Assign($2, $4)
      ) else raise (TypeError "Type mismatch: Expected bool")
    }
  | ID LPAREN INT SEMICOLON INT RPAREN ASSIGN expr {
      let lhs_type = type_of var_table (MatrixRef($1, LitInt($3), LitInt($5))) in
      let rhs_type = type_of var_table $8 in
      if lhs_type = rhs_type then MatrixAssign($1, LitInt($3), LitInt($5), $8)
      else raise (TypeError "Type mismatch in matrix assignment")
    }
  | ID LPAREN ID SEMICOLON ID RPAREN ASSIGN expr {
      let lhs_type = type_of var_table (MatrixRef($1, Var($3), Var($5))) in
      let rhs_type = type_of var_table $8 in
      if lhs_type = rhs_type then MatrixAssign($1, Var($3), Var($5), $8)
      else raise (TypeError "Type mismatch in matrix assignment")
    }
  | ID LPAREN INT SEMICOLON ID RPAREN ASSIGN expr {
      let lhs_type = type_of var_table (MatrixRef($1, LitInt($3), Var($5))) in
      let rhs_type = type_of var_table $8 in
      if lhs_type = rhs_type then MatrixAssign($1, LitInt($3), Var($5), $8)
      else raise (TypeError "Type mismatch in matrix assignment")
    }
  | ID LPAREN ID SEMICOLON INT RPAREN ASSIGN expr {
      let lhs_type = type_of var_table (MatrixRef($1, Var($3), LitInt($5))) in
      let rhs_type = type_of var_table $8 in
      if lhs_type = rhs_type then MatrixAssign($1, Var($3), LitInt($5), $8)
      else raise (TypeError "Type mismatch in matrix assignment")
    }
  | ID LPAREN INT RPAREN ASSIGN expr {
      let lhs_type = type_of var_table (VectorRef($1, LitInt($3))) in
      let rhs_type = type_of var_table $6 in
      if lhs_type = rhs_type then VectorAssign($1, LitInt($3), $6)
      else raise (TypeError "Type mismatch in vector assignment")
    }
  | ID LPAREN ID RPAREN ASSIGN expr {
      let lhs_type = type_of var_table (VectorRef($1, Var($3))) in
      let rhs_type = type_of var_table $6 in
      if lhs_type = rhs_type then VectorAssign($1, Var($3), $6)
      else raise (TypeError "Type mismatch in vector assignment")
    }


  | INT_TYPE ID { Hashtbl.add var_table $2 TInt; Declare($2) }
  | FLOAT_TYPE ID { Hashtbl.add var_table $2 TFloat; Declare($2) }
  | VECTOR_INT_TYPE INT ID { Hashtbl.add var_table $3 (TVectorInt $2); Declare($3) }
  | VECTOR_FLOAT_TYPE INT ID { Hashtbl.add var_table $3 (TVectorFloat $2); Declare($3) }
  | MATRIX_INT_TYPE INT COMMA INT ID { Hashtbl.add var_table $5 (TMatrixInt ($2, $4)); Declare($5) }
  | MATRIX_FLOAT_TYPE INT COMMA INT ID { Hashtbl.add var_table $5 (TMatrixFloat ($2, $4)); Declare($5) }
  | BOOL_TYPE ID { Hashtbl.add var_table $2 TBool; Declare($2) }    


  | ID ASSIGN expr  { 
    let lhs_type = if Hashtbl.mem var_table $1 then Hashtbl.find var_table $1 else raise (TypeError "variable does not exist") in
    let rhs_type = type_of var_table $3 in 
    if lhs_type = rhs_type then  Assign($1, $3)  else  raise (TypeError "Type mismatch in vector assignment")
    }          // need to chech this confirm it


  | if_stmt { $1 }
  | WHILE LPAREN expr RPAREN LBRACE cmds RBRACE { While($3, $6) }
  | FOR LPAREN  ID ASSIGN INT SEMICOLON expr SEMICOLON ID ASSIGN expr RPAREN LBRACE cmds RBRACE 
    { For($3, $5, $7, $9 , $11, $14) }
  | INPUT                    { Input }
  | PRINT_OUT                { Printout($1) }
  | PRINT                    { Print }
  | LBRACE cmds RBRACE       { Seq($2) }

;

if_stmt:
  | IF LPAREN expr RPAREN THEN LBRACE cmds RBRACE { If($3, $7, []) }
  | IF LPAREN expr RPAREN THEN LBRACE cmds RBRACE ELSE LBRACE cmds RBRACE { IfElse($3, $7, $11) }
  | IF LPAREN expr RPAREN THEN LBRACE cmds RBRACE elseif_clause { If($3, $7, $9) }
;

elseif_clause:
  | ELSEIF LPAREN expr RPAREN THEN LBRACE cmds RBRACE { [($3, $7)] }
  | ELSEIF LPAREN expr RPAREN THEN LBRACE cmds RBRACE elseif_clause { ($3, $7) :: $9 }
  | ELSEIF LPAREN expr RPAREN THEN LBRACE cmds RBRACE ELSE LBRACE cmds RBRACE { [($3, $7); (LitBool(true), $11)] }
;


(* Parse expressions *)
expr:
  | ang_expr                    { $1 } (*finding angle between vectors *)
  | minor                       { $1 } (*finding minor of  a given matrxi*)
  | SQRT LPAREN expr RPAREN     { check_unop Sqrt $3 } (*finding sqrt*)
  | ABS LPAREN expr RPAREN      { check_unop Abs $3 }  (*finding the absolute value*)
  | MAG LPAREN expr RPAREN      { check_unop Mag $3 }  (*finding the magnitude of a vector*)
  | DIM LPAREN expr RPAREN      { check_unop Dim $3 } (*finding the dimension of a vector*)
  | TRANS LPAREN expr RPAREN    { check_unop Trans $3 } (*finding the transpose of a matrix*)
  // | INVERSE LPAREN expr RPAREN  { check_unop Inverse $3} (*finding the inverse of a matrix*)
  | DETERMINANT LPAREN expr RPAREN { check_unop Determinant $3 } (*finding the determinant of a matrix*)


(*accessing a vector and along with checking if it is mentioned correctly *)
  | ID LPAREN INT SEMICOLON INT RPAREN { 
    if type_of var_table (MatrixRef($1, LitInt($3), LitInt($5))) = TInt ||
         type_of var_table (MatrixRef($1, LitInt($3), LitInt($5))) = TFloat then
        MatrixRef($1, LitInt($3), LitInt($5))
      else raise (TypeError "Type mismatch: Expected a matrix") }
  | ID LPAREN ID SEMICOLON ID RPAREN { 
    if type_of var_table (MatrixRef($1, Var($3), Var($5))) = TInt ||
         type_of var_table (MatrixRef($1, Var($3), Var($5))) = TFloat then
        MatrixRef($1, Var($3), Var($5))
    else raise (TypeError "Type mismatch: Expected a matrix") }
  | ID LPAREN INT SEMICOLON ID RPAREN { 
    if type_of var_table (MatrixRef($1, LitInt($3), Var($5))) = TInt ||
         type_of var_table (MatrixRef($1, LitInt($3), Var($5))) = TFloat then
        MatrixRef($1, LitInt($3), Var($5))
    else raise (TypeError "Type mismatch: Expected a matrix") }
   | ID LPAREN ID SEMICOLON INT RPAREN {
      if type_of var_table (MatrixRef($1, Var($3), LitInt($5))) = TInt ||
         type_of var_table (MatrixRef($1, Var($3), LitInt($5))) = TFloat then
        MatrixRef($1, Var($3), LitInt($5))
      else raise (TypeError "Type mismatch: Expected a matrix")
    }
  | ID LPAREN INT RPAREN {
      if type_of var_table (VectorRef($1, LitInt($3))) = TInt ||
         type_of var_table (VectorRef($1, LitInt($3))) = TFloat then
        VectorRef($1, LitInt($3))
      else raise (TypeError "Type mismatch: Expected a vector")
    }
  | ID LPAREN ID RPAREN {
      if type_of var_table (VectorRef($1, Var($3))) = TInt ||
         type_of var_table (VectorRef($1, Var($3))) = TFloat then
        VectorRef($1, Var($3))
      else raise (TypeError "Type mismatch: Expected a vector")
    }

(*basic types*)
  | vector                      { $1 }
  | matrix                      { $1 }
  | literal                     { $1 }
  | ID                          { Var($1) }

(*basic operations*)
  | LPAREN expr RPAREN          { $2 }
  | expr PLUS expr              { check_binop Add $1 $3 }
  | expr MINUS expr             { check_binop Sub $1 $3 }
  | expr TIMES expr             { check_binop Mul $1 $3 }
  | expr DIVIDE expr            { check_binop Div $1 $3 }
  | expr REM expr               { check_binop Rem $1 $3 }
  | expr POW expr               { check_binop Pow $1 $3}
  | expr DOT expr               { check_binop Dot $1 $3 }
  | MINUS expr %prec UMINUS     { check_unop Neg $2 }


(*comparison operations*)
  | NOT expr                    { check_unop Not $2 }
  | expr EQ expr                { check_binop Eq $1 $3 }
  | expr NEQ expr               { check_binop Neq $1 $3 }
  | expr LT expr                { check_binop Lt $1 $3 }
  | expr GT expr                { check_binop Gt $1 $3 }
  | expr LEQ expr               { check_binop Leq $1 $3 }
  | expr GEQ expr               { check_binop Geq $1 $3 }
  | expr AND expr               { check_binop And $1 $3 }
  | expr OR expr                { check_binop Or $1 $3 }
;

(* Parse angle between vectors *)
ang_expr:
  | ANG LPAREN vector COMMA vector RPAREN { check_binop Ang $3 $5 }
;
  
  (* Parse minor of a matrix  and also checking if it was declared correctly*)
minor:
  | MINOR LPAREN ID COMMA INT COMMA INT RPAREN {
      match type_of var_table (Minor($3, LitInt($5), LitInt($7))) with
      | TMatrixInt(_, _) | TMatrixFloat(_, _) -> Minor($3, LitInt($5), LitInt($7))
      | _ -> raise (TypeError "Type mismatch: Expected a matrix for minor")
    }
  | MINOR LPAREN ID COMMA ID COMMA ID RPAREN {
      match type_of var_table (Minor($3, Var($5), Var($7))) with
      | TMatrixInt(_, _) | TMatrixFloat(_, _) -> Minor($3, Var($5), Var($7))
      | _ -> raise (TypeError "Type mismatch: Expected a matrix for minor")
    }
  | MINOR LPAREN ID COMMA INT COMMA ID RPAREN {
      match type_of var_table (Minor($3, LitInt($5), Var($7))) with
      | TMatrixInt(_, _) | TMatrixFloat(_, _) -> Minor($3, LitInt($5), Var($7))
      | _ -> raise (TypeError "Type mismatch: Expected a matrix for minor")
    }
  | MINOR LPAREN ID COMMA ID COMMA INT RPAREN {
      match type_of var_table (Minor($3, Var($5), LitInt($7))) with
      | TMatrixInt(_, _) | TMatrixFloat(_, _) -> Minor($3, Var($5), LitInt($7))
      | _ -> raise (TypeError "Type mismatch: Expected a matrix for minor")
    }
;
  
  (*literals *)
literal:
  | INT       { LitInt($1) }
  | FLOAT     { LitFloat($1) }
  | BOOL      { LitBool($1) }
  | INT_MAX   { LitInt(Int.max_int) }
  | INT_MIN   { LitInt(Int.min_int) }
;
  
  (* Parse a vector and checking if its dimensions were declared correctly *)
vector:
  | INT VECTOR_INT { 
      let dim, elems = $1, $2 in
      if List.length elems != dim then
        raise (SyntaxError "Vector dimension mismatch")
      else
        VectorIntLit(dim,elems) 
    }
| INT VECTOR_FLOAT { 
      let dim, elems = $1, $2 in
      if List.length elems != dim then
        raise (SyntaxError "Vector dimension mismatch")
      else
        VectorFloatLit(dim,elems) 
    }
;

  (* Parse a matrix and checking if its dimensions were declared correctly *)
matrix:
  | INT COMMA INT MATRIX_INT  {            
      let rows, cols, m = $1, $3, $4 in
      if List.exists (fun r -> List.length r != cols) m then
        raise (SyntaxError "Matrix column mismatch")
      else if List.length m != rows then
        raise (SyntaxError "Matrix row mismatch")
      else
        MatrixIntLit(rows,cols,m)
    }
    // check for list.exists what it is 
  | INT COMMA INT MATRIX_FLOAT  {            
        let rows, cols, m = $1, $3, $4 in
        if List.exists (fun r -> List.length r != cols) m then 
          raise (SyntaxError "Matrix column mismatch")
        else if List.length m != rows then
          raise (SyntaxError "Matrix row mismatch")
        else
          MatrixFloatLit(rows,cols,m)
      }

;