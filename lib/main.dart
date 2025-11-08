import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/game.dart';
import 'components/shop.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  await Supabase.initialize(
    url: 'https://qwvhwnsapbbnqwdrdzop.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3dmh3bnNhcGJibnF3ZHJkem9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MDI5MzIsImV4cCI6MjA3NzI3ODkzMn0.BGbq6BU45nOD_1I0HAnB_VilSs-cnZYvlBY0V2ZVGto',
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _GameWrapper(),
    ),
  );
}

class _GameWrapper extends StatefulWidget {
  @override
  State<_GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<_GameWrapper> {
  final ShopManager _shopManager = ShopManager();
  MyPhysicsGame? _game;
  bool _showShop = true;

  void _startGame(LevelType levelType) {
    setState(() {
      _showShop = false;
      _game = MyPhysicsGame(
        shopManager: _shopManager,
        levelType: levelType,
      );
    });
  }

  void _returnToShop() {
    // Resetear items comprados para el siguiente turno
    _shopManager.resetItemsForNewTurn();
    setState(() {
      _showShop = true;
      _game = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showShop) {
      return ShopScreen(
        shopManager: _shopManager,
        onStartGame: _startGame,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget.controlled(
        gameFactory: () => _game!,
        overlayBuilderMap: {
          'dialog': (context, game) {
            return _SaveScoreDialog(
              game: game as MyPhysicsGame,
              onReturnToShop: _returnToShop,
            );
          },
        },
      ),
    );
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
        padding: EdgeInsets.all(24),
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
                padding: EdgeInsets.all(20),
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
              SizedBox(height: 16),
              
              // Mensaje principal
              Text(
                won ? '¡Victoria!' : '¡Juego Terminado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              
              // Score
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
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
              SizedBox(height: 24),
              
              // Instrucción
              Text(
                'Ingresa tu nombre para guardar tu score',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              
              // Campo de texto
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Nombre del jugador',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 24),
              
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
                                SnackBar(
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
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Por favor ingresa tu nombre'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text('Guardar Score'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Nueva Ronda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        widget.game.overlays.remove('dialog');
                        await widget.game.reset();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Nueva Ronda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Volver a Tienda
                  if (widget.onReturnToShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.game.overlays.remove('dialog');
                          widget.onReturnToShop!();
                        },
                        icon: Icon(Icons.shopping_cart),
                        label: Text('Volver a Tienda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
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