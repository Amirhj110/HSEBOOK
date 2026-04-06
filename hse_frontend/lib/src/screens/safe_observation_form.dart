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
  final _observationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rectificationController = TextEditingController();
  
  String _postType = 'Observation';
  String _incidentType = 'Unsafe Act';
  String _severity = 'Medium';
  String _location = '';
  
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _observationController.dispose();
    _descriptionController.dispose();
    _rectificationController.dispose();
    super.dispose();
  }

  // ... (keeping _pickImages, _takePhoto, _readImageBytes, _removeImage) ...

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final data = {
        'postType': _postType,
        'incidentType': _incidentType,
        'observation': _observationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rectification': _rectificationController.text.trim(),
        'severity': _severity,
        'location': _location.trim(),
        'status': 'Open',
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
        top: 40,
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
                _buildHeader(),
                const SizedBox(height: 20),
                
                // Post Type Selection
                _sectionLabel('Report Type', Icons.assignment_outlined),
                Row(
                  children: [
                    _typeButton('Observation'),
                    const SizedBox(width: 12),
                    _typeButton('Incident'),
                  ],
                ),
                const SizedBox(height: 16),

                // Incident Type (Category)
                _sectionLabel('Category', Icons.category_outlined),
                Wrap(
                  spacing: 8,
                  children: [
                    'Unsafe Act',
                    'Unsafe Condition',
                    'Safe Act',
                  ].map((c) => _incidentTypeChip(c)).toList(),
                ),
                const SizedBox(height: 16),

                // Severity & Location
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Severity', Icons.warning_amber_outlined),
                          DropdownButtonFormField<String>(
                            value: _severity,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            items: ['Low', 'Medium', 'High'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _severity = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Location', Icons.location_on_outlined),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Area/Site',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onChanged: (v) => _location = v,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Observation Title
                _sectionLabel('Observation', Icons.visibility_outlined),
                TextFormField(
                  controller: _observationController,
                  decoration: InputDecoration(
                    hintText: 'Short title of the observation',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Description
                _sectionLabel('Description', Icons.description_outlined),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Provide detailed details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Rectification
                _sectionLabel('Rectification / Action', Icons.build_outlined),
                TextFormField(
                  controller: _rectificationController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'What action was taken?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionLabel('Attachments', Icons.photo_camera_outlined),
                _buildImagePickerControls(),
                if (_selectedImages.isNotEmpty) _buildImagePreview(),
                
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Text('Safety Professional Form', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
          ],
        ),
      ],
    );
  }

  Widget _typeButton(String type) {
    final isSelected = _postType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _postType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade700 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.red.shade700 : Colors.grey.shade300),
          ),
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _incidentTypeChip(String type) {
    final isSelected = _incidentType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (v) => setState(() => _incidentType = type),
      selectedColor: Colors.red.shade50,
      labelStyle: TextStyle(color: isSelected ? Colors.red.shade700 : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildImagePickerControls() {
    return Row(
      children: [
        Expanded(child: OutlinedButton.icon(onPressed: _pickImages, icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
        const SizedBox(width: 12),
        Expanded(child: OutlinedButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) => Stack(
              children: [
                Container(width: 80, height: 80, margin: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_selectedImages[index].path, fit: BoxFit.cover))),
                Positioned(top: 0, right: 8, child: GestureDetector(onTap: () => _removeImage(index), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
        label: Text(_isSubmitting ? 'Submitting...' : 'Submit HSE Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [Icon(icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 6), Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800))]),
    );
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_selectedImages.length < 5) _selectedImages.add(file);
          }
        });
        await _readImageBytes();
      }
    } catch (e) {}
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null && _selectedImages.length < 5) {
        setState(() => _selectedImages.add(pickedFile));
        await _readImageBytes();
      }
    } catch (e) {}
  }

  Future<void> _readImageBytes() async {
    _imageBytes.clear();
    for (var image in _selectedImages) {
      try {
        final bytes = await image.readAsBytes();
        _imageBytes.add(bytes);
      } catch (e) {}
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _imageBytes.length) _imageBytes.removeAt(index);
    });
  }
}
