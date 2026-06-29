// ================================================================
// Module  : counter         Project : custom-soc-project
// Author  : Aashrith        Date    : 2026-06-28
// Description : 8-bit counter for toolchain verification.
// Dependencies: none
// ================================================================

module counter(
    input logic clk,
    input logic rst,
    output logic[7:0] count
);
    
    always_ff @(posedge clk ) begin 
        if(rst)
            count <= 8'b0;
        else
            count <= count + 1; 
    end

endmodule
