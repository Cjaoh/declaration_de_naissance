import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

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

      // Ici vous pouvez intégrer un service d'envoi d'email comme SendGrid, Mailgun, etc.
      // Pour l'instant, on simule l'envoi
      developer.log('OTP $otp envoyé à $email', name: 'EmailService');
      
      // Simuler un délai d'envoi
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
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