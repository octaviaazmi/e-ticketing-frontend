import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'IT Support';
  String _selectedPriority = 'medium';
  List<XFile> _attachments = []; // 🔥 UBAH: List<XFile>
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'IT Support',
    'HR',
    'Finance',
    'Facility',
    'Lainnya',
  ];

  final Map<String, String> _priorityLabels = {
    'low': 'Rendah',
    'medium': 'Sedang',
    'high': 'Tinggi',
  };

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _attachments.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _attachments.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Judul tiket harus diisi'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deskripsi tiket harus diisi'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final result = await api.createTicket(
        title: _titleController.text,
        category: _selectedCategory,
        priority: _selectedPriority,
        description: _descriptionController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        int ticketId = result['ticketId'] ?? 0;
        int successCount = 0;

        if (ticketId > 0 && _attachments.isNotEmpty) {
          for (var xfile in _attachments) {
            final bytes = await xfile.readAsBytes();
            final fileName = xfile.name;
            var uploadResult = await api.uploadAttachment(ticketId, bytes, fileName);
            if (uploadResult['success']) successCount++;
          }
        }

        String message = result['message'];
        if (_attachments.isNotEmpty) {
          message += " ($successCount dari ${_attachments.length} file terupload)";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $message'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal membuat tiket'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
          'Buat Tiket',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ========== CARD ==========
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== TITLE ==========
                  Text(
                    'Judul',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.title,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan judul tiket',
                              hintStyle: GoogleFonts.inter(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18),

                  // ========== CATEGORY ==========
                  Text(
                    'Kategori',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.tag,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              dropdownColor: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              items: _categories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ),

                  SizedBox(height: 18),

                  // ========== PRIORITY ==========
                  Text(
                    'Prioritas',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.flag,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPriority,
                              isExpanded: true,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              dropdownColor: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              items: _priorityLabels.keys.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: value == 'high'
                                              ? Color(0xFFDC2626)
                                              : value == 'medium'
                                                  ? Color(0xFFF59E0B)
                                                  : Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(_priorityLabels[value]!),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedPriority = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ),

                  SizedBox(height: 18),

                  // ========== DESCRIPTION ==========
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Icon(
                            Icons.format_align_left,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 6,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Jelaskan masalah Anda...',
                              hintStyle: GoogleFonts.inter(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18),

                  // ========== ATTACHMENTS ==========
                  Text(
                    'Lampiran',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 6),

                  // Upload Zone
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.40) ?? Colors.grey,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 40,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.60) ?? Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap untuk upload gambar atau file',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            ),
                          ),
                          Text(
                            'Maksimal 5 file',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.70) ?? Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ========== ATTACHMENT PREVIEW ==========
                  if (_attachments.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _attachments.asMap().entries.map((entry) {
                          int index = entry.key;
                          XFile xfile = entry.value;
                          // 🔥 Preview: gunakan File dari path (masih work di web/mobile)
                          File file = File(xfile.path);
                          return Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: file.path.toLowerCase().endsWith('.jpg') ||
                                        file.path.toLowerCase().endsWith('.jpeg') ||
                                        file.path.toLowerCase().endsWith('.png') ||
                                        file.path.toLowerCase().endsWith('.gif')
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          file,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.insert_drive_file,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          size: 32,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: GestureDetector(
                                  onTap: () => _removeAttachment(index),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.error,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.error.withOpacity(0.30),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  // ========== CAMERA BUTTON ==========
                  if (_attachments.length < 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: _pickCamera,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Theme.of(context).primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ambil foto dari kamera',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 24),

                  // ========== SUBMIT BUTTON ==========
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Kirim Tiket',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}