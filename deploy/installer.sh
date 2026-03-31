#!/usr/bin/env bash

# there are manual steps for a device:
#  1 - download and set up the id_ed25519 key
#  2 - download and execute this script on device

cleanup() {
    rm -r $1
}

usage() {
    echo "Usage $0 [-v] -a app -w working directory -d destination directory"
}

# $1 : app we're setting up
# $2 : working folder
prepare_working_dir() {
    local app="$1"
    local working="$2"
    
    if [ ! -d $1 ]; then
        mkdir -p $working > /dev/null
    else
        rm -r $working/* 2> /dev/null
        rm -r $working/.* 2> /dev/null
    fi

    pushd $working > /dev/null

    if [ ! -f download_artifact.rb ]; then
        wget -q https://raw.githubusercontent.com/csolallo/Termux-shared/refs/heads/main/deploy/download_artifact.rb
    fi
    if [ ! -f parse_token_file.awk ]; then
        wget -q https://raw.githubusercontent.com/csolallo/Termux-shared/refs/heads/main/deploy/parse_token_file.awk
    fi

    # download keys from github (you'll need the id_ed25519 ssh deploy key set up)
    git clone git@github.com:csolallo/Keys-and-Tokens.git
    mv ./Keys-and-Tokens/tokens.txt ./Keys-and-Tokens/"${app}"/* ./Keys-and-Tokens/"${app}"/.* .

    rm -rf ./Keys-and-Tokens

    download_token=$(awk -f parse_token_file.awk -v token=archive-download tokens.txt)
    if [ "$verbose" == "1" ]; then
        echo "$download_token"
    fi
    APP="$app" TOKEN="$download_token" SSL_CERT_DIR="$SSL_CERT_DIR" SSL_CERT_FILE="${SSL_CERT_FILE}" ruby ./download_artifact.rb

    popd
}

# $1 : app we are installing
# $2 : working dir
function prepare_build() {
    local app="$1"
    local working="$2"

    pushd $working

    # always named the same
    unzip archive.tar.gz.zip
    tar -xvf archive.tar.gz

    prepare_app_build "$app" "$working"

    popd
}

# $1 : working folder
# $2 : destination folder
#move_to_destination() {
#    mkdir -p $2/groceries && cp -a $1/scripts/. $2/groceries
#}

# $1 : destination folder
# create_helper_script() {
#     sc=$(cat <<EOF
# #!/data/data/com.termux/files/usr/bin/bash

# pushd ~/.termux/tasker/groceries > /dev/null
# SSL_CERT_DIR=${SSL_CERT_DIR} SSL_CERT_FILE=${SSL_CERT_FILE} bundle exec ruby driver.rb \$1
# popd > /dev/null

# rm /data/data/com.termux/files/home/storage/shared/Documents/Xfer/copied-*
# EOF
# )
#     if [ "$verbose" == "1" ]; then
#         echo "$sc"
#     fi
#     echo "$sc" > groceries.sh
#     chmod +x groceries.sh
# }

while getopts "a:w:d:hv" opt; do
    case "$opt" in
        a)
        app=$OPTARG
        ;;
        w) 
        working=$OPTARG
        ;;
        d)
        dest=$OPTARG
        ;;
        v)
        verbose=1
        ;;
        h)
        usage
        exit 0
        ;;
    esac
done

if [ -z "$app" -o -z "$working" -o -z "$dest" ]; then
    exit -1
fi

source "./$app-setup.sh"

# test to ensure required functions are exported
expected_funcs=("prepare_app_build")
for func in "${expected_funcs[@]}"; do
    if [[ -z "$(declare -p -f $func)" ]]; then
        echo "required function $func not present in setup file"
        exit -1
    fi
done

echo "Step 1: prepare working folder" 
echo "----------------------------------------------------------------"
prepare_working_dir "$app" "$working"
if [[ $? -ne 0 ]]; then
   cleanup "$working"
   exit -1
fi

echo "Step 2: prepare a build"
echo "----------------------------------------------------------------"
prepare_build "$app" "$working"
#create_helper_script "$dest"

echo "Step 3: deploy to destination folder"
echo "----------------------------------------------------------------"
#move_to_destination "$working" "$dest"
echo "Done"

# cleanup "$working"
