class Cliente {
  final String id;
  final String nombreRazonSocial;
  final String rut;
  final String direccion;
  final String? telefono;
  final String? email;

  Cliente({
    required this.id,
    required this.nombreRazonSocial,
    required this.rut,
    required this.direccion,
    this.telefono,
    this.email,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombreRazonSocial,
      'rut': rut,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'searchKeywords': _generateKeywords(nombreRazonSocial),
    };
  }

  // Generador de keywords para búsqueda simple
  List<String> _generateKeywords(String text) {
    List<String> keywords = [];
    String temp = "";
    for (int i = 0; i < text.length; i++) {
      temp = temp + text[i].toLowerCase();
      keywords.add(temp);
    }
    return keywords;
  }
}
