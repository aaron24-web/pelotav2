import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/game.dart';
import '../components/shop.dart';

class GameScreen extends StatefulWidget {
  final LevelType levelType;

  const GameScreen({super.key, required this.levelType});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MyPhysicsGame _game;
  final ShopManager _shopManager = ShopManager();

  @override
  void initState() {
    super.initState();
    _game = MyPhysicsGame(
      shopManager: _shopManager,
      levelType: widget.levelType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget.controlled(
            gameFactory: () => _game,
            overlayBuilderMap: {
              'dialog': (context, game) {
                return _SaveScoreDialog(
                  game: game as MyPhysicsGame,
                  onReturnToShop: _returnToShop,
                );
              },
              'shop': (context, game) {
                return ShopScreen(
                  shopManager: _shopManager,
                  game: game as MyPhysicsGame,
                  isOverlay: true,
                );
              },
            },
          ),
          // Botón de la tienda
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_game.overlays.isActive('shop')) {
                  _game.overlays.remove('shop');
                } else {
                  _game.overlays.add('shop');
                }
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Tienda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _returnToShop() {
    _shopManager.resetItemsForNewTurn();
    Navigator.of(context).pop(); // Vuelve a la pantalla de login
  }
}

class _SaveScoreDialog extends StatefulWidget {
  const _SaveScoreDialog({
    required this.game,
    this.onReturnToShop,
  });

  final MyPhysicsGame game;
  final VoidCallback? onReturnToShop;

  @override
  State<_SaveScoreDialog> createState() => _SaveScoreDialogState();
}

class _SaveScoreDialogState extends State<_SaveScoreDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.game.playerWon;
    final score = widget.game.score;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de resultado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: won ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),
              
              // Mensaje principal
              Text(
                won ? '¡Victoria!' : '¡Juego Terminado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Tu Score: $score',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Instrucción
              Text(
                'Ingresa tu nombre para guardar tu score',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Campo de texto
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Nombre del jugador',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones de acción
              Column(
                children: [
                  // Guardar Score
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_textController.text.isNotEmpty) {
                          try {
                            await widget.game.saveScore(_textController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Score guardado exitosamente'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar score: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor ingresa tu nombre'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Score'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Nueva Ronda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        widget.game.overlays.remove('dialog');
                        await widget.game.reset();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nueva Ronda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Volver a la pantalla de inicio
                  if (widget.onReturnToShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.game.overlays.remove('dialog');
                          widget.onReturnToShop!();
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Volver al Inicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
