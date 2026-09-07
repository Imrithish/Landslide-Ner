# NER Landslide Early Warning System - Project Documentation

## 1. Executive Summary
The **NER (North Eastern Region) Landslide Early Warning System** is an end-to-end, full-stack predictive analytics platform designed to monitor, predict, and alert authorities and citizens about imminent landslide and flash flood threats. Leveraging live satellite telemetry, historical disaster data, and machine learning, the system provides a real-time GIS dashboard and an automated multi-channel emergency dispatch engine.

---

## 2. Technology Stack & Tools Used

### Frontend (Client-Side)
- **Framework:** React.js powered by Vite (for ultra-fast HMR and bundling).
- **Styling:** Vanilla CSS Modules with modern glassmorphic and responsive UI design.
- **GIS Mapping:** `react-leaflet` and Leaflet.js utilizing CartoDB/OpenStreetMap tiles for interactive hazard mapping.
- **Icons:** `lucide-react` for clean, consistent iconography.
- **Routing:** React Router DOM.

### Backend (Server-Side)
- **Framework:** FastAPI (Python) - High-performance async web framework.
- **Server:** Uvicorn (ASGI server).
- **Database:** MySQL (for robust storage of alerts, field reports, and user registries).
- **Concurrency:** Native Python `asyncio` for simultaneous fetching of weather telemetry and multi-threaded ML inference.
- **HTTP Client:** `httpx` for asynchronous API requests.

### Machine Learning & Data Science
- **Core Library:** `scikit-learn` (Machine Learning), `pandas` (Data manipulation), `numpy`.
- **Model:** `RandomForestClassifier` optimized for complex, non-linear environmental threshold triggers.
- **Data Balancing:** `imbalanced-learn` (SMOTE) to handle rare hazard events against a majority of non-hazard data.
- **Persistence:** `joblib` for serializing and deserializing the trained model directly into the backend inference pipeline.

### Third-Party APIs & Gateways
- **Open-Meteo API:** Provides live, hyper-local weather forecasting, soil moisture metrics, and river discharge data.
- **NASA EONET API:** Used in the continuous training pipeline to fetch verified, real-world live landslide events.
- **TextBee SMS Gateway:** Automates the sending of emergency SMS alerts directly through a connected Android device.
- **OpenStreetMap Nominatim:** Global geocoding API allowing users to search arbitrary global locations on the map.

---

## 3. Core Implementations

### A. Interactive GIS Risk Map
A fully interactive map allowing authorities to monitor 40 critical stations across 8 North-Eastern states. 
- **Features:** Custom pin-dropping, global location search via Nominatim Geocoding, state-level filtering, and real-time inspector overlays. When a user clicks a map location, the backend instantly fetches telemetry and runs a live ML inference for that specific coordinate.

### B. Live Telemetry Engine
Instead of relying strictly on offline data, the prediction engine dynamically fetches real-time variables (`rainfall_1d`, `rainfall_3d`, `rainfall_7d`, `elevation`, `slope`, `soil_moisture`) using bounding boxes and interpolation to assess the exact ground reality of any coordinate.

### C. Multi-Hazard Rolling Forecast
Calculates a 7-day future threat timeline by superimposing forecasted weather surges over static local terrain metrics, warning users of incoming flash flood or landslide peaks up to a week in advance.

### D. Automated Emergency Dispatch
Features a proximity-based geofencing system. When a severe threat is detected, the system calculates the blast radius and automatically dispatches targeted SMS and Email alerts to citizens registered within the danger zone.

---

## 4. Machine Learning Pipeline & Training

### Feature Engineering
The Random Forest model is trained on a highly curated dataset (`final_ml_dataset.csv`) comprising historical environmental snapshots. The defining features are:
1. `rainfall_1d` (mm): Immediate trigger precipitation.
2. `rainfall_3d` (mm): Short-term saturation.
3. `rainfall_7d` (mm): Long-term antecedent bedrock saturation.
4. `elevation_m` (m): Altitude risk factor.
5. `slope_degrees` (°): Gravity and terrain steepness.
6. `soil_moisture` (fraction): Water-logging and lubrication metric.

### Training Strategy
1. **Data Preprocessing:** Missing values are imputed using median strategies; numerical features are normalized using `StandardScaler`.
2. **Class Imbalance Handling:** Because landslides are rare events, the dataset inherently leans toward "Safe" days. The pipeline uses **SMOTE (Synthetic Minority Over-sampling Technique)** to synthesize realistic hazard events, preventing the model from becoming biased toward predicting "Safe".
3. **Hyperparameter Tuning:** Uses `RandomizedSearchCV` to find the optimal number of trees, depth, and split criteria for the Random Forest to maximize the *Recall* score (ensuring we rarely miss a real disaster).
4. **Evaluation:** The model is rigorously tested against an unseen test split, generating a classification report detailing Precision, Recall, and F1-scores.

### Continuous Training (MLOps)
The project includes an automated continuous training pipeline (`continuous_training_pipeline.py`).
- **Data Ingestion:** A script contacts the NASA Earth Observatory Natural Event Tracker (EONET) to pull newly verified landslides globally.
- **Enrichment:** It back-fetches the historical weather and terrain conditions for the day that specific disaster occurred.
- **Appending & Retraining:** The new data is appended to `final_ml_dataset.csv`, and `train_final_model.py` is executed to rebuild and overwrite the `.joblib` model. This allows the system to continuously "learn" from new global climate patterns.

---

## 5. Exporting this Documentation to PDF
Since IDEs natively render Markdown files beautifully, you can easily export this document to a PDF format for distribution:
- **If using VS Code:** Press `Ctrl+Shift+P`, type **"Markdown: Print to PDF"** (requires a standard markdown PDF extension).
- **If using a Browser:** Open this file in your browser or GitHub, press `Ctrl+P`, and select **"Save as PDF"**.
