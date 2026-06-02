# Dash Bloquera - Sistema ERP de Gestión Integral

![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20|%20Firestore%20|%20Storage%20|%20AppCheck-FFCA28?logo=firebase)
![Provider](https://img.shields.io/badge/State%20Management-Provider-42A5F5)

**Dash Bloquera** es una aplicación móvil multiplataforma desarrollada en **Flutter**, diseñada para la gestión administrativa y operativa integral de empresas de manufactura (Bloqueras). El sistema centraliza el control de inventarios, ventas, presupuestos, finanzas y recursos humanos, garantizando la continuidad operativa gracias a su arquitectura *Offline-First*.

---

## 📱 Características Principales

### 📦 Gestión de Inventario Avanzada
* **Control de Stock en Tiempo Real:** Monitoreo preciso de existencias de productos y materia prima.
* **Kardex Automatizado:** Registro histórico detallado de movimientos (entradas por compras, ajustes e inventario inicial).
* **Escaneo de Código de Barras Nativos:** Permite usar dispositivos físicos ("pistolas" Android) como entrada de teclado estándar sin plugins pesados.

### 💰 Módulo de Ventas, Presupuestos y Facturación
* **Punto de Venta (POS):** Interfaz ágil y optimizada para la creación de ventas rápidas.
* **Presupuestos / Cotizaciones:** Generación y gestión de estimaciones de ventas previas a la facturación, con conversión fácil a ventas concretadas.
* **Generación de Documentos PDF:**
  * **Formato A4:** Comprobantes detallados e impresiones térmicas tipo ticket (80mm).
* **Control de Saldos:** Gestión de cuentas por cobrar y abonos parciales.

### 📊 Dashboard y Finanzas
* **Visualización de KPIs:** Gráficos interactivos de ingresos vs. gastos.
* **Exportación de Datos Avanzada:** Exportación de tablas financieras y bases de datos a formato CSV nativo de Android y uso de shares para evitar conflictos de "Scoped Storage".
* **Gestión de Gastos:** Registro y categorización de egresos operativos.

### 👥 Recursos Humanos (RRHH)
* **Gestión de Personal:** Directorio centralizado.
* **Control de Asistencia:** Registro de jornadas laborales y cálculo automatizado de nóminas basadas en asistencias.

### 🔐 Seguridad y Conectividad (Preparado para Producción)
* **Role-Based Access Control (RBAC):** Cuentas con roles (incluyendo un flag \`isDemo\` en \`AuthProvider\` para limitar ediciones en demostraciones).
* **Modo Demostración (Portfolio):** Permite a visitantes explorar la funcionalidad completa de la aplicación sin necesidad de registro, mediante un acceso anónimo de solo lectura.
* **Firebase App Check:** Prevención contra fraudes usando *Play Integrity* (Android), *DeviceCheck* (Apple) y *ReCaptchaV3* (Web).
* **Arquitectura Offline:** Manejo limpio de \`FirebaseException\` ("unavailable") para transacciones y paginación Firestore.
* **Tema Adaptable:** Soporte global para Dark Mode vía \`ThemeProvider\`.

---

## 🛠 Stack Tecnológico

* **Frontend:** Flutter & Dart (Compatible con sintaxis moderna como \`withValues\` para opacidades).
* **Backend (BaaS):** Firebase (Firestore, Auth, Storage, AppCheck).
* **Gestión de Estado:** Provider Pattern.
* **Seguridad:** Entornos cargados mediante \`flutter_dotenv\`.
* **Exportación/Impresión:** \`csv\`, \`share_plus\`, \`pdf\`, \`printing\`.

---

## 🚀 Guía de Instalación y Despliegue Local

### 1. Prerrequisitos
- Flutter SDK (Versión 3.27+ recomendada).
- Cuenta activa de Firebase y proyecto configurado (Web, Android, iOS según tu objetivo).

### 2. Clonar el repositorio
\`\`\`bash
git clone https://github.com/PABM25/dash_bloquera.git
cd dash_bloquera
\`\`\`

### 3. Instalar dependencias
\`\`\`bash
flutter pub get
\`\`\`

### 4. Configurar Variables de Entorno (\`.env\`)
Crea un archivo \`.env\` en el directorio raíz (al mismo nivel que el \`pubspec.yaml\`) e ingresa las variables de Firebase. El archivo \`.env\` no se versiona en Git por seguridad:

\`\`\`env
# Ejemplo de contenido para .env
PROJECT_ID=tu_project_id
MESSAGING_SENDER_ID=tu_sender_id
STORAGE_BUCKET=tu_storage_bucket

# Configuración Web
WEB_API_KEY=tu_web_api_key
WEB_APP_ID=tu_web_app_id
WEB_AUTH_DOMAIN=tu_web_auth_domain
RECAPTCHA_V3_SITE_KEY=tu_clave_publica_recaptcha_v3

# Configuración Android / iOS
ANDROID_API_KEY=tu_android_api_key
ANDROID_APP_ID=tu_android_app_id
IOS_API_KEY=tu_ios_api_key
IOS_APP_ID=tu_ios_app_id
IOS_BUNDLE_ID=tu_ios_bundle_id
\`\`\`

> *Asegúrate de que la API key para ReCaptcha V3 esté registrada correctamente en el portal de Firebase App Check si deseas desplegar en web.*

### 5. Configurar Firestore Rules (Producción)
Este proyecto cuenta con un archivo local \`firestore.rules\`. Debes subirlas a Firebase mediante el panel de Firebase Console o la CLI de Firebase:
\`\`\`bash
firebase deploy --only firestore:rules
\`\`\`

### 6. Ejecutar la aplicación
\`\`\`bash
flutter run
\`\`\`
*(O utiliza \`flutter build apk\` / \`flutter build web\` para compilar a producción).*

---

## 🌟 Modo Demo para Portafolio

Este proyecto incluye una funcionalidad de **"VER DEMO"** diseñada específicamente para reclutadores o interesados que deseen probar la aplicación sin configurar Firebase ni crear una cuenta:

1. Al iniciar la app, selecciona el botón **"VER DEMO"**.
2. La aplicación iniciará sesión de forma anónima y asignará automáticamente el rol `demo`.
3. **Restricciones del modo Demo:**
   - La interfaz oculta los botones de creación (Floating Action Buttons).
   - Se deshabilitan las acciones de edición y eliminación.
   - Un banner informativo en el Dashboard indica que se encuentra en modo de solo lectura.
   - Las *Firestore Security Rules* están configuradas para rechazar cualquier intento de escritura desde una cuenta con rol `demo`.

---

## 📂 Estructura del Proyecto

El código está organizado siguiendo un principio de capas para facilitar la modularidad:
\`\`\`text
lib/
├── models/         # Clases de datos (Producto, Venta, Usuario, etc.)
├── providers/      # Lógica de negocio (InventarioProvider, AuthProvider, etc.)
├── screens/        # Interfaz de usuario dividida por dominios
├── utils/          # Constantes, configuraciones de Theme (AppTheme)
├── widgets/        # Componentes UI reutilizables
└── main.dart       # Punto de entrada y configuraciones de Firebase + Providers
\`\`\`
