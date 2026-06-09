module parity_tree(
    input  logic [15:0] x,
    output logic [16:0] y
) {
    function logic parity8(input logic [7:0] v) {
        parity8 = ^v;
    }

    always_comb {
        y = ${
            ${4; parity8(x[15:8])},
            ${4; parity8(x[7:0])},
            x[7:0],
            ^x
        };
    }
}
