import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../theme/app_theme.dart';
import 'ai_settings_page.dart';

/// Page des paramètres
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    final locale = ref.watch(localeProvider);
    final aiConnected = ref.watch(aiConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Appareil photo et médias
            _buildSectionHeader('Appareil photo et médias'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Stockage'),
                    subtitle: const Text('Gérer le stockage des photos'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToStorageSettings(),
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Sauvegarde'),
                    subtitle: const Text('Sauvegarder les photos'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToBackupSettings(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // IA et automatisation
            _buildSectionHeader('IA et automatisation'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_awesome),
                    title: const Text('Assistant IA Mistral'),
                    subtitle: Text(aiConnected ? 'Connecté' : 'Déconnecté'),
                    value: aiConnected,
                    onChanged: (value) => _toggleAiConnection(value),
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('Clé API Mistral'),
                    subtitle: Text(_getApiKeyStatus()),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showApiKeyDialog(),
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(Icons.settings_input_antenna),
                    title: const Text('Paramètres IA'),
                    subtitle: const Text('Configurer Mistral AI'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiSettingsPage()),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Apparence
            _buildSectionHeader('Apparence'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Mode sombre'),
                    subtitle: const Text('Activer le thème sombre'),
                    value: darkMode,
                    onChanged: (value) => ref.read(darkModeProvider.notifier).state = value,
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Langue'),
                    subtitle: Text(_getLanguageName(locale)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageDialog(),
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(Icons.text_increase),
                    title: const Text('Taille du texte'),
                    subtitle: const Text('Moyen'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showTextSizeDialog(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations
            _buildSectionHeader('Informations'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('À propos de GitPhoto Studio IA'),
                    subtitle: const Text('Version 1.0.0'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showAboutDialog(),
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Aide'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showHelp(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Déconnexion (si nécessaire)
            if (_shouldShowLogout())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const SizedBox(
                    width: double.infinity,
                    child: Text('Déconnexion', textAlign: TextAlign.center),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Construit un en-tête de section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Navigue vers les paramètres de stockage
  void _navigateToStorageSettings() {
    // À implémenter
  }

  /// Navigue vers les paramètres de sauvegarde
  void _navigateToBackupSettings() {
    // À implémenter
  }

  /// Active/désactive la connexion IA
  void _toggleAiConnection(bool value) {
    ref.read(aiConnectedProvider.notifier).state = value;
  }

  /// Récupère le statut de la clé API
  String _getApiKeyStatus() {
    // À implémenter - vérifier si la clé API est configurée
    return 'Non configurée';
  }

  /// Affiche le dialogue de clé API
  void _showApiKeyDialog() {
    final apiKeyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clé API Mistral'),
        content: TextField(
          controller: apiKeyController,
          decoration: const InputDecoration(
            labelText: 'Entrer votre clé API',
            hintText: 'ex: sk-xxxxxxxxxxxxxxxxxxxx',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Sauvegarder la clé API
              final aiService = ref.read(aiServiceProvider);
              aiService.initialize(apiKey: apiKeyController.text);
              ref.read(aiConnectedProvider.notifier).state = true;
              Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  /// Navigue vers les paramètres IA
  void _navigateToAiSettings() {
    // À implémenter
  }

  /// Récupère le nom de la langue
  String _getLanguageName(String locale) {
    switch (locale) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'Anglais';
      case 'es':
        return 'Espagnol';
      default:
        return 'Système';
    }
  }

  /// Affiche le dialogue de langue
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Français'),
                trailing: Radio<String>(
                  value: 'fr',
                  groupValue: ref.watch(localeProvider),
                  onChanged: (value) {
                    ref.read(localeProvider.notifier).state = value!;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Anglais'),
                trailing: Radio<String>(
                  value: 'en',
                  groupValue: ref.watch(localeProvider),
                  onChanged: (value) {
                    ref.read(localeProvider.notifier).state = value!;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Espagnol'),
                trailing: Radio<String>(
                  value: 'es',
                  groupValue: ref.watch(localeProvider),
                  onChanged: (value) {
                    ref.read(localeProvider.notifier).state = value!;
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche le dialogue de taille de texte
  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taille du texte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Petit'),
              trailing: Radio<String>(
                value: 'small',
                groupValue: 'medium',
                onChanged: (value) => Navigator.pop(context),
              ),
            ),
            ListTile(
              title: const Text('Moyen'),
              trailing: Radio<String>(
                value: 'medium',
                groupValue: 'medium',
                onChanged: (value) => Navigator.pop(context),
              ),
            ),
            ListTile(
              title: const Text('Grand'),
              trailing: Radio<String>(
                value: 'large',
                groupValue: 'medium',
                onChanged: (value) => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue À propos
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'GitPhoto Studio IA',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.photo_camera, size: 64),
      children: [
        const Text(
          'Application de gestion de photos avec intelligence artificielle basée sur Mistral.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Développée avec Flutter',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  /// Affiche l'aide
  void _showHelp() {
    // À implémenter
  }

  /// Vérifie si on doit afficher la déconnexion
  bool _shouldShowLogout() {
    // À implémenter - vérifier si l'utilisateur est connecté
    return false;
  }

  /// Affiche le dialogue de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Implémenter la déconnexion
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
