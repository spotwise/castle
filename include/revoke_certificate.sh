function revoke_certificate {
    echo
    echo "To revoke a certificate you must specify which subordinate CA that"
    echo "signed the certificate as well as the name of the certificate to"
    echo "revoke."
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
        cert_status=$(get_certificate_status $ca $cert_name)
        if [ $cert_status != "R" ]; then
            echo "  $f - [$cert_name / $cert_expiration]"
        fi
    done
    
    echo
    read -e -p "Which certificate do you want to revoke (left column) : " fn_cert
    
    if [ ! -f $root/sub/$ca/public/$fn_cert ]; then
        read -e -p "Incorrect certificate filename. Press enter to continue."
        return
    fi

    cnf=`echo $fn_cert | sed 's/.\crt$//'`

    revoke_impl $ca $cnf
}
