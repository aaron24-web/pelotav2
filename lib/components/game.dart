import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'background.dart';
import 'brick.dart';
import 'ground.dart';
import 'enemy.dart';
import 'big_boss.dart';
import 'player.dart';
import 'shop.dart';

enum LevelType { normal, bigBoss }

class MyPhysicsGame extends Forge2DGame {
  final ShopManager? shopManager;
  final LevelType levelType;
  int _maxShots = 10;
  double _playerSpeedMultiplier = 1.0;
  double _damageMultiplier = 1.0;
  int _scoreMultiplier = 1;

  // State for active ability
  ShopItem? _activeAbility;
  int _abilityUses = 0;
  late final TextComponent _abilityCounterText;
  bool get isAbilityActive => _activeAbility != null;

  MyPhysicsGame({this.shopManager, this.levelType = LevelType.normal})
      : super(gravity: Vector2(0, 10)) {
    // Aplicar items de la tienda
    if (shopManager != null) {
      _maxShots = 10 + shopManager!.getTotalExtraShots();

      // Si tiene combo pack, aplicar todos los beneficios
      if (shopManager!.hasComboPack()) {
        _playerSpeedMultiplier = 1.5;
        _damageMultiplier = 2.0;
        _scoreMultiplier = 2;
      } else {
        _playerSpeedMultiplier = shopManager!.getSpeedMultiplier();
        _damageMultiplier = shopManager!.getDamageMultiplier();
        _scoreMultiplier = shopManager!.getScoreMultiplier();
      }
    }
  }

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;

  late final AudioPlayer _backgroundMusicPlayer;
  late final AudioPlayer _winMusicPlayer;
  late final AudioPlayer _gameOverMusicPlayer;

  late final TextComponent _shotCounterText;
  int _shotCounter = 0;
  late final TextComponent _scoreText;
  int _score = 0;
  bool _gameEnded = false;
  bool _playerWon = false;

  int get score => _score;
  bool get playerWon => _playerWon;

  void _updateTextPositions() {
    if (!isMounted) return;
    final viewportSize = camera.viewport.size;
    _shotCounterText.position = Vector2(viewportSize.x - 10, 10);
    _scoreText.position = Vector2(viewportSize.x - 10, 35);
    _abilityCounterText.position = Vector2(viewportSize.x - 10, 60);
  }

  @override
  FutureOr<void> onLoad() async {
    // Cargar imagen de fondo según el tipo de nivel
    final backgroundImagePath = levelType == LevelType.bigBoss
        ? 'baby.png'
        : 'colored_grass.png';
    final backgroundImage = await images.load(backgroundImagePath);
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];

    _backgroundMusicPlayer = AudioPlayer();
    _winMusicPlayer = AudioPlayer();
    _gameOverMusicPlayer = AudioPlayer();

    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer.play(AssetSource('audio/fondo.mp3'));

    await super.onLoad();

