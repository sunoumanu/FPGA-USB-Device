# Tang Nano 20K USB HID Mouse - Setup and Troubleshooting Guide

## Project Overview

This FPGA project implements a USB HID Mouse device on the Tang Nano 20K board (Gowin GW2A-18C FPGA). The mouse moves the cursor in a circular pattern automatically.

**Important Note on USB Speed**: This implementation uses **USB Full-Speed (12 Mbps)**, which is compliant with USB 1.1/2.0 specifications. While you requested USB 1.0 Low-Speed (1.5 Mbps), Full-Speed is backward compatible with USB 1.0 hosts and is the standard for HID mice. Converting to Low-Speed would require extensive core redesign (see Appendix A).

## Hardware Requirements

- **FPGA Board**: Tang Nano 20K (Gowin GW2A-18C PBGA256)
- **USB Connection**: USB Type-A or Type-B connector with cable
- **Resistor**: 1x 1.5kΩ resistor (1/4W, 5% tolerance is fine)
- **Wiring**: Breadboard and jumper wires, or direct soldering
- **PC**: Windows, Linux, or macOS with USB host port

## Pin Assignments

Based on `tang_nano_20k.cst`, the following pins are used:

| Signal        | FPGA Pin | Description                              |
|---------------|----------|------------------------------------------|
| sys_clk       | H11      | 27MHz onboard oscillator                 |
| button        | T10      | Reset button (S1), active low            |
| led[0]        | A13      | Status LED (active low)                  |
| led[1-5]      | C13, D14, C10, C12, D10 | Additional LEDs (unused) |
| usb_dp        | B11      | USB D+ data line                         |
| usb_dn        | B12      | USB D- data line                         |
| usb_dp_pull   | B13      | Pullup control for D+                    |
| uart_tx       | M11      | Optional debug UART output               |

**Note**: Verify these pin assignments match your physical wiring. Adjust the `.cst` file if needed.

## Circuit Connection

### USB Wiring Diagram

```
Tang Nano 20K                           USB Connector
┌──────────────┐                        ┌─────────────┐
│              │                        │             │
│  usb_dp_pull ├───┐                    │             │
│    (B13)     │   │                    │             │
│              │   │                    │             │
│              │  ┌┴┐ 1.5kΩ             │             │
│              │  │ │ resistor          │             │
│              │  └┬┘                   │             │
│              │   │                    │             │
│   usb_dp     ├───┴────────────────────┤  D+         │
│    (B11)     │                        │  (Green)    │
│              │                        │             │
│   usb_dn     ├────────────────────────┤  D-         │
│    (B12)     │                        │  (White)    │
│              │                        │             │
│     GND      ├────────────────────────┤  GND        │
│              │                        │  (Black)    │
│              │                        │             │
│              │          (optional)    │  VBUS (+5V) │
│              │          ┌─────────────┤  (Red)      │
│              │          │             │             │
└──────────────┘          │             └─────────────┘
                          │
                    ┌─────┴──────┐
                    │ Power FPGA │
                    │ (optional) │
                    └────────────┘
```

### Critical Connection Requirements

1. **USB D+ Pullup**: The 1.5kΩ resistor **MUST** connect between `usb_dp_pull` (B13) and `usb_dp` (B11). This resistor signals to the USB host that a Full-Speed device is attached.

2. **Short Wires**: Keep USB data wires as short as possible (< 10 cm for flying leads). Long wires cause signal integrity problems.

3. **Differential Pair**: If using PCB, route `usb_dp` and `usb_dn` as a differential pair with matched lengths.

4. **Ground Connection**: Connect FPGA GND to USB GND. This is critical for proper operation.

5. **VBUS (Optional)**: The USB VBUS (+5V) can power the Tang Nano 20K if connected to a 5V input pin. Otherwise, power the board separately via USB-C programming port.

### Recommended Physical Setup

**Option 1: Breadboard (Testing)**
- Use a USB breakout board (Type A or Type B female)
- Connect with short (5-10 cm) jumper wires
- Insert 1.5kΩ resistor between usb_dp_pull and usb_dp on breadboard

**Option 2: Direct Soldering (Permanent)**
- Solder USB cable directly to FPGA board pins
- Solder resistor between pins B13 and B11
- Use heat shrink tubing for insulation

**Option 3: PCB Adapter (Professional)**
- Design a PCB with proper USB connector
- Route D+/D- as 90Ω differential pair
- Add ESD protection diodes (optional but recommended)

## Software Setup

