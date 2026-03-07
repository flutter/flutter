/**
 * Dashboard Module - Metrics, alerts, and data source status
 */

const DashboardModule = (() => {
    let alertsPanel = null;
    let metricsData = {};
    let trendChartInstance = null;

    function init() {
        alertsPanel = document.getElementById('alerts-panel');
    }

    function updateMetrics(hazardData) {
        const points = hazardData.grid_data || [];
        const moistures = points.map(p => p.soil_moisture).filter(v => v !== null && v !== undefined && !isNaN(v));
        const ndviValues = points.map(p => p.ndvi).filter(v => v !== null && v !== undefined && !isNaN(v));
        const precipValues = points.map(p => p.precipitation).filter(v => v !== null && v !== undefined && !isNaN(v));

        const avgMoisture = moistures.length > 0 ? (moistures.reduce((a, b) => a + b, 0) / moistures.length).toFixed(1) : "0.0";
        const avgNdvi = ndviValues.length > 0 ? (ndviValues.reduce((a, b) => a + b, 0) / ndviValues.length).toFixed(3) : "0.000";
        const avgPrecip = precipValues.length > 0 ? (precipValues.reduce((a, b) => a + b, 0) / precipValues.length).toFixed(1) : "0.0";

        const riskyPoints = points.filter(p => p.risk_score !== null && p.risk_score !== undefined && !isNaN(p.risk_score) && p.risk_score >= 60);
        const highRiskPct = points.length > 0 ? ((riskyPoints.length / points.length) * 100).toFixed(1) : "0.0";

        // Animate metric updates
        animateValue('avg-moisture', `${avgMoisture}%`);
        animateValue('high-risk-pct', `${highRiskPct}%`);
        animateValue('avg-precip', `${avgPrecip}mm`);
        animateValue('avg-ndvi', avgNdvi);

        metricsData = { avgMoisture, highRiskPct, avgPrecip, avgNdvi };
    }

    function animateValue(elementId, newValue) {
        const el = document.getElementById(elementId);
        if (!el) return;
        el.style.opacity = '0';
        el.style.transform = 'translateY(5px)';
        setTimeout(() => {
            el.textContent = newValue;
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
            el.style.transition = 'all 0.3s ease';
        }, 150);
    }

    async function loadAlerts() {
        try {
            const res = await fetch('/api/alerts');
            const data = await res.json();
            renderAlerts(data);
        } catch (err) {
            console.error('Failed to load alerts:', err);
            if (alertsPanel) {
                alertsPanel.innerHTML = '<div class="loading-placeholder">Failed to load alerts</div>';
            }
        }
    }

    function renderAlerts(alertData) {
        if (!alertsPanel) return;

        if (!alertData.alerts || alertData.alerts.length === 0) {
            alertsPanel.innerHTML = `
                <div style="text-align: center; padding: 16px; color: var(--accent-green);">
                    <div style="font-size: 24px; margin-bottom: 6px;">✅</div>
                    <div style="font-size: 12px; font-weight: 600;">All Clear</div>
                    <div style="font-size: 10px; color: var(--text-muted); margin-top: 4px;">No active hazard alerts</div>
                </div>
            `;
            return;
        }

        const alertSummary = `
            <div style="display: flex; gap: 8px; margin-bottom: 10px; flex-wrap: wrap;">
                ${alertData.critical > 0 ? `<span style="font-size: 10px; padding: 2px 8px; border-radius: 10px; background: rgba(239,68,68,0.15); color: var(--risk-critical); font-weight: 600;">${alertData.critical} Critical</span>` : ''}
                ${alertData.severe > 0 ? `<span style="font-size: 10px; padding: 2px 8px; border-radius: 10px; background: rgba(249,115,22,0.15); color: var(--risk-high); font-weight: 600;">${alertData.severe} Severe</span>` : ''}
                ${alertData.moderate > 0 ? `<span style="font-size: 10px; padding: 2px 8px; border-radius: 10px; background: rgba(245,158,11,0.15); color: var(--risk-moderate); font-weight: 600;">${alertData.moderate} Moderate</span>` : ''}
            </div>
        `;

        const alertItems = alertData.alerts.slice(0, 10).map((alert, i) => `
            <div class="alert-item ${alert.severity}" style="animation-delay: ${i * 0.05}s" 
                 onclick="MapModule.flyToLocation(${alert.lat}, ${alert.lon}, 10)">
                <div class="alert-header">
                    <span class="alert-type">${getAlertIcon(alert.type)} ${alert.type}</span>
                    <span class="alert-severity">${alert.severity}</span>
                </div>
                <div class="alert-location">${alert.location}</div>
                <div class="alert-message">${alert.message}</div>
            </div>
        `).join('');

        alertsPanel.innerHTML = alertSummary + alertItems;
    }

    function getAlertIcon(type) {
        switch (type) {
            case 'DROUGHT': return '🏜️';
            case 'FLOOD': return '🌊';
            case 'LANDSLIDE': return '⛰️';
            default: return '⚠️';
        }
    }

    function showLocationDetail(locationData) {
        const panel = document.getElementById('location-detail');
        const content = document.getElementById('location-detail-content');
        if (!panel || !content) return;

        panel.style.display = 'block';

        const assessment = locationData.assessment;
        const ha = assessment?.hazard_assessment || {};
        const sm = assessment?.soil_moisture || {};
        const terrain = assessment?.terrain || {};
        const precip = assessment?.precipitation || {};
        const veg = assessment?.vegetation || {};
        const deform = assessment?.ground_deformation || {};
        const hydro = assessment?.hydrology || {};

        content.innerHTML = `
            <div class="detail-header">
                <div>
                    <div class="detail-name">${locationData.name}</div>
                    <div class="detail-state">${locationData.state} · ${locationData.type}</div>
                </div>
            </div>
            <div class="detail-grid">
                <div class="detail-item">
                    <div class="detail-item-label">Soil Moisture</div>
                    <div class="detail-item-value" style="color: ${getMoistureColor(sm.value_pct || 0)}">${sm.value_pct || '--'}%</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">Elevation</div>
                    <div class="detail-item-value">${terrain.elevation_m || '--'}m</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">Slope</div>
                    <div class="detail-item-value">${terrain.slope_deg || '--'}°</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">Precipitation</div>
                    <div class="detail-item-value">${precip.daily_accumulation_mm || '--'}mm</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">NDVI</div>
                    <div class="detail-item-value">${veg.ndvi || '--'}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">Deformation</div>
                    <div class="detail-item-value">${deform.displacement_mm || '--'}mm</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">Runoff</div>
                    <div class="detail-item-value">${hydro.surface_runoff_mm || '--'}mm</div>
                </div>
                <div class="detail-item">
                    <div class="detail-item-label">Risk Score</div>
                    <div class="detail-item-value">${ha.risk_score || '--'}</div>
                </div>
            </div>
            <div class="detail-risk-badge ${ha.overall_risk || 'SAFE'}">
                ${ha.overall_risk || 'SAFE'} Risk
            </div>
            
            ${ha.alerts && ha.alerts.length > 0 ? `
                <div style="margin-top: 10px;">
                    ${ha.alerts.map(a => `
                        <div style="font-size: 10px; color: var(--text-secondary); padding: 4px 0; border-bottom: 1px solid var(--border-color);">
                            ${getAlertIcon(a.type)} ${a.message}
                        </div>
                    `).join('')}
                </div>
            ` : ''}

            ${ha.safe_route_url ? `
                <a href="${ha.safe_route_url}" target="_blank" style="display: block; margin-top: 12px; padding: 10px; background: rgba(16, 185, 129, 0.15); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 6px; text-decoration: none; text-align: center; font-weight: 600; font-size: 12px; transition: all 0.2s ease;">
                    🗺️ Get Safe Evacuation Route
                </a>
            ` : ''}
        `;

        // Fetch AI Analysis and Trend
        fetchAiAnalysis(locationData.name);
        fetchTrendData(locationData.name);
    }

    async function fetchAiAnalysis(name) {
        const container = document.getElementById('ai-analysis-content');
        if (!container) return;
        container.innerHTML = '<div class="loading-placeholder">Processing latest satellite metrics...</div>';

        try {
            const res = await fetch(`/api/analysis/${encodeURIComponent(name)}`);
            if (res.ok) {
                const data = await res.json();
                container.innerHTML = data.synthesis;
            } else {
                container.innerHTML = 'Analysis unavailable at this time.';
            }
        } catch (e) {
            container.innerHTML = 'Error generating analysis.';
        }
    }

    async function fetchTrendData(name) {
        try {
            const res = await fetch(`/api/trend/${encodeURIComponent(name)}`);
            if (res.ok) {
                const data = await res.json();
                renderTrendChart(data.trend);
            }
        } catch (e) {
            console.error('Trend fetch error:', e);
        }
    }

    function renderTrendChart(trendData) {
        const ctx = document.getElementById('trendChart');
        if (!ctx) return;

        if (trendChartInstance) {
            trendChartInstance.destroy();
        }

        const labels = trendData.map(d => {
            const date = new Date(d.date);
            return `${date.getDate()}/${date.getMonth() + 1}`;
        });
        const precipData = trendData.map(d => d.precipitation);
        const smData = trendData.map(d => d.soil_moisture_proxy);

        trendChartInstance = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Precipitation',
                        data: precipData,
                        type: 'bar',
                        backgroundColor: 'rgba(79, 195, 247, 0.4)',
                        borderColor: '#4fc3f7',
                        borderWidth: 1,
                        yAxisID: 'y-precip'
                    },
                    {
                        label: 'Moisture (%)',
                        data: smData,
                        type: 'line',
                        borderColor: '#f7c948',
                        backgroundColor: 'rgba(247, 201, 72, 0.15)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4,
                        yAxisID: 'y-sm',
                        pointRadius: 1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false,
                },
                plugins: {
                    legend: {
                        position: 'top',
                        labels: { color: '#a0a0b0', boxWidth: 10, font: { size: 10 } }
                    }
                },
                scales: {
                    x: {
                        ticks: { color: '#888', font: { size: 9 }, maxTicksLimit: 7 },
                        grid: { color: 'rgba(255,255,255,0.05)' }
                    },
                    'y-sm': {
                        type: 'linear',
                        position: 'left',
                        min: 0, max: 100,
                        ticks: { color: '#f7c948', font: { size: 9 } },
                        grid: { color: 'rgba(255,255,255,0.05)' }
                    },
                    'y-precip': {
                        type: 'linear',
                        position: 'right',
                        min: 0,
                        ticks: { color: '#4fc3f7', font: { size: 9 } },
                        grid: { display: false }
                    }
                }
            }
        });
    }

    function getMoistureColor(value) {
        if (value < 10) return '#ef6c00';
        if (value < 18) return '#f59e0b';
        if (value < 38) return '#10b981';
        if (value < 48) return '#1565c0';
        return '#ef4444';
    }

    function updateSourcesStatus(sources) {
        const panel = document.getElementById('sources-panel');
        if (!panel) return;

        const items = panel.querySelectorAll('.source-item');
        items.forEach(item => {
            item.classList.add('active');
            const status = item.querySelector('.source-status');
            if (status) status.textContent = 'Active';
        });
    }

    return {
        init,
        updateMetrics,
        loadAlerts,
        showLocationDetail,
        updateSourcesStatus
    };
})();
