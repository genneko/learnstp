#!/bin/sh
prog=$(basename $0)
bindir=$(dirname $(readlink -f $0))

VERBOSE=1

echoerr() {
	echo "$@" >&2
}

echov() {
	test "$VERBOSE" -gt 0 && echo "$@"
}

echoerrv() {
	test "$VERBOSE" -gt 0 && echoerr "$@"
}

_getelem() {
	local array=$1
	local index=${2:-1}
	if echo "$index" | grep -q '[^0-9]'; then
		echo ""
	elif [ $index -eq 0 ]; then
		echo ""
	else
		echo "$array" | cut -d ' ' -f $index
	fi
}

_ep() {
	local ep=$1
	if [ -n "$ep" ]; then
		echo $ep | sed -E 's/[ab]$//'
	fi
}

link_down() {
	local ep
	for ep in $@; do
		if [ -n "$ep" ]; then
			ifconfig ${ep}a down 2>&1 > /dev/null
			ifconfig ${ep}b down 2>&1 > /dev/null
		fi
	done
}

link_up() {
	local ep
	for ep in $@; do
		if [ -n "$ep" ]; then
			ifconfig ${ep}a up 2>&1 > /dev/null
			ifconfig ${ep}b up 2>&1 > /dev/null
		fi
	done
}

disconnect_bridges() {
	local ep
	for ep in $@; do
		local bridge_list=$($bindir/app/show_bridge.pl -e $ep)
		local b1=$(_getelem "$bridge_list" 1)
		local b2=$(_getelem "$bridge_list" 2)
		echov "$ep: $b1 - $b2"

		if [ -n "$b1" -a -n "$b2" -a -n "$ep" ]; then
			link_down $ep
			ifconfig $b1 deletem ${ep}a
			ifconfig $b2 deletem ${ep}b
		fi
	done
}

connect_bridges() {
	local b1=$1
	local b2=$2

	local ep=$(ifconfig epair create | sed 's/a$//')
	echov "$ep: $b1 - $b2"

	if [ -n "$b1" -a -n "$b2" -a -n "$ep" ]; then
		ifconfig $b1 addm ${ep}a stp ${ep}a up
		ifconfig $b2 addm ${ep}b stp ${ep}b up
		link_up $ep
	fi
}

build() {
	local topology=$1
	shift

	local OPTIND
	local rootindex=0
	while getopts "R:" opt
	do
		case "$opt" in
			R) rootindex="$OPTARG" ;;
		esac
	done
	shift $(( $OPTIND - 1 ))

	local nbridges=${1:-4}
	local nlinks=${2:-1}

	local bridge_list=""
	local root_bridge=""
	local i j k lb rb ep

	if [ -z "$nbridges" -o $nbridges -lt 1 ]; then
		echoerrv "* nbridges >= 1 (default: 4)"
		echoerrv "* nlinks >= 1 (default: 1)"
		return
	elif [ $rootindex -gt $nbridges ]; then
		echoerrv "* rootindex (-R) <= nbridges (default: 1)"
		return
	fi

	case "$topology" in
		mesh|ring|inline)
			bridge_list=$(_mk_bridges $nbridges)
			root_bridge=$(_getelem "$bridge_list" $rootindex)
			echov "nbridges=$nbridges"
			echov "nlinks=$nlinks"
			echov "bridge_list=$bridge_list"
			echov "root_bridge=$root_bridge"
			_mk_${topology} $nbridges $nlinks "$bridge_list"
			;;
		*)
			echoerrv "* specify mesh or ring."
			return
			;;
	esac

	if [ -n "$root_bridge" ]; then
		ifconfig $root_bridge priority 0
	fi
}

_mk_bridges() {
	local nbridges=$1
	local bridge_list=""
	local i
	for i in $(seq 1 $nbridges); do
		bridge_list="$bridge_list${bridge_list:+ }$(ifconfig bridge create)"
	done
	echo "$bridge_list"
}

_mk_mesh() {
	local nbridges=$1
	local nlinks=$2
	local bridge_list=$3
	local i j k lb rb
	for i in $(seq 1 $nbridges); do
		if [ $i -eq $nbridges ]; then
			break
		fi
		lb=$(_getelem "$bridge_list" $i)
		for j in $(seq $(expr $i + 1) $nbridges); do
			rb=$(_getelem "$bridge_list" $j)

			for k in $(seq 1 $nlinks); do
				connect_bridges $lb $rb
			done
		done
	done
}

_mk_ring() {
	local nbridges=$1
	local nlinks=$2
	local bridge_list=$3
	local open_path=$4
	local i j k lb rb
	for i in $(seq 1 $nbridges); do
		lb=$(_getelem "$bridge_list" $i)
		if [ $i -eq $nbridges ]; then
			if [ -n "$open_path" -o $nbridges -eq 1 ]; then
				j=0
			else
				j=1
			fi
		else
			j=$(expr $i + 1)
		fi
		rb=$(_getelem "$bridge_list" $j)

		if [ -n "$rb" ]; then
			for k in $(seq 1 $nlinks); do
				connect_bridges $lb $rb
			done
		fi
	done
}

_mk_inline() {
	local nbridges=$1
	local nlinks=$2
	local bridge_list=$3
	_mk_ring "$1" "$2" "$3" "openpath"
}

destroy_bridge() {
	local br po portlist bridgelist
	for br in $@; do
		portlist=$($bindir/app/show_bridge.pl -E $br)
		echov $br: $portlist
		for po in $portlist; do
			link_down $(_ep $po)
			ifconfig $br deletem $po
			bridgelist=$($bindir/app/show_bridge.pl -e $po)
			if [ -z "$bridgelist" ]; then
				ifconfig $po destroy
			fi
		done
		ifconfig $br down
		ifconfig $br destroy
	done
}

usage_exit() {
	echoerr "usage: # $prog mesh [-R <root>] [<nbridegs> [<nlinks>]]"
	echoerr "       # $prog ring [-R <root>] [<nbridegs> [<nlinks>]]"
	echoerr "       # $prog inline [-R <root>] [<nbridegs> [<nlinks>]]"
	echoerr "       # $prog connect <bridge1> <bridge2>"
	echoerr "       # $prog disconnect <epair>..."
	echoerr "       # $prog linkup <epair>..."
	echoerr "       # $prog linkdown <epair>..."
	echoerr "       # $prog destroy <bridge>..."
	echoerr "       # $prog destroy-all"
	echoerr "       $ $prog show"
	exit 1
}

cmd=$1
shift

case "$cmd" in
	mesh)
		build mesh "$@"
		;;
	ring)
		build ring "$@"
		;;
	inline)
		build inline "$@"
		;;
	linkup)
		link_up "$@"
		;;
	linkdown)
		link_down "$@"
		;;
	connect)
		connect_bridges "$@"
		;;
	disconnect)
		disconnect_bridges "$@"
		;;
	destroy)
		destroy_bridge "$@"
		;;
	destroy-all)
		ifconfig -g epair | sudo xargs -n1 -I IF ifconfig IF down
		ifconfig -g bridge | sudo xargs -n1 -I IF ifconfig IF down
		ifconfig -g bridge | sudo xargs -n1 -I IF ifconfig IF destroy
		ifconfig -g epair | grep 'a$' | sudo xargs -n1 -I IF ifconfig IF destroy
		;;
	show)
		$bindir/app/show_bridge.pl
		;;
	*)
		usage_exit
		;;
esac



