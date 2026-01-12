
//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top_usb_mouse_gowin
// Type    : synthesizable, fpga top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: example for usb_mouse_top on Gowin Tang Nano 20k
//--------------------------------------------------------------------------------------------------------

module fpga_top_usb_mouse_gowin (
    // clock
    input  wire        sys_clk,      // connect to the onboard 27MHz oscillator
    // reset button
    input  wire        button,       // connect to a button (S1 or S2), 0=pressed
    // LED
    output wire [5:0]  led,          // 6 LEDs on Tang Nano 20k (active low usually)
    // USB signals
    output wire        usb_dp_pull,  // connect to USB D+ by an 1.5k resistor
    inout              usb_dp,       // connect to USB D+
    inout              usb_dn,       // connect to USB D-
    // debug output info
    output wire        uart_tx       // Optional debug UART
);

    // Turn off other LEDs, use led[0] for status
    assign led[5:1] = 5'b11111; 
    wire led_status;
    assign led[0] = ~led_status; // Invert because LEDs are active low

    //-------------------------------------------------------------------------------------------------------------------------------------
    // Clock Generation: 27MHz -> 60MHz
    // You MUST generate this IP using Gowin EDA IP Core Generator
    // 1. Tools -> IP Core Generator -> CLOCK -> PLL
    // 2. Input Freq: 27MHz
    // 3. Output Freq: 60MHz
    // 4. Uncheck "Reset" and "Locked" if not used, or map them
    //-------------------------------------------------------------------------------------------------------------------------------------
    wire clk60mhz;
    wire pll_lock;
    
    // Instantiation of the generated PLL
    // NOTE: The name 'Gowin_PLL' and port names depend on your IP generation settings.
    // You might need to change this to match your generated file (e.g., "Gowin_PLL u_pll (...)")
    Gowin_PLL u_pll (
        .clkout(clk60mhz), // Output 60MHz
        .lock(pll_lock),   // PLL Lock status
        .clkin(sys_clk)    // Input 27MHz
    );

    //-------------------------------------------------------------------------------------------------------------------------------------
    // USB-HID mouse device
    //-------------------------------------------------------------------------------------------------------------------------------------

    reg        mouse_update = 1'b0;
    reg [ 7:0] mouse_dx = 8'h0;
    reg [ 7:0] mouse_dy = 8'h0;
    reg [ 2:0] mouse_btn = 3'b000;
    reg [ 7:0] mouse_wheel = 8'h0;

    usb_mouse_top #(
        .DEBUG           ( "FALSE"             )
    ) usb_mouse_i (
        .rstn            ( pll_lock & button ), // Reset when PLL not locked or button pressed
        .clk             ( clk60mhz            ),
        // USB signals
        .usb_dp_pull     ( usb_dp_pull         ),
        .usb_dp          ( usb_dp              ),
        .usb_dn          ( usb_dn              ),
        // USB reset output
        .usb_rstn        ( led_status          ),   // 1: connected , 0: disconnected
        // HID mouse control signals
        .mouse_dx        ( mouse_dx            ),   // X movement
        .mouse_dy        ( mouse_dy            ),   // Y movement
        .mouse_btn       ( mouse_btn           ),   // Button states
        .mouse_wheel     ( mouse_wheel         ),   // Scroll wheel
        .mouse_update    ( mouse_update        ),   // Update trigger
        // debug output info
        .debug_en        (                     ),
        .debug_data      (                     ),
        .debug_uart_tx   ( uart_tx             )
    );

    //-------------------------------------------------------------------------------------------------------------------------------------
    // Move mouse in a circular pattern
    //-------------------------------------------------------------------------------------------------------------------------------------

    localparam CIRCLE_STEPS = 360;           
    localparam UPDATE_INTERVAL = 600000;     // 10ms at 60MHz

    reg [31:0] count = 0;                    
    reg [ 8:0] angle = 0;                    

    always @ (posedge clk60mhz) begin
        if (count < UPDATE_INTERVAL) begin
            count <= count + 1;
            mouse_update <= 1'b0;
        end else begin
            count <= 0;
            mouse_update <= 1'b1;
            
            // Update angle
            angle <= (angle >= CIRCLE_STEPS - 1) ? 9'd0 : angle + 9'd1;
            
            // Simple circular motion
            case (angle[8:6])
                3'd0: begin mouse_dx <=  8'd5; mouse_dy <=  8'd0; end  // East
                3'd1: begin mouse_dx <=  8'd4; mouse_dy <=  8'd4; end  // Northeast
                3'd2: begin mouse_dx <=  8'd0; mouse_dy <=  8'd5; end  // North
                3'd3: begin mouse_dx <= -8'd4; mouse_dy <=  8'd4; end  // Northwest
                3'd4: begin mouse_dx <= -8'd5; mouse_dy <=  8'd0; end  // West
                3'd5: begin mouse_dx <= -8'd4; mouse_dy <= -8'd4; end  // Southwest
                3'd6: begin mouse_dx <=  8'd0; mouse_dy <= -8'd5; end  // South
                3'd7: begin mouse_dx <=  8'd4; mouse_dy <= -8'd4; end  // Southeast
            endcase
            
            mouse_btn <= 3'b000;
            mouse_wheel <= 8'h0;
        end
    end

endmodule
