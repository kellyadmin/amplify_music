import 'package:flutter/material.dart';

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFFFD700);
    const Color darkSurface = Color(0xFF1E1E1E);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Artist Info Section
          Container(
            decoration: BoxDecoration(
              color: isDark ? darkSurface : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/fameica.jpg'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('Fik Fameica',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.verified, color: gold, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('420K Followers',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Streams', '1.2M', gold),
              _buildStatCard('Songs', '12', gold),
              _buildStatCard('Listeners', '340K', gold),
            ],
          ),
          const SizedBox(height: 30),

          // Manage Songs
          Text('Your Songs',
              style:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          _buildSongTile(
              title: 'Sability',
              album: 'Top Hits',
              onEdit: () {},
              onDelete: () {}),
          _buildSongTile(
              title: 'Energy',
              album: 'Vibes Only',
              onEdit: () {},
              onDelete: () {}),

          const SizedBox(height: 30),

          // Upload New
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload New Song'),
            onPressed: () {
              // Upload logic or screen
            },
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile({
    required String title,
    required String album,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(album),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'Edit') onEdit();
            if (value == 'Delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'Edit', child: Text('Edit')),
            PopupMenuItem(value: 'Delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
