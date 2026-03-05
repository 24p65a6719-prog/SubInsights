// SubInsights Frontend Main Application
// Orchestrates UI components and handles user interactions

class SubInsightsApp {
    constructor() {
        this.backendUrl = 'http://localhost:5000/api';
        this.userId = 'user_1';
        this.benefitCard = null;
        this.mapView = null;
        this.alertPanel = null;
        this.updateInterval = null;
    }

    // Initialize application
    async init() {
        console.log('%cSubInsights Frontend Initialized', 'color: #2196F3; font-size: 16px; font-weight: bold;');
        
        // Initialize components
        this.mapView = new MapView('map-section', 37.7749, -122.4194);
        this.mapView.initialize();
        
        this.alertPanel = new AlertPanel('alert-section');
        this.alertPanel.initialize();
        
        // Make alert panel globally accessible
        window.alertPanel = this.alertPanel;
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Start auto-refresh
        this.startAutoRefresh();
        
        console.log('%c✓ Frontend ready for user interactions', 'color: #4CAF50;');
    }

    // Setup event listeners
    setupEventListeners() {
        const updateBtn = document.getElementById('update-location-btn');
        if (updateBtn) {
            updateBtn.addEventListener('click', () => this.simulateLocationUpdate());
        }

        const verifyBtn = document.getElementById('verify-benefits-btn');
        if (verifyBtn) {
            verifyBtn.addEventListener('click', () => this.verifyVisibleBenefits());
        }
    }

    // Simulate location update (in production: real GPS)
    async simulateLocationUpdate() {
        const latInput = document.getElementById('latitude-input');
        const lonInput = document.getElementById('longitude-input');
        
        const lat = latInput ? parseFloat(latInput.value) : 37.7749;
        const lon = lonInput ? parseFloat(lonInput.value) : -122.4194;
        
        console.log(`📍 Updating location to: ${lat}, ${lon}`);
        
        this.mapView.updateUserLocation(lat, lon);
        
        // In production: POST to /api/location/update
        await this.loadNearbyBenefits(lat, lon);
    }

    // Load and display nearby benefits
    async loadNearbyBenefits(lat, lon) {
        console.log('🔍 Fetching nearby benefits...');
        
        // Simulated API response (in production: fetch from backend)
        const nearbyBenefits = [
            {
                id: 'ben_hotel_discount',
                title: 'Hotel Discount',
                description: '15% off hotel stays',
                discount_percent: 15,
                is_verified: true,
                verification_score: 0.85,
                merchant: {
                    id: 'merch_marriott_001',
                    name: 'Marriott Hotels',
                    address: 'San Francisco, CA',
                    category: 'hotel'
                },
                distance_km: 0.8
            },
            {
                id: 'ben_amex_travel_credit',
                title: '$200 Annual Travel Credit',
                description: 'Get $200 credit toward travel purchases',
                discount_percent: 25,
                is_verified: true,
                verification_score: 0.95,
                merchant: {
                    id: 'merch_marriott_001',
                    name: 'Marriott Hotels',
                    address: 'San Francisco, CA',
                    category: 'hotel'
                },
                distance_km: 0.8
            },
            {
                id: 'ben_travel_incentive',
                title: 'Travel Incentive',
                description: 'Earn 2x points on all travel bookings',
                discount_percent: 5,
                is_verified: true,
                verification_score: 0.72,
                merchant: {
                    id: 'merch_united_001',
                    name: 'United Airlines',
                    address: 'San Francisco Airport, CA',
                    category: 'airline'
                },
                distance_km: 3.2
            },
            {
                id: 'ben_dining_credit',
                title: '$100 Dining Credit',
                description: 'Credit toward restaurant purchases',
                discount_percent: 10,
                is_verified: true,
                verification_score: 0.88,
                merchant: {
                    id: 'merch_restaurant_sf',
                    name: 'Michelin Restaurant SF',
                    address: 'San Francisco, CA',
                    category: 'restaurant'
                },
                distance_km: 1.5
            }
        ];

        // Clear previous benefits
        const benefitsContainer = document.getElementById('benefits-list');
        if (benefitsContainer) {
            benefitsContainer.innerHTML = '';
        }

        // Display each benefit
        for (const benefit of nearbyBenefits) {
            const card = new BenefitCard(benefit, benefit.merchant, benefit.distance_km);
            
            if (benefitsContainer) {
                const cardDiv = document.createElement('div');
                cardDiv.innerHTML = card.render();
                benefitsContainer.appendChild(cardDiv);
            }
            
            // Add to map
            this.mapView.addMerchant(benefit.merchant, benefit, benefit.distance_km);
        }

        console.log(`%c✓ Loaded ${nearbyBenefits.length} nearby benefits`, 'color: #4CAF50;');
        
        // Create mock alerts (in production: these would come from backend geofence detection)
        this.createMockAlerts(nearbyBenefits);
    }

    // Create mock alerts for demo
    createMockAlerts(benefits) {
        // Show top 2 benefits as alerts
        benefits.slice(0, 2).forEach((benefit, index) => {
            setTimeout(() => {
                this.alertPanel.addAlert({
                    id: `alert_${benefit.id}`,
                    title: `🎉 ${benefit.title} at ${benefit.merchant.name}`,
                    message: `${benefit.merchant.name} is honoring your ${benefit.title}! Get ${benefit.discount_percent}% off. Valid today.`,
                    discount: benefit.discount_percent,
                    priority: benefit.discount_percent >= 20 ? 'high' : 'medium'
                });
                
                console.log(`%c📢 Got alert: ${benefit.title}`, 'color: #FF9800; font-weight: bold;');
            }, index * 1000);
        });
    }

    // Handle benefit claim
    window.claimBenefit = function(benefitId) {
        const result = window.app.alertPanel.claimBenefit(benefitId);
        alert(`✓ ${result.message}\n\nRedemption Code: ${result.redemptionCode}\n\nShow this code at checkout!`);
        console.log('%c✓ Benefit claimed!', 'color: #4CAF50; font-weight: bold;', result);
    };

    // Handle benefit save
    window.saveBenefit = function(benefitId) {
        alert('✓ Benefit saved to your collection!');
    };

    // Verify visible benefits (BERT verification)
    async verifyVisibleBenefits() {
        console.log('%c🔬 Running BERT verification on visible benefits...', 'color: #9C27B0; font-weight: bold;');
        
        // In production: would call /api/benefits/<id>/verify
        alert('BERT verification running...\n\n- Scraping merchant reviews\n- Analyzing sentiment\n- Updating verification scores\n\nCheck console for details.');
    }

    // Start auto-refresh of data
    startAutoRefresh() {
        // Refresh every 30 seconds in demo
        this.updateInterval = setInterval(() => {
            console.log('%c🔄 Auto-refreshing nearby benefits...', 'color: #2196F3;');
        }, 30000);
    }

    // Stop auto-refresh
    stopAutoRefresh() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }
    }

    // Utils: Update UI status
    updateStatus(label, active = true) {
        const status = document.querySelector(`[data-status="${label}"] .status-indicator`);
        if (status) {
            status.classList.toggle('active', active);
            status.classList.toggle('inactive', !active);
        }
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
    window.app = new SubInsightsApp();
    await window.app.init();
    
    // Trigger initial load
    window.app.simulateLocationUpdate();
});
