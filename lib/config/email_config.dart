// Configuration for email services
// Configure your email service credentials here

class EmailConfig {
  // EmailJS Configuration (https://www.emailjs.com/)
  static const String emailJSServiceID = 'YOUR_SERVICE_ID';
  static const String emailJSTemplateID = 'YOUR_TEMPLATE_ID';
  static const String emailJSUserID = 'YOUR_USER_ID';
  
  // SendGrid Configuration (https://sendgrid.com/)
  static const String sendGridAPIKey = 'YOUR_SENDGRID_API_KEY';
  
  // SMTP Configuration (for custom SMTP servers)
  static const String smtpServer = 'YOUR_SMTP_SERVER';
  static const int smtpPort = 587;
  static const String smtpUsername = 'YOUR_SMTP_USERNAME';
  static const String smtpPassword = 'YOUR_SMTP_PASSWORD';
  
  // Email template
  static const String otpEmailSubject = 'Code de vérification - Application Naissance';
  static const String verificationEmailSubject = 'Vérification d\'email - Application Naissance';
}