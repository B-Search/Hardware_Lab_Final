`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 06:07:55 PM
// Design Name: 
// Module Name: debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debouncer (
    input clk,        
    input btn_in,       
    output reg btn_out  
);

    reg [19:0] count = 0;
    reg btn_sync_0, btn_sync_1;

    always @(posedge clk) begin
        
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;

        if (btn_sync_1 == btn_out) begin

            count <= 0;
        end else begin

            count <= count + 1;

            if (count == 20'd1_000_000) begin
                btn_out <= btn_sync_1; 
                count <= 0;
            end
        end
    end
endmodule
