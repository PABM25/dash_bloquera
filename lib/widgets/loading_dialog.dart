import 'package:flutter/material.dart';

/// Muestra un diálogo de carga mientras corre [task].
///
/// [task] recibe `close`, para cerrar el diálogo apenas el archivo esté listo
/// (antes de abrir el diálogo de imprimir/compartir). Si no se llama, el
/// diálogo se cierra al terminar. Si [task] falla, se muestra [errorMessage].
Future<void> runWithLoading(
  BuildContext context,
  Future<void> Function(VoidCallback close) task, {
  String message = 'Generando PDF…',
  String errorMessage = 'No se pudo generar el archivo. Intenta nuevamente.',
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  bool open = true;
  void close() {
    if (!open) return;
    open = false;
    navigator.pop();
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(message, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // Deja que el diálogo se pinte antes de empezar el trabajo pesado
  // (en Web todo corre en el mismo hilo).
  await WidgetsBinding.instance.endOfFrame;

  try {
    await task(close);
  } catch (e) {
    debugPrint("runWithLoading: $e");
    messenger.showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: errorColor));
  } finally {
    close();
  }
}
