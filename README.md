# JetForm

![screenshot](https://github.com/jetform-dev/jetform/assets/1094221/15ab7f06-378f-4a11-b92e-cccb55e63b1b)

> 🚧 Under heavy development... 🚧

JetForm dibuat dari nol dengan fokus membantu anda penjual/creator produk digital seperti ebook, desain, source code dll. **Anda fokus membuat produk berkualitas, sisanya biar JetForm yang menangani**.

JetForm bukan ide baru, namun terinspirasi dari beberapa platform yang sudah ada di pasaran namun dengan keunggulan tersendiri, platform tersebut misalnya:

- **gumroad.com**, inspirasi utama dari JetForm adalah Gumroad, tetapi Gumroad tidak mendukung sistem pembayaran lokal yang kadang menyulitkan content creator yang mentargetkan pasar lokal.
- **orderonline.id**, inspirasi berikutnya, tetapi platform ini *overkill* dan *relatif mahal* bagi mereka yang hanya menjual produk digital dengan penjualan yang tidak pasti setiap bulannya.
- **karyakarsa.com**, lebih ke media sosial buat kreator meskipun bisa jualan karya.
- **trakteer.id**, lebih ke media sosial buat kreator meskipun bisa jualan karya.
- **lynk.id**, fitur terlalu minim buat mereka yang fokus jualan produk digital, berorientasi ke pengguna mobile.

## Kenapa JetForm?

**Untuk penjual**: JetForm fokus memberikan pengalaman (User Experience) yang sederhana namun memiliki semua fitur penting yang dibutuhkan penjual. Kreator fokus membuat produk dan memasaekan, JetForm akan menjadi partner bisnis yang mengurusi penjualan dan distribusi produk.

**Untuk pembeli**: Akses ke produk yang dibeli langsung didapatkan begitu pembayaran selesai. Tidak perlu menunggu lama, karena semua serba otomatis.

**Versi pertama hanya fokus pada fitur inti** (fitur yang anda perlukan untuk mulai jualan):
```
1. Penjual membuat produk dengan mudah (3 langkah: Daftar Gratis, Buat Produk, Promosikan)
2. Penjual menerima pembayaran dengan mudah (Sistem pembayaran otomatis, QRIS atau Virtual Account Bank)
3. Pembeli mendapatkan produk dengan cepat (Buat order, bayar, dan langsung dapat produk; Otomatis, 24/7)
4. Penjual menarik keuntungan dengan mudah (Request penarikan dana, diproses secepatnya)
```

---
Dan berikut detailnya:

- [x] **Open source (kode sumber terbuka)**. JetForm mengedepankan transparansi, keterbukaan (openess) dan keadilan (fairness). Dikembangkan menggunakan tools open source serta berkontribusi balik ke komunitas open source. JetForm ❤️ open source.
- [x] **Built-in digital product distribution system**. Produk dijual dan didistribusikan langsung ke pembeli dengan aman tanpa perlu integrasi dengan sistem pihak ketiga.
- [x] **Fast and secure checkout page**. Pembeli membeli produk yang mereka inginkan dengan proses yang cepat, mudah dan aman.
- [x] **Simple and flexible pricing!** Anda bisa daftar dan langsung jualan tanpa iuran bulanan dengan sistem Pay As You Go (komisi) atau pilih paket Bulanan kalau penjualan Anda sudah mulai meningkat.
- [x] **No limits**. Tidak ada batasan dalam jumlah produk ataupun jumlah transaksi.
- [x] **Product Variants**. Buat produk dengan varian berbeda dengan harga berbeda. Bisa juga untuk produk gratis (Lead Magnet).
- [x] **Withdraw anytime**. Withdraw hasil penjualan anda kapan saja.
- [x] **Local payment methods**. Pembayaran aman dengan metode pembayaran kekinian (Virtual Account, QRIS, dll.). Payment processor JetForm adalah Midtrans.
- [ ] **Create great offers!** Berbagai modul untuk membuat penawaran anda lebih menarik, seperti: Scarcity (stok terbatas), Urgency (waktu terbatas), Bonus (bonus melimpah) atau kode voucher.
- [ ] **Integrasi dengan platform lain.** JetForm bisa dihubungkan dengan platform lain menggunakan layanan dari _Zapier_.
- [ ] **Advance analytics**. Lihat siapa yang mengakses halaman produk anda, siapa yang membeli, lewat apa (mobile atau web), kampanye iklan yang mana, dll.
- [ ] **Your product, your data**. Export data produk, penjualan dan pembeli untuk keperluan analisis anda.

Anda punya ide menarik? [lets talk](https://github.com/jetform-dev/jetform/discussions).

## Detail Teknis

JetForm dibuat dengan [Phoenix framework](https://www.phoenixframework.org/) dengan bahasa [Elixir](https://elixir-lang.org/). Adalah web-framework untuk membuat aplikasi dengan produktif, di-backing dengan bahasa Elixir (berjalan diatas Erlang VM) yang terkenal dengan kemampuannya untuk membangun aplikasi yang highly-concurrent + fault tolerant (dipakai Discord, WhatsApp, Pinterest, dll.) dan merupakan bahasa functional.

## Development

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Lisensi

JetForm berlisensi **AGPL-3.0 License**.
```
Permissions of this strongest copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license. Copyright and license notices must be preserved. Contributors provide an express grant of patent rights. When a modified version is used to provide a service over a network, the complete source code of the modified version must be made available.
```

Yang artinya:
```
Siapa saja boleh mempergunakan, memodifikasi dan mendistribusikan proyek ini tetapi harus tetap menggunakan lisensi yang sama dan kode sumber yang harus selalu dibuka secara penuh.
```

Lebih detail mengenai lisensi ini bisa dibaca [disini](https://github.com/jetform-dev/jetform/blob/main/LICENSE).
