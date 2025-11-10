import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_helper.dart';
import '../components/game.dart';
import '../components/shop.dart';
import '../audio_manager.dart';

class GameScreen extends StatefulWidget {
  final LevelType levelType;

  const GameScreen({super.key, required this.levelType});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MyPhysicsGame _game;
  final ShopManager _shopManager = ShopManager();
  final ValueNotifier<bool> _isShopOpen = ValueNotifier(false);
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _game = MyPhysicsGame(
      shopManager: _shopManager,
      levelType: widget.levelType,
    );
    _shopManager.setGameInstance(_game);
    if (widget.levelType == LevelType.bigBoss) {
      AudioManager.instance.playBossMusic();
    } else {
      AudioManager.instance.playNormalBackgroundMusic();
    }

    _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadBannerAd() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _returnToShop();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _returnToShop();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAd = null;
              });
              _loadRewardedAd();
            },
          );

          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void dispose() {
    _isShopOpen.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _handleReturnToShop() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      _returnToShop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget.controlled(
            gameFactory: () => _game,
            overlayBuilderMap: {
              'dialog': (context, game) {
                return _SaveScoreDialog(
                  game: game as MyPhysicsGame,
                  onReturnToShop: _handleReturnToShop,
                );
              },
              'shop': (context, game) {
                return ShopScreen(
                  shopManager: _shopManager,
                  game: game as MyPhysicsGame,
                  isOverlay: true,
                  onClose: () {
                    _game.overlays.remove('shop');
                    _isShopOpen.value = false;
                  },
                );
              },
            },
          ),
          // Botón de la tienda
          ValueListenableBuilder<bool>(
            valueListenable: _isShopOpen,
            builder: (context, isShopOpen, child) {
              if (isShopOpen) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 20,
                left: 20,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _game.overlays.add('shop');
                    _isShopOpen.value = true;
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Tienda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              );
            },
          ),
          // Botón de recompensa
          ValueListenableBuilder<bool>(
            valueListenable: _isShopOpen,
            builder: (context, isShopOpen, child) {
              if (isShopOpen || _rewardedAd == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 20,
                right: 20,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('¿Ver un anuncio?'),
                          content:
                              const Text('Mira un anuncio para ganar 50 monedas.'),
                          actions: [
                            TextButton(
                              child: const Text('CANCELAR'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text('VER'),
                              onPressed: () {
                                Navigator.pop(context);
                                _rewardedAd?.show(
                                  onUserEarnedReward: (ad, reward) {
                                    _shopManager.updateCoins(50);
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Recompensa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              );
            },
          ),
          if (_bannerAd != null)
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  void _returnToShop() {
    _shopManager.resetItemsForNewTurn();
    if (!mounted) return;
    AudioManager.instance.playMenuMusic();
    Navigator.of(context).pop(); // Vuelve a la pantalla de login
  }
}

class _SaveScoreDialog extends StatefulWidget {
  const _SaveScoreDialog({required this.game, this.onReturnToShop});

  final MyPhysicsGame game;
  final VoidCallback? onReturnToShop;

  @override
  State<_SaveScoreDialog> createState() => _SaveScoreDialogState();
}

class _SaveScoreDialogState extends State<_SaveScoreDialog> {
  @override
  Widget build(BuildContext context) {
    final won = widget.game.playerWon;
    final score = widget.game.score;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de resultado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: won ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Mensaje principal
              Text(
                won ? '¡Victoria!' : '¡Juego Terminado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Tu Score: $score',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Column(
                children: [
                  // Guardar Score
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await widget.game.saveScore();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Score guardado exitosamente'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) {
                            return; // Check mounted after async operation
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar score: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Score'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nueva Ronda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        widget.game.overlays.remove('dialog');
                        await widget.game.reset();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nueva Ronda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Volver a la pantalla de inicio
                  if (widget.onReturnToShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.game.overlays.remove('dialog');
                          widget.onReturnToShop!();
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Volver al Inicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
