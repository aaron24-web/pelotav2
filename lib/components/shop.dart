import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for TextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game.dart';
import '../models/coin_pack.dart';
import '../models/voucher.dart';
import '../widgets/coin_purchase_dialog.dart'; // Import the new dialog

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

// Clase para representar una tarjeta de pago
class PaymentCard {
  final String id;
  final String cardNumberLast4;
  final String cardHolder;
  final String expiryDate;

  PaymentCard({
    required this.id,
    required this.cardNumberLast4,
    required this.cardHolder,
    required this.expiryDate,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'].toString(),
      cardNumberLast4: json['card_number_last4'] as String,
      cardHolder: json['card_holder'] as String,
      expiryDate: json['expiry_date'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentCard &&
        other.id == id &&
        other.cardNumberLast4 == cardNumberLast4 &&
        other.cardHolder == cardHolder &&
        other.expiryDate == expiryDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        cardNumberLast4.hashCode ^
        cardHolder.hashCode ^
        expiryDate.hashCode;
  }
}

// Clase para manejar las tarjetas de pago
class CardManager {
  List<PaymentCard> cards = [];

  Future<void> fetchCards() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        cards = []; // Clear cards if no user is logged in
        return;
      }
      final userId = currentUser.id;
      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('tarjetas')
          .select()
          .eq('pelorero_id', userId);
      cards = data.map((json) => PaymentCard.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching cards: $e');
    }
  }

  Future<void> addCard(
    String cardNumberLast4,
    String cardHolder,
    String expiryDate,
  ) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in. Cannot add card.');
      }
      final userId = currentUser.id;
      await Supabase.instance.client.from('tarjetas').insert({
        'pelorero_id': userId,
        'card_number_last4': cardNumberLast4,
        'card_holder': cardHolder,
        'expiry_date': expiryDate,
      });
      await fetchCards(); // Refresh cards after adding
    } catch (e) {
      debugPrint('Error adding card: $e');
      rethrow;
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await Supabase.instance.client.from('tarjetas').delete().eq('id', cardId);
      await fetchCards(); // Refresh cards after deleting
    } catch (e) {
      debugPrint('Error deleting card: $e');
      rethrow;
    }
  }
}

// Clase para manejar las compras de la tienda
class ShopManager {
  int coins = 0;
  final Map<String, ShopItem> items = {};
  final CardManager cardManager = CardManager(); // Integrate CardManager

  // Mapa local para propiedades de UI no almacenadas en la BD
  final Map<String, Map<String, dynamic>> _itemUIMap = {
    'extra_shots': {'icon': Icons.add_circle, 'color': Colors.blue},
    'extra_life': {'icon': Icons.favorite, 'color': Colors.pink},
    'mega_shots': {'icon': Icons.all_inclusive, 'color': Colors.blue.shade700},
  };

  ShopManager();

  void setGameInstance(MyPhysicsGame game) {
    // _game = game; // Removed as _game is no longer a field
  }

