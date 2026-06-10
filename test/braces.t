  $ ../src/berilog.exe <<'EOF'
  > typedef enum logic [1:0] {
  >   IDLE,
  >   BUSY
  > } state_t;
  > 
  > typedef struct packed {
  >   logic a;
  >   logic b;
  > } pair_t;
  > 
  > always_comb {
  >   foo = 1'b1;
  > }
  > EOF
  // Auto-generated with Aurorasphere's Berilog transcompiler
  typedef enum logic [1:0] {
    IDLE,
    BUSY
  } state_t;
  
  typedef struct packed {
    logic a;
    logic b;
  } pair_t;
  
  always_comb  begin
    foo = 1'b1;
  end

  $ ../src/berilog.exe <<'EOF'
  > case (state) {
  >   FETCH_A_ADDR: {
  >     address <= pc;
  >   }
  >   default: foo();
  > }
  > EOF
  // Auto-generated with Aurorasphere's Berilog transcompiler
  case (state) 
    FETCH_A_ADDR:  begin
      address <= pc;
    end
    default: foo();
  endcase

  $ ../src/berilog.exe <<'EOF' 2>&1
  > always_comb {
  >   foo = ${bar;
  > }
  > EOF
  berilog: line 3: missing repeated concat expression
  [1]
