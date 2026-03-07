/**
 * App Controller - Main application orchestration
 * Handles data loading, refresh cycles, and layer toggling
 */

const App = (() => {
    let refreshInterval = null;
    let isLoading = false;
    let cachedData = {};

    const REFRESH_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes

    async function init() {
        console.log('🛰️ Hazard Monitor initializing...');

        // Initialize modules
        MapModule.init();
        SearchModule.init();
        DashboardModule.init();

        // Setup layer toggles
        setupLayerToggles();

        // Setup refresh button
        const refreshBtn = document.getElementById('btn-refresh');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => loadAllData());
        }

        // Load initial data
        await loadAllData();

        // Hide loading screen
        setTimeout(() => {
            const loadingScreen = document.getElementById('loading-screen');
            if (loadingScreen) loadingScreen.classList.add('hidden');
        }, 2200);

        // Start auto-refresh
        refreshInterval = setInterval(loadAllData, REFRESH_INTERVAL_MS);

        // Start Server-Sent Events (SSE) Listener for Real-Time Live Updates
        initRealTimeSSE();

        console.log('✅ Hazard Monitor ready');
    }

    function initRealTimeSSE() {
        console.log("🔌 Connecting to Real-Time SSE Stream...");
        const evtSource = new EventSource("/api/events");

        evtSource.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (data.type === "MAP_UPDATE") {
                    console.log("🌊 Real-Time Map Update Received!", data.timestamp);

                    // The payload is structured similarly to /api/hazard-assessment
                    const hazardData = { grid_data: data.data };

                    // Update Map and Dashboard without full reload
                    cachedData.hazard = hazardData;
                    MapModule.renderHazardGrid(hazardData);
                    DashboardModule.updateMetrics(hazardData);

                    // Also try to refresh alerts quietly
                    DashboardModule.loadAlerts();

                    updateTimestamp();
                } else if (data.type === "PING") {
                    // Just a keep-alive ping, ignore
                }
            } catch (err) {
                console.error("Error parsing SSE data", err);
            }
        };

        evtSource.onerror = (err) => {
            console.error("SSE Connection Error. Reconnecting...", err);
            // Browser automatically reconnects EventSource on drop.
        };
    }

    async function loadAllData() {
        if (isLoading) return;
        isLoading = true;

        const refreshBtn = document.getElementById('btn-refresh');
        if (refreshBtn) refreshBtn.classList.add('spinning');

        try {
            // Load hazard assessment (main data)
            const hazardData = await fetchJSON('/api/hazard-assessment');
            if (hazardData) {
                cachedData.hazard = hazardData;
                MapModule.renderHazardGrid(hazardData);
                DashboardModule.updateMetrics(hazardData);
            }

            // Load alerts
            await DashboardModule.loadAlerts();

            // Load supplementary data in parallel
            const [precipData, insarData, ndviData, terrainData, runoffData] = await Promise.allSettled([
                fetchJSON('/api/precipitation'),
                fetchJSON('/api/insar'),
                fetchJSON('/api/ndvi'),
                fetchJSON('/api/terrain'),
                fetchJSON('/api/runoff')
            ]);

            if (precipData.status === 'fulfilled' && precipData.value) {
                cachedData.precipitation = precipData.value;
                MapModule.renderPrecipitation(precipData.value);
            }
            if (insarData.status === 'fulfilled' && insarData.value) {
                cachedData.insar = insarData.value;
                MapModule.renderDeformation(insarData.value);
            }
            if (ndviData.status === 'fulfilled' && ndviData.value) {
                cachedData.ndvi = ndviData.value;
                MapModule.renderNDVI(ndviData.value);
            }
            if (terrainData.status === 'fulfilled' && terrainData.value) {
                cachedData.terrain = terrainData.value;
                MapModule.renderTerrain(terrainData.value);
            }
            if (runoffData.status === 'fulfilled' && runoffData.value) {
                cachedData.runoff = runoffData.value;
                MapModule.renderRunoff(runoffData.value);
            }

            DashboardModule.updateSourcesStatus(cachedData);
            updateTimestamp();

        } catch (err) {
            console.error('Data load error:', err);
        } finally {
            isLoading = false;
            if (refreshBtn) refreshBtn.classList.remove('spinning');
        }
    }

    async function fetchJSON(url) {
        try {
            const res = await fetch(url);
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            return await res.json();
        } catch (err) {
            console.error(`Fetch error for ${url}:`, err);
            return null;
        }
    }

    function setupLayerToggles() {
        const toggles = document.querySelectorAll('.layer-toggle');
        toggles.forEach(toggle => {
            const checkbox = toggle.querySelector('input[type="checkbox"]');
            const layerName = toggle.dataset.layer;

            if (!checkbox || !layerName) return;

            checkbox.addEventListener('change', () => {
                MapModule.toggleLayer(layerName, checkbox.checked);
                toggle.classList.toggle('active', checkbox.checked);
            });
        });
    }

    function updateTimestamp() {
        const el = document.getElementById('last-update');
        if (el) {
            const now = new Date();
            const timeStr = now.toLocaleTimeString('en-IN', {
                hour: '2-digit', minute: '2-digit', second: '2-digit',
                hour12: false
            });
            el.textContent = `Updated: ${timeStr}`;
        }
    }

    return { init };
})();

// Boot the application when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    App.init();
});
