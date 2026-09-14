# Multi-Port Mode Analysis and Measurement Data for a mm-Wave QVCO

## Overview

This repository provides MATLAB analysis scripts, extracted multi-port S-parameter data, and measured phase-noise data for a mm-wave quadrature voltage-controlled oscillator (QVCO).

The repository is intended to support reproducible analysis of the two quadrature oscillation modes using extracted 9-port S-parameters. The analysis applies two quadrature current excitations,

$$
i_Q=-j i_I
$$

and

$$
i_Q=+j i_I,
$$

to evaluate the two mode-dependent responses.

The released materials include:

- mode-dependent $Z_{GS}$ calculation;
- effective parallel resistance $R_p$;
- open-loop $Q$;
- prediction of the two quadrature-mode frequencies;
- model validation using a reference QVCO dataset;
- measured phase-noise data across the tuning range.

---

## Repository Structure

```text
.
├── README.md
├── .gitignore
│
├── model_matlab/
│   ├── proposed_QVCO/
│   │   ├── calc_zgs.m
│   │   ├── calc_rp.m
│   │   ├── calc_open_loop_q.m
│   │   ├── predict_mode_frequency.m
│   │   ├── QVCO_Mine_SW31_Cs_*.s9p
│   │   └── QVCO_Mine_wi_var_SW*.s9p
│   │
│   └── reference_QVCO_JSSC23_xichen/
│       ├── validate_model_with_reference_QVCO.m
│       ├── QVCO_Xichen_Cs_nch_lvt_dnw_*.s9p
│       └── supporting PDF results
│
└── measurement/
    └── phase_noise/
        ├── csv/
        │   └── PN_AVDD0p60_VG0p50_XCORR1000_SW*.CSV
        └── screenshots/
            └── PN_AVDD0p60_VG0p50_XCORR1000_SW*.PNG
```

---

## Multi-Port Analysis Method

The extracted passive network is represented by a 9-port S-parameter model.

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

For the two quadrature excitations, the model forms two effective branches corresponding to the two physical quadrature modes.

The scripts use a consistent port mapping and mode-excitation convention throughout the repository.

---

## MATLAB Scripts

### `calc_zgs.m`

Calculates the mode-dependent gate-to-source transimpedance $Z_{GS}$ from the extracted 9-port S-parameters.

The main quantity is

$$
Z_{GS}=\frac{V_{GS}}{I_{DS}}.
$$

The script evaluates both quadrature branches and plots the corresponding $Z_{GS}$ response versus frequency.

---

### `calc_rp.m`

Calculates the mode-dependent effective parallel resistance $R_p$ at the corresponding oscillation frequency.

The implemented quantity is based on the real part of the drain-voltage response under the total quadrature current excitation:

$$
R_p=
\left|
\mathrm{Re}
\left\{
\frac{V_D}{I_{DS}}
\right\}
\right|.
$$

The two quadrature branches are evaluated separately.

---

### `calc_open_loop_q.m`

Calculates the open-loop $Q$ from the local slope of the effective mode phase around the oscillation frequency.

The implemented definition is

$$
Q=
\frac{f_0}{2}
\left|
\frac{d\phi_K}{df}
\right|,
$$

where $\phi_K$ is expressed in radians and the derivative is evaluated locally around the corresponding oscillation frequency.

---

### `predict_mode_frequency.m`

Predicts the two quadrature-mode frequencies from the extracted 9-port S-parameter data.

The effective mode responses are formed as

$$
K_+=K_{II}+jK_{IQ},
$$

and

$$
K_-=K_{II}-jK_{IQ}.
$$

The predicted mode frequencies are obtained from the corresponding phase condition and are compared with the oscillation-frequency reference used by the script.

---

### `validate_model_with_reference_QVCO.m`

Applies the same multi-port analysis method to a reference QVCO dataset.

This script is used to examine the mode-dependent behavior of the reference design and compare the calculated quantities with the corresponding simulation references.

---

## S-Parameter Data

The repository contains extracted 9-port Touchstone files (`.s9p`) used by the MATLAB scripts.

### $C_S$ sweep

Files matching

```text
QVCO_Mine_SW31_Cs_*.s9p
```

are used to evaluate how the two modes evolve as the source capacitance $C_S$ changes.

Typical extracted quantities include:

- $Z_{GS}$;
- $R_p$;
- open-loop $Q$;
- phase shifts;
- mode-transition behavior.

### Tuning-bank sweep

Files matching

```text
QVCO_Mine_wi_var_SW*.s9p
```

are used for mode-frequency prediction across the tuning range.

### Reference-QVCO sweep

Files matching

```text
QVCO_Xichen_Cs_nch_lvt_dnw_*.s9p
```

are used for validation of the same analysis framework on the reference QVCO dataset.

---

## Measurement Data

Measured phase-noise data are provided as instrument-exported CSV files in

```text
measurement/phase_noise/csv/
```

Corresponding instrument screenshots are provided in

```text
measurement/phase_noise/screenshots/
```

The released dataset covers tuning-bank codes `SW00` through `SW31`.

Measurement condition:

- AVDD = 0.60 V
- VG = 0.50 V
- XCORR factor = 1000

Typical data units are:

- frequency offset: Hz;
- phase noise: dBc/Hz.

The metadata contained in each CSV file should be treated as the authoritative record of the instrument acquisition settings. The PNG files are included only as visual references; the CSV files should be used for numerical analysis.

---

## Requirements

The MATLAB scripts require:

- MATLAB;
- RF Toolbox, for `sparameters()` and Touchstone-file import.

The scripts are written for direct execution as MATLAB scripts with local helper functions.

---

## Usage

Clone or download the repository, then open MATLAB and set the desired analysis folder as the current working directory.

For the proposed QVCO analysis:

```matlab
cd model_matlab/proposed_QVCO
```

Run the desired script:

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

For the reference-QVCO validation:

```matlab
cd model_matlab/reference_QVCO_JSSC23_xichen
validate_model_with_reference_QVCO
```

The required `.s9p` files are stored in the same folders as the corresponding scripts.

---

## Mode Convention

The two mathematical quadrature excitations are

```text
q = -j
q = +j
```

and are mapped to the two physical quadrature modes according to the convention implemented in each script.

The selected and unselected branches are explicitly identified in the MATLAB code and generated plots.

---

## Reproducibility Notes

- The S-parameter files are the extracted network data used by the released MATLAB scripts.
- The MATLAB scripts contain the numerical post-processing used to obtain the released model results.
- The phase-noise CSV files are direct instrument exports.
- The phase-noise screenshots are included only as visual references.
- No foundry PDK, transistor-level design database, or proprietary process files are included.

---

## Contact / Citation

Author and publication information may be added after the anonymous review period, if appropriate.

A formal citation entry can also be added after publication.
