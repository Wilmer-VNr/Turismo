import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsPage extends StatefulWidget {
  final String lugarId;
  
  const ReviewsPage({super.key, required this.lugarId});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final TextEditingController comentarioController = TextEditingController();
  late final CollectionReference resenasRef;
  
  String? currentUserName;
  String? userRole;

  @override
  void initState() {
    super.initState();
    resenasRef = FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('reseñas');
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select('name, role')
            .eq('id', user.id)
            .single();
        
        setState(() {
          currentUserName = '${data['name']} ';
          userRole = data['role'];
        });
      }
    } catch (e) {
      print('Error al obtener usuario: $e');
    }
  }

  Future<void> _agregarResena() async {
    if (comentarioController.text.trim().isEmpty) {
      _showSnackBar('Por favor escribe un comentario');
      return;
    }

    try {
      await resenasRef.add({
        'comentario': comentarioController.text.trim(),
        'autor': currentUserName ?? 'Usuario',
        'fecha': Timestamp.now(),
        'role': userRole ?? 'visitante',
      });
      
      comentarioController.clear();
      if (mounted) {
        _showSnackBar('Reseña agregada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al agregar reseña: $e');
      }
    }
  }

  Future<void> _eliminarResena(String resenaId) async {
    try {
      await resenasRef.doc(resenaId).delete();
      if (mounted) {
        _showSnackBar('Reseña eliminada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al eliminar reseña: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseñas del Lugar'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Información del perfil actual
          if (userRole != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: userRole == 'publicador' ? Colors.blue[50] : Colors.green[50],
              child: Row(
                children: [
                  Icon(
                    userRole == 'publicador' ? Icons.edit : Icons.visibility,
                    color: userRole == 'publicador' ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil ${userRole![0].toUpperCase() + userRole!.substring(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: userRole == 'publicador' ? Colors.blue : Colors.green,
                          ),
                        ),
                        Text(
                          userRole == 'publicador' 
                              ? 'Puedes gestionar reseñas'
                              : 'Puedes visualizar reseñas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de reseñas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: resenasRef.orderBy('fecha', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final resenas = snapshot.data!.docs;
                
                if (resenas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay reseñas aún',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '¡Sé el primero en comentar!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resenas.length,
                  itemBuilder: (context, index) {
                    final resena = resenas[index].data() as Map<String, dynamic>;
                    final resenaId = resenas[index].id;
                    final fecha = (resena['fecha'] as Timestamp).toDate();
                    final autor = resena['autor'] ?? 'Anónimo';
                    final role = resena['role'] ?? 'visitante';
                    final isCurrentUser = autor == currentUserName;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: role == 'publicador' 
                                      ? Colors.blue 
                                      : Colors.green,
                                  child: Text(
                                    autor[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            autor,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: role == 'publicador' 
                                                  ? Colors.blue 
                                                  : Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              role[0].toUpperCase() + role.substring(1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (userRole == 'publicador' || isCurrentUser)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _eliminarResena(resenaId);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Eliminar'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              resena['comentario'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Campo para agregar reseña
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: comentarioController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe una reseña...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _agregarResena(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _agregarResena,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 