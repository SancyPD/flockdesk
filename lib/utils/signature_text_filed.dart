import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlSignatureText extends StatefulWidget {
  @override
  _HtmlSignatureTextState createState() => _HtmlSignatureTextState();
}

class _HtmlSignatureTextState extends State<HtmlSignatureText> {
  final TextEditingController _signatureController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Email Signature")),
      body: Column(
        children: [
          // Input Field (raw HTML)
          TextField(
            controller: _signatureController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter your email signature (HTML)',
              border: OutlineInputBorder(),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) {
              setState(() {}); // refresh preview when typing
            },
          ),

          SizedBox(height: 20),

          Text("Preview:", style: TextStyle(fontWeight: FontWeight.bold)),

          // Render HTML Preview
          Expanded(
            child: SingleChildScrollView(
              child: Html(
                data: _signatureController.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}