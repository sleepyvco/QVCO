# Multi-Port Mode Analysis and Measurement Data for a mm-Wave QVCO

## Overview

This repository provides MATLAB analysis scripts, extracted multi-port S-parameter data, and measured phase-noise data for a mm-wave quadrature voltage-controlled oscillator (QVCO).

The main purpose of the repository is to support reproducible analysis of the two quadrature oscillation modes using extracted 9-port S-parameters. The analysis applies two quadrature current excitations,

\[
i_Q=-j\,i_I
\]

and

\[
i_Q=+j\,i_I,
\]

to evaluate the two mode-dependent responses.

The released materials include:

- mode-dependent \(Z_{GS}\) calculation;
- effective parallel resistance \(R_p\);
- open-loop \(Q\);
- prediction of the two quadrature-mode frequencies;
- model validation using a reference QVCO dataset;
- measured phase-noise data across the tuning range.

---

## Suggested Repository Structure

```text
.
├── README.md
│
├── model/
│   ├── proposed_qvco/
│   │   ├── calc_zgs.m
│   │   ├── calc_rp.m
│   │   ├── calc_open_loop_q.m
│   │   ├── predict_mode_frequency.m
│   │   └── sparameters/
│   │       ├── cs_sweep/
│   │       └── bank_sweep/
│   │
│   └── reference_QVCO_JSSC23_xichen/
│       ├── validate_model_with_reference_qvco.m
│       ├── sparameters/
│       └── results/
│
└── measurement/
    └── phase_noise/
        ├── csv/
        └── screenshots/
```

The exact folder names may be changed as long as the paths used in the MATLAB scripts are updated consistently.

---

## Multi-Port Analysis Method

The extracted network is represented by a 9-port S-parameter file.

The analysis flow is:

```text
Extracted 9-port S-parameters
            ↓
        S-to-Y conversion
            ↓
Removal of the real MOS admittance contribution
            ↓
Construction of the I/Q excitation basis
            ↓
      i_Q = ±j i_I
            ↓
   Two mode-dependent responses
            ↓
 Z_GS / R_p / open-loop Q / mode frequency
```

For the two quadrature excitations, the model forms two effective branches that correspond to the two physical quadrature modes.

The scripts use the same port mapping and mode-excitation convention throughout the repository.

---

## MATLAB Scripts

### `calc_zgs.m`

Calculates the mode-dependent gate-to-source transimpedance \(Z_{GS}\) from the extracted 9-port S-parameters.

The script evaluates both quadrature branches and plots the corresponding \(Z_{GS}\) response versus frequency.

Main quantity:

\[
Z_{GS}=\frac{V_{GS}}{I_{DS}}.
\]

---

### `calc_rp.m`

Calculates the mode-dependent effective parallel resistance \(R_p\) at the corresponding oscillation frequency.

The current implementation uses the drain-voltage response under the total quadrature current excitation:

\[
R_p=\left|\operatorname{Re}\left\{\frac{V_D}{I_{DS}}\right\}\right|.
\]

The two quadrature branches are evaluated separately.

---

### `calc_open_loop_q.m`

Calculates the open-loop \(Q\) from the local slope of the effective mode phase around the oscillation frequency.

The implemented definition is

\[
Q=\frac{f_0}{2}
\left|
\frac{d\phi_K}{df}
\right|,
\]

where \(\phi_K\) is expressed in radians and the derivative is evaluated locally around the corresponding oscillation frequency.

---

### `predict_mode_frequency.m`

Predicts the two quadrature-mode frequencies from the extracted 9-port S-parameter data.

The effective mode responses are formed as

\[
K_+=K_{II}+jK_{IQ},
\]

and

\[
K_-=K_{II}-jK_{IQ}.
\]

The predicted mode frequencies are obtained from the corresponding phase condition and are compared with the simulated oscillation-frequency reference used by the script.

---

### `validate_model_with_reference_qvco.m`

Applies the same multi-port analysis method to a reference QVCO dataset.

This script is intended to demonstrate the behavior of the model on a second design and to compare the calculated mode-dependent quantities with the reference simulation results.

---

## S-Parameter Data

The repository contains extracted 9-port Touchstone files (`.s9p`) used by the MATLAB scripts.

Two main sweeps are used:

### \(C_S\) sweep

These files are used to evaluate how the two modes evolve as the source capacitance \(C_S\) changes.

Typical quantities obtained from this sweep include:

- \(Z_{GS}\);
- \(R_p\);
- open-loop \(Q\);
- phase shifts;
- mode transition behavior.

### Tuning-bank sweep

These files are used to predict the two mode frequencies across the tuning range.

If the S-parameter files are moved into subfolders, update the file paths in the corresponding MATLAB scripts before running them.

---

## Measurement Data

Measured phase-noise data are provided as instrument-exported CSV files.

Corresponding screenshots may also be included for visual reference.

The phase-noise dataset covers multiple tuning-bank codes across the oscillator tuning range.

The measurement filenames contain the relevant bias condition and tuning-bank code.

For the released dataset:

- AVDD = 0.60 V
- VG = 0.50 V

The CSV files contain the frequency-offset axis and measured phase-noise values exported from the phase-noise analyzer.

Typical units are:

- frequency offset: Hz;
- phase noise: dBc/Hz.

The instrument metadata contained in each CSV file should be treated as the authoritative record of the acquisition settings.

---

## Requirements

The MATLAB scripts require:

- MATLAB;
- RF Toolbox, for `sparameters()` and Touchstone-file import.

The scripts were written for direct execution as MATLAB scripts with local helper functions.

---

## Usage

1. Place the required `.s9p` files in the folder expected by the corresponding script, or update the file paths in the script.
2. Open MATLAB and set the repository folder as the working directory.
3. Run the desired script.

For example:

```matlab
calc_zgs
```

```matlab
calc_rp
```

```matlab
calc_open_loop_q
```

```matlab
predict_mode_frequency
```

The scripts generate plots directly in MATLAB.

---

## Mode Convention

The two mathematical quadrature excitations are

```text
q = -j
q = +j
```

and are mapped to the two physical quadrature modes according to the mode convention used in each dataset.

The scripts explicitly label the selected and unselected physical modes so that the branch assignment can be checked directly from the source code.

---

## Reproducibility Notes

- The S-parameter data are the extracted network data used by the released MATLAB scripts.
- The MATLAB scripts contain the numerical post-processing required to obtain the released model results.
- The phase-noise CSV files are direct instrument exports.
- Screenshots are provided only as visual references; the CSV files should be used for numerical analysis.
- No foundry PDK, transistor-level design database, or proprietary process files are included.

---

## Contact / Citation

Author and publication information may be added after the anonymous review period, if appropriate.

A formal citation entry can also be added after publication.
