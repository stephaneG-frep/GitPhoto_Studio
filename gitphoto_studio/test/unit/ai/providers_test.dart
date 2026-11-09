import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/ai_agent/application/ai_settings.dart';
import 'package:gitphoto_studio/features/ai_agent/data/anthropic_provider.dart';
import 'package:gitphoto_studio/features/ai_agent/data/gemini_provider.dart';
import 'package:gitphoto_studio/features/ai_agent/data/openai_compatible_provider.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';

import '../../support/fake_ai.dart';

const _key = 'cle-secrete-de-test-1234567890';

const _tool = AiToolSpec(
  name: 'search_media',
  description: 'Cherche',
  parameters: {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'text': {'type': 'string'},
    },
  },
);

final _history = [
  const AiMessage.system('Tu es un assistant.'),
  const AiMessage.user('Trouve mes photos de plage'),
  const AiMessage.assistant(
    '',
    toolCalls: [
      AiToolCall(
        id: 'abc123def',
        name: 'search_media',
        arguments: {'text': 'plage'},
      ),
    ],
  ),
  const AiMessage.toolResult(
    callId: 'abc123def',
    name: 'search_media',
    content: '{"total":1}',
  ),
];

void main() {
  group('Mistral / format chat completions', () {
    late FakeAiHttp http;
    late OpenAiCompatibleProvider mistral;

    setUp(() {
      http = FakeAiHttp();
      mistral = OpenAiCompatibleProvider(
        id: AiProviderId.mistral,
        baseUrl: 'https://api.mistral.ai/v1',
        apiKey: _key,
        dio: http.dio(),
      );
    });

    test(
      'requête : en-tête, outils, historique avec appel et résultat',
      () async {
        http.reply(200, {
          'choices': [
            {
              'finish_reason': 'tool_calls',
              'message': {
                'role': 'assistant',
                'content': '',
                'tool_calls': [
                  {
                    'id': 'Xy12Ab34C',
                    'type': 'function',
                    // Mistral renvoie les arguments sous forme de chaîne JSON.
                    'function': {
                      'name': 'search_media',
                      'arguments': '{"text":"mer","limit":5}',
                    },
                  },
                ],
              },
            },
          ],
        });
        final r = await mistral.chat(
          AiChatRequest(
            model: 'mistral-small-latest',
            messages: _history,
            tools: const [_tool],
          ),
        );
        final req = http.requests.single;
        expect(
          req.uri.toString(),
          'https://api.mistral.ai/v1/chat/completions',
        );
        expect(req.headers['Authorization'], 'Bearer $_key');
        expect(req.body!['model'], 'mistral-small-latest');
        expect(req.body!['tool_choice'], 'auto');
        final tools = req.body!['tools']! as List;
        expect((tools.single as Map)['type'], 'function');
        final msgs = (req.body!['messages']! as List)
            .cast<Map<String, Object?>>();
        expect(msgs.map((m) => m['role']), [
          'system',
          'user',
          'assistant',
          'tool',
        ]);
        final call = (msgs[2]['tool_calls'] as List).single as Map;
        expect(call['id'], 'abc123def');
        expect((call['function'] as Map)['arguments'], '{"text":"plage"}');
        expect(msgs[3]['tool_call_id'], 'abc123def');
        expect(msgs[3]['name'], 'search_media');

        expect(r.finishReason, 'tool_calls');
        final c = r.message.toolCalls.single;
        expect(c.id, 'Xy12Ab34C');
        expect(c.name, 'search_media');
        expect(c.arguments, {'text': 'mer', 'limit': 5});
        expect(c.argumentsError, isNull);
      },
    );

    test('arguments JSON invalides : signalés, jamais exécutés', () async {
      http.reply(200, {
        'choices': [
          {
            'message': {
              'content': null,
              'tool_calls': [
                {
                  'id': 'a',
                  'function': {'name': 'search_media', 'arguments': '{oups'},
                },
              ],
            },
          },
        ],
      });
      final r = await mistral.chat(
        const AiChatRequest(model: 'm', messages: [AiMessage.user('x')]),
      );
      expect(r.message.toolCalls.single.argumentsError, isNotNull);
      expect(r.message.toolCalls.single.arguments, isEmpty);
    });

    test('contenu en fragments (liste) : texte reconstitué', () async {
      http.reply(200, {
        'choices': [
          {
            'message': {
              'content': [
                {'type': 'text', 'text': 'Bon'},
                {'type': 'text', 'text': 'jour'},
              ],
            },
          },
        ],
      });
      final r = await mistral.chat(
        const AiChatRequest(model: 'm', messages: [AiMessage.user('x')]),
      );
      expect(r.message.content, 'Bonjour');
    });

    test(
      'modèles : capacités publiées par Mistral, modèles non chat exclus',
      () async {
        http.reply(200, {
          'data': [
            {
              'id': 'mistral-small-latest',
              'capabilities': {
                'completion_chat': true,
                'function_calling': true,
                'vision': true,
              },
            },
            {
              'id': 'mistral-embed',
              'capabilities': {'completion_chat': false},
            },
            {
              'id': 'open-mistral-7b',
              'capabilities': {
                'completion_chat': true,
                'function_calling': false,
              },
            },
            // Doublon d'alias : ignoré.
            {
              'id': 'mistral-small-latest',
              'capabilities': {'completion_chat': true},
            },
          ],
        });
        final models = await mistral.listModels();
        expect(models.map((m) => m.id), [
          'mistral-small-latest',
          'open-mistral-7b',
        ]);
        expect(models.first.capabilities!.structuredToolCalls, isTrue);
        expect(models.last.capabilities!.structuredToolCalls, isFalse);
        expect(http.requests.single.uri.path, '/v1/models');
      },
    );

    test(
      'clé refusée : erreur typée, clé jamais recopiée dans le message',
      () async {
        // Un serveur qui renverrait la clé dans son message d'erreur.
        http.reply(401, {'message': 'Unauthorized: key $_key is invalid'});
        final status = await mistral.testConnection();
        expect(status.availability, AiAvailability.unavailable);
        expect(status.error!.kind, AiErrorKind.unauthorized);
        expect(status.message, isNot(contains(_key)));
        expect(status.error.toString(), isNot(contains(_key)));
      },
    );

    test('codes HTTP → erreurs typées', () async {
      final cases = {
        403: AiErrorKind.forbidden,
        404: AiErrorKind.notFound,
        429: AiErrorKind.rateLimited,
        500: AiErrorKind.server,
        400: AiErrorKind.badRequest,
      };
      for (final e in cases.entries) {
        http.reply(e.key, {'object': 'error', 'message': 'erreur ${e.key}'});
        await expectLater(
          mistral.chat(
            const AiChatRequest(model: 'm', messages: [AiMessage.user('x')]),
          ),
          throwsA(
            isA<AiException>()
                .having((x) => x.kind, 'kind', e.value)
                .having((x) => x.message, 'message', 'erreur ${e.key}'),
          ),
        );
      }
    });

    test('modèle sans outils (Ollama) : erreur dédiée', () async {
      http.reply(400, {
        'error': {'message': 'registry/llama2 does not support tools'},
      });
      await expectLater(
        mistral.chat(
          const AiChatRequest(model: 'm', messages: [AiMessage.user('x')]),
        ),
        throwsA(
          isA<AiException>().having(
            (x) => x.kind,
            'kind',
            AiErrorKind.toolsUnsupported,
          ),
        ),
      );
    });

    test('réponse illisible : erreur, pas de plantage', () async {
      http.reply(200, '<html>proxy</html>');
      await expectLater(
        mistral.chat(
          const AiChatRequest(model: 'm', messages: [AiMessage.user('x')]),
        ),
        throwsA(
          isA<AiException>().having(
            (x) => x.kind,
            'kind',
            AiErrorKind.invalidResponse,
          ),
        ),
      );
    });

    test('Ollama : aucune clé, aucun en-tête d’autorisation', () async {
      final ollama = OpenAiCompatibleProvider(
        id: AiProviderId.ollama,
        baseUrl: 'http://localhost:11434/v1',
        dio: http.dio(),
      );
      http.reply(200, {
        'data': [
          {'id': 'llama3.1:8b'},
          {'id': 'nomic-embed-text'},
        ],
      });
      final models = await ollama.listModels();
      expect(models.map((m) => m.id), ['llama3.1:8b']);
      expect(http.requests.single.headers['Authorization'], isNull);
    });
  });

  group('Anthropic', () {
    test(
      'format Messages : système séparé, blocs tool_use / tool_result',
      () async {
        final http = FakeAiHttp();
        final p = AnthropicProvider(
          baseUrl: 'https://api.anthropic.com/v1',
          apiKey: _key,
          dio: http.dio(),
        );
        http.reply(200, {
          'stop_reason': 'tool_use',
          'content': [
            {'type': 'text', 'text': 'Je cherche.'},
            {
              'type': 'tool_use',
              'id': 'toolu_1',
              'name': 'search_media',
              'input': {'text': 'mer'},
            },
          ],
        });
        final r = await p.chat(
          AiChatRequest(
            model: 'claude-x',
            messages: _history,
            tools: const [_tool],
          ),
        );
        final req = http.requests.single;
        expect(req.uri.path, '/v1/messages');
        expect(req.headers['x-api-key'], _key);
        expect(req.headers['anthropic-version'], '2023-06-01');
        expect(req.body!['system'], 'Tu es un assistant.');
        final msgs = (req.body!['messages']! as List)
            .cast<Map<String, Object?>>();
        expect(msgs.map((m) => m['role']), ['user', 'assistant', 'user']);
        expect(
          ((msgs[1]['content'] as List).single as Map)['type'],
          'tool_use',
        );
        final result = (msgs[2]['content'] as List).single as Map;
        expect(result['type'], 'tool_result');
        expect(result['tool_use_id'], 'abc123def');
        expect(
          ((req.body!['tools']! as List).single as Map)['input_schema'],
          isNotNull,
        );

        expect(r.message.content, 'Je cherche.');
        expect(r.message.toolCalls.single.arguments, {'text': 'mer'});
      },
    );
  });

  group('Gemini', () {
    test(
      'clé en en-tête (jamais dans l’URL), schéma nettoyé, appels',
      () async {
        final http = FakeAiHttp();
        final p = GeminiProvider(
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          apiKey: _key,
          dio: http.dio(),
        );
        http.reply(200, {
          'candidates': [
            {
              'finishReason': 'STOP',
              'content': {
                'role': 'model',
                'parts': [
                  {
                    'functionCall': {
                      'name': 'search_media',
                      'args': {'text': 'mer'},
                    },
                    'thoughtSignature': 'sig',
                  },
                ],
              },
            },
          ],
        });
        final r = await p.chat(
          AiChatRequest(
            model: 'gemini-2.5-flash',
            messages: _history,
            tools: const [_tool],
          ),
        );
        final req = http.requests.single;
        expect(req.uri.path, '/v1beta/models/gemini-2.5-flash:generateContent');
        expect(req.uri.query, isEmpty);
        expect(req.headers['x-goog-api-key'], _key);
        final decl =
            (((req.body!['tools']! as List).single
                            as Map)['functionDeclarations']
                        as List)
                    .single
                as Map;
        expect(
          (decl['parameters'] as Map).containsKey('additionalProperties'),
          isFalse,
        );
        final contents = (req.body!['contents']! as List)
            .cast<Map<String, Object?>>();
        expect(contents.map((c) => c['role']), ['user', 'model', 'user']);
        final fr =
            ((contents[2]['parts'] as List).single as Map)['functionResponse']
                as Map;
        expect(fr['name'], 'search_media');
        expect(fr['response'], {'total': 1});

        final call = r.message.toolCalls.single;
        expect(call.arguments, {'text': 'mer'});
        // La signature est conservée pour être renvoyée telle quelle.
        expect(call.providerPart!['thoughtSignature'], 'sig');
      },
    );

    test('identifiant de modèle dangereux : refusé avant tout envoi', () async {
      final http = FakeAiHttp();
      final p = GeminiProvider(
        baseUrl: 'https://x/v1beta',
        apiKey: _key,
        dio: http.dio(),
      );
      await expectLater(
        p.chat(
          const AiChatRequest(
            model: '../../evil?x=1',
            messages: [AiMessage.user('x')],
          ),
        ),
        throwsA(isA<AiException>()),
      );
      expect(http.requests, isEmpty);
    });

    test('demande bloquée : erreur explicite', () async {
      final http = FakeAiHttp();
      final p = GeminiProvider(
        baseUrl: 'https://x/v1beta',
        apiKey: _key,
        dio: http.dio(),
      );
      http.reply(200, {
        'promptFeedback': {'blockReason': 'SAFETY'},
      });
      await expectLater(
        p.chat(
          const AiChatRequest(model: 'g', messages: [AiMessage.user('x')]),
        ),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('SAFETY'),
          ),
        ),
      );
    });
  });

  test('adresses de serveur : HTTPS, ou HTTP local seulement si autorisé', () {
    expect(
      isAcceptableBaseUrl('https://api.mistral.ai/v1', allowHttp: false),
      isTrue,
    );
    expect(
      isAcceptableBaseUrl('http://localhost:11434/v1', allowHttp: true),
      isTrue,
    );
    expect(
      isAcceptableBaseUrl('http://localhost:11434/v1', allowHttp: false),
      isFalse,
    );
    expect(
      isAcceptableBaseUrl('https://user:pw@host/v1', allowHttp: true),
      isFalse,
    );
    expect(isAcceptableBaseUrl('ftp://host', allowHttp: true), isFalse);
    expect(isAcceptableBaseUrl('pas une url', allowHttp: true), isFalse);
  });

  test(
    'catalogue : Mistral prioritaire, chaque fournisseur a un adaptateur',
    () {
      expect(aiProviderCatalog.first.id, AiProviderId.mistral);
      for (final d in aiProviderCatalog) {
        final p = createAiProvider(d.id, d.defaultBaseUrl, 'k');
        expect(p.id, d.id);
        expect(p.capabilities.chat, isTrue);
      }
    },
  );
}
