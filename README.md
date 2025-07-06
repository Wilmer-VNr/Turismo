# Blog Turístico App

Una aplicación Flutter que permite a los usuarios compartir y descubrir lugares turísticos con un sistema de perfiles diferenciados.

## Características

### Perfiles de Usuario

**Perfil Visitante:**

- Puede visualizar contenido y reseñas
- Acceso a geolocalización
- Navegación por lugares turísticos
- Lectura de reseñas de otros usuarios

**Perfil Publicador:**

- Tiene permisos para publicar en el blog
- Subir fotografías de lugares turísticos
- Gestionar reseñas (agregar y eliminar)
- Panel completo de administración de contenido

### Instalación

1. Clona el repositorio:

```bash
git clone <url-del-repositorio>
cd blog_turismo_app
```

2. Instala las dependencias:

```bash
flutter pub get
```

3. Configura las credenciales:

   - Actualiza las credenciales de Supabase en `lib/main.dart`
   - Actualiza las credenciales de Firebase en `lib/main.dart`

4. Ejecuta la aplicación:

```bash
flutter run
```

## Funcionalidades Principales

### Autenticación

- Registro de usuarios con roles diferenciados
- Inicio de sesión con validación
- Gestión de sesiones con Supabase

### Panel del Publicador

- Formulario para crear nuevos lugares turísticos
- Subida de imágenes desde cámara o galería
- Gestión de coordenadas geográficas
- Lista de lugares publicados
- Gestión de reseñas

### Panel del Visitante

- Visualización de lugares turísticos
- Servicios de geolocalización
- Integración con Google Maps
- Lectura de reseñas
- Navegación intuitiva

### Sistema de Reseñas

- Comentarios en tiempo real
- Diferenciación por roles
- Gestión de permisos
- Interfaz responsive
