import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_feedback.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDBC3C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.indicatorAndIcon,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          onPressed: () async {
            await HapticFeedbackUtil.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Om Fylgja',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryText,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Et fylgje',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ', på norrønt fylgja («den som følger»), er en ånd eller vette, enten usynlig eller i form av et dyr, som ifølge nordisk folketro følger ætten eller enkeltmennesket. Passende navn :D',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fylgja, navnet hviskes på vind,\n'
                    'En norrøn ånd, din digitale venn.\n'
                    'På fjellet høyt, der signalet svikter,\n'
                    'Dens kraft deg guidet, aldri forvikter.\n\n'
                    'Værvarsler suser hvis storm er i vente,\n'
                    'Sikkerhet trygg, fra skredfaren fremtredende.\n'
                    'Stier og topper den åpner for deg,\n'
                    'Fjellvett og kunnskap, din verdi så høy.\n\n'
                    'Fylgja, følgesvennen i lommen din tett,\n'
                    'Holder deg trygg og orientert.\n'
                    'Med norrøn visdom og teknologi smart,\n'
                    'Gir deg fordelen før turen din tar fart.\n\n'
                    'Så la appen veilede, mens fjellene kaller,\n'
                    'Eventyret venter, der friheten smaker.\n'
                    'Med Fylgjas ånd, aldri redd eller alene,\n'
                    'Stien er din, fjellets stemme den rene.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
                    
                    const Spacer(),
                    
                    // Footer
                    const Column(
                      children: [
                        SizedBox(height: 32),
                        Text(
                          'a flokroll project',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
