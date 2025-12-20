import 'package:flutter/material.dart';
import 'dart:io';
import '../models/destination.dart';

class DestinationCard extends StatelessWidget {
  final Destination dest;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isAdmin;

  const DestinationCard({
    required this.dest,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isAdmin = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: dest.imagePath != null
                      ? Image.file(File(dest.imagePath!), fit: BoxFit.cover)
                      : Container(
                          color: Color(0xFFE0F2F1),
                          child: Icon(
                            Icons.landscape,
                            size: 40,
                            color: Color(0xFF00897B),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16),
              // Content Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      dest.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    // Address
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dest.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${dest.openTime} - ${dest.closeTime}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Category Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dest.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00897B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Ticket info (jika ada)
                    if (dest.ticketInfo.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 14,
                            color: Color(0xFF00897B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dest.ticketInfo,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Actions
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Color(0xFF00897B)),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') _showDeleteDialog(context);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Color(0xFF00897B)),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Destinasi?'),
        content: Text('Apakah Anda yakin ingin menghapus "${dest.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
