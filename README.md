# Parkstad Racer 0.9 — levels per gemeente

Godot 4.2+ project (GL Compatibility).

## Nieuw in 0.9: levels
Het spel start nu in een menu met één level per Parkstad-gemeente en de Parkstad Finale (Buitenring) als laatste. Een level speel je vrij door het vorige te halen.
- **Racen à la A2 Racer**: aftellen, de klok loopt af en elk checkpoint geeft extra tijd. Er rijdt verkeer in beide richtingen, en een botsing kost je snelheid. R zet je terug op het laatste checkpoint, Esc pauzeert.
- **Finish**: racetijd, medaille (goud/zilver/brons) en je record, opgeslagen in `user://parkstad_progress.cfg`. Tijdslimiet en medailletijden worden berekend uit de lengte van de route.
- **Level 1, Heerlen** (`scripts/levels/level_heerlen.gd`): van Heerlen-Noord langs Mijnmuseum ON I het centrum in, finish op het Pancratiusplein tussen kerk en Glaspaleis. Het stratenplan is verzonnen en compact.
- **Level 2, Kerkrade** (`scripts/levels/level_kerkrade.gd`): start op de Nieuwstraat/Neustraße, waar de grens midden over de straat loopt (middenberm met grenspalen, Nederlandse en Duitse straatnaamborden). Daarna langs de poort van Abdij Rolduc en westwaarts naar de finish bij het Parkstad Limburg Stadion.
- **Abdij Rolduc** (`scripts/landmarks/landmark_rolduc.gd`), naar foto's op Wikimedia Commons:
  - romaanse westtoren met lisenen, rondboogfriezen en een barokke leien spits met lantaarn;
  - westbouw, schip en achtkante vieringtoren;
  - vleugels van rode baksteen met witte schuiframen, schilddaken en dakkapellen;
  - poortmuur met drie bogen en een Mariabeeld, koepeltorentjes;
  - voorhof met grasveld, beeldzuil, kroon en vlaggen.

  Het complex is ingekort. Textuur `rolduc_wing.png`.
