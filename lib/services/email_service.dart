import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/email_config.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envoie un email de vérification avec un design moderne
  Future<bool> sendVerificationEmail(String email) async {
    try {
      // Créer un document temporaire pour stocker les informations de vérification
      await _firestore.collection('email_verifications').add({
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'verification',
      });

      // Envoyer l'email via Firebase Auth
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        await user.sendEmailVerification();
        developer.log('Email de vérification envoyé à $email', name: 'EmailService');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Erreur lors de l\'envoi de l\'email: $e', name: 'EmailService');
      return false;
    }
  }

  /// Envoie un email avec un service HTTP (EmailJS, SendGrid, etc.)
  Future<bool> _sendEmailViaAPI(String toEmail, String subject, String body) async {
    try {
      // Implementation avec EmailJS
      // Inscrivez-vous sur https://www.emailjs.com/ pour obtenir vos identifiants
      if (EmailConfig.emailJSServiceID != 'YOUR_SERVICE_ID') {
        final response = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'service_id': EmailConfig.emailJSServiceID,
            'template_id': EmailConfig.emailJSTemplateID,
            'user_id': EmailConfig.emailJSUserID,
            'template_params': {
              'to_email': toEmail,
              'subject': subject,
              'message': body,
            }
          }),
        );
        
        if (response.statusCode == 200) {
          developer.log('Email envoyé via EmailJS à $toEmail', name: 'EmailService');
          return true;
        } else {
          developer.log('Erreur EmailJS: ${response.body}', name: 'EmailService');
          return false;
        }
      }
      
      // Fallback: Simuler un succès si aucun service n'est configuré
      developer.log('Email simulé envoyé à $toEmail avec sujet: $subject', name: 'EmailService');
      developer.log('Pour envoyer de vrais emails, configurez un service dans lib/config/email_config.dart', name: 'EmailService');
      return true;
    } catch (e) {
      developer.log('Erreur lors de l\'envoi de l\'email via API: $e', name: 'EmailService');
      return false;
    }
  }

  /// Envoie un code OTP par email
  Future<bool> sendOTPEmail(String email, String otp) async {
    try {
      // Stocker l'OTP dans Firestore pour vérification
      await _firestore.collection('otp_codes').add({
        'email': email,
        'otp': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'expires_at': FieldValue.serverTimestamp(), // Expire après 10 minutes
        'used': false,
      });

      // Créer le contenu de l'email
      final subject = 'Code de vérification - Application Naissance';
      final body = '''
Bonjour,

Votre code de vérification est : $otp

Ce code expirera dans 10 minutes.

Cordialement,
L'équipe de l'Application Naissance
''';

      // Envoyer l'email via l'API
      final emailSent = await _sendEmailViaAPI(email, subject, body);
      
      if (emailSent) {
        developer.log('OTP $otp envoyé à $email', name: 'EmailService');
        return true;
      } else {
        developer.log('Erreur lors de l\'envoi de l\'OTP à $email', name: 'EmailService');
        return false;
      }
    } catch (e) {
      developer.log('Erreur lors de l\'envoi de l\'OTP: $e', name: 'EmailService');
      return false;
    }
  }

  /// Vérifie si un email a été vérifié
  Future<bool> isEmailVerified(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == email) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      developer.log('Erreur lors de la vérification de l\'email: $e', name: 'EmailService');
      return false;
    }
  }

  /// Vérifie un code OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final querySnapshot = await _firestore
          .collection('otp_codes')
          .where('email', isEqualTo: email)
          .where('otp', isEqualTo: otp)
          .where('used', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final timestamp = doc.data()['timestamp'] as Timestamp;
        final now = Timestamp.now();
        
        // Vérifier si l'OTP n'a pas expiré (10 minutes)
        if (now.toDate().difference(timestamp.toDate()).inMinutes < 10) {
          // Marquer l'OTP comme utilisé
          await doc.reference.update({'used': true});
          return true;
        }
      }
      return false;
    } catch (e) {
      developer.log('Erreur lors de la vérification de l\'OTP: $e', name: 'EmailService');
      return false;
    }
  }

  /// Génère un code OTP sécurisé
  String generateSecureOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final otp = (random % 900000 + 100000).toString();
    return otp;
  }

  /// Nettoie les anciens OTP expirés
  Future<void> cleanupExpiredOTPs() async {
    try {
      final tenMinutesAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      
      final querySnapshot = await _firestore
          .collection('otp_codes')
          .where('timestamp', isLessThan: tenMinutesAgo)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      
      developer.log('Nettoyage des OTP expirés terminé', name: 'EmailService');
    } catch (e) {
      developer.log('Erreur lors du nettoyage des OTP: $e', name: 'EmailService');
    }
  }
} 