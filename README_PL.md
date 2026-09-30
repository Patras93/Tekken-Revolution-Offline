# Tekken Revolution Offline / Custom Updates

Repozytorium zawiera wyłącznie własne patche, skrypty aktualizacji i instrukcje dla TEKKEN REVOLUTION NPUB31250 01.05.

## Czego repo nie zawiera
- plików gry,
- EBOOT.BIN / EBOOT.elf,
- data*.psarc,
- zapisów użytkownika,
- bazy RPCN,
- tokenów i danych logowania.

## Pakiet RPCS3 + lokalny serwer
Gotowy pakiet emulatora z lokalnym backendem i lokalnym RPCN jest publikowany jako asset GitHub Release, a nie jako plik w repo.

Użytkownik musi sam posiadać legalną kopię TEKKEN REVOLUTION NPUB31250 01.05.

## Custom Updates
Pierwsza własna linia aktualizacji zaczyna się od 1.1.0.

### 1.1.1 – Startup Reliability Hotfix
- Zachowuje gameplay z 1.1.0: nieskończony czas rundy, 5 wygranych i maksymalnie 9 rund.
- Dodaje jeden launcher uruchamiający lokalny backend, RPCN 1.8.7 i RPCS3 w poprawnej kolejności.
- Backend odpowiada na `/launcher/update/windows/manifest`, dzięki czemu lokalny launcher nie wywala się na sprawdzaniu własnej aktualizacji.
- Nie nadpisuje zapisów gry, bazy RPCN ani danych logowania.
- Działający lokalny hook Offline Kit ma SHA-256: `53e7985b6b1737bb7f89809df50145256d1574513deb0c3c1a69415aef1906de`.

### 1.1.0
- Native Infinite Round / nieskończony czas rundy.
- Patch dla NPUB31250 01.05.
- 5 wygranych / do 9 rund z Final Round przy 4:4.

Kolejne funkcje będą dodawane jako następne wersje po potwierdzeniu testów.

## Automatyczny updater
Plik `tools/Update-TekkenRevolution.ps1` sprawdza repozytorium, wykrywa najwyższą wersję z katalogu `releases`, pobiera manifest i potrzebne pliki, zatrzymuje RPCS3, robi backup i instaluje aktualizację.

W paczce dystrybucyjnej są dwa proste pliki:
- `Sprawdz aktualizacje.cmd` — tylko sprawdza, czy jest nowsza wersja.
- `Aktualizuj Tekken Revolution.cmd` — pobiera i instaluje najnowszy update.

Rollback używa `custom_updates/install_state.json` i potrafi zarówno przywrócić nadpisane pliki, jak i usunąć pliki utworzone przez update.

## Bezpieczeństwo danych
Pakiet dystrybucyjny nie zawiera lokalnej bazy kont RPCN ani prywatnych tokenów.
