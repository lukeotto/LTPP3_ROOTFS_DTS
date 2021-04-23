#!/bin/bash
#---COLOR CONSTANTS
DOCKER__NOCOLOR=$'\e[0m'
DOCKER__ERROR_FG_LIGHTRED=$'\e[1;31m'
DOCKER__SUCCESS_FG_LIGHTGREEN=$'\e[1;32m'
DOCKER__GENERAL_FG_YELLOW=$'\e[1;33m'
DOCKER__TITLE_FG_LIGHTBLUE=$'\e[30;38;5;45m'
DOCKER__IMAGEID_FG_BORDEAUX=$'\e[30;38;5;198m'

DOCKER__TITLE_BG_ORANGE=$'\e[30;48;5;215m'
DOCKER__FILES_FG_ORANGE=$'\e[30;38;5;215m'
DOCKER__DIRS_FG_VERYLIGHTORANGE=$'\e[30;38;5;223m'
DOCKER__TITLE_BG_LIGHTBLUE=$'\e[30;48;5;45m'



#---CONSTANTS
DOCKER__TITLE="TIBBO"
DOCKER__YES="y"
DOCKER__FIVE_SPACES="     "
DOCKER__LATEST="latest"
DOCKER__EXITING_NOW="Exiting now..."
DOCKER__NINE=9



#---PATHS
docker__dockerList_fpath=""
docker__dockerList_filename=""



#---Trap ctrl-c and Call ctrl_c()
trap CTRL_C__sub INT



#---FUNCTIONS
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
				exit
			else
				break
			fi
		fi
		
		tcounter=$((tcounter+1))
	done
	echo -e "\r"
}



#---SUBROUTINES
docker__load_header__sub() {
    echo -e "\r"
    echo -e "${DOCKER__TITLE_BG_ORANGE}                                 ${DOCKER__TITLE}${DOCKER__TITLE_BG_ORANGE}                                ${DOCKER__NOCOLOR}"
}

docker__mandatory_apps_check__sub() {
    #Define local constants
    local DOCKER_IO="docker.io"
    local QEMU_USER_STATIC="qemu-user-static"

    local docker_io_isInstalled=`dpkg -l | grep "${DOCKER_IO}"`
    local qemu_user_static_isInstalled=`dpkg -l | grep "${QEMU_USER_STATIC}"`

    if [[ -z ${docker_io_isInstalled} ]] || [[ -z ${qemu_user_static_isInstalled} ]]; then
        echo -e "${DOCKER__FIVE_SPACES}The following mandatory software is/are not installed:"
        if [[ -z ${docker_io_isInstalled} ]]; then
            echo -e "${DOCKER__FIVE_SPACES}- docker.io"
        fi
        if [[ -z ${qemu_user_static_isInstalled} ]]; then
            echo -e "${DOCKER__FIVE_SPACES}- qemu-user-static"
        fi
        echo -e "\r"
        echo -e "${DOCKER__FIVE_SPACES}PLEASE INSTALL the missing software."
        echo -e "\r"
        
        press_any_key__localfunc
    fi
}

