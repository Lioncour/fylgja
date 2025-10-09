import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/main_viewmodel.dart';
import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.buttonAndAbout,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.indicatorAndIcon,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Main content
              const Text(
                'Et fylgje, på norrønt fylgja («den som følger»), er en ånd eller vette, enten usynlig eller i form av et dyr, som ifølge nordisk folketro følger ætten eller enkeltmennesket. Passende navn :D',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryText,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Fylgja er din digitale følgesvenn i fjell og dal. Som en moderne versjon av de gamle åndene som fulgte våre forfedre, er Fylgja her for å vokte over deg på dine eventyr i naturen.\n\n'
                'Med en blanding av norrøn visdom og smart teknologi, gir Fylgja deg varsler om værforhold, sikkerhet og kunnskap som holder deg trygg på fjellet. Appen overvåker nettverksdekning i bakgrunnen, slik at du alltid vet når du har tilgang til hjelp og informasjon.\n\n'
                'La Fylgja være din guide gjennom storm og stille, gjennom tåke og klar himmel. Som de gamle åndene som fulgte våre forfedre, er Fylgja her for å gi deg trygghet og trygghet på dine reiser i det store utendørs.\n\n'
                'Velkommen til en ny æra av fjellfører, hvor teknologi møter tradisjon, og hvor du aldri er alene i naturen.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryText,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Pause duration setting
              Consumer<MainViewModel>(
                builder: (context, viewModel, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lengde på varselpause (minutter):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: viewModel.pauseDuration.toDouble(),
                        min: 1,
                        max: 15,
                        divisions: 14,
                        activeColor: AppTheme.indicatorAndIcon,
                        inactiveColor: AppTheme.notificationPanel,
                        onChanged: (value) {
                          viewModel.setPauseDuration(value.round());
                        },
                      ),
                      Center(
                        child: Text(
                          '${viewModel.pauseDuration} minutter',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
