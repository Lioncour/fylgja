import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFFDBC3C5),
      ),
      body: Container(
        color: Color(0xFFDBC3C5),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Fylgja, på norrønt Fylgja («den som følger»), er en ånd eller vette, enten usynlig eller i form av et dyr, som ifølge nordisk folketro følger ætten eller enkeltmennesket. Passende navn :D\n\nFylgja, navnet hviskes på vind, En norrøn ånd, din digitale venn. På fjellet høyt, der signalet svikter, Dens kraft deg guidet, aldri forvikter.\n\nVærvarsler suser hvis storm er i vente, Sikkerhet trygg, fra skredfaren fremtredende. Stier og topper den åpner for deg, Fjellvett og kunnskap, din verdi så høy.\n\nFylgja, følgesvennen i lommen din tett, Holder deg trygg og orientert. Med norrøn visdom og teknologi smart, Gir deg fordelen før turen din tar fart.\n\nSå la appen veilede, mens fjellene kaller, Eventyret venter, der friheten smaker. Med Fylgjas ånd, aldri redd eller alene, Stien er din, fjellets stemme den rene.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}
