"""
BERT Sentiment Verification Engine
Uses transformer-based NLP to verify benefits are active by analyzing 
recent merchant reviews for sentiment about membership perks
"""
from typing import List, Dict, Tuple
from datetime import datetime
import json


class BERTVerificationEngine:
    """
    Deep learning verification using BERT-style sentiment analysis
    
    How it works:
    1. Scraped recent merchant reviews are collected
    2. BERT encoder analyzes sentiment of discount/benefit mentions
    3. Sentiment score threshold determines if perk is "verified active"
    4. Updates benefit.is_verified and verification_score
    
    In production, would use:
    - transformers.AutoTokenizer
    - transformers.AutoModelForSequenceClassification
    
    For demo, uses simplified scoring based on keyword analysis.
    """
    
    def __init__(self):
        """Initialize BERT verification engine"""
        self.positive_keywords = [
            "great discount", "excellent deal", "highly recommended",
            "worth it", "saved money", "amazing offer", "perfect",
            "love it", "fantastic", "best", "awesome", "helpful",
            "reliable", "trust", "5 star", "happy", "satisfied",
            "discount worked", "redeemed", "claimed", "easy process",
            "verified", "legitimate", "works great"
        ]
        
        self.negative_keywords = [
            "expired", "not working", "doesn't work", "fake",
            "waste of time", "scam", "fraud", "deceptive",
            "terms changed", "no longer valid", "only applies to",
            "excluded", "restrictions", "complicated", "poor",
            "refused", "denied", "doesn't honor", "blacklisted",
            "disappointing", "overpriced", "bad experience"
        ]
        
        self.verification_history: Dict[str, List[Dict]] = {}
        
    def verify_benefit(self, 
                      benefit_id: str, 
                      merchant_name: str,
                      recent_reviews: List[str]) -> Tuple[bool, float, str]:
        """
        Verify if a benefit is active using sentiment analysis
        
        Args:
            benefit_id: ID of benefit to verify
            merchant_name: Name of merchant offering benefit
            recent_reviews: Recent customer review texts (web-scraped)
            
        Returns:
            Tuple of (is_verified: bool, confidence_score: 0-1, reasoning: str)
        """
        
        if not recent_reviews:
            return False, 0.0, "No recent reviews available"
            
        # Analyze sentiment of reviews mentioning the benefit
        positive_count = 0
        negative_count = 0
        relevant_reviews = 0
        
        for review in recent_reviews:
            review_lower = review.lower()
            
            # Check if review is about discounts/benefits
            if any(keyword in review_lower for keyword in 
                   ["discount", "offer", "deal", "benefit", "perk", "membership"]):
                relevant_reviews += 1
                
                # Count sentiment indicators
                pos_score = sum(1 for kw in self.positive_keywords 
                               if kw in review_lower)
                neg_score = sum(1 for kw in self.negative_keywords 
                               if kw in review_lower)
                
                if pos_score > neg_score:
                    positive_count += 1
                elif neg_score > pos_score:
                    negative_count += 1
        
        # Calculate verification score
        if relevant_reviews == 0:
            confidence = 0.5  # Neutral if no relevant reviews
            reasoning = "No reviews mentioning membership benefits found"
        else:
            positive_ratio = positive_count / relevant_reviews
            
            # BERT threshold: 0.6+ confidence means verified
            confidence = positive_ratio
            
            if confidence >= 0.6:
                is_verified = True
                reasoning = f"Strong positive sentiment ({int(positive_ratio*100)}% positive reviews)"
            elif confidence >= 0.4:
                is_verified = False
                reasoning = f"Mixed sentiment ({int(positive_ratio*100)}% positive) - Needs monitoring"
            else:
                is_verified = False
                reasoning = f"Negative sentiment ({int(positive_ratio*100)}% positive) - Likely expired"
        
        # Record in history
        if benefit_id not in self.verification_history:
            self.verification_history[benefit_id] = []
            
        self.verification_history[benefit_id].append({
            "timestamp": datetime.now().isoformat(),
            "is_verified": confidence >= 0.6,
            "confidence": confidence,
            "positive_reviews": positive_count,
            "negative_reviews": negative_count,
            "total_relevant": relevant_reviews
        })
        
        return confidence >= 0.6, confidence, reasoning
    
    def batch_verify_benefits(self, 
                            benefits_with_reviews: Dict[str, Tuple[str, List[str]]]) -> Dict[str, Dict]:
        """
        Verify multiple benefits at once
        
        Args:
            benefits_with_reviews: {benefit_id: (merchant_name, [reviews])}
            
        Returns:
            {benefit_id: {is_verified, confidence, reasoning, updated_at}}
        """
        results = {}
        
        for benefit_id, (merchant_name, reviews) in benefits_with_reviews.items():
            is_verified, confidence, reasoning = self.verify_benefit(
                benefit_id, merchant_name, reviews
            )
            
            results[benefit_id] = {
                "is_verified": is_verified,
                "confidence": confidence,
                "reasoning": reasoning,
                "updated_at": datetime.now().isoformat()
            }
        
        print(f"\n[BERT Verification] Verified {len(results)} benefits")
        for bid, result in results.items():
            status = "✓ VERIFIED" if result['is_verified'] else "✗ NOT VERIFIED"
            print(f"  {bid}: {status} (confidence: {result['confidence']:.1%})")
            
        return results
    
    def get_verification_history(self, benefit_id: str) -> List[Dict]:
        """Get verification history for a benefit"""
        return self.verification_history.get(benefit_id, [])
    
    def requires_reverification(self, benefit_id: str, max_age_hours: int = 24) -> bool:
        """
        Check if benefit needs reverification based on age of last check
        
        Args:
            benefit_id: ID of benefit to check
            max_age_hours: Maximum hours before re-verification needed
            
        Returns:
            True if reverification is needed
        """
        history = self.get_verification_history(benefit_id)
        
        if not history:
            return True
            
        last_check = history[-1]["timestamp"]
        last_check_dt = datetime.fromisoformat(last_check)
        age_hours = (datetime.now() - last_check_dt).total_seconds() / 3600
        
        return age_hours > max_age_hours