docker__load_environment_variables__sub() {
    docker__current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    docker__current_dir=$(dirname ${docker__current_script_fpath})
    docker__parent_dir=${docker__current_dir%/*}    #gets one directory up
    if [[ -z ${docker__parent_dir} ]]; then
        docker__parent_dir="${DOCKER__SLASH_CHAR}"
    fi
    #Define local variables
    docker_current_script_filename=`basename $0`

    docker__my_LTPP3_ROOTFS_docker_dir=${docker__parent_dir}/docker
    docker__my_LTPP3_ROOTFS_docker_list_dir=${docker__my_LTPP3_ROOTFS_docker_dir}/list
    docker__my_LTPP3_ROOTFS_docker_dockerfiles_dir=${docker__my_LTPP3_ROOTFS_docker_dir}/dockerfiles
}

docker__show_dockerList_files__sub() {
    #Clear terminal screen
    # tput clear

    #Define variables
    local listOf_dockerListFpaths_string=""
    local listOf_dockerListFpaths_arr=()
    local listOf_dockerListFpaths_arrItem=""
    local extract_filename=""
    local readInput_msg="Choose a file (ctrl+c: quit): "

    #Get all files at the specified location
    listOf_dockerListFpaths_string=`find ${docker__my_LTPP3_ROOTFS_docker_list_dir} -maxdepth 1 -type f | LC_ALL=C sort`

    #Check if '' is an EMPTY STRING
    if [[ -z ${listOf_dockerListFpaths_string} ]]; then
        echo -e "\r"
        echo -e "----------------------------------------------------------------------"
        echo -e "***${DOCKER__ERROR_FG_LIGHTRED}ERROR${DOCKER__NOCOLOR}: no files found in directory:"
        echo -e "${DOCKER__FIVE_SPACES}${docker__my_LTPP3_ROOTFS_docker_list_dir}"
        echo -e "\r"
        echo -e "Please put all ${DOCKER__GENERAL_FG_YELLOW}dockerfile-list${DOCKER__NOCOLOR} files in this directory"

        echo -e "\r"
        echo -e "\r"

        exit
    fi


    #Convert string to array (with space delimiter)
    listOf_dockerListFpaths_arr=(${listOf_dockerListFpaths_string})

    #Start loop
    while true
    do
        #Initial sequence number
        local seqnum=0

        #Show all 'dockerfile-list' files
        echo -e "----------------------------------------------------------------------"
        echo -e "\t${DOCKER__GENERAL_FG_YELLOW}Create${DOCKER__NOCOLOR} multiple ${DOCKER__IMAGEID_FG_BORDEAUX}IMAGES${DOCKER__NOCOLOR} with ${DOCKER__TITLE_FG_LIGHTBLUE}DOCKER-FILES${DOCKER__NOCOLOR}"
        echo -e "----------------------------------------------------------------------"
        for listOf_dockerListFpaths_arrItem in "${listOf_dockerListFpaths_arr[@]}"
        do
            #increment sequence-number
            seqnum=$((seqnum+1))

            #Get filename only
            extract_filename=`basename ${listOf_dockerListFpaths_arrItem}`  
        
            #Show filename
            echo -e "${DOCKER__FIVE_SPACES}${seqnum}. ${extract_filename}"
        done
        echo -e "----------------------------------------------------------------------"

        #Read-input handler
        while true
        do
            #Show read-input
            if [[ ${seqnum} -le ${DOCKER__NINE} ]]; then    #seqnum <= 9
                read -N1 -p "Choose a file (ctrl+c: quit): " mychoice
            else    #seqnum > 9
                read -p "Choose a file (ctrl+c: quit): " mychoice
            fi

            #Check if 'mychoice' is a numeric value
            if [[ ${mychoice} =~ [1-9,0] ]]; then
                #check if 'mychoice' is one of the numbers shown in the overview...
                #... AND 'mychoice' is NOT '0'
                if [[ ${mychoice} -lt ${seqnum} ]] && [[ ${mychoice} -ne 0 ]]; then
                    echo -e "\r"    #print an empty line

                    break   #exit loop
                else
                    tput cuu1   #move-UP one line
                    tput el #clean until end of line
                fi
            else
                tput cuu1   #move-UP one line
                tput el #clean until end of line    
            fi
        done

        #Since arrays start with index=0, deduct 'mychoice' value by '1'
        index=$((mychoice-1))

        #Extract the chosen file from array and assign to the GLOBAL variable 'docker__dockerList_fpath'
        docker__dockerList_fpath=${listOf_dockerListFpaths_arr[index]}
echo $docker__dockerList_fpath
        docker__dockerList_filename=`basename ${docker__dockerList_fpath}`

        #Show chosen file contents
        echo -e "\r"
        echo -e "----------------------------------------------------------------------"
        echo -e "Contents of File ${DOCKER__FILES_FG_ORANGE}${extract_filename}${DOCKER__NOCOLOR}"
        echo -e "----------------------------------------------------------------------"
        while read file_line
        do
            echo -e "${DOCKER__FIVE_SPACES}${file_line}"

        done < ${docker__dockerList_fpath}
        echo -e "----------------------------------------------------------------------"

        #Read-input handler
        while true
        do
            #Show read-input
            read -N1 -p "Do you wish to continue (y/n): " mychoice

            #Check if 'mychoice' is a numeric value
            if [[ ${mychoice} =~ [y,n] ]]; then
                #print 2 empty lines
                echo -e "\r"
                echo -e "\r"

                if [[ ${mychoice} == ${DOCKER__YES} ]]; then
                    return  #exit function
                else
                    break   #exit THIS loop
                fi
            else
                tput cuu1   #move-UP one line
                tput el #clean until end of line    
            fi
        done
    done   
}

docker__create_image_handler__sub() {
    #---Read contents of the file
    #Each line of the file represents a 'dockerfile' containing the instructions to-be-executed
    
    #Define variables
    local linenum=1
    local dockerfile_fpath=""

    while IFS='' read file_line
    do
        if [[ ${linenum} -gt 1 ]]; then #skip the header
            #Get the fullpath
            dockerfile_fpath=${docker__my_LTPP3_ROOTFS_docker_dockerfiles_dir}/${file_line}

            #Check if file exists
            if [[ -f ${dockerfile_fpath} ]]; then
                docker__create_image__func ${dockerfile_fpath}
            else
                echo -e "\r"
                echo -e "***${DOCKER__ERROR_FG_LIGHTRED}ERROR${DOCKER__NOCOLOR}: non-existing file: ${dockerfile_fpath}"
                echo -e "\r"       
            fi
        fi

        linenum=$((linenum+1))  #increment index by 1
    done < ${docker__dockerList_fpath}
}
function docker__create_image__func() {
    #Input args
    local dockerfile_fpath=${1}

    #Define constants
    GREP_PATTERN="LABEL repository:tag"

    #Get REPOSITORY:TAG from dockerfile
    local dockerfile_repository_tag=`egrep -w "${GREP_PATTERN}" ${dockerfile_fpath} | cut -d"\"" -f2`

    #Check if '' is an EMPTY STRING
    if [[ -z ${dockerfile_repository_tag} ]]; then
        dockerfile_repository_tag="${dockerfile}:${DOCKER__LATEST}"
    fi

    #Define Docker command
    dockercmd="docker build --tag ${dockerfile_repository_tag} - < ${dockerfile_fpath}" #with REPOSITORY:TAG

    #Execute Docker command
    echo -e "\r"
    echo -e "Running: ${DOCKER__FILES_FG_ORANGE}${dockerfile_fpath}${DOCKER__NOCOLOR}"
    echo -e "\r"

    sudo sh -c "${dockercmd}" #execute cmd
    docker__validate_exitCode__func   #check if cmd ran successfully

    echo -e "\r"
        sudo sh -c "docker image ls"    #show Docker IMAGE list
    echo -e "\r"
    echo -e "\r"
}
function docker__validate_exitCode__func() {
    exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        echo -e "\r"
        echo -e "script was executed ${DOCKER__SUCCESS_FG_LIGHTGREEN}successfully${DOCKER__NOCOLOR}..."
        echo -e "\r"

    else
        echo -e "\r"
        echo -e "***${DOCKER__ERROR_FG_LIGHTRED}ERROR${DOCKER__NOCOLOR}: script was stopped due to an error occurred..."
        echo -e "\r"
        echo -e "Please resolve the issue..."
        echo -e "\r"
        echo -e "${DOCKER__EXITING_NOW}"
        echo -e "\r"
        echo -e "\r"

        exit
    fi
}




#---MAIN SUBROUTINE
main_sub() {
    docker__load_header__sub

    docker__load_environment_variables__sub

    docker__mandatory_apps_check__sub

    docker__show_dockerList_files__sub

    docker__create_image_handler__sub
}



#---EXECUTE
main_sub
