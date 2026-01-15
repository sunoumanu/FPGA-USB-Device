
module Gowin_PLL (clkout, lock, clkin);

    output clkout;
    output lock;
    input clkin;

    // GW2A-18C PLL Parameters
    // CLKIN = 27MHz
    // Target CLKOUT = 60MHz
    // Using FCLKOUT = FCLKIN * (FBDIV_SEL+1) / (IDIV_SEL+1) / ODIV_SEL
    // 60 = 27 * 40 / 2 / 9 = 1080 / 2 / 9 = 540 / 9 = 60MHz
    // VCO = FCLKIN * (FBDIV_SEL+1) / (IDIV_SEL+1) = 27 * 40 / 2 = 540MHz

    rPLL #(
        .FCLKIN("27"),
        .DEVICE("GW2A-18C"),
        .DYN_IDIV_SEL("false"),
        .IDIV_SEL(1),      // Input divider = 2
        .DYN_FBDIV_SEL("false"),
        .FBDIV_SEL(39),    // Feedback divider = 40
        .DYN_ODIV_SEL("false"),
        .ODIV_SEL(9)       // Output divider = 9
    ) pll_inst (
        .CLKOUT(clkout),
        .LOCK(lock),
        .CLKOUTP(),
        .CLKOUTD(),
        .CLKOUTD3(),
        .RESET(1'b0),
        .RESET_P(1'b0),
        .CLKIN(clkin),
        .CLKFB(1'b0),
        .FBDSEL(6'b0),
        .IDSEL(6'b0),
        .ODSEL(6'b0),
        .PSDA(4'b0),
        .DUTYDA(4'b0),
        .FDLY(4'b0)
    );

endmodule
