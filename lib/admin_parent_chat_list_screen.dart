import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'parent_admin_chat_screen.dart';
import 'package:intl/intl.dart';

class AdminParentChatListScreen extends StatefulWidget {
  const AdminParentChatListScreen({super.key});

  @override
  State<AdminParentChatListScreen> createState() =>
      _AdminParentChatListScreenState();
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
              stream: _firebaseService.getAdminParentChatRoomsStream(
                _currentAdminId,
              ),
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
                        String parentName = (room['parentName'] ?? '')
                            .toString()
                            .toLowerCase();
                        return parentName.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
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
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        20,
      ),
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
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search parents...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14.5,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
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
                  const Color(0xFF9E38FF).withValues(alpha: 0.08),
                  const Color(0xFFD500F9).withValues(alpha: 0.04),
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
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ===== CHAT TILE =====
  Widget _buildChatTile(Map<String, dynamic> room, String parentId, int index) {
    String fallbackName = room['parentName'] ?? 'Parent';
    String lastMsg = room['lastMessageText'] ?? room['lastMessage'] ?? '';
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
        return FutureBuilder<DocumentSnapshot?>(
          future: room['parentName'] == null
              ? FirebaseFirestore.instance
                    .collection('admins')
                    .doc(_currentAdminId)
                    .collection('students')
                    .doc(parentId)
                    .get()
              : Future.value(null),
          builder: (context, snapshot) {
            String parentName = fallbackName;
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              parentName =
                  (snapshot.data!.data()
                      as Map<String, dynamic>)['parentName'] ??
                  'Parent';
            }

            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 30),
                child: GestureDetector(
                  onTap: () async {
                    // Mark as read
                    await _firebaseService.markParentAdminChatAsRead(
                      parentId,
                      _currentAdminId,
                      'admin',
                    );

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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: hasUnread
                            ? const Color(0xFF9E38FF)
                            : Colors.grey[200]!,
                        width: hasUnread ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: hasUnread
                                      ? const Color(0x1A9E38FF) // Light purple
                                      : const Color(0xFFF0F2F5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    parentName.isNotEmpty
                                        ? parentName[0].toUpperCase()
                                        : 'P',
                                    style: TextStyle(
                                      color: hasUnread
                                          ? const Color(0xFF9E38FF)
                                          : Colors.grey[600],
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9E38FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        parentName,
                                        style: TextStyle(
                                          fontWeight: hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasUnread
                                            ? const Color(0xFF9E38FF)
                                            : Colors.grey[500],
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg,
                                        style: TextStyle(
                                          color: hasUnread
                                              ? Colors.black87
                                              : Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: hasUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasUnread) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9E38FF),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
