import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';
import '../models/comment.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class TicketDetailScreen extends StatefulWidget {
  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Ticket? _ticket;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (id != null) {
      _fetchTicket(id);
    }
  }

  Future<void> _fetchTicket(int id) async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final ticket = await api.getTicketDetail(id);
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail tiket: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tulis komentar terlebih dahulu'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSendingComment = true);
    await Future.delayed(Duration(milliseconds: 500));

    final auth = AuthService();
    final user = await auth.getUser();

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch,
      ticketId: _ticket!.id,
      userId: user?.id ?? 0,
      text: _commentController.text,
      createdAt: DateTime.now(),
      user: user,
    );

    setState(() {
      _ticket!.comments.add(newComment);
      _commentController.clear();
      _isSendingComment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Komentar ditambahkan'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========== METHOD UNTUK UPDATE STATUS ==========
  Future<void> _updateStatus(String status) async {
    try {
      final api = ApiService();
      final result = await api.updateTicketStatus(_ticket!.id, status);
      if (result['success']) {
        await _fetchTicket(_ticket!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ========== METHOD UNTUK ASSIGN ==========
  Future<void> _assignTicket() async {
    final helpdeskId = 2;
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/tickets/${_ticket!.id}'),
        headers: headers,
        body: jsonEncode({'assigned_to': helpdeskId}),
      );
      if (response.statusCode == 200) {
        await _fetchTicket(_ticket!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tiket berhasil ditugaskan ke Helpdesk'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? 'Gagal assign tiket'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ========== METHOD UNTUK DELETE ==========
  Future<void> _deleteTicket() async {
    try {
      final api = ApiService();
      final result = await api.deleteTicket(_ticket!.id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ========== HELPER HEADERS ==========
  Future<Map<String, String>> _getHeaders() async {
    final auth = AuthService();
    final token = await auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _ticket != null ? '#${_ticket!.id} ${_ticket!.title}' : 'Detail Tiket',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                builder: (context) => _buildActionSheet(),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _ticket == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tiket tidak ditemukan',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      SizedBox(height: 12),
                      _buildHistoryCard(),
                      SizedBox(height: 12),
                      _buildCommentsCard(),
                      SizedBox(height: 12),
                      _buildReplyBox(),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  // ========== ACTION SHEET ==========
  Widget _buildActionSheet() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final role = user?.role ?? 'user';
    final t = _ticket!;

    print('🔥 ROLE DI ACTION SHEET: $role');
    print('🔥 STATUS TIKET: ${t.status}');

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 16),

            if (role == 'admin' && t.status == 'open')
              _buildActionSheetItem(Icons.person_add, 'Assign ke Helpdesk', () {
                Navigator.pop(context);
                _assignTicket();
              }),

            if (role == 'helpdesk' && t.status == 'assigned')
              _buildActionSheetItem(Icons.check_circle, 'Terima', () {
                Navigator.pop(context);
                _updateStatus('inprogress');
              }),

            if (role == 'helpdesk' && t.status == 'inprogress')
              _buildActionSheetItem(Icons.check_circle, 'Selesai', () {
                Navigator.pop(context);
                _updateStatus('closed');
              }),

            if (role == 'admin' || role == 'helpdesk')
              _buildActionSheetItem(Icons.delete, 'Hapus', () {
                Navigator.pop(context);
                _deleteTicket();
              }),

            _buildActionSheetItem(Icons.close, 'Tutup', () {
              Navigator.pop(context);
            }, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSheetItem(IconData icon, String label, VoidCallback onTap, {bool isLast = false}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isLast
          ? null
          : Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
      onTap: onTap,
    );
  }

  // ========== BUILD INFO CARD ==========
  Widget _buildInfoCard() {
    final t = _ticket!;
    final statusMap = {
      'open': 'Open',
      'assigned': 'Assigned',
      'inprogress': 'In Progress',
      'closed': 'Closed'
    };
    final priorityMap = {'high': 'Tinggi', 'medium': 'Sedang', 'low': 'Rendah'};

    Color statusColor;
    Color statusBg;
    switch (t.status) {
      case 'open':
        statusColor = Color(0xFF2563EB);
        statusBg = Color(0xFFDBEAFE);
        break;
      case 'assigned':
        statusColor = Color(0xFFD97706);
        statusBg = Color(0xFFFEF3C7);
        break;
      case 'inprogress':
        statusColor = Color(0xFF7C3AED);
        statusBg = Color(0xFFEDE9FE);
        break;
      case 'closed':
        statusColor = Color(0xFF059669);
        statusBg = Color(0xFFD1FAE5);
        break;
      default:
        statusColor = Color(0xFF94A3B8);
        statusBg = Color(0xFFF1F5F9);
    }

    Color priorityColor;
    Color priorityBg;
    switch (t.priority) {
      case 'high':
        priorityColor = Color(0xFFDC2626);
        priorityBg = Color(0xFFFEE2E2);
        break;
      case 'medium':
        priorityColor = Color(0xFFD97706);
        priorityBg = Color(0xFFFEF3C7);
        break;
      case 'low':
        priorityColor = Color(0xFF2563EB);
        priorityBg = Color(0xFFDBEAFE);
        break;
      default:
        priorityColor = Color(0xFF94A3B8);
        priorityBg = Color(0xFFF1F5F9);
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Status', statusMap[t.status] ?? t.status, color: statusColor, bgColor: statusBg),
          Divider(color: Theme.of(context).dividerColor),
          _buildInfoRow('Prioritas', priorityMap[t.priority] ?? t.priority, color: priorityColor, bgColor: priorityBg),
          Divider(color: Theme.of(context).dividerColor),
          _buildInfoRow('Kategori', t.category),
          Divider(color: Theme.of(context).dividerColor),
          _buildInfoRow('Deskripsi', t.description, isDescription: true),
          Divider(color: Theme.of(context).dividerColor),
          _buildInfoRow('Pelapor', t.createdByUser?.name ?? 'Unknown'),
          Divider(color: Theme.of(context).dividerColor),
          _buildInfoRow('Ditugaskan ke', t.assignedToUser?.name ?? 'Belum ditugaskan'),
          Divider(color: Theme.of(context).dividerColor),
          _buildInfoRow('Dibuat', _formatDate(t.createdAt)),
          if (t.attachments.isNotEmpty) ...[
            Divider(color: Theme.of(context).dividerColor),
            Text(
              'Lampiran',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: t.attachments.map((fileName) {
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 24,
                        ),
                        SizedBox(height: 2),
                        Text(
                          fileName.length > 10 ? '${fileName.substring(0, 10)}...' : fileName,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, Color? bgColor, bool isDescription = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 4),
        if (color != null && bgColor != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isDescription ? 14 : 15,
              fontWeight: isDescription ? FontWeight.w400 : FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: isDescription ? 1.5 : 1,
            ),
          ),
        SizedBox(height: 4),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ========== HISTORY CARD ==========
  Widget _buildHistoryCard() {
    final t = _ticket!;
    final statusLabels = {
      'open': 'Dibuat',
      'assigned': 'Ditugaskan',
      'inprogress': 'Dikerjakan',
      'closed': 'Ditutup'
    };

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Tiket',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/tracking', arguments: t.id);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lihat Tracking',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (t.histories.isEmpty)
            Center(
              child: Text(
                'Belum ada riwayat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            )
          else
            ...t.histories.map((h) => _buildTimelineItem(
                  title: statusLabels[h.status] ?? h.status,
                  desc: h.note ?? '',
                  time: _formatDate(h.createdAt),
                  isLast: h == t.histories.last,
                )),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String title, required String desc, required String time, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4F46E5).withOpacity(0.30),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: Color(0xFF4F46E5).withOpacity(0.20),
              ),
          ],
        ),
        SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== COMMENTS CARD ==========
  Widget _buildCommentsCard() {
    final t = _ticket!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komentar',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 12),
          if (t.comments.isEmpty)
            Center(
              child: Text(
                'Belum ada komentar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            )
          else
            ...t.comments.map((c) => _buildCommentItem(c)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final initial = comment.user?.name?.isNotEmpty == true
        ? comment.user!.name[0].toUpperCase()
        : '?';
    final role = comment.user?.role ?? '';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFFDDD6FE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user?.name ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(width: 6),
                    if (role.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  comment.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatDate(comment.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== REPLY BOX ==========
  Widget _buildReplyBox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: 4,
              minLines: 1,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                hintStyle: GoogleFonts.inter(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4F46E5).withOpacity(0.30),
                  blurRadius: 12,
                ),
              ],
            ),
            child: IconButton(
              icon: _isSendingComment
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isSendingComment ? null : _addComment,
            ),
          ),
        ],
      ),
    );
  }

  // ========== BOTTOM NAV ==========
  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home, 'Beranda', 0, currentIndex == 0,
              onTap: () => Navigator.pushReplacementNamed(context, '/dashboard')),
          _buildNavItem(context, Icons.list_alt, 'Tiket', 1, currentIndex == 1,
              onTap: () => Navigator.pushReplacementNamed(context, '/tickets')),
          _buildNavItem(context, Icons.notifications, 'Notif', 2, currentIndex == 2,
              onTap: () => Navigator.pushReplacementNamed(context, '/notifications')),
          _buildNavItem(context, Icons.person, 'Profil', 3, currentIndex == 3,
              onTap: () => Navigator.pushReplacementNamed(context, '/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, bool isActive,
      {VoidCallback? onTap}) {
    final color = isActive
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodySmall?.color;
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}