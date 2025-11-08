import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game.dart';

// Clase para representar un item de la tienda
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;
  int quantity;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    this.quantity = 0,
  });
}

// Clase para manejar las compras de la tienda
class ShopManager {
  int coins = 500; // Monedas iniciales
  final Map<String, ShopItem> items = {};

  // Mapa local para propiedades de UI no almacenadas en la BD
  final Map<String, Map<String, dynamic>> _itemUIMap = {
    'extra_shots': {'icon': Icons.add_circle, 'color': Colors.blue},
    'extra_life': {'icon': Icons.favorite, 'color': Colors.pink},
    'mega_shots': {'icon': Icons.all_inclusive, 'color': Colors.blue.shade700},
  };

  // Constructor vacío
  ShopManager();

  // Inicializa los items desde Supabase
  Future<void> initialize() async {
    try {
      final List<Map<String, dynamic>> data = await Supabase.instance.client.from('habilidades').select();
      for (var itemData in data) {
        final id = itemData['id'] as String;
        items[id] = ShopItem(
          id: id,
          name: itemData['name'] as String,
          description: itemData['description'] as String,
          price: itemData['price'] as int,
          icon: _itemUIMap[id]?['icon'] ?? Icons.error, // Icono por defecto
          color: _itemUIMap[id]?['color'] ?? Colors.grey, // Color por defecto
          quantity: 0,
        );
      }
    } catch (e) {
      debugPrint('Error fetching shop items: $e');
      // Opcional: Cargar items por defecto o mostrar un error
    }
  }

  bool canBuy(ShopItem item) {
    return coins >= item.price;
  }

  void buyItem(String itemId) {
    final item = items[itemId];
    if (item == null || !canBuy(item)) return;

    coins -= item.price;
    item.quantity++;
  }

  int getTotalExtraShots() {
    return (items['extra_shots']?.quantity ?? 0) * 5 +
           (items['extra_life']?.quantity ?? 0) * 3 +
           (items['mega_shots']?.quantity ?? 0) * 10;
  }

  bool hasComboPack() {
    return (items['mega_shots']?.quantity ?? 0) > 0;
  }

  double getSpeedMultiplier() {
    return hasComboPack() ? 1.5 : 1.0;
  }

  double getDamageMultiplier() {
    return hasComboPack() ? 2.0 : 1.0;
  }

  int getScoreMultiplier() {
    return hasComboPack() ? 2 : 1;
  }

  // Resetear las cantidades de items después de un turno
  void resetItemsForNewTurn() {
    for (var item in items.values) {
      item.quantity = 0;
    }
  }
}

// Widget de la tienda
class ShopScreen extends StatefulWidget {
  final ShopManager shopManager;
  final MyPhysicsGame? game;
  final bool isOverlay;
  final VoidCallback? onClose;

  const ShopScreen({
    super.key,
    required this.shopManager,
    this.game,
    this.isOverlay = false,
    this.onClose,
  }) : assert(isOverlay ? game != null : true, 'Game instance must be provided for overlays');

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = widget.shopManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black87,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
              child: Text(
                'Error al cargar la tienda: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black87,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade900,
                  Colors.blue.shade900,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 20),
                    
                    // Lista de items
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategorySection(
                              context,
                              'Tiros y Vidas',
                              ['extra_shots', 'extra_life', 'mega_shots'],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIENDA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Compra items para mejorar tu juego',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        if (widget.isOverlay)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: widget.onClose,
          )
        else
          _buildCoinsDisplay(),
      ],
    );
  }

  Widget _buildCoinsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${widget.shopManager.coins}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () {
            setState(() {
              widget.shopManager.coins += 200;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡+200 monedas gratis!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add_circle, color: Colors.white70, size: 16),
          label: const Text(
            'Monedas gratis',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String categoryName, List<String> itemIds) {
    final categoryItems = itemIds
        .map((id) => widget.shopManager.items[id])
        .where((item) => item != null)
        .cast<ShopItem>()
        .toList();

    if (categoryItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            categoryName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: _ShopItemCard(
                  item: item,
                  shopManager: widget.shopManager,
                  onBuy: () {
                    setState(() {
                      widget.shopManager.buyItem(item.id);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final ShopManager shopManager;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.shopManager,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canBuy = shopManager.canBuy(item);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color.withAlpha(102),
              item.color.withAlpha(51),
            ],
          ),
          border: Border.all(
            color: item.color.withAlpha(128),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              if (item.quantity > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${item.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: canBuy ? onBuy : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBuy ? item.color : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        canBuy ? 'COMPRAR' : 'SIN FONDOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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