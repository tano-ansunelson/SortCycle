import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter_application_1/mobile_app/chat_page/chat_page.dart';
import 'package:flutter_application_1/mobile_app/routes/app_route.dart';
import 'package:intl/intl.dart';

class UserRequestsScreen extends StatefulWidget {
  final String userId; // Pass the current user's ID

  const UserRequestsScreen({super.key, required this.userId});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends State<UserRequestsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Pickups',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
              icon: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // stream: _firestore
        //     .collection('pickup_requests')
        //     .where('userId', isEqualTo: widget.userId)
        //     .orderBy('createdAt', descending: true)
        //     .snapshots(),
        stream: _firestore
            .collection('pickup_requests')
            .where('userId', isEqualTo: widget.userId)
            .where(
              'status',
              whereNotIn: ['completed'],
            ) // 👈 this line filters out completed
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: FadeTransition(
                opacity: _animationController,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade100,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.eco_outlined,
                          size: 64,
                          color: Colors.green.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No pickup requests yet',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start your journey towards a cleaner environment.\nYour pickup requests will appear here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return AnimatedList(
            padding: const EdgeInsets.all(16),
            initialItemCount: requests.length,
            itemBuilder: (context, index, animation) {
              if (index >= requests.length) return const SizedBox.shrink();

              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: RequestCard(
                  requestId: request.id,
                  requestData: data,
                  onCancel: () => _cancelRequest(request.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      // Show confirmation dialog
      bool? shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Cancel Request'),
            ],
          ),
          content: const Text(
            'Are you sure you want to cancel this pickup request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Request',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (shouldCancel == true) {
        await _firestore.collection('pickup_requests').doc(requestId).update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Request cancelled successfully'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to cancel request: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class RequestCard extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  final VoidCallback onCancel;

  const RequestCard({
    super.key,
    required this.requestId,
    required this.requestData,
    required this.onCancel,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.requestData['status'] as String;
    final pickupDate = (widget.requestData['pickupDate'] as Timestamp).toDate();
    // final wasteCategories = List<String>.from(
    //   widget.requestData['wasteCategories'] ?? [],
    // );
    final collectorId = widget.requestData['collectorId'] as String?;
    final hasCollector = collectorId != null && collectorId.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? Colors.green.shade200
                    : Colors.grey.shade200,
                blurRadius: _isPressed ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isPressed ? Colors.green.shade300 : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Status and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(status),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(pickupDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Pickup Details
                _buildInfoRow(
                  Icons.access_time_rounded,
                  'Pickup Time',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(pickupDate),
                  Colors.blue.shade600,
                ),

                const SizedBox(height: 12),

                _buildInfoRow(
                  Icons.location_on_rounded,
                  'Location',
                  '${widget.requestData['userTown']}',
                  Colors.red.shade600,
                ),

                const SizedBox(height: 16),

                // Collector Info (if assigned)
                if (hasCollector)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('collectors')
                        .doc(collectorId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final collectorData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: _buildInfoRow(
                            Icons.person_rounded,
                            'Assigned Collector',
                            '${collectorData['name']} - ${collectorData['phone']}',
                            Colors.purple.shade600,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  )
                else
                  // Show status for requests without collectors
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: _buildInfoRow(
                      Icons.schedule_rounded,
                      'Collector Status',
                      'Waiting for collector assignment',
                      Colors.orange.shade600,
                    ),
                  ),

                const SizedBox(height: 20),

                // Proof of Service Section (if available)
                if (widget.requestData['proofImageUrl'] != null &&
                    status == 'pending_confirmation') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Proof of Service Provided',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showProofImage(
                            widget.requestData['proofImageUrl'],
                          ),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.requestData['proofImageUrl'],
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, color: Colors.red),
                                          SizedBox(height: 4),
                                          Text('Failed to load'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap image to view full size. Please confirm completion to release payment.',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                _buildActionButtons(status, hasCollector, collectorId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    List<Color> gradientColors;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule_rounded;
        gradientColors = [Colors.orange.shade100, Colors.orange.shade50];
        break;
      case 'accepted':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.check_circle_outline_rounded;
        gradientColors = [Colors.blue.shade100, Colors.blue.shade50];
        break;
      case 'in_progress':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        icon = Icons.local_shipping_rounded;
        gradientColors = [Colors.purple.shade100, Colors.purple.shade50];
        break;
      case 'pending_confirmation':
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        icon = Icons.verified_user_rounded;
        gradientColors = [Colors.amber.shade100, Colors.amber.shade50];
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        gradientColors = [Colors.green.shade100, Colors.green.shade50];
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        gradientColors = [Colors.red.shade100, Colors.red.shade50];
        break;
      case 'missed':
        backgroundColor = Colors.deepOrange.shade100;
        textColor = Colors.deepOrange.shade800;
        icon = Icons.warning_rounded;
        gradientColors = [
          Colors.deepOrange.shade100,
          Colors.deepOrange.shade50,
        ];
        break;
      case 'refunded':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        icon = Icons.money_off_rounded;
        gradientColors = [Colors.purple.shade100, Colors.purple.shade50];
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline_rounded;
        gradientColors = [Colors.grey.shade100, Colors.grey.shade50];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRequestDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.green.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Request Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Request ID', widget.requestId),
                    _buildDetailRow(
                      'Name',
                      widget.requestData['userName'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Phone',
                      widget.requestData['userPhone'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Town',
                      widget.requestData['userTown'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Status',
                      widget.requestData['status'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Created At',
                      widget.requestData['createdAt'] != null
                          ? DateFormat('MMM dd, yyyy - hh:mm a').format(
                              (widget.requestData['createdAt'] as Timestamp)
                                  .toDate(),
                            )
                          : 'N/A',
                    ),
                    if (widget.requestData['updatedAt'] != null)
                      _buildDetailRow(
                        'Updated At',
                        DateFormat('MMM dd, yyyy - hh:mm a').format(
                          (widget.requestData['updatedAt'] as Timestamp)
                              .toDate(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status, bool hasCollector, String? collectorId) {
    List<Widget> buttons = [];
    
    // Primary action button (left side)
    if (status == 'pending') {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    } else if (status == 'missed') {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rescheduleRequest(),
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Reschedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),
        ),
      );
    } else if (status == 'pending_confirmation' && widget.requestData['proofImageUrl'] != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmCompletion(),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),
        ),
      );
    } else {
      // Add spacer if no primary action
      buttons.add(const Spacer());
    }
    
    // Add spacing between primary and secondary buttons
    if (buttons.isNotEmpty && buttons.first is! Spacer) {
      buttons.add(const SizedBox(width: 12));
    }
    
    // Details button (always present)
    buttons.add(
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showRequestDetails(context),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Details'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade600,
            side: BorderSide(color: Colors.blue.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
    
    // Add spacing before tertiary button
    buttons.add(const SizedBox(width: 12));
    
    // Tertiary action button (right side)
    if (status == 'missed') {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _requestRefund(),
            icon: const Icon(Icons.money_off, size: 18),
            label: const Text('Refund'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade600,
              side: BorderSide(color: Colors.orange.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    } else if (hasCollector && status != 'missed' && status != 'completed') {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'collectorId': collectorId,
                  'collectorName': widget.requestData['collectorName'] ?? 'Collector',
                  'requestId': widget.requestId,
                  'userName': widget.requestData['userName'] ?? 'User',
                },
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),
        ),
      );
    } else {
      // Add spacer if no tertiary action
      buttons.add(const Spacer());
    }
    
    return Row(
      children: buttons,
    );
  }

  Future<void> _confirmCompletion() async {
    try {
      // Show confirmation dialog
      bool? shouldConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Confirm Completion'),
            ],
          ),
          content: const Text(
            'Are you satisfied with the service provided? Confirming will release payment to the collector and mark this request as completed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not Yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, Confirm'),
            ),
          ],
        ),
      );

      if (shouldConfirm == true) {
        // Update the request status to completed
        await FirebaseFirestore.instance
            .collection('pickup_requests')
            .doc(widget.requestId)
            .update({
              'status': 'completed',
              'userConfirmedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Create notification for the collector
        try {
          final collectorId = widget.requestData['collectorId'];
          final collectorName = widget.requestData['collectorName'];

          if (collectorId != null) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': collectorId,
              'type': 'pickup_confirmed',
              'title': '✅ Pickup Confirmed',
              'message':
                  '${widget.requestData['userName']} has confirmed the pickup completion. Payment has been released.',
              'data': {
                'requestId': widget.requestId,
                'userName': widget.requestData['userName'],
                'userTown': widget.requestData['userTown'],
                'totalAmount': widget.requestData['totalAmount'],
                'status': 'completed',
              },
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Error creating confirmation notification: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Pickup confirmed successfully!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to confirm completion: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Proof of Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, size: 48, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Failed to load image'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rescheduleRequest() async {
    try {
      // Show confirmation dialog
      bool? shouldReschedule = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Reschedule Pickup'),
            ],
          ),
          content: const Text(
            'This will create a new pickup request with the same details. The current missed request will be cancelled. Do you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reschedule'),
            ),
          ],
        ),
      );

      if (shouldReschedule == true) {
        // Navigate to waste pickup form with pre-filled data
        Navigator.pushNamed(
          context,
          '/wastepickupformupdated',
          arguments: {
            'isReschedule': true,
            'originalRequestId': widget.requestId,
            'originalRequestData': widget.requestData,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestRefund() async {
    try {
      // Show confirmation dialog
      bool? shouldRefund = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.money_off, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Request Refund'),
            ],
          ),
          content: Text(
            'You will receive a full refund of GH₵${widget.requestData['totalAmount']?.toStringAsFixed(2) ?? '0.00'} for this missed pickup. The request will be cancelled. Do you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Request Refund'),
            ),
          ],
        ),
      );

      if (shouldRefund == true) {
        // Update the request status to refunded
        await FirebaseFirestore.instance
            .collection('pickup_requests')
            .doc(widget.requestId)
            .update({
              'status': 'refunded',
              'refundRequestedAt': FieldValue.serverTimestamp(),
              'refundAmount': widget.requestData['totalAmount'],
              'refundReason': 'Missed pickup - service not provided',
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Create notification for the collector about refund
        try {
          final collectorId = widget.requestData['collectorId'];
          if (collectorId != null) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'collectorId': collectorId,
              'type': 'refund_requested',
              'title': '💰 Refund Requested',
              'message':
                  '${widget.requestData['userName']} has requested a refund for the missed pickup. Amount: GH₵${widget.requestData['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
              'data': {
                'requestId': widget.requestId,
                'userName': widget.requestData['userName'],
                'userTown': widget.requestData['userTown'],
                'refundAmount': widget.requestData['totalAmount'],
                'status': 'refunded',
              },
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Error creating refund notification: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.money_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Refund requested successfully!'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting refund: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
