import 'package:flutter/material.dart';
import '../components/game.dart';
import '../components/shop.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final ShopManager shopManager;

  const LevelSelectionScreen({super.key, required this.shopManager});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = widget.shopManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/colored_grass.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selecciona un Nivel',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            levelType: LevelType.normal,
                            shopManager: widget.shopManager,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: const Text('Nivel Normal'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: widget.shopManager.bossLevelUnlocked
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  levelType: LevelType.bigBoss,
                                  shopManager: widget.shopManager,
                                ),
                              ),
                            );
                          }
                        : null, // Disabled if not unlocked
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 24),
                      disabledBackgroundColor: Colors.grey.shade700,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.shopManager.bossLevelUnlocked)
                          const Icon(Icons.lock, size: 24),
                        const SizedBox(width: 8),
                        const Text('Nivel Jefe Final'),
                      ],
                    ),
                  ),
                  if (!widget.shopManager.bossLevelUnlocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Cómpralo en la tienda para desbloquear',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
