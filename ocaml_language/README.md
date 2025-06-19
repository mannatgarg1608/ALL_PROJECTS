# OCaml Matrix/Vector Language Interpreter

This project implements an interpreter for a custom programming language supporting advanced operations on integers, floats, vectors, and matrices. The language supports variable declarations, arithmetic, logical operations, control flow (if, for, while), and I/O (including file input).

## Project Structure

- [`ast.ml`](ast.ml): Abstract syntax tree and type definitions.
- [`function.ml`](function.ml): Core mathematical and utility functions for vectors and matrices.
- [`token.ml`](token.ml): Token definitions and parsing utilities.
- [`lexer.mll`](lexer.mll): OCamllex lexer for tokenizing the language.
- [`parser.mly`](parser.mly): Menhir parser for the language grammar.
- [`interpreter.ml`](interpreter.ml): Interpreter implementation for evaluating programs.
- [`main3.ml`](main3.ml): Entry point, test harness, and REPL logic.
- `input_check*.txt`: Example input files for testing file-based input.
- [`run.txt`](run.txt): Build instructions.

## Building

To build the interpreter, run the commands listed in [`run.txt`](run.txt):

```sh
ocamlc -c ast.ml
menhir --ocamlc "ocamlc -c" --explain --infer parser.mly
ocamllex lexer.mll
ocamlc -c token.ml
ocamlc -c parser.mli
ocamlc -c parser.ml
ocamlc -c lexer.ml
ocamlc -c function.ml
ocamlc -c interpreter.ml
ocamlc -c main3.ml
ocamlc -o my_interpreter token.cmo ast.cmo parser.cmo lexer.cmo function.cmo interpreter.cmo main3.cmo
```

Or simply:

```sh
sh run.txt
```

## Usage

After building, run the interpreter:

```sh
./my_interpreter
```

The interpreter will execute a series of test cases defined in [`main3.ml`](main3.ml). You can modify or add your own test cases there.

### Input Files

- [`input_check1.txt`](input_check1.txt): Integer input example.
- [`input_check2.txt`](input_check2.txt): Float input example.
- [`input_check3.txt`](input_check3.txt): Vector input example.
- [`input_check4.txt`](input_check4.txt): Matrix input example.

These files are used for file-based input commands in the language.

## Language Features

- **Types:** `int`, `float`, `bool`, `vector_int`, `vector_float`, `matrix_int`, `matrix_float`
- **Operations:** Arithmetic, logical, vector/matrix arithmetic, dot product, transpose, determinant, minor, angle, etc.
- **Control Flow:** `if`, `else if`, `else`, `for`, `while`
- **I/O:** `Input()`, `Input(filename)`, `Print()`, `Print(variable)`
- **Assignments:** Variable, vector/matrix element assignment

## Example

```ocaml
matrix_int 2,2 x := 2,2 [[1,2],[3,4]];
matrix_int 2,2 y := 2,2 [[5,6],[7,8]];
matrix_int 2,2 add_matrices := x + y;
Print( x );
Print( y );
Print( add_matrices );
```
