# 🩸 FeSa — Salivary Anemia Monitoring WebUSB Companion App

> **Accubits Invent Lab** | Point-of-Care Non-Invasive Anemia Diagnostic Platform

[![Live WebUSB App](https://img.shields.io/badge/Live_App-GitHub_Pages-0077b6?style=for-the-badge&logo=googlechrome)](https://kezinb.github.io/fesa-app-demo/)
[![Hardware](https://img.shields.io/badge/Hardware-Raspberry_Pi_RP2040-c51a4a?style=for-the-badge&logo=raspberrypi)](https://www.raspberrypi.com/products/rp2040/)

---

## 🌟 Overview

**FeSa** (Ferritin Salivary Diagnostic Platform) is a screenless, buttonless point-of-care medical device designed to measure salivary ferritin concentrations for rapid, non-invasive anemia screening. 

This repository hosts the **WebUSB / Web Serial Companion Application**, allowing healthcare workers and patients to connect the FeSa USB-C reader directly to an Android smartphone or laptop web browser to view real-time diagnostic curves.

🔗 **Live Application URL:** [https://kezinb.github.io/fesa-app-demo/](https://kezinb.github.io/fesa-app-demo/)

---

## ⚡ Key Features

- **Direct USB OTG Serial Connection:** Uses native browser [Web Serial API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Serial_API) — zero mobile app installation required.
- **Real-Time Binding Kinetics:** Dual-axis plotting of paper rGO strip resistance ($R_{\text{strip}}$) and analog front-end voltage ($V_{\text{out}}$).
- **Clinical Metrics:** Calculates live **Salivary Ferritin (ng/mL)** estimation and **Anemia Risk Score (%)**.
- **1-Click CSV Log Export:** Full 30-second measurement curve telemetry export for patient records.
- **Color-Coded Status Guidance:** Automatic status pill feedback (Ready / Measuring / Low Risk / High Risk).

---

## 🛠️ Hardware System Architecture

```text
┌──────────────────────────────────────────────────────────┐
│                      FeSa Reader                         │
│                                                          │
│   ┌───────────────────┐        ┌──────────────────────┐  │
│   │ Waveshare RP2040  │        │ MCP3425A0T-E/CH      │  │
│   │ (USB CDC Serial)  │ ◄I2C─► │ 16-Bit SOT-23-6 ADC │  │
│   └─────────┬─────────┘        └──────────┬───────────┘  │
│             │ SPI                         │              │
│             ▼                             │              │
│   ┌───────────────────┐                   │              │
│   │ AD5160 (50k Rref) │ ◄─────────────────┘              │
│   └─────────┬─────────┘ (Node V_out)                     │
└─────────────┼────────────────────────────────────────────┘
              │ (Card-edge slot)
              ▼
┌───────────────────────────────┐
│ Paper-based rGO Sensor Strip  │ ◄── Saliva Sample (~20–50 µL)
└───────────────────────────────┘
```

- **MCU:** Waveshare RP2040-Zero (Dual ARM Cortex-M0+ @ 133MHz).
- **ADC:** Microchip MCP3425A0T-E/CH (16-Bit Delta-Sigma I2C ADC, 2.048V internal ref).
- **Auto-Range Digipot:** Analog Devices AD5160BRJZ50 (256-Position 50kΩ SPI Digital Potentiometer).
- **Sensor Interface:** Disposable card-edge paper rGO sensor strip.

---

## 🚀 QuickStart Guide for Android & Desktop

1. Connect the **FeSa Reader** to your Android Smartphone or PC using a **USB Type-C OTG cable**.
2. Open **Google Chrome** or **Microsoft Edge**.
3. Enable Web Serial API (Android Chrome only):
   - Navigate to `chrome://flags`
   - Set **Experimental Web Platform features** to **Enabled** $\to$ Relaunch browser.
4. Open the Web App: **[https://kezinb.github.io/fesa-app-demo/](https://kezinb.github.io/fesa-app-demo/)**
5. Click **🔌 Connect USB** $\to$ Select **RP2040 / USB Serial Device** $\to$ Click **Connect**.

---

## 📄 License & Organization

Developed by **Accubits Invent Lab**  
Lead Developer: *Kezin B Wilson*  
All rights reserved © 2026.
