import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/routing.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

/// Page for creating a new chat room with form validation
class CreateChatRoomPage extends StatefulWidget {
  const CreateChatRoomPage({super.key});

  @override
  State<CreateChatRoomPage> createState() => _CreateChatRoomPageState();
}

class _CreateChatRoomPageState extends State<CreateChatRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Chat Room'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createRoom,
            child: const Text(
              'Create',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
          ),
        ],
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoading && state.operation == 'Creating chat room') {
            setState(() {
              _isLoading = true;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }

          if (state is ChatRoomCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat room created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            NavigationService.goBack();
          } else if (state is ChatError &&
              state.operation == 'create_chat_room') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildCreateButton(),
            const SizedBox(height: 16),
            _buildGuidelines(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Room Name *',
        hintText: 'Enter a name for your chat room',
        prefixIcon: Icon(Icons.chat_bubble_outline),
      ),
      textInputAction: TextInputAction.next,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Room name is required';
        }
        if (value.trim().length < 2) {
          return 'Room name must be at least 2 characters';
        }
        if (value.trim().length > 100) {
          return 'Room name cannot exceed 100 characters';
        }
        if (value.contains('<') ||
            value.contains('>') ||
            value.contains('"') ||
            value.contains("'")) {
          return 'Room name contains invalid characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Describe what this room is about',
        prefixIcon: Icon(Icons.description_outlined),
        alignLabelWithHint: true,
      ),
      textInputAction: TextInputAction.done,
      maxLines: 3,
      maxLength: 500,
      validator: (value) {
        if (value != null && value.trim().length > 500) {
          return 'Description cannot exceed 500 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _createRoom,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isLoading ? 'Creating...' : 'Create Room'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildGuidelines(BuildContext context) {
    return Card(
      color: AppColors.primaryLight.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Room Guidelines',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuidelineItem('Room names must be 2-100 characters long'),
            _buildGuidelineItem(
                'Descriptions are optional but help others understand the room purpose'),
            _buildGuidelineItem(
                'You will automatically become the room creator and first participant'),
            _buildGuidelineItem(
                'Other users can join your room once it\'s created'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createRoom() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    context.read<ChatBloc>().add(
          CreateChatRoom(
            name: name,
            description: description,
          ),
        );
  }
}
