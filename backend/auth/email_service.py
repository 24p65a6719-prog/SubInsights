"""
Email Service Module
Handles email delivery for OTP verification and notifications
"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List, Tuple
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class EmailService:
    """
    Email service for sending OTP and notifications
    
    Supports SMTP configuration for Gmail, Mailgun, or custom SMTP servers
    For demo, can use environment variables or fallback to console output
    """
    
    def __init__(
        self,
        smtp_server: str = "smtp.gmail.com",
        smtp_port: int = 587,
        sender_email: str = None,
        sender_password: str = None,
        demo_mode: bool = True
    ):
        """
        Initialize email service
        
        Args:
            smtp_server: SMTP server address
            smtp_port: SMTP port (usually 587 for TLS, 465 for SSL)
            sender_email: Sender email address (set from env or param)
            sender_password: Sender password/app password
            demo_mode: If True, print emails instead of sending
        """
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.sender_email = sender_email or os.environ.get("SENDER_EMAIL", "noreply@subinsights.com")
        self.sender_password = sender_password or os.environ.get("SENDER_PASSWORD", "demo_password")
        self.demo_mode = demo_mode
        self.email_log: List[dict] = []
    
    def send_otp_email(self, recipient_email: str, otp_code: str, full_name: str) -> Tuple[bool, str]:
        """
        Send OTP verification email
        
        Args:
            recipient_email: Recipient's email address
            otp_code: 6-digit OTP code
            full_name: Recipient's full name
        
        Returns:
            (success, message)
        """
        subject = "SubInsights - Email Verification (OTP)"
        
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; background-color: #f5f5f5;">
                <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px;">
                    <h2 style="color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px;">
                        Welcome to SubInsights
                    </h2>
                    
                    <p>Hi {full_name},</p>
                    
                    <p>Thank you for signing up! To complete your email verification, please use the OTP code below:</p>
                    
                    <div style="background-color: #3498db; color: white; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
                        <h1 style="margin: 0; letter-spacing: 5px; font-family: monospace;">{otp_code}</h1>
                    </div>
                    
                    <p style="color: #e74c3c;"><strong>⏱ This OTP is valid for 15 minutes.</strong></p>
                    
                    <p>If you didn't sign up for SubInsights, you can safely ignore this email.</p>
                    
                    <hr style="border: none; border-top: 1px solid #ecf0f1; margin: 20px 0;">
                    
                    <p style="color: #7f8c8d; font-size: 12px;">
                        SubInsights - Location-Aware Benefit Discovery<br>
                        Powered by geofencing and AI verification<br>
                        <a href="https://subinsights.com" style="color: #3498db;">Learn more</a>
                    </p>
                </div>
            </body>
        </html>
        """
        
        return self._send_email(recipient_email, subject, html_body, "OTP_VERIFICATION")
    
    def send_notification_email(
        self,
        recipient_email: str,
        recipient_name: str,
        hotel_name: str,
        discount_percentage: int,
        benefit_description: str,
        distance_km: float = None
    ) -> Tuple[bool, str]:
        """
        Send geofence notification email when user enters hotel location
        
        Args:
            recipient_email: User's email
            recipient_name: User's full name
            hotel_name: Hotel name where user is located
            discount_percentage: Discount percentage available
            benefit_description: Description of available benefit
            distance_km: Distance to hotel in km (optional)
        
        Returns:
            (success, message)
        """
        distance_text = f"({distance_km:.2f} km away)" if distance_km else ""
        
        subject = f"SubInsights: {discount_percentage}% Discount Available at {hotel_name}!"
        
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; background-color: #f5f5f5;">
                <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px;">
                    <h2 style="color: #27ae60; border-bottom: 3px solid #27ae60; padding-bottom: 10px;">
                        🎉 Great Deal Available!
                    </h2>
                    
                    <p>Hi {recipient_name},</p>
                    
                    <p>You're near <strong>{hotel_name}</strong> {distance_text} and a special offer awaits you!</p>
                    
                    <div style="background-color: #27ae60; color: white; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
                        <h1 style="margin: 10px 0;">{discount_percentage}% OFF</h1>
                        <p style="margin: 10px 0; font-size: 16px;">{benefit_description}</p>
                    </div>
                    
                    <p style="background-color: #ecf0f1; padding: 15px; border-radius: 8px;">
                        <strong>📍 Location-Based Offer:</strong><br>
                        This special discount is available exclusively at {hotel_name} through your active subscription.
                    </p>
                    
                    <p>
                        Open the SubInsights app to view more details and claim your discount!
                    </p>
                    
                    <hr style="border: none; border-top: 1px solid #ecf0f1; margin: 20px 0;">
                    
                    <p style="color: #7f8c8d; font-size: 12px;">
                        SubInsights - Location-Aware Benefit Discovery<br>
                        Offer valid for {recipient_name}'s active subscription<br>
                        Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
                    </p>
                </div>
            </body>
        </html>
        """
        
        return self._send_email(recipient_email, subject, html_body, "LOCATION_NOTIFICATION")
    
    def send_subscription_confirmation_email(
        self,
        recipient_email: str,
        recipient_name: str,
        subscription_name: str,
        subscription_id: str,
        expiry_date: str
    ) -> Tuple[bool, str]:
        """
        Send subscription purchase confirmation email
        
        Args:
            recipient_email: User's email
            recipient_name: User's name
            subscription_name: Name of subscription purchased
            subscription_id: ID of subscription
            expiry_date: When subscription expires
        
        Returns:
            (success, message)
        """
        subject = f"SubInsights - Subscription Confirmed: {subscription_name}"
        
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; background-color: #f5f5f5;">
                <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px;">
                    <h2 style="color: #3498db; border-bottom: 3px solid #3498db; padding-bottom: 10px;">
                        ✅ Subscription Active
                    </h2>
                    
                    <p>Hi {recipient_name},</p>
                    
                    <p>Your subscription to <strong>{subscription_name}</strong> is now active!</p>
                    
                    <div style="background-color: #ecf0f1; padding: 15px; border-radius: 8px; margin: 20px 0;">
                        <p><strong>Subscription Details:</strong></p>
                        <ul style="list-style: none; padding: 0;">
                            <li>📋 ID: {subscription_id}</li>
                            <li>📅 Valid Until: {expiry_date}</li>
                            <li>📍 Geofencing: Active</li>
                        </ul>
                    </div>
                    
                    <p>You'll now receive location-based notifications when you're near partner hotels and merchants offering exclusive benefits!</p>
                    
                    <hr style="border: none; border-top: 1px solid #ecf0f1; margin: 20px 0;">
                    
                    <p style="color: #7f8c8d; font-size: 12px;">
                        SubInsights - Location-Aware Benefit Discovery<br>
                        <a href="https://subinsights.com/my-subscriptions" style="color: #3498db;">View your active subscriptions</a>
                    </p>
                </div>
            </body>
        </html>
        """
        
        return self._send_email(recipient_email, subject, html_body, "SUBSCRIPTION_CONFIRMATION")
    
    def _send_email(self, recipient_email: str, subject: str, html_body: str, email_type: str) -> Tuple[bool, str]:
        """
        Internal method to send email via SMTP
        
        Args:
            recipient_email: Recipient's email address
            subject: Email subject
            html_body: HTML email body
            email_type: Type of email (for logging)
        
        Returns:
            (success, message)
        """
        # Log email
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "type": email_type,
            "recipient": recipient_email,
            "subject": subject,
            "status": "sent" if not self.demo_mode else "demo"
        }
        self.email_log.append(log_entry)
        
        if self.demo_mode:
            # In demo mode, print email instead of sending
            print("\n" + "="*80)
            print(f"📧 EMAIL ({email_type}) - DEMO MODE")
            print("="*80)
            print(f"To: {recipient_email}")
            print(f"Subject: {subject}")
            print("-"*80)
            print(html_body[:200] + "..." if len(html_body) > 200 else html_body)
            print("="*80 + "\n")
            return True, f"Email sent to {recipient_email} (demo mode)"
        
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.sender_email
            message["To"] = recipient_email
            
            # Attach HTML body
            part = MIMEText(html_body, "html")
            message.attach(part)
            
            # Send email via SMTP
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, recipient_email, message.as_string())
            
            return True, f"Email sent to {recipient_email}"
        
        except Exception as e:
            error_msg = f"Failed to send email to {recipient_email}: {str(e)}"
            print(f"[EmailService Error] {error_msg}")
            return False, error_msg
    
    def get_email_log(self) -> List[dict]:
        """Get log of all sent emails"""
        return self.email_log.copy()
    
    def get_email_stats(self) -> dict:
        """Get statistics about sent emails"""
        total = len(self.email_log)
        by_type = {}
        for entry in self.email_log:
            email_type = entry["type"]
            by_type[email_type] = by_type.get(email_type, 0) + 1
        
        return {
            "total_emails": total,
            "by_type": by_type,
            "demo_mode": self.demo_mode
        }

# Create singleton instance
# Load configuration from environment
demo_mode_env = os.environ.get('DEMO_MODE', 'true').lower() == 'true'
sender_email = os.environ.get('SENDER_EMAIL')
smtp_password = os.environ.get('SENDER_PASSWORD')

# Check if we have valid credentials
if sender_email and smtp_password and not demo_mode_env and 'your_gmail_app_password_here' not in smtp_password:
    email_service = EmailService(
        smtp_server=os.environ.get('SMTP_SERVER', 'smtp.gmail.com'),
        smtp_port=int(os.environ.get('SMTP_PORT', 587)),
        sender_email=sender_email,
        sender_password=smtp_password,
        demo_mode=False
    )
    print("[EmailService] Using REAL EMAIL MODE - Emails will be sent via SMTP")
else:
    email_service = EmailService(demo_mode=True)
    print("[EmailService] Using DEMO MODE - OTP shown on page (no real email sending)")
    if demo_mode_env or not sender_email or not smtp_password or 'your_gmail_app_password_here' in str(smtp_password):
        print("[EmailService] To enable real email sending, configure .env file with valid Gmail app password")
