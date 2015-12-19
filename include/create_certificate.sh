function create_certificate {

    echo
    echo "You are creating a new certificate. The certificate will be "
    echo "signed by one of your subordinate CAs. The subordinate CA must be "
    echo "set up prior to creating the certificate. The common name of the "
    echo "certificate should normally match the hostname part of a URL, a "
    echo "mail server or similar."
    echo
    echo "N.B. This script does not allow spaces in the common name."
    echo

    echo "These are your subordinate certificate authorities:"
    echo
    
    for d in $(ls $root/sub); do
        sub_ca_crt=$(ls $root/sub/$d/public/ca_*)
        sub_name=$(get_certificate_cn $sub_ca_crt)
        echo "  $d - $sub_name"
    done
    
    if [[ -z $ca ]]; then
        echo
        read -e -p "Which subordinate CA should sign the new certificate (left column) : " ca
    fi
    
    if [ ! -d $root/sub/$ca ]; then
        read -e -p "Incorrect subordinate CA name. Press enter to continue."
        return
    fi

    if [[ -z $cn ]]; then
        echo
        read -e -p "What common name should the new certificate have : " cn
    fi

    if [[ -z $alt ]]; then
        echo
        echo "What alternative names should the certificate include (if any)?"
        echo "Note that only DNS names are supported. Just press enter to skip"
        echo "adding alternative names."
        read -e alt
        echo
    fi
    
    # A little roundabout way of doing it. We want to have email:move as SubjectAltNames
    # in most cases but when the user has specified a list of names we want to replace it
    # with them instead.
    if [ ! -z $alt ]; then
        alt=`echo $alt | sed "s/,/,DNS:/g" | awk '{ print "DNS:" $0 }'`
    else
        alt="email:move"
    fi

    if [[ -z $cmd ]]; then
        while true
        do
            echo "WARNING: You are creating a new certificate with the common name \"$cn\"."
            echo
            echo "Please confirm by typing YES :"
            read CONFIRM
            case $CONFIRM in
                YES|yes|Yes)
                    break ;;
                *)
                    echo
                    read -e -p "Aborting."
                    echo
                    return
                    ;;
            esac
        done
    fi
    
    cnf=`echo $cn | tr '.' '_'`    
    
    echo "Creating temporary configuration files."
    cat "$data/template.conf" | \
        sed "s/===COMMONNAME===/$cn/" | \
        sed "s/===CANAME===/$ca/" | \
        sed "s/email:move/$alt/" > "$data/temp_sub.conf"
        
    echo
    echo "Generating a CSR"
    pushd "$root/sub/$ca"
    openssl req -batch -nodes -new -passout pass:012345678 -keyout private/$cnf.key \
        -out requests/$cnf.csr -config "$data/temp_sub.conf"

    echo "Signing the CSR by the subordinate CA"
    echo
    openssl ca -batch -policy policy_match -config "$data/temp_sub.conf" \
        -passin pass:012345678 -cert public/ca_$ca.crt -in requests/$cnf.csr \
        -keyfile private/ca_$ca.key -days 1825 -out public/$cnf.crt

    echo
    echo "Creating a .pfx file with all certificates from the certificate chain"
    echo
    cat "$root/public/ca.crt" public/ca_$ca.crt > temp.crt
    openssl pkcs12 -export -nodes -passout pass: \
        -in public/$cnf.crt -inkey private/$cnf.key -certfile temp.crt -out pfx/$cnf.pfx
    openssl pkcs12 -export -nodes -passout pass: \
        -in public/$cnf.crt -inkey private/$cnf.key -out pfx/$cnf-single.pfx
    rm temp.crt

    openssl x509 -in "public/$cnf.crt" -out "public/$cnf.pem" -outform PEM

    rm -f "$data/temp_sub.conf"
    
    # Copy certificates and keys
    cp private/$cnf.key "$data/all/"
    cp public/$cnf.{crt,pem} "$data/all/"
    cp pfx/$cnf.pfx "$data/all/"
    cp pfx/$cnf-single.pfx "$data/all/"
    
    popd
}