  // Inicializa los items desde Supabase
  Future<void> initialize() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final userId = currentUser.id;
        final data = await Supabase.instance.client
            .from('peloreros')
            .select('coins')
            .eq('id', userId)
            .single();
        coins = data['coins'] as int;
      }

      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('habilidades')
          .select();
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
      await cardManager.fetchCards(); // Fetch cards during initialization
    } catch (e) {
      debugPrint('Error fetching shop items or cards: $e');
      // Opcional: Cargar items por defecto o mostrar un error
    }
  }

  Future<void> updateCoins(int amount) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in. Cannot update coins.');
    }
    final userId = currentUser.id;
    final newCoins = coins + amount;
    await Supabase.instance.client
        .from('peloreros')
        .update({'coins': newCoins}).eq('id', userId);
    coins = newCoins;
  }

  Future<Voucher> buyCoins(CoinPack coinPack, PaymentCard paymentCard) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Update user's coin balance
    await updateCoins(coinPack.coins);

    // Generate a unique voucher ID
    final voucherId = '${DateTime.now().millisecondsSinceEpoch}-${coinPack.id}';

    final voucher = Voucher(
      id: voucherId,
      coinPackId: coinPack.id,
      purchaseDate: DateTime.now(),
      amount: coinPack.coins,
    );

    // In a real application, you would store this voucher in a database
    debugPrint('Voucher generated: ${voucher.id} for ${voucher.amount} coins.');

    return voucher;
  }

  bool canBuy(ShopItem item) {
    return coins >= item.price;
  }

  void buyItem(String itemId) async {
    final item = items[itemId];
    if (item == null || !canBuy(item)) return;

    await updateCoins(-item.price);
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
  }) : assert(
         isOverlay ? game != null : true,
         'Game instance must be provided for overlays',
       );

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
                colors: [Colors.purple.shade900, Colors.blue.shade900],
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
                            _buildCategorySection(context, 'Tiros y Vidas', [
                              'extra_shots',
                              'extra_life',
                              'mega_shots',
                            ]),
                            const SizedBox(height: 20),
                            _buildPaymentMethodsSection(
                              context,
                            ), // New section for payment methods
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
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        Row(
          children: [
            _buildCoinsDisplay(),
            if (widget.isOverlay)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: widget.onClose,
              ),
          ],
        )
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
            showDialog(
              context: context,
              builder: (context) => CoinPurchaseDialog(
                shopManager: widget.shopManager,
                onCoinsPurchased: () {
                  setState(() {}); // Refresh ShopScreen after purchase
                },
              ),
            );
          },
          icon: const Icon(Icons.add_circle, color: Colors.white70, size: 16),
          label: const Text(
            'Comprar Monedas',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String categoryName,
    List<String> itemIds,
  ) {
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
                  onNeedCoins: () {
                    showDialog(
                      context: context,
                      builder: (context) => CoinPurchaseDialog(
                        shopManager: widget.shopManager,
                        onCoinsPurchased: () {
                          setState(() {}); // Refresh ShopScreen
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Métodos de Pago',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 120, // Height for card list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                widget.shopManager.cardManager.cards.length +
                1, // +1 for add card button
            itemBuilder: (context, index) {
              if (index < widget.shopManager.cardManager.cards.length) {
                final card = widget.shopManager.cardManager.cards[index];
                return _PaymentCardWidget(
                  card: card,
                  onDelete: (cardId) async {
                    await widget.shopManager.cardManager.deleteCard(cardId);
                    setState(() {}); // Refresh UI
                  },
                );
              } else {
                return _AddCardButton(
                  onPressed: () async {
                    await _showAddCardDialog(context);
                    setState(() {}); // Refresh UI after adding card
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddCardDialog(BuildContext context) async {
    final cardNumberController = TextEditingController();
    final cardHolderController = TextEditingController();
    final expiryDateController = TextEditingController();
    final cvvController = TextEditingController(); // New CVV controller
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Agregar Nueva Tarjeta'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Tarjeta (16 dígitos)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CardNumberInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null ||
                          value.replaceAll(' ', '').length != 16) {
                        return 'Debe ingresar los 16 dígitos de la tarjeta';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: cardHolderController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Titular',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Debe ingresar el nombre del titular';
                      }
                      return null;
                    },
                    maxLines: 1, // Fix overflow
                  ),
                  TextFormField(
                    controller: expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Vencimiento (MM/AA)',
                    ),
                    keyboardType: TextInputType.datetime,
                    maxLength: 5, // MM/YY
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryDateInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null ||
                          value.length != 5 ||
                          !value.contains('/')) {
                        return 'Formato MM/AA inválido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: cvvController, // New CVV field
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    validator: (value) {
                      if (value == null || value.length != 3) {
                        return 'Debe ingresar el CVV (3 dígitos)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Agregar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // Only store last 4 digits for simulation
                    await widget.shopManager.cardManager.addCard(
                      cardNumberController.text.substring(12), // Store last 4
                      cardHolderController.text,
                      expiryDateController.text,
                    );
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    if (!mounted) return; // Added explicit check
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarjeta agregada exitosamente!'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al agregar tarjeta: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final ShopManager shopManager;
  final VoidCallback onBuy;
  final VoidCallback onNeedCoins;

  const _ShopItemCard({
    required this.item,
    required this.shopManager,
    required this.onBuy,
    required this.onNeedCoins,
  });

  @override
  Widget build(BuildContext context) {
    final canBuy = shopManager.canBuy(item);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [item.color.withAlpha(102), item.color.withAlpha(51)],
          ),
          border: Border.all(color: item.color.withAlpha(128), width: 2),
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
                child: Icon(item.icon, size: 28, color: item.color),
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
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                      const Icon(
                        Icons.monetization_on,
                        size: 12,
                        color: Colors.amber,
                      ),
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
                      onPressed: canBuy ? onBuy : onNeedCoins,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBuy ? item.color : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        canBuy ? 'COMPRAR' : 'COMPRAR MONEDAS',
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

class _PaymentCardWidget extends StatelessWidget {
  final PaymentCard card;
  final ValueChanged<String> onDelete;

  const _PaymentCardWidget({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      color: Colors.blueGrey.shade700,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 20),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => onDelete(card.id),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '**** **** **** ${card.cardNumberLast4}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.cardHolder,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              'Exp: ${card.expiryDate}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddCardButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      color: Colors.grey.shade800,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'Agregar Tarjeta',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Formatter for Card Number
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');

    if (text.length > 16) {
      text = text.substring(0, 16);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Custom Formatter for Expiry Date (MM/YY)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    if (newText.length > 5) {
      return oldValue;
    }

    var text = newText.replaceAll('/', '');
    if (text.length > 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
