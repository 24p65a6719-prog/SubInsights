// MapView Component
// Displays user location and nearby merchants on an interactive map
// Uses Leaflet.js for mapping (in production: Google Maps or Mapbox)

class MapView {
    constructor(containerId, initialLat = 37.7749, initialLon = -122.4194) {
        this.containerId = containerId;
        this.currentLat = initialLat;
        this.currentLon = initialLon;
        this.merchants = [];
        this.userMarker = null;
        this.merchantMarkers = {};
    }

    // Initialize map (mock implementation without Leaflet)
    initialize() {
        const container = document.getElementById(this.containerId);
        if (!container) return;

        container.innerHTML = `
        <div class="map-container">
            <div class="map-header">
                <h2>Nearby Benefits Map</h2>
                <p>Green: Within range | Orange: 2-5km | Red: Further away</p>
            </div>
            <div class="map-info">
                <p>📍 Current Location: ${this.currentLat.toFixed(4)}, ${this.currentLon.toFixed(4)}</p>
                <div id="merchants-list"></div>
            </div>
        </div>
        `;
    }

    // Add merchant to map
    addMerchant(merchant, benefit, distance) {
        this.merchants.push({
            merchant: merchant,
            benefit: benefit,
            distance: distance
        });
        this._updateMapDisplay();
    }

    // Clear all markers
    clearMarkers() {
        this.merchants = [];
        this._updateMapDisplay();
    }

    // Update user location
    updateUserLocation(lat, lon) {
        this.currentLat = lat;
        this.currentLon = lon;
        this._updateMapDisplay();
    }

    // Private method to update display
    _updateMapDisplay() {
        const merchantsList = document.getElementById('merchants-list');
        if (!merchantsList) return;

        if (this.merchants.length === 0) {
            merchantsList.innerHTML = '<p>No merchants nearby</p>';
            return;
        }

        // Sort by distance
        this.merchants.sort((a, b) => a.distance - b.distance);

        let html = '<div class="merchants-nearby"><h3>Merchants with Benefits:</h3>';
        
        this.merchants.forEach((item, index) => {
            const { merchant, benefit, distance } = item;
            let icon = '🟢'; // Green
            if (distance > 2) icon = '🟠'; // Orange
            if (distance > 5) icon = '🔴'; // Red

            html += `
            <div class="merchant-item">
                ${icon} <strong>${merchant.name}</strong>
                <div class="merchant-details">
                    <span>${benefit.title}</span>
                    <span class="distance">${distance.toFixed(2)} km</span>
                </div>
            </div>
            `;
        });

        html += '</div>';
        merchantsList.innerHTML = html;
    }

    // Get nearby merchants within radius
    getNearbyMerchants(radiusKm) {
        return this.merchants.filter(item => item.distance <= radiusKm);
    }
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = MapView;
}
