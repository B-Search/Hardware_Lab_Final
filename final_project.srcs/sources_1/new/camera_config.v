`timescale 1ns / 1ps

module camera_config(
        input clk,
        input reset,
        input sccb_ready,
        output reg sccb_start = 0,
        output [7:0] reg_addr,
        output [7:0] reg_data,
        output reg done = 0
    );

    localparam [24:0] RESET_WAIT_CYCLES = 25'd30_000_000;  // 300 ms @100 MHz
    localparam [24:0] TX_GAP_CYCLES     = 25'd200_000;     // 2 ms @100 MHz

    localparam ST_IDLE      = 3'd0;
    localparam ST_WAIT_BUSY = 3'd1;
    localparam ST_WAIT_DONE = 3'd2;
    localparam ST_DELAY     = 3'd3;
    localparam ST_DONE      = 3'd4;

    reg [2:0] state = ST_IDLE;
    reg [24:0] delay_cnt = 0;
    reg [7:0] rom_addr_idx = 0;
    reg [15:0] rom_data_word;

    always @(*) begin
        case (rom_addr_idx)
            8'd0:  rom_data_word = 16'h12_80; // COM7 reset
            8'd1:  rom_data_word = 16'h11_00; // CLKRC
            8'd2:  rom_data_word = 16'h6B_4A; // DBLV
            8'd3:  rom_data_word = 16'h3B_0A; // COM11

            // RGB565 output, VGA sensor timing; FPGA downsamples to 320x240
            8'd4:  rom_data_word = 16'h12_04; // COM7 RGB + VGA
            8'd5:  rom_data_word = 16'h40_D0; // COM15 RGB565 full range
            8'd6:  rom_data_word = 16'h3A_04; // TSLB
            8'd7:  rom_data_word = 16'h0C_00; // COM3
            8'd8:  rom_data_word = 16'h3E_00; // COM14
            8'd9:  rom_data_word = 16'h70_3A; // SCALING_XSC
            8'd10: rom_data_word = 16'h71_35; // SCALING_YSC
            8'd11: rom_data_word = 16'h72_11; // SCALING_DCWCTR
            8'd12: rom_data_word = 16'h73_F1; // SCALING_PCLK_DIV
            8'd13: rom_data_word = 16'hA2_02; // SCALING_PCLK_DELAY

            8'd14: rom_data_word = 16'h17_13; // HSTART
            8'd15: rom_data_word = 16'h18_01; // HSTOP
            8'd16: rom_data_word = 16'h32_BF; // HREF
            8'd17: rom_data_word = 16'h19_02; // VSTART
            8'd18: rom_data_word = 16'h1A_7A; // VSTOP
            8'd19: rom_data_word = 16'h03_0A; // VREF

            8'd20: rom_data_word = 16'h4F_80; // MTX1: คืนค่ากลาง (Default)
            8'd21: rom_data_word = 16'h50_80; // MTX2: คืนค่ากลาง (Default)
            8'd22: rom_data_word = 16'h51_00; 
            8'd23: rom_data_word = 16'h52_22; 
            8'd24: rom_data_word = 16'h53_5E; 
            8'd25: rom_data_word = 16'h54_80; // MTX6: คืนค่ากลาง (Default)
            8'd26: rom_data_word = 16'h58_9E;

            8'd27: rom_data_word = 16'h13_EF; // COM8
            8'd28: rom_data_word = 16'h00_00; // GAIN
            8'd29: rom_data_word = 16'h10_00; // AECH
            8'd30: rom_data_word = 16'h0D_40; // COM4
            8'd31: rom_data_word = 16'h14_38; // COM9
            8'd32: rom_data_word = 16'h24_95; // AEW
            8'd33: rom_data_word = 16'h25_33; // AEB
            8'd34: rom_data_word = 16'h26_E3; // VPT

            8'd35: rom_data_word = 16'h7A_20;
            8'd36: rom_data_word = 16'h7B_10;
            8'd37: rom_data_word = 16'h7C_1E;
            8'd38: rom_data_word = 16'h7D_35;
            8'd39: rom_data_word = 16'h7E_5A;
            8'd40: rom_data_word = 16'h7F_69;
            8'd41: rom_data_word = 16'h80_76;
            8'd42: rom_data_word = 16'h81_80;
            8'd43: rom_data_word = 16'h82_88;
            8'd44: rom_data_word = 16'h83_8F;
            8'd45: rom_data_word = 16'h84_96;
            8'd46: rom_data_word = 16'h85_A3;
            8'd47: rom_data_word = 16'h86_AF;
            8'd48: rom_data_word = 16'h87_C4;
            8'd49: rom_data_word = 16'h88_D7;
            8'd50: rom_data_word = 16'h89_E8;

            8'd51: rom_data_word = 16'h41_08;// COM16
            8'd52: rom_data_word = 16'h76_E1;
            8'd53: rom_data_word = 16'h33_0B;
            8'd54: rom_data_word = 16'h3C_78;
            8'd55: rom_data_word = 16'h69_00;
            8'd56: rom_data_word = 16'h74_00;
            8'd57: rom_data_word = 16'hB0_84;
            8'd58: rom_data_word = 16'hB1_00;
            8'd59: rom_data_word = 16'hB2_0E;
            8'd60: rom_data_word = 16'hB3_82;

            8'd61: rom_data_word = 16'h67_D8; // U Gain: ดันขึ้นจาก C0 -> D8 (เพิ่มความสดสีฟ้า/เหลือง)
            8'd62: rom_data_word = 16'h68_D8; // V Gain: ดันขึ้นจาก C0 -> D8 (เพิ่มความสดสีแดง/เขียว)
            8'd63: rom_data_word = 16'h56_40;// Saturation V: ค่ากลางๆ
            8'd64: rom_data_word = 16'h15_00; // COM10
            8'd65: rom_data_word = 16'h13_EF; // COM8 repeat
            8'd66: rom_data_word = 16'h0E_61; // COM6
            8'd67: rom_data_word = 16'h16_00;
            8'd68: rom_data_word = 16'h1E_07; // MVFP
            8'd69: rom_data_word = 16'h42_00; // COM17: no test pattern

            8'd70: rom_data_word = 16'hFF_FF;
            default: rom_data_word = 16'hFF_FF;
        endcase
    end

    assign reg_addr = rom_data_word[15:8];
    assign reg_data = rom_data_word[7:0];

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE;
            sccb_start <= 0;
            done <= 0;
            rom_addr_idx <= 0;
            delay_cnt <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (rom_data_word == 16'hFF_FF) begin
                        sccb_start <= 0;
                        done <= 1;
                        state <= ST_DONE;
                    end else if (sccb_ready) begin
                        sccb_start <= 1;
                        state <= ST_WAIT_BUSY;
                    end else begin
                        sccb_start <= 0;
                    end
                end

                ST_WAIT_BUSY: begin
                    if (!sccb_ready) begin
                        sccb_start <= 0;
                        state <= ST_WAIT_DONE;
                    end else begin
                        // Hold start high until SCCB controller samples it.
                        sccb_start <= 1;
                    end
                end

                ST_WAIT_DONE: begin
                    sccb_start <= 0;
                    if (sccb_ready) begin
                        if (rom_addr_idx == 0) begin
                            delay_cnt <= RESET_WAIT_CYCLES - 1;
                        end else begin
                            delay_cnt <= TX_GAP_CYCLES - 1;
                        end
                        state <= ST_DELAY;
                    end
                end

                ST_DELAY: begin
                    sccb_start <= 0;
                    if (delay_cnt == 0) begin
                        rom_addr_idx <= rom_addr_idx + 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        delay_cnt <= delay_cnt - 1'b1;
                    end
                end

                ST_DONE: begin
                    sccb_start <= 0;
                    done <= 1;
                end

                default: begin
                    sccb_start <= 0;
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule