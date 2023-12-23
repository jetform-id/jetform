# Gummy.id

Gummy dibuat dari nol dengan fokus 100% memudahkan para penjual/creator produk digital seperti ebook, online course dll. **No bloated unnecessary bells and whistels!**

Gummy bukanlah ide baru, melainkan penggabungan intisari beberapa produk yang sudah ada di pasaran namun dengan keunggulan tersendiri, produk-produk tersebut misalnya:

- **gumroad.com**, inspirasi utama dari Gummy adalah Gumroad (perhatikan saja namanya :)), tetapi Gumroad tidak mendukung sistem pembayaran lokal yang kadang menyulitkan content creator yang mentargetkan pasar lokal.
- **orderonline.id**, inspirasi berikutnya, tetapi platform ini sepertinya *overkill* dan *terlalu mahal* bagi mereka yang hanya menjual produk digital dengan penjualan yang tidak pasti setiap bulannya.
- **karyakarsa.com**, fitur terlalu minim buat mereka yang fokus jualan produk digital.
- **saweria.co**, fitur terlalu minim buat mereka yang fokus jualan produk digital.
- **lynk.id**, fitur terlalu minim buat mereka yang fokus jualan produk digital.

## Fitur Gummy

- [x] **Built-in digital product distribution system**. Produk digital bisa dijual dan didistribusikan langsung secara otomatis ke pembeli dengan aman tanpa perlu integrasi dengan sistem pihak ketiga.
- [x] **Fast and secure checkout page**. Pembeli langsung dapat membeli produk yang mereka inginkan dengan proses yang cepat, mudah dan aman.
- [x] **Flat commision fee. No monthly subscription!** Anda bisa daftar dan langsung jualan tanpa iuran bulanan. Gummy mendapat komisi 10% dari setiap transaksi penjualan produk anda.
- [x] **No limits**. Tidak ada batasan dalam jumlah produk ataupun jumlah transaksi.
- [ ] **Create great offers!** Berbagai modul untuk membuat penawaran anda lebih menarik, seperti: Scarcity (stok terbatas), Urgency (waktu terbatas), Bonuses (bonus melimpah) atau kode voucher.
- [x] **Product Variants**. Buat produk dengan varian berbeda dan dengan harga berbeda.
- [x] **Withdraw anytime**. Withdraw hasil penjualan anda kapan saja.
- [x] **Local payment methods**. Pembayaran aman dengan metode pembayaran kekinian. Payment processor kami adalah Midtrans.
- [ ] **Advance analytics**. Lihat siapa yang mengakses halaman produk anda, siapa yang membeli, lewat apa (mobile atau web), kampanye iklan yang mana dll.
- [ ] **Your product, your data**. Export data product, penjualan dan pembeli untuk keperluan anda.
- [x] **Open source (kode sumber terbuka)**. Gummy mengedepankan keterbukaan (openess) dan keadilan (fairness), menggunakan produk-produk open source serta ingin didukung dan berkontribusi balik ke komunitas open source. We ❤️ open source.

Anda punya ide menarik? [lets talk](https://github.com/ekaputra07/gummy.id/discussions).

## Technical details

System Gummy adalah monolith dengan semua fitur mulai dari landing page, admin sampai halaman checkout ada di dalam satu code base. Why? why not (maaf, lagi tidak ingin berdebat tentang monolith vs microservice).

Gummy dibuat dengan [Phoenix framework](https://www.phoenixframework.org/) dengan bahasa [Elixir](https://elixir-lang.org/). Belum pernah dengar? no worries. Adalah fullstack framework yang memungkinkan kita membuat aplikasi berbasis web dengan cepat (yah semua framework juga gitu kan?) tetapi di-backing dengan bahasa Elixir (berjalan diatas Erlang VM) yang terkenal dengan kemampuannya untuk membangun aplikasi yang highly-concurrent + fault tolerant (dipakai Discord, WhatsApp) dan merupakan bahasa functional. *Yes! I need some break from OOP and go functional way and it's fun!*.

Karena bahasa dan Framework tersebut saya bisa membuat admin dan halaman checkout Gummy menjadi full-realtime. Bisa membuat UI interaktif tanpa harus tenggelam dalam pilihan fancy UI framework yang tiada habisnya, cukup berbekal Elixir dan Tailwind CSS (thats all you need!).

## Development

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
