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
      // CORRECCIÓN CLAVE: Casteo seguro 'as num?'. 
      // Esto evita crashes si 'stock' viene como double (ej: 5.0) en la BD.
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      
      // CORRECCIÓN CLAVE: Aseguramos que siempre sea double.
      precioCosto: (data['precio_costo'] as num?)?.toDouble() ?? 0.0,
      
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