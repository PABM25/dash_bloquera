import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// Comparte UNA suscripción a Firestore entre todas las pantallas que la usan.
///
/// - Devuelve siempre la misma instancia de Stream, así un `StreamBuilder`
///   no se vuelve a suscribir en cada `build()`.
/// - Entrega al instante el último valor a quien se suscribe después.
/// - Si nadie escucha, cancela la consulta y se reconecta al volver a usarse.
class SharedStream<T> {
  SharedStream(this._factory) {
    _instances.add(this);
  }

  static final List<SharedStream<dynamic>> _instances = [];

  final Stream<T> Function() _factory;
  BehaviorSubject<T>? _subject;
  StreamSubscription<T>? _upstream;

  Stream<T> get stream {
    final current = _subject;
    if (current != null && !current.isClosed) return current;

    late final BehaviorSubject<T> subject;
    subject = BehaviorSubject<T>(
      onListen: () {
        _upstream = _factory().listen(subject.add, onError: subject.addError);
      },
      onCancel: () {
        _upstream?.cancel();
        _upstream = null;
        // Un error (ej. permisos al cerrar sesión) no debe quedar en caché.
        if (subject.hasError) _discard();
      },
    );
    _subject = subject;
    return subject;
  }

  void _discard() {
    _upstream?.cancel();
    _upstream = null;
    _subject?.close();
    _subject = null;
  }

  /// Descarta los datos en caché de todas las consultas (ej. al cerrar sesión).
  static void resetAll() {
    for (final s in _instances) {
      s._discard();
    }
  }
}
