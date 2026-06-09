module generated_pipeline #(
    parameter int STAGES = 2,
    parameter int WIDTH  = 8
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
) {
    logic [WIDTH-1:0] stage_q [0:STAGES-1];

    generate {
        for (genvar i = 0; i < STAGES; i++) {
            always_ff @(posedge clk) {
                if (rst) {
                    stage_q[i] <= '0;
                } else {
                    if (i == 0) {
                        stage_q[i] <= din;
                    } else {
                        stage_q[i] <= stage_q[i-1];
                    }
                }
            }
        }
    }

    always_comb {
        dout = stage_q[STAGES-1];
    }
}
