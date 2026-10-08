# DSP-Based Speech Enhancement System for Hearing Assistance

## Overview

This project is a MATLAB-based speech enhancement system designed to reduce background noise and improve speech clarity in noisy environments.

The system takes a noisy audio file as input, analyzes the speech and noise components using Digital Signal Processing (DSP) techniques, suppresses unwanted noise, and produces an enhanced speech output.

The project is designed as an academic prototype demonstrating the practical application of DSP in speech processing and hearing assistance.

---

## Objectives

- Reduce background noise from speech recordings
- Improve speech clarity and intelligibility
- Analyze speech in both time and frequency domains
- Visualize the effect of noise reduction
- Provide an easy-to-use MATLAB interface
- Demonstrate practical applications of DSP

---

## How It Works

The system follows this basic processing pipeline:

**Noisy Audio → Pre-processing → Framing & Windowing → FFT → Noise Estimation → Noise Suppression → IFFT → Filtering → Enhanced Speech**

### Main DSP Techniques Used

- Framing and Windowing
- Hamming Window
- Fast Fourier Transform (FFT)
- Noise Spectrum Estimation
- Spectral Subtraction
- Wiener-style Filtering
- Frequency-selective Noise Suppression
- Inverse FFT (IFFT)
- Overlap-Add Reconstruction
- Digital Filtering

---

## Analysis

The application provides visual analysis of the audio, including:

- Original Speech Waveform
- Enhanced Speech Waveform
- Original vs Enhanced Comparison
- FFT / Frequency Spectrum
- Spectrogram
- Noise Suppression Analysis
- DSP Processing Explanation

These graphs help visualize how the signal changes before and after enhancement.

---

## User Controls

The application provides controls for adjusting the enhancement process:

### Noise Profile Duration
Defines the initial portion of the audio used to estimate background noise.

### Noise Suppression
Controls the strength of background noise reduction.

### Speech Preservation
Controls how strongly speech components are preserved during noise suppression.

The user can adjust these parameters to find a suitable balance between **noise reduction and speech quality**.

---

## Input & Output

### Input
A noisy speech recording containing:

- Speech
- Background noise

For best results, the beginning of the recording should preferably contain a short noise-only section for noise estimation.

### Output

The system generates:

- Enhanced speech audio
- Waveform comparison
- Frequency-domain analysis
- Spectrogram comparison
- DSP processing visualizations

The enhanced audio can also be saved for further use.

---

## Technologies Used

- **MATLAB**
- **Digital Signal Processing**
- **Speech Signal Processing**
- **FFT / IFFT**
- **Digital Filtering**
- **Audio Signal Analysis**

---

