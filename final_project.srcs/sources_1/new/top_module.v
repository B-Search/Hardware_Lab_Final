`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 09:16:20 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
        input clk,
        input reset,
        //vga
        output vga_hsync,
        output vga_vsync,
        output [3:0] vga_r,
        output [3:0] vga_g,
        output [3:0] vga_b,
        // sccb & camera 
        inout siod,
        input pclk,
        input ov_href,
        input ov_vsync,
        input [7:0] d,
        output sioc,
        output rst,
        output pwdn,
        output camera_clk,
        
        output led,
        output led2
    );
    wire clk_vga_out;
    wire clk_camera_out;
    wire clk_sys;
    wire clk_locked;
    wire clean_reset;
    
    clk_wiz_0 clk_1(
        .clk_vga(clk_vga_out),
        .clk_camera(clk_camera_out),
        .clk_sys(clk_sys),
        .reset(1'b0),
        .locked(clk_locked),
        .clk_in1(clk)
    );
    debouncer reset_button(
        .clk(clk_sys),
        .btn_in(reset),
        .btn_out(clean_reset)
    );
    assign camera_clk = clk_camera_out;
    wire sccb_start;
    wire sccb_ready;
    wire [7:0] reg_addr;
    wire [7:0] reg_data;
    wire config_done;
    wire sys_reset;
    assign sys_reset = clean_reset | ~clk_locked;
    assign pwdn = 1'b0;
    assign rst = 1'b1;
    
    camera_config config_inst(
        .clk(clk_sys),
        .reset(sys_reset),
        .sccb_ready(sccb_ready),
        .sccb_start(sccb_start),
        .reg_addr(reg_addr),
        .reg_data(reg_data),
        .done(config_done)
    );    
    sccb_controller controller_inst(
        .clk(clk_sys),
        .reset(sys_reset),
        .start(sccb_start),
        .dev_addr(8'h42),
        .reg_addr(reg_addr),
        .data(reg_data),
        .ready(sccb_ready),
        .sio_c(sioc),
        .sio_d(siod)
    );
    
    assign led = config_done;
    assign led2 = clean_reset;
    wire [16:0] write_addr;
    wire [15:0] write_data;
    wire write_en;
    wire [15:0] read_data;
    wire [16:0] read_addr;
    camera_capture capture(
        .pclk(pclk),
        .reset(sys_reset),
        .vsync(ov_vsync),
        .href(ov_href),
        .d(d),
        .addr(write_addr),
        .dout(write_data),
        .we(write_en)
    );
   
    frame_buffer buffer_ram(
        .clka(pclk),
        .wea(write_en),
        .addra(write_addr),
        .dina(write_data),
        
        .clkb(clk_vga_out),
        .addrb(read_addr),
        .enb(1'b1),
        .doutb(read_data)
    );
    
 vga_controller vga_control(
     .clk_vga(clk_vga_out),
     .hsync(vga_hsync),
     .vsync(vga_vsync),
     .vga_r(vga_r),
     .vga_g(vga_g),
     .vga_b(vga_b),
     .read_addr(read_addr),
     .frame_data(read_data)
   );
    
    
endmodule
