import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reviews_page.dart';

class PublisherPage extends StatefulWidget {
  const PublisherPage({super.key});

  @override
  State<PublisherPage> createState() => _PublisherPageState();
}

class _PublisherPageState extends State<PublisherPage> {
  final turismosRef = FirebaseFirestore.instance.collection('turismo');
  final picker = ImagePicker();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController fotoController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? currentUserName;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', user.id)
            .single();

        setState(() {
          currentUserName = '${data['name']}';
        });
      }
    } catch (e) {
      print('Error al obtener usuario: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image != null) {
        return Uint8List.fromList(img.encodeJpg(image, quality: 85));
      }
    } catch (e) {
      print('Error al comprimir imagen: $e');
    }
    return imageBytes;
  }

  Future<void> _pickImageFromSupabase(bool fromCamera) async {
    final XFile? image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    final sizeMB = imageBytes.length / (1024 * 1024);

    if (sizeMB > 5.0) {
      _showSnackBar('La imagen excede el tamaño máximo de 5MB');
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final compressed = await _compressImage(imageBytes);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      await Supabase.instance.client.storage
          .from('uploads')
          .uploadBinary(fileName, compressed);

      final publicUrl = Supabase.instance.client.storage
          .from('uploads')
          .getPublicUrl(fileName);

      setState(() {
        fotoController.text = publicUrl;
      });

      _showSnackBar('Imagen subida correctamente');
    } catch (e) {
      _showSnackBar('Error al subir imagen: $e');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _guardarTurismo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await turismosRef.add({
          'nombre': nombreController.text,
          'descripcion': descripcionController.text,
          'foto': fotoController.text,
          'ubicacion': ubicacionController.text,
          'autor': currentUserName ?? 'Usuario',
          'fecha': Timestamp.now(),
        });

        _clearForm();
        _showSnackBar('Lugar turístico guardado correctamente');
      } catch (e) {
        _showSnackBar('Error al guardar: $e');
      }
    }
  }

  void _clearForm() {
    nombreController.clear();
    descripcionController.clear();
    fotoController.clear();
    ubicacionController.clear();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _verResenas(String turismoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsPage(lugarId: turismoId),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showSnackBar('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Publicador'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perfil Publicador',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tienes permisos para publicar en el blog, subir fotografías y gestionar reseñas.',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (currentUserName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Usuario: $currentUserName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Publicar Nuevo Lugar Turístico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(nombreController, 'Nombre del lugar'),
                  const SizedBox(height: 12),
                  _buildTextField(descripcionController, 'Descripción', maxLines: 3),
                  const SizedBox(height: 12),
                  _buildTextField(ubicacionController, 'Ubicación'),
                  const SizedBox(height: 12),
                  const Text(
                    'Imagen del lugar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : () => _pickImageFromSupabase(true),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : () => _pickImageFromSupabase(false),
                          icon: const Icon(Icons.image),
                          label: const Text('Galería'),
                        ),
                      ),
                    ],
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (fotoController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fotoController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error, size: 50, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarTurismo,
                      icon: const Icon(Icons.save),
                      label: const Text('Publicar Lugar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Lugares Publicados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: turismosRef.orderBy('fecha', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final lugares = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lugares.length,
                  itemBuilder: (context, index) {
                    final lugar = lugares[index];
                    final fecha = lugar['fecha'] as Timestamp?;
                    return Card(
                      child: ListTile(
                        leading: lugar['foto'] != null && lugar['foto'] != ''
                            ? Image.network(lugar['foto'], width: 60, height: 60, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 60),
                        title: Text(lugar['nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lugar['descripcion']),
                            if (fecha != null)
                              Text(
                                'Publicado: ${DateFormat.yMMMd().format(fecha.toDate())}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        onTap: () => _verResenas(lugar.id),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.edit),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        return null;
      },
    );
  }
}