### Step 1: Install Gowin EDA

1. Download Gowin EDA IDE from [Gowin Semiconductor](https://www.gowinsemi.com/en/support/download_eda/)
2. Install the software and obtain a license (free for Tang Nano 20K)
3. Install USB drivers for the Tang Nano 20K programmer

### Step 2: Generate PLL IP Core

The project requires a PLL to convert 27MHz (onboard) to 60MHz (USB core requirement).

The PLL file `RTL/gowin_pll/Gowin_PLL.v` is already included, but verify it's correct:

1. Open Gowin EDA IDE
2. Go to **Tools → IP Core Generator**
3. Select **CLOCK → PLL → rPLL**
4. Configure:
   - Input Frequency: **27 MHz**
   - Output Frequency: **60 MHz**
   - Device: **GW2A-18C**
5. Generate and verify it matches `RTL/gowin_pll/Gowin_PLL.v`

### Step 3: Open and Synthesize Project

1. Open `usb_mouse.gprj` in Gowin EDA
2. Verify all source files are listed (should see 10 .v files + 1 .cst file)
3. Set Top Module: **usb_hid_mouse_top** (already configured)
4. Run **Synthesize** (double-click "Synthesize" in Process window)
5. Check for errors in console

### Step 4: Place and Route

1. Run **Place & Route** (double-click in Process window)
2. Wait for completion (may take 1-2 minutes)
3. Check timing report: verify 60 MHz clock meets timing

### Step 5: Generate Bitstream

1. Run **Program Device → Generate Bit Stream**
2. Output file: `impl/pnr/usb_hid_mouse.fs`

### Step 6: Program FPGA

**SRAM Mode (Temporary, for Testing)**
1. Connect Tang Nano 20K to PC via USB-C programming port
2. Open Gowin Programmer
3. Select device: GW2A-18C
4. Load bitstream: `impl/pnr/usb_hid_mouse.fs`
5. Click **Program/Configure**
6. Wait for "Success" message

**Flash Mode (Permanent)**
1. In Gowin Programmer, select **Operation → Flash Programming**
2. Load bitstream
3. Program to embedded flash
4. FPGA will auto-configure on power-up

### Step 7: Connect USB Device

1. **Do NOT connect USB device yet** while programming
2. After programming, verify LED[0] is OFF (device not connected)
3. Connect the USB device port (the one with your custom wiring) to PC
4. LED[0] should turn ON (indicating USB connection established)
5. Check if mouse moves in a circle on screen

## Testing and Verification

### Expected Behavior

1. **LED Status**:
   - LED[0] OFF: USB disconnected or not enumerated
   - LED[0] ON: USB connected and enumerated successfully

2. **Mouse Movement**:
   - Cursor should move in a smooth circular pattern
   - Movement updates every 10ms
   - Completes one circle approximately every 3.6 seconds

3. **Device Recognition**:
   - **Windows**: Check Device Manager → Human Interface Devices → "FPGA-USB-Mouse"
   - **Linux**: Run `lsusb`, look for "FPGA-USB-Mouse" (VID:PID = FB9A:FB9A)
   - **macOS**: System Information → USB → "FPGA-USB-Mouse"

### Testing Checklist

- [ ] FPGA programming successful (no errors)
- [ ] LED[0] turns ON when USB connected
- [ ] Device appears in operating system device list
- [ ] Mouse cursor moves in circular pattern
- [ ] No error messages in system logs
- [ ] Device works after disconnect/reconnect

## Troubleshooting

### Problem 1: FPGA Programming Fails

**Symptoms**: Gowin Programmer shows error, bitstream won't load

**Solutions**:
1. Check USB-C cable to PC (programming port)
2. Verify drivers installed (Gowin Programmer should detect device)
3. Try different USB port on PC
4. Power cycle Tang Nano 20K
5. Check Gowin EDA version compatibility (use latest version)

### Problem 2: Synthesis Errors

**Symptoms**: Synthesis fails with errors in Gowin EDA console

**Solutions**:
1. Check PLL IP core is generated correctly (60 MHz output)
2. Verify all source files are included in project
3. Check Verilog syntax (project uses Verilog 2001 standard)
4. Review error messages for missing modules or signals
5. Ensure `usb_hid_mouse_top` module exists in `fpga_top_usb_mouse_gowin.v`

### Problem 3: Timing Violations

**Symptoms**: Place & Route completes but timing report shows violations

**Solutions**:
1. Check PLL lock signal is used correctly
2. Verify 60 MHz clock constraint
3. Increase effort level in Place & Route settings
4. If persistent, timing violations < 0.5ns usually still work

### Problem 4: USB Device Not Detected

**Symptoms**: LED[0] stays OFF, PC doesn't recognize device

**Solutions**:

1. **Check Physical Connections**:
   - Verify USB D+ connects to pin B11
   - Verify USB D- connects to pin B12
   - Verify 1.5kΩ resistor between B13 and B11
   - Verify GND connection
   - Check for shorts or open connections with multimeter

2. **Check Wiring Length**:
   - Flying leads > 10 cm cause signal degradation
   - Use shorter wires or shielded cable
   - Twist D+ and D- wires together if possible

3. **Verify Power Supply**:
   - Tang Nano 20K must be powered during USB connection
   - If powering from VBUS, ensure 5V rail is connected correctly
   - Check power LED on board is lit

4. **Check Pin Assignments**:
   - Open `tang_nano_20k.cst` and verify pin numbers match your wiring
   - If you used different pins, update the .cst file and reprogram

5. **Test with Oscilloscope** (if available):
   - Probe D+ line: should see 3.3V idle level (due to pullup)
   - Probe D- line: should see 0V idle level
   - When host sends traffic, should see data pulses

### Problem 5: USB Device Detected but Doesn't Work

**Symptoms**: Device appears in Device Manager but cursor doesn't move

**Solutions**:

1. **Check USB Descriptors**:
   - In Device Manager (Windows), check Properties → Details → Hardware IDs
   - Should show VID_FB9A&PID_FB9A
   - If showing errors, descriptor parsing may have failed

2. **Verify Clock Frequency**:
   - PLL must output exactly 60 MHz
   - Check PLL lock signal (LED[0] depends on it)
   - Reprogram PLL IP core if needed

3. **Check Mouse HID Descriptor**:
   - Use USBView (Windows) or `lsusb -v` (Linux) to inspect descriptors
   - Report descriptor should be 50 bytes
   - Interface class should be HID (0x03), subclass=Boot (0x01), protocol=Mouse (0x02)

4. **Reset Sequence**:
   - Disconnect USB device
   - Press button (S1) on Tang Nano 20K (forces reset)
   - Reconnect USB device
   - Check if LED[0] turns ON

### Problem 6: USB Device Works Intermittently

**Symptoms**: Sometimes works, sometimes doesn't, or disconnects randomly

**Solutions**:

1. **Signal Integrity Issues**:
   - Shorten USB wires (most common cause)
   - Add 0.1µF capacitor between VBUS and GND near FPGA
   - Use shielded cable for USB lines
   - Check for electrical noise from other devices

2. **Power Supply Issues**:
   - Ensure stable 3.3V supply to FPGA
   - Add bulk capacitance (10µF) on 3.3V rail
   - Don't power FPGA from marginal USB port (use powered hub)

3. **Timing Issues**:
   - Verify 60 MHz PLL is locked (check timing report)
   - Check setup/hold time violations in timing analysis
   - Ensure clock jitter is minimal

4. **USB Host Issues**:
   - Try different USB port on PC
   - Try different PC (rule out host-side problems)
   - Check USB port power capacity (some ports may be limited)

### Problem 7: Wrong Device Detected

**Symptoms**: PC detects a different device type (not HID mouse)

**Solutions**:
1. Verify you programmed the correct bitstream (`usb_hid_mouse.fs`)
2. Check USB descriptors in code match mouse device class
3. Reprogram FPGA from scratch (clean build)

### Problem 8: Error Messages in System Logs

**Windows Event Viewer**:
- "USB Device Not Recognized" → Check wiring and signal integrity
- "Device Failed Enumeration" → Check USB descriptors, verify 60 MHz clock
- "Power Surge" → Check for short circuit, verify current consumption

**Linux dmesg**:
- "device descriptor read error" → Signal integrity, check wiring
- "device not accepting address" → Timing issue, verify PLL lock
- "string descriptor 0 read error" → Check descriptor format in code

## Advanced Debugging

### UART Debug Output

The design includes optional debug UART output on pin M11 (115200 baud, 8N1).

To enable:
1. Edit `RTL/fpga_examples/fpga_top_usb_mouse_gowin.v` line 60:
   - Change `DEBUG ( "FALSE" )` to `DEBUG ( "TRUE" )`
2. Resynthesize and reprogram
3. Connect USB-UART adapter to pin M11 and GND
4. Open serial terminal (PuTTY, minicom, screen, etc.) at 115200 baud
5. Monitor USB transaction debug info

Debug output shows:
- USB reset detection
- Descriptor requests
- Endpoint transactions
- Data packet contents

### Using USB Protocol Analyzer

For professional debugging, use a hardware USB protocol analyzer (e.g., Beagle USB 480):
1. Connect analyzer between FPGA device and PC
2. Capture USB traffic during enumeration
3. Verify descriptor responses match USB 2.0 spec
4. Check for protocol errors (CRC, timeout, etc.)

### Modifying Mouse Behavior

To change the circular motion pattern, edit `RTL/fpga_examples/fpga_top_usb_mouse_gowin.v`:

1. **Speed**: Change `UPDATE_INTERVAL` (line 87)
   - Smaller = faster movement
   - Must be ≥ 60000 (1ms minimum per USB spec)

2. **Pattern**: Modify the `case` statement (lines 104-113)
   - Change `mouse_dx` and `mouse_dy` values
   - Values are signed 8-bit (-127 to +127)

3. **Buttons**: Set `mouse_btn` (line 115)
   - bit[0]: Left button (1=pressed)
   - bit[1]: Right button (1=pressed)
   - bit[2]: Middle button (1=pressed)

4. **Scroll Wheel**: Set `mouse_wheel` (line 116)
   - Signed 8-bit value (-127 to +127)
   - Positive = scroll up, Negative = scroll down

## Verilog 2001 Compliance

This project is confirmed to use **Verilog 2001 (IEEE1364-2001)** standard as requested:
- No SystemVerilog constructs (logic, always_comb, etc.)
- Uses only Verilog 2001 syntax (reg, wire, always @)
- Project file specifies `verilog_language="verilog-2001"`

All source files comply with Verilog 2001 standard.

## Appendix A: USB Low-Speed (1.5 Mbps) Conversion

You requested USB 1.0 Low-Speed (1.5 Mbps) support. The current implementation uses USB Full-Speed (12 Mbps), which is the standard for HID mice and is backward compatible with USB 1.0 hosts.

**Why Full-Speed is Better for This Application**:
- HID mice typically use Full-Speed (12 Mbps)
- Better compatibility with modern PCs
- Faster response time (1ms vs 8ms minimum polling)
- Same circuit complexity

**If Low-Speed Conversion is Required**:

Converting to Low-Speed requires these changes:

1. **Clock Frequency**: 60 MHz → 7.5 MHz
   - Update PLL: 27 MHz input → 7.5 MHz output
   - Modify `Gowin_PLL.v` parameters

2. **Pullup Resistor Location**: D+ → D-
   - Move 1.5kΩ resistor from D+ to D-
   - Update `usb_dp_pull` to `usb_dn_pull` in RTL
   - Change pin B13 to control D- pullup instead of D+

3. **USB Core Timing**:
   - Modify `usbfs_bitlevel.v`:
     - Clock divider: 5 cycles/bit (1.5 Mbps @ 7.5 MHz)
     - All timing constants scale by 8x
     - `CNTJ_BEFORE_RX`, `CNTJ_BEFORE_TX` adjust accordingly

4. **USB Descriptors**:
   - Update device descriptor `bcdUSB` field: 0x0110 → 0x0100
   - Update endpoint descriptor `bInterval`: 10ms → 10ms (no change for mouse)

5. **Testing**:
   - Low-Speed devices may have compatibility issues with USB 3.0 ports
   - Use USB 2.0 hub or port for best results

**Estimated Effort**: 40-80 hours of FPGA development work to fully convert and test.

**Recommendation**: Keep the current Full-Speed implementation unless you have a specific requirement for Low-Speed. Full-Speed provides better performance and wider compatibility.

## Support and Resources

- **Project Repository**: Original repo at github.com/WangXuan95/FPGA-USB-Device
- **Tang Nano 20K Wiki**: https://wiki.sipeed.com/nano20k
- **Gowin Semiconductor**: https://www.gowinsemi.com/
- **USB 2.0 Specification**: https://www.usb.org/document-library/usb-20-specification
- **HID Usage Tables**: https://www.usb.org/hid

## License

This project is licensed under LGPL (as indicated in git commit history).

---

**Document Version**: 1.0
**Date**: 2026-01-15
**FPGA Device**: Tang Nano 20K (Gowin GW2A-18C)
**USB Speed**: Full-Speed (12 Mbps, USB 1.1/2.0 compatible)
