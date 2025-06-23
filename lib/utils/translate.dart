import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

String tr(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  switch (key) {
    case 'settings':
      if (lang == 'mg') return 'Toerana';
      if (lang == 'en') return 'Settings';
      return 'Paramètres';
    case 'preferences':
      if (lang == 'mg') return 'Safidy';
      if (lang == 'en') return 'Preferences';
      return 'Préférences';
    case 'dark_mode':
      if (lang == 'mg') return 'Maizina';
      if (lang == 'en') return 'Dark mode';
      return 'Mode sombre';
    case 'language':
      if (lang == 'mg') return 'Fiteny';
      if (lang == 'en') return 'Language';
      return 'Langue';
    case 'account':
      if (lang == 'mg') return 'Kaonty';
      if (lang == 'en') return 'Account';
      return 'Compte';
    case 'change_password':
      if (lang == 'mg') return 'Hanova tenimiafina';
      if (lang == 'en') return 'Change password';
      return 'Changer mot de passe';
    case 'logout':
      if (lang == 'mg') return 'Hiala';
      if (lang == 'en') return 'Logout';
      return 'Se déconnecter';
    case 'connexion':
      if (lang == 'mg') return 'Hiditra';
      if (lang == 'en') return 'Login';
      return 'Connexion';
    case 'create_account':
      if (lang == 'mg') return 'Mamorona kaonty';
      if (lang == 'en') return 'Create account';
      return 'Créer un compte';
    case 'dashboard':
      if (lang == 'mg') return 'Tahirin-kevitra';
      if (lang == 'en') return 'Dashboard';
      return 'Tableau de bord';
    case 'declarations':
      if (lang == 'mg') return 'Fanambaràna';
      if (lang == 'en') return 'Declarations';
      return 'Déclarations';
    case 'synchronization':
      if (lang == 'mg') return 'Fanatontoloana';
      if (lang == 'en') return 'Synchronization';
      return 'Synchronisation';
    case 'help':
      if (lang == 'mg') return 'Fanampiana';
      if (lang == 'en') return 'Help';
      return 'Aide';
    case 'disconnect':
      if (lang == 'mg') return 'Hiala';
      if (lang == 'en') return 'Disconnect';
      return 'Déconnexion';
    case 'version':
      if (lang == 'mg') return 'Karazana';
      if (lang == 'en') return 'Version';
      return 'Version';
    case 'email':
      if (lang == 'mg') return 'Mailaka';
      if (lang == 'en') return 'Email';
      return 'Email';
    case 'password':
      if (lang == 'mg') return 'Tenimiafina';
      if (lang == 'en') return 'Password';
      return 'Mot de passe';
    case 'confirm_password':
      if (lang == 'mg') return 'Amarina ny tenimiafina';
      if (lang == 'en') return 'Confirm password';
      return 'Confirmer le mot de passe';
    case 'register':
      if (lang == 'mg') return 'Hisoratra';
      if (lang == 'en') return 'Register';
      return 'Inscription';
    case 'sync_now':
      if (lang == 'mg') return 'Ataovy fanatontoloana ankehitriny';
      if (lang == 'en') return 'Sync now';
      return 'SYNCHRONISER MAINTENANT';
    case 'last_sync':
      if (lang == 'mg') return 'Fanatontoloana farany:';
      if (lang == 'en') return 'Last sync:';
      return 'Dernière synchro:';
    case 'never':
      if (lang == 'mg') return 'Tsy nisy';
      if (lang == 'en') return 'Never';
      return 'Jamais';
    case 'sync_success':
      if (lang == 'mg') return 'Nahomby ny fanatontoloana!';
      if (lang == 'en') return 'Sync successful!';
      return 'Synchronisation réussie!';
    case 'sync_error':
      if (lang == 'mg') return 'Diso ny fanatontoloana:';
      if (lang == 'en') return 'Sync error:';
      return 'Erreur de synchronisation:';
    case 'syncing':
      if (lang == 'mg') return 'Ataovy fanatontoloana...';
      if (lang == 'en') return 'Syncing...';
      return 'Synchronisation en cours...';
    case 'declaration_list':
      if (lang == 'mg') return 'Lisitry ny fanambaràna';
      if (lang == 'en') return 'Declaration list';
      return 'Liste des déclarations';
    case 'search':
      if (lang == 'mg') return 'Fikarohana';
      if (lang == 'en') return 'Search';
      return 'Rechercher';
    case 'edit':
      if (lang == 'mg') return 'Hanitsy';
      if (lang == 'en') return 'Edit';
      return 'Modifier';
    case 'delete':
      if (lang == 'mg') return 'Hamafa';
      if (lang == 'en') return 'Delete';
      return 'Supprimer';
    case 'cancel':
      if (lang == 'mg') return 'Hanamafisana';
      if (lang == 'en') return 'Cancel';
      return 'Annuler';
    case 'save':
      if (lang == 'mg') return 'Te-hijery';
      if (lang == 'en') return 'Save';
      return 'Enregistrer';
    case 'name':
      if (lang == 'mg') return 'Anarana';
      if (lang == 'en') return 'Name';
      return 'Nom';
    case 'first_name':
      if (lang == 'mg') return 'Fanampiana';
      if (lang == 'en') return 'First name';
      return 'Prénom';
    case 'birth_date':
      if (lang == 'mg') return 'Daty nahaterahana';
      if (lang == 'en') return 'Birth date';
      return 'Date de naissance';
    case 'birth_place':
      if (lang == 'mg') return 'Toerana nahaterahana';
      if (lang == 'en') return 'Birth place';
      return 'Lieu de naissance';
    case 'gender':
      if (lang == 'mg') return 'Lahy na vavy';
      if (lang == 'en') return 'Gender';
      return 'Sexe';
    case 'boy':
      if (lang == 'mg') return 'Lahy';
      if (lang == 'en') return 'Boy';
      return 'Garçon';
    case 'girl':
      if (lang == 'mg') return 'Vavy';
      if (lang == 'en') return 'Girl';
      return 'Fille';
    case 'select_date':
      if (lang == 'mg') return 'Fidiana daty';
      if (lang == 'en') return 'Select date';
      return 'Sélectionner une date';
    case 'required_field':
      if (lang == 'mg') return 'Fidiana ilaina';
      if (lang == 'en') return 'Required field';
      return 'Champ obligatoire';
    case 'min_characters':
      if (lang == 'mg') return '6 tora-baiko latsaka indrindra';
      if (lang == 'en') return 'Minimum 6 characters';
      return 'Minimum 6 caractères';
    case 'passwords_dont_match':
      if (lang == 'mg') return 'Tsy mitovy ny tenimiafina';
      if (lang == 'en') return 'Passwords do not match';
      return 'Les mots de passe ne correspondent pas';
    case 'declaration_success':
      if (lang == 'mg') return 'Nahomby ny fanambaràna!';
      if (lang == 'en') return 'Declaration successful!';
      return 'Déclaration enregistrée avec succès!';
    case 'no_declaration':
      if (lang == 'mg') return 'Tsy misy fanambaràna voarara';
      if (lang == 'en') return 'No declarations recorded';
      return 'Aucune déclaration enregistrée';
    case 'boys':
      if (lang == 'mg') return 'Lahy:';
      if (lang == 'en') return 'Boys:';
      return 'Garçons:';
    case 'girls':
      if (lang == 'mg') return 'Vavy:';
      if (lang == 'en') return 'Girls:';
      return 'Filles:';
    default:
      return key;
  }
}

class MalagasyMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const MalagasyMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mg';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture(MalagasyMaterialLocalizations());
  }

  @override
  bool shouldReload(covariant MalagasyMaterialLocalizationsDelegate old) => false;
}

class MalagasyMaterialLocalizations extends DefaultMaterialLocalizations {
  @override
  String get okButtonLabel => 'DIA';

  @override
  String get cancelButtonLabel => 'TSIA';
}

class MalagasyLocalizations {
  static const LocalizationsDelegate<MaterialLocalizations> materialDelegate = MalagasyMaterialLocalizationsDelegate();
}
