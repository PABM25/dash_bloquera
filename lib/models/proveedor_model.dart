class Proveedor {
  final String id;
  final String nombre;
  final String rut;
  final String contacto;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.rut,
    required this.contacto,
  });

  factory Proveedor.fromFirestore(Map<String, dynamic> data, String id) {
    return Proveedor(
      id: id,
      nombre: data['nombre'] ?? '',
      rut: data['rut'] ?? '',
      contacto: data['contacto'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'rut': rut,
      'contacto': contacto,
    };
  }
}
