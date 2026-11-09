import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_model.dart';
import '../models/ai_response_model.dart';

/// Service pour l'intégration avec Mistral AI
class AiService {
  static final AiService _instance = AiService._internal();
  
  factory AiService() => _instance;
  
  AiService._internal();

  // Configuration Mistral
  String? _apiKey;
  String _baseUrl = 'https://api.mistral.ai/v1';
  String _model = 'mistral-large-latest';
  
  // Cache des réponses
  final Map<String, AiResponse> _responseCache = {};
  
  // Statut de connexion
  bool _isConnected = false;

  /// Initialise le service avec la clé API
  Future<void> initialize({String? apiKey, String? baseUrl, String? model}) async {
    if (apiKey != null) {
      _apiKey = apiKey;
      await _saveApiKey(apiKey);
    } else {
      _apiKey = await _loadApiKey();
    }
    
    if (baseUrl != null) _baseUrl = baseUrl;
    if (model != null) _model = model;
    
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _isConnected = await checkConnectivity();
    }
  }

  /// Charge la clé API depuis les préférences
  Future<String?> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ai_api_key');
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarde la clé API dans les préférences
  Future<bool> _saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('ai_api_key', apiKey);
    } catch (e) {
      return false;
    }
  }

  /// Charge la clé API (méthode publique)
  Future<String?> loadApiKey() => _loadApiKey();

  /// Sauvegarde la clé API (méthode publique)
  Future<bool> saveApiKey(String apiKey) => _saveApiKey(apiKey);

  /// Supprime la clé API
  Future<bool> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = null;
      _isConnected = false;
      return await prefs.remove('ai_api_key');
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si le service est initialisé
  bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;

  /// Vérifie si connecté à l'API
  bool get isConnected => _isConnected;

  /// Récupère le modèle actuel
  String get currentModel => _model;

  /// Définit le modèle
  void setModel(String model) {
    _model = model;
  }

  /// Génère une description pour une photo en utilisant Mistral
  Future<AiResponse> generatePhotoDescription({
    required Photo photo,
    String? customPrompt,
  }) async {
    if (!isInitialized) {
      throw Exception('AI Service not initialized. Please provide an API key.');
    }

    // Construis le prompt
    final prompt = customPrompt ?? _buildDescriptionPrompt(photo);
    
    // Vérifie le cache
    final cacheKey = _generateCacheKey('describe', photo.id, prompt);
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }
    
    final request = AiRequest(
      prompt: prompt,
      model: _model,
      temperature: 0.7,
      maxTokens: 500,
    );

    try {
      final response = await _sendRequest(request);
      _responseCache[cacheKey] = response;
      return response;
    } catch (e) {
      final errorResponse = AiResponse(
        id: _generateId(),
        model: _model,
        createdAt: DateTime.now(),
        prompt: prompt,
        response: '',
        status: AiResponseStatus.failed,
        errorMessage: e.toString(),
      );
      _responseCache[cacheKey] = errorResponse;
      return errorResponse;
    }
  }

  /// Génère des tags pour une photo
  Future<AiResponse> generatePhotoTags({required Photo photo, int maxTags = 10}) async {
    if (!isInitialized) {
      throw Exception('AI Service not initialized');
    }

    final prompt = _buildTaggingPrompt(photo, maxTags);
    final cacheKey = _generateCacheKey('tags', photo.id, prompt);
    
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }
    
    final request = AiRequest(
      prompt: prompt,
      model: _model,
      temperature: 0.5,
      maxTokens: 200,
    );

    try {
      final response = await _sendRequest(request);
      _responseCache[cacheKey] = response;
      return response;
    } catch (e) {
      final errorResponse = AiResponse(
        id: _generateId(),
        model: _model,
        createdAt: DateTime.now(),
        prompt: prompt,
        response: '',
        status: AiResponseStatus.failed,
        errorMessage: e.toString(),
      );
      _responseCache[cacheKey] = errorResponse;
      return errorResponse;
    }
  }

  /// Analyse une image pour détecter des objets (avec support image)
  Future<AiResponse> analyzePhotoObjects({required Photo photo}) async {
    if (!isInitialized) {
      throw Exception('AI Service not initialized');
    }

    final prompt = _buildObjectDetectionPrompt(photo);
    final cacheKey = _generateCacheKey('objects', photo.id, prompt);
    
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }
    
    try {
      // Essayer d'envoyer l'image si elle existe
      final file = File(photo.path);
      if (await file.exists()) {
        final response = await _sendImageRequest(file, prompt);
        _responseCache[cacheKey] = response;
        return response;
      }
      
      // Sinon, envoyer juste le texte
      final request = AiRequest(
        prompt: prompt,
        model: _model,
        temperature: 0.3,
        maxTokens: 1000,
      );
      
      final response = await _sendRequest(request);
      _responseCache[cacheKey] = response;
      return response;
    } catch (e) {
      final errorResponse = AiResponse(
        id: _generateId(),
        model: _model,
        createdAt: DateTime.now(),
        prompt: prompt,
        response: '',
        status: AiResponseStatus.failed,
        errorMessage: e.toString(),
      );
      _responseCache[cacheKey] = errorResponse;
      return errorResponse;
    }
  }

  /// Envoie une image à Mistral pour analyse
  Future<AiResponse> _sendImageRequest(File imageFile, String prompt) async {
    // Lire l'image en base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    // Construire le payload avec l'image
    final payload = {
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'temperature': 0.3,
      'max_tokens': 1000,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;
        
        return AiResponse(
          id: _generateId(),
          model: _model,
          createdAt: DateTime.now(),
          prompt: prompt,
          response: content,
          status: AiResponseStatus.completed,
          tokenCount: jsonResponse['usage']?['total_tokens'],
        );
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Image analysis failed: ${e.toString()}');
    }
  }

  /// Pose une question sur une photo
  Future<AiResponse> askAboutPhoto({
    required Photo photo,
    required String question,
  }) async {
    if (!isInitialized) {
      throw Exception('AI Service not initialized');
    }

    final prompt = _buildQuestionPrompt(photo, question);
    final cacheKey = _generateCacheKey('question', photo.id, question);
    
    if (_responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }
    
    final request = AiRequest(
      prompt: prompt,
      model: _model,
      temperature: 0.7,
      maxTokens: 500,
    );

    try {
      final response = await _sendRequest(request);
      _responseCache[cacheKey] = response;
      return response;
    } catch (e) {
      final errorResponse = AiResponse(
        id: _generateId(),
        model: _model,
        createdAt: DateTime.now(),
        prompt: prompt,
        response: '',
        status: AiResponseStatus.failed,
        errorMessage: e.toString(),
      );
      _responseCache[cacheKey] = errorResponse;
      return errorResponse;
    }
  }

  /// Envoie une requête texte à l'API Mistral
  Future<AiResponse> _sendRequest(AiRequest request) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = {
      'model': request.model,
      'messages': [
        {'role': 'user', 'content': request.prompt}
      ],
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'] as String;
      
      return AiResponse(
        id: _generateId(),
        model: request.model ?? _model,
        createdAt: DateTime.now(),
        prompt: request.prompt,
        response: content,
        status: AiResponseStatus.completed,
        tokenCount: jsonResponse['usage']?['total_tokens'],
      );
    } else {
      throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
    }
  }

  /// Construis un prompt pour la description de photo
  String _buildDescriptionPrompt(Photo photo) {
    return '''
Analyse cette photo et fournis une description détaillée et créative en français.

Informations sur la photo:
- Nom: ${photo.name}
- Date de création: ${photo.dateCreated.toString().split(' ').first}
- Taille: ${photo.width}x${photo.height}
- Taille fichier: ${photo.sizeInMb.toStringAsFixed(2)} Mo

Description (max 500 caractères) :
''';
  }

  /// Construis un prompt pour le tagging
  String _buildTaggingPrompt(Photo photo, int maxTags) {
    return '''
Génère une liste de $maxTags tags pertinents et précis pour cette photo.
Les tags doivent être en français, séparés par des virgules, sans espaces.

Informations sur la photo:
- Nom: ${photo.name}
- Date: ${photo.dateCreated.toString().split(' ').first}

Exemples de tags: paysage, coucher-de-soleil, plage, famille, voyage, etc.

Tags :
''';
  }

  /// Construis un prompt pour la détection d'objets
  String _buildObjectDetectionPrompt(Photo photo) {
    return '''
Analyse cette photo et liste tous les objets principaux que tu détectes.
Pour chaque objet, indique :
- Nom de l'objet (en français)
- Catégorie (ex: animal, véhicule, nourriture, etc.)
- Position approximative (haut/bas/gauche/droite/centre)

Informations sur la photo:
- Nom: ${photo.name}

Format de réponse:
1. Objet: [nom], Catégorie: [catégorie], Position: [position]
2. Objet: [nom], Catégorie: [catégorie], Position: [position]
...

Objets détectés :
''';
  }

  /// Construis un prompt pour une question sur une photo
  String _buildQuestionPrompt(Photo photo, String question) {
    return '''
Réponds à cette question sur la photo de manière précise et détaillée.

Informations sur la photo:
- Nom: ${photo.name}
- Date: ${photo.dateCreated.toString().split(' ').first}
- Description existante: ${photo.description ?? 'Aucune'}

Question: $question

Réponse :
''';
  }

  /// Génère un ID unique
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_model.replaceAll('-', '_')}';
  }

  /// Génère une clé de cache
  String _generateCacheKey(String type, String photoId, String prompt) {
    return '$type|$photoId|${prompt.hashCode}';
  }

  /// Vérifie la connectivité à l'API
  Future<bool> checkConnectivity() async {
    if (_apiKey == null || _apiKey!.isEmpty) return false;
    
    try {
      final headers = {
        'Authorization': 'Bearer $_apiKey',
      };
      
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupère la liste des modèles disponibles
  Future<List<String>> listAvailableModels() async {
    if (_apiKey == null || _apiKey!.isEmpty) return [];
    
    try {
      final headers = {
        'Authorization': 'Bearer $_apiKey',
      };
      
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final models = <String>[];
        
        if (jsonResponse['data'] is List) {
          for (final model in jsonResponse['data']) {
            models.add(model['id'] as String);
          }
        }
        
        return models;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Efface le cache des réponses
  void clearCache() {
    _responseCache.clear();
  }

  /// Définit manuellement la clé API
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Récupère la clé API (masquée partiellement)
  String? get maskedApiKey {
    if (_apiKey == null) return null;
    return '${_apiKey!.substring(0, 4)}...${_apiKey!.substring(_apiKey!.length - 4)}';
  }
}
