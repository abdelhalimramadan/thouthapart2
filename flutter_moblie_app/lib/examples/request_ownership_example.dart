import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/helpers/request_ownership_helper.dart';

import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';

/// Example showing how to implement ownership logic for requests
class RequestOwnershipExample extends StatefulWidget {
  const RequestOwnershipExample({super.key});

  @override
  State<RequestOwnershipExample> createState() => _RequestOwnershipExampleState();
}

class _RequestOwnershipExampleState extends State<RequestOwnershipExample> {
  int _currentDoctorId = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final doctorId = await RequestOwnershipHelper.getCurrentDoctorId();
    if (mounted) {
      setState(() {
        _currentDoctorId = doctorId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Ownership Example')),
      body: ListView(
        children: [
          // Example request card
          _buildRequestCard(
            request: CaseRequestModel(
              id: 1,
              doctorId: 123, // This would come from your API
              doctorFirstName: 'أحمد',
              doctorLastName: 'محمد',
              doctorPhoneNumber: '+201234567890',
              doctorCityName: 'القاهرة',
              doctorUniversityName: 'جامعة القاهرة',
              categoryName: 'طب الأسنان',
              description: 'وصف الحالة',
              dateTime: '2026-03-17T21:00:00',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({required CaseRequestModel request}) {
    // Method 1: Using the helper's sync version (recommended for UI)
    final isOwner = RequestOwnershipHelper.isRequestOwnerSync(request, _currentDoctorId);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Request details
          Text(
            request.doctorFullName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Action buttons - only show for owners
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Method 1: Simple conditional rendering
              if (isOwner) ...[
                ElevatedButton.icon(
                  onPressed: () => _editRequest(request),
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _deleteRequest(request),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              // Method 2: Using the helper widget
              RequestOwnershipHelper.buildOwnerOnlyWidget(
                request: request,
                currentDoctorId: _currentDoctorId,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _editRequest(request),
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _deleteRequest(request),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Method 3: Using conditional widget
              RequestOwnershipHelper.buildConditionalWidget(
                request: request,
                currentDoctorId: _currentDoctorId,
                ownerWidget: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _editRequest(request),
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _deleteRequest(request),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                nonOwnerWidget: const Text(
                  'لا يمكنك تعديل أو حذف هذا الطلب',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editRequest(CaseRequestModel request) {
    // Navigate to edit screen
    print('Editing request: ${request.id}');
  }

  void _deleteRequest(CaseRequestModel request) {
    // Show confirmation dialog and delete
    print('Deleting request: ${request.id}');
  }
}

/// FutureBuilder version for when you need async checking
class RequestCardFutureBuilder extends StatelessWidget {
  final CaseRequestModel request;

  const RequestCardFutureBuilder({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: RequestOwnershipHelper.getCurrentDoctorId(),
      builder: (context, snapshot) {
        final currentDoctorId = snapshot.data ?? 0;
        final isOwner = RequestOwnershipHelper.isRequestOwnerSync(request, currentDoctorId);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(request.doctorFullName),
              const SizedBox(height: 16),
              
              // Only show delete button for owners
              if (isOwner)
                ElevatedButton.icon(
                  onPressed: () => _deleteRequest(request),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('حذف الطلب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _deleteRequest(CaseRequestModel request) {
    print('Deleting request: ${request.id}');
  }
}
