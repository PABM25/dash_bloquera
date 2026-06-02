import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late Future<List<ConnectivityResult>> _initialCheck;

  @override
  void initState() {
    super.initState();
    _initialCheck = Connectivity().checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: _initialCheck,
      builder: (context, futureSnapshot) {
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          // Mientras carga el estado inicial, mostramos la app sin banner para evitar el parpadeo.
          return Material(child: widget.child);
        }

        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          initialData: futureSnapshot.data,
          builder: (context, snapshot) {
            final results = snapshot.data ?? [ConnectivityResult.none];
            final isOffline = results.contains(ConnectivityResult.none);

            return Material(
              child: Column(
                children: [
                  if (isOffline)
                    SafeArea(
                      bottom: false,
                      child: Container(
                        color: Colors.red.shade600,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: const Text(
                          'Modo Offline - Los cambios se sincronizarán al reconectar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.none, // Previene la línea amarilla en caso que Material falle
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: widget.child),
                ],
              ),
            );
          },
        );
      }
    );
  }
}
