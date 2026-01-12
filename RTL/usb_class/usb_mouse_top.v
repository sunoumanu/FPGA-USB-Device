
//--------------------------------------------------------------------------------------------------------
// Module  : usb_mouse_top
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: A USB Full Speed (12Mbps) device, act as a USB HID mouse
//--------------------------------------------------------------------------------------------------------

module usb_mouse_top #(
    parameter          DEBUG = "FALSE"  // whether to output USB debug info, "TRUE" or "FALSE"
) (
    input  wire        rstn,          // active-low reset, reset when rstn=0 (USB will unplug when reset), normally set to 1
    input  wire        clk,           // 60MHz is required
    // USB signals
    output wire        usb_dp_pull,   // connect to USB D+ by an 1.5k resistor
    inout              usb_dp,        // USB D+
    inout              usb_dn,        // USB D-
    // USB reset output
    output wire        usb_rstn,      // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
    // HID mouse control signals
    input  wire [ 7:0] mouse_dx,      // X movement (signed, -127 to +127)
    input  wire [ 7:0] mouse_dy,      // Y movement (signed, -127 to +127)
    input  wire [ 2:0] mouse_btn,     // Button states: bit0=left, bit1=right, bit2=middle
    input  wire [ 7:0] mouse_wheel,   // Scroll wheel movement (signed, -127 to +127)
    input  wire        mouse_update,  // when mouse_update=1 pulses, a mouse report is sent
    // debug output info, only for USB developers, can be ignored for normally use. Please set DEBUG="TRUE" to enable these signals
    output wire        debug_en,      // when debug_en=1 pulses, a byte of debug info appears on debug_data
    output wire [ 7:0] debug_data,    // 
    output wire        debug_uart_tx  // debug_uart_tx is the signal after converting {debug_en,debug_data} to UART (format: 115200,8,n,1). If you want to transmit debug info via UART, you can use this signal. If you want to transmit debug info via other custom protocols, please ignore this signal and use {debug_en,debug_data}.
);



//-------------------------------------------------------------------------------------------------------------------------------------
// HID mouse IN data packet process
//-------------------------------------------------------------------------------------------------------------------------------------
reg  [31:0] in_data = 32'h0;
reg         in_valid = 1'b0;
reg  [ 4:0] in_cnt = 5'h0;
wire        in_ready;

always @ (posedge clk or negedge usb_rstn)
    if (~usb_rstn) begin
        in_data <= 32'h0;
        in_valid <= 1'b0;
        in_cnt <= 5'h0;
    end else begin
        if (in_cnt == 5'd0) begin
            // Mouse report format: [buttons, X, Y, wheel]
            in_data <= {mouse_wheel, mouse_dy, mouse_dx, 5'h0, mouse_btn};
            if (mouse_update) begin
                in_valid <= 1'b1;
                in_cnt <= 5'd1;
            end
        end else if (in_cnt < 5'd5) begin
            if (in_ready) begin
                in_data <= {8'h0, in_data[31:8]};
                in_cnt <= in_cnt + 5'd1;
            end
        end else begin
            in_valid <= 1'b0;
            in_cnt <= 5'd0;
        end
    end




//-------------------------------------------------------------------------------------------------------------------------------------
// endpoint 00 (control endpoint) command response : HID descriptor
//-------------------------------------------------------------------------------------------------------------------------------------
wire [63:0] ep00_setup_cmd;
wire [ 8:0] ep00_resp_idx;
reg  [ 7:0] ep00_resp;

// HID Report Descriptor for a standard mouse with 3 buttons and scroll wheel
// Report format: 4 bytes
//   Byte 0: Buttons (bit 0=left, bit 1=right, bit 2=middle, bits 3-7=padding)
//   Byte 1: X movement (signed byte, -127 to +127)
//   Byte 2: Y movement (signed byte, -127 to +127)
//   Byte 3: Wheel movement (signed byte, -127 to +127)
localparam [50*8-1:0] DESCRIPTOR_HID = 400'h05_01_09_02_a1_01_09_01_a1_00_05_09_19_01_29_03_15_00_25_01_75_01_95_03_81_02_95_01_75_05_81_01_05_01_09_30_09_31_09_38_15_81_25_7f_75_08_95_03_81_06_c0_c0;

always @ (posedge clk)
    if (ep00_setup_cmd[15:0] == 16'h0681)
        ep00_resp <= DESCRIPTOR_HID[ (50 - 1 - ep00_resp_idx) * 8 +: 8 ];
    else
        ep00_resp <= 8'h0;




//-------------------------------------------------------------------------------------------------------------------------------------
// USB full-speed core
//-------------------------------------------------------------------------------------------------------------------------------------
usbfs_core_top #(
    .DESCRIPTOR_DEVICE  ( {  //  18 bytes available
        144'h12_01_10_01_00_00_00_20_9A_FB_9A_FB_00_01_01_02_00_01
    } ),
    .DESCRIPTOR_STR1    ( {  //  64 bytes available
        352'h2C_03_67_00_69_00_74_00_68_00_75_00_62_00_2e_00_63_00_6f_00_6d_00_2f_00_57_00_61_00_6e_00_67_00_58_00_75_00_61_00_6e_00_39_00_35_00,  // "github.com/WangXuan95"
        160'h0
    } ),
    .DESCRIPTOR_STR2    ( {  //  64 bytes available
        256'h20_03_46_00_50_00_47_00_41_00_2d_00_55_00_53_00_42_00_2d_00_4d_00_6f_00_75_00_73_00_65_00,                          // "FPGA-USB-Mouse"
        256'h0
    } ),
    .DESCRIPTOR_CONFIG  ( {  // 512 bytes available
        72'h09_02_22_00_01_01_00_80_64,        // configuration descriptor
        72'h09_04_00_00_01_03_01_02_00,        // interface descriptor (bInterfaceProtocol=2 for mouse)
        72'h09_21_11_01_00_01_22_32_00,        // HID descriptor (wDescriptorLength=0x0032=50 bytes)
        56'h07_05_81_03_04_00_0a,              // endpoint descriptor (IN, bInterval=10ms)
        3832'h0
    } ),
    .EP81_MAXPKTSIZE    ( 10'h04           ),
    .DEBUG              ( DEBUG            )
) u_usbfs_core (
    .rstn               ( rstn             ),
    .clk                ( clk              ),
    .usb_dp_pull        ( usb_dp_pull      ),
    .usb_dp             ( usb_dp           ),
    .usb_dn             ( usb_dn           ),
    .usb_rstn           ( usb_rstn         ),
    .sot                (                  ),
    .sof                (                  ),
    .ep00_setup_cmd     ( ep00_setup_cmd   ),
    .ep00_resp_idx      ( ep00_resp_idx    ),
    .ep00_resp          ( ep00_resp        ),
    .ep81_data          ( in_data[7:0]     ),
    .ep81_valid         ( in_valid         ),
    .ep81_ready         ( in_ready         ),
    .ep82_data          ( 8'h0             ),
    .ep82_valid         ( 1'b0             ),
    .ep82_ready         (                  ),
    .ep83_data          ( 8'h0             ),
    .ep83_valid         ( 1'b0             ),
    .ep83_ready         (                  ),
    .ep84_data          ( 8'h0             ),
    .ep84_valid         ( 1'b0             ),
    .ep84_ready         (                  ),
    .ep01_data          (                  ),
    .ep01_valid         (                  ),
    .ep02_data          (                  ),
    .ep02_valid         (                  ),
    .ep03_data          (                  ),
    .ep03_valid         (                  ),
    .ep04_data          (                  ),
    .ep04_valid         (                  ),
    .debug_en           ( debug_en         ),
    .debug_data         ( debug_data       ),
    .debug_uart_tx      ( debug_uart_tx    )
);


endmodule
