import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'parent_admin_chat_screen.dart';
import 'package:intl/intl.dart';

class AdminParentChatListScreen extends StatefulWidget {
  const AdminParentChatListScreen({super.key});

  @override
  State<AdminParentChatListScreen> createState() => _AdminParentChatListScreenState();
}

class _AdminParentChatListScreenState extends State<AdminParentChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late String _currentAdminId;

  @override
  void initState() {
    super.initState();
    _currentAdminId = _firebaseService.currentAdminId ?? '';
  }

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
              stream: _firebaseService.getAdminParentChatRoomsStream(_currentAdminId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9E38FF), // Admin theme color
                      strokeWidth: 2.5,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final allRooms = snapshot.data!.docs;

                // Filter by search query
                final rooms = _searchQuery.isEmpty
                    ? allRooms
                    : allRooms.where((doc) {
                        var room = doc.data() as Map<String, dynamic>;
                        String parentName = (room['parentName'] ?? '').toString().toLowerCase();
                        return parentName.contains(_searchQuery.toLowerCase());
                      }).toList();

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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    var room = rooms[index].data() as Map<String, dynamic>;
                    String parentId = room['parentId'] ?? rooms[index].id;
                    return _buildChatTile(room, parentId, index);
                  },
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
          colors: [Color(0xFF7B1FA2), Color(0xFF9E38FF), Color(0xFFD500F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x409E38FF),
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
                  'Parent Message Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
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
                hintText: 'Search parents...',
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
                  const Color(0xFF9E38FF).withOpacity(0.08),
                  const Color(0xFFD500F9).withOpacity(0.04),
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
            'No message requests yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When parents contact you, they\'ll appear here',
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
  Widget _buildChatTile(Map<String, dynamic> room, String parentId, int index) {
    String parentName = room['parentName'] ?? 'Parent';
    String lastMsg = room['lastMessageText'] ?? '';
    bool hasUnread = room['hasUnreadForAdmin'] == true;
    dynamic timestamp = room['lastMessageTime'];

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
          await _firebaseService.markParentAdminChatAsRead(parentId, 'admin');

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParentAdminChatScreen(
                  parentId: parentId,
                  parentName: parentName,
                  adminId: _currentAdminId,
                  role: 'admin',
                ),
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
                ? Border.all(color: const Color(0xFF9E38FF).withOpacity(0.15), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: hasUnread
                    ? const Color(0xFF9E38FF).withOpacity(0.08)
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
                      const Color(0xFF9E38FF).withOpacity(0.12),
                      const Color(0xFFD500F9).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF9E38FF).withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Color(0xFF9E38FF), size: 26),
                ),
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
                                  parentName,
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
                                    color: Color(0xFF9E38FF),
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
                            color: hasUnread ? const Color(0xFF9E38FF) : Colors.grey[400],
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? Colors.grey[700] : Colors.grey[400],
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
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
