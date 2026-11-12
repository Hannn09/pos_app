import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/products/presentation/providers/product_notifiers.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:food_pos/widgets/labeled_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final PosProduct? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockThresholdController;

  late String _selectedCategory;
  late bool _isAvailable;
  final List<PosAddon> _selectedAddons = [];
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.round().toString() : '',
    );
    _costPriceController = TextEditingController(
      text: p?.costPrice != null ? p!.costPrice!.round().toString() : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '20',
    );
    _lowStockThresholdController = TextEditingController(text: '5');

    _selectedCategory = p?.categoryId ?? 'coffee';
    _isAvailable = p?.isAvailable ?? true;
    _imagePath = p?.imagePath;

    if (p != null) {
      _selectedAddons.addAll(p.availableAddons);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final savedProduct = PosProduct(
        id:
            widget.productToEdit?.id ??
            'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        categoryId: _selectedCategory,
        price: double.tryParse(_priceController.text) ?? 0,
        costPrice: double.tryParse(_costPriceController.text),
        stock: int.tryParse(_stockController.text) ?? 0,
        icon: widget.productToEdit?.icon ?? IconsaxPlusLinear.reserve,
        isAvailable: _isAvailable,
        availableAddons: _selectedAddons,
        imagePath: _imagePath,
      );

      context.pop(savedProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.productToEdit == null
                ? 'Product added successfully'
                : 'Product updated successfully',
          ),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productToEdit != null;
    final categoriesAsync = ref.watch(categoriesProvider);
    final addonsAsync = ref.watch(addonsProvider);

    final categories =
        categoriesAsync.value?.where((c) => c.id != 'all').toList() ?? [];
    final availableAddonsList = addonsAsync.value ?? [];

    if (categories.isNotEmpty &&
        !categories.any((c) => c.id == _selectedCategory)) {
      _selectedCategory = categories.first.id;
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left, color: blackColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? 'Edit Product' : 'Add New Product',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _onSave,
              child: Text(
                'Save',
                style: boldTextStyle.copyWith(
                  fontSize: 15,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    if (_imagePath != null &&
                        File(_imagePath!).existsSync()) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_imagePath!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imagePath = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Change Product Photo',
                        style: semiBoldTextStyle.copyWith(
                          fontSize: 13,
                          color: blackColor,
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryLightColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          IconsaxPlusLinear.gallery_add,
                          size: 36,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload Product Photo',
                        style: boldTextStyle.copyWith(
                          fontSize: 15,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports JPG, PNG up to 5MB',
                        style: regularTextStyle.copyWith(
                          fontSize: 12,
                          color: greyColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Camera'),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 16,
                          ),
                          label: const Text('Gallery'),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: boldTextStyle.copyWith(
                        fontSize: 16,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledTextField(
                      label: 'Product Name',
                      hint: 'e.g. Iced Sea Salt Latte',
                      controller: _nameController,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: mediumTextStyle.copyWith(color: blackColor),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              categories.any((c) => c.id == _selectedCategory)
                              ? _selectedCategory
                              : (categories.isNotEmpty
                                    ? categories.first.id
                                    : null),
                          isExpanded: true,
                          hint: const Text('Select Category'),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: regularTextStyle.copyWith(
                                      color: blackColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing & Inventory',
                      style: boldTextStyle.copyWith(
                        fontSize: 16,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledTextField(
                            label: 'Selling Price (Rp)',
                            hint: 'e.g. 35000',
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Price required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledTextField(
                            label: 'Cost / COGS (Rp)',
                            hint: 'e.g. 15000',
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledTextField(
                            label: 'Initial Stock',
                            hint: 'e.g. 50',
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Stock required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledTextField(
                            label: 'Low Stock Alert',
                            hint: 'Alert when < 5',
                            controller: _lowStockThresholdController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: primaryColor,
                      title: Text(
                        'Available for Sale',
                        style: semiBoldTextStyle.copyWith(
                          fontSize: 14,
                          color: blackColor,
                        ),
                      ),
                      subtitle: Text(
                        'Disable to temporarily hide or mark as sold out',
                        style: regularTextStyle.copyWith(
                          fontSize: 12,
                          color: greyColor,
                        ),
                      ),
                      value: _isAvailable,
                      onChanged: (val) {
                        setState(() {
                          _isAvailable = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach Add-ons / Modifiers',
                      style: boldTextStyle.copyWith(
                        fontSize: 16,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select which add-ons can be chosen for this item',
                      style: regularTextStyle.copyWith(
                        fontSize: 12,
                        color: greyColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...availableAddonsList.map((addon) {
                      final isChecked = _selectedAddons.any(
                        (a) => a.id == addon.id,
                      );
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: primaryColor,
                        title: Text(
                          addon.name,
                          style: mediumTextStyle.copyWith(
                            fontSize: 13,
                            color: blackColor,
                          ),
                        ),
                        subtitle: Text(
                          addon.price > 0
                              ? '+Rp ${addon.price.round()}'
                              : 'Free Modifier',
                          style: regularTextStyle.copyWith(
                            fontSize: 11,
                            color: primaryColor,
                          ),
                        ),
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedAddons.add(addon);
                            } else {
                              _selectedAddons.removeWhere(
                                (a) => a.id == addon.id,
                              );
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: primaryButtonStyle,
                  onPressed: _onSave,
                  child: Text(
                    isEdit ? 'Save Changes' : 'Create Product',
                    style: boldTextStyle.copyWith(
                      fontSize: 15,
                      color: whiteColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
