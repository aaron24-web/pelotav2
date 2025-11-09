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
  PaymentCard? _selectedCard;
  bool _isLoading = false;

  final List<CoinPack> _coinPacks = [
    CoinPack(
      id: const Uuid().v4(),
      name: '50 Monedas',
      price: 100,
      coins: 50,
    ),
    CoinPack(
      id: const Uuid().v4(),
      name: '100 Monedas',
      price: 90,
      coins: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.shopManager.cardManager.cards.isNotEmpty) {
      _selectedCard = widget.shopManager.cardManager.cards.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comprar Monedas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona un paquete de monedas:'),
            const SizedBox(height: 10),
            ..._coinPacks.map((pack) => _buildCoinPackTile(pack)),
            const SizedBox(height: 20),
            const Text('Selecciona un método de pago:'),
            const SizedBox(height: 10),
            if (widget.shopManager.cardManager.cards.isEmpty)
              const Text('No hay tarjetas guardadas. Agrega una en la tienda.'),
            ...widget.shopManager.cardManager.cards.map(
              (card) => _buildPaymentCardSelection(card),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
          ],
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

  Widget _buildPaymentCardSelection(PaymentCard card) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCard = card;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Radio<PaymentCard>(
              value: card,
              groupValue: _selectedCard,
              onChanged: (PaymentCard? value) {
                setState(() {
                  _selectedCard = value;
                });
              },
            ),
            Expanded(
              child: Text(
                '**** **** **** ${card.cardNumberLast4} (${card.cardHolder})',
              ),
            ),
            Text('Exp: ${card.expiryDate}'),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(CoinPack pack) async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una tarjeta de pago.'),
        ),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Compra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Se cobrará \$${pack.price} por ${pack.coins} monedas.'),
              const SizedBox(height: 10),
              Text('Tarjeta: **** **** **** ${_selectedCard!.cardNumberLast4}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                await _performPurchase(pack);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performPurchase(CoinPack pack) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final voucher = await widget.shopManager.buyCoins(pack, _selectedCard!);
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
