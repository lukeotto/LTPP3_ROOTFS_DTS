#!/bin/bash
#---Define colors
DOCKER__YELLOW='\033[1;33m'
DOCKER__LIGHTBLUE='\033[1;34m'
DOCKER__NOCOLOR='\033[0m'

DOCKER__BG_LIGHTBLUE='\e[30;48;5;45m'

#---Define PATHS
SP7xxx_foldername="SP7021"
disk_foldername="disk"
qemu_user_static_filename="qemu-user-static"

usr_dir=/usr
usr_bin_dir=${usr_dir}/bin

home_dir=~
SP7xxx_dir=${home_dir}/${SP7xxx_foldername}
SP7xxx_linux_rootfs_initramfs_dir=${SP7xxx_dir}/linux/rootfs/initramfs
SP7xxx_linux_rootfs_initramfs_disk_dir=${SP7xxx_linux_rootfs_initramfs_dir}/${disk_foldername}

qemu_fpath=${usr_bin_dir}/qemu-arm-static
bash_fpath=${usr_bin_dir}/bash


#---Trap ctrl-c and Call ctrl_c()
trap CTRL_C__sub INT

function CTRL_C__sub() {
    echo -e "\r"
    echo -e "\r"
    echo -e "${DOCKER__EXITING_NOW}"
    echo -e "\r"
    echo -e "\r"

    exit
}

press_any_key__localfunc() {
	#Define constants
	local cTIMEOUT_ANYKEY=10

	#Initialize variables
	local keypressed=""
	local tcounter=0

	#Show Press Any Key message with count-down
	echo -e "\r"
	while [[ ${tcounter} -le ${cTIMEOUT_ANYKEY} ]];
	do
		delta_tcounter=$(( ${cTIMEOUT_ANYKEY} - ${tcounter} ))

		echo -e "\rPress (a)bort or any key to continue... (${delta_tcounter}) \c"
		read -N 1 -t 1 -s -r keypressed

		if [[ ! -z "${keypressed}" ]]; then
			if [[ "${keypressed}" == "a" ]] || [[ "${keypressed}" == "A" ]]; then
                echo -e "\r"
                echo -e "\r"
				exit
			else
				break
			fi
		fi
		
		tcounter=$((tcounter+1))
	done
	echo -e "\r"
}


#SHOW DOCKER BANNER
docker__load_header__sub() {
    echo -e "\r"
    echo -e "${DOCKER__BG_LIGHTBLUE}                               DOCKER${DOCKER__BG_LIGHTBLUE}                               ${DOCKER__NOCOLOR}"
}

docker__mandatory_apps_check__sub() {
    echo -e "\r"
    echo -e "Before we continue..."
    echo -e "\r"
    echo -e "Please make sure that to have ${DOCKER__YELLOW}manually${DOCKER__NOCOLOR} installed '${qemu_user_static_filename}'"
    echo -e "\r"
    echo -e "Using the already ${DOCKER__YELLOW}built-in${DOCKER__NOCOLOR} '${qemu_user_static_filename}' may result in errors."
    echo -e "\r"

    press_any_key__localfunc
}

docker__run_script__sub() {
    echo -e "\r"
        echo -e "--------------------------------------------------------------------"
    echo -e "GOING INTO <CHROOT>"
        echo -e "--------------------------------------------------------------------"
    echo -e "REMARK:"
    echo -e "\tTo EXIT 'chroot', type 'exit'"
        echo -e "--------------------------------------------------------------------"
    chroot ${SP7xxx_linux_rootfs_initramfs_disk_dir} ${qemu_fpath} ${bash_fpath}
}

docker__main__sub(){
    docker__load_header__sub
    docker__mandatory_apps_check__sub
    docker__run_script__sub
}


#Run main subroutine
docker__main__sub