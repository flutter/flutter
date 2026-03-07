/**
 * Map Module - Leaflet map with multiple base layers and data overlays
 * Base layers: Street Map, Heatmap, Vegetation Map
 */

const MapModule = (() => {
    let map = null;
    let heatLayer = null;
    let riskMarkers = [];
    let layerGroups = {};
    let baseLayers = {};
    let currentPopup = null;
    let currentBaseLayer = 'street';

    // Risk colors
    const RISK_COLORS = {
        SAFE: '#10b981',
        LOW: '#0891b2',
        MODERATE: '#d97706',
        HIGH: '#ea580c',
        CRITICAL: '#dc2626'
    };

    function getMoistureColor(value) {
        if (value < 8) return '#1e3a5f';
        if (value < 18) return '#e65100';
        if (value < 30) return '#f9a825';
        if (value < 38) return '#2e7d32';
        if (value < 48) return '#1565c0';
        return '#b71c1c';
    }

    function getMoistureOpacity(value) {
        return Math.min(0.65, 0.25 + (value / 60) * 0.4);
    }

    function getRiskColor(riskLevel) {
        return RISK_COLORS[riskLevel] || RISK_COLORS.SAFE;
    }

    function init() {
        map = L.map('map', {
            center: [10.8, 78.7],
            zoom: 7,
            minZoom: 4,
            maxZoom: 18,
            zoomControl: true,
            attributionControl: true
        });

        // ─── BASE LAYERS ───
        // 1. Street Map (clear OpenStreetMap)
        baseLayers.street = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
            maxZoom: 19
        });

        // 2. Satellite / Terrain (Esri World Imagery)
        baseLayers.satellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
            attribution: '&copy; Esri, Maxar, Earthstar Geographics',
            maxZoom: 18
        });

        // 3. Topographic for terrain context
        baseLayers.topo = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenTopoMap',
            maxZoom: 17
        });

        // Default: Street map
        baseLayers.street.addTo(map);

        // Remove tile filter since we're using light/normal tiles
        const tp = document.querySelector('.leaflet-tile-pane');
        if (tp) tp.style.filter = 'none';

        // ─── DATA OVERLAY GROUPS ───
        layerGroups = {
            'soil-moisture': L.layerGroup().addTo(map),
            'precipitation': L.layerGroup(),
            'ground-deformation': L.layerGroup(),
            'ndvi': L.layerGroup(),
            'terrain': L.layerGroup(),
            'runoff': L.layerGroup(),
            'hazard-zones': L.layerGroup().addTo(map),
            'heatmap': L.layerGroup()
        };

        // Tamil Nadu boundary (approx)
        L.rectangle([[8.0, 76.0], [13.5, 80.5]], {
            color: 'rgba(59, 130, 246, 0.3)',
            weight: 2,
            fillOpacity: 0.02,
            dashArray: '6, 6'
        }).addTo(map);

        // ─── LEAFLET LAYER CONTROL ───
        const baseObj = {
            "🗺️ Street Map": baseLayers.street,
            "🛰️ Satellite": baseLayers.satellite,
            "⛰️ Topographic": baseLayers.topo
        };

        const overlayObj = {
            "🌡️ Soil Moisture": layerGroups['soil-moisture'],
            "🔥 Heatmap": layerGroups['heatmap'],
            "🌧️ Precipitation": layerGroups['precipitation'],
            "📡 Ground Deformation": layerGroups['ground-deformation'],
            "🌿 Vegetation NDVI": layerGroups['ndvi'],
            "⛰️ Terrain / Slope": layerGroups['terrain'],
            "💧 Surface Runoff": layerGroups['runoff'],
            "⚠️ Hazard Zones": layerGroups['hazard-zones']
        };

        L.control.layers(baseObj, overlayObj, {
            position: 'topright',
            collapsed: true
        }).addTo(map);

        // Map click handler (Tamil Nadu + India)
        map.on('click', async (e) => {
            const { lat, lng } = e.latlng;
            if (lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 98.0) {
                await showLocationPopup(lat, lng);
            }
        });

        return map;
    }

    async function showLocationPopup(lat, lon) {
        try {
            const res = await fetch(`/api/location-assessment?lat=${lat}&lon=${lon}`);
            const data = await res.json();

            const ha = data.hazard_assessment;
            const popupContent = `
                <div class="popup-title">📍 ${lat.toFixed(3)}°N, ${lon.toFixed(3)}°E</div>
                <div class="popup-grid">
                    <div><span class="popup-label">Soil Moisture</span><br><span class="popup-value">${data.soil_moisture.value_pct}%</span></div>
                    <div><span class="popup-label">Elevation</span><br><span class="popup-value">${data.terrain.elevation_m}m</span></div>
                    <div><span class="popup-label">Slope</span><br><span class="popup-value">${data.terrain.slope_deg}°</span></div>
                    <div><span class="popup-label">Precipitation</span><br><span class="popup-value">${data.precipitation.daily_accumulation_mm}mm</span></div>
                    <div><span class="popup-label">NDVI</span><br><span class="popup-value">${data.vegetation.ndvi}</span></div>
                    <div><span class="popup-label">Runoff</span><br><span class="popup-value">${data.hydrology.surface_runoff_mm}mm</span></div>
                    <div><span class="popup-label">Deformation</span><br><span class="popup-value">${data.ground_deformation.displacement_mm}mm</span></div>
                    <div><span class="popup-label">Risk Score</span><br><span class="popup-value">${ha.risk_score}</span></div>
                </div>
                <div class="popup-risk ${ha.overall_risk}">Risk: ${ha.overall_risk}</div>
            `;

            if (currentPopup) map.closePopup(currentPopup);
            currentPopup = L.popup({ maxWidth: 340, className: 'custom-popup' })
                .setLatLng([lat, lon])
                .setContent(popupContent)
                .openOn(map);
        } catch (err) {
            console.error('Location popup error:', err);
        }
    }

    function renderHazardGrid(gridData) {
        layerGroups['soil-moisture'].clearLayers();
        layerGroups['hazard-zones'].clearLayers();
        layerGroups['heatmap'].clearLayers();

        if (!gridData || !gridData.grid_data) return;

        const points = gridData.grid_data;
        const step = gridData.resolution_deg || 0.5;
        const halfStep = step / 2;

        // ─── District markers with labels + risk circles ───
        points.forEach(point => {
            const color = getMoistureColor(point.soil_moisture);
            const riskColor = getRiskColor(point.risk_level);
            const radius = point.name ? 12 : 6;

            // Risk circle
            const circle = L.circleMarker([point.lat, point.lon], {
                radius: radius,
                fillColor: riskColor,
                color: '#fff',
                weight: 2,
                fillOpacity: 0.75
            });

            const tooltip = point.name
                ? `<b>${point.name}</b><br>` +
                `Soil Moisture: ${point.soil_moisture}%<br>` +
                `Risk: <b>${point.risk_level}</b> (${point.risk_score}/100)<br>` +
                `Slope: ${point.slope}° | Precip: ${point.precipitation}mm`
                : `SM: ${point.soil_moisture}% | Risk: ${point.risk_level}`;

            circle.bindTooltip(tooltip, { sticky: true });
            circle.on('click', () => showLocationPopup(point.lat, point.lon));

            layerGroups['soil-moisture'].addLayer(circle);

            // District name label (permanent)
            if (point.name) {
                const label = L.marker([point.lat, point.lon], {
                    icon: L.divIcon({
                        className: 'district-label',
                        html: `<span style="
                            font-size: 10px;
                            font-weight: 700;
                            font-family: Inter, sans-serif;
                            color: #1a1d2e;
                            background: rgba(255,255,255,0.85);
                            padding: 1px 6px;
                            border-radius: 4px;
                            border: 1px solid ${riskColor};
                            white-space: nowrap;
                            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                        ">${point.name}</span>`,
                        iconSize: [0, 0],
                        iconAnchor: [0, -16]
                    })
                });
                layerGroups['soil-moisture'].addLayer(label);
            }

            // ─── Hazard zone glow for MODERATE/HIGH/CRITICAL risky areas ───
            if (['MODERATE', 'HIGH', 'CRITICAL'].includes(point.risk_level) || point.risk_score >= 30) {
                const glowCircle = L.circleMarker([point.lat, point.lon], {
                    radius: 25 + (point.risk_score / 4),
                    color: riskColor,
                    fillColor: riskColor,
                    fillOpacity: 0.15,
                    weight: 1.5,
                    dashArray: point.risk_score >= 70 ? null : '4, 4'
                });

                const alertTypes = (point.alerts || []).join(', ') || 'None';
                glowCircle.bindTooltip(
                    `<b>⚠️ ${point.risk_level} RISK</b><br>` +
                    `${point.name || ''} — Score: ${point.risk_score}/100<br>` +
                    `Hazard: ${alertTypes}`,
                    { sticky: true }
                );

                layerGroups['hazard-zones'].addLayer(glowCircle);
            }
        });

        // ─── Heatmap layer (separate toggle) ───
        if (heatLayer) { map.removeLayer(heatLayer); heatLayer = null; }
        const heatData = points.map(p => [p.lat, p.lon, p.soil_moisture / 60]);
        heatLayer = L.heatLayer(heatData, {
            radius: 30,
            blur: 35,
            maxZoom: 10,
            max: 1.0,
            gradient: {
                0.0: '#1e3a5f',
                0.18: '#e65100',
                0.33: '#f9a825',
                0.50: '#2e7d32',
                0.70: '#1565c0',
                0.90: '#b71c1c'
            }
        });
        layerGroups['heatmap'].addLayer(heatLayer);
    }

    function renderPrecipitation(gridData) {
        layerGroups['precipitation'].clearLayers();
        if (!gridData || !gridData.grid_data) return;

        gridData.grid_data.forEach(point => {
            const precip = point.precipitation;
            if (precip.daily_accumulation_mm > 5) {
                const intensity = Math.min(1, precip.daily_accumulation_mm / 100);
                const circle = L.circleMarker([point.lat, point.lon], {
                    radius: 5 + intensity * 10,
                    color: 'rgba(37, 99, 235, 0.4)',
                    fillColor: `rgba(37, 99, 235, ${0.2 + intensity * 0.5})`,
                    fillOpacity: 0.6,
                    weight: 1
                });
                circle.bindTooltip(`🌧️ ${precip.daily_accumulation_mm}mm/day<br>Rate: ${precip.precip_rate_mm_hr}mm/hr`);
                layerGroups['precipitation'].addLayer(circle);
            }
        });
    }

    function renderDeformation(gridData) {
        layerGroups['ground-deformation'].clearLayers();
        if (!gridData || !gridData.grid_data) return;

        gridData.grid_data.forEach(point => {
            const def = point.deformation;
            if (def.risk_level !== 'LOW') {
                const intensity = Math.min(1, def.displacement_mm / 10);
                const color = def.risk_level === 'HIGH' ? '#dc2626' : '#7c3aed';
                const circle = L.circleMarker([point.lat, point.lon], {
                    radius: 5 + intensity * 9,
                    color: color,
                    fillColor: color,
                    fillOpacity: 0.35,
                    weight: 1.5
                });
                circle.bindTooltip(
                    `📡 Deformation: ${def.displacement_mm}mm<br>` +
                    `Direction: ${def.direction}<br>` +
                    `Zone: ${def.zone.replace(/_/g, ' ')}`
                );
                layerGroups['ground-deformation'].addLayer(circle);
            }
        });
    }

    function renderNDVI(gridData) {
        layerGroups['ndvi'].clearLayers();
        if (!gridData || !gridData.grid_data) return;

        gridData.grid_data.forEach(point => {
            const veg = point.vegetation;
            const ndvi = veg.ndvi;

            // Color: red (bare) → yellow → green (dense vegetation)
            let r, g, b;
            if (ndvi < 0.2) { r = 180; g = 60; b = 40; }
            else if (ndvi < 0.4) { r = 220; g = 160; b = 30; }
            else if (ndvi < 0.6) { r = 100; g = 180; b = 50; }
            else { r = 20; g = 130; b = 30; }

            const rect = L.rectangle(
                [[point.lat - 0.25, point.lon - 0.25],
                [point.lat + 0.25, point.lon + 0.25]],
                {
                    color: 'rgba(0,0,0,0.03)',
                    fillColor: `rgb(${r}, ${g}, ${b})`,
                    fillOpacity: 0.4,
                    weight: 0.5
                }
            );
            rect.bindTooltip(
                `🌿 NDVI: ${veg.ndvi}<br>` +
                `Health: ${veg.vegetation_health}<br>` +
                `Cover: ${veg.land_cover.replace(/_/g, ' ')}<br>` +
                `LAI: ${veg.lai}`
            );
            layerGroups['ndvi'].addLayer(rect);
        });
    }

    function renderTerrain(gridData) {
        layerGroups['terrain'].clearLayers();
        if (!gridData || !gridData.grid_data) return;

        gridData.grid_data.forEach(point => {
            const t = point.terrain;
            if (t.slope_deg > 8) {
                const intensity = Math.min(1, t.slope_deg / 45);
                const r = Math.floor(140 + intensity * 80);
                const g = Math.floor(90 + intensity * 30);
                const b = Math.floor(50);
                const circle = L.circleMarker([point.lat, point.lon], {
                    radius: 4 + intensity * 7,
                    color: 'rgba(0,0,0,0.1)',
                    fillColor: `rgb(${r}, ${g}, ${b})`,
                    fillOpacity: 0.5,
                    weight: 1
                });
                circle.bindTooltip(
                    `⛰️ Elevation: ${t.elevation_m}m<br>` +
                    `Slope: ${t.slope_deg}°<br>` +
                    `Risk: ${t.landslide_susceptibility.replace(/_/g, ' ')}<br>` +
                    `Ruggedness: ${t.terrain_ruggedness}`
                );
                layerGroups['terrain'].addLayer(circle);
            }
        });
    }

    function renderRunoff(gridData) {
        layerGroups['runoff'].clearLayers();
        if (!gridData || !gridData.grid_data) return;

        gridData.grid_data.forEach(point => {
            const h = point.hydrology;
            if (h.surface_runoff_mm > 1) {
                const intensity = Math.min(1, h.surface_runoff_mm / 15);
                const circle = L.circleMarker([point.lat, point.lon], {
                    radius: 4 + intensity * 8,
                    color: 'rgba(2, 132, 199, 0.3)',
                    fillColor: `rgba(2, 132, 199, ${0.2 + intensity * 0.5})`,
                    fillOpacity: 0.5,
                    weight: 1
                });
                circle.bindTooltip(
                    `💧 Runoff: ${h.surface_runoff_mm}mm<br>` +
                    `Flood Risk: ${h.flood_risk}<br>` +
                    `Soil: ${h.soil_type.replace(/_/g, ' ')}<br>` +
                    `Drainage: ${h.drainage_class}`
                );
                layerGroups['runoff'].addLayer(circle);
            }
        });
    }

    function toggleLayer(layerName, visible) {
        const group = layerGroups[layerName];
        if (!group) return;

        if (visible) {
            if (!map.hasLayer(group)) map.addLayer(group);
        } else {
            if (map.hasLayer(group)) map.removeLayer(group);
        }
    }

    function flyToLocation(lat, lon, zoom = 10) {
        map.flyTo([lat, lon], zoom, { duration: 1.5 });
    }

    function addLocationMarker(lat, lon, name, data, isLive = false) {
        const riskLevel = data?.moisture_data?.risk_type || 'NORMAL';
        const moisture = data?.moisture_data?.soil_moisture_pct || 0;
        const color = riskLevel === 'FLOOD' ? '#1565c0' :
            riskLevel === 'DROUGHT' ? '#e65100' : '#10b981';

        const marker = L.circleMarker([lat, lon], {
            radius: 9,
            fillColor: color,
            color: '#fff',
            weight: 2.5,
            fillOpacity: 0.85,
            className: isLive ? 'live-location-pulse' : ''
        }).addTo(map);

        marker.bindPopup(`
            <div class="popup-title">📍 ${name}</div>
            <div class="popup-grid">
                <div><span class="popup-label">Moisture</span><br><span class="popup-value">${moisture}%</span></div>
                <div><span class="popup-label">Risk</span><br><span class="popup-value">${riskLevel}</span></div>
            </div>
        `);

        return marker;
    }

    return {
        init,
        renderHazardGrid,
        renderPrecipitation,
        renderDeformation,
        renderNDVI,
        renderTerrain,
        renderRunoff,
        toggleLayer,
        flyToLocation,
        addLocationMarker,
        showLocationPopup,
        getMap: () => map
    };
})();
