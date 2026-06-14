#!/bin/bash
#
# Copyright (c) 2026 Rofi (Fixploit03)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

clean_up(){
	echo -e "\n[*] Menghentikan monitoring log DHCP server..."
	exit 0
}

restart_dhcp(){
	echo "[*] Merestart DHCP server..."
	systemctl restart isc-dhcp-server

	local sukses=0

	for i in {1..10}; do
		if systemctl is-active --quiet isc-dhcp-server; then
			sukses=1
			break
		fi
		sleep 1
	done

	if [[ "${sukses}" -eq 1 ]]; then
		echo "[+] DHCP server berhasil direstart!"
	else
		echo "[-] Gagal menjalankan DHCP server!"
		echo "[*] Ketik 'journalctl -u isc-dhcp-server -n 50' untuk melihat log."
		exit 1
	fi
}

usage(){
	echo "Penggunaan: sudo bash $0 -i <interface> [opsi]"
	echo ""
	echo "Opsi:"
	echo "	-h	: Menampilkan menu bantuan"
	echo "	-i	: Menentukan interface jaringan"
	echo "	-l	: Menampilkan log DHCP server"
	echo "	-r	: Mereset pool DHCP server"
	exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
	echo "[-] Script ini harus dijalankan sebagai root!"
	exit 1
fi

if ! dpkg -s isc-dhcp-server &>/dev/null; then
	echo "[-] isc-dhcp-server belum terinstal!"
	exit 1
fi

ip="10.10.10.1/24"
log=0
reset=0
interface=""

while getopts ":hi:lr" opsi; do
	case "${opsi}" in
		h)
			usage
			;;
		i)
			interface="${OPTARG}"
			;;
		l)
			log=1
			;;
		r)
			reset=1
			;;
		\?)
			echo "ERROR: Opsi tidak dikenal -${OPTARG}" >&2
			exit 1
			;;
		:)
			echo "ERROR: Opsi -${OPTARG} butuh argumen." >&2
			exit 1
			;;
	esac
done

if [[ -z "${interface}" ]]; then
	usage
fi

if [[ ! -d "/sys/class/net/${interface}" ]]; then
	echo "[-] Interface ${interface} tidak ditemukan!"
	exit 1
fi

if [[ "${reset}" -eq 1 ]]; then
	echo "[*] Menghentikan DHCP server sementara..."
	systemctl stop isc-dhcp-server

	echo "[*] Mereset pool DHCP (mengosongkan semua lease)..."
	if [[ -f /var/lib/dhcp/dhcpd.leases ]]; then
		truncate -s 0 /var/lib/dhcp/dhcpd.leases
		echo "[+] File lease berhasil dikosongkan!"
	else
		echo "[-] File lease tidak ditemukan!"
	fi

	restart_dhcp
	exit 0
fi

echo "[*] Menambahkan IP ${ip} ke interface ${interface}..."
ip addr flush dev "${interface}"
ip addr add "${ip}" dev "${interface}"
ip link set "${interface}" up

if [[ -f /etc/default/isc-dhcp-server && ! -f /etc/default/isc-dhcp-server.bak ]]; then
	echo "[*] Membuat backup pada file konfigurasi '/etc/default/isc-dhcp-server'..."
	cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak
fi

if [[ -f /etc/dhcp/dhcpd.conf && ! -f /etc/dhcp/dhcpd.conf.bak ]]; then
	echo "[*] Membuat backup pada file konfigurasi '/etc/dhcp/dhcpd.conf'..."
	cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
fi

echo "[*] Membuat file konfigurasi '/etc/default/isc-dhcp-server'..."
cat << EOF > /etc/default/isc-dhcp-server
INTERFACESv4="${interface}"
INTERFACESv6=""
EOF

echo "[*] Membuat file konfigurasi '/etc/dhcp/dhcpd.conf'..."
cat << EOF > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
# sesuaikan dengan ip yang ada di variabel ip
subnet 10.10.10.0 netmask 255.255.255.0 {
	range 10.10.10.2 10.10.10.254;
	option routers 10.10.10.1;
	#option domain-name-servers 8.8.8.8, 8.8.4.4;
	option subnet-mask 255.255.255.0;
}
EOF

restart_dhcp

if [[ "${log}" -eq 1 ]]; then
	echo "[*] Menampilkan log DHCP server secara real-time..."
	echo "[*] Tekan [CTRL+C] untuk menghentikan monitoring log."
	trap clean_up SIGINT
	journalctl -u isc-dhcp-server -f
fi
