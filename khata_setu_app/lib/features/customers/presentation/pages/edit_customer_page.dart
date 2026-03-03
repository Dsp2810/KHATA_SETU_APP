import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/models/customer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

class EditCustomerPage extends StatefulWidget {
  final CustomerModel customer;

  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _notesController;

  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _creditLimitController = TextEditingController(
      text: widget.customer.creditLimit.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: widget.customer.notes ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final creditLimit =
          double.tryParse(_creditLimitController.text) ?? widget.customer.creditLimit;

      context.read<CustomerBloc>().add(UpdateCustomer(
            id: widget.customer.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            creditLimit: creditLimit,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerAdded) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.customerUpdated),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop(true);
        } else if (state is CustomerError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.all(8),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20, color: context.textPrimaryColor),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: GradientText(
                            text: l10n.editCustomer,
                            style: AppTextStyles.h3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Form(
                        key: _formKey,
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              CustomTextField(
                                controller: _nameController,
                                label: l10n.customerName,
                                hint: l10n.customerNameHint,
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => Validators.validateName(
                                    v, l10n: l10n),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Phone
                              CustomTextField(
                                controller: _phoneController,
                                label: l10n.phone,
                                hint: l10n.phoneHint,
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                validator: (v) => Validators.validatePhone(
                                    v, l10n: l10n),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Credit Limit
                              CustomTextField(
                                controller: _creditLimitController,
                                label: l10n.creditLimitLabel,
                                hint: '5000',
                                prefixIcon: Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                                validator: (v) => Validators.validateAmount(
                                    v, l10n: l10n),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Notes
                              CustomTextField(
                                controller: _notesController,
                                label: l10n.addNotesOptional,
                                hint: l10n.customerNotesHint,
                                prefixIcon: Icons.note_outlined,
                                maxLines: 3,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Save Button
                              CustomButton(
                                onPressed: _isLoading ? null : _onSave,
                                text: l10n.updateCustomer,
                                icon: Icons.save_outlined,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
