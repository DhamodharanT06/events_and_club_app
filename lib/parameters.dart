import 'package:flutter/material.dart';

// COLORS
Color maincol = Colors.white70;
Color seccol = Colors.blue;
Color accentcol = const Color(0xFF4B4B4B);
Color textcol = Colors.black;

// AI CONFIGURATION - OpenRouter (Provides Gemini via REST API)
const String openRouterApiKey = 'your_openrouter_api_key_here';
const String geminiModel = 'google/gemini-2.0-flash-exp:free';
const String geminiApiUrl = 'https://openrouter.ai/api/v1/chat/completions';

// ADMIN CONFIGURATION
const String adminEmail = 'admin@example.com';
const String adminPassword = 'Admin@12345';

// Check if user is admin
bool isAdminUser(String email) {
  return email == adminEmail;
}

// Verify admin credentials
bool verifyAdminCredentials(String email, String password) {
  return email == adminEmail && password == adminPassword;
}

// AI Response Settings
const int aiResponseTimeoutSeconds = 30;
const bool enableLocalAIFallback = true; // Always enabled - works WITHOUT internet

// AI System Prompt Configuration
const String aiSystemPromptBase = '''You are an intelligent Event Lister AI Assistant. 
Your role is to help users find events, discover clubs, and get personalized recommendations.

When users ask about events or clubs, provide helpful suggestions based on:
1. Event names and descriptions
2. Club information and member count
3. Current availability and registration status
4. User interests and preferences

Always be friendly, concise, and helpful. Provide specific event/club recommendations when possible.
If a user asks about an event or club not in your knowledge, suggest similar alternatives.''';

// TIMEOUT CONFIGURATIONS
const Duration apiTimeoutDuration = Duration(seconds: 30);
const Duration chatMessageTimeoutDuration = Duration(seconds: 15);
const Duration aiResponseTimeoutDuration = Duration(seconds: 30);

// PAGINATION & LIMITS
const int defaultPageSize = 10;
const int maxEventsPerPage = 20;
const int maxClubsPerPage = 15;
const int maxMessagesPerPage = 50;
const int maxRecommendationsCount = 10;

// FEATURE FLAGS
const bool enableAIAssistant = true;
const bool enableEventRecommendations = true;
const bool enableClubChat = true;
const bool enableUserProfiles = true;
const bool enableActivityTracking = true;

// CACHE CONFIGURATIONS
const Duration eventsCacheDuration = Duration(minutes: 5);
const Duration clubsCacheDuration = Duration(minutes: 5);
const Duration userCacheDuration = Duration(minutes: 10);
const Duration chatMessagesCacheDuration = Duration(minutes: 2);
