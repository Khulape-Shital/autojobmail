import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fl_chart/fl_chart.dart';

class AIHelperScreen extends StatefulWidget {
  @override
  _AIHelperScreenState createState() => _AIHelperScreenState();
}

class _AIHelperScreenState extends State<AIHelperScreen> {
  late final GenerativeModel _model;
  String _output = '';
  File? _selectedFile;
  List<PieChartSectionData> _pieChartData = [];
  int _atsScore = 0;
  bool _isLoading = false;

  final List<String> _atsKeywords = [
    "python",
    "java",
    "communication",
    "leadership",
    "project management",
    "teamwork",
    "data analysis",
    "marketing",
    "sales",
    "customer service",
    "research",
    "design",
    "develop",
    "AWS",
    "cloud",
    "data science",
    "machine learning",
    "software engineering",
    "problem-solving",
    "management",
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: 'AIzaSyBv_nA0frLPsxt0KFAKVyz5Y6yx-fJ3HgE',
      generationConfig: GenerationConfig(
        maxOutputTokens: 3000,
        temperature: 0.1,
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _output = '';
        _pieChartData.clear();
        _atsScore = 0;
      });
    }
  }

  Future<String> _extractTextFromPDF(File file) async {
    final bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  String cleanText(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .trim();
  }

  int calculateATSScore(String text) {
    int score = 0;

    for (String keyword in _atsKeywords) {
      if (text.toLowerCase().contains(keyword.toLowerCase())) {
        score += 5;
      }
    }

    return score > 100 ? 100 : score;
  }

  void _analyzeResponse(String response) {
    int atsScore = calculateATSScore(response);

    setState(() {
      _atsScore = atsScore;
      _pieChartData = [
        PieChartSectionData(
          value: atsScore.toDouble(),
          title: 'Improvement Needed: $atsScore%',
          color: Colors.blue,
          radius: 50,
        ),
        PieChartSectionData(
          value: (100 - atsScore).toDouble(),
          title: 'ATS Score: ${100 - atsScore}%',
          color: Colors.grey,
          radius: 50,
        ),
      ];
    });
  }

  Future<void> _getSuggestionsAndDebug() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String fileContent = await _extractTextFromPDF(_selectedFile!);
      String cleanedContent = cleanText(fileContent);

      final prompt = '''
You are an AI assistant. Analyze the following content extracted from a PDF file:
---
$cleanedContent
---
1. Identify any issues or inconsistencies.
2. Suggest improvements or optimizations.
3. If it's a resume or code, recommend enhancements and fixes.
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      setState(() {
        _output = response.text ?? "No suggestions found.";
      });

      _analyzeResponse(response.text ?? "");
    } catch (e) {
      setState(() {
        _output = 'Error reading or analyzing the file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false when the operation finishes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Helper"), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Upload PDF File'),
            ),
            SizedBox(height: 10),
            if (_selectedFile != null)
              Text("Selected File: ${_selectedFile!.path.split('/').last}"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _getSuggestionsAndDebug,
              icon: Icon(Icons.analytics_outlined),
              label: Text("Analyze & Suggest"),
            ),
            SizedBox(height: 20),
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (!_isLoading)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_pieChartData.isNotEmpty)
                        Container(
                          height: 200,
                          child: PieChart(
                            PieChartData(sections: _pieChartData),
                          ),
                        ),
                      SizedBox(height: 20),
                      _output.isNotEmpty
                          ? MarkdownBody(data: _output)
                          : Text("Analysis will appear here."),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
