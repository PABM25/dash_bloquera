# Dash Bloquera - Sistema ERP de Gestión Integral

![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20|%20Firestore%20|%20Storage-FFCA28?logo=firebase)
![Provider](https://img.shields.io/badge/State%20Management-Provider-42A5F5)

**Dash Bloquera** es una aplicación móvil multiplataforma desarrollada en **Flutter** diseñada para la gestión administrativa y operativa completa de una empresa de manufactura (Bloquera). El sistema centraliza el control de inventarios, ventas, finanzas y recursos humanos, permitiendo operar incluso en entornos con conectividad inestable gracias a su arquitectura *Offline-First*.

## 📱 Características Principales

### 📦 Gestión de Inventario Avanzada
* **Control de Stock en Tiempo Real:** Monitoreo de existencias de productos.
* **Kardex Automatizado:** Registro histórico de movimientos (Entradas por compras/inventario inicial).
* **Cálculo de Costos:** Gestión de precios de costo para análisis de márgenes.

### 💰 Módulo de Ventas y Facturación
* **Punto de Venta (POS):** Interfaz ágil para la creación de ventas.
* **Generación de Documentos PDF:** * Formato A4 para comprobantes tipo factura.
  * Formato Ticket (80mm) para impresoras térmicas.
  * Ambos incluyen desglose de totales y datos de la empresa.
* **Control de Saldos:** Gestión de pagos parciales y cuentas por cobrar.

### 📊 Dashboard y Finanzas
* **Visualización de KPIs:** Gráficos interactivos de Ingresos vs. Gastos usando `fl_chart`.
* **Gestión de Gastos:** Registro y categorización de egresos operativos.
* **Resumen Financiero:** Cálculo automático de utilidad neta.

### 👥 Recursos Humanos
* **Gestión de Personal:** Base de datos de trabajadores.
* **Control de Asistencia:** Registro de días trabajados.
* **Cálculo de Nómina:** Procesamiento de salarios basado en asistencia.

### 🔐 Seguridad y Conectividad
* **Autenticación Robusta:** Login y Registro mediante Firebase Auth.
* **Persistencia de Datos:** Habilitada la persistencia en disco de Firestore para funcionalidad **Offline**.

## 🛠 Stack Tecnológico

* **Frontend:** Flutter & Dart.
* **Backend (BaaS):** Firebase (Firestore Database, Authentication, Storage).
* **Gestión de Estado:** Provider Pattern (MultiProvider, ProxyProvider).
* **Librerías Clave:**
  * `pdf` & `printing`: Generación y previsualización de documentos.
  * `fl_chart`: Gráficos estadísticos.
  * `firebase_core` & `cloud_firestore`: Conexión a BD NoSQL.
  * `flutter_dotenv`: Manejo de variables de entorno.

## 📂 Estructura del Proyecto

La arquitectura sigue una separación de responsabilidades clara para mantenibilidad:

```text
lib/
├── models/         # Modelos de datos (Producto, Venta, Usuario, etc.)
├── providers/      # Lógica de estado (InventoryProvider, SalesProvider)
├── repositories/   # Capa de acceso a datos (Firestore interactions)
├── screens/        # Interfaz de usuario (Vistas divididas por módulos)
│   ├── auth/
│   ├── dashboard/
│   ├── finanzas/
│   ├── inventario/
│   ├── rh/
│   └── ventas/
├── utils/          # Utilidades (PDF Generator, Validadores, Formateadores)
└── widgets/        # Componentes reutilizables (KPI Cards, Drawer)

```



## 🚀 Instalación y Configuración

### 1. Clonar repositorio

```text
git clone [https://github.com/tu-usuario/dash_bloquera.git](https://github.com/tu-usuario/dash_bloquera.git)
cd dash_bloquera
```

### 2.  Instalar dependencias

```text
flutter pub get
```
### 3. Configuración de Firebase:

Crea un proyecto en Firebase Console.

Descarga el archivo google-services.json (para Android) y colócalo en android/app/.

Asegúrate de habilitar Authentication y Firestore Database en la consola.

### 4. Variables de Entorno:

Crea un archivo .env en la raíz del proyecto (basado en el ejemplo si existe) para configurar credenciales sensibles si es necesario.

### 5. Ejecutar la app

```text
flutter run
```



