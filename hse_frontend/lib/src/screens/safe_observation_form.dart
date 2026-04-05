import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SafetyObservationForm extends StatefulWidget {
  const SafetyObservationForm({super.key, this.onSubmit});

  final Function(Map<String, dynamic>)? onSubmit;

  @override
  State<SafetyObservationForm> createState() => _SafetyObservationFormState();
}

class _SafetyObservationFormState extends State<SafetyObservationForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _category = 'Unsafe Act';
  String _severity = 'Medium';
  String _location = '';
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_selectedImages.length < 5) {
              _selectedImages.add(file);
            }
          }
        });
        // Read bytes for each selected file
        await _readImageBytes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(pickedFile);
        });
        // Read bytes
        await _readImageBytes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  Future<void> _readImageBytes() async {
    _imageBytes.clear();
    for (var image in _selectedImages) {
      try {
        final bytes = await image.readAsBytes();
        _imageBytes.add(bytes);
      } catch (e) {
        debugPrint('Error reading image bytes: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _imageBytes.length) {
        _imageBytes.removeAt(index);
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final data = {
        'content': _descriptionController.text.trim(),
        'category': _category,
        'severity': _severity,
        'location': _location.trim(),
        'status': 'Pending',
        'imageBytes': _imageBytes,
        'imageNames': _selectedImages.map((f) => f.name).toList(),
      };
      widget.onSubmit?.call(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 80,
        left: 0,
        right: 0,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.red.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'New Safety Observation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Report a safety observation or hazard.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // Category
                _sectionLabel('Category', Icons.category_outlined),
                Wrap(
                  spacing: 8,
                  children: [
                    'Unsafe Act',
                    'Unsafe Condition',
                    'Safe Act',
                  ].map((c) => _categoryChip(c)).toList(),
                ),
                const SizedBox(height: 16),
                // Severity
                _sectionLabel('Severity', Icons.warning_amber_outlined),
                Wrap(
                  spacing: 8,
                  children: [
                    'Low',
                    'Medium',
                    'High',
                  ].map((s) => _severityChip(s)).toList(),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Location', Icons.location_on_outlined),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Where was this observed?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (v) => _location = v,
                ),
                const SizedBox(height: 16),
                _sectionLabel('Description', Icons.description_outlined),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'What did you observe?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please describe the observation'
                      : null,
                ),
                const SizedBox(height: 20),
                // Media section
                _sectionLabel('Photos / Video', Icons.photo_camera_outlined),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedImages.length}/5 images selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedImages.length >= 5
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ),
                // Image preview
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _selectedImages[index].path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Observation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String category) {
    final isSelected = _category == category;
    Color color;
    switch (category.toLowerCase()) {
      case 'unsafe act':
        color = Colors.red.shade700;
        break;
      case 'unsafe condition':
        color = Colors.orange.shade700;
        break;
      case 'safe act':
        color = Colors.blue.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (v) => setState(() => _category = category),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }

  Widget _severityChip(String severity) {
    final isSelected = _severity == severity;
    Color color;
    switch (severity.toLowerCase()) {
      case 'low':
        color = Colors.green.shade700;
        break;
      case 'medium':
        color = Colors.orange.shade700;
        break;
      case 'high':
        color = Colors.red.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }
    return ChoiceChip(
      label: Text(severity),
      selected: isSelected,
      onSelected: (v) => setState(() => _severity = severity),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }
}