- **Level 3, Landgraaf** (`scripts/levels/level_landgraaf.gd`): van Schaesberg langs Megaland met een Pinkpop-festivalopstelling (`landmark_pinkpop.gd`: truss-podium, PINKPOP-banner, schermen, PA, mixtoren, hekken), richting de Wilhelminaberg. Finish voor de ingang van SnowWorld (`landmark_snowworld.gd`, naar foto's op Wikimedia Commons): beboste berg, witte skihal die tegen de flank op loopt met gebogen daken en een opgebolde kop, wit voorgebouw met de chaletgevels van de ingang.
- **Level 4, Brunssum** (`scripts/levels/level_brunssum.gd`):
  - start op de Brunssummerheide: dicht bos van loofbomen en sparren met open heidevelden (heide, stuifzand, lage duinen);
  - bij het plaatsnaambord Brunssum/Broensem de bebouwde kom in, langs het schachtwiel (`landmark_mijnwiel.gd`, herdenkingsmonument);
  - finish voor de Heilige Gregoriuskerk van Gottfried Böhm (`landmark_gregoriuskerk.gd`, naar foto's op Wikimedia Commons): losse betonnen klokkentoren met raster van ronde gaten en groene klok, bakstenen kerkzaal met afgeronde hoeken en ronde vensters, witte tentvormige doopkapel, vijver met beeldengroep.
- **Level 5, Simpelveld** (`scripts/levels/level_simpelveld.gd`):
  - over het heuvelland (akkers, heggen, bomen) naast de Miljoenenlijn, in een race tegen de stoomtrein (`steam_train.gd`: locomotief met tender, drie groene rijtuigen, rook), die elke ronde opnieuw vertrekt;
  - bij het bord Simpelveld/Zumpelveld het dorp in, langs Huize Loreto (`landmark_loreto.gd`: kloostergebouw met puntgevels, neogotische kapel met dakruiter, muur met pijlers);
  - finish bij station Simpelveld (`landmark_station_simpelveld.gd`), waar de trein afremt en stopt.
- **Level 6, Voerendaal** (`scripts/levels/level_voerendaal.gd`):
  - over het heuvelland langs de schuren, muur en herenhuis van Kasteel Puth (`landmark_puth.gd`);
  - bij het bord Voerendaal/Voelender het dorp in;
  - finish bij Kasteel Cortenbach (`landmark_cortenbach.gd`): herenhuis met mansardedak in de gracht, voorburcht met poortgebouw met uivormige spits, ronde hoektoren, brug.
- **Level 7, Beekdaelen** (`scripts/levels/level_beekdaelen.gd`):
  - start in de Schinveldse bossen, waar een AWACS-vliegtuig (`awacs.gd`) vlak na de start van voren laag over de weg komt;
  - langs een wegkruis met knotbomen het heuvelland in, bij het bord Beekdaelen/Baekdale het dorp in;
  - finish bij Kasteel Terborgh in Schinnen (`landmark_terborgh.gd`): kasteelhuis met hoge puntgevel, poortvleugel met rondboog en brug, vleugels rond een binnenplaats, gracht.
- Bossen (`forest()`) en de bomen in het heuvelland worden met MultiMesh getekend voor de framerate. Bossen en wegkruisen (`wayside_cross()`) staan in `level_base.gd`.
- Akkers, heggen, bomen en heuvels zijn een herbruikbare functie `countryside()` in `level_base.gd`. Daken met schilden of mansardes maak je met `Kit.frustum()`.
- **Finale: de Buitenring** (`scripts/levels/level_finale.gd`), **3 ronden** op een gesloten ring van zo'n 2,5 km:
  - een gescheiden weg (2x2) met middenberm en vangrail, viaducten en blauwe portaalborden;
  - druk verkeer in twee stroken per richting, de linkerstrook rijdt sneller;
  - langs de ring bezienswaardigheden uit alle gemeenten:
    - het Parkstad Limburg Stadion bij start/finish;
    - Mijnmuseum ON I, Abdij Rolduc en het Pinkpop-terrein;
    - de Gregoriuskerk, station Simpelveld met de stoomtrein, Kasteel Terborgh en Kasteel Cortenbach;
    - binnen de ring SnowWorld op de Wilhelminaberg;
    - daarnaast de Schinveldse bossen met AWACS, de Brunssummerheide en de stadsranden aan de horizon;
  - per ronde zes checkpoints (de gemeenten) plus de start/finish; aan het begin van ronde 2 en 3 krijg je extra tijd. Na de laatste ronde: PARKSTAD KAMPIOEN!

  Het tracé is verzonnen.
- **Ronden in alle levels**:
  - elk level is nu een rondje met start/finish op het startrechte stuk (`Route.new(..., true)`, `finish_line(n)`);
  - de oude finish-landmarks zijn checkpoints die je elke ronde passeert;
  - Heerlen en Kerkrade hebben lange ronden en krijgen 2 ronden, de rest en de finale 3;
  - een race is daardoor 6,5 tot 11 km, goud ligt rond de 4 minuten;
  - de HUD toont de ronde, aan het begin van elke nieuwe ronde krijg je extra tijd, en de medailletijden tellen alle ronden mee.
- **Geld en garage** (`cars_catalog.gd`, `garage.gd`, profiel in `game.gd`):
  - **verdienen:** prijzengeld per plaats (1e 100%, 2e 60%, 3e 40%, ... van € 1.000 in Heerlen, oplopend tot € 3.800 in de finale) en € 250 per omvergereden flitspaal;
  - **boete:** bij geflitst worden € 50 + € 3 per km/u te hard (in Heerlen de helft, oplopend tot volledig in de finale); door rood levert juist € 50 op, fietser aangereden € 50 en 3 s. Na een flitser komt (op Normaal en Moeilijk) de politie achter je aan: laat je je vastzetten of tik je hem 3 keer, dan word je aangehouden (€ 300 en 6 s); ontsnappen levert € 100 op (scripts/police.gd). Je verliest in een race nooit meer dan je die race verdient. Alles wordt aan het eind van de race verrekend en staat op het eindscherm.
  - **garage** (vanuit het menu en het eindscherm): 5 auto's, van de gratis John Hatchback tot de Parkstad Special van € 30.000, elk met eigen topsnelheid, acceleratie, grip en remmen. 4 upgrades (motor, turbo, banden, remmen) in 3 niveaus, en een lakkleur naar keuze. Met een draaiend 3D-voorbeeld.
  - **tegenstanders** worden per level 2,5% sterker (in de finale 17,5%), zodat je voor de latere levels een betere auto of upgrades nodig hebt. De ideale rit en de tijdslimiet rekenen met de auto van de tegenstanders, niet met de jouwe.
  - geld, auto's en upgrades staan in een spelersprofiel, klaar voor online spelen.
- **Auto's** (`car_look.gd`): de carrosserie is een geëxtrudeerd zijprofiel in plaats van losse blokken.
  - drie modellen: rallyhatchback (ronde koplampen), lage coupé met achterspoiler, sedan;
  - elke auto heeft lak, twee racestrepen over motorkap/dak/achterkant en een startnummer op deuren en dak;
  - verder velgen met spaken, bumpers, grille, spiegels en uitlaat; de koplampen en achterlichten lichten op.
  - Jij rijdt de rode hatchback #1, de tegenstanders hebben elk een eigen model, kleur en nummer (#2 t/m #8).
- **Nederlandse verkeerselementen** (`scripts/levels/dutch_streets.gd`, `cyclist.gd`, `speed_camera.gd`), automatisch in elk level:
  - wegprofiel: band, rood fietspad en trottoir aan beide kanten;
  - fietsers rijden mee (rechts) en tegemoet (links), ze trappen en zijn niet hard;
  - in de bebouwde kom: zebrapaden met blauwe zebraborden en Amsterdammertjes, bushaltes met abri (lange open kant naar de stoep), H-bord en BUS op de weg, bloembakken en ondergrondse containers;
  - snelheidsborden (50 in de kom, 80 erbuiten, 100 op de Buitenring), voorrangswegborden (oranje ruit), twee blauwe ANWB-wegwijzers per level;
  - flitspalen op de band: rij je meer dan 10 km/u te hard, dan flitst hij en zie je "GEFLITST!" (nog zonder boete). Rij je hem omver, dan valt hij om en krijg je 5 s extra (zoals in A2 Racer).
  - op de Buitenring: reflectorpalen en hectometerpaaltjes.
- **7 tegenstanders** (`rival_driver.gd`):
  - Sjef, Mia, Jo, Truus, Bert, Ilse en Kevin, elk met een eigen kleur en niveau (89-98,5% van de ideale snelheid);
  - ze rijden met dezelfde fysica als jij, remmen voor bochten, sluiten aan achter langzamere auto's en halen in via de andere strook. Op een gewone weg alleen als er geen tegenligger aankomt, en niet over een middenberm (`no_overtake`, bv. de Nieuwstraat);
  - start in 4 rijen van 2; jij staat op de 7e plek. Rechtsboven zie je je positie (bv. 3 / 8).
  - **Uitslag:** na de finish rijden de anderen door en vult de tabel zich live: de winnaar met zijn tijd, de rest met hun achterstand (+3.214). Wie nog rijdt, krijgt een geschatte achterstand (~+12.5) tot hij binnen is. Een vastgelopen computercoureur wordt na 4 s teruggezet op de weg.
  - **Medailles op plaats:** 1e goud, 2e zilver, 3e brons. Het volgende level speel je vrij met een top-3-plaats.
  - Met tegenstanders rijdt de helft van het normale verkeer. Een tik tegen een andere racer kost weinig snelheid (5%), verkeer meer (18%), een muur het meest (28%).
- **Rijgedrag** (`car.gd`, alle getallen bovenin als `@export`):
  - **grip:** 15 m/s². Te snel een bocht in en de achterkant breekt uit: de neus draait verder dan de banden kunnen volgen, met een driftwinkel van zo'n 12-15° op de grens.
  - **terugstellen:** de achterbanden trekken de auto daarna terug in de rijrichting, en met tegensturen vang je hem op.
  - **handrem:** remt licht en maakt de achterkant los; drift tot ongeveer 60°.
  - **sturen:** gaat geleidelijk naar volle uitslag (toetsenbord), en glijden kost snelheid.
  - **optrekken:** 0-100 km/u in ongeveer 2,5 s, naar topsnelheid ongeveer 5 s.
  - **naast de weg** (gras, heide, plein; meer dan 3 m buiten het asfalt): halve topsnelheid en 55% grip. 2 s gras kost zo'n 1,5 s.
- **Medailles en tijdslimiet** (`race.gd`): berekend uit een ideale rit per level, uit de bochten en de grip, het optrekken en het remmen van de auto. De tijd per checkpoint is de ideale tijd + 70% (ruimte voor inhalen). Medailles gaan sinds de tegenstanders op plaats.
- **Camera**: de volgcamera stond scheef als een level niet richting -Z begon; ze wordt nu ten opzichte van de auto gericht.
- Alle levels zijn gebouwd. Wat nog beter kan aan de gebouwen staat in `VERBETERLIJST.md`.
- Plaatsnaamborden zijn blauw met witte letters, met de Limburgse naam op een kleiner bord eronder (Heële, Kirchroa, Lankgraaf). De namen komen van de Limburgstalige Wikipedia.
- **Moeilijkheid** (Instellingen): Makkelijk, Normaal of Moeilijk; verandert het niveau en de auto's van de tegenstanders en de tijdslimiet per stuk (`DIFF_*` in `race.gd`). Tegenstanders groeien deels mee met jouw auto en upgrades (`DIFF_CATCHUP`).
- **Testmodus** (verborgen): druk in het menu vijf keer snel op T, of tik op telefoon of tablet vijf keer snel op de titel PARKSTAD RACER. Alle levels zijn dan speelbaar zonder eerst de vorige te halen, alle auto's en upgrades in de garage zijn gratis (met een knop om upgrades terug te zetten), en rechtsboven staat TESTMODUS. Nog eens vijf keer T (of tikken) zet hem uit; de stand wordt onthouden.
- **Automatische tests** moeten `PARKSTAD_SAVE=<pad>` gebruiken, zodat ze in een eigen bestand schrijven en nooit aan de echte records (`user://parkstad_progress.cfg`) komen.

| Bestand | Rol |
|---|---|
| `scripts/game.gd` | Autoload `Game`: levellijst, voortgang, scènewissels |
| `scripts/menu.gd`, `scenes/menu.tscn` | Hoofdmenu (startscène) |
| `scripts/race.gd`, `scenes/race.tscn` | Racescène: klok, checkpoints, verkeer, HUD, finish- en pauzescherm |
| `scripts/route.gd` | Route uit hoekpunten met afgeronde bochten; alles leest posities af via de afstand langs de route |
| `scripts/levels/level_base.gd` | Basis voor een level: weg als één mesh (asfalt, stoepen, belijning), straatbebouwing, plaatsnaambord |
| `scripts/traffic_car.gd` | Verkeersauto's en busjes |
| `scripts/places/pancratiusplein.gd` | Het plein met kerk en Glaspaleis, gebruikt door het Heerlen-level |
| `scripts/places/pls_site.gd` | Stadion met parkeerterrein en rotonde, gedeeld door het Kerkrade-level en de finale |

**Een nieuw level maken**: kopieer `level_heerlen.gd` en zet in `build()` de route (hoekpunten en bochtstralen), de checkpoints en de gebouwen. Zet daarna het pad naar het script bij de gemeente in `Game.LEVELS`.

## Nieuw in 0.8: het stadion naar foto's
Het Parkstad Limburg Stadion is opnieuw gebouwd op basis van drie foto's (voorgevel, luchtfoto, binnenkant):
- langgerekt kantoorblok van beige baksteen met donkere banden, hoger middendeel met glazen tongewelf, embleem en losse letters PARKSTAD / LIMBURG op het dak, STADION-bord boven de glazen entree
- rijen witte tongewelven boven alle vier de tribunes, witte tentkappen op de hoeken, schuin naar buiten leunende lichtmasten
- geel/zwarte stoelblokken, kantoorvleugel om de westhoek, rotonde met grasveld voor de entree (solide: erom heen rijden)
- gevel is één herhalende textuur (`assets/pls_office.png`) in plaats van honderden losse vensters: licht voor de framerate
- 0.8.1: lichtmasten gecorrigeerd: wit driehoeksspant dat naar binnen over het veld leunt, met een lampenpaneel (7 x 3 lampen) dat omlaag op het veld gericht is
- 0.8.2: naar luchtfoto's, Street View-rondje en de kaart. Gesloten kom, rechtsom vanaf de rotonde: hoofdgevel, hoek 7, Fair Play/Basic-Fit (getrapt 4-5-6 lagen, beige/donker gestreept), hoek 5/6, Fletcher-hotelzijde (lamellen, donkerbruin entreedeel met atrium, glazen dakopbouw), hoek 3/4, Albert Heijn (drie donkere tongewelven, glazen trappenhuizen), hoek 2 met grijze Music Dome-hal. De hoeken zijn de open betonnen tribunehoek (gebogen kolommen, grijze gevelband, ingangsnummer); de witte vakwerkmast staat op die betonhoek, steekt door de top van de tent en leunt ver naar binnen. Witte driehoeksspanten steken boven de daken uit. Nieuwe texturen `pls_hotel.png`, `pls_louvre.png`, `pls_market.png`
Afmetingen zijn uit de foto's geschat, niet opgemeten.

## Eerder in 0.7
De ~900 regels gelaagde gebouwcode uit `world.gd` (`_enhance_`, `_refine_`, `_add_version_0x_`) zijn weg.
Elk gebouw staat nu in een eigen, leesbaar script en is los aan te passen:

| Bestand | Gebouw |
|---|---|
| `scripts/landmarks/landmark_pancratiuskerk.gd` | Sint-Pancratiuskerk, Heerlen (0.8.2, naar Street View): mergeltoren in vier versprongen geledingen met waterlijsten, breuksteen onder en hardsteen boven, galmgaten in paren, leien naaldspits met uurwerken; ronde traptoren; rode deur in de torenzijgevel; driebeukig schip met lessenaarsdaken, consoles, rondboogfries en dakkapellen; vieringtoren met piramidedak; dwarspand met drie hoge vensters en zuilenportaal; koor met apsis; beeld van P.J. Savelberg. Texturen `kerk_rubble.png`, `kerk_ashlar.png` |
| `scripts/landmarks/landmark_glaspaleis.gd` | SCHUNCK Glaspaleis (0.8.2, naar Street View): doorzichtig glasvlies met dunne stijlen voor uitkragende vloeren, paddenstoelkolommen, gordijnen en plafondlampen; terugliggende begane grond onder doorlopende luifel met rode SCHUNCK-letters; glazen dakverdieping met stalen kooi, rond trappenhuis en vlaggen. Links de geschubde kubus die uitkraagt over een glazen terrasverdieping en grijze stenen plint, wit trappenhuisblok, beige achterbouw met hoog SCHUNCK-venster en palmen, bronzen beeld en het bakstenen torentje met tentdak. Texturen `glas_tiles.png`, `glas_stone.png`. Staat nu op x -118 (kubus links, vrij van de doorrit) |
| `scripts/landmarks/landmark_on.gd` | Mijnmonument ON-I (0.8.2, naar foto's): vierkant bakstenen schachtgebouw met witte banden, rondboogvensters, boogfries en kantelen; groengrijze schachtbok die uit het dak steekt met bordessen, kop met twee schijven, schuine schoorbok en oranje ON-letters bovenop; machinehal, betonnen museumgebouw, stoomlocomotief met kolenwagens |
| `scripts/landmarks/landmark_pls.gd` | Parkstad Limburg Stadion (zie 0.8 hierboven) |
| `scripts/build_kit.gd` | Gedeelde bouwset (blokken, cilinders, daken, boogramen, tribune-wig, labels) |

De oude vrije-ritkaart (`world.gd`, `scenes/main.tscn`) is in 0.9 verwijderd; alle gebouwen staan nu in de levels.

## Bijkomende wijzigingen
- Belichting verlaagd (zon 0.75, omgeving 0.5, tonemap-exposure 0.55): de oude instellingen overbelichtten alle gevels tot wit.
- Straatborden kleiner.

## Hoe betrouwbaar zijn de gebouwen?
Gebaseerd op het rijksmonumentenregister en openbare bronnen, niet op opmetingen:
- **Glaspaleis**: uitkragende vloeren met paddenstoelkolommen (monumentenregister); gevels, kubus en achterbouw naar Street View-foto's. Afmetingen zijn geschat.
- **Pancratiuskerk**: driebeukig romaans schip, 14e-eeuwse toren, koor en dwarspand uit 1901-1903 (monumentenregister); vorm en details naar Street View-foto's, maten geschat.
- **ON-I**: opgebouwd naar foto's van schachtgebouw, schachtbok en machinehal; maten geschat.
- **PLS**: opgebouwd naar foto's (zie hierboven); maten geschat.

Het geel/zwarte embleem op het stadion is een eigen ontwerp en niet het officiële Roda JC-logo.

## Starten
Pak de zip uit, importeer `project.godot` in Godot 4.2+ en druk F5. Test: headless gestart en gerenderd in Godot 4.3, zonder scriptfouten. De auto zelf is niet gedreven in de editor.

## Geluid en bronvermelding

- Motorgeluid: "rally car idle loop" (Pixabay, gebruiker freesound_community, bestand rally-car-idle-loop-17-84405). Pixabay-licentie: gratis, ook commercieel, naamsvermelding niet verplicht; los doorverkopen/verspreiden van het geluidsbestand zelf mag niet. `assets/engine_loop.wav` is die opname (mono, 44,1 kHz) met een naadloze overvloeiing.
- Alle andere effecten (`scripts/sfx.gd`) en de menumuziek (`assets/menu_music.wav`) zijn zelf in code gemaakt.

## Profielen en opslag

- Tabblad **Profiel**: 3 opslagplekken, elk met eigen geld, auto's, upgrades, lak, records, medailles en testmodus. Kiezen, nieuw maken, hernoemen en wissen (met bevestiging). Geluidsinstellingen gelden voor alle profielen.
- Alles staat in één bestand (`user://parkstad_progress.cfg`), per profiel in secties `p1_…`, `p2_…`, `p3_…`. Een oude save zonder profielen wordt bij de eerste start automatisch profiel 1.
- In de browser (webexport) bewaart Godot `user://` in de IndexedDB van de website: de voortgang blijft bewaard per browser en apparaat, en verdwijnt alleen als de speler de sitegegevens wist (of in een privévenster speelt).

## Web, telefoon en app (PWA)
- Het beeld schaalt mee met de schermbreedte (`window/stretch/aspect="expand"`): geen zwarte
  balken op brede telefoons. Menu's blijven 1280x720 in het midden, de aanraakknoppen schuiven
  mee naar de randen (`scripts/screen_fit.gd`).
- De webversie is een PWA: op iPhone via Delen > Zet op beginscherm, op Android via
  "App installeren". Hij opent dan schermvullend zonder adresbalk en werkt na het eerste
  bezoek ook offline. Een nieuwe versie neemt bij het openen vanzelf over (één keer herladen).
- `tools/publish_web.sh` past de service worker aan zodat hij `index.wasm.gz` bewaart.

## Menu en spelmodi
- Het Racen-tabblad toont een plaatsnaambord per gemeente (groot genoeg voor een telefoon).
  Een tik op een bord vraagt: **Racen** (tegen 7 tegenstanders, checkpoints, klok,
  prijzengeld) of **Vrij rijden**.
- Vrij rijden: zelfde stad en verkeer (dubbel zoveel, want geen tegenstanders), geen
  checkpointpoorten, klok of geld. De HUD toont de volgende bezienswaardigheid; R zet je
  terug bij de laatst gepasseerde. Flitsers, fietsers en rood licht geven alleen een melding.
- Steden die nog dicht zijn, zijn in beide modi dicht.
