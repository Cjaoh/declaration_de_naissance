# Guide de Test du Système de Vérification

Ce guide explique comment tester le système de vérification d'email et OTP dans votre application.

## Étapes de Test

### 1. Test de l'envoi d'OTP par email

1. **Lancez l'application**
2. **Accédez à l'écran d'inscription**
3. **Remplissez le formulaire avec une adresse email valide**
4. **Cliquez sur "CRÉER MON COMPTE"**
5. **Vérifiez que :**
   - Le code OTP est généré
   - L'email est envoyé (vérifiez la console pour les logs)
   - La boîte de dialogue OTP s'affiche

### 2. Test de la vérification OTP

1. **Vérifiez votre boîte email** pour le code OTP
2. **Saisissez le code dans les champs** de la boîte de dialogue
3. **Vérifiez que :**
   - La validation est réussie
   - Vous passez à l'étape suivante

### 3. Test de l'envoi d'email de vérification Firebase

1. **Après la vérification OTP**, l'utilisateur est créé dans Firebase Auth
2. **Un email de vérification est automatiquement envoyé**
3. **Vérifiez que :**
   - L'email de vérification est envoyé
   - La boîte de dialogue de vérification email s'affiche

### 4. Test de la vérification email

1. **Cliquez sur le lien** dans l'email de vérification
2. **Revenez à l'application**
3. **Cliquez sur "J'ai vérifié"**
4. **Vérifiez que :**
   - L'utilisateur est redirigé vers le tableau de bord
   - Le profil est créé dans Firestore et SQLite

## Résolution des Problèmes

### Problème : Les emails OTP ne sont pas reçus

1. **Vérifiez la configuration email** :
   - Assurez-vous d'avoir configuré un service d'email dans `lib/config/email_config.dart`
   - Vérifiez les identifiants du service

2. **Vérifiez la console** :
   - Regardez les logs pour les messages d'erreur
   - Vérifiez si l'email est simulé (message dans les logs)

3. **Testez avec une autre adresse email** :
   - Parfois, certains fournisseurs bloquent les emails

### Problème : Les emails de vérification Firebase ne sont pas reçus

1. **Vérifiez la configuration Firebase Auth** :
   - Connectez-vous à la console Firebase
   - Allez dans Authentication > Paramètres
   - Vérifiez les modèles d'email

2. **Vérifiez le domaine** :
   - Assurez-vous que votre domaine est vérifié
   - Vérifiez les paramètres d'expéditeur

3. **Vérifiez les spams** :
   - Les emails peuvent être filtrés comme spam

### Problème : L'OTP n'est pas accepté

1. **Vérifiez le code** :
   - Assurez-vous de saisir le bon code
   - Les codes expirent après 10 minutes

2. **Renvoyez le code** :
   - Utilisez le bouton "Renvoyer" dans la boîte de dialogue

## Tests Automatisés

Pour exécuter les tests automatisés :

```bash
flutter test
```

## Tests Manuelles Recommandés

1. **Test avec différentes adresses email** :
   - Gmail, Outlook, Yahoo, etc.

2. **Test avec des connexions lentes** :
   - Simulez une mauvaise connexion

3. **Test des cas d'erreur** :
   - Saisie incorrecte de l'OTP
   - Email non vérifié
   - Temps d'expiration

## Surveillance

1. **Vérifiez les logs Firebase** :
   - Authentication > Logs

2. **Surveillez Firestore** :
   - Collection `otp_codes` pour les codes
   - Collection `email_verifications` pour les vérifications

## Support

Pour obtenir de l'aide supplémentaire :
- Consultez la documentation dans `VERIFICATION_FEATURES.md`
- Vérifiez les logs de l'application
- Contactez l'équipe de développement