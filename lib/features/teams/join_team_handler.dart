import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/colors.dart';

class JoinTeamHandler extends StatefulWidget {
  final String teamId;

  const JoinTeamHandler({super.key, required this.teamId});

  @override
  State<JoinTeamHandler> createState() => _JoinTeamHandlerState();
}

class _JoinTeamHandlerState extends State<JoinTeamHandler> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinTeam();
    });
  }

  Future<void> _joinTeam() async {
    try {
      if (widget.teamId.isEmpty) {
        throw Exception('Invalid team link');
      }

      // Call InsForge Edge Function (assuming URL and dummy profile_id for now
      // in a real app this uses the auth token)
      final url = Uri.parse('https://ip53vj9s.ap-southeast.insforge.app/functions/v1/joinTeam');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Replace with real anon key / auth header in prod
          'Authorization': 'Bearer YOUR_ANON_OR_AUTH_TOKEN', 
        },
        body: jsonEncode({
          'team_id': widget.teamId,
          // Offline mode or temp local profile id simulation
          'profile_id': 'local_user_123' 
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Successfully joined team!'),
                backgroundColor: AppColors.primary,
              ),
            );
            context.go('/teams');
          }
        } else {
          throw Exception(result['message'] ?? 'Failed to join team');
        }
      } else {
        final errResult = jsonDecode(response.body);
        throw Exception(errResult['error'] ?? 'API error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/home'); // Fallback on error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Joining team...',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
