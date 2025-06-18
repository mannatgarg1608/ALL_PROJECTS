AES Decryption System with Basys 3 Display
Overview
A VHDL implementation of AES-128 decryption with real-time display on Basys 3 FPGA. Implements inverse AES operations in reverse encryption order with finite state machine (FSM) control and time-multiplexed display.


Key Features

text
- 128-bit block decryption with 10-round key expansion
- Inverse cipher operations: InvSubBytes, InvShiftRows, InvMixColumns
- BRAM/ROM memory interfaces for ciphertext and round keys
- Persistence of Vision (POV) display with time-scrolling
- 100 MHz clock domain management

  src/  
├── controller/  
│   ├── fsm_controller.vhd        # Main FSM  
│   └── clock_divider.vhd         # 100MHz → 1KHz display clock  
├── crypto/  
│   ├── inv_sub_bytes.vhd         # Inverse S-Box substitution  
│   ├── inv_shift_row.vhd         # Row shifting logic  
│   ├── inv_mix_columns.vhd       # GF(2^8) column mixing  
│   └── add_round_key.vhd         # XOR with round keys  
├── memory/  
│   ├── rom_access.vhd            # Ciphertext ROM interface  
│   └── bram_access.vhd           # Round key BRAM controller  
└── display/  
    ├── seven_seg_decoder.vhd     # Hex to 7-segment  
    └── scroll_controller.vhd     # Time-multiplexed display


FSM Control Logic 

States:

IDLE → INIT_READ → INITIAL_XOR → INV_SHIFT_ROWST →  
INV_SUB_BYTEST → ROUND_KEY_XOR → INV_MIX_COLST →  
CHECK_ROUND → FINAL_XOR → DISPLAY  


Key Design Choices:

4×32-bit data registers for state matrix storage
8-cycle latency compensation for BRAM access
Round key addressing: 4*round_num + byte_position
16-phase clock management for display refresh


Cryptographic Modules
InvMixColumns :

vhdl
-- GF(2^8) multiplication using irreducible polynomial x^8 + x^4 + x^3 + x + 1
col0 <= xtime_0E(s0) xor xtime_0B(s1) xor xtime_0D(s2) xor xtime_09(s3);
InvShiftRows :

text
Row 0: No shift  
Row 1: Right shift 1 byte  
Row 2: Right shift 2 bytes  
Row 3: Right shift 3 bytes  
Display Subsystem 
POV Specifications:

4-digit 7-segment multiplexing

20ms refresh rate per digit

Circular buffer for plaintext ASCII

Hex-to-segment decoder with blanking control

Simulation & Verification
Testbench Structure:

text
$ make sim  
▶ inv_sub_bytes_tb: S-Box lookup verification  
▶ inv_mix_columns_tb: Matrix transformation checks  
▶ fsm_controller_tb: Full decryption cycle test  
Sample Waveform (FSM):
![Simulation showing state transitions and data_reg updates transition every 8 clock cycles with BRAM latency compensation *

Setup Instructions
Requirements:

Vivado 2024.1
Basys 3 Board (Artix-7 FPGA)

COE files:
ciphertext.coe: 16-byte blocks in hex
roundkeys.coe: 44×4-byte round keys



