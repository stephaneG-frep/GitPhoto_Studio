import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../router/app_router.dart';
import '../../core/providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../gallery/gallery_page.dart';
import '../settings/settings_page.dart';
import '../ai/ai_assistant_page.dart';

/// Page d'accueil principale de l'application
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  /// Pages disponibles dans la barre de navigation
  final List<Widget> _pages = const [
    GalleryPage(),
    AiAssistantPage(),
    SettingsPage(),
  ];

  /// Éléments de la barre de navigation
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.photo_library),
      label: 'Galerie',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome),
      label: 'IA',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Paramètres',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialise les services
    _initializeServices();
  }

  /// Initialise les services nécessaires
  Future<void> _initializeServices() async {
    final storageService = ref.read(storageServiceProvider);
    final albumService = ref.read(albumServiceProvider);
    
    await storageService.initialize();
    await albumService.initialize();
    
    // Vérifie la connectivité IA
    final aiService = ref.read(aiServiceProvider);
    final isConnected = await aiService.checkConnectivity();
    ref.read(aiConnectedProvider.notifier).state = isConnected;
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GitPhoto Studio IA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Bouton de recherche
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: 'Rechercher',
          ),
          // Bouton de mode sombre/clair
          IconButton(
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(darkModeProvider.notifier).state = !darkMode,
            tooltip: darkMode ? 'Mode clair' : 'Mode sombre',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Construit le bouton flottant
  Widget? _buildFloatingActionButton() {
    // Boutons différents selon la page
    switch (_currentIndex) {
      case 0: // Galerie
        return FloatingActionButton(
          onPressed: () => _showImportOptions(context),
          tooltip: 'Importer',
          child: const Icon(Icons.add),
        );
      case 1: // IA
        return FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiAssistantPage(),
            ),
          ),
          tooltip: 'Assistant IA',
          child: const Icon(Icons.chat),
        );
      case 2: // Paramètres
        return null;
      default:
        return null;
    }
  }

  /// Affiche les options d'importation
  void _showImportOptions(BuildContext context) {
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
                'Importer une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Depuis la galerie'),
                subtitle: const Text('Sélectionner une photo existante'),
                onTap: () {
                  Navigator.pop(context);
                  _importFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Utiliser la caméra'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Importe une photo depuis la galerie
  void _importFromGallery() async {
    final photoService = ref.read(photoServiceProvider);
    final photo = await photoService.importPhotoFromGallery();
    
    if (photo != null) {
      // Rafraîchit la liste des photos
      ref.refresh(photosProvider);
      
      // Affiche un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo importée: ${photo.name}'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  /// Prend une photo avec la caméra
  void _takePhoto() async {
    final photoService = ref.read(photoServiceProvider);
    final photo = await photoService.takePhotoWithCamera();
    
    if (photo != null) {
      ref.refresh(photosProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo prise: ${photo.name}'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  /// Affiche la barre de recherche
  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: PhotoSearchDelegate(ref),
    );
  }
}

/// Délégat de recherche pour les photos
class PhotoSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  PhotoSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
        tooltip: 'Effacer',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
      tooltip: 'Retour',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(child: Text('Résultats de recherche'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Suggestions de recherche'));
  }
}
