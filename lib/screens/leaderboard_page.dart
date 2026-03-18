import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: Text(
          "Global Leaderboard",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('leaderboardPoints', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading leaderboard',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No users found on the leaderboard yet!',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final points = userData['leaderboardPoints'] ?? 0;
              final name = userData['fullName'] ?? 'Anonymous';
              final isTopThree = index < 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isTopThree ? const Color(0xFF2ECC71).withOpacity(0.1) : const Color(0xFF1C1E24),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isTopThree ? const Color(0xFF2ECC71).withOpacity(0.5) : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTopThree ? const Color(0xFF2ECC71) : Colors.white10,
                      ),
                      child: Center(
                        child: Text(
                          "#${index + 1}",
                          style: GoogleFonts.poppins(
                            color: isTopThree ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$points PTS",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2ECC71),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Icon placeholder based on rank
                    if (index == 0)
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    if (index == 1)
                      Icon(Icons.emoji_events, color: Colors.grey.shade400, size: 28),
                    if (index == 2)
                      Icon(Icons.emoji_events, color: Colors.orange.shade300, size: 28),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
