# Turismo Ciudadano - App Flutter

Una aplicación móvil para el turismo ciudadano desarrollada por "El Búho" que permite a los usuarios publicar y descubrir sitios turísticos con reseñas y fotografías.

## 🚀 Funcionalidades Implementadas

### ✅ Completamente Implementado

1. **Sistema de Autenticación**
   - Registro e inicio de sesión de usuarios
   - Dos perfiles diferenciados: Visitante y Publicador
   - Validación de email y contraseña
   - Interfaz moderna con gradientes y animaciones

2. **Publicación de Lugares Turísticos**
   - Formulario completo con nombre, ubicación y descripción
   - Subida de múltiples fotografías (mínimo 5, máximo 10)
   - Validación de tamaño de imágenes (100KB - 5MB)
   - Compresión automática de imágenes
   - Captura de fotos desde la cámara
   - Selección desde galería
   - Grid visual de imágenes subidas

3. **Sistema de Reseñas Completo**
   - Visualización de reseñas existentes
   - Publicación de nuevas reseñas
   - Sistema de respuestas a reseñas (comentarios anidados)
   - Interfaz intuitiva con avatares y fechas

4. **Interfaz de Usuario Moderna**
   - Diseño responsive y atractivo
   - Navegación fluida entre pantallas
   - Indicadores de carga y estados
   - Mensajes de confirmación y error
   - Paleta de colores consistente

### 🎯 Perfiles de Usuario

#### Visitante
- Visualizar todos los lugares turísticos publicados
- Ver múltiples imágenes por lugar con navegación
- Leer reseñas existentes
- Publicar reseñas sobre lugares
- Responder a reseñas de otros usuarios

#### Publicador
- Todas las funcionalidades del visitante
- Publicar nuevos lugares turísticos
- Subir múltiples fotografías (5-10)
- Gestionar contenido propio

## 🛠️ Configuración de la Base de Datos

### Supabase Setup

1. **Crear proyecto en Supabase**
   - Ve a [supabase.com](https://supabase.com)
   - Crea un nuevo proyecto
   - Guarda la URL y anon key

2. **Configurar Storage**
   ```sql
   -- Crear bucket para imágenes
   INSERT INTO storage.buckets (id, name, public) 
   VALUES ('uploads', 'uploads', true);
   ```

3. **Crear tablas en la base de datos**

   ```sql
   -- Tabla de lugares turísticos
   CREATE TABLE lugares (
     id SERIAL PRIMARY KEY,
     nombre VARCHAR(255) NOT NULL,
     descripcion TEXT NOT NULL,
     ubicacion VARCHAR(255) NOT NULL,
     imagenes TEXT[] NOT NULL,
     user_id UUID REFERENCES auth.users(id),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Tabla de reseñas
   CREATE TABLE reviews (
     id SERIAL PRIMARY KEY,
     post_id INTEGER REFERENCES lugares(id) ON DELETE CASCADE,
     user_id UUID REFERENCES auth.users(id),
     content TEXT NOT NULL,
     parent_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Políticas de seguridad RLS
   ALTER TABLE lugares ENABLE ROW LEVEL SECURITY;
   ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

   -- Políticas para lugares
   CREATE POLICY "Lugares visibles para todos" ON lugares
     FOR SELECT USING (true);

   CREATE POLICY "Solo publicadores pueden insertar" ON lugares
     FOR INSERT WITH CHECK (
       (SELECT user_metadata->>'user_type' FROM auth.users WHERE id = auth.uid()) = 'Publicador'
     );

   -- Políticas para reseñas
   CREATE POLICY "Reseñas visibles para todos" ON reviews
     FOR SELECT USING (true);

   CREATE POLICY "Usuarios autenticados pueden insertar reseñas" ON reviews
     FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
   ```

4. **Configurar Storage Policies**
   ```sql
   -- Permitir subida de imágenes a usuarios autenticados
   CREATE POLICY "Usuarios autenticados pueden subir imágenes" ON storage.objects
     FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

   -- Permitir lectura pública de imágenes
   CREATE POLICY "Imágenes públicas" ON storage.objects
     FOR SELECT USING (true);
   ```

## 📱 Instalación y Configuración

### Prerrequisitos
- Flutter SDK 3.8.1 o superior
- Dart SDK
- Android Studio / VS Code
- Dispositivo Android/iOS o emulador

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd turismo_ciudadano
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Supabase**
   - Actualiza las credenciales en `lib/main.dart`
   - Reemplaza la URL y anon key con las de tu proyecto

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📦 Dependencias Utilizadas

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.9.1      # Backend y autenticación
  file_picker: ^10.2.0          # Selección de archivos
  camera: ^0.11.0+1             # Acceso a cámara
  image_picker: ^1.0.7          # Captura de imágenes
  path_provider: ^2.1.2         # Manejo de rutas
  permission_handler: ^11.3.1   # Gestión de permisos
  cached_network_image: ^3.3.1  # Carga optimizada de imágenes
  image: ^4.1.7                 # Procesamiento de imágenes
```

## 🔧 Configuración de Permisos

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para tomar fotos de lugares turísticos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Esta app necesita acceso a la galería para seleccionar fotos</string>
```

## 🎨 Características de Diseño

- **Interfaz moderna** con gradientes y sombras
- **Navegación intuitiva** entre pantallas
- **Validaciones en tiempo real** de formularios
- **Indicadores de progreso** para operaciones asíncronas
- **Mensajes de feedback** con colores apropiados
- **Diseño responsive** para diferentes tamaños de pantalla

## 🚀 Funcionalidades Técnicas

- **Validación de imágenes**: Tamaño mínimo 100KB, máximo 5MB
- **Compresión automática**: Optimización de calidad vs tamaño
- **Carga lazy**: Imágenes cargadas bajo demanda
- **Gestión de estado**: Manejo eficiente de estados de UI
- **Manejo de errores**: Captura y presentación de errores
- **Persistencia**: Datos guardados en Supabase

## 📊 Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada y configuración
├── login_page.dart        # Autenticación y registro
├── crearLugar.dart        # Publicación de lugares (Publicadores)
└── visitantePage.dart     # Visualización y reseñas (Todos)
```

## 🔒 Seguridad

- **Autenticación robusta** con Supabase Auth
- **Políticas RLS** para control de acceso a datos
- **Validación de entrada** en frontend y backend
- **Permisos granulares** por tipo de usuario
- **Sanitización de datos** antes de almacenar

## 🎯 Próximas Mejoras

- [ ] Sistema de calificaciones con estrellas
- [ ] Filtros por ubicación y categorías
- [ ] Búsqueda de lugares
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Compartir lugares en redes sociales
- [ ] Mapa interactivo de lugares
- [ ] Sistema de favoritos

## 📞 Soporte

Para soporte técnico o preguntas sobre la implementación, contacta al equipo de desarrollo de "El Búho".

---

**Desarrollado con ❤️ por El Búho**
