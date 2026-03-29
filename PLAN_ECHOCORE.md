# PLAN ROZWOJU GRY „ECHOCORE” (Godot)

## 1. Wizja projektu (krótko)

**Hasło projektu:** prosta forma + mocny klimat + czytelny cel.

Gracz jako operator kolonii terraformującej ląduje na planecie, która wydaje się martwa, ale reaguje jak uśpiony organizm. Pętla gry łączy **rozbudowę fabryki** i **obronę przed reakcjami planety**.

## 2. Filar rozgrywki (core loop)

1. Zbieraj zasoby i stawiaj moduły produkcyjne.
2. Generuj 3 wskaźniki terraformacji: **Tlen, Ciepło, Energia Bio**.
3. Odblokowuj nowe heksy/biomy i struktury.
4. Odpieraj „wyrzuty” planety (fale reakcji obronnej).
5. Skaluj sieć produkcji i decyduj o kierunku końcowym.

## 3. Minimalny zakres MVP (grywalna wersja 1)

### Systemy obowiązkowe
- Mapa heksowa (1 biom startowy + 1 biom odblokowywany).
- Podstawowe budynki:
  - Ekstraktor surowca,
  - Generator energii,
  - Przetwornik terraformacji,
  - Wieżyczka obronna.
- 3 surowce/progresory:
  - Minerały,
  - Energia,
  - Biomasa/Impuls planety.
- Prosty model fal zagrożenia (co X minut / progów terraformacji).
- HUD z jasnym celem i postępem terraformacji.
- Ekran wyniku stanu planety (stabilizacja albo eskalacja reakcji).

### Czego NIE robimy w MVP
- Rozbudowane drzewko technologii,
- Kilku frakcji,
- Craftingu wieloetapowego,
- Rozbudowanej fabuły tekstowej,
- Multiplayera.

## 4. Fundament fabularny (lekki, wspierający gameplay)

- Start: „Planeta klasy K-41. Terraformacja automatyczna aktywna.”
- Po pierwszym progu rozwoju: „Wykryto odpowiedź podpowierzchniową.”
- Po kolejnych progach: planeta „uczy się” wzorca kolonii i odpowiada silniej.
- Finał: wybór strategii:
  1. **Uspokojenie** (harmonizacja, wolniejsza terraformacja, mniej fal),
  2. **Dominacja** (maksymalna wydajność, silne fale obronne),
  3. **Symbioza** (zbalansowany wariant z unikalnym bonusem).

Wszystko podawane krótkimi komunikatami systemowymi (1–2 zdania).

## 5. Plan produkcyjny (iteracje)

## Iteracja 0 — techniczny fundament (1 tydzień)
- Uporządkowanie scen: `Main`, `World`, `UI`, `Simulation`.
- Dane budynków jako zasoby/konfiguracje (łatwe balansowanie).
- Tick symulacji i eventy (produkcja, zużycie, fale).
- Narzędzia debug: przyspieszenie czasu, podgląd ekonomii.

**Kryterium wyjścia:** można stawiać budynki, czas płynie, zasoby rosną.

## Iteracja 1 — grywalny pion (1–2 tygodnie)
- Działający core loop: budowa → produkcja → próg terraformacji → fala obrony.
- Jedna jednostka wroga planetarnego + jedna wieżyczka.
- Podstawowe UI celu i stanu bazy.

**Kryterium wyjścia:** pełna sesja 15–20 minut z początkiem, napięciem i zakończeniem.

## Iteracja 2 — klimat i czytelność (1 tydzień)
- Silny kontrast wizualny:
  - Terraformacja: szarość → zielonkawy glow,
  - Zagrożenie: czerwone pulsowanie/pęknięcia.
- Dźwięki reakcji planety i alertów.
- Lepszy feedback: linie zasilania, wskaźniki przeciążenia.

**Kryterium wyjścia:** gracz bez tutoriala rozumie, co dzieje się na mapie.

## Iteracja 3 — decyzje i replayability (1–2 tygodnie)
- 2–3 archetypy reakcji planety (np. szybkie/słabe, wolne/mocne, zakłócające energię).
- 3 ścieżki finałowe (Uspokojenie/Dominacja/Symbioza).
- Wstępny balans tempa rozgrywki.

**Kryterium wyjścia:** co najmniej 2 różne style przejścia tej samej mapy.

## 6. Architektura systemów (pod Godot)

### Moduły
- `GridManager` — zarządzanie heksami i stanem terenu.
- `Simulation` — tick ekonomii, terraformacja, fale reakcji.
- `WorldRenderer` — wizualna warstwa zmian biomu i efektów planety.
- `Main` — orkiestracja sceny i przepływ sesji.

### Dane
- Dane budynków i wrogów trzymane w konfiguracjach (łatwe tunowanie bez przepisywania logiki).
- Progi terraformacji jako tabelka wartości (czytelny balans).

## 7. UI/UX — zasady

- Jeden główny cel na ekranie: „Ustabilizuj planetę do X%”.
- Trzy czytelne paski: Tlen, Ciepło, Energia Bio.
- Alerty tylko wysokiej wartości (fala, niedobór energii, nowy próg).
- Minimum tekstu — maksimum kodowania kolorem/animacją.

## 8. Styl artystyczny (low scope, high mood)

- Heksy i proste bryły.
- 2–3 dominujące kolory na biom.
- Klimat budowany przez:
  - światło,
  - puls,
  - kontrast „spokój vs reakcja”.

## 9. Ryzyka + ograniczanie

- **Ryzyko:** zbyt szybki rozrost feature’ów.
  - **Mitigacja:** trzymać MVP, każdą nową funkcję przepuszczać przez pytanie „czy wzmacnia core loop?”.
- **Ryzyko:** chaos wizualny przy falach.
  - **Mitigacja:** priorytetyzacja efektów i czytelne warstwy UI.
- **Ryzyko:** nudny midgame.
  - **Mitigacja:** progi terraformacji odblokowujące nowe zachowania planety.

## 10. Metryki, które warto mierzyć od początku

- Średni czas sesji.
- Moment pierwszej porażki.
- Ile fal gracz przeżywa.
- Którą ścieżkę finałową wybiera.
- W którym momencie najczęściej kończy grę.

## 11. Definicja sukcesu (na 1. kamień milowy)

Po 4–6 tygodniach masz build, który:
- daje pełną pętlę 20–30 minut,
- ma wyraźny klimat „żywej planety”,
- pozwala wygrać/przegrać z poczuciem sprawczości,
- zachęca do kolejnego podejścia inną strategią.
