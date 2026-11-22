# Ankieta

Interaktywna ankieta dla klientów pracowni projektowania wnętrz.

## Co potrafi

- **Przygotowanie (dla projektantki):** wgranie rzutu mieszkania, oznaczenie pomieszczeń numerkami,
  wybór ich przeznaczenia albo pozostawienie wyboru klientowi, włączanie i wyłączanie pojedynczych pytań.
- **Część 1 – Dom i domownicy:** domownicy, zwierzęta, codzienne życie, instalacje, styl i oczekiwania, priorytety.
- **Część 2 – Pomieszczenia:** rzut z numerkami, wybór przeznaczenia pomieszczeń, osobny zestaw pytań
  dla każdego pomieszczenia, notatki klienta na rzucie, powiększanie rzutu.
- **Część 3 – Podsumowanie:** wszystkie odpowiedzi, poprawianie opisów na miejscu, kopiowanie odpowiedzi.
- Pytania dodatkowe pojawiają się tylko wtedy, gdy klient wybierze odpowiednią odpowiedź.
- Link z końcówką `#klient` otwiera od razu widok klienta.

## Pliki

- `index.html` – cała ankieta (pytania są na początku skryptu, w sekcji „PYTANIA ANKIETY”).

## Plany

- Panel projektantki z logowaniem, osobny link dla każdego klienta, zapisywanie odpowiedzi w bazie danych,
  powiadomienia e-mail i eksport podsumowania do PDF.

## Notatki dla Claude (kolejne sesje)

- Rozmawiaj po polsku, prosto i przyjaźnie: właścicielka projektu nie jest programistką.
- **Przypomnienie:** gdy zmiana wymaga klikania w Supabase (np. migracja bazy) albo w ustawieniach Netlify,
  zaproponuj najpierw założenie kluczy dostępu (Supabase Access Token, Netlify Personal Access Token)
  przez bezpieczny formularz, żeby Claude mógł to zrobić sam. Właścicielka poprosiła o to przypomnienie.
- Netlify (darmowy plan): każda publikacja na gałęzi `main` kosztuje 15 kredytów z 300 miesięcznie.
  Zbieraj poprawki i publikuj je paczkami; prace w toku trzymaj na gałęzi `pierwsza-wersja-ankiety`.
- Przed publikacją zmian wymagających nowych kolumn/funkcji najpierw uruchom migrację bazy (`supabase/`).
- Adres aplikacji: https://ankieta-xgwb.netlify.app · projekt Supabase: pbkgiukbtydyktjenvbb (Frankfurt).
- Do zrobienia: informacja o RODO i zgoda klienta w ankiecie.
