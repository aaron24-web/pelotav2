import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'body_component_with_user_data.dart';

const bigBossSize = 12.0; // Más grande que los enemigos normales (5.0)
const bigBossHealth = 5; // Requiere 5 impactos para ser derrotado (más difícil)

class BigBoss extends BodyComponentWithUserData with ContactCallbacks {
  int _health = bigBossHealth;

  BigBoss(Vector2 position, Sprite sprite, {void Function(BodyComponent)? onRemove})
      : super(
          onRemoveCallback: onRemove,
          renderBody: false,
          bodyDef: BodyDef()
            ..position = position
            ..type = BodyType.dynamic,
          fixtureDefs: [
            FixtureDef(
              PolygonShape()..setAsBoxXY(bigBossSize / 2, bigBossSize / 2),
              friction: 0.3,
              density: 2.0, // Más pesado que los enemigos normales
            ),
          ],
          children: [
            SpriteComponent(
              anchor: Anchor.center,
              sprite: sprite,
              size: Vector2.all(bigBossSize),
              position: Vector2(0, 0),
            ),
          ],
        );

  @override
  void beginContact(Object other, Contact contact) {
    var interceptVelocity =
        (contact.bodyA.linearVelocity - contact.bodyB.linearVelocity).length
            .abs();
    
    // Requiere más velocidad para recibir daño (más difícil)
    if (interceptVelocity > 45) {
      _health--;
      
      // Efecto visual de daño (parpadeo)
      if (children.isNotEmpty) {
        final spriteComponent = children.first as SpriteComponent;
        spriteComponent.add(
          OpacityEffect.to(
            0.3,
            EffectController(
              duration: 0.1,
              reverseDuration: 0.1,
            ),
          ),
        );
      }
      
      // Si se queda sin salud, remover
      if (_health <= 0) {
        removeFromParent();
      }
    }

    super.beginContact(other, contact);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // El boss no se elimina al salir de pantalla, es más persistente
    final rect = camera.visibleWorldRect;
    final centerX = (rect.left + rect.right) / 2;
    if (position.x > rect.right + 20 ||
        position.x < rect.left - 20) {
      // Solo remover si está muy lejos
      if ((position.x - centerX).abs() > 50) {
        removeFromParent();
      }
    }
  }

  int get health => _health;
  int get maxHealth => bigBossHealth;
}

