module handshake_property(
    input logic clk,
    input logic rst,
    input logic valid,
    input logic ready
) {
    property p_ready_when_valid {
        @(posedge clk)
        if (!rst) valid |-> ready;
    }
}
