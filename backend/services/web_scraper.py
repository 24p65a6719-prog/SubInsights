"""
Web Scraper Service
Collects merchant reviews from web for BERT verification
"""
import json
from typing import List, Dict
from datetime import datetime, timedelta


class WebScraperService:
    """
    Scrapes recent customer reviews from merchant websites and review platforms
    
    In production, would integrate with:
    - Google Reviews API
    - Yelp API
    - TripAdvisor API
    - Direct merchant review pages (BeautifulSoup)
    
    For demo: Returns simulated review data with realistic content
    """
    
    def __init__(self):
        """Initialize web scraper"""
        self.scraped_reviews: Dict[str, List[Dict]] = {}
        self.last_scrape_time: Dict[str, datetime] = {}
        
    def scrape_merchant_reviews(self, merchant_id: str, merchant_name: str) -> List[str]:
        """
        Scrape recent reviews for a merchant
        
        Args:
            merchant_id: ID of merchant
            merchant_name: Name of merchant
            
        Returns:
            List of review texts
        """
        
        # Check if reviews are cached and recent (less than 24 hours old)
        if merchant_id in self.last_scrape_time:
            age = datetime.now() - self.last_scrape_time[merchant_id]
            if age < timedelta(hours=24):
                print(f"[Scraper] Using cached reviews for {merchant_name}")
                return self.scraped_reviews.get(merchant_id, [])
        
        # Simulate scraping reviews
        print(f"[Scraper] Fetching recent reviews for {merchant_name}...")
        
        reviews = self._get_simulated_reviews(merchant_name)
        
        self.scraped_reviews[merchant_id] = reviews
        self.last_scrape_time[merchant_id] = datetime.now()
        
        print(f"[Scraper] Retrieved {len(reviews)} reviews for {merchant_name}")
        
        return reviews
    
    def _get_simulated_reviews(self, merchant_name: str) -> List[str]:
        """
        Get realistic example reviews (in production: actual web-scraped data)
        Different merchants have different review profiles
        """
        
        # Database of merchant review patterns
        merchant_reviews = {
            "Marriott Hotels": [
                "Great stay! The IEEE member discount worked perfectly. Saved $50 on my room.",
                "Excellent hotel, tried to use my membership discount but had some issues at first.",
                "Highly recommended! Staff was helpful and verified my professional membership benefits.",
                "Perfect! The hotel honors all the advertised perks. Very satisfied.",
                "Amazing experience. The discount was applied easily and staff was knowledgeable.",
            ],
            "United Airlines": [
                "Excellent service. Professional member discount saved me on this flight.",
                "The baggage waiver worked great! Very satisfied with membership benefits.",
                "Some confusion about which benefits apply, but eventually honored the discount.",
                "IEI member benefits not honored on basic economy fares. Be careful.",
                "Fantastic! Full benefits package working as advertised. Highly satisfied.",
            ],
            "American Express": [
                "Best credit card ever. Using the dining credit is so easy!",
                "Skeptical about the travel credits, but honestly they work perfectly.",
                "Hotel credits are easy to claim. Very happy with this card.",
                "The benefits seem great but lots of restrictions and blackout dates.",
                "Worth it just for the welcome bonus. Benefits actually valid too!",
            ],
            "Hilton Hotels": [
                "Great deal with member discount! Worked as advertised.",
                "Hotel tried to deny the discount initially but eventually honored it.",
                "Excellent stay, all perks verified and easily redeemed.",
                "Mixed experience - discount applied but benefits limited to certain rooms.",
                "Perfect! Elite benefits all working, staff was amazing.",
            ],
            "Default": [
                "Recently used a membership benefit here - worked great!",
                "The advertised perk was honored without any issues.",
                "Good experience claiming the membership discount.",
                "Benefits are real and easy to redeem.",
                "Worth having the membership just for this place.",
            ]
        }
        
        # Return reviews for this merchant, or defaults
        reviews = merchant_reviews.get(merchant_name, merchant_reviews["Default"])
        
        # Add some timestamp info (in production: actual review dates)
        return reviews[:5]  # Return last 5 reviews
    
    def scrape_benefit_mentions(self, merchant_id: str, benefit_keyword: str) -> List[str]:
        """
        Extract reviews that specifically mention a benefit
        
        Args:
            merchant_id: Merchant to search
            benefit_keyword: Keyword to search for (e.g., "discount", "waiver")
            
        Returns:
            List of reviews mentioning the benefit
        """
        reviews = self.scraped_reviews.get(merchant_id, [])
        
        matching = [r for r in reviews if benefit_keyword.lower() in r.lower()]
        return matching
    
    def batch_scrape_merchants(self, merchant_list: List[Dict]) -> Dict[str, List[str]]:
        """
        Scrape reviews for multiple merchants
        
        Args:
            merchant_list: List of {id, name} dicts
            
        Returns:
            {merchant_id: [reviews]}
        """
        results = {}
        
        for merchant in merchant_list:
            reviews = self.scrape_merchant_reviews(
                merchant["id"], 
                merchant["name"]
            )
            results[merchant["id"]] = reviews
            
        return results
    
    def get_review_stats(self, merchant_id: str) -> Dict:
        """Get statistics about scraped reviews"""
        reviews = self.scraped_reviews.get(merchant_id, [])
        
        if not reviews:
            return {"total": 0, "average_length": 0}
            
        return {
            "total": len(reviews),
            "average_length": sum(len(r) for r in reviews) / len(reviews),
            "last_scraped": self.last_scrape_time.get(merchant_id).isoformat()
        }
