<p align="center">
  <img src="doc/pictures/logo.png" alt="BenchmarkBeholder Logo" width="100%"/>
</p>

<h1 align="center">BenchmarkBeholder (BBH)</h1>
<p align="center">
  <b>Test any workload, explore every parameter combination, and uncover the performance sweet spot.</b>
</p>

---

**BBH** is a universal benchmarking tool for <b>any workload</b> — from AI models and APIs to databases, filesystems, GPUs, and beyond.  
It runs <b>all parameter combinations</b> for your task, measures target metrics, and reveals the optimal setup, trends, and bottlenecks — all in a single sweep.

---

## 🚀 What is BBH?

BBH systematically benchmarks your workload across all combinations of its input parameters.  
It helps you:

- Tune your system for maximum performance.
- Choose between competing models, tools, or configurations.
- Validate that your system is truly optimized.

---

## 💡 Example Use Case

You're building a chatbot. With BBH, you can:

- Compare AI models for speed and quality.
- Evaluate GPUs by performance-to-cost.
- Test RAM or storage setups (e.g. for RAG caching).
- Choose the best infrastructure combo overall.

---

## ✨ Key Features

- **Reproducible** — Stores all configs + metrics.
- **Extensible** — Works with any workload or platform (AWS, Azure, OCI).
- **Accumulative** — Saves results in CSV for long-term tracking.
- **Visual-friendly** — Compatible with Excel, Power BI, Tableau, etc.

---

## ⚡ Quick Start

```bash
./bbh ./workloads/ping_dns.json

