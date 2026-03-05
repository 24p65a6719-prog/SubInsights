// AlertPanel Component
// Displays real-time alerts and notifications

class AlertPanel {
    constructor(containerId) {
        this.containerId = containerId;
        this.alerts = [];
        this.claimedCount = 0;
    }

    // Initialize alert panel
    initialize() {
        const container = document.getElementById(this.containerId);
        if (!container) return;

        container.innerHTML = `
        <div class="alert-panel">
            <div class="alerts-header">
                <h2>🔔 Real-Time Alerts</h2>
                <div class="alert-stats">
                    <span>Pending: <strong id="pending-count">0</strong></span>
                    <span>Claimed: <strong id="claimed-count">0</strong></span>
                </div>
            </div>
            <div id="alerts-container" class="alerts-container">
                <p class="empty-state">No alerts yet. Check map for nearby benefits!</p>
            </div>
        </div>
        `;
    }

    // Add new alert
    addAlert(alert) {
        this.alerts.push({
            ...alert,
            timestamp: new Date(),
            status: 'pending'
        });
        this._updateDisplay();
    }

    // Mark alert as claimed
    claimAlert(alertId) {
        const alert = this.alerts.find(a => a.id === alertId);
        if (alert) {
            alert.status = 'claimed';
            this.claimedCount++;
            this._updateDisplay();
            return {
                status: 'success',
                message: `Claimed: ${alert.title}`,
                redemptionCode: `SUB${Math.random().toString(36).substr(2, 6).toUpperCase()}`
            };
        }
        return { status: 'error', message: 'Alert not found' };
    }

    // Dismiss alert
    dismissAlert(alertId) {
        this.alerts = this.alerts.filter(a => a.id !== alertId);
        this._updateDisplay();
    }

    // Get pending alerts
    getPendingAlerts() {
        return this.alerts.filter(a => a.status === 'pending');
    }

    // Private: Update display
    _updateDisplay() {
        const container = document.getElementById('alerts-container');
        const pendingCount = document.getElementById('pending-count');
        const claimedCount = document.getElementById('claimed-count');

        if (pendingCount) pendingCount.textContent = this.getPendingAlerts().length;
        if (claimedCount) claimedCount.textContent = this.claimedCount;

        if (this.alerts.length === 0) {
            container.innerHTML = '<p class="empty-state">No alerts yet</p>';
            return;
        }

        let html = '';

        this.getPendingAlerts().forEach(alert => {
            const priorityClass = `priority-${alert.priority}`;
            const time = alert.timestamp.toLocaleTimeString();

            html += `
            <div class="alert-item ${priorityClass}">
                <div class="alert-content">
                    <p class="alert-title">${alert.title}</p>
                    <p class="alert-message">${alert.message}</p>
                    <div class="alert-meta">
                        <span class="time">${time}</span>
                        <span class="discount">${alert.discount}% off</span>
                    </div>
                </div>
                <div class="alert-actions">
                    <button class="btn-claim" onclick="window.alertPanel.claimAlert('${alert.id}')">
                        💳 Claim
                    </button>
                    <button class="btn-dismiss" onclick="window.alertPanel.dismissAlert('${alert.id}')">
                        ✕
                    </button>
                </div>
            </div>
            `;
        });

        container.innerHTML = html;
    }
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = AlertPanel;
}
