import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';

class AddProductDialog extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Product) onSubmit;

  const AddProductDialog({
    super.key,
    this.product,
    required this.onSubmit,
  });

  bool get isEditing => product != null;

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _locationController;
  late final TextEditingController _harvestDateController;
  late final TextEditingController _expiryDateController;

  late String _unit;
  late String _category;
  late bool _isOrganic;
  bool _isLoading = false;

  static const _units = ['KG', 'G', 'TON', 'PIECE', 'BUNCH', 'BOX'];
  static const _categories = [
    'VEGETABLES',
    'FRUITS',
    'GRAINS',
    'DAIRY',
    'MEAT',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '',
    );
    _locationController = TextEditingController(text: p?.location ?? '');
    _harvestDateController = TextEditingController(
      text: p != null ? _formatDateForField(p.harvestDate) : '',
    );
    _expiryDateController = TextEditingController(
      text: p?.expiryDate != null ? _formatDateForField(p!.expiryDate!) : '',
    );
    _unit = p?.unit ?? 'KG';
    _category = p?.category.isNotEmpty == true ? p!.category : 'VEGETABLES';
    if (p != null && _categories.contains(p.category)) {
      _category = p.category;
    }
    _isOrganic = p?.isOrganic ?? false;
  }

  static String _formatDateForField(String value) {
    if (value.isEmpty) return '';
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isEditing
                            ? Icons.edit_outlined
                            : Icons.add_box_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Edit Product' : 'Add New Product',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'Product Name', true),
                _buildTextField(
                  _descriptionController,
                  'Description',
                  false,
                  maxLines: 2,
                ),
                _buildPriceUnitRow(),
                _buildCategoryStockRow(),
                _buildTextField(_locationController, 'Location', true),
                _buildDateField(_harvestDateController, 'Harvest Date', true),
                _buildDateField(
                  _expiryDateController,
                  'Expiry Date (optional)',
                  false,
                ),
                SwitchListTile(
                  title: const Text('Organic product'),
                  value: _isOrganic,
                  onChanged: (v) => setState(() => _isOrganic = v),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: widget.isEditing ? 'Save Changes' : 'Add Product',
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => v?.isEmpty == true ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label,
    bool required,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        readOnly: true,
        onTap: () => _selectDate(controller),
        validator: required
            ? (v) => v?.isEmpty == true ? '$label is required' : null
            : null,
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      controller.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildPriceUnitRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: 'ETB ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty == true) return 'Price required';
                if (double.tryParse(v!) == null) return 'Invalid price';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField(
              value: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: _units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => _unit = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStockRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField(
              value: _categories.contains(_category) ? _category : 'VEGETABLES',
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty == true) return 'Stock required';
                if (int.tryParse(v!) == null) return 'Invalid stock';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      unit: _unit,
      category: _category,
      stock: int.parse(_stockController.text),
      images: widget.product?.images ?? [],
      location: _locationController.text.trim(),
      isOrganic: _isOrganic,
      harvestDate: _harvestDateController.text,
      expiryDate: _expiryDateController.text.isEmpty
          ? null
          : _expiryDateController.text,
      farmerId: widget.product?.farmerId ?? '',
      isAvailable: widget.product?.isAvailable ?? true,
    );

    try {
      await widget.onSubmit(product);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    _harvestDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }
}
