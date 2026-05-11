`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2026 03:47:39 PM
// Design Name: 
// Module Name: sccb_controller
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


module sccb_controller(
    input clk,
    input reset,
    input start,
    input [7:0] dev_addr,
    input [7:0] reg_addr,
    input [7:0] data,
    output reg busy = 0,
    output reg ready = 1,
    output sio_c,
    inout sio_d
    );
    reg [9:0] clk_cnt = 0;
    reg tick =0;
    
    always @(posedge clk) begin
        if(clk_cnt == 249) begin
            clk_cnt <= 0;
            tick <= 1;
         end else begin
            clk_cnt <= clk_cnt +1;
            tick <= 0;
         end
     end
     localparam IDLE = 0,
                START = 1,
                ID_ADDRESS = 2,
                ACK1 = 3,
                SUB_ADDRESS = 4,
                ACK2 = 5,
                DATA = 6,
                ACK3 = 7,
                STOP = 8,
                DONE = 9;
      reg [3:0] state = IDLE;
      reg [1:0] phase = 0;
      reg [3:0] bit_count = 0;
      reg [7:0] shift_reg = 0;
      reg r_sioc = 1;
      reg r_siod = 1;
      reg siod_oe = 1;
      always @(posedge clk) begin
        if(reset) begin
            state <= IDLE;
            busy <= 0;
            ready <= 1;
            r_sioc <= 1;
            r_siod <= 1;
            siod_oe <= 1;
        end
        else if(tick) begin
            case (state)
                IDLE : begin
                    busy <= 0;
                    ready <= 1;
                    r_sioc <= 1;
                    r_siod <= 1;
                    siod_oe <= 1;
                    if(start) begin
                        busy <= 1;
                        ready <= 0;
                        state <= START;
                        shift_reg <= dev_addr;
                        phase <= 0;
                    end
                end
                START : begin
                    case (phase)
                        0: r_siod <= 0;
                        1:r_sioc <= 0;
                        3: begin
                            state <= ID_ADDRESS;
                            phase <= 0;
                            bit_count <= 0;
                        end
                    endcase
                    phase <= phase + 1;
                end
                ID_ADDRESS, SUB_ADDRESS, DATA: begin
                    case(phase)
                        0:r_sioc <= 0;
                        1:r_siod <= shift_reg[7];
                        2:r_sioc <= 1;
                        3: begin
                            if(bit_count == 7)begin
                                state <= state + 1;
                                bit_count <= 0;
                            end else begin 
                                bit_count <= bit_count + 1;
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            end
                        end
                    endcase 
                    phase <= phase + 1;
                end
                ACK1, ACK2, ACK3: begin
                    case(phase)
                        0:r_sioc <= 0;
                        1:siod_oe <= 0;
                        2:r_sioc <= 1;
                        3:begin
                            siod_oe <= 1;
                            if(state == ACK1) shift_reg <= reg_addr;
                            else if(state == ACK2) shift_reg <= data;
                            state <= state + 1;
                        end
                    endcase
                    phase <= phase + 1;
                end
                STOP : begin
                    case(phase)
                        0:r_sioc <= 0;
                        1:r_siod <= 0;
                        2:r_sioc <= 1;
                        3:r_siod <= 1;
                    endcase
                    if(phase == 3) state <= DONE;
                    else phase <= phase + 1;
                end
                DONE : begin
                    ready <= 1;
                    state <= IDLE;
                end
            endcase
        end
      end
    
      assign sio_c = r_sioc;
      assign sio_d = (siod_oe) ? r_siod : 1'bz;
endmodule
