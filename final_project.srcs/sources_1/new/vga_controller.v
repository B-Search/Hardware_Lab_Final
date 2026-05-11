`timescale 1ns / 1ps

module vga_controller(
    input clk_vga,
    output reg hsync,
    output reg vsync,
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,
    output reg [16:0] read_addr,
    input [15:0] frame_data
    );

    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;
    reg active_d1 = 0;
    reg active_d2 = 0;

    wire active = (h_cnt < 640) && (v_cnt < 480);
    wire [8:0] row = v_cnt[9:1];
    wire [8:0] col = h_cnt[9:1];
    wire [16:0] row_addr = ({8'b0, row} << 8) + ({8'b0, row} << 6);
    wire [16:0] addr_next = row_addr + {8'b0, col};

    always @(posedge clk_vga) begin
        if (h_cnt == 799) begin
            h_cnt <= 0;
            if (v_cnt == 524) begin
                v_cnt <= 0;
            end else begin
                v_cnt <= v_cnt + 1'b1;
            end
        end else begin
            h_cnt <= h_cnt + 1'b1;
        end
    end

    always @(posedge clk_vga) begin
        hsync <= (h_cnt >= 656 && h_cnt < 752) ? 1'b0 : 1'b1;
        vsync <= (v_cnt >= 490 && v_cnt < 492) ? 1'b0 : 1'b1;
    end

    always @(posedge clk_vga) begin
        read_addr <= active ? addr_next : 17'd0;
        active_d1 <= active;
        active_d2 <= active_d1;
    end

    always @(posedge clk_vga) begin
        if (active_d2) begin
            vga_r <= frame_data[15:12]; // R[4:0] → เอา 4 bits บน
            vga_g <= frame_data[10:7];  // G[5:0] → เอา 4 bits บน  
            vga_b <= frame_data[4:1];   // B[4:0] → เอา 4 bits บน
        end else begin
            vga_r <= 4'd0;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end
    end

endmodule
