/**
 * Search Module - Location search with autocomplete
 * Searches Indian cities, towns, and villages
 */

const SearchModule = (() => {
    let searchInput = null;
    let searchResults = null;
    let searchContainer = null;
    let debounceTimer = null;
    let isOpen = false;

    function init() {
        searchInput = document.getElementById('search-input');
        searchResults = document.getElementById('search-results');
        searchContainer = document.getElementById('search-container');

        if (!searchInput || !searchResults) return;

        // Input handler with debounce
        searchInput.addEventListener('input', (e) => {
            clearTimeout(debounceTimer);
            const query = e.target.value.trim();

            if (query.length < 2) {
                hideResults();
                return;
            }

            debounceTimer = setTimeout(() => performSearch(query), 250);
        });

        // Focus handler
        searchInput.addEventListener('focus', () => {
            if (searchInput.value.trim().length >= 2) {
                performSearch(searchInput.value.trim());
            }
        });

        // Click outside to close
        document.addEventListener('click', (e) => {
            if (!searchContainer.contains(e.target)) {
                hideResults();
            }
        });

        // Keyboard shortcut (Ctrl+K)
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                searchInput.focus();
                searchInput.select();
            }
            if (e.key === 'Escape') {
                hideResults();
                searchInput.blur();
            }
        });

        // Live Location Tracking
        const locateBtn = document.getElementById('btn-locate');
        if (locateBtn) {
            locateBtn.addEventListener('click', () => {
                locateBtn.style.color = '#3b82f6';
                locateBtn.classList.add('spinning');
                locateBtn.title = "Locating...";

                if ("geolocation" in navigator) {
                    navigator.geolocation.getCurrentPosition(async (position) => {
                        const lat = position.coords.latitude;
                        const lon = position.coords.longitude;
                        locateBtn.title = "Fetching data for your location...";

                        try {
                            const res = await fetch(`/api/live-location?lat=${lat}&lon=${lon}`);
                            if (res.ok) {
                                const data = await res.json();
                                MapModule.flyToLocation(lat, lon, 13);

                                const formattedData = {
                                    name: "GPS Location",
                                    state: "Live",
                                    type: "User",
                                    lat: lat,
                                    lon: lon,
                                    assessment: {
                                        hazard_assessment: {
                                            risk_score: data.risk_score,
                                            overall_risk: data.alert,
                                            safe_route_url: data.safe_route_url,
                                            alerts: data.hazard !== "none" ? [{ type: data.hazard.toUpperCase(), message: `Live GPS ${data.hazard} risk` }] : []
                                        },
                                        soil_moisture: { value_pct: data.metrics.soil_moisture_pct },
                                        terrain: { elevation_m: data.metrics.elevation_m, slope_deg: data.metrics.slope_deg },
                                        precipitation: { daily_accumulation_mm: data.metrics.precipitation_mm },
                                        vegetation: { ndvi: data.metrics.ndvi },
                                        ground_deformation: { displacement_mm: 0 },
                                        hydrology: { surface_runoff_mm: data.metrics.runoff_mm }
                                    }
                                };
                                MapModule.addLocationMarker(lat, lon, "Your Live GPS", { moisture_data: { risk_type: data.alert, soil_moisture_pct: data.metrics.soil_moisture_pct } }, true);
                                DashboardModule.showLocationDetail(formattedData);
                            } else {
                                alert("Backend failed to process GPS location. Using fallback data.");
                                MapModule.flyToLocation(lat, lon, 12);
                                MapModule.showLocationPopup(lat, lon);
                            }
                        } catch (e) {
                            console.error("Live track failed", e);
                            alert("Network error while fetching local hazard data.");
                        } finally {
                            locateBtn.style.color = '';
                            locateBtn.classList.remove('spinning');
                            locateBtn.title = "Track my location";
                        }
                    }, (err) => {
                        console.error("Geolocation failed", err);
                        locateBtn.style.color = '';
                        locateBtn.classList.remove('spinning');
                        locateBtn.title = "Track my location";

                        let msg = "Could not access your location.";
                        if (err.code === 1) msg = "Location permission denied. Please enable GPS for this site.";
                        else if (err.code === 2) msg = "GPS signal lost or unavailable.";
                        else if (err.code === 3) msg = "Location request timed out.";
                        alert(msg);
                    }, { enableHighAccuracy: true, timeout: 10000 });
                } else {
                    alert("Geolocation is not supported by your browser.");
                    locateBtn.style.color = '';
                    locateBtn.classList.remove('spinning');
                    locateBtn.title = "Track my location";
                }
            });
        }

        // Keyboard navigation
        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
                e.preventDefault();
                navigateResults(e.key === 'ArrowDown' ? 1 : -1);
            }
            if (e.key === 'Enter') {
                const active = searchResults.querySelector('.search-result-item.active');
                if (active) active.click();
            }
        });
    }

    async function performSearch(query) {
        try {
            const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
            const data = await res.json();
            displayResults(data.results);
        } catch (err) {
            console.error('Search error:', err);
        }
    }

    function getMoistureColor(value) {
        if (value < 10) return '#ef6c00';
        if (value < 18) return '#f59e0b';
        if (value < 38) return '#10b981';
        if (value < 48) return '#1565c0';
        return '#ef4444';
    }

    function displayResults(results) {
        if (!results || results.length === 0) {
            searchResults.innerHTML = `
                <div style="padding: 16px; text-align: center; color: var(--text-muted); font-size: 12px;">
                    No locations found
                </div>
            `;
            showResults();
            return;
        }

        searchResults.innerHTML = results.map((r, i) => {
            const moisture = r.moisture_data?.soil_moisture_pct || 0;
            const risk = r.moisture_data?.risk_type || 'NORMAL';
            const color = getMoistureColor(moisture);
            const typeIcon = r.type === 'metro' ? '🏙️' : r.type === 'city' ? '🏘️' : r.type === 'town' ? '🏠' : '🏡';

            return `
                <div class="search-result-item" data-lat="${r.lat}" data-lon="${r.lon}" data-name="${r.name}" data-index="${i}">
                    <div class="result-info">
                        <span class="result-name">${typeIcon} ${r.name}</span>
                        <span class="result-state">${r.state} · ${r.type}</span>
                    </div>
                    <div class="result-moisture">
                        <div class="result-moisture-value" style="color: ${color}">${moisture}%</div>
                        <div class="result-moisture-label">${risk === 'NORMAL' ? 'Normal' : risk}</div>
                    </div>
                </div>
            `;
        }).join('');

        // Bind click handlers
        searchResults.querySelectorAll('.search-result-item').forEach(item => {
            item.addEventListener('click', () => {
                const lat = parseFloat(item.dataset.lat);
                const lon = parseFloat(item.dataset.lon);
                const name = item.dataset.name;
                selectLocation(lat, lon, name);
            });
        });

        showResults();
    }

    async function selectLocation(lat, lon, name) {
        hideResults();
        searchInput.value = name;

        // Fly to location on map
        MapModule.flyToLocation(lat, lon, 10);

        // Show location details
        try {
            const res = await fetch(`/api/location/${encodeURIComponent(name)}`);
            if (res.ok) {
                const data = await res.json();
                DashboardModule.showLocationDetail(data);
                MapModule.addLocationMarker(lat, lon, name, { moisture_data: data.assessment.soil_moisture });
            }

            // Also show popup
            setTimeout(() => MapModule.showLocationPopup(lat, lon), 1500);
        } catch (err) {
            console.error('Location detail error:', err);
            MapModule.showLocationPopup(lat, lon);
        }
    }

    function navigateResults(direction) {
        const items = searchResults.querySelectorAll('.search-result-item');
        if (items.length === 0) return;

        const current = searchResults.querySelector('.search-result-item.active');
        let index = current ? parseInt(current.dataset.index) + direction : (direction === 1 ? 0 : items.length - 1);
        index = Math.max(0, Math.min(items.length - 1, index));

        items.forEach(item => item.classList.remove('active'));
        items[index].classList.add('active');
        items[index].style.background = 'var(--bg-hover)';

        // Reset others
        items.forEach((item, i) => {
            if (i !== index) item.style.background = '';
        });

        items[index].scrollIntoView({ block: 'nearest' });
    }

    function showResults() {
        searchResults.classList.add('visible');
        isOpen = true;
    }

    function hideResults() {
        searchResults.classList.remove('visible');
        isOpen = false;
    }

    return { init, performSearch, selectLocation };
})();
