import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachmentTile extends StatelessWidget {
  final String fileName;
  final String fileUrl;

  const AttachmentTile({
    super.key,
    required this.fileName,
    required this.fileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // const Icon(Icons.insert_drive_file, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.download, color: Colors.grey),
        ],
      ),
    );
  }
}
