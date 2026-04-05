
A MATLAB-based simulation project for wireless communication systems, designed to reproduce the technologies and algorithms presented in academic papers.

## Project Overview

This project includes a complete simulation framework for wireless communication systems, implementing core communication techniques in MATLAB such as QPSK modulation/demodulation, channel estimation, time-domain equalization, and interference cancellation. It is suitable for learning and researching various signal processing algorithms in wireless communication systems.

## Main Features

- **QPSK Modulation/Demodulation**: Implementation of QPSK signal modulation and demodulation
- **Channel Estimation**: Provides channel estimation algorithms to obtain channel state information
- **Time-Domain Equalization**: Implements RLS DFE adaptive equalizer
- **Time Reversal**: Adaptive time-reversal technique
- **Interference Cancellation**: Successive Interference Cancellation (SIC) technique
- **Performance Evaluation**: Computes system bit error rate (BER)

## File Description

| File | Function |
|------|----------|
| run_main.m | Main program entry point |
| qpsk_mod.m | QPSK modulation |
| qpsk_demod.m | QPSK demodulation |
| channel_estimation.m | Channel estimation |
| rls_dfe_equalizer.m | RLS DFE equalizer |
| adaptive_time_reversal.m | Adaptive time reversal |
| time_reversal.m | Time reversal technique |
| calc_ber.m | BER calculation |
| true_equivalent_channel.m | Equivalent channel |

## Usage Instructions

Run the main program `run_main.m` directly in the MATLAB environment to initiate the simulation.

```matlab
% Run in the MATLAB command window
run_main
```

## System Requirements

- MATLAB R2016a or higher
- Signal Processing Toolbox

## Directory Structure

```
falunwen/
└── paper reproduction/
    └── First/          # Main simulation code directory
```

## Technical Background

This project implements several key technologies in wireless communications:
- LFM signal synchronization
- QPSK baseband modulation
- Adaptive filtering and equalization
- Time-domain signal processing

For detailed implementation and algorithm descriptions, refer to the individual subroutines.