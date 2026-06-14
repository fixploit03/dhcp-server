# DHCP Server

## Instalasi

```
sudo apt update
sudo apt install -y isc-dhcp-server
```

## Penggunaan

```
sudo bash dhcp-server.sh -i <interface> [opsi]
```

Daftar opsi yang tersedia:
- `-h`: Menampilkan menu bantuan
- `-i`: Menentukan interface jaringan
- `-l`: Menampilkan log DHCP server
- `-r`: Mereset pool DHCP server

## Catatan

IP masih di-hardcode, untuk IP defaultnya adalah `10.10.10.1/24`. IP tersebut bisa diganti sesuai kebutuhan dengan mengedit variabel `ip` di dalam script `dhcp-server.sh`.
