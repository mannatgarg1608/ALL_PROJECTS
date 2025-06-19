# Spreadsheet Program in RUST

## 1. Features Included in the Implementation

### ✅ General Formula Support
- Supports general expressions like `A1 + B1 + C1`, `A1 + Max(A1:A5)` (use `Max` instead of `MAX`).
- Cell assignments via:
  - Formula bar: `cellname = expression`
  - Inside the cell: `=expression`
- Toggle formula input mode by clicking the black bar at the top-left corner (GUI).
- Scrolling via arrow buttons or entering `w`, `a`, `s`, `d` in the formula bar (GUI/CLI).
- Supports functions: `SUM`, `AVG`, `MIN`, `MAX`, `STDEV`, `SLEEP` (case-insensitive, but use capitalized names in CLI).

### ✅ User Interface
- Built with the `fltk` crate for GUI mode.
- **Bold** a cell: `b cellname`
- *Italicize* a cell: `i cellname`
- Error cells:
  - Shown in **red**
  - Popup prompts for correction (GUI)
- Undo/Redo via buttons or commands (`undo`, `redo`)
- File import via GUI controls or command

### ✅ Common Functionalities
- **Cut (single)**: `dc cellname target_cell`
- **Cut (range)**: `d cell_range target_range`
- **Copy (single)**: `yc cellname target_cell`
- **Copy (range)**: `y cell_range target_range`
- **Undo**: Use the **Undo button** or type `undo`
- **Redo**: Use the **Redo button** or type `redo`
- **Filter**: `filter <range> <comparator> <value>` (e.g., `filter A1:B2 > 10`)
- **CSV Import**: Load data from CSV files (see below)

### ✅ Graphing Capabilities
#### Forecast
```bash
forecast <length> <X_range> <Y_range> <filename>.png
```
Use the **Plot Graph** button and select **forecast** (GUI), or use the command above (CLI).

#### Plot Types
- **Histogram**: `plot_histogram <range> <filename>.png`
- **Line Plot**: `plot_line <range> <filename>.png`
- **Scatter Plot**: `plot_scatter <x_range> <y_range> <filename>.png`

---

## 2. Features Not Included

- ❌ Underline formatting (`u cellname`)
- ❌ Range-based formatting
- ❌ Bar chart, pie chart support
- ❌ Graph style customization (colors, labels)
- ❌ Dynamic dependency updates
- ❌ Full parallel/concurrent processing
- ❌ Full GUI (still uses command-line input for some tasks)

---

## 3. Potential Future Extensions

- Add underline and range-based formatting
- Graph customization (colors, labels, etc.)
- Automatic dynamic dependency tracking
- Enhanced error messages
- Full GUI with `fltk` or `egui`
- Export to CSV or Excel

---

## 4. Primary Data Structures

### `Cell` struct:
```rust
struct Cell {
    value: i32,
    formula: Expr,
    is_bold: bool,
    is_italic: bool,
    dependents: HashSet<(row, col)>,
    precedents: HashSet<(row, col)>
}
```

### `Spreadsheet`:
- `rows`, `columns`: dimensions
- `all_cells`: `Vec<Vec<Cell>>`

### `Expr` Enum:
```rust
enum Expr {
    Number(i32),
    Cell((row, col)),
    BinaryOp(Box<Expr>, char, Box<Expr>),
    Function(String, Vec<Expr>),
    Range(CellReference, CellReference),
}
```

### `UndoRedoStack`:
- Stores last 17 operations
- Efficient memory use by tracking only necessary state

---

## 5. Interfaces Between Software Modules

### Workflow Highlights
- GUI runs in a **separate thread**
- Uses `Arc<T>` for shared memory
- GUI polling via `input_text.lock().unwrap()`
- Input parsed via `formula.rs` (LALRPOP grammar)
- AST passed to `assign_cell()` in `graph_extension.rs`
- File I/O handled in `read_mode.rs`
- Visual mode handled in `parser_visual_mode.rs`
- Plotting delegated to specific modules like `plot_graph.rs`

---

## 6. Encapsulation Approaches

- Modules are well-separated by function (e.g., `graph_extension.rs`, `formula.rs`)
- Only public functions are exposed using `pub`
- Type hierarchies ensure proper data encapsulation (e.g., `Cell`)
- Safe concurrency via `Arc<T>`, no data races
- Ownership and borrowing principles ensure clean inter-module communication

---

## 7. Justification for Good Design

- Modular code using Rust’s module system
- Memory-efficient undo/redo design
- Thread-safe sharing using `Arc<T>`
- Object-oriented principles in Rust style
- Used iterators to avoid index panics
- Followed official Rust formatting using `rustfmt` and `clippy`
- Used only well-maintained crates
- Avoided unsafe blocks unless strictly necessary

---

## 8. Getting Started

### Prerequisites
- Rust toolchain (https://rustup.rs/)
- [FLTK](https://crates.io/crates/fltk) library (for GUI mode)

### Build Instructions
```sh
# In the project directory:
cargo build --release
```

### Running
- **CLI Mode:**
  ```sh
  cargo run --features main1 -- <rows> <columns>
  ```
- **GUI Mode:**
  ```sh
  cargo run --features main2 -- <rows> <columns>
  ```

### Usage Examples

#### Command-Line Mode (main1)
- Assign value: `A1 = 5`
- Assign formula: `A2 = A1 + 10`
- Filter: `filter A1:B2 > 10`
- Cut/copy: `dc A1 B2`, `yc A1 B2`, `d A1:B2 C1:D2`, `y A1:B2 C1:D2`
- Plot: `plot_histogram A1:A10 hist.png`, `plot_line A1:A10 line.png`, `plot_scatter A1:A10 B1:B10 scatter.png`, `forecast 5 A1:A10 B1:B10 forecast.png`
- Formatting: `b A1`, `i A1`
- Undo/Redo: `undo`, `redo`
- Import CSV: `read <filename.csv>`
- Quit: `q`

#### GUI Mode (main2)
- Click to select/edit cells, enter formulas, and use formatting buttons
- Undo/redo and file import available via GUI controls
- Use arrow buttons or `w`, `a`, `s`, `d` to scroll

---

## 9. File Structure
- `src/cellsp.rs` / `src/cell_extension.rs`: Core cell and spreadsheet data structures
- `src/dependency_graph_final.rs` / `src/graph_extension.rs`: Dependency management and formula evaluation
- `src/input.rs` / `src/parser_visual_mode.rs`: Command parsing and visual mode logic
- `src/display.rs`: GUI implementation (FLTK)
- `src/read_mode.rs`: CSV import
- `src/expression_parser.rs`, `src/expression_utils.rs`: Formula parsing and evaluation
- `src/plot_graph.rs`, `src/forecast.rs`: Plotting and forecasting
- `tests/coverage_tests.rs`: Unit tests for spreadsheet logic

---

## 10. Documentation
See `RustLab.pdf` for detailed design, features, and user guide.

---

