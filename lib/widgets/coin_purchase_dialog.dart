import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../components/shop.dart';
import '../models/coin_pack.dart';
import '../models/voucher.dart';

class CoinPurchaseDialog extends StatefulWidget {
  final ShopManager shopManager;
  final VoidCallback onCoinsPurchased;

  const CoinPurchaseDialog({
    super.key,
    required this.shopManager,
    required this.onCoinsPurchased,
  });

  @override
  State<CoinPurchaseDialog> createState() => _CoinPurchaseDialogState();
}

class _CoinPurchaseDialogState extends State<CoinPurchaseDialog> {
  bool _isLoading = false;

  final List<CoinPack> _coinPacks = [
    CoinPack(id: const Uuid().v4(), name: '50 Monedas', price: 100, coins: 50),
    CoinPack(id: const Uuid().v4(), name: '100 Monedas', price: 90, coins: 100),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comprar Monedas'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona un paquete de monedas:'),
              const SizedBox(height: 10),
              ..._coinPacks.map((pack) => _buildCoinPackTile(pack)),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildCoinPackTile(CoinPack pack) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: Colors.amber),
        title: Text(pack.name),
        trailing: Text('\$${pack.price}'),
        onTap: () => _showConfirmationDialog(pack),
      ),
    );
  }

  Future<void> _showConfirmationDialog(CoinPack pack) async {
    if (widget.shopManager.cardManager.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, agrega una tarjeta de pago en la tienda.'),
        ),
      );
      return;
    }

    int selectedCardIndex = 0;
    final pageController = PageController(viewportFraction: 0.7);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          final selectedCard =
              widget.shopManager.cardManager.cards[selectedCardIndex];

          Widget buildDot(int index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: selectedCardIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: selectedCardIndex == index
                    ? Colors.blue
                    : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }

          Widget buildPaymentCard(PaymentCard card, bool isSelected) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isSelected
                    ? Colors.blue.shade700
                    : Colors.grey.shade800,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.credit_card,
                        color: Colors.white, size: 22),
                    const Spacer(),
                    Text(
                      '**** **** **** ${card.cardNumberLast4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.cardHolder,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      'Exp: ${card.expiryDate}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildCardCarousel() {
            return Column(
              children: [
                SizedBox(
                  height: 110,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: widget.shopManager.cardManager.cards.length,
                    onPageChanged: (index) {
                      setState(() {
                        selectedCardIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final card =
                          widget.shopManager.cardManager.cards[index];
                      return buildPaymentCard(
                          card, index == selectedCardIndex);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.shopManager.cardManager.cards.length,
                    (index) => buildDot(index),
                  ),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Confirmar Compra'),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 8.0),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Se cobrará \$${pack.price} por ${pack.coins} monedas.'),
                    const SizedBox(height: 20),
                    const Text('Selecciona un método de pago:'),
                    const SizedBox(height: 10),
                    if (widget.shopManager.cardManager.cards.isEmpty)
                      const Text(
                        'No hay tarjetas guardadas. Agrega una en la tienda.',
                      ),
                    if (widget.shopManager.cardManager.cards.isNotEmpty)
                      buildCardCarousel(),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  pageController.dispose();
                },
              ),
              ElevatedButton(
                child: const Text('Aceptar'),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  pageController.dispose();
                  await _performPurchase(pack, selectedCard);
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _performPurchase(CoinPack pack, PaymentCard selectedCard) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final voucher = await widget.shopManager.buyCoins(pack, selectedCard);
      if (!mounted) return;
      widget.onCoinsPurchased();
      Navigator.of(context).pop(); // Close CoinPurchaseDialog

      _showVoucherDialog(voucher);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al comprar monedas: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVoucherDialog(Voucher voucher) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Compra Exitosa!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gracias por tu compra.'),
              const SizedBox(height: 10),
              Text('Voucher ID: ${voucher.id}'),
              Text('Monedas compradas: ${voucher.amount}'),
              Text(
                'Fecha: ${voucher.purchaseDate.toLocal().toString().split('.')[0]}',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
