# Astral Observer 🌌

A MATLAB-based UFO sightings visualization and analysis application. Explore over 80,000 documented sightings through interactive maps, 3D globes, and predictive analytics.

## Quick Start

```matlab
launch_app
```

That's it. The application handles everything else.

## Features

### Visualizations
- **Map View** — Geographic scatter plot with shape-coded markers
- **3D Globe** — Interactive Earth with topographic texture and hotspot overlay
- **Shape Distribution** — Pie chart of UFO shapes (top 10 + others)
- **Time Analysis** — Yearly trends, monthly patterns, hourly distribution
- **Word Cloud** — Common terms from sighting descriptions

### Analytics
- **Stats Dashboard** — Total sightings, average duration, most common shapes, date range
- **Top Cities** — Horizontal bar chart of UFO hotspots
- **Prediction Engine** — Machine learning models (Decision Tree & Naive Bayes) to estimate sighting probability

### Interactive
- **Random Sighting** — Explore individual reports with full details
- **Rotating Globe** — Mouse-controlled 3D Earth visualization
- **Animated UI** — Pulsing title with neon glow effect

## Project Structure

```
astral-observer/
├── UFOVisualizerApp.m      # Main application (App Designer)
├── launch_app.m            # Quick launcher
├── bg.jpeg                 # Welcome screen background
├── dataset/
│   ├── ufo_optimized.mat   # Processed sighting data
│   ├── ufo_model_ct.mat    # Decision Tree model
│   └── ufo_model_nb.mat    # Naive Bayes model
├── preprocess_data.m       # Data cleaning script
├── train_ufo_model.m       # Decision Tree training
└── train_ufo_model_nb.m    # Naive Bayes training
```

## Data Overview

| Metric | Value |
|--------|-------|
| Total Sightings | ~80,000 |
| Date Range | 1949 – 2013 |
| Primary Source | USA (~95%) |
| Top Shapes | Light, Circle, Triangle, Fireball, Sphere |

## Requirements

- MATLAB R2019b or later
- Mapping Toolbox
- Statistics and Machine Learning Toolbox

## Technical Notes

- Data is cached in `ufo_optimized.mat` for faster loading
- Globe uses MATLAB's built-in topographic data (`topo.mat`)
- Prediction models are pre-trained; retraining requires the original CSV

## UI Theme

The app uses a "Neon Terminal" aesthetic:
- Dark background (`#0B1220`)
- Accent colors: Aqua, Pink, Orange, Green
- Consolas monospace font throughout
- Panel borders with matching highlight colors

---

Data sourced from NUFORC (National UFO Reporting Center).
