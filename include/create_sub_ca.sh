function create_sub_ca {

    if [[ -z $sub ]]; then
        echo
        echo "Subordinate certificate authorities are signed by the root CA and "
        echo "are used to sign certificates. You must enter the name of the "
        echo "subordinate CA. The name will be suffixed by \" CA\" and assigned "
        echo "as common name for the certificate."
        echo
        echo "N.B. This script does not allow spaces in the name."
        echo
        read -e -p "Please enter the name of the subordinate CA : " sub
        echo
    fi

    # Change name to lower case and convert space to underscore for file operations
    sublc=`echo $sub | tr [:upper:] [:lower:] | tr " " "_"`
        
    if [ -d "$root/sub/$sublc" ]; then
        echo
        echo "The subordinate CA already exists!"
        echo
        read e
        return
    fi

    if [[ -z $sub ]]; then
        while true
        do
            echo "WARNING: You are creating a new subordinate CA with the common name \"$sub CA\"."
            echo
            echo "Please confirm by typing YES :"
            read CONFIRM
            case $CONFIRM in
                YES|yes|Yes)
                    break ;;
                *)
                    echo
                    read -e -p "Aborting. Press enter to continue."
                    echo
                    return
                    ;;
            esac
        done
    fi

    echo
    echo "Creating temporary configuration files."
    cat "$data/template.conf" | \
        sed "s/===COMMONNAME===/$sub CA/" | \
        sed "s/===CANAME===/$sublc/" > "$data/temp_sub.conf"
    cat "$data/template.conf" | \
        sed "s|===COMMONNAME===|$organisation root CA|" | \
        sed "s|===CANAME===|root|" | \
        sed "s|CA:true|critical,CA:true|"> "$data/temp_root.conf"
                
    echo "Setting up folder structure."
    mkdir -p "$root/sub/$sublc"/{public,private,requests,crl,pfx}
    chmod 700 "$root/sub/$sublc/private" 
    touch "$root/sub/$sublc/index.txt"
    echo 01 > "$root/sub/$sublc/serial"
    
    echo "Generating the subordinate CA private key."
    echo
    pushd "$root/sub/$sublc"
    openssl genrsa -des3 -passout pass:012345678 -out private/ca_$sublc.key 2048

    echo "Generating the subordinate CA CSR."
    echo
    openssl req -batch -config "$data/temp_sub.conf" -new -passin pass:012345678 \
        -key private/ca_$sublc.key -out requests/ca_$sublc.csr

    echo
    echo "Signing the subordinate CSR by the root CA."
    echo
    cp requests/ca_$sublc.csr "$root/requests/"
    cd "$root"
    
    openssl ca -batch -policy policy_match -config "$data/temp_root.conf" \
        -passin pass:012345678 -cert public/ca.crt \
        -in requests/ca_$sublc.csr -keyfile private/ca.key -days 5475 \
        -out public/ca_$sublc.crt -extensions v3_ca

    openssl x509 -in "public/ca_$sublc.crt" -out "public/ca_$sublc.pem" -outform PEM

    cp public/ca_$sublc.{crt,pem} "$root/sub/$sublc/public"

    rm -f "$data/temp_root.conf"
    rm -f "$data/temp_sub.conf"

    # Copy certificate
    cp public/ca_$sublc.{crt,pem} "$data/all/"

    popd 
}
