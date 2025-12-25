import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/investment_plan_model.dart';
import '../../services/investment_plan_service.dart';
import '../../services/api_service.dart' show ApiException;
import 'investment_setup_success_screen.dart';

class PaymentMandateScreen extends StatefulWidget {
  final InvestmentPlan plan;
  final int? goalId;

  const PaymentMandateScreen({
    super.key,
    required this.plan,
    this.goalId,
  });

  @override
  State<PaymentMandateScreen> createState() => _PaymentMandateScreenState();
}

class _PaymentMandateScreenState extends State<PaymentMandateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _createMandate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mandate = await InvestmentPlanService.createPaymentMandate(
        bankAccountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim().toUpperCase(),
        accountHolderName: _accountHolderController.text.trim(),
        goalId: widget.goalId,
      );

      // Complete setup
      await InvestmentPlanService.completeSetup(
        mandateId: mandate['id'],
        goalId: widget.goalId,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InvestmentSetupSuccessScreen(
              goalId: widget.goalId,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = e.message;
        
        // Parse validation errors if available
        if (e.errors != null && e.errors!.isNotEmpty) {
          final errorList = e.errors!.map((err) {
            final field = err['field'] ?? '';
            final msg = err['msg'] ?? '';
            return '${field.isNotEmpty ? "$field: " : ""}$msg';
          }).join('\n');
          errorMessage = errorList;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Mandate',
          style: AppTheme.headingSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Placeholder Card
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Placeholder for creating payment Mandate',
                      style: AppTheme.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bank Account Details Form
                Text(
                  'Bank Account Details',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    labelText: 'Account Holder Name',
                    hintText: 'Enter account holder name',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter account holder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    hintText: 'Enter bank account number',
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter account number';
                    }
                    final accountNumber = value.trim();
                    if (!RegExp(r'^\d+$').hasMatch(accountNumber)) {
                      return 'Account number must contain only digits';
                    }
                    if (accountNumber.length < 9 || accountNumber.length > 18) {
                      return 'Account number must be between 9 and 18 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ifscController,
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    hintText: 'Enter IFSC code (e.g., HDFC0001234)',
                    prefixIcon: const Icon(Icons.code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter IFSC code';
                    }
                    final ifscCode = value.trim().toUpperCase();
                    if (ifscCode.length != 11) {
                      return 'IFSC code must be exactly 11 characters';
                    }
                    // IFSC format: AAAA0XXXXXX (4 letters, 0, then 6 alphanumeric)
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscCode)) {
                      return 'Invalid IFSC format. Use format: AAAA0XXXXXX';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Next Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createMandate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Next >'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

