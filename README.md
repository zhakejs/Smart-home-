# Smart Home 13 saklar lewat web (Supabase + Vercel + ESP32-C3)

## A. Supabase (proyek BARU)
1. supabase.com > New project (org Chat box / Pribadi, region Asia-Pasifik, paket Free).
2. Di `supabase.sql`, ganti `GANTI_RAHASIA_PERANGKAT` dengan kata acak panjang buatanmu, lalu tempel seluruh isinya di SQL Editor > Run.
3. Authentication > Sign In / Providers: matikan *Allow new users to sign up* dan *Confirm email*.
4. Authentication > Users > Add user: email `usernamemu@home.app`, isi sandi, centang Auto Confirm. (Satu akun per orang yang boleh mengontrol.)
5. Project Settings > API Keys > Legacy: salin Project URL dan kunci **anon public**.

## B. GitHub + Vercel
1. Repo GitHub baru (PRIVATE). Upload `index.html`, `config.js`, `manifest.json`, `icon.svg`, dan `sw.js` (tanpa folder).
2. Di `config.js` isi URL dan kunci anon.
3. Vercel > Add New > Project > pilih repo > Framework Other > Deploy. Tidak perlu Environment Variables.

## C. ESP32-C3 (ArduinoDroid)
1. Buka `SmartHome_Cloud.ino`, isi SB_HOST (tanpa https://), SB_KEY (anon), DEV_KEY (kata rahasia yang sama dengan di SQL), (WiFi rumah "Syaban" sudah terisi; pastikan itu WiFi 2,4 GHz).
2. Board ESP32C3 Dev Module, partisi Default 4MB. Colok HP ke ESP32 lewat kabel OTG, lalu Upload.
3. Buka web > tulisan di kanan atas harus berubah jadi **Online** dalam beberapa detik.

## Pasang seperti aplikasi
Di Chrome HP: titik tiga > Tambahkan ke layar utama (Install app).

## Catatan
- Pin GPIO tiap saklar bisa diganti di tab Jadwal.
- Percobaan login yang berulang dibatasi Supabase (Authentication > Rate Limits).
- Update firmware yang gagal (ukuran tidak cocok, dll.) muncul sebagai pesan merah di tab Firmware.
- Jangan upload `.ino` yang sudah berisi sandi WiFi ke GitHub.
- Update firmware lewat web: compile, ambil file `.bin`, upload di tab Firmware.
