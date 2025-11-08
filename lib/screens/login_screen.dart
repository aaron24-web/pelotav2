import 'package:flutter/material.dart';
import '../components/game.dart';
import 'game_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de pantalla
          Image.asset(
            'assets/images/colored_land.png',
            fit: BoxFit.cover,
          ),
          
          // Contenido centrado
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo o título (opcional)
                  const Text(
                    'Angry Birds',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(5.0, 5.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Botón para Nivel Normal
                  _buildLevelButton(
                    context,
                    'Nivel Normal',
                    () => _navigateToGame(context, LevelType.normal),
                    Colors.blue.shade700,
                  ),
                  const SizedBox(height: 20),
                  
                  // Botón para Nivel Boss
                  _buildLevelButton(
                    context,
                    'Nivel Boss',
                    () => _navigateToGame(context, LevelType.bigBoss),
                    Colors.red.shade800,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir los botones de nivel
  Widget _buildLevelButton(BuildContext context, String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: 300,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Navega a la pantalla del juego
  void _navigateToGame(BuildContext context, LevelType levelType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(levelType: levelType),
      ),
    );
  }
}
