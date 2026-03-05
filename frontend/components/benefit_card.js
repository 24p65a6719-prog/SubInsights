// BenefitCard Component
// Displays individual benefit card with discount info and action buttons

class BenefitCard {
    constructor(benefit, merchant, distanceKm) {
        this.benefit = benefit;
        this.merchant = merchant;
        this.distanceKm = distanceKm;
    }

    // Generate HTML for card
    render() {
        const discountColor = this.benefit.discount_percent >= 30 ? '#d4af37' : 
                            this.benefit.discount_percent >= 15 ? '#ff9800' : '#4CAF50';
        
        const verifiedBadge = this.benefit.is_verified ? 
            '✓ BERT Verified' : '⚠ Not Verified';
        
        return `
        <div class="benefit-card" style="border-left: 4px solid ${discountColor};">
            <div class="card-header">
                <h3>${this.benefit.title}</h3>
                <span class="verification-badge" title="BERT verification score">
                    ${verifiedBadge}
                </span>
            </div>
            
            <div class="discount-display">
                <span class="discount-percent">${this.benefit.discount_percent}%</span>
                <span class="discount-text">OFF at ${this.merchant.name}</span>
            </div>
            
            <div class="card-details">
                <p><strong>Description:</strong> ${this.benefit.description}</p>
                <p><strong>Location:</strong> ${this.merchant.address}</p>
                <p><strong>Distance:</strong> ${this.distanceKm.toFixed(2)} km away</p>
                <p><strong>Category:</strong> ${this.merchant.category.toUpperCase()}</p>
                ${this.benefit.verification_score > 0 ? 
                    `<p><strong>Confidence:</strong> ${(this.benefit.verification_score * 100).toFixed(0)}%</p>` : ''}
            </div>
            
            <div class="card-actions">
                <button class="btn-primary" onclick="claimBenefit('${this.benefit.id}')">
                    Claim Now
                </button>
                <button class="btn-secondary" onclick="saveBenefit('${this.benefit.id}')">
                    Save
                </button>
            </div>
        </div>
        `;
    }
}

// Export for use in main app
if (typeof module !== 'undefined' && module.exports) {
    module.exports = BenefitCard;
}
