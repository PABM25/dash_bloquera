# Guía para Migrar a un Nuevo Repositorio (Portafolio)

Esta versión de **Dash Bloquera** ha sido preparada con un sistema de **Mock Data** para que puedas crear un repositorio independiente que funcione sin necesidad de configurar Firebase, ideal para demostraciones rápidas en tu portafolio.

## Pasos para crear el nuevo repositorio:

1. **Crear el repositorio en GitHub:** Crea un nuevo repositorio vacío (ej: `dash-bloquera-demo`).
2. **Clonar esta rama:**
   ```bash
   git clone -b demo-portfolio-mode https://github.com/PABM25/dash_bloquera.git dash-bloquera-portfolio
   cd dash-bloquera-portfolio
   ```
3. **Cambiar el origen remoto:**
   ```bash
   git remote remove origin
   git remote add origin https://github.com/TU_USUARIO/TU_NUEVO_REPO.git
   ```
4. **Limpiar archivos innecesarios (Opcional):**
   Puedes eliminar archivos como `firebase.json`, `firestore.rules`, etc., si quieres una versión 100% limpia de backend, aunque no estorban.
5. **Subir al nuevo repo:**
   ```bash
   git add .
   git commit -m "Initial commit: Portfolio standalone version"
   git push -u origin main
   ```

## Características de esta versión:
- **Zero Configuration:** No requiere archivo `.env` ni cuenta de Firebase para funcionar en modo demo.
- **Modo Solo Lectura:** El botón "VER DEMO" activa repositorios locales que cargan datos de prueba desde `lib/repositories/mock_data.dart`.
- **Resiliencia:** Si Firebase no está configurado, la app no crashea y permite entrar directamente al modo demo.

---
¡Listo! Ahora tienes una versión perfecta para que cualquier reclutador la clone y la ejecute con un simple `flutter run`.