    // Configurar cámara con viewport que llena toda la pantalla horizontal
    // Usar el tamaño real de la pantalla (ya está en horizontal por SystemChrome)
    final screenSize = size;
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(screenSize.x, screenSize.y),
    );

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();

    // Cargar nivel según el tipo
    if (levelType == LevelType.bigBoss) {
      unawaited(addBigBossLevel());
    } else {
      unawaited(addBricks().then((_) => addEnemies()));
    }

    // Inicializar textos usando HUDComponent para que siempre sean visibles
    final viewportSize = camera.viewport.size;

    _shotCounterText = TextComponent(
      text: 'Disparos: 0/$_maxShots',
      anchor: Anchor.topRight,
      position: Vector2(viewportSize.x - 10, 10),
      priority: 1000,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    // Agregar como HUD para que esté siempre visible
    camera.viewport.add(_shotCounterText);

    _scoreText = TextComponent(
      text: 'Score: 0',
      anchor: Anchor.topRight,
      position: Vector2(viewportSize.x - 10, 35),
      priority: 1000,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    // Agregar como HUD para que esté siempre visible
    camera.viewport.add(_scoreText);

    _abilityCounterText = TextComponent(
      text: '',
      anchor: Anchor.topRight,
      position: Vector2(viewportSize.x - 10, 60),
      priority: 1000,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.amber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    camera.viewport.add(_abilityCounterText);

    await addPlayer();
  }

  void activateAbility(ShopItem item) {
    _activeAbility = item;
    switch (item.id) {
      case 'extra_shots':
        _abilityUses = 5;
        break;
      case 'extra_life':
        _abilityUses = 3;
        break;
      case 'mega_shots':
        _abilityUses = 10;
        break;
    }
    _abilityCounterText.text = '${item.name}: $_abilityUses';
  }

  void _deactivateAbility() {
    _activeAbility = null;
    _abilityUses = 0;
    _abilityCounterText.text = '';
  }

  Future<void> addGround() {
    return world.addAll([
      for (
        var x = camera.visibleWorldRect.left;
        x < camera.visibleWorldRect.right + groundSize;
        x += groundSize
      )
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
  }

  final _random = Random();

  Future<void> addBricks() async {
    for (var i = 0; i < 5; i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 5 - 2.5),
            0,
          ),
          sprites: brickFileNames(
            type,
            size,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
          damageMultiplier: _damageMultiplier,
          onRemove: (brick) {
            _score += 10 * _scoreMultiplier;
            _scoreText.text = 'Score: $_score';
            final scoreText = TextComponent(
              text: '+10',
              position: brick.position.clone(),
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            );
            world.add(scoreText);
            scoreText.add(
              MoveByEffect(
                Vector2(0, -1),
                EffectController(duration: 1),
                onComplete: () => scoreText.removeFromParent(),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Vector2? _playerInitialPosition;

  Future<void> addPlayer() async {
    _playerInitialPosition = Vector2(camera.visibleWorldRect.left * 2 / 3, 0);
    return world.add(
      Player(
        _playerInitialPosition!,
        aliens.getSprite(PlayerColor.randomColor.fileName),
        initialPosition: _playerInitialPosition!,
        showAimingArrow: true,
        onShot: () {
          if (isAbilityActive) {
            _abilityUses--;
            if (_abilityUses <= 0) {
              _deactivateAbility();
            } else {
              _abilityCounterText.text =
                  '${_activeAbility!.name}: $_abilityUses';
            }
          } else {
            _shotCounter++;
            _shotCounterText.text = 'Disparos: $_shotCounter/$_maxShots';
            if (_shotCounter >= _maxShots && !_gameEnded) {
              _gameEnded = true;
              _playerWon = false;
              _backgroundMusicPlayer.stop();
              _gameOverMusicPlayer.play(AssetSource('audio/game_over.mp3'));
              overlays.add('dialog');
            }
          }
        },
        speedMultiplier: _playerSpeedMultiplier,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameEnded) {
      return;
    }
    // Verificar si el jugador fue eliminado
    bool hasEnemies = false;
    if (levelType == LevelType.bigBoss) {
      hasEnemies = world.children.whereType<BigBoss>().isNotEmpty;
    } else {
      hasEnemies = world.children.whereType<Enemy>().isNotEmpty;
    }

    if (isMounted && world.children.whereType<Player>().isEmpty && hasEnemies) {
      if (_shotCounter >= _maxShots) {
        if (!_gameEnded) {
          _gameEnded = true;
          _playerWon = false;
          _backgroundMusicPlayer.stop();
          _gameOverMusicPlayer.play(AssetSource('audio/game_over.mp3'));
          overlays.add('dialog');
        }
      } else {
        addPlayer();
      }
    }
    // Verificar condición de victoria según el tipo de nivel
    if (levelType == LevelType.bigBoss) {
      // En nivel boss, ganar cuando el boss es eliminado
      if (isMounted &&
          enemiesFullyAdded &&
          world.children.whereType<BigBoss>().isEmpty &&
          world.children.whereType<TextComponent>().isEmpty) {
        _gameEnded = true;
        _playerWon = true;
        _backgroundMusicPlayer.stop();
        _winMusicPlayer.play(AssetSource('audio/win.mp3'));
        overlays.add('dialog');
      }
    } else {
      // Nivel normal: ganar cuando todos los enemigos son eliminados
      if (isMounted &&
          enemiesFullyAdded &&
          world.children.whereType<Enemy>().isEmpty &&
          world.children.whereType<TextComponent>().isEmpty) {
        _gameEnded = true;
        _playerWon = true;
        _backgroundMusicPlayer.stop();
        _winMusicPlayer.play(AssetSource('audio/win.mp3'));
        overlays.add('dialog');
      }
    }
  }

  var enemiesFullyAdded = false;

  Future<void> addEnemies() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    for (var i = 0; i < 3; i++) {
      await world.add(
        Enemy(
          Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 7 - 3.5),
            (_random.nextDouble() * 3),
          ),
          aliens.getSprite(EnemyColor.randomColor.fileName),
          onRemove: (enemy) {
            _score += 50 * _scoreMultiplier;
            _scoreText.text = 'Score: $_score';
            final scoreText = TextComponent(
              text: '+50',
              position: enemy.position.clone(),
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            );
            world.add(scoreText);
            scoreText.add(
              MoveByEffect(
                Vector2(0, -1),
                EffectController(duration: 1),
                onComplete: () => scoreText.removeFromParent(),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    enemiesFullyAdded = true;
  }

  Future<void> saveScore() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in. Score not saved.');
        return;
      }
      final userId = currentUser.id;
      await Supabase.instance.client.from('puntaje').insert([
        {'pelorero_id': userId, 'score': _score},
      ]);
      debugPrint(
        'Score guardado exitosamente para el usuario $userId - $_score',
      );
    } catch (e) {
      debugPrint('Error al guardar score: $e');
      rethrow;
    }
  }

  Future<void> reset() async {
    // Detener música
    await _backgroundMusicPlayer.stop();
    await _winMusicPlayer.stop();
    await _gameOverMusicPlayer.stop();

    // Remover overlay
    overlays.remove('dialog');

    // Resetear variables
    _score = 0;
    _shotCounter = 0;
    _gameEnded = false;
    _playerWon = false;
    enemiesFullyAdded = false;

    // Actualizar textos
    _scoreText.text = 'Score: 0';
    _shotCounterText.text = 'Disparos: 0/$_maxShots';

    // Asegurar que los textos estén visibles y en la posición correcta
    _updateTextPositions();

    // Limpiar el mundo
    world.removeAll(world.children.toList());

    // Reiniciar música de fondo
    await _backgroundMusicPlayer.play(AssetSource('audio/fondo.mp3'));

    // Recargar elementos del juego según el tipo de nivel
    final backgroundImagePath = levelType == LevelType.bigBoss
        ? 'baby.png'
        : 'colored_grass.png';
    final backgroundImage = await images.load(backgroundImagePath);
    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();

    if (levelType == LevelType.bigBoss) {
      unawaited(addBigBossLevel());
    } else {
      unawaited(addBricks().then((_) => addEnemies()));
    }
    await addPlayer();
  }

  // Método para crear el nivel Big Boss (MÁS DIFÍCIL)
  Future<void> addBigBossLevel() async {
    // Crear una estructura defensiva más compleja y difícil
    // Formar una "fortaleza" más robusta alrededor del boss

    // Bricks en forma de pirámide/estructura defensiva
    final centerX = camera.visibleWorldRect.right / 3;
    final baseY = 0.0;

    // Base de la estructura (bricks grandes de piedra - más resistentes)
    for (var i = 0; i < 4; i++) {
      await world.add(
        Brick(
          type: BrickType.stone, // Bricks de piedra más resistentes
          size: BrickSize.size220x70,
          damage: BrickDamage.none,
          position: Vector2(centerX + (i - 1.5) * 2.5, baseY - 1.5),
          sprites: brickFileNames(
            BrickType.stone,
            BrickSize.size220x70,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
          damageMultiplier: _damageMultiplier,
          onRemove: (brick) {
            _score += 15 * _scoreMultiplier;
            _scoreText.text = 'Score: $_score';
            final scoreText = TextComponent(
              text: '+15',
              position: brick.position.clone(),
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            );
            world.add(scoreText);
            scoreText.add(
              MoveByEffect(
                Vector2(0,-1),
                EffectController(duration: 1),
                onComplete: () => scoreText.removeFromParent(),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Segunda capa de bricks (protección adicional)
    for (var i = 0; i < 3; i++) {
      await world.add(
        Brick(
          type: BrickType.metal, // Bricks de metal
          size: BrickSize.size140x70,
          damage: BrickDamage.none,
          position: Vector2(centerX + (i - 1) * 2.0, baseY - 3.0),
          sprites: brickFileNames(
            BrickType.metal,
            BrickSize.size140x70,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
          damageMultiplier: _damageMultiplier,
          onRemove: (brick) {
            _score += 15 * _scoreMultiplier;
            _scoreText.text = 'Score: $_score';
            final scoreText = TextComponent(
              text: '+15',
              position: brick.position.clone(),
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            );
            world.add(scoreText);
            scoreText.add(
              MoveByEffect(
                Vector2(0, -1),
                EffectController(duration: 1),
                onComplete: () => scoreText.removeFromParent(),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Tercera capa superior (protección extra)
    for (var i = 0; i < 2; i++) {
      await world.add(
        Brick(
          type: BrickType.stone, // Bricks de piedra en la parte superior
          size: BrickSize.size140x70,
          damage: BrickDamage.none,
          position: Vector2(centerX + (i - 0.5) * 2.0, baseY - 4.5),
          sprites: brickFileNames(
            BrickType.stone,
            BrickSize.size140x70,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
          damageMultiplier: _damageMultiplier,
          onRemove: (brick) {
            _score += 15 * _scoreMultiplier;
            _scoreText.text = 'Score: $_score';
            final scoreText = TextComponent(
              text: '+15',
              position: brick.position.clone(),
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            );
            world.add(scoreText);
            scoreText.add(
              MoveByEffect(
                Vector2(0, -1),
                EffectController(duration: 1),
                onComplete: () => scoreText.removeFromParent(),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Esperar un momento antes de agregar el boss
    await Future<void>.delayed(const Duration(seconds: 1));

    // Agregar el Big Boss en el centro de la estructura
    await world.add(
      BigBoss(
        Vector2(centerX, baseY - 1.0),
        aliens.getSprite('alienPink_suit.png'), // Usar sprite de boss
        onRemove: (boss) {
          _score +=
              500 * _scoreMultiplier; // Muchos puntos por derrotar al boss
          _scoreText.text = 'Score: $_score';
          final scoreText = TextComponent(
            text: '+500',
            position: boss.position.clone(),
            anchor: Anchor.center,
            textRenderer: TextPaint(
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          world.add(scoreText);
          scoreText.add(
            MoveByEffect(
              Vector2(0, -2),
              EffectController(duration: 2),
              onComplete: () => scoreText.removeFromParent(),
            ),
          );
        },
      ),
    );

    enemiesFullyAdded = true;
  }
}
