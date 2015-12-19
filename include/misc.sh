function get_certificate_cn() {
    cn=`openssl x509 -text -in "$1" | grep Subject: | awk -F 'CN=' '{ print $2 }' | awk -F '/' '{ print $1 }'`
    echo $cn
}

function get_certificate_expiration() {
    exp=`openssl x509 -text -in "$1" | grep 'Not After'`
    echo ${exp#*:}
}

function get_certificate_status() {
    # $1 = CA name
    # $2 = CN name
    caf=`echo $1 | sed "s/ /_/g"`
    stat=`cat "$root/sub/$caf/index.txt" | grep "CN=$2" | tail -n 1`
    echo ${stat:0:1}
}

function revoke_impl {
    # $1 = CA name
    # $2 = certificate filename base
    caf=`echo $1 | sed "s/ /_/g"`
    
    pushd "$root/sub/$caf"
    
    echo "Creating temporary configuration files."
    cat "$path/template.conf" | \
        sed "s/===CANAME===/$1/" > "$path/temp_sub_revoke.conf"
            
    openssl ca -config "$path/temp_sub_revoke.conf" \
        -cert public/ca_$caf.crt  -keyfile private/ca_$caf.key \
        -passin pass:012345678 -revoke public/$2.crt
        
    # Remove files (do not remove CSR and key)
    rm public/$2.crt
    rm $path/all/$2*
        
    popd
    rm -f "$path/temp_sub_revoke.conf"    
}

function backup {

    dt=`date -u +%Y%m%d-%H%M%S`
    fn="$dt.tar.gz"
    
    mkdir -p "$path/backup"
    
    # Note: Some implementations of 'tar' does not include the --transform option.
    # This script checks the exit code of tar and runs the command without the
    # transformation if this is the case. 
    tar -cvzf "$path/backup/$fn" --transform "s|^|/$dt/|" --directory "$path" --exclude backup* *
    
    if [ $? -ne 0 ]; then
        tar -cvzf "$path/backup/alt_$fn" --directory "$path" --exclude backup* *
        echo
        echo "NOTE: Your 'tar' command does not support file name transformation."
        echo "Check the structure of the archive before unpacking the archive."
    fi

    echo
    read -e -p "Press enter to continue."
}

function clean {
    while true
    do
        echo -n "WARNING! Do you want to wipe all settings (yes or no) : "
        read CONFIRM
        case $CONFIRM in
            YES|yes|Yes)
                break ;;
            no|NO|No)
                echo
                echo Aborting. Run this script again to retry.
                echo
                return
                ;;
        esac
    done    
    
    while true
    do
        echo -n "WARNING! You are wiping all settings. Do you want to abort (yes or no) : "
        read CONFIRM
        case $CONFIRM in
            no|NO|No)
                break ;;
            YES|yes|Yes)        
                echo
                echo Aborting. Run this script again to retry.
                echo
                return
                ;;
        esac
    done    
    
    pushd "$path"
    
    rm -rf $data
    
    popd
}
