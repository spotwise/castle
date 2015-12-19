function renew_certificate {
    echo
    echo "To renew a certificate you must specify which subordinate CA that"
    echo "signed the certificate as well as the name of the certificate to"
    echo "renew."
    echo

    echo "These are your subordinate certificate authorities:"
    echo
    
    for d in $(ls $root/sub); do
        sub_ca_crt=$(ls $root/sub/$d/public/ca_*)
        sub_name=$(get_certificate_cn $sub_ca_crt)
        echo "  $d - $sub_name"
    done
    
    echo
    read -e -p "Which subordinate CA signed the certificate (left column) : " ca
    
    if [ ! -d $root/sub/$ca ]; then
        read -e -p "Incorrect subordinate CA name. Press enter to continue."
        return
    fi

    echo "These are the certificates signed by this subordinate CA:"
    echo
    
    for f in $(ls -1 $root/sub/$ca/public/*.crt | grep -v ca_ | sed 's/.*\///'); do
        sub_ca_crt=$(ls $root/sub/$d/public/ca_*)
        cert_name=$(get_certificate_cn $root/sub/$ca/public/$f)
        cert_expiration=$(get_certificate_expiration $root/sub/$ca/public/$f)
        echo "  $f - [$cert_name / $cert_expiration]"
    done
    
    echo
    read -e -p "Which certificate do you want to renew (left column) : " fn_cert
    
    if [ ! -f $root/sub/$ca/public/$fn_cert ]; then
        read -e -p "Incorrect certificate filename. Press enter to continue."
        return
    fi

    cnf=`echo $fn_cert | sed 's/.\crt$//'`

    echo "Creating temporary configuration files."
    cat "$data/template.conf" | \
        sed "s/===CANAME===/$ca/" > "$data/temp_sub.conf"
        
    pushd "$root/sub/$ca"
    
    # Revoke the old certificate
    revoke_impl $ca $cnf

    # Now that the old certificate is revoked we can sign the CSR again
    
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

    rm -f "$data/temp_sub.conf"
    
    # Copy certificates
    cp public/$cnf.crt "$data/all/"
    cp pfx/$cnf.pfx "$data/all/"
    cp pfx/$cnf-single.pfx "$data/all/"
    
    popd
}
