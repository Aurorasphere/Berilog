# Berilog
Brace+Verilog, very lightweight transpiler that maps brace-based block syntax to SystemVerilog.

## Build
This process requires [Dune](https://github.com/ocaml/dune)
```bash
git clone https://github.com/Aurorasphere/berilog.git
cd berilog
dune build
```

## Want precompiled binary?
Sorry. but i'm too lazy to make tons of version of executable binary. I mean, if you can use SystemVerilog i'm pretty sure you can install dune to your computer and type some commands in terminal.

## Usage
```bash
./_build/default/src/berilog input.b > output.sv
./_build/default/src/berilog input.b -o output.sv
./_build/default/src/berilog input.b -o build/
./_build/default/src/berilog -o output.sv < input.b
```

If no input file is given and stdin is an interactive terminal, `berilog` exits with usage text instead of waiting forever.

## Supported Keywords
### begin/end
- `if`
- `else`
- `for`
- `while`
- `do`
- `repeat`
- `forever`
- `always`
- `always_comb`
- `always_ff`
- `always_latch`
- `initial`
- `final`

### dedicated closing keyword
- `module` - `endmodule`
- `interface` - `endinterface`
- `package` - `endpackage`
- `program` - `endprogram`
- `function` - `endfunction`
- `task` - `endtask`
- `class` - `endclass`
- `clocking` - `endclocking`
- `checker` - `endchecker`
- `covergroup` - `endgroup`
- `sequence` - `endsequence`
- `randsequence` - `endsequence`
- `property` - `endproperty`
- `primitive` - `endprimitive`
- `config` - `endconfig`
- `case` - `endcase`
- `casex` - `endcase`
- `casez` - `endcase`
- `generate` - `endgenerate`
- `specify` - `endspecify`

## Concatenation Syntax
- Concatenation operator is not `{}` anymore! use `${}` instead.
- `${a, b, c}` -> `{a, b, c}`
- `${4; 1'b1}` -> `{4{1'b1}}`

## Examples
Check `examples/` directory.

## TODOS
- Make tree-sitter or plugins for Berilog. Not sure i could finish this before i go to military service.
