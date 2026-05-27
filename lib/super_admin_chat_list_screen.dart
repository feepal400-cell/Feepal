import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class SuperAdminChatListScreen extends StatefulWidget {
  const SuperAdminChatListScreen({super.key});

  @override
  State<SuperAdminChatListScreen> createState() => _SuperAdminChatListScreenState();
}

class _SuperAdminChatListScreenState extends State<SuperAdminChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Column(
        children: [
          // --- GRADIENT HEADER ---
          _buildHeader(),
          // --- CHAT LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getChatRoomsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2168F8),
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final allRooms = snapshot.data!.docs;

                // Filter by search query
                final rooms = _searchQuery.isEmpty
                    ? allRooms
                    : allRooms.where((doc) {
                        var room = doc.data() as Map<String, dynamic>;
                        String schoolName = (room['schoolName'] ?? '').toString().toLowerCase();
                        return schoolName.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (allRooms.isEmpty) {
                  return _buildEmptyState();
                }

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$_searchQuery"',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF2168F8),
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      var room = rooms[index].data() as Map<String, dynamic>;
                      String schoolId = room['schoolId'] ?? rooms[index].id;
                      return _buildChatTile(room, schoolId, index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== GRADIENT HEADER =====
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A5CE8), Color(0xFF2979FF), Color(0xFF40C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x402168F8),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              ),
              const Expanded(
                child: Text(
                  'Support Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Unread badge summary
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getChatRoomsStream(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();
                  int totalUnread = 0;
                  for (var doc in snap.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    totalUnread += ((data['unreadCount'] ?? 0) as num).toInt();
                  }
                  if (totalUnread == 0) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$totalUnread new',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search schools...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14.5),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.7), size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2168F8).withOpacity(0.08),
                  const Color(0xFF40C4FF).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 52,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No support requests yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When schools contact support, they\'ll appear here',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===== CHAT TILE =====
  Widget _buildChatTile(Map<String, dynamic> room, String roomId, int index) {
    String schoolName = room['schoolName'] ?? 'Loading...';
    String lastMsg = room['lastMessage'] ?? '';
    String? logo = room['schoolLogo'];
    int unreadCount = ((room['unreadCount'] ?? 0) as num).toInt();
    bool hasUnread = room['hasUnread'] == true;
    dynamic timestamp = room['lastMessageAt'];

    String timeStr = '';
    if (timestamp != null) {
      DateTime ts = (timestamp as Timestamp).toDate();
      DateTime now = _firebaseService.secureTime;
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime msgDate = DateTime(ts.year, ts.month, ts.day);

      if (msgDate == today) {
        timeStr = DateFormat('hh:mm a').format(ts);
      } else if (msgDate == today.subtract(const Duration(days: 1))) {
        timeStr = 'Yesterday';
      } else {
        timeStr = DateFormat('MMM dd').format(ts);
      }
    }

    // If room metadata doesn't have school info, fallback to FutureBuilder
    if (schoolName == 'Loading...') {
      return FutureBuilder<Map<String, dynamic>?>(
        future: _firebaseService.getAdminData(roomId),
        builder: (context, adminSnapshot) {
          String resolvedName = adminSnapshot.data?['schoolName'] ?? 'School';
          String? resolvedLogo = adminSnapshot.data?['schoolLogo'];
          return _buildChatTileCard(
            roomId: roomId,
            schoolName: resolvedName,
            logo: resolvedLogo,
            lastMsg: lastMsg,
            timeStr: timeStr,
            unreadCount: unreadCount,
            hasUnread: hasUnread,
            index: index,
          );
        },
      );
    }

    return _buildChatTileCard(
      roomId: roomId,
      schoolName: schoolName,
      logo: logo,
      lastMsg: lastMsg,
      timeStr: timeStr,
      unreadCount: unreadCount,
      hasUnread: hasUnread,
      index: index,
    );
  }

  Widget _buildChatTileCard({
    required String roomId,
    required String schoolName,
    required String? logo,
    required String lastMsg,
    required String timeStr,
    required int unreadCount,
    required bool hasUnread,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 60)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () async {
          // Mark as read
          await _firebaseService.markChatAsRead(roomId, true);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(roomId: roomId, schoolName: schoolName),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasUnread ? Colors.white : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: hasUnread
                ? Border.all(color: const Color(0xFF2168F8).withOpacity(0.15), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: hasUnread
                    ? const Color(0xFF2168F8).withOpacity(0.08)
                    : Colors.black.withOpacity(0.03),
                blurRadius: hasUnread ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2168F8).withOpacity(0.12),
                      const Color(0xFF40C4FF).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF2168F8).withOpacity(0.1),
                    width: 1.5,
                  ),
                  image: (logo != null && logo.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(logo), fit: BoxFit.cover)
                      : null,
                ),
                child: (logo == null || logo.isEmpty)
                    ? const Center(
                        child: Icon(Icons.school_rounded, color: Color(0xFF2168F8), size: 26),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  schoolName,
                                  style: TextStyle(
                                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  height: 6,
                                  width: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2168F8), // Matching theme color for SA
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread ? const Color(0xFF2168F8) : Colors.grey[400],
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? Colors.grey[700] : Colors.grey[400],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A5CE8), Color(0xFF2979FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
