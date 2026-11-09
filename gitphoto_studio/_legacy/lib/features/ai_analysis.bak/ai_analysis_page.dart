import 'package:flutter/services.dart' show Clipboard, ClipboardData;
/// Page d'analyse IA pour GitPhoto Studio
/// Affiche les résultats d'analyse et permet de lancer de nouvelles analyses

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/photo_model.dart';
import '../../core/models/ai_analysis_result.dart';
import '../../core/providers/ai_analysis_provider.dart';
import '../../widgets/photo_thumbnail.dart';
import '../../widgets/loading_overlay.dart';
import '../gallery/gallery_page.dart';

/// Page d'analyse IA
class AIAnalysisPage extends ConsumerStatefulWidget {
  final String photoId;

  const AIAnalysisPage({super.key, required this.photoId});

  @override
  ConsumerState<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends ConsumerState<AIAnalysisPage> {
  Photo? _photo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    setState(() => _isLoading = true);
    
    try {
      final photoManager = ref.read(photoManagerServiceProvider);
      final photo = await photoManager.getPhotoById(widget.photoId);
      
      if (mounted) {
        setState(() {
          _photo = photo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(
      aiPhotoAnalysisProvider(widget.photoId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(
              aiPhotoAnalysisProvider(widget.photoId),
            ),
            tooltip: 'Rafraîchir l\'analyse',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _photo == null
                  ? const Center(child: Text('Photo introuvable'))
                  : _buildAnalysisContent(context, analysisAsync),
    );
  }

  Widget _buildAnalysisContent(
    BuildContext context,
    AsyncValue<AIAnalysisResult?> analysisAsync,
  ) {
    return analysisAsync.when(
      loading: () => const LoadingOverlay(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(
                aiPhotoAnalysisProvider(widget.photoId),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (analysis) => analysis == null
          ? _buildNoAnalysis(context)
          : _buildAnalysisResult(context, analysis),
    );
  }

  Widget _buildNoAnalysis(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune analyse IA disponible',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'analyse IA nécessite une clé API Mistral valide',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/settings/ai'),
            icon: const Icon(Icons.settings),
            label: const Text('Configurer l\'API'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(
    BuildContext context,
    AIAnalysisResult analysis,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + infos principales
          _buildPhotoHeader(context),
          const Divider(height: 32),
          
          // Score de qualité
          _buildQualityScore(analysis),
          const Divider(height: 32),
          
          // Description
          _buildDescription(analysis),
          const Divider(height: 32),
          
          // Tags
          _buildTagsSection(analysis),
          const Divider(height: 32),
          
          // Catégories
          _buildCategoriesSection(analysis),
          const Divider(height: 32),
          
          // Couleurs dominantes
          _buildColorsSection(analysis),
          const Divider(height: 32),
          
          // Objets détectés
          _buildObjectsSection(analysis),
          const Divider(height: 32),
          
          // Ambiance et style
          _buildMoodAndStyle(analysis),
          const Divider(height: 32),
          
          // Notes techniques
          _buildTechnicalNotes(analysis),
          const SizedBox(height: 32),
          
          // Actions
          _buildActions(context, analysis),
        ],
      ),
    );
  }

  Widget _buildPhotoHeader(BuildContext context) {
    if (_photo == null) return const SizedBox();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhotoThumbnail(
          photo: _photo!,
          size: 100,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _photo!.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${_photo!.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (_photo!.dateCreated != null)
                Text(
                  'Date: ${_photo!.dateCreated.toString().split(' ').first}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  _photo!.isFavorite ? '❤️ Favoris' : 'Favoris',
                ),
                backgroundColor: _photo!.isFavorite
                    ? Colors.red.withOpacity(0.2)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityScore(AIAnalysisResult analysis) {
    final color = _getQualityColor(analysis.qualityScore);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score de qualité',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.star, color: color, size: 40),
            const SizedBox(width: 8),
            Text(
              '${analysis.qualityScore}/10',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LinearProgressIndicator(
                value: analysis.qualityScore / 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getQualityLabel(analysis.qualityScore),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    if (score >= 4) return Colors.yellow;
    return Colors.red;
  }

  String _getQualityLabel(int score) {
    if (score >= 9) return 'Excellente';
    if (score >= 8) return 'Très bonne';
    if (score >= 7) return 'Bonne';
    if (score >= 6) return 'Moyenne';
    if (score >= 4) return 'Passable';
    return 'À améliorer';
  }

  Widget _buildDescription(AIAnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              analysis.description.isNotEmpty
                  ? analysis.description
                  : 'Aucune description disponible',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(AIAnalysisResult analysis) {
    if (analysis.tags.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags (${analysis.tags.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.tags
              .map((tag) => Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(AIAnalysisResult analysis) {
    if (analysis.categories.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories (${analysis.categories.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.categories
              .map((category) => Chip(
                    label: Text(category),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.blue),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorsSection(AIAnalysisResult analysis) {
    if (analysis.dominantColors.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleurs dominantes (${analysis.dominantColors.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.dominantColors
              .map((color) => _buildColorChip(color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorChip(String colorName) {
    final color = _parseColor(colorName);
    
    return Chip(
      label: Text(colorName),
      backgroundColor: color.withOpacity(0.3),
      labelStyle: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _parseColor(String colorName) {
    const colorMap = {
      'rouge': Colors.red,
      'vert': Colors.green,
      'bleu': Colors.blue,
      'jaune': Colors.yellow,
      'orange': Colors.orange,
      'violet': Colors.purple,
      'rose': Colors.pink,
      'marron': Colors.brown,
      'noir': Colors.black,
      'blanc': Colors.white,
      'gris': Colors.grey,
      'cyan': Colors.cyan,
      'magenta': Colors.purple,
    };
    
    final lowerName = colorName.toLowerCase();
    for (final entry in colorMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return Colors.grey;
  }

  Widget _buildObjectsSection(AIAnalysisResult analysis) {
    if (analysis.objectsDetected.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objets détectés (${analysis.objectsDetected.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.objectsDetected
              .map((object) => Chip(
                    label: Text(object),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.green),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMoodAndStyle(AIAnalysisResult analysis) {
    final hasMood = analysis.mood.isNotEmpty;
    final hasStyle = analysis.style.isNotEmpty;
    
    if (!hasMood && !hasStyle) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ambiance & Style',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (hasMood)
              Expanded(
                child: _buildInfoCard('Ambiance', analysis.mood, Icons.emoji_emotions),
              ),
            if (hasMood && hasStyle) const SizedBox(width: 16),
            if (hasStyle)
              Expanded(
                child: _buildInfoCard('Style', analysis.style, Icons.art_track),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalNotes(AIAnalysisResult analysis) {
    if (analysis.technicalNotes.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes techniques',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
              },
              children: analysis.technicalNotes.entries
                  .map((entry) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(entry.value),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AIAnalysisResult analysis) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Appliquer les tags à la photo
            _applyTagsToPhoto(analysis);
          },
          icon: const Icon(Icons.tag),
          label: const Text('Appliquer les tags'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Générer une légende
            _generateCaption();
          },
          icon: const Icon(Icons.text_fields),
          label: const Text('Générer légende'),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            // Retour à la galerie
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour'),
        ),
      ],
    );
  }

  Future<void> _applyTagsToPhoto(AIAnalysisResult analysis) async {
    if (_photo == null) return;
    
    final photoManager = ref.read(photoManagerServiceProvider);
    
    // Ajouter les tags à la photo
    final updatedTags = [
      ..._photo!.tags,
      ...analysis.allTags,
    ].toSet().toList();
    
    await photoManager.updatePhoto(
      _photo!.copyWith(tags: updatedTags),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tags appliqués avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _generateCaption() async {
    if (_photo == null) return;
    
    final captionAsync = ref.read(
      aiGenerateCaptionProvider(_photo!.id),
    );
    
    final caption = await captionAsync.future;
    
    if (caption != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Légende générée'),
          content: Text(caption),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                // Copier dans le presse-papiers
                Clipboard.setData(ClipboardData(text: caption));
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Légende copiée dans le presse-papiers!'),
                  ),
                );
              },
              child: const Text('Copier'),
            ),
          ],
        ),
      );
    }
  }

  /// Build avec le contexte actuel
  Widget buildWithContext(BuildContext context) {
    return Builder(
      builder: (newContext) => AIAnalysisPage(photoId: widget.photoId),
    );
  }
}

/// Page de recherche sémantique
class AISemanticSearchPage extends ConsumerStatefulWidget {
  const AISemanticSearchPage({super.key});

  @override
  ConsumerState<AISemanticSearchPage> createState() => _AISemanticSearchPageState();
}

class _AISemanticSearchPageState extends ConsumerState<AISemanticSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Photo> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche sémantique'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_isSearching)
            const LinearProgressIndicator(),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Text(
                      'Entrez un terme de recherche pour trouver des photos similaires',
                      textAlign: TextAlign.center,
                    ),
                  )
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await ref.read(
        aiSemanticSearchProvider(query).future,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildResultsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final photo = _searchResults[index];
        return GestureDetector(
          onTap: () {
            context.push('/gallery?photoId=${photo.id}');
          },
          child: PhotoThumbnail(
            photo: photo,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
