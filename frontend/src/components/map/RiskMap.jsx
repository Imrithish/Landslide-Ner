import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Circle, CircleMarker, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { Layers, Navigation, Loader2 } from 'lucide-react';
import { MapClickHandler } from './MapControls';
import { getRiskColor } from '../../utils/riskUtils';
import Button from '../common/Button';
import styles from './RiskMap.module.css';

// Smooth Map Pan/Zoom Updater
const MapCenterUpdater = ({ center, zoom }) => {
  const map = useMap();
  const lat = center ? center[0] : null;
  const lng = center ? center[1] : null;

  useEffect(() => {
    if (lat !== null && lng !== null) {
      map.setView([lat, lng], zoom || 7);
    }
  }, [lat, lng, zoom, map]);
  return null;
};

const GpsFlyTo = ({ trigger, coords }) => {
  const map = useMap();
  useEffect(() => {
    if (trigger && coords && coords.lat && coords.lng) {
      map.flyTo([coords.lat, coords.lng], 13, { animate: true, duration: 1.5 });
    }
  }, [trigger, coords, map]);
  return null;
};

const customPinIcon = new L.divIcon({
  className: 'custom-pin-icon',
  html: `<div style="color: #dc2626; display: flex; justify-content: center; align-items: center;">
           <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 24 24" fill="currentColor" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
             <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
             <circle cx="12" cy="10" r="3" fill="white"></circle>
           </svg>
         </div>`,
  iconSize: [36, 36],
  iconAnchor: [18, 36],
  popupAnchor: [0, -36]
});

