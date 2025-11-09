import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'body_component_with_user_data.dart';
import 'brick.dart';
import 'enemy.dart';

const bulletSize = 2.0;

class Bullet extends BodyComponentWithUserData with ContactCallbacks {
  Bullet(Vector2 position, Vector2 velocity)
    : _velocity = velocity,
      super(
        renderBody: false,
        bodyDef: BodyDef()
          ..position = position
          ..type = BodyType.dynamic
          ..bullet = true
          ..linearVelocity = velocity,
        fixtureDefs: [
          FixtureDef(
              PolygonShape()..setAsBoxXY(bulletSize * 0.6, bulletSize * 0.3),
            )
            ..restitution = 0.8
            ..density = 0.1
            ..friction = 0.0
            ..isSensor = false,
        ],
      );

  final Vector2 _velocity;

  @override
  Future<void> onLoad() {
    // Calcular el ángulo de rotación basado en la velocidad
    final angle = atan2(_velocity.y, _velocity.x);

    add(ArrowComponent(angle: angle));
    add(RemoveEffect(delay: 3.0));
    return super.onLoad();
  }

  @override
  void beginContact(Object other, Contact contact) {
    // Verificar si la bala impactó con un enemigo o bloque
    if (other is Enemy ||
        other is Brick ||
        (contact.bodyA.userData is Enemy) ||
        (contact.bodyB.userData is Enemy) ||
        (contact.bodyA.userData is Brick) ||
        (contact.bodyB.userData is Brick)) {
      // La bala se elimina al impactar
      removeFromParent();
    }
    super.beginContact(other, contact);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Eliminar bala si sale de la pantalla
    if (position.x > camera.visibleWorldRect.right + 10 ||
        position.x < camera.visibleWorldRect.left - 10 ||
        position.y > camera.visibleWorldRect.bottom + 10 ||
        position.y < camera.visibleWorldRect.top - 10) {
      removeFromParent();
    }
  }
}

class ArrowComponent extends CustomPainterComponent {
  ArrowComponent({required double angle})
    : super(
        painter: _ArrowPainter(),
        anchor: Anchor.center,
        size: Vector2(bulletSize * 1.2, bulletSize * 0.6),
        angle: angle,
      );
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    final path = Path();

    // Cuerpo de la flecha (rectángulo)
    path.addRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.25,
        size.width * 0.6,
        size.height * 0.5,
      ),
    );

    // Punta de la flecha (triángulo)
    path.moveTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width * 0.9, 0);
    path.lineTo(size.width * 0.9, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Plumas de la flecha
    final featherPaint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.fill;

    // Pluma izquierda
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.25)
        ..lineTo(0, size.height * 0.1)
        ..lineTo(0, size.height * 0.4)
        ..close(),
      featherPaint,
    );

    // Pluma derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.75)
        ..lineTo(0, size.height * 0.6)
        ..lineTo(0, size.height * 0.9)
        ..close(),
      featherPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
