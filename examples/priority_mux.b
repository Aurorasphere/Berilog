module priority_mux(
    input  logic [1:0] sel,
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] c,
    output logic [7:0] y
) {
    always_comb {
        casez (sel) {
            2'b1?: y = a;
            2'b01: y = b;
            default: y = c;
        }
    }
}