const RiskMap = ({
  selectedLocation,
  onLocationSelect,
  riskZones = [],
  showZones = true,
  height = '500px',
  center = [26.2006, 92.9376],
  zoom = 7,
  interactive = true,
  onMapClick,
  onZoneClick
}) => {
  const [layers, setLayers] = useState({ zones: showZones, satellite: false });
  const [locating, setLocating] = useState(false);
  const [gpsCoords, setGpsCoords] = useState(null);
  const [gpsTrigger, setGpsTrigger] = useState(false);
  const [gpsError, setGpsError] = useState('');

  const mapCenter = (center && center[0] && center[1]) ? center : [26.2006, 92.9376];

  // GPS Location Finder Handler
  const handleFindMyLocation = () => {
    setGpsError('');
    if (!navigator.geolocation) {
      setGpsError('Geolocation is not supported by your browser.');
      return;
    }

    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        setLocating(false);
        setGpsCoords({ lat, lng });
        setGpsTrigger(prev => !prev);

        if (onLocationSelect) onLocationSelect(lat, lng);
        if (onMapClick) onMapClick({ lat, lng });
      },
      (err) => {
        setLocating(false);
        setGpsError('Unable to retrieve GPS coordinates. Please grant location access in browser.');
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );
  };

  return (
    <div className={styles.mapWrapper} style={{ height }}>
      <MapContainer
        center={mapCenter}
        zoom={zoom}
        style={{ height: '100%', width: '100%' }}
        className={styles.leafletContainer}
      >
        {/* Fast Esri Base Tiles */}
        <TileLayer
          attribution={
            layers.satellite
              ? '&copy; Google Maps'
              : '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          }
          url={
            layers.satellite
              ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
          }
        />

        <MapCenterUpdater center={mapCenter} zoom={zoom} />
        <GpsFlyTo trigger={gpsTrigger} coords={gpsCoords} />

        {interactive && (
          <MapClickHandler onLocationSelect={(lat, lng) => {
            if (onLocationSelect) onLocationSelect(lat, lng);
            if (onMapClick) onMapClick({ lat, lng });
          }} />
        )}

        {/* Live GPS Location User Marker (Blue Pulse Dot) */}
        {gpsCoords && (
          <CircleMarker
            center={[gpsCoords.lat, gpsCoords.lng]}
            radius={9}
            pathOptions={{
              color: '#ffffff',
              weight: 2.5,
              fillColor: '#2563eb',
              fillOpacity: 1.0
            }}
          >
            <Popup>
              <div className={styles.popup}>
                <strong style={{ color: '#1d4ed8' }}>📍 Your Live GPS Location</strong>
                <p>Lat: {gpsCoords.lat.toFixed(5)}° N</p>
                <p>Lng: {gpsCoords.lng.toFixed(5)}° E</p>
                <p style={{ fontSize: '0.7rem', color: '#64748b' }}>Accuracy: High GPS Telemetry</p>
              </div>
            </Popup>
          </CircleMarker>
        )}

        {/* Selected Target Point (Location Pin) */}
        {selectedLocation && selectedLocation.lat && selectedLocation.lng && (
          <Marker
            position={[selectedLocation.lat, selectedLocation.lng]}
            icon={customPinIcon}
          >
            <Popup>
              <div className={styles.popup}>
                <strong>Target Location</strong>
                <p>Lat: {selectedLocation.lat.toFixed(4)}° N</p>
                <p>Lng: {selectedLocation.lng.toFixed(4)}° E</p>
              </div>
            </Popup>
          </Marker>
        )}

        {/* Risk Zones & Stations — Clean GIS Circles & Risk Dots */}
        {layers.zones && riskZones.map((zone) => {
          const zLat = zone.latitude || zone.lat;
          const zLng = zone.longitude || zone.lng;
          const level = zone.riskLevel || zone.risk_level || 'LOW';
          const prob = zone.probability || zone.risk_probability || 0.3;
          const color = getRiskColor(level);

          if (!zLat || !zLng) return null;

          return (
            <div key={zone.id || `${zLat}_${zLng}`}>
              <Circle
                center={[zLat, zLng]}
                radius={zone.radius || 2000}
                pathOptions={{
                  color: color,
                  fillColor: color,
                  fillOpacity: 0.25,
                  weight: 1.5
                }}
                eventHandlers={{
                  click: () => {
                    if (onZoneClick) onZoneClick(zone);
                  }
                }}
              >
                <Popup>
                  <div className={styles.popup}>
                    <strong>{zone.name}</strong>
                    <p>Risk: <span style={{ color: color, fontWeight: 'bold' }}>{level}</span></p>
                    <p>Probability: {Math.round(prob * 100)}%</p>
                  </div>
                </Popup>
              </Circle>

              <CircleMarker
                center={[zLat, zLng]}
                radius={5}
                pathOptions={{
                  color: '#ffffff',
                  weight: 1.5,
                  fillColor: color,
                  fillOpacity: 0.9
                }}
                eventHandlers={{
                  click: () => {
                    if (onZoneClick) onZoneClick(zone);
                  }
                }}
              >
                <Popup>
                  <div className={styles.popup}>
                    <strong>{zone.name}</strong>
                    <p>Coordinates: {zLat.toFixed(4)}°, {zLng.toFixed(4)}°</p>
                    <p>Risk: <span style={{ color: color, fontWeight: 'bold' }}>{level}</span> ({Math.round(prob * 100)}%)</p>
                    {zone.elevation_m && <p>Elevation: {zone.elevation_m} m</p>}
                    {zone.slope_degrees && <p>Slope: {zone.slope_degrees}°</p>}
                  </div>
                </Popup>
              </CircleMarker>
            </div>
          );
        })}
      </MapContainer>

      {/* Floating GIS & GPS Controls */}
      <div className={styles.mapControls}>
        <Button
          variant="primary"
          size="small"
          icon={locating ? Loader2 : Navigation}
          onClick={handleFindMyLocation}
          disabled={locating}
        >
          {locating ? 'Locating GPS...' : '📍 GPS Location Finder'}
        </Button>

        <Button
          variant="secondary"
          size="small"
          icon={Layers}
          onClick={() => setLayers(prev => ({ ...prev, satellite: !prev.satellite }))}
        >
          {layers.satellite ? 'Map View' : 'Satellite'}
        </Button>
      </div>

      {gpsError && (
        <div className={styles.locationError}>
          <span>⚠ {gpsError}</span>
          <button onClick={() => setGpsError('')}>✕</button>
        </div>
      )}
    </div>
  );
};

export default RiskMap;
