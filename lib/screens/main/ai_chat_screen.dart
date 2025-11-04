import 'dart:ui';
import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), // backdrop-blur-xl
            child: Container(
              color: Colors.white.withOpacity(0.40), // bg-white/40
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFF2563EB), size: 30), // text-blue-600
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nora',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF111827)), // text-gray-900
                        ),
                        Text(
                          'En línea',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF16A34A)), // text-green-600
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Color(0xFF6B7280)), // text-gray-500
                      onPressed: () { /* ... */ },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[100]!,
              Colors.green[100]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                children: [
                  // Disclaimer Bubble
                  Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100]!.withOpacity(0.80), // bg-gray-100/80
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.grey[200]!.withOpacity(0.60)), // border-gray-200/60
                    ),
                    child: const Text(
                      'Nora puede cometer errores, así que verifica sus respuestas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF4B5563), fontSize: 16), // text-gray-600
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nora's Bubble
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.40), // bg-white/40
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: Colors.white.withOpacity(0.60)), // border-white/60
                          ),
                          child: const Text(
                            'Hola Marco, ¿en qué puedo ayudarte hoy?',
                            style: TextStyle(color: Color(0xFF111827), fontSize: 16), // text-gray-900
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User's Bubble
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB), // bg-blue-600
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Text(
                        'Tengo dolor en la rodilla.',
                        style: TextStyle(color: Colors.white, fontSize: 16), // text-white
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Input Bar
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  color: Colors.white.withOpacity(0.40), // bg-white/40
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.60), // bg-white/60
                              hintText: 'Escribe tu mensaje...',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), // text-gray-400
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () { /* ... enviar mensaje ... */ },
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)], // from-blue-500 to-cyan-400
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
