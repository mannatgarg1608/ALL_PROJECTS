open Ast
open Parser
open Lexer
open Interpreter (* Add this line to import your interpreter module *)

(* Function to parse, interpret, and print results *)
let print_value = function
| LitInt i -> Printf.printf "%d\n" i
| LitFloat f -> Printf.printf "%f\n" f
| LitBool b -> Printf.printf "%b\n" b
| VectorIntLit (dim, elements) -> Printf.printf "VECTOR_INT([%s])\n" (String.concat "; " (List.map string_of_int elements))
| VectorFloatLit (dim, elements) -> Printf.printf "VECTOR_FLOAT([%s])\n" (String.concat "; " (List.map string_of_float elements))
| MatrixIntLit (rows, cols, matrix) -> Printf.printf "MATRIX_INT(%s)\n"
(String.concat "; "
(List.map (fun row ->
"[" ^ String.concat "; " (List.map string_of_int row) ^ "]")
matrix))
| MatrixFloatLit (rows, cols, matrix) -> Printf.printf "MATRIX_FLOAT(%s)\n"
(String.concat "; "
(List.map (fun row ->
"[" ^ String.concat "; " (List.map string_of_float row) ^ "]")
matrix))
| _ -> failwith "type not matched"

let parse_and_interpret str =
let lexbuf = Lexing.from_string str in
try
let parsed_program = Parser.main Lexer.token lexbuf in
Printf.printf "Input: %s\n Output:\n" str;

(* Create a new environment and interpret the program *)
let env = Hashtbl.create 100 in
let final_env = eval_cmds env parsed_program in
final_env
with
| Lexer.SyntaxError msg ->
Printf.printf  "Lexical error: %s\n%!" msg;
Hashtbl.create 0 (* Return empty environment on error *)
| Parser.Error ->
Printf.printf  "Syntax error at position %d\n%!" (Lexing.lexeme_start lexbuf);
Hashtbl.create 0 (* Return empty environment on error *)
| Failure msg ->
Printf.printf  "Runtime error: %s\n%!" msg;
Hashtbl.create 0 (* Return empty environment on error *)

let main () =
  (* Test cases *)
