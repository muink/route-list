#!/bin/bash

CURDIR="$(cd $(dirname $0); pwd)"
export PATH="$PATH:$CURDIR"

# return: $OS $ARCH
getSysinfo() {
	case "$(uname || echo $OSTYPE)" in
		Linux|linux-gnu)
			# Linux
			export OS=linux
		;;
		Darwin|darwin*)
			# Mac OSX
			export OS=darwin
		;;
		CYGWIN_NT*|cygwin)
			# POSIX compatibility layer and Linux environment emulation for Windows
			export OS=windows
		;;
		MINGW32_NT*|MINGW64_NT*|MSYS_NT*|msys)
			# Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
			export OS=windows
		;;
		*)
			# Unknown.
			unset OS
		;;
	esac
	case "$(uname -m || echo $PROCESSOR_ARCHITECTURE)" in
		x86_64|amd64|AMD64)
			export ARCH=amd64
		;;
		arm64|ARM64|aarch64|AARCH64|armv8*|ARMV8*)
			export ARCH=arm64
		;;
		*)
			# Unknown.
			unset ARCH
		;;
	esac
	[ -n "$OS" -a -n "$ARCH" ] || err "Unsupported system or architecture.\n"
	[ "$OS" = "windows" -a "$ARCH" = "arm64" ] && err "Unsupported system or architecture.\n"
	return 0
}

getSysinfo
MERGER_VERSION=v1.1.3
[ "$OS" = "darwin" ] && SED=gsed || SED=sed
if [ -n "$OS$ARCH" ]; then
	MERGER=cidr-merger-$OS-$ARCH
	[ "$OS" = "windows" ] && MERGER=$MERGER.exe

	[ -x "$MERGER" ] || { curl -Lo $MERGER "https://github.com/zhanhb/cidr-merger/releases/download/$MERGER_VERSION/$MERGER" && chmod +x $MERGER; }
fi


# downloadto <url> <target>
downloadto() {
	curl -Lo "$2" "$1" && echo >> "$2"
}

update_ipcidr() {
	# China IP
	## IPv4
	IPv4='china_ipv4.txt'
	Version4='china_ipv4.ver'
	downloadto 'https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt' ipip.tmp
	downloadto 'https://raw.githubusercontent.com/metowolf/iplist/master/data/special/china.txt' cz88.tmp
	downloadto 'https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt' coipv4.tmp
	## Merge IPv4
	cat ipip.tmp cz88.tmp coipv4.tmp | sort -u > "$IPv4"
	$SED -i '/#.*/d; /^\s*$/d; s|\s||g' "$IPv4"
	sort -n -t'.' -k1,1 -k2,2 -k3,3 -k4,4 "$IPv4" -o "$IPv4"
	$MERGER -s --cidr -o "$IPv4" "$IPv4"
	cat <<-EOF > $Version4
	Last modified: $(date -u '+%F %T %Z')
	Source:
	ipip: https://github.com/17mon/china_ip_list/blob/master/china_ip_list.txt
	cz88: https://github.com/metowolf/iplist/blob/master/data/special/china.txt
	coip: https://github.com/gaoyifan/china-operator-ip/blob/ip-lists/china.txt
	EOF

	## IPv6
	IPv6='china_ipv6.txt'
	Version6='china_ipv6.ver'
	downloadto 'https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china6.txt' coipv6.tmp
	downloadto 'http://www.ipdeny.com/ipv6/ipaddresses/blocks/cn.zone' ipdeny6.tmp
	## Merge IPv6
	cat coipv6.tmp ipdeny6.tmp | sort -u > "$IPv6"
	$SED -i '/^#/d; /^\s*$/d; s|\s||g' "$IPv6"
	$MERGER -s --cidr -o "$IPv6" "$IPv6"
	cat <<-EOF > $Version6
	Last modified: $(date -u '+%F %T %Z')
	Source:
	coip6: https://github.com/gaoyifan/china-operator-ip/blob/ip-lists/china6.txt
	deny6: http://www.ipdeny.com/ipv6/ipaddresses/blocks/cn.zone
	EOF

	# Cleanup
	rm -f *.tmp
}

update_chinalist() {
	# China Domain
	## China Domain
	List='china_list.txt'
	Version='china_list.ver'
	downloadto 'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf' "$List"
	$SED -i 's|#.*||g; /^\s*$/d; s|\s||g' "$List"
	$SED -Ei "s|^server=/||; s|/.*$||" "$List"
	sort -u "$List" -o "$List"
	cat <<-EOF > $Version
	Last modified: $(date -u '+%F %T %Z')
	Source: https://github.com/felixonmars/dnsmasq-china-list/blob/master/accelerated-domains.china.conf
	type: domain_suffix
	EOF

	## China Domain Modified v2
	List='china_list2.txt'
	Version='china_list2.ver'
	downloadto 'https://raw.githubusercontent.com/muink/dnsmasq-china-tool/list/accelerated-domains2.china.conf' "$List"
	$SED -i 's|#.*||g; /^\s*$/d; s|\s||g' "$List"
	$SED -Ei "s|^server=/||; s|/.*$||" "$List"
	sort -u "$List" -o "$List"
	cat <<-EOF > $Version
	Last modified: $(date -u '+%F %T %Z')
	Source: https://github.com/muink/dnsmasq-china-tool/blob/list/accelerated-domains2.china.conf
	type: domain_suffix
	EOF

	# Cleanup
	rm -f *.tmp
}


# main
update_ipcidr
update_chinalist
