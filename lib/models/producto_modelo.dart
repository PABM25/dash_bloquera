import 'package:cloud_firestore/cloud_firestore.dart';


class Producto {
  final String id;
  final String nombre;
  final int stock;
  final double precioCosto;
  final String? descripcion;

  Producto({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.precioCosto,
    this.descripcion,
  });
  
  // Convierte un documento de Firestore a un objeto Producto
  factory Producto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Producto(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      stock: data['stock'] ?? 0,
      // Convertir a double asegurando que no falle si viene como int
      precioCosto: (data['precio_costo'] ?? 0).toDouble(),
      descripcion: data['descripcion'],
    );
  }

  // Convierte el objeto a un Mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'stock': stock,
      'precio_costo': precioCosto,
      'descripcion': descripcion,
    };
  }

}