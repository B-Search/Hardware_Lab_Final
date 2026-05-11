`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 08:14:45 PM
// Design Name: 
// Module Name: camera_capture
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


module camera_capture(
       input pclk,
       input reset,
       input vsync,
       input href,
       input [7:0] d,
        output reg [16:0] addr = 0,
        output reg [15:0] dout = 0,
        output reg we = 0
    );
    
    localparam [16:0] FRAME_PIXELS = 17'd76800;

    reg [7:0] first_byte = 0;
    reg byte_cnt = 0;
    reg vsync_prev = 0;
    reg href_prev = 0;
    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;
    
    always @(negedge pclk) begin
        vsync_prev <= vsync;
        href_prev <= href;
        we <= 0;

        if (reset) begin
            addr <= 0;
            byte_cnt <= 0;
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (vsync) begin
                addr <= 0;
                byte_cnt <= 0;
                h_cnt <= 0;
                v_cnt <= 0;
            end

            if (!href && href_prev) begin
                v_cnt <= v_cnt + 1'b1;
            end

            if (href) begin
                if (!byte_cnt) begin
                    byte_cnt <= 1;
                    first_byte <= d;
                end else begin
                    byte_cnt <= 0;
                    if ((h_cnt[0] == 1'b0) && (v_cnt[0] == 1'b0)) begin
                        dout <= {first_byte, d};
                        we <= 1;
                        if (addr == FRAME_PIXELS - 1) begin
                            addr <= 0;
                        end else begin
                            addr <= addr + 1'b1;
                        end
                    end
                    h_cnt <= h_cnt + 1'b1;
                end
            end else begin
                byte_cnt <= 0;
                h_cnt <= 0;
            end

            if (!vsync && vsync_prev) begin
                addr <= 0;
            end
        end
    end 
endmodule
