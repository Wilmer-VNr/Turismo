import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

class CrLugarPage extends StatefulWidget {
  const CrLugarPage({super.key});

  @override
  State<CrLugarPage> createState() => _CrLugarPageState();
}

class _CrLugarPageState extends State<CrLugarPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  List<String> uploadedImageUrls = [];
  bool isLoading = false;

  // Configuración de validación de imágenes
  static const double maxImageSizeMB = 5.0; // 5MB máximo
  static const double minImageSizeMB = 0.1; // 100KB mínimo
  static const int maxImages = 10; // Máximo 10 imágenes
  static const int minImages = 1; // Mínimo 5 imágenes

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final user = supabase.auth.currentUser;
    final userType = user?.userMetadata?['user_type'];
    if (user == null || userType != 'Publicador') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso solo para Publicadores')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();
    
    return statuses[Permission.camera]!.isGranted && 
           statuses[Permission.storage]!.isGranted;
  }

  Future<bool> _validateImageSize(Uint8List imageBytes) async {
    final sizeInMB = imageBytes.length / (1024 * 1024);
    
    if (sizeInMB > maxImageSizeMB) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La imagen es muy grande. Máximo ${maxImageSizeMB}MB'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    if (sizeInMB < minImageSizeMB) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La imagen es muy pequeña. Mínimo ${minImageSizeMB}MB'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image != null) {
        // Comprimir la imagen manteniendo calidad razonable
        final compressed = img.encodeJpg(image, quality: 85);
        return compressed;
      }
    } catch (e) {
      print('Error comprimiendo imagen: $e');
    }
    return imageBytes;
  }

  Future<void> _pickImageFromGallery() async {
    if (uploadedImageUrls.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxImages imágenes permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      await _processAndUploadImage(await image.readAsBytes(), image.name);
    }
  }

  Future<void> _takePhotoWithCamera() async {
    if (uploadedImageUrls.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxImages imágenes permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se requieren permisos de cámara y almacenamiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      await _processAndUploadImage(await image.readAsBytes(), image.name);
    }
  }

  Future<void> _processAndUploadImage(Uint8List imageBytes, String fileName) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Validar tamaño
      if (!await _validateImageSize(imageBytes)) {
        return;
      }

      // Comprimir imagen
      final compressedBytes = await _compressImage(imageBytes);
      
      // Generar nombre único
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Subir a Supabase Storage
      await supabase.storage
          .from('uploads')
          .uploadBinary(uniqueFileName, compressedBytes);
      
      final url = supabase.storage.from('uploads').getPublicUrl(uniqueFileName);
      
      setState(() {
        uploadedImageUrls.add(url);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen subida correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      uploadedImageUrls.removeAt(index);
    });
  }

  Future<void> _submitLugar() async {
    if (_nombreController.text.isEmpty ||
        _descripcionController.text.isEmpty ||
        _ubicacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (uploadedImageUrls.length < minImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes subir al menos $minImages imágenes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      final data = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'ubicacion': _ubicacionController.text,
        'imagenes': uploadedImageUrls,
        'user_id': user?.id,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('lugares').insert(data);
      
      // Limpiar formulario
      _nombreController.clear();
      _descripcionController.clear();
      _ubicacionController.clear();
      setState(() {
        uploadedImageUrls.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lugar turístico publicado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Lugar Turístico'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del lugar
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Lugar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del lugar *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.place),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _ubicacionController,
                            decoration: const InputDecoration(
                              labelText: 'Ubicación *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descripcionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Descripción *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sección de imágenes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_library),
                              const SizedBox(width: 8),
                              const Text(
                                'Imágenes del Lugar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${uploadedImageUrls.length}/$maxImages',
                                style: TextStyle(
                                  color: uploadedImageUrls.length >= minImages 
                                      ? Colors.green 
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mínimo $minImages, máximo $maxImages imágenes (${maxImageSizeMB}MB máximo)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Botones para agregar imágenes
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _takePhotoWithCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Cámara'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Galería'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Grid de imágenes subidas
                          if (uploadedImageUrls.isNotEmpty) ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: uploadedImageUrls.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        uploadedImageUrls[index],
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón de publicación
                  ElevatedButton(
                    onPressed: uploadedImageUrls.length >= minImages ? _submitLugar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Publicar Lugar Turístico',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}