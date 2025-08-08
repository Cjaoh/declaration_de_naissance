# Configuration des Emails pour l'Application

Ce guide explique comment configurer les services d'envoi d'emails pour votre application Flutter.

## Services d'Email Supportés

### 1. EmailJS (Recommandé pour les débutants)

EmailJS est un service simple qui ne nécessite pas de backend. Il fonctionne directement depuis le navigateur ou l'application mobile.

#### Étapes de configuration :

1. **Créez un compte EmailJS** : https://www.emailjs.com/
2. **Créez un service Email** dans votre tableau de bord EmailJS
3. **Créez un template d'email** avec les variables nécessaires
4. **Obtenez vos identifiants** :
   - Service ID
   - Template ID
   - User ID
5. **Configurez le fichier `lib/config/email_config.dart`** :
   ```dart
   static const String emailJSServiceID = 'votre_service_id';
   static const String emailJSTemplateID = 'votre_template_id';
   static const String emailJSUserID = 'votre_user_id';
   ```

#### Variables du template EmailJS :

Pour les emails OTP, utilisez ces variables dans votre template :
- `to_email` : L'adresse email du destinataire
- `subject` : Le sujet de l'email
- `message` : Le contenu de l'email (contient le code OTP)

Exemple de template EmailJS :
```
Bonjour,

Votre code de vérification est : {{message}}

Ce code expirera dans 10 minutes.

Cordialement,
L'équipe de l'Application Naissance
```

### 2. SendGrid

Pour utiliser SendGrid :

1. **Créez un compte SendGrid** : https://sendgrid.com/
2. **Générez une API Key**
3. **Configurez le fichier `lib/config/email_config.dart`** :
   ```dart
   static const String sendGridAPIKey = 'votre_api_key';
   ```

### 3. SMTP personnalisé

Pour utiliser un serveur SMTP personnalisé :

1. **Obtenez les paramètres SMTP** de votre fournisseur
2. **Configurez le fichier `lib/config/email_config.dart`** :
   ```dart
   static const String smtpServer = 'votre_serveur_smtp';
   static const int smtpPort = 587; // ou 465, 25 selon votre serveur
   static const String smtpUsername = 'votre_nom_utilisateur';
   static const String smtpPassword = 'votre_mot_de_passe';
   ```

## Test de la configuration

Après avoir configuré l'un des services ci-dessus :

1. **Redémarrez l'application Flutter**
2. **Testez l'inscription** avec une adresse email valide
3. **Vérifiez que vous recevez le code OTP** dans votre boîte email

## Résolution des problèmes

### Problème : Les emails ne sont pas reçus

1. **Vérifiez les spams** : Les emails peuvent être filtrés comme spam
2. **Vérifiez la configuration** : Assurez-vous que vos identifiants sont corrects
3. **Testez avec une autre adresse email** : Parfois, certains fournisseurs bloquent les emails

### Problème : Erreurs dans la console

1. **Vérifiez les logs** : Regardez les messages d'erreur dans la console
2. **Vérifiez la connexion Internet** : L'application doit avoir accès à Internet
3. **Vérifiez les quotas** : Certains services ont des limites d'envoi

## Sécurité

- **Ne commitez jamais vos identifiants** dans un dépôt public
- **Utilisez des variables d'environnement** pour les applications en production
- **Protégez vos API Keys** en les limitant aux domaines/applications autorisés

## Support

Pour obtenir de l'aide supplémentaire, consultez :
- La documentation EmailJS : https://www.emailjs.com/docs/
- La documentation SendGrid : https://docs.sendgrid.com/
- Les forums de développement Flutter