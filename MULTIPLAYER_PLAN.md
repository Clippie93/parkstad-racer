# Plan: multiplayer (na v1.1)

Stand: 25-11. Fase 0 (server) is klaar; fase 1 (spookauto's) is gebouwd en wacht op de test op de iPhone.

## Jouw keuzes (25-11)

| Vraag | Keuze |
|---|---|
| Hoe samen spelen | **Online met een code**: één speler maakt een kamer en krijgt een code van 4 letters, de anderen typen die code in |
| Hoeveel spelers | **Tot 8 mensen**; lege plekken op de startgrid kunnen AI-tegenstanders worden |
| Beloning | **Prijzengeld, geen medailles**: geld zoals in de single player, medailles en ontgrendelen blijven van de single player |
| Auto's en levels | **Keuze per kamer**: de maker van de kamer (host) kiest "eigen garage" (ieder zijn eigen auto met upgrades) of "gelijke auto's", en kiest het level |

## Hoe de verbinding werkt

Het spel draait in de browser (ook op de iPhone). Daar kan een spel geen directe
verbindingen openen zoals een pc-spel, dus er is altijd een klein stukje server nodig.
Twee manieren:

**A. Via een server (relay).** Elke speler heeft een WebSocket-verbinding met een kleine
server bij Cloudflare (een Worker met één "Durable Object" per kamer). De server stuurt de
berichten door en weet welke spelers in welke kamer zitten; het spel zelf draait niet op
de server.
- Werkt overal: wifi, 4G/5G, achter elke router.
- Eenvoudig te bouwen en te testen.
- Iets meer vertraging: alles gaat via de server (Cloudflare zit dichtbij, in Amsterdam
  of Frankfurt, dus naar verwachting enkele tientallen milliseconden).
- Kosten: het gratis plan van Cloudflare heeft Durable Objects met WebSockets, met een
  daglimiet. Voor een groep vrienden is dat naar verwachting ruim genoeg; dat meet ik
  in fase 1.

**B. Peer-to-peer (WebRTC).** De spelers maken onderling een directe verbinding; de host is
het middelpunt en heeft een verbinding met elke andere speler.
- Minder vertraging tussen spelers in dezelfde regio, en bijna geen verkeer over een server.
- Er blijft een kleine server nodig om elkaar te vinden (signaling: alleen even bij het
  verbinden). Dat kan dezelfde Cloudflare-kamer zijn.
- Op 4G/5G en sommige routers lukt een directe verbinding vaak niet (de provider zet
  spelers achter een gedeeld adres). Dan is een doorgeefserver (TURN) nodig, en die kost
  meestal geld, of je valt terug op manier A.
- Bij 8 spelers moet de telefoon van de host 7 verbindingen tegelijk bijhouden.
- Meer werk om te bouwen en lastiger te testen.

**Gekozen (25-11): beginnen met A.** Het netwerkdeel van het spel maak ik zo dat de manier van
verbinden eronder te vervangen is. Werkt alles, dan kan B er later bij: eerst proberen
peer-to-peer te verbinden, en als dat niet lukt via de server (A). Zo werkt het altijd, en
is het waar mogelijk sneller.

## Wie bepaalt wat

- **Je eigen auto** rekent je eigen spel uit, zodat sturen net zo direct voelt als nu. Je
  spel stuurt ~15 keer per seconde je positie, richting, snelheid, ronde en voortgang. De
  auto's van de anderen worden vloeiend getoond (ongeveer 0,1 s achter, met voorspelling).
- **De host** bepaalt het startmoment (gezamenlijk aftellen), de AI-tegenstanders (alleen
  zijn spel rekent ze uit en stuurt hun posities door), de finishvolgorde en de uitslag.
- **Verkeer, fietsers, de stoomtrein en de AWACS** rekent ieder spel zelf uit uit dezelfde
  startwaarde en de raceklok; dat hoeft niet over het netwerk. (Het verkeer gebruikt nu geen
  toeval tijdens het rijden; dat controleer ik nog in fase 3.)
- **Botsen tussen spelers:** ieder spel duwt alleen de eigen auto weg van de anderen. Kleine
  verschillen tussen de schermen zijn dan mogelijk; dat is gebruikelijk in racegames in de
  browser.
- **Botsen met verkeer (jouw vraag, 25-11):** het verkeer staat op elk scherm op dezelfde
  plek (zelfde startwaarde en raceklok, en het verkeer reageert niet op de spelers). Het
  verschil zit in de auto van een ander: die komt ~0,1 s later binnen, en een verkeersauto
  rijdt in die tijd 1 à 1,5 m. Daarom:
  - de andere auto's worden getoond waar ze naar verwachting **nu** zijn (voorspeld uit
    snelheid en richting), niet 0,1 s in het verleden; dan staan ze meestal precies goed
    naast het verkeer, alleen op het moment van een botsing kan er een kleine sprong zijn;
  - een botsing met het verkeer wordt ook een bericht, zodat de anderen de schok en het
    geluid zien en horen, ook als de auto's op hun scherm net niet tegen elkaar staan.
  Op je eigen scherm klopt je eigen botsing altijd precies.
- **Flitspalen:** omverrijden wordt een bericht, zodat de paal bij iedereen weg is.
  Flitsen en boetes blijven per speler.
- **Politie:** zit alleen achter de speler aan die geflitst is en wordt door diens spel
  uitgerekend, maar de positie gaat mee over het netwerk (als een extra auto bij die
  speler), zodat iedereen de achtervolging ziet.

## Wat er in het spel bijkomt

- **Menu, nieuwe tab "Samen":** Kamer maken / Meedoen met code.
- **Lobby:** lijst met spelers (naam, auto), klaar-knop; de host kiest level, autoregel
  (eigen garage of gelijke auto's), AI aanvullen ja/nee en het niveau van de AI.
- **In de race:** namen boven de auto's, mini-leaderboard met namen.
- **Uitslag:** multiplayer-uitslag met prijzengeld; geen medailles.
- **Wegvallen:** een speler die wegvalt verdwijnt (of wordt AI); valt de host weg, dan
  stopt de kamer (eerst simpel, later eventueel een andere host).

## Fasen

0. ~~**Server:** Cloudflare Worker met een kamer per code.~~ **Klaar (25-11):** staat online
   op https://parkstad-racer-mp.cliffwings.workers.dev (code in `server/`, uploaden met
   `npm run deploy` in die map). Test `npm test` (11 controles) slaagt lokaal en online; de
   Godot-client `scripts/net_client.gd` werkt ermee (ping ~34 ms vanaf de Mac).
1. **Spookauto's:** twee browsers (Mac en iPhone) in hetzelfde level zien elkaar rijden.
   Nog geen lobby. Meten: vertraging, schokken en verbruik van de gratis limiet.
   **Gebouwd (25-11):** tab "Samen" (TEST) met Nieuwe kamer / Meedoen met code; in de race
   gaat je auto 15 keer per seconde de lijn over (47 bytes per bericht) en de anderen in
   hetzelfde level rijden mee als spookauto met hun naam erboven, voorspeld naar "nu";
   statusregel bovenin met de kamercode en de ping. Getest met twee Godot-vensters op de
   Mac via de echte server: berichten komen elke 67 ms (hoogstens 77 ms), zijn bij aankomst
   gemiddeld ~40 ms oud, ping 30-50 ms. Verbruik: Cloudflare telt 20 binnenkomende berichten
   als één verzoek, dus een race van 3 minuten kost ~270 verzoeken per 2 spelers en ~1.100
   bij 8 spelers. **Nog te doen:** test op de iPhone samen met de Mac (live zetten).
2. **Lobby en start:** kamer maken en meedoen met code, lobby met hostinstellingen,
   gezamenlijk aftellen, finish en uitslag.
3. **AI en wereld:** AI-tegenstanders van de host, flitspaal-berichten, prijzengeld,
   controleren dat het verkeer bij iedereen gelijk loopt.
4. **Afwerken:** wegvallen en opnieuw verbinden (ook als je op de iPhone even een andere
   app opent), modus gelijke auto's, testen met 8 (met nep-spelers).
5. **Eventueel:** peer-to-peer (WebRTC) erbij, met de server als terugval.

## Risico's

- **iPhone:** Safari pauzeert het spel als je de app wisselt; de verbinding valt dan weg.
  Opnieuw verbinden moet dus goed werken.
- **Vertraging op mobiel internet:** de spookauto's moeten vloeiend blijven, ook bij
  haperend 4G.
- **Botsen tussen spelers** voelt anders dan tegen de AI; dat stellen we af na fase 1.

## Wat ik van jou nodig heb

- Toegang tot je Cloudflare-account om de server te uploaden (fase 0).
- Een tweede apparaat of een vriend om mee te testen (fase 1 en verder).
