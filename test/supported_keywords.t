  $ ../src/berilog.exe <<'EOF'
  > if (cond) {
  >   a = 1;
  > } else {
  >   a = 0;
  > }
  > for (int i = 0; i < 4; i++) {
  >   sum += i;
  > }
  > while (ready) {
  >   step();
  > }
  > do {
  >   tick();
  > } while (again);
  > repeat (4) {
  >   pulse();
  > }
  > forever {
  >   tick();
  > }
  > always {
  >   tick();
  > }
  > always_comb {
  >   y = x;
  > }
  > always_ff @(posedge clk) {
  >   q <= d;
  > }
  > always_latch {
  >   q <= d;
  > }
  > initial {
  >   init();
  > }
  > final {
  >   finish();
  > }
  > EOF
  // Auto-generated with Aurorasphere's Berilog transcompiler
  if (cond)  begin
    a = 1;
  end else  begin
    a = 0;
  end
  for (int i = 0; i < 4; i++)  begin
    sum += i;
  end
  while (ready)  begin
    step();
  end
  do  begin
    tick();
  end while (again);
  repeat (4)  begin
    pulse();
  end
  forever  begin
    tick();
  end
  always  begin
    tick();
  end
  always_comb  begin
    y = x;
  end
  always_ff @(posedge clk)  begin
    q <= d;
  end
  always_latch  begin
    q <= d;
  end
  initial  begin
    init();
  end
  final  begin
    finish();
  end

  $ ../src/berilog.exe <<'EOF'
  > module m() {
  > }
  > interface i() {
  > }
  > package p {
  > }
  > program pr() {
  > }
  > function logic f(input logic x) {
  >   f = x;
  > }
  > task t() {
  >   work();
  > }
  > class C {
  > }
  > clocking cb @(posedge clk) {
  > }
  > checker chk() {
  > }
  > covergroup cg {
  > }
  > sequence seq1 {
  >   a ##1 b;
  > }
  > randsequence (main) {
  >   main : item;
  > }
  > property prop1 {
  >   @(posedge clk)
  >   a |-> b;
  > }
  > primitive udp0 {
  > }
  > config cfg {
  >   design top;
  > }
  > generate {
  >   genvar i;
  > }
  > specify {
  >   specparam T = 1;
  > }
  > case (opcode) {
  >   0: a();
  > }
  > casex (opcode) {
  >   1'bx: a();
  > }
  > casez (opcode) {
  >   1'bz: a();
  > }
  > EOF
  // Auto-generated with Aurorasphere's Berilog transcompiler
  module m() ;
  endmodule
  interface i() ;
  endinterface
  package p ;
  endpackage
  program pr() ;
  endprogram
  function logic f(input logic x) ;
    f = x;
  endfunction
  task t() ;
    work();
  endtask
  class C ;
  endclass
  clocking cb @(posedge clk) ;
  endclocking
  checker chk() ;
  endchecker
  covergroup cg ;
  endgroup
  sequence seq1 ;
    a ##1 b;
  endsequence
  randsequence (main) ;
    main : item;
  endsequence
  property prop1 ;
    @(posedge clk)
    a |-> b;
  endproperty
  primitive udp0 
  endprimitive
  config cfg 
    design top;
  endconfig
  generate 
    genvar i;
  endgenerate
  specify 
    specparam T = 1;
  endspecify
  case (opcode) 
    0: a();
  endcase
  casex (opcode) 
    1'bx: a();
  endcase
  casez (opcode) 
    1'bz: a();
  endcase
