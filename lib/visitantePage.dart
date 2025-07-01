import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'login_page.dart';

class VisitorHomePage extends StatefulWidget {
  const VisitorHomePage({super.key});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  Future<List<Map<String, dynamic>>> _fetchLugares() async {
    final lugaresRes = await Supabase.instance.client
        .from('lugares')
        .select('id, nombre, descripcion, ubicacion, imagenes, created_at, user_id')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(lugaresRes);
  }

  Future<List<Map<String, dynamic>>> _fetchReviews(int postId) async {
    try {
      final reviewsRes = await Supabase.instance.client
          .from('reviews')
          .select('id, content, created_at, user_id, parent_id')
          .eq('post_id', postId)
          .order('created_at', ascending: false);
      
      // Filtrar solo reseñas principales (sin parent_id)
      final reviews = List<Map<String, dynamic>>.from(reviewsRes);
      return reviews.where((review) => review['parent_id'] == null).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReplies(int reviewId) async {
    try {
      final repliesRes = await Supabase.instance.client
          .from('reviews')
          .select('id, content, created_at, user_id')
          .eq('parent_id', reviewId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(repliesRes);
    } catch (e) {
      print('Error fetching replies: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turismo Ciudadano'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLugares(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final lugares = snapshot.data ?? [];
          if (lugares.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay sitios turísticos publicados.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: lugares.length,
            itemBuilder: (context, index) {
              final lugar = lugares[index];
              return _buildLugarCard(lugar);
            },
          );
        },
      ),
    );
  }

  Widget _buildLugarCard(Map<String, dynamic> lugar) {
    final List<String> imagenes = List<String>.from(lugar['imagenes'] ?? []);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imágenes del lugar
          if (imagenes.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: imagenes.length,
                itemBuilder: (context, imageIndex) {
                  return CachedNetworkImage(
                    imageUrl: imagenes[imageIndex],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
            // Indicadores de página
            if (imagenes.length > 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imagenes.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == 0 ? Colors.blue : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
          ],
          
          // Información del lugar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lugar['nombre'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lugar['ubicacion'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lugar['descripcion'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                
                // Sección de reseñas
                _buildReviewsSection(lugar['id']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(int postId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rate_review, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Reseñas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de reseñas existentes
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchReviews(postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final reviews = snapshot.data ?? [];
            
            if (reviews.isEmpty) {
              return const Text(
                'No hay reseñas aún. ¡Sé el primero en comentar!',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              );
            }
            
            return Column(
              children: reviews.map((review) => _buildReviewCard(review, postId)).toList(),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Formulario para nueva reseña
        _buildReviewForm(postId),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, int postId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(review['created_at']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review['content'] ?? ''),
            const SizedBox(height: 8),
            
            // Botón para responder
            TextButton.icon(
              onPressed: () => _showReplyDialog(review['id'], postId),
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Responder'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: EdgeInsets.zero,
              ),
            ),
            
            // Respuestas a esta reseña
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchReplies(review['id']),
              builder: (context, snapshot) {
                final replies = snapshot.data ?? [];
                if (replies.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  children: replies.map((reply) => _buildReplyCard(reply)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(Map<String, dynamic> reply) {
    return Container(
      margin: const EdgeInsets.only(left: 32, top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuario',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      _formatDate(reply['created_at']),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reply['content'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm(int postId) {
    final reviewController = TextEditingController();
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deja tu reseña:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Comparte tu experiencia...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final content = reviewController.text.trim();
                          if (content.isEmpty) return;
                          
                          setState(() => isLoading = true);
                          try {
                            final userId = Supabase.instance.client.auth.currentUser?.id;
                            await Supabase.instance.client
                                .from('reviews')
                                .insert({
                                  'post_id': postId,
                                  'user_id': userId,
                                  'content': content,
                                });
                            reviewController.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reseña enviada exitosamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refrescar la página
                              setState(() {});
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setState(() => isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Enviar'),
                      ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showReplyDialog(int reviewId, int postId) {
    final replyController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Responder a la reseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: replyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      final content = replyController.text.trim();
                      if (content.isEmpty) return;
                      
                      setState(() => isLoading = true);
                      try {
                        final userId = Supabase.instance.client.auth.currentUser?.id;
                        await Supabase.instance.client
                            .from('reviews')
                            .insert({
                              'post_id': postId,
                              'user_id': userId,
                              'content': content,
                              'parent_id': reviewId,
                            });
                        
                        Navigator.of(context).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Respuesta enviada'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refrescar la página
                          setState(() {});
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
                    child: const Text('Enviar'),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}