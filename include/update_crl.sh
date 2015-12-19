function update_crl {

    cat "$data/template.conf" | \
        sed "s|===COMMONNAME===|$organisation root CA|" | \
        sed "s|===CANAME===|root|" | \
        sed "s|CA:true|critical,CA:true|"> "$data/temp_root.conf"

    pushd $root

    # Root CA
    echo "Generating CRL for the root CA."
    openssl ca -gencrl -config "$data/temp_root.conf" -crlexts crl_ext \
        -passin pass:012345678 -keyfile private/ca.key -cert public/ca.crt \
        -out crl/root.crl
    cp crl/root.crl "$data/crl/"

    # Subordinates
    for d in $(ls sub); do    
        sub_ca_crt=$(ls sub/$d/public/ca_*)
        sub_name=$(get_certificate_cn $sub_ca_crt)
        echo "Generating CRL for $sub_name"

        cat "$data/template.conf" | \
            sed "s/===CANAME===/$d/" > "$data/temp_sub.conf"

        pushd sub/$d
        
        openssl ca -gencrl -config "$data/temp_sub.conf" -crlexts crl_ext \
            -passin pass:012345678 -keyfile private/ca_$d.key -cert public/ca_$d.crt \
            -out crl/$d.crl
        cp crl/$d.crl "$data/crl/"
        
        rm -f "$data/temp_sub.conf"

        popd
    done

    rm -f "$data/temp_root.conf"
    
    popd
}
