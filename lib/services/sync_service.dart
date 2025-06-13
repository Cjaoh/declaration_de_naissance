import '../models/naissance.dart';

class SyncService {
  Future<void> syncDeclarations(List<Naissance> declarations) async {
    // Simule la synchronisation avec un serveur distant
    await Future.delayed(const Duration(seconds: 2));
    // Ici tu pourrais envoyer les données à une API REST
  }
}