{
open Token
open Parser
exception SyntaxError of string
}

(* Regular expressions *)
let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z']
let id = ['a'-'z' 'A'-'Z' '0'-'9' '_' ''']*
let int = '-'? digit+
(* Defining float literals with optional scientific notation *)
let float = ('-'? digit+ '.' digit+) |('-'? digit '.'? digit+ ('e' | 'E') ('-' | '+')? digit+)| ('-'? digit ('e' | 'E') ('-' | '+')? digit+)
let whitespace = [' ' '\t' '\n' '\r' ]+
let comment_start = "/*"
let comment_end = "*/"
let vector_int = '[' (int) (',' (int))* ']'
let vector_float = '[' (float) (',' (float))* ']'
let matrix_int = '[' '[' (int) (',' (int))* ']' (',' '[' (int) (',' (int))* ']')* ']'
let matrix_float = '[' (vector_float) (',' (vector_float))* ']'
let filename =  [^ ' ' '\t' '\n' ';' '(' ')' '{' '}' '[' ']']+


(* Lexer rules *)
rule token = parse
  | whitespace { token lexbuf } (* Skip whitespace *)
  | comment_start { comment lexbuf } (* Handle comments *)
  
  (* Keywords *)
  | "if" { IF }
  | "then" { THEN }
  | "else if" { ELSEIF }
  | "else" { ELSE }
  | "for" { FOR }
  | "while" { WHILE }
  | "Input" '('')' { INPUT }
  | "Print" '('')' { PRINT }
  | "INT_MAX" { INT_MAX Int.max_int} (* Maximum integer value *)
  | "INT_MIN" { INT_MIN Int.min_int} (* Minimum integer value *)
  | "Input" whitespace* '(' whitespace* (filename as f) whitespace* ')' { INPUT_FILE f }
  | "Print" whitespace* '(' whitespace* (id as name ) whitespace* ')' { PRINT_OUT name }

  (* Boolean literals *)
  | "True" { BOOL true }
  | "False" { BOOL false }

  (* Vector/Matrix operations *)
  | "." { DOT }
  | "/_" { ANG }
  | "mag" { MAG }
  | "dim" { DIM }
  | "trans" { TRANS }
  | "determinant" { DETERMINANT }
  (* | "inverse" { INVERSE } *)
  | "minor" { MINOR }

 (* identifying the type as names *)
  | "int" { INT_TYPE }
  | "float" { FLOAT_TYPE }
  | "vector_int" { VECTOR_INT_TYPE }
  | "vector_float" { VECTOR_FLOAT_TYPE }
  | "matrix_int" { MATRIX_INT_TYPE }
  | "matrix_float" { MATRIX_FLOAT_TYPE }
  | "bool" { BOOL_TYPE }

  (* Logical operators *)
  | "&&" { AND }
  | "||" { OR }
  | "~" { NOT }

  (* Arithmetic operators *)
  | '+' { PLUS }
  | '-' { MINUS }
  | '*' { TIMES }
  | '/' { DIVIDE }
  | ":=" { ASSIGN }
  | ';' { SEMICOLON }
  | "," { COMMA }
  (* Comparison operators *)
  | "==" { EQ }
  | "=!=" { NEQ }
  | '>' { GT }
  | '<' { LT }
  | ">=" { GEQ }
  | "<=" { LEQ }

  (* Delimiters *)

  | '(' { LPAREN }
  | ')' { RPAREN }
  | '{' { LBRACE }
  | '}' { RBRACE }
  | '[' { LBRACKET }
  | ']' { RBRACKET }

  (* Functions *)
  | "abs" { ABS }
  | "sqrt" { SQRT }
  | "^" { POW }
  | "rem" {REM}



  (* Literals: Integers, Floats, Vectors, Matrices *)
  | int as i { INT (int_of_string i) }
  | float as f { FLOAT (float_of_string f) }
  | vector_int as vi { VECTOR_INT (parse_vector_int vi) }
  | vector_float as vf { VECTOR_FLOAT (parse_vector_float vf) }
  | matrix_int as mi { MATRIX_INT (parse_matrix_int mi) }
  | matrix_float as mf { MATRIX_FLOAT (parse_matrix_float mf) }

  (* Identifiers (variables) *)
  | id as name { ID name }

  (* End of file *)
  | eof { EOF }
  | _ { raise (SyntaxError ("Unrecognized token: " ^ (Lexing.lexeme lexbuf))) }
(* Handle comments by skipping everything until the comment ends *)
and comment = parse
    | comment_end   { token lexbuf } (* End of comment, return to normal lexing *)
    | _             { comment lexbuf } (* Continue skipping characters inside the comment block *)

