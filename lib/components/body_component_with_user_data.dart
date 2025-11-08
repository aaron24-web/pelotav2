import 'package:flame_forge2d/flame_forge2d.dart';

class BodyComponentWithUserData extends BodyComponent {
  BodyComponentWithUserData({
    super.key,
    super.bodyDef,
    super.children,
    super.fixtureDefs,
    super.paint,
    super.priority,
    super.renderBody,
    this.onRemoveCallback,
  });

  final void Function(BodyComponent)? onRemoveCallback;

  @override
  Body createBody() {
    final body = world.createBody(super.bodyDef!)..userData = this;
    fixtureDefs?.forEach(body.createFixture);
    return body;
  }

  @override
  void onRemove() {
    onRemoveCallback?.call(this);
    super.onRemove();
  }
}