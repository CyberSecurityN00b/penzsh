#!/bin/bash
## Exports
export PENZSH_HOME_DIR="${0:h:a}"
export PENZSH_CMD_DIR="${0:h:a}/cmds"
export PENZSH_CUSTCMD_DIR="${0:h:a}/custcmds"
export PENZSH_SHELL_DIR="${0:h:a}/shells"
export PENZSH_CUSTSHELL_DIR="${0:h:a}/custshells"
export PENZSH_CONFIG_DEFAULT="${0:h:a}/config.sh"
export PENZSH_CONFIG_LOCAL="/opt/penzsh/config.sh"

# Load the default to get everything, and then local to get changes
if [ -f ${PENZSH_CONFIG_DEFAULT} ] ; then
	source ${PENZSH_CONFIG_DEFAULT}
fi
if [ -f ${PENZSH_CONFIG_LOCAL} ] ; then
	source ${PENZSH_CONFIG_LOCAL}
fi

## Hook function definitions
function chpwd_update_penzsh_vars() {
	update_current_penzsh_vars
}

function prompt_penzsh() {
	if ( $PENZSH ) ; then
		local pzsh_icon=""
		local pzsh_text=""

		case $PENZSH_OS in
		windows) pzsh_icon="WINDOWS_ICON";;
		linux) pzsh_icon="LINUX_ICON";;
		bsd) pzsh_icon="FREEBSD_ICON";;
		net) pzsh_icon="NETWORK_ICON";;
		proxy) pzsh_icon="PROXY_ICON";;
		*) pzsh_icon="VCS_UNTRACKED_ICON";;
		esac

#		if [[ -f $PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/target && ! -f $PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/proxy_pid ]] ; then
#			pzsh_text="${PENZSH_TARGET}::PROXY_DOWN"
		if ( $PENZSH_PROXY_HOST ) ; then
			pzsh_text="${PENZSH_TARGET}::${PENZSH_FIRST_TARGET}"
		elif ( $PENZSH_PROXY_NET ) ; then
			pzsh_text="${PENZSH_PROXY_NET_TARGET}::${PENZSH_FIRST_TARGET}"
		else
			pzsh_text="${PENZSH_TARGET}"
		fi
		
		p10k segment -r -i ${pzsh_icon} -b red -t ${pzsh_text} 2>/dev/null
	fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_update_penzsh_vars

## Aliases
alias pz=penzsh

## Function Definitions
function update_current_penzsh_vars() {
	for var in $(env | egrep "^PENZSH_PROXY" | cut -d= -f1) ; do
		unset ${var}
	done
	export PENZSH=false
	export PENZSH_PROXY_NET=false
	export PENZSH_PROXY_HOST=false
	# Are we in a penzsh project?
	fc -P
	local x=`pwd`
	while [ "$x" != "/" ] ; do
		if [ `find "$x" -maxdepth 1 -name .penzsh -type d 2>/dev/null` ] ; then
			export PENZSH=true
			export PENZSH_DIR=$x
			export PENZSH_DIR_META=$x/.penzsh
			export PENZSH_FIRST_DIR=$x
			export PENZSH_FIRST_TARGET=$(cat $x/.penzsh/target)
			break
		elif [ `find "$x" -maxdepth 1 -name .penzsh_proxy_net -type d 2>/dev/null` ] ; then
			export PENZSH_PROXY_NET=true
			export PENZSH_PROXY_NET_DIR=$x
			export PENZSH_PROXY_NET_TARGET=$(cat $x/.penzsh_proxy_net/target)
		elif [ `find "$x" -maxdepth 1 -name .penzsh_proxy_host -type d 2>/dev/null` ] ; then
			export PENZSH_PROXY_HOST=true
			export PENZSH_PROXY_HOST_DIR=$x
		fi
		x=`dirname "$x"`
	done

	if ( $PENZSH ) ; then
		if ( $PENZSH_PROXY_HOST ) ; then
			export PENZSH_DIR=$PENZSH_PROXY_HOST_DIR
			export PENZSH_DIR_META=$PENZSH_PROXY_HOST_DIR/.penzsh_proxy_host
			export PENZSH_TARGET=$(cat $PENZSH_DIR_META/target)
			export PENZSH_OS=$(cat $PENZSH_DIR_META/os)
		elif ( $PENZSH_PROXY_NET ) ; then
			export PENZSH_DIR=$PENZSH_PROXY_NET_DIR
			export PENZSH_DIR_META=$PENZSH_PROXY_NET_DIR/.penzsh_proxy_net
			export PENZSH_TARGET=$(cat $PENZSH_DIR_META/target)
			export PENZSH_OS=$(cat $PENZSH_DIR_META/os)
		else
			export PENZSH_TARGET=$(cat $PENZSH_DIR_META/target)
			export PENZSH_OS=$(cat $PENZSH_DIR_META/os)
		fi

		export PENZSH_RHOST=${PENZSH_TARGET}
		export PENZSH_LHOST=${$(ip route get $PENZSH_RHOST 2>/dev/null | awk '{print $7}'):-0.0.0.0}
		export pzip=$PENZSH_TARGET
		fc -p $PENZSH_DIR_META/history
	fi
}
update_current_penzsh_vars

function penzsh_echo() {
	echo "PENZSH >>> ${@}"
}

# stolen from cmds/.core ...
function pzcore_func_require()
{
	# $1 - String used to check existence of requirement
	# $2 - String used to install necessary requirement
	
	eval "$1 >/dev/null 2>&1"
	if [ "$?" = 1 ] ; then
		pzcore_echo "This command is missing a requirement!"
		pzcore_echo "Should I run the following to fulfill this requirement?\n\t$2"
		read "REPLY?(y/n): "
		if [[ $REPLY =~ ^[Yy]$ ]] ; then
			eval "$2"
		else
			pzcore_echo "FAILED to run command without requirement!"
			return 1
		fi
	fi
}

function penzsh_cmd_do(){}
function penzsh_cmd_info(){}

function penzsh_create_host_dir() {
	#1 - Root host directory
	#2 - Target
	
	PENZSH_DIR="$1"
	mkdir -p $PENZSH_DIR/.penzsh
	echo $2 > $PENZSH_DIR/.penzsh/target
	touch $PENZSH_DIR/.penzsh/notes
	touch $PENZSH_DIR/.penzsh/todo
	touch $PENZSH_DIR/.penzsh/os
	mkdir -p $PENZSH_DIR/enum
	mkdir -p $PENZSH_DIR/loot
	mkdir -p $PENZSH_DIR/exploit
	mkdir -p $PENZSH_DIR/privesc
	mkdir -p $PENZSH_DIR/research
	mkdir -p $PENZSH_DIR/server

	update_current_penzsh_vars
}

function penzsh() {
	local CMD=${1:-help}

	if ( $PENZSH ) ; then
		case $CMD in
		create)
			penzsh_echo "Currently in a penzsh project for $PENZSH_TARGET!"
			penzsh_echo "penzsh does not support sub-projects!"
			;;
		flag)I
			case $2 in
			os:win*)
				echo windows > $PENZSH_DIR_META/os
				penzsh_echo "Now treating target as a Windows machine."
				;;
			os:lin*)
				echo linux > $PENZSH_DIR_META/os
				penzsh_echo "Now treating target as a Linux machine."
				;;
			os:freebsd|os:bsd)
				echo bsd > $PENZSH_DIR_META/os
				penzsh_echo "Now treating target as a FreeBSD machine."
				;;
			*)
				penzsh_echo "Error: Unknown flag!"
				;;
			esac
			update_current_penzsh_vars
			;;
		note)
			echo "$(date -u +\[%Y-%b-%d\ %T\ UTC\]) > ${@:2}" >> $PENZSH_DIR_META/notes
			;;
		notes)
			less $PENZSH_DIR_META/notes
			;;
		todo)
			# fix for empty lines if someone just does `pz todo`
			if [ "$#" -ne 1 ]
			then
				echo "${@:2}" >> $PENZSH_DIR_META/todo
			fi
			;;
		todos)
			cat -n $PENZSH_DIR_META/todo
			;;
		todone)
			local TODO_N=$(($2+0))
			local TODO_TASK=`sed -n "${TODO_N}p;" $PENZSH_DIR_META/todo 2>/dev/null`
			if [ -z "$TODO_TASK" ] ; then
				penzsh_echo "There aren't that many tasks!"
			else
				penzsh_echo "Really complete ${TODO_TASK}?"
				read -q "REPLY?(y/n): "
				echo ""
				if [ $REPLY = "y" ] ; then
					sed -i "${TODO_N}d;" $PENZSH_DIR_meta/todo
					penzsh note "Completed todo: ${TODO_TASK}"
					penzsh_echo "Todo removed!"
				else
					penzsh_echo "Aborting todo completion!"
				fi
			fi
			;;
		update)
			git --git-dir=$PENZSH_HOME_DIR pull
			penzsh_echo "If successful, you should have any updates. Please restart your shell!"
			;;
		info)
			if [ -f $PENZSH_CUSTCMD_DIR/$2 ]; then
				source $PENZSH_CUSTCMD_DIR/$2
				echo "=== $2 Information ==="
				penzsh_cmd_info
				echo ""
				echo "=== $2 Definition  ==="
				declare -f penzsh_cmd_do
			elif [ -f $PENZSH_CMD_DIR/$2 ]; then
				source $PENZSH_CMD_DIR/$2
				echo "=== $2 Information ==="
				penzsh_cmd_info
				echo ""
				echo "=== $2 Definition  ==="
				declare -f penzsh_cmd_do
			else
				penzsh_echo "No such command: $2"
				echo ""
				penzsh cmds
			fi
			;;
		proxyhostnew)
			if [[ $PENZSH_PROXY_NET && !$PENZSH_PROXY_HOST ]] ; then
				local pz_c_target=""

				if [ $2 ] ; then
					pz_c_target=$2
				else
					read "target?Target: "
					pz_c_target="$target"
				fi

				penzsh_create_host_dir "$(pwd)/$pz_c_target" "$pz_c_target"
			else
				penzsh_echo "This command is only available in immediate 'proxy_nets' subfolders!"
			fi
			;;
		proxyhostenum)
			if [[ $PENZSH_PROXY_NET && !$PENZSH_PROXY_HOST ]] ; then
				penzsh_echo "Performing basic host discovery, standby..."
				pzcore_func_require "which proxychains4" "sudo apt-get install proxychains4"
				if [ "$?" = 0 ] ; then
					for host in $(sudo proxychains4 -f $PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/proxychains.conf nmap -n -sT -Pn $PENZSH_PROXY_NET_TARGET -oG - | grep "Status: Up" | awk '{print $2}') ; do
						penzsh_create_host_dir "$PENZSH_PROXY_NET_DIR/$host" "$host"
					done
					penzsh_echo "Basic host discovery completed. NOTE: Not all hosts may have been discovered!"
				else
					penzsh_echo "Unable to comply, need proxychains4 to continue."
				fi
			else
				penzsh_echo "This command is only available in immediate 'proxy_nets' subfolders!"
			fi
			;;
		proxyconfig)
			if [[ $PENZSH_PROXY_NET && !$PENZSH_PROXY_HOST ]] ; then
				$PENZSH_PROGRAM_EDITOR $PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/proxy.sh
			else
				penzsh_echo "This command is only available in immediate 'proxy_nets' subfolders!"
			fi
			;;
		proxystart)
			if [[ $PENZSH_PROXY_NET && !$PENZSH_PROXY_HOST ]] ; then
				$PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/proxy.sh
			else
				penzsh_echo "This command is only available in immediate 'proxy_nets' subfolders!"
			fi
			;;
#		proxystop)
#			if [[ $PENZSH_PROXY_NET && !$PENZSH_PROXY_HOST ]] ; then
#				kill $(cat $PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/proxy_pid)
#				rm $PENZSH_PROXY_NET_DIR/.penzsh_proxy_net/proxy_pid
#			else
#				penzsh_echo "This command is only available in immediate 'proxy_nets' subfolders!"
#			fi
#			;;
		proxynew)
			mkdir -p "$PENZSH_FIRST_DIR/proxy_nets"
			read "network?What is the network on the other side of the proxy (i.e., 10.10.10.0/24)? "
			local network_dir="$PENZSH_FIRST_DIR/proxy_nets/$(echo $network | tr '/' _)"
			mkdir -p "$network_dir/.penzsh_proxy_net"
			echo $network > "$network_dir/.penzsh_proxy_net/target"
			echo net > "$network_dir/.penzsh_proxy_net/os"

			local proxyscript="$network_dir/.penzsh_proxy_net/proxy.sh"
			cp $PENZSH_HOME_DIR/proxytemplate ${proxyscript}
			sed -i s/___TARGET___/$PENZSH_TARGET/g ${proxyscript}
			chmod +x ${proxyscript}
			$PENZSH_PROGRAM_EDITOR $network_dir/.penzsh_proxy_net/proxy.sh

			penzsh_echo "Hopefully you're good to go!"
			penzsh_echo "Make sure to 'cd $(realpath --relative-to=. $network_dir)' and run 'pz proxystart'!"
			;;
		cmds)
			echo "Custom Commands:"
			ls $PENZSH_CUSTCMD_DIR
			echo ""
			echo "Core Commands:"
			ls $PENZSH_CMD_DIR
			;;
		*)
			if [ -f $PENZSH_CUSTCMD_DIR/$1 ]; then
				source $PENZSH_CUSTCMD_DIR/$1
				if ( $PENZSH_PROXY_NET ) ; then
					proxychains penzsh_cmd_do ${@:2}
				else
					penzsh_cmd_do ${@:2}
				fi
			elif [ -f $PENZSH_CMD_DIR/$1 ]; then
				source $PENZSH_CMD_DIR/$1
				penzsh_cmd_do ${@:2}
			else
				echo -e "Following are currently supported:"
				#echo -e "\tanalyze <file> - Analyze a file"
				echo -e "\tcmds           - List vailable custom/tool commands"
				echo -e "\tcreate         - Make the current direction a penzsh project"
				echo -e "\tflag"
				echo -e "\t\tos:freebsd - Flag the target as a FreeBSD machine."
				echo -e "\t\tos:linux   - Flag the target as a Linux machine."
				echo -e "\t\tos:windows - Flag the target as a Windows machine."
				echo -e "\tnote           - Save a note for later"
				echo -e "\tnotes          - Read your notes for this target"
				echo -e "\tproxynew       - Creates a new proxy"
				echo -e "\ttodo           - Remind yourself of something"
				echo -e "\ttodos          - See what you need to do for this target"
				echo -e "\tupdate         - Updates the penzsh project, ONLY IF YOU GIT CLONED IT!"
				echo -e ""

				if ( $PENZSH_PROXY_NET ) ; then
					if ( ! $PENZSH_PROXY_HOST ) ; then
						echo -e "========== PROXY NETWORK =========="
						echo -e "\tproxyconfig    - Configures the proxy for this CIDR."
						echo -e "\tproxyhostnew   - Creates single proxy-host directory."
						echo -e "\tproxyhostenum  - Creates proxy-host directories after host enumeration."
						echo -e "\tproxystart     - Starts the proxy configured for this CIDR."
						echo -e "\t\t\t(Note: For multiple proxies, make sure to start them in the correct order.)"
#						echo -e "\tproxystop      - Stops the proxy configured for this CIDR."
						echo -e ""
					fi
				fi

				echo -e "========== C O M M A N D S =========="
				echo -e "\tinfo <cmd>     - Shows brief info of command and prints command definition"
				echo -e "\t<cmd>          - Runs contextual command"
				echo -e ""
				echo -e "========== N O T E S =========="
				echo -e " - Try using 'pz' instead of 'penzsh' when calling this command!"
				echo -e " - You can use \$pzip to easily reference the target when in a PENZSH directory."
				echo -e " - If you're having trouble with default wordlists, make sure they are installed and you've run 'updatedb'."
				echo -e " - If you haven't already, copy ${PENZSH_CONFIG_DEFAULT} to ${PENZSH_CONFIG_LOCAL} and update with your preferences."
				#echo -e ""
				#echo -e "========== V A R I A B L E S =========="
				#env | egrep -i "^(penzsh_.*=|pz_.*=)"
			fi
			;;
		esac
	else
		case $CMD in
		create)
			local pz_c_name=""
			local pz_c_target=""

			if [ $2 ] ; then
				pz_c_name=$2
			else
				read "name?Project Name: "
			fi

			if [ $3 ] ; then
				pz_c_target=$3
			else
				read "target?Project Target: "
			fi

			penzsh_create_host_dir "$(pwd)/$pz_c_name" "$pz_c_target"

			;;
		*)
			penzsh_echo "This is not a penzsh project. Please run 'penzsh create' to create a penzsh project directory here."
		esac
	fi

	
}
