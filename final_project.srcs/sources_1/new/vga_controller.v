`timescale 1ns / 1ps

module vga_controller(
    input clk_vga,
    input sw0,
    input sw1,
    input sw2,
    
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

    // ============================================
    // 320x240 framebuffer scaling
    // ============================================

    wire [8:0] row = v_cnt[9:1];
    wire [8:0] col = h_cnt[9:1];

    // row * 320 = row*256 + row*64
    wire [16:0] row_addr =
        ({8'b0, row} << 8) +
        ({8'b0, row} << 6);

    wire [16:0] addr_next =
        row_addr + {8'b0, col};

    // ============================================
    // VGA TIMING
    // ============================================

    always @(posedge clk_vga) begin

        if (h_cnt == 799) begin
            h_cnt <= 0;
            
            if (v_cnt == 524)
                v_cnt <= 0;
            else
                v_cnt <= v_cnt + 1'b1;

        end
        else begin
            h_cnt <= h_cnt + 1'b1;
        end

    end

    // ============================================
    // HSYNC / VSYNC
    // ============================================

    always @(posedge clk_vga) begin

        hsync <= (h_cnt >= 656 && h_cnt < 752) ? 1'b0 : 1'b1;
        vsync <= (v_cnt >= 490 && v_cnt < 492) ? 1'b0 : 1'b1;

    end

    // ============================================
    // FRAME BUFFER ADDRESS
    // ============================================

    always @(posedge clk_vga) begin

        read_addr <= active ? addr_next : 17'd0;
        active_d1 <= active;
        active_d2 <= active_d1;

    end

    // ============================================
    // RGB565 -> RGB888
    // ============================================

    wire [4:0] r5 = frame_data[15:11];
    wire [5:0] g6 = frame_data[10:5];
    wire [4:0] b5 = frame_data[4:0];

    wire [7:0] r8 = {r5, r5[4:2]};
    wire [7:0] g8 = {g6, g6[5:4]};
    wire [7:0] b8 = {b5, b5[4:2]};

    // ============================================
    // GRAYSCALE
    // ============================================

    wire [7:0] gray = (r8 >> 2) + (g8 >> 1) + (b8 >> 3);

    // ============================================
    // COLOR INVERSION
    // ============================================

    wire [7:0] inv_r = 8'hFF - r8;
    wire [7:0] inv_g = 8'hFF - g8;
    wire [7:0] inv_b = 8'hFF - b8;

    // ============================================
    // BETTER EDGE DETECTION
    // ============================================

    // Previous left pixel
    reg [7:0] gray_left = 0;

    // Previous row buffer
    reg [7:0] line_buffer [0:639];

    // Current pixel position
    reg [9:0] x_pos = 0;

    // Previous upper pixel
    reg [7:0] gray_up = 0;

    // Gradient values
    reg [7:0] grad_x = 0;
    reg [7:0] grad_y = 0;

    // Combined edge strength
    wire [8:0] edge_strength = grad_x + grad_y;

    always @(posedge clk_vga) begin

        // Reset horizontal position
        if (h_cnt == 0)
            x_pos <= 0;
        else
            x_pos <= x_pos + 1'b1;

        // Read pixel from previous row
        gray_up <= line_buffer[x_pos];

        // Store current gray pixel
        line_buffer[x_pos] <= gray;

        // Horizontal difference
        if (gray > gray_left)
            grad_x <= gray - gray_left;
        else
            grad_x <= gray_left - gray;

        // Vertical difference
        if (gray > gray_up)
            grad_y <= gray - gray_up;
        else
            grad_y <= gray_up - gray;

        // Update left pixel
        gray_left <= gray;

    end

    // Edge threshold
    wire Edge = (edge_strength > 9'd40);

    // ============================================
    // VGA OUTPUT
    // ============================================

    always @(posedge clk_vga) begin

        if (active_d1) begin

            // ====================================
            // SW2 = EDGE DETECTION
            // ====================================

            if (sw2) begin

                if (Edge) begin
                    vga_r <= 4'hF;
                    vga_g <= 4'hF;
                    vga_b <= 4'hF;
                end
                else begin
                    vga_r <= 4'h0;
                    vga_g <= 4'h0;
                    vga_b <= 4'h0;
                end

            end

            // ====================================
            // SW1 = COLOR INVERSION
            // ====================================

            else if (sw1) begin

                vga_r <= inv_r[7:4];
                vga_g <= inv_g[7:4];
                vga_b <= inv_b[7:4];

            end

            // ====================================
            // SW0 = GRAYSCALE
            // ====================================

            else if (sw0) begin

                vga_r <= gray[7:4];
                vga_g <= gray[7:4];
                vga_b <= gray[7:4];

            end

            // ====================================
            // NORMAL RGB
            // ====================================

            else begin

                vga_r <= r8[7:4];
                vga_g <= g8[7:4];
                vga_b <= b8[7:4];

            end

        end
        else begin

            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;

        end

    end

endmodule