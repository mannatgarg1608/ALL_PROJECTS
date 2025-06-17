# Makefile for the Rust spreadsheet project

# Define variables
BINARY_NAME = spreadsheet
RUST_DIR = rust_lab
RELEASE_DIR = $(RUST_DIR)/target/release
DEBUG_DIR = $(RUST_DIR)/target/debug
SOURCE_BINARY = main
AUTOGRADER_DIR = /tmp/cop290/lab1_build
AUTOGRADER_BINARY = spreadsheet2023CS50678_2023CS10138_2023CS10489

.PHONY: all clean release autograder

# Default target
all: release autograder

# Build the release version and rename binary
release:
	@echo "Building release version..."
	cd $(RUST_DIR) && cargo build --release
	@echo "Creating binary $(BINARY_NAME)..."
	mkdir -p target/release
	cp $(RELEASE_DIR)/$(SOURCE_BINARY) target/release/$(BINARY_NAME)
	@echo "Build complete: target/release/$(BINARY_NAME)"

# Create autograder-compatible binary
autograder: release
	@echo "Preparing binary for autograder..."
	mkdir -p $(AUTOGRADER_DIR)
	cp $(RELEASE_DIR)/$(SOURCE_BINARY) $(AUTOGRADER_DIR)/$(AUTOGRADER_BINARY)
	chmod +x $(AUTOGRADER_DIR)/$(AUTOGRADER_BINARY)
	@echo "Autograder binary ready: $(AUTOGRADER_DIR)/$(AUTOGRADER_BINARY)"

# Clean the target directory
clean:
	@echo "Cleaning..."
	cd $(RUST_DIR) && cargo clean
	rm -rf target
	rm -rf $(AUTOGRADER_DIR)
	@echo "Clean complete"

# Run the application with default values (10x10 grid)
run: release
	@echo "Running spreadsheet..."
	./target/release/$(BINARY_NAME) 10 10

coverage:
	cd $(RUST_DIR) && cargo tarpaulin --exclude-files "src/formula.rs"

test:
	cd $(RUST_DIR) && cargo test --features main1

ext1:
	@echo "Building extension version..."
	cd $(RUST_DIR) && cargo build --no-default-features --features main2
	@echo "Creating binary $(BINARY_NAME)..."
	mkdir -p target/release
	cp $(DEBUG_DIR)/$(SOURCE_BINARY) target/release/$(BINARY_NAME)
	@echo "Build complete: target/release/$(BINARY_NAME)"
	./target/release/spreadsheet 100 100

docs:
	cd $(RUST_DIR) && cargo doc --no-default-features --features main1
	cd $(RUST_DIR) && cargo doc --open
	@echo "Generating PDF from LaTeX source..."
	pdflatex report.tex
	pdflatex report.tex  # Run twice to resolve references
	@echo "PDF generation complete: report.pdf"