let test_cases = [
  (* Your test cases here *)
  (*basic matrix operations*)
  "matrix_int 2,2 x := 2,2 [[1,2],[3,4]]; 
matrix_int 2,2 y := 2,2 [[5,6],[7,8]]; 
matrix_int 2,2 add_matrices := x + y;
Print( x );
Print( y );
Print( add_matrices )";
    (* checking for transpose of a matrix*)
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; 
matrix_int 2,2 transpose_matrix := trans(A);
Print( transpose_matrix );";

(*determinant of matrix*)
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; 
int determinant_of_matrix := determinant(A);
Print( determinant_of_matrix )";
    
(*matrix operations and for loop flow*)
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; if (determinant(A) =!= 0) then { 
    matrix_int 2,2 cofactor_matrix := 2,2 [[0,0],[0,0]]; 
    int i; 
    for (i := 0; i < 2; i := i + 1) { 
        int j; 
        for (j := 0; j < 2; j := j + 1) { 
            matrix_int 1,1 minor1 := minor(A, i, j); 
            Print( minor1 );
            cofactor_matrix(i;j) := (-1)^(i+j) * determinant(minor1); 
        }; 
    }; 
    matrix_int 2,2 adjoint_of_matrix := trans(cofactor_matrix); 
} else { 
    Print ( A ); 
};";    

(*matrix multiplication*)
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; 
matrix_int 2,2 B := 2,2 [[5,6],[7,8]]; 
matrix_int 2,2 multiply_matrices := A * B;
Print( multiply_matrices );";
    

(*matrix ans vector multiplication*)
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; 
vector_int 2 x := 2 [5,6]; 
vector_int 2 multiply_vector_matrix := A * x;
Print( multiply_vector_matrix );";
    
(* some nested operations*)
"int x := 2+ 3*4;
 Print( x );";

"int z := 4+5^3;
 Print( z )";
    
"matrix_float 2,2 A := 2,2 [[1.0,2.0],[3.0,4.0]]; float trace := A(0;0) + A(1;1); Print( trace );float determi := determinant(A);Print( determi ); float D := trace * trace - 4.0 * determi; if (D >= 0.0) then { float eigenvalue1 := trace + sqrt(D) ; float eigenvalue2 := trace - sqrt(D) ; } else { Print ( eigenvalue1 ) ; };";
    
"vector_int 3 vector_sum := 3 [1,2,3]; int sum :=0 ;int i := 0;for (i := 0; i < 3; i := i + 1) { sum := vector_sum(i)+ sum;Print( sum ); };";
    
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; int sum_of_squares := 0; int i := 0;for (i := 0; i < 2; i := i + 1) {int j := 0; for (j := 0; j < 2; j := j + 1) { sum_of_squares := sum_of_squares + A(i;j)* A(i;j); Print( sum_of_squares )}; }; float magnitude_of_matrix := sqrt(sum_of_squares);";
    
(*some declarations*)

"int x := 5;";
"float y := 3.14;";
"vector_int 3 v := 3 [1,2,3];";
"matrix_int 2,2 m := 2,2 [[1,2],[3,4]];";
"matrix_int 2,2 m := 2,2 [[1,2],[3,4]]; m(1;1) := 10;";
"matrix_int 2,2 m := 2,2 [[1,2],[3,4]]; int det := determinant(m);";
"matrix_int 2,2 m := 2,2 [[1,2],[3,4]]; matrix_int 2,2 t := trans(m);";
"int i;for (i := 0; i < 10; i := i + 1) { int x := i; };";

"matrix_int 3,3 A := 3,3 [[1,2,3],[4,5,6],[7,8,9]]; vector_int 3 v := 3 [1,2,3]; vector_int 3 result := 3 [0,0,0]; int i; for (i := 0; i < 3; i := i + 1) { int j; for (j := 0; j < 3; j := j + 1) { result(i) := result(i) + A(i;j) * v(j);Print( result(i) ) }; };";

(* Matrix multiplication and determinant *)
"matrix_int 2,2 A := 2,2 [[1,2],[3,4]]; matrix_int 2,2 B := 2,2 [[5,6],[7,8]]; matrix_int 2,2 C := A * B; int det := determinant(C);";


(* Complex arithmetic with vectors *)
"vector_float 3 v1 := 3 [1.0,2.0,3.0]; vector_float 3 v2 := 3 [4.0,5.0,6.0]; float dot_product := v1 . v2;";

"int x := 5 rem 3 ;
Print( x )";
(* Nested conditionals with loops *)
"matrix_float 3,3 A := 3,3 [[1.0,2.0,3.0],[4.0,5.0,6.0],[7.0,8.0,9.0]]; int i; int j; for (i := 0; i < 3; i := i + 1) { for (j := 0; j < 3; j := j + 1) { if (A(i;j) == 0.0) then { A(i;j) := A(i;j) / 2.0; } else { A(i;j) := A(i;j) * 2.0; }; }; };";


(* Test boolean operations *)
"bool a := True;
bool b := False;
bool c := a && b;  /* Logical AND */
bool d := a || b;  /* Logical OR */
bool e := ~a;      /* Logical NOT */
bool f := (a && b) || (~b);
bool g := a && (b || ~b);

Print( a );  /* Should print True */
Print( b );  /* Should print False */
Print( c );  /* Should print False */
Print( d );  /* Should print True */
Print( e );  /* Should print False */
Print( f );  /* Should print True */
Print( g );  /* Should print True */ ";

(*runtime errors*)
(* Division by zero *)
"int x := 10;
int y := 0;
int z := x / y;";

(* Matrix multiplication with incompatible dimensions *)
"matrix_int 2,3 A := 2,3 [[1,2,3],[4,5,6]];
matrix_int 2,2 B := 2,2 [[1,2],[3,4]];
matrix_int 2,2 C := A * B;";

(*Vector access out of bounds *)
"vector_int 3 v := 3 [1,2,3];
int x := v(3);
Print( x )";

(*Determinant of non-square matrix *)
"matrix_float 2,3 M := 2,3 [[1.0,2.0,3.0],[4.0,5.0,6.0]];
float det := determinant(M);
Print( M )";

(*Angle between zero vectors *)
"vector_float 2 zero_vector := 2 [0.0,0.0];
float angle := /_(2 [0.0,0.0],2 [0.0,0.0]);";


(* Calculate matrix inverse using adjoint method *)
"matrix_float 2,2 A := 2,2 [[4.0,7.0],[2.0,6.0]];
Print( A );

/* Calculate determinant */
float det := determinant(A);
Print( det );  /* Should print 10.0 */

/* Check if matrix is invertible */
if (det == 0.0) then {
  Print( A );
  Print( det );
} else {
  /* Create adjoint matrix */
  matrix_float 2,2 adj := 2,2 [[0.0,0.0],[0.0,0.0]];
  
  /* For 2x2 matrix, adjoint is simple */
  adj(0;0) := A(1;1);
  adj(0;1) := -1.0 * A(0;1);
  adj(1;0) := -1.0 * A(1;0);
  adj(1;1) := A(0;0);
  
  Print( adj );  /* Should print [[6.0, -7.0], [-2.0, 4.0]] */
  
  /* Calculate inverse as adjoint/determinant */
  matrix_float 2,2 A_inv := 2,2 [[0.0,0.0],[0.0,0.0]];
  int i;
  for (i := 0; i < 2; i := i + 1) {
      int j;
      for (j := 0; j < 2; j := j + 1) {
          A_inv(i;j) := adj(i;j) / det;
      };
  };
  
  Print( A_inv );  /* Should print [[0.6, -0.7], [-0.2, 0.4]] */
  
  /* Verify: A * A_inv should be identity matrix */
  matrix_float 2,2 I := A * A_inv;
  Print( I );  /* Should be close to [[1.0, 0.0], [0.0, 1.0]] */
};";


(*Determinant of non-square matrix *)
"matrix_float 2,3 M := 2,3 [[1.0,2.0,3.0],[4.0,5.0,6.0]];
float det := determinant(M);
Print( M );";


"matrix_float 2,3 M := 2,3 [[1.0,2.0,3.0],[4.0,5.0,6.0]];
int det := determinant(M);
Print( M );";


"vector_float 2 zero_vector := 2 [0.0,0.0];
float angle := /_([0.0,0.0],[0.0,0.0]);";

(* Calculate angle between two vectors *)
"vector_float 3 v1 := 3 [1.0,0.0,0.0];  /* Unit vector along x-axis */
vector_float 3 v2 := 3 [0.0,1.0,0.0];  /* Unit vector along y-axis */

/* Calculate dot product */
float dot_product := v1.v2;
Print( dot_product );  /* Should print 0.0 */

/* Calculate magnitudes */
float mag_v1 := mag(v1);
float mag_v2 := mag(v2);
Print( mag_v1 );  /* Should print 1.0 */
Print( mag_v2 );  /* Should print 1.0 */

/* Calculate angle using built-in operator */
float angle1 := /_(3 [1.0,0.0,0.0],3 [0.0,1.0,0.0]);
Print( angle1 );  /* Should print 1.5708... (π/2 radians or 90 degrees) */

/* Calculate angle manually using dot product formula */
float cos_angle := dot_product / (mag_v1 * mag_v2);
float angle2 := 0.0;

/* Handle potential numerical issues */
if (cos_angle > 1.0) then {
    angle2 := 0.0;
} else if (cos_angle < -1.0) then {
    angle2 := 3.14159;  /* π radians or 180 degrees */
} else {
    /* We would need an acos function, but we can compare with the built-in result */
    angle2 := /_(3 [1.0,0.0,0.0],3 [0.0,1.0,0.0]);
};

Print( angle2 );  /* Should match angle1 */

/* Test with non-perpendicular vectors */
vector_float 2 u1 := 2 [1.0,1.0];
vector_float 2 u2 := 2 [0.0,1.0];
float angle3 := /_(2 [1.0,1.0],2 [0.0,1.0]);
Print( angle3 );  /* Should print 0.7854... (π/4 radians or 45 degrees) */";

"int n := Input();
Print( n );";

"float x := Input();
Print( x );";

"matrix_int 2,2 x := Input();
Print( x )";

"vector_float 3 v := Input();
Print( v );";


"int n := Input(input_check1.txt);
Print( n );";

"float x := Input(input_check2.txt);
Print( x );";

"vector_float 3 v := Input(input_check3.txt);
Print( v );";

"matrix_float 2,2 x := Input(input_check4.txt);
Print( x )";

  ] in

  (* Run interpreter on each test case *)
  List.iter (fun test ->
    Printf.printf "======= Running Test =======\n";
    (try
      let _ = parse_and_interpret test in
      ()
    with
    | Lexer.SyntaxError msg ->
        Printf.printf "Lexical error: %s\n%!" msg;
    | Parser.Error ->
        Printf.printf "Syntax error\n%!";
    | Failure msg ->
        Printf.printf "Runtime error: %s\n%!" msg;
    | e ->
        Printf.printf "Unexpected error: %s\n%!" (Printexc.to_string e));
    Printf.printf "==========================\n\n";
  ) test_cases

let () = main ()
