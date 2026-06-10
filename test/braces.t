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
