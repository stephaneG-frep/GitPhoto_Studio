import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/ai_service.dart';
import '../../theme/app_theme.dart';

/// Page de configuration de l'IA Mistral
class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _customPromptController = TextEditingController();
  bool _isLoading = false;
  bool _isConnected = false;
  String? _connectionError;
  String _selectedModel = 'mistral-large-latest';

  // Modèles disponibles chez Mistral
  final List<String> _availableModels = [
    'mistral-tiny-latest',
    'mistral-small-latest',
    'mistral-medium-latest',
    'mistral-large-latest',
    'mistral-embed',
    'codestral-latest',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  /// Charge les paramètres actuels
  Future<void> _loadSettings() async {
    final aiService = ref.read(aiServiceProvider);
    final savedKey = await aiService.loadApiKey();
    
    if (savedKey != null) {
      _apiKeyController.text = savedKey;
      _isConnected = aiService.isConnected;
    }
    
    _selectedModel = aiService.currentModel;
    
    if (mounted) setState(() {});
  }

  /// Sauvegarde la clé API
  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une clé API'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      await aiService.initialize(apiKey: apiKey, model: _selectedModel);
      
      // Test la connexion
      final isConnected = await aiService.checkConnectivity();
      
      if (isConnected) {
        setState(() {
          _isConnected = true;
          _connectionError = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clé API sauvegardée et connexion réussie !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isConnected = false;
          _connectionError = 'Impossible de se connecter à l\'API Mistral';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clé API sauvegardée mais connexion échouée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionError = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Efface la clé API
  Future<void> _clearApiKey() async {
    final aiService = ref.read(aiServiceProvider);
    await aiService.clearApiKey();
    
    _apiKeyController.clear();
    setState(() {
      _isConnected = false;
      _connectionError = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clé API supprimée'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  /// Sélectionne un modèle
  void _selectModel(String? model) {
    if (model != null) {
      setState(() => _selectedModel = model);
      final aiService = ref.read(aiServiceProvider);
      aiService.setModel(model);
    }
  }

  /// Teste la connexion
  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une clé API d\'abord'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _connectionError = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      await aiService.initialize(apiKey: _apiKeyController.text.trim(), model: _selectedModel);
      final isConnected = await aiService.checkConnectivity();
      
      setState(() => _isConnected = isConnected);
      
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie à Mistral AI !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _connectionError = 'Connexion échouée');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _connectionError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration IA Mistral'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveApiKey,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Clé API
            _buildSectionHeader('Clé API Mistral', Icons.key),
            const SizedBox(height: 16),
            
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Clé API',
                hintText: 'Entrez votre clé API Mistral',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _apiKeyController.clear,
                ),
              ),
              obscureText: true,
              obscuringCharacter: '*',
            ),
            const SizedBox(height: 8),
            
            Text(
              'Où trouver votre clé API :',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Connectez-vous à https://console.mistral.ai/',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  '2. Allez dans "API Keys"',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  '3. Créez une nouvelle clé ou copiez une existante',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveApiKey,
                    icon: const Icon(Icons.save),
                    label: _isLoading 
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text('Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tester'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Statut de connexion
            _buildConnectionStatus(),
            const SizedBox(height: 20),
            
            const Divider(),
            const SizedBox(height: 20),
            
            // Section Modèle
            _buildSectionHeader('Modèle', Icons.model_training),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedModel,
              items: _availableModels.map((model) => DropdownMenuItem(
                value: model,
                child: Text(model),
              )).toList(),
              onChanged: _selectModel,
              decoration: const InputDecoration(
                labelText: 'Modèle Mistral',
                prefixIcon: Icon(Icons.rocket),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez le modèle à utiliser pour les requêtes IA',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            const Divider(),
            const SizedBox(height: 20),
            
            // Section Prompt personnalisé
            _buildSectionHeader('Prompt Personnalisé', Icons.edit),
            const SizedBox(height: 16),
            
            TextField(
              controller: _customPromptController,
              decoration: InputDecoration(
                labelText: 'Prompt personnalisé',
                hintText: 'Ex: Décris cette image en détail pour un photographe',
                prefixIcon: const Icon(Icons.text_fields),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _customPromptController.clear,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Text(
              'Ce prompt sera utilisé par défaut pour l\'analyse des images',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // Bouton de suppression
            if (_apiKeyController.text.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _clearApiKey,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Supprimer la clé', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construit un en-tête de section
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Construit l'affichage du statut de connexion
  Widget _buildConnectionStatus() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_connectionError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur: $_connectionError',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (_isConnected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text(
              'Connecté à Mistral AI avec succès !',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            'Non connecté - Entrez une clé API valide',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
