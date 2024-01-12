# Snappy

> 🚧 Under heavy development... 🚧

Snappy dibuat dari nol dengan fokus 100% memudahkan para penjual/creator produk digital seperti ebook, online course dll. **No bloated unnecessary bells and whistels!**

Snappy bukanlah ide baru, melainkan penggabungan intisari beberapa produk yang sudah ada di pasaran namun dengan keunggulan tersendiri, produk-produk tersebut misalnya:

- **gumroad.com**, inspirasi utama dari Snappy adalah Gumroad, tetapi Gumroad tidak mendukung sistem pembayaran lokal yang kadang menyulitkan content creator yang mentargetkan pasar lokal.
- **orderonline.id**, inspirasi berikutnya, tetapi platform ini *overkill* dan *relatif mahal* bagi mereka yang hanya menjual produk digital dengan penjualan yang tidak pasti setiap bulannya.
- **karyakarsa.com**, fitur terlalu minim buat mereka yang fokus jualan produk digital.
- **saweria.co**, fitur terlalu minim buat mereka yang fokus jualan produk digital.
- **lynk.id**, fitur terlalu minim buat mereka yang fokus jualan produk digital.

> 👉 Snappy ingin menjadi 'sweet spot' diantara produk-produk diatas, dimana menyediakan fitur yang **cukup** (tidak minim, juga tidak _over_). Fokus pada _happy seller and buyer experience_ yang simpel, to-the-point, dan pastinya _snappy!_ alias cepat.

## Fitur Snappy

**Versi pertama hanya fokus pada fitur inti** (fitur yang anda perlukan untuk mulai jualan):
1. Penjual buat produk dengan mudah
1. Penjual terima pembayaran dengan mudah
1. Pembeli mendapatkan produk dengan cepat 
1. Penjual withdraw keuntungan dengan mudah

---
Dan berikut detailnya:

- [x] **Open source (kode sumber terbuka)**. Snappy mengedepankan transparansi, keterbukaan (openess) dan keadilan (fairness). Dikembangkan menggunakan tools open source dan ingin berkontribusi balik ke komunitas open source. We ❤️ open source.
- [x] **Built-in digital product distribution system**. Produk digital bisa dijual dan didistribusikan langsung secara otomatis ke pembeli dengan aman tanpa perlu integrasi dengan sistem pihak ketiga.
- [x] **Fast and secure checkout page**. Pembeli langsung dapat membeli produk yang mereka inginkan dengan proses yang cepat, mudah dan aman.
- [x] **Flat commision fee. No monthly subscription!** Anda bisa daftar dan langsung jualan tanpa iuran bulanan. Snappy mendapat komisi 5-10% dari setiap transaksi penjualan produk atau komisi Rp. 5,000 apabila harga produk anda kurang dari Rp. 50,000. _Komisi ini digunakan untuk pengembangan, biaya payment processor, dan insfrastruktur sistem Snappy_.
- [x] **No limits**. Tidak ada batasan dalam jumlah produk ataupun jumlah transaksi.
- [x] **Product Variants**. Buat produk dengan varian berbeda dan harga berbeda.
- [x] **Withdraw anytime**. Withdraw hasil penjualan anda kapan saja (bebas biaya).
- [x] **Local payment methods**. Pembayaran aman dengan metode pembayaran kekinian (Virtual Account, QRIS, dll.). Payment processor kami adalah Midtrans.
- [ ] **Create great offers!** Berbagai modul untuk membuat penawaran anda lebih menarik, seperti: Scarcity (stok terbatas), Urgency (waktu terbatas), Bonuses (bonus melimpah) atau kode voucher.
- [ ] **Advance analytics**. Lihat siapa yang mengakses halaman produk anda, siapa yang membeli, lewat apa (mobile atau web), kampanye iklan yang mana dll.
- [ ] **Your product, your data**. Export data product, penjualan dan pembeli untuk keperluan anda.

Anda punya ide menarik? [lets talk](https://github.com/ekaputra07/snappy/discussions).

## Detail Teknis

Snappy adalah aplikasi monolith dengan semua fitur mulai dari landing page, admin sampai halaman checkout ada di dalam satu code base. Why? why not (maaf, lagi tidak ingin berdebat tentang monolith vs microservice).

Snappy dibuat dengan [Phoenix framework](https://www.phoenixframework.org/) dengan bahasa [Elixir](https://elixir-lang.org/). Belum pernah dengar? no worries. Adalah fullstack framework yang memungkinkan kita membuat aplikasi berbasis web dengan cepat (yah semua framework juga gitu kan?) tetapi di-backing dengan bahasa Elixir (berjalan diatas Erlang VM) yang terkenal dengan kemampuannya untuk membangun aplikasi yang highly-concurrent + fault tolerant (dipakai Discord, WhatsApp) dan merupakan bahasa functional. *Yes! I need some break from OOP and go the functional way and it's fun!*

Karena bahasa dan Framework tersebut saya bisa membuat admin dan halaman checkout Snappy menjadi realtime dan interaktif. Bisa membuat UI interaktif tanpa harus tenggelam dalam pilihan fancy UI framework yang tiada habisnya, cukup berbekal Elixir dan Tailwind CSS saja.

## Development

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/

## Lisensi

Snappy berlisensi **AGPL-3.0 License**.
```
Permissions of this strongest copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license. Copyright and license notices must be preserved. Contributors provide an express grant of patent rights. When a modified version is used to provide a service over a network, the complete source code of the modified version must be made available.
```

Yang artinya:
```
Siapa saja boleh mempergunakan, memodifikasi dan mendistribusikan proyek ini tetapi harus tetap menggunakan lisensi yang sama dan kode sumber harus selalu dibuka secara penuh.
```

Lebih detail mengenai lisensi ini bisa dibaca [disini](https://github.com/ekaputra07/snappy/blob/main/LICENSE).
