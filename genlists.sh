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

# trim <src>
trim() {
	$SED -i 's|#.*||g; /^\s*$/d; s|\s||g' "$1"
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
	trim "$IPv4"
	sort -n -t'.' -k1,1 -k2,2 -k3,3 -k4,4 "$IPv4" -o "$IPv4"
	$MERGER -s --cidr -o "$IPv4" "$IPv4"
	cat <<-EOF > $Version4
	Last modified: $(date -u '+%F %T %Z')
	Source:
	- ipip: https://github.com/17mon/china_ip_list/blob/master/china_ip_list.txt
	- cz88: https://github.com/metowolf/iplist/blob/master/data/special/china.txt
	- coip: https://github.com/gaoyifan/china-operator-ip/blob/ip-lists/china.txt
	EOF

	## IPv6
	IPv6='china_ipv6.txt'
	Version6='china_ipv6.ver'
	downloadto 'https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china6.txt' coipv6.tmp
	downloadto 'http://www.ipdeny.com/ipv6/ipaddresses/blocks/cn.zone' ipdeny6.tmp
	## Merge IPv6
	cat coipv6.tmp ipdeny6.tmp | sort -u > "$IPv6"
	trim "$IPv6"
	$MERGER -s --cidr -o "$IPv6" "$IPv6"
	cat <<-EOF > $Version6
	Last modified: $(date -u '+%F %T %Z')
	Source:
	- coip6: https://github.com/gaoyifan/china-operator-ip/blob/ip-lists/china6.txt
	- deny6: http://www.ipdeny.com/ipv6/ipaddresses/blocks/cn.zone
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
	trim "$List"
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
	trim "$List"
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

update_gfwlist() {
	# GFW Domain
	## GFWList
	SRC='gfwlist.tmp'
	DST='gfwlist.list'
	TXT='gfwlist.txt'
	Version='gfwlist.ver'
	geo='ac ad ae af ai al am as at az ba be bf bg bi bj bs bt by ca cat cd cf cg ch ci cl cm co.ao co.bw co.ck co.cr co.id co.il co.in co.jp co.ke co.kr co.ls co.ma com com.af com.ag com.ai com.ar com.au com.bd com.bh com.bn com.bo com.br com.bz com.co com.cu com.cy com.do com.ec com.eg com.et com.fj com.gh com.gi com.gt com.hk com.jm com.kh com.kw com.lb com.ly com.mm com.mt com.mx com.my com.na com.nf com.ng com.ni com.np com.om com.pa com.pe com.pg com.ph com.pk com.pr com.py com.qa com.sa com.sb com.sg com.sl com.sv com.tj com.tr com.tw com.ua com.uy com.vc com.vn co.mz co.nz co.th co.tz co.ug co.uk co.uz co.ve co.vi co.za co.zm co.zw cv cz de dj dk dm dz ee es eu fi fm fr ga ge gg gl gm gp gr gy hk hn hr ht hu ie im iq is it it.ao je jo kg ki kz la li lk lt lu lv md me mg mk ml mn ms mu mv mw mx ne nl no nr nu org pl pn ps pt ro rs ru rw sc se sh si sk sm sn so sr st td tg tk tl tm tn to tt us vg vn vu ws'
	downloadto 'https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt' base64.tmp && base64 -d base64.tmp > "$SRC"
	$SED -Ei '/^\!/d; /^\[/d; /^\//d; /^@@/d; /^[^\.]+$/d; /[0-9]+(\.[0-9]+){3}/d; /:[0-9]+$/d' "$SRC"
	$SED -Ei 's|https?://||; s|/.*$||' "$SRC"
	$SED -i '/\.\*$/d' "$SRC"
	### regexp
	{ for z in $geo; do
		echo .blogspot.$z
		echo .google.$z
	done; } > domain_suffix.tmp
	echo twimg.edgesuite.net >> domain_suffix.tmp
	### ||domain^
	$SED -En 's/^\|\|([a-zA-Z0-9\*\.-]*[a-zA-Z0-9]).*/\1/p' "$SRC" | sed -E 's|^.*\*[a-zA-Z0-9-]*((\.[a-zA-Z0-9-]+){2,})|\1|' | sed '/\*/d' | sort -u >> domain_suffix.tmp
	sort -u domain_suffix.tmp -o domain_suffix.tmp
	$SED 's|\.|\\.|g; s|^|\\b|; s|$|\$|' domain_suffix.tmp > domain_suffix.regexp
	$SED -i '/^||/d' "$SRC"
	### .domain^
	$SED -En 's|^(\.[a-zA-Z0-9\*\.-]*[a-zA-Z0-9]).*|\1|p' "$SRC" | sed -E 's|^.*\*[a-zA-Z0-9-]*((\.[a-zA-Z0-9-]+){2,})|\1|' | sed '/\*/d' | sort -u | grep -Evf domain_suffix.regexp >> domain_suffix.tmp
	sort -u domain_suffix.tmp -o domain_suffix.tmp
	$SED 's|\.|\\.|g; s|^|\\b|; s|$|\$|' domain_suffix.tmp > domain_suffix.regexp
	$SED -i '/^\./d' "$SRC"
	### |domain^
	$SED -En 's/^\|([a-zA-Z0-9\*\.-]*[a-zA-Z0-9]).*/\1/p' "$SRC" | sed -E 's|^.*\*[a-zA-Z0-9-]*((\.[a-zA-Z0-9-]+){2,})|\1|' | sed '/\*/d' | sort -u | grep -Evf domain_suffix.regexp > domain.tmp
	$SED -i '/^|/d' "$SRC"
	### domain^
	$SED -En 's|^([a-zA-Z0-9\*\.-]*[a-zA-Z0-9]).*|\1|p' "$SRC" | sed -E 's|^.*\*[a-zA-Z0-9-]*((\.[a-zA-Z0-9-]+){2,})|\1|' | sed '/\*/d' | sort -u | grep -Evf domain_suffix.regexp >> domain.tmp
	sort -u domain.tmp -o domain.tmp
	#$SED -i '/^[a-zA-Z0-9\*\.-]*[a-zA-Z0-9]/d' "$SRC"
	### Others
	grep '^\.' domain.tmp >> domain_suffix.tmp
	sort -u domain_suffix.tmp -o domain_suffix.tmp
	$SED -i '/^\./d' domain.tmp

	### list
	sed 's|^|DOMAIN,|' domain.tmp > "$DST"
	sed 's|^|DOMAIN-SUFFIX,|' domain_suffix.tmp >> "$DST"
	### text
	cat domain.tmp domain_suffix.tmp | sed 's|^\.||' | sort -u > "$TXT"
	cat <<-EOF > $Version
	Last modified: $(date -u '+%F %T %Z')
	Source: https://github.com/gfwlist/gfwlist/blob/master/gfwlist.txt
	type: domain_suffix
	EOF

	# Cleanup
	rm -f *.tmp
	rm -f *.regexp
}


# main
update_ipcidr
update_chinalist
update_gfwlist
