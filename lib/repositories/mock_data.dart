import '../models/producto_modelo.dart';
import '../models/venta_model.dart';
import '../models/trabajador_model.dart';
import '../models/proveedor_model.dart';
import '../models/gasto_model.dart';
import '../models/compra_model.dart';

class MockData {
  static final List<Producto> productos = [
    Producto(id: 'p1', nombre: 'Bloque 10x20x40', stock: 1500, precioCosto: 450, descripcion: 'Bloque estándar', barcode: '7801234567891'),
    Producto(id: 'p2', nombre: 'Bloque 15x20x40', stock: 800, precioCosto: 600, descripcion: 'Bloque reforzado', barcode: '7801234567892'),
    Producto(id: 'p3', nombre: 'Cemento 25kg', stock: 50, precioCosto: 3500, descripcion: 'Cemento Portland', barcode: '7801234567893'),
  ];

  static final List<Trabajador> trabajadores = [
    Trabajador(id: 't1', nombre: 'Juan Pérez', rut: '12.345.678-9', cargo: 'Operario Máquina', tipoProyecto: 'BLOQUERA', salarioPorDia: 25000),
    Trabajador(id: 't2', nombre: 'María González', rut: '15.678.901-2', cargo: 'Administración', tipoProyecto: 'BLOQUERA', salarioPorDia: 35000),
  ];

  static final List<Proveedor> proveedores = [
    Proveedor(id: 'pr1', nombre: 'Cemento S.A.', rut: '77.888.999-0', contacto: 'ventas@cemento.cl'),
    Proveedor(id: 'pr2', nombre: 'Ferretería El Martillo', rut: '88.111.222-3', contacto: 'contacto@elmartillo.cl'),
  ];

  static final List<Venta> ventas = [
    Venta(
      id: 'v1',
      folio: 'V-2025-0001',
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      cliente: 'Constructora Alfa',
      total: 450000,
      totalCosto: 300000,
      totalUtilidad: 150000,
      estadoPago: 'PAGADA',
      montoPagado: 450000,
      items: [
        ItemOrden(productoId: 'p1', nombre: 'Bloque 10x20x40', cantidad: 1000, precioUnitario: 450, totalLinea: 450000),
      ],
      estadoEntrega: 'ENTREGADO',
    ),
    Venta(
      id: 'v2',
      folio: 'V-2025-0002',
      fecha: DateTime.now(),
      cliente: 'Particular Juan',
      total: 60000,
      totalCosto: 40000,
      totalUtilidad: 20000,
      estadoPago: 'PENDIENTE',
      montoPagado: 0,
      items: [
        ItemOrden(productoId: 'p2', nombre: 'Bloque 15x20x40', cantidad: 100, precioUnitario: 600, totalLinea: 60000),
      ],
      estadoEntrega: 'PENDIENTE',
    ),
  ];

  static final List<Gasto> gastos = [
    Gasto(id: 'g1', descripcion: 'Reparación de cinta', monto: 50000, fecha: DateTime.now().subtract(const Duration(days: 2)), categoria: 'MANTENCION', tipoProyecto: 'BLOQUERA'),
    Gasto(id: 'g2', descripcion: 'Pago de luz', monto: 120000, fecha: DateTime.now().subtract(const Duration(days: 5)), categoria: 'SERVICIOS', tipoProyecto: 'BLOQUERA'),
  ];

  static final List<Compra> compras = [
    Compra(
      id: 'c1',
      folio: 'COM-2025-0001',
      proveedorId: 'pr1',
      proveedorNombre: 'Cemento S.A.',
      fecha: DateTime.now().subtract(const Duration(days: 3)),
      total: 350000,
      items: [
        CompraItem(productoId: 'p3', nombre: 'Cemento 25kg', cantidad: 100, costoUnitario: 3500, totalLinea: 350000),
      ],
    ),
  ];
}
