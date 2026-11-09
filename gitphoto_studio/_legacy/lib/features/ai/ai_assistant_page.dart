import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/photo_model.dart';
import '../../core/models/ai_response_model.dart';
import '../../core/providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../gallery/gallery_page.dart';

/// Page de l'assistant IA
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final TextEditingController _promptController = TextEditingController();
  final List<AiMessage> _messages = [];
  bool _isLoading = false;
  Photo? _selectedPhoto;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiConnected = ref.watch(aiConnectedProvider);
    final darkMode = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search),
            onPressed: () => _selectPhoto(),
            tooltip: 'Sélectionner une photo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de photo
          if (_selectedPhoto != null) _buildSelectedPhoto(),
          
          // Historique des messages
          Expanded(
            child: _messages.isEmpty 
                ? _buildWelcomeMessage() 
                : _buildMessageList(),
          ),
          
          // Barre de saisie
          _buildInputBar(),
        ],
      ),
    );
  }

  /// Construit l'affichage de la photo sélectionnée
  Widget _buildSelectedPhoto() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 30, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPhoto!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_selectedPhoto!.width}x${_selectedPhoto!.height} - ${_selectedPhoto!.sizeInMb.toStringAsFixed(2)} Mo',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _selectedPhoto = null),
            tooltip: 'Retirer la photo',
          ),
        ],
      ),
    );
  }

  /// Construit le message de bienvenue
  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bonjour !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Je suis votre assistant IA Mistral.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Je peux vous aider à analyser vos photos, générer des descriptions, détecter des objets et bien plus encore.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showSuggestions(),
              child: const Text('Que puis-je faire ?'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la liste des messages
  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Construit une bulle de message
  Widget _buildMessageBubble(AiMessage message) {
    final isUser = message.role == AiMessageRole.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser 
              ? AppTheme.primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser 
                ? const Radius.circular(12)
                : const Radius.circular(0),
            bottomRight: isUser 
                ? const Radius.circular(0)
                : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.name != null)
              Text(
                message.name!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la barre de saisie
  Widget _buildInputBar() {
    final aiConnected = ref.watch(aiConnectedProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: _selectedPhoto == null 
                    ? 'Poser une question...' 
                    : 'Analyser cette photo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _sendMessage(text),
              enabled: aiConnected,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _sendMessage(_promptController.text),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  /// Envoye un message
  void _sendMessage(String text) async {
    if (text.isEmpty || _isLoading) return;
    
    final message = AiMessage(
      role: AiMessageRole.user,
      content: text,
    );
    
    setState(() {
      _messages.add(message);
      _promptController.clear();
      _isLoading = true;
    });
    
    try {
      final aiService = ref.read(aiServiceProvider);
      AiResponse response;
      
      if (_selectedPhoto != null) {
        // Analyse de photo
        response = await aiService.analyzePhotoObjects(photo: _selectedPhoto!);
      } else {
        // Message textuel - créer une photo factice
        response = await aiService.generatePhotoDescription(
          photo: Photo(
            id: 'temp',
            path: '',
            name: 'générale',
            dateCreated: DateTime.now(),
            dateModified: DateTime.now(),
            sizeBytes: 0,
            width: 0,
            height: 0,
          ),
          customPrompt: text,
        );
      }
      
      final assistantMessage = AiMessage(
        role: AiMessageRole.assistant,
        content: response.response,
        name: 'Mistral AI',
      );
      
      setState(() {
        _messages.add(assistantMessage);
      });
    } catch (e) {
      final errorMessage = AiMessage(
        role: AiMessageRole.assistant,
        content: 'Désolé, je n\'ai pas pu traiter votre demande: ${e.toString()}',
        name: 'Mistral AI',
      );
      
      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Sélectionne une photo
  void _selectPhoto() async {
    final photosAsync = ref.watch(photosProvider);
    
    photosAsync.whenData((photos) {
      if (photos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune photo disponible'),
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sélectionner une photo'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPhoto = photo);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPhoto?.id == photo.id 
                            ? AppTheme.primaryColor 
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 24, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    });
  }

  /// Affiche les suggestions
  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Que puis-je faire pour vous ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Générer une description pour une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _promptController.text = 'Décris cette photo en détail';
                },
              ),
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Générer des tags pour une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _promptController.text = 'Quels tags puis-je ajouter à cette photo ?';
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Détecter des objets dans une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _selectPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.question_answer),
                title: const Text('Poser une question sur une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _selectPhoto();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page d'analyse IA pour une photo spécifique
class AiAnalysisPage extends ConsumerStatefulWidget {
  final Photo photo;

  const AiAnalysisPage({super.key, required this.photo});

  @override
  ConsumerState<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends ConsumerState<AiAnalysisPage> {
  AiResponse? _analysisResponse;
  bool _isLoading = false;
  String _selectedAnalysisType = 'description';

  @override
  void initState() {
    super.initState();
    _analyzePhoto();
  }

  /// Analyse la photo
  Future<void> _analyzePhoto() async {
    setState(() => _isLoading = true);
    
    try {
      final aiService = ref.read(aiServiceProvider);
      
      switch (_selectedAnalysisType) {
        case 'description':
          _analysisResponse = await aiService.generatePhotoDescription(
            photo: widget.photo,
          );
          break;
        case 'tags':
          _analysisResponse = await aiService.generatePhotoTags(
            photo: widget.photo,
          );
          break;
        case 'objects':
          _analysisResponse = await aiService.analyzePhotoObjects(
            photo: widget.photo,
          );
          break;
      }
    } catch (e) {
      setState(() {
        _analysisResponse = AiResponse(
          id: 'error',
          model: 'mistral-large',
          createdAt: DateTime.now(),
          prompt: 'Analyse de ${widget.photo.name}',
          response: 'Erreur lors de l\'analyse: ${e.toString()}',
          status: AiResponseStatus.failed,
          errorMessage: e.toString(),
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse IA: ${widget.photo.name}'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedAnalysisType,
            onSelected: (value) {
              setState(() => _selectedAnalysisType = value);
              _analyzePhoto();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'description',
                child: Text('Description'),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: Text('Tags'),
              ),
              const PopupMenuItem(
                value: 'objects',
                child: Text('Objets'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo
          Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image, size: 64, color: Colors.grey),
            ),
          ),
          
          // Informations de base
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Date: ${widget.photo.dateCreated.toString().split(' ').first}',
                ),
                const SizedBox(width: 16),
                Text('${widget.photo.width}x${widget.photo.height}'),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Analyse
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildAnalysisResult(),
          ),
        ],
      ),
    );
  }

  /// Construit le résultat de l'analyse
  Widget _buildAnalysisResult() {
    if (_analysisResponse == null) {
      return const Center(
        child: Text('Aucune analyse disponible'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getAnalysisTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _analysisResponse!.response,
            style: const TextStyle(fontSize: 16),
          ),
          
          if (_analysisResponse!.status == AiResponseStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Erreur: ${_analysisResponse!.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  /// Récupère le titre de l'analyse
  String _getAnalysisTitle() {
    switch (_selectedAnalysisType) {
      case 'description':
        return 'Description générée par IA';
      case 'tags':
        return 'Tags suggérés';
      case 'objects':
        return 'Objets détectés';
      default:
        return 'Analyse';
    }
  }
}
