/// Modèle pour les réponses de l'API Mistral
class AiResponse {
  final String id;
  final String model;
  final DateTime createdAt;
  final String prompt;
  final String response;
  final int? tokenCount;
  final double? confidence;
  final Map<String, dynamic>? metadata;
  final AiResponseStatus? status;
  final String? errorMessage;

  AiResponse({
    required this.id,
    required this.model,
    required this.createdAt,
    required this.prompt,
    required this.response,
    this.tokenCount,
    this.confidence,
    this.metadata,
    this.status,
    this.errorMessage,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'model': model,
    'createdAt': createdAt.toIso8601String(),
    'prompt': prompt,
    'response': response,
    'tokenCount': tokenCount,
    'confidence': confidence,
    'metadata': metadata,
    'status': status?.name,
    'errorMessage': errorMessage,
  };

  /// Create from JSON
  factory AiResponse.fromJson(Map<String, dynamic> json) => AiResponse(
    id: json['id'] as String,
    model: json['model'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    prompt: json['prompt'] as String,
    response: json['response'] as String,
    tokenCount: json['tokenCount'] as int?,
    confidence: json['confidence'] as double?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    status: json['status'] != null 
        ? AiResponseStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => AiResponseStatus.pending,
          )
        : null,
    errorMessage: json['errorMessage'] as String?,
  );

  AiResponse copyWith({
    String? id,
    String? model,
    DateTime? createdAt,
    String? prompt,
    String? response,
    int? tokenCount,
    double? confidence,
    Map<String, dynamic>? metadata,
    AiResponseStatus? status,
    String? errorMessage,
  }) {
    return AiResponse(
      id: id ?? this.id,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      prompt: prompt ?? this.prompt,
      response: response ?? this.response,
      tokenCount: tokenCount ?? this.tokenCount,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is AiResponse && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Statuts possibles pour une réponse IA
enum AiResponseStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Modèle pour les requêtes IA
class AiRequest {
  final String prompt;
  final String? systemMessage;
  final double? temperature;
  final int? maxTokens;
  final String? model;
  final List<AiMessage>? messages;

  AiRequest({
    required this.prompt,
    this.systemMessage,
    this.temperature,
    this.maxTokens,
    this.model,
    this.messages,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'systemMessage': systemMessage,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'model': model,
    'messages': messages?.map((m) => m.toJson()).toList(),
  };

  /// Create from JSON
  factory AiRequest.fromJson(Map<String, dynamic> json) => AiRequest(
    prompt: json['prompt'] as String,
    systemMessage: json['systemMessage'] as String?,
    temperature: json['temperature'] as double?,
    maxTokens: json['maxTokens'] as int?,
    model: json['model'] as String?,
    messages: (json['messages'] as List<dynamic>?)?.map(
      (e) => AiMessage.fromJson(e as Map<String, dynamic>),
    ).toList(),
  );

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is AiRequest && other.prompt == prompt);

  @override
  int get hashCode => prompt.hashCode;
}

/// Modèle pour les messages dans une conversation IA
class AiMessage {
  final AiMessageRole role;
  final String content;
  final String? name;

  AiMessage({
    required this.role,
    required this.content,
    this.name,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    'name': name,
  };

  /// Create from JSON
  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
    role: AiMessageRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => AiMessageRole.user,
    ),
    content: json['content'] as String,
    name: json['name'] as String?,
  );

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    (other is AiMessage && 
     other.role == role && 
     other.content == content);

  @override
  int get hashCode => role.hashCode ^ content.hashCode;
}

/// Rôles pour les messages IA
enum AiMessageRole {
  system,
  user,
  assistant,
}

/// Modèle pour l'analyse d'image par IA
class AiImageAnalysis {
  final String photoId;
  final String? description;
  final List<String>? tags;
  final List<AiDetectedObject>? objects;
  final List<AiDetectedFace>? faces;
  final String? scene;
  final String? dominantColor;
  final List<String>? colorPalette;
  final String? style;
  final DateTime? analysisDate;

  AiImageAnalysis({
    required this.photoId,
    this.description,
    this.tags,
    this.objects,
    this.faces,
    this.scene,
    this.dominantColor,
    this.colorPalette,
    this.style,
    this.analysisDate,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'photoId': photoId,
    'description': description,
    'tags': tags,
    'objects': objects?.map((o) => o.toJson()).toList(),
    'faces': faces?.map((f) => f.toJson()).toList(),
    'scene': scene,
    'dominantColor': dominantColor,
    'colorPalette': colorPalette,
    'style': style,
    'analysisDate': analysisDate?.toIso8601String(),
  };

  /// Create from JSON
  factory AiImageAnalysis.fromJson(Map<String, dynamic> json) => AiImageAnalysis(
    photoId: json['photoId'] as String,
    description: json['description'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    objects: (json['objects'] as List<dynamic>?)?.map(
      (e) => AiDetectedObject.fromJson(e as Map<String, dynamic>),
    ).toList(),
    faces: (json['faces'] as List<dynamic>?)?.map(
      (e) => AiDetectedFace.fromJson(e as Map<String, dynamic>),
    ).toList(),
    scene: json['scene'] as String?,
    dominantColor: json['dominantColor'] as String?,
    colorPalette: (json['colorPalette'] as List<dynamic>?)?.map((e) => e as String).toList(),
    style: json['style'] as String?,
    analysisDate: json['analysisDate'] != null 
        ? DateTime.parse(json['analysisDate'] as String)
        : null,
  );
}

/// Objet détecté dans une image
class AiDetectedObject {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? category;

  AiDetectedObject({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.category,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'category': category,
  };

  /// Create from JSON
  factory AiDetectedObject.fromJson(Map<String, dynamic> json) => AiDetectedObject(
    label: json['label'] as String,
    confidence: json['confidence'] as double,
    x: json['x'] as double,
    y: json['y'] as double,
    width: json['width'] as double,
    height: json['height'] as double,
    category: json['category'] as String?,
  );
}

/// Visage détecté dans une image
class AiDetectedFace {
  final double x;
  final double y;
  final double width;
  final double height;
  final int? age;
  final String? gender;
  final double? smileProbability;
  final List<double>? emotions;
  final String? identity;

  AiDetectedFace({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.age,
    this.gender,
    this.smileProbability,
    this.emotions,
    this.identity,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'age': age,
    'gender': gender,
    'smileProbability': smileProbability,
    'emotions': emotions,
    'identity': identity,
  };

  /// Create from JSON
  factory AiDetectedFace.fromJson(Map<String, dynamic> json) => AiDetectedFace(
    x: json['x'] as double,
    y: json['y'] as double,
    width: json['width'] as double,
    height: json['height'] as double,
    age: json['age'] as int?,
    gender: json['gender'] as String?,
    smileProbability: json['smileProbability'] as double?,
    emotions: (json['emotions'] as List<dynamic>?)?.map((e) => e as double).toList(),
    identity: json['identity'] as String?,
  );
}
