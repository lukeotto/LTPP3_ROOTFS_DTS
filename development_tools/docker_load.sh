#!/bin/bash -m
#Remark: by using '-m' the INT will NOT propagate to the PARENT scripts
#--SUBROUTINES
docker__load_environment_variables__sub() {
    #---Define PATHS
    docker__current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    docker__current_dir=$(dirname ${docker__current_script_fpath})
    if [[ ${docker__current_dir} == ${DOCKER__DOT} ]]; then
        docker__current_dir=$(pwd)
    fi
    docker__current_folder=`basename ${docker__current_dir}`

    docker__development_tools_folder="development_tools"
    if [[ ${docker__current_folder} != ${docker__development_tools_folder} ]]; then
        docker__my_LTPP3_ROOTFS_development_tools_dir=${docker__current_dir}/${docker__development_tools_folder}
    else
        docker__my_LTPP3_ROOTFS_development_tools_dir=${docker__current_dir}
    fi

    docker__global__filename="docker_global.sh"
    docker__global__fpath=${docker__my_LTPP3_ROOTFS_development_tools_dir}/${docker__global__filename}



    docker__image_fPath=${DOCKER__EMPTYSTRING}
}

docker__load_source_files__sub() {
    source ${docker__global__fpath}
}

docker__load_header__sub() {
    show_header__func "${DOCKER__TITLE}" "${DOCKER__TABLEWIDTH}" "${DOCKER__BG_ORANGE}" "${DOCKER__NUMOFLINES_2}" "${DOCKER__NUMOFLINES_0}"
}

docker__load_constants__sub() {
    #Define phase constants
    DOCKER__SELECT_SRC_DIR=0
    DOCKER__LOAD_PHASE=1
    DOCKER__SHOW_UPDATED_IMAGE_LIST_PHASE=2

    #Define message constants
    DOCKER__MENUTITLE="${DOCKER__FG_YELLOW}Import${DOCKER__NOCOLOR} an ${DOCKER__FG_BORDEAUX}Image${DOCKER__NOCOLOR} file"
    DOCKER__READDIALOG_CHOOSE_TARGET_DIR="Choose src-fullpath: "

    #Define numeric constants
    #Remark:
    #   (DOCKER__LEADING_ECHOMSG_LEN) is the length of echo-msg '---:COMPLETED: Exporting image ' including: one space ( ), two quotes (')
    DOCKER__LEADING_ECHOMSG_LEN=33
}

docker__init_variables__sub() {
    docker__answer=${DOCKER__EMPTYSTRING}
    docker__image_fpath=${DOCKER__EMPTYSTRING}
    docker__image_fpath_print=${DOCKER__EMPTYSTRING}
    docker__imageID_chosen=${DOCKER__EMPTYSTRING}
    docker__repo_chosen=${DOCKER__EMPTYSTRING}
    docker__tag_chosen=${DOCKER__EMPTYSTRING}

    docker__images_cmd="docker images"

    docker__images_repoColNo=1
    docker__images_tagColNo=2
    docker__images_IDColNo=3

    docker__onEnter_breakLoop=false
    docker__showTable=true
}

docker__load_handler__sub() {
    #Define variables
    local echomsg=${DOCKER__EMPTYSTRING}
    local phase=${DOCKER__EMPTYSTRING}

    #Set initial 'phase'
    phase=${DOCKER__SELECT_SRC_DIR}
    while true
    do
        case "${phase}" in
            ${DOCKER__SELECT_SRC_DIR})
                #Show and select directory
	            ${dirlist__readInput_w_autocomplete__fpath} "${DOCKER__EMPTYSTRING}" \
						"${docker__docker_images__dir}" \
						"${DOCKER__READDIALOG_CHOOSE_TARGET_DIR}" \
						"${DOCKER__DIRLIST_REMARKS}" \
                        "${dirlist__dst_ls_1aA_output__fpath}" \
                        "${dirlist__dst_ls_1aA_tmp__fpath}" \
						"${DOCKER__EMPTYSTRING}" \
                        "${DOCKER__FALSE}"

                #Get the exitcode just in case:
                #   1. Ctrl-C was pressed in script 'docker__readInput_w_autocomplete__fpath'.
                #   2. An error occured in script 'docker__readInput_w_autocomplete__fpath',...
                #      ...and exit-code = 99 came from function...
                #      ...'show_msg_w_menuTitle_w_pressAnyKey_w_ctrlC_func' (in script: docker__global.sh).
                docker__exitCode=$?
                if [[ ${docker__exitCode} -eq ${DOCKER__EXITCODE_99} ]]; then
                    exit__func "${docker__exitCode}" "${DOCKER__NUMOFLINES_2}"
                else
                    #Retrieve the selected container-ID from file
                    docker__path_output=`get_output_from_file__func "${dirlist__readInput_w_autocomplete_out__fpath}" "${DOCKER__LINENUM_1}"`
                    docker__numOfMatches_output=`get_output_from_file__func "${dirlist__readInput_w_autocomplete_out__fpath}" "${DOCKER__LINENUM_2}"`
                fi

                if [[ -f ${docker__path_output} ]]; then    #is a file
                    #Generate 'docker__image_fpath'
                    docker__image_fpath="${docker__path_output}"

                    #Replace multiple slashes with a single slash (/)
                    docker__image_fpath=`subst_multiple_chars_with_single_char__func "${docker__image_fpath}" \
                                    "${DOCKER__ESCAPED_SLASH}" \
                                    "${DOCKER__ESCAPED_SLASH}"`

                    #Set the maximum allowed string-length for 'docker__image_fpath_print'
                    docker__image_fpath_print_maxLen=$((DOCKER__TABLEWIDTH - DOCKER__LEADING_ECHOMSG_LEN))

                    #Resize 'docker__image_fpath' in order to fit into table-size 'DOCKER__TABLEWIDTH'
                    docker__image_fpath_print=`trim_string_toFit_specified_windowSize__func \
                            "${docker__image_fpath}" \
                            "${docker__image_fpath_print_maxLen}" \
                            "${DOCKER__TRUE}"`

                    echomsg="---:${DOCKER__FG_ORANGE}SOURCE${DOCKER__NOCOLOR}: ${DOCKER__FG_LIGHTGREY}${docker__image_fpath_print}${DOCKER__NOCOLOR}"
                    show_msg_only__func "${echomsg}" "${DOCKER__NUMOFLINES_1}"

                    #Goto next-phase
                    phase=${DOCKER__LOAD_PHASE}
                else    #is a directory
                    show_msg_wo_menuTitle_w_PressAnyKey__func "${DOCKER__INVALID_OR_NOT_A_FILE}" \
                                "${DOCKER__NUMOFLINES_1}" \
                                "${DOCKER__TIMEOUT_10}" \
                                "${DOCKER__NUMOFLINES_1}" \
                                "${DOCKER__NUMOFLINES_1}"  
                fi
                ;;
            ${DOCKER__LOAD_PHASE})
                moveDown_and_cleanLines__func "${DOCKER__NUMOFLINES_1}"

                while true
                do
                    read -N1 -p "${DOCKER__READDIALOG_DO_YOU_WISH_TO_CONTINUE_YN}" docker__answer
                    if  [[ "${docker__answer}" == "${DOCKER__Y}" ]]; then
                        moveDown_and_cleanLines__func "${DOCKER__NUMOFLINES_3}"

                        echomsg="---:${DOCKER__FG_ORANGE}START${DOCKER__NOCOLOR}: Importing image '${DOCKER__FG_LIGHTGREY}${docker__image_fpath_print}${DOCKER__NOCOLOR}'\n"
                        echomsg+="------:${DOCKER__FG_ORANGE}INFO${DOCKER__NOCOLOR}: Depending on the image size...\n"
                        echomsg+="------:${DOCKER__FG_ORANGE}INFO${DOCKER__NOCOLOR}: This may take a while...\n"
                        echomsg+="------:${DOCKER__FG_ORANGE}INFO${DOCKER__NOCOLOR}: Please wait..."
                        show_msg_only__func "${echomsg}" "${DOCKER__NUMOFLINES_0}"

                        #Save image to 'docker__image_fpath'
                        docker image load --input ${docker__image_fpath} > /dev/null

                        echomsg="---:${DOCKER__FG_ORANGE}COMPLETED${DOCKER__NOCOLOR}: Importing image '${DOCKER__FG_LIGHTGREY}${docker__image_fpath_print}${DOCKER__NOCOLOR}'"
                        show_msg_only__func "${echomsg}" "${DOCKER__NUMOFLINES_0}"

                        #Goto next-phase
                        phase=${DOCKER__SHOW_UPDATED_IMAGE_LIST_PHASE}

                        break
                    elif  [[ "${docker__answer}" == "${DOCKER__N}" ]]; then
                        moveDown_and_cleanLines__func "${DOCKER__NUMOFLINES_3}"

                        #Goto next-phase
                        phase=${DOCKER__SELECT_SRC_DIR}

                        break
                    else    #Empty String
                        if [[ "${docker__answer}" != "${DOCKER__ENTER}" ]]; then    #no ENTER was pressed
                            moveDown_oneLine_then_moveUp_and_clean__func "${DOCKER__NUMOFLINES_1}"
                        else    #ENTER was pressed
                            moveUp_and_cleanLines__func "${DOCKER__NUMOFLINES_1}"
                        fi
                    fi
                done
                ;;
            ${DOCKER__SHOW_UPDATED_IMAGE_LIST_PHASE})
                #Show repo-list
                show_repository_or_container_list__func "${DOCKER__MENUTITLE_UPDATED_REPOSITORYLIST}" \
                                    "${DOCKER__ERRMSG_NO_IMAGES_FOUND}" \
                                    "${docker__images_cmd}" \
                                    "${DOCKER__NUMOFLINES_2}" \
                                    "${DOCKER__TIMEOUT_10}" \
                                    "${DOCKER__NUMOFLINES_0}" \
                                    "${DOCKER__NUMOFLINES_0}"

                exit__func "${DOCKER__EXITCODE_0}" "${DOCKER__NUMOFLINES_0}"
                ;;
        esac
    done
}





#---MAIN SUBROUTINE
main_sub() {
    docker__load_environment_variables__sub

    docker__load_source_files__sub

    docker__load_header__sub

    docker__load_constants__sub

    docker__init_variables__sub

    docker__load_handler__sub
}



#---EXECUTE
main_sub
