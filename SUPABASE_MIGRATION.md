# Migración a Supabase - Instrucciones

Este documento describe los pasos necesarios para completar la migración del backend personalizado a Supabase.

## 📋 Resumen de Cambios

La aplicación ha sido migrada para usar **Supabase** en lugar del backend personalizado (`https://venya-backend.vercel.app`). Los siguientes archivos fueron actualizados:

### Archivos Nuevos
- `lib/Services/supabase_service.dart` - Servicio principal de Supabase
- `supabase/schema.sql` - Esquema de base de datos

### Archivos Modificados
- `pubspec.yaml` - Agregada dependencia `supabase_flutter`
- `lib/main.dart` - Inicialización de Supabase
- `lib/screens/login_screen.dart` - Login con Supabase Auth
- `lib/screens/register_screen.dart` - Registro con Supabase Auth
- `lib/screens/register_documents_screen.dart` - Guardar documentos en Supabase
- `lib/screens/main_screen.dart` - Guardar viajes en Supabase
- `lib/splashScreen/splash_screen.dart` - Verificación de sesión con Supabase

## 🚀 Configuración de Supabase

### 1. Crear Proyecto en Supabase

1. Ve a [Supabase Dashboard](https://app.supabase.com)
2. Crea un nuevo proyecto
3. Espera a que se complete la configuración

### 2. Obtener Credenciales

En tu proyecto de Supabase:
1. Ve a **Project Settings** → **API**
2. Copia la **URL** y la **anon key**
3. Reemplaza los valores en `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'https://tu-proyecto.supabase.co',  // Tu URL de Supabase
  anonKey: 'tu-anon-key-aqui',              // Tu anon key
);
```

### 3. Configurar Base de Datos

1. Ve a **SQL Editor** en el dashboard de Supabase
2. Crea una **New query**
3. Copia y pega todo el contenido de `supabase/schema.sql`
4. Ejecuta el script (Run)

### 4. Configurar Autenticación

1. Ve a **Authentication** → **Settings**
2. Configura los proveedores de autenticación:
   - **Email**: Habilitado por defecto
   - Si deseas usar Google, Facebook, etc., configúralos aquí

3. En **Email Templates**, personaliza los mensajes si es necesario

### 5. Configurar Políticas de Seguridad (RLS)

Las políticas RLS ya están configuradas en el archivo `schema.sql`, pero verifica que estén activas:

1. Ve al **Table Editor**
2. Selecciona la tabla `users`
3. Verifica que esté habilitado **RLS** (toggle verde)
4. Revisa las políticas en la pestaña **Policies**

Repite para la tabla `rides`.

## 📱 Configuración de la App

### Android

En `android/app/src/main/AndroidManifest.xml`, agrega el permiso de internet si no está:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

En `ios/Runner/Info.plist`, agrega:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🧪 Probar la Integración

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar la app**:
   ```bash
   flutter run
   ```

3. **Flujo de prueba**:
   - Registro de usuario nuevo
   - Login
   - Subir documentos
   - Solicitar un viaje
   - Verificar que los datos se guarden en Supabase

## 🔍 Verificar en Supabase

Para verificar que los datos se están guardando correctamente:

1. Ve a **Table Editor** en el dashboard de Supabase
2. Revisa las tablas `users` y `rides`
3. Los registros nuevos deberían aparecer allí

## 🔄 Cambios en la Estructura de Datos

### Diferencias Clave

| Antes (Backend Propio) | Ahora (Supabase) |
|------------------------|------------------|
| JWT token personalizado | Token de Supabase Auth |
| `_id` como string | `id` como UUID |
| `blocked`, `verified` | Igual, pero manejado en Supabase |
| Documentos en JSON | Documentos en JSONB (PostgreSQL) |

### Tablas en Supabase

#### users
```sql
- id (UUID, PK, vinculado a auth.users)
- names (TEXT)
- surnames (TEXT)
- email (TEXT)
- phone (TEXT)
- address (TEXT)
- identification_type (TEXT)
- identification_number (TEXT)
- documents (JSONB)
- blocked (BOOLEAN)
- verified (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### rides
```sql
- id (UUID, PK)
- user_id (UUID, FK)
- firebase_ride_id (TEXT)
- origin_address (TEXT)
- destination_address (TEXT)
- origin_latitude (DECIMAL)
- origin_longitude (DECIMAL)
- destination_latitude (DECIMAL)
- destination_longitude (DECIMAL)
- vehicle_type (TEXT)
- fare_amount (DECIMAL)
- distance (DECIMAL)
- duration (INTEGER)
- driver_id (TEXT)
- status (TEXT)
- rating (INTEGER)
- feedback (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- completed_at (TIMESTAMP)
```

## 🔐 Seguridad

### Row Level Security (RLS)

Las políticas RLS garantizan que:
- Cada usuario solo puede ver/modificar sus propios datos
- Los viajes están asociados al usuario que los creó
- No se pueden hacer operaciones CRUD sin autenticación

### Tokens

- El token JWT de Supabase tiene una duración limitada (por defecto 1 hora)
- Se refresca automáticamente mientras la sesión esté activa
- El token se almacena en `AppInfo` para compatibilidad con el código existente

## 🐛 Solución de Problemas

### Error: "Invalid API key"
Verifica que la `anonKey` en `main.dart` sea correcta.

### Error: "relation 'users' does not exist"
No ejecutaste el script SQL. Ve al SQL Editor y ejecútalo.

### Error: "new row violates row-level security policy"
El usuario no está autenticado o las políticas RLS están mal configuradas.

### No se guardan los datos
Verifica que:
1. El usuario esté autenticado
2. Las políticas RLS permitan la operación
3. Los campos requeridos no sean NULL

## 📝 Notas Adicionales

### Mantener Firebase
La app aún usa Firebase para:
- Notificaciones push (FCM)
- Realtime Database (para tracking de conductores)
- Storage (para imágenes de documentos, opcional)
- Google Maps API (para lugares y direcciones)

### Migración de Datos Existentes
Si necesitas migrar datos del backend anterior:
1. Exporta los datos del backend actual
2. Transforma los IDs de string a UUID
3. Usa la API de Supabase o el panel de administración para importar

## 📞 Soporte

- Documentación de Supabase: https://supabase.com/docs
- Documentación de supabase_flutter: https://supabase.com/docs/reference/dart
- Comunidad de Supabase: https://github.com/supabase/supabase/discussions
