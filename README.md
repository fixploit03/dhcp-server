# DHCP Server

Script Bash sederhana untuk setup DHCP Server secara otomatis.

## Instalasi

```bash
sudo apt update
sudo apt install -y isc-dhcp-server git
git clone https://github.com/fixploit03/dhcp-server.git
cd dhcp-server
chmod +x dhcp-server.sh
```

## Penggunaan

```bash
sudo ./dhcp-server.sh -i <interface> [opsi]
```

Daftar opsi yang tersedia:
- `-h`: Menampilkan menu bantuan
- `-i`: Menentukan interface jaringan
- `-l`: Menampilkan log DHCP server
- `-r`: Mereset pool DHCP server

## Contoh

Menjalankan DHCP server tanpa log:

```bash
sudo ./dhcp-server -i <interface>
```

Menjalankan DHCP server dengan log:

```bash
sudo ./dhcp-server -i <interface> -l
```

Mereset pool DHCP server:

```bash
sudo ./dhcp-server -r
```

## Catatan

IP masih di-hardcode, untuk IP defaultnya adalah `10.10.10.1/24`. IP tersebut bisa diganti sesuai kebutuhan dengan mengedit variabel `ip` di dalam script `dhcp-server.sh`.

## Lisensi
Project ini dilisensikan di bawah lisensi [MIT](LICENSE).
