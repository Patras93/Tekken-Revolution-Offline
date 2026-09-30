# v1.2.0 development – Private Online foundation

Ta galaz nie jest jeszcze publikowana przez automatyczny updater.

Cel:
- wspolny prywatny RPCN dla dwoch graczy;
- lokalny backend Tekken Revolution na kazdym komputerze;
- tryb Host i Gosc bez recznego edytowania hosts/rpcn.yml;
- przygotowanie pod Practice Online i warstwe NVDA.

Pliki:
- Setup Private Online Host.ps1
- Setup Private Online Guest.ps1
- Start Tekken Revolution Online.ps1

Siec:
- RPCN logowanie/matchmaking: TCP 31313;
- RPCN signaling: UDP 3657.
- Przy grze przez internet trzeba przekierowac oba porty do komputera hosta albo uzyc wspolnej sieci VPN.

Wazne:
- kazdy gracz potrzebuje osobnego konta RPCN na wspolnym serwerze;
- obecny OfflinePlayer nie moze byc docelowym wspolnym kontem dla dwoch jednoczesnych graczy;
- Practice Online i odczyt menu NVDA beda kolejnymi warstwami po potwierdzeniu polaczenia 1v1.
