function list_all {

    echo
    echo "Listing all certificate authorities and certificates:"
    echo

    # Root CA
    root_name=$(get_certificate_cn $root/public/ca.crt)
    root_expiration=$(get_certificate_expiration $root/public/ca.crt)
    echo $root_name [$root_expiration]

    for d in $(ls $root/sub 2>/dev/null); do

        sub_ca_crt=$(ls $root/sub/$d/public/ca_*)
        sub_name=$(get_certificate_cn $sub_ca_crt)
        sub_expiration=$(get_certificate_expiration $sub_ca_crt)
        echo "  $sub_name [$sub_expiration]"

        for c in $(ls -1 $root/sub/$d/public/*.crt | grep -v ca_); do

            c_name=$(get_certificate_cn $c)
            c_expiration=$(get_certificate_expiration $c)
            c_status=$(get_certificate_status $d $c_name)
            if [ $c_status != "R" ]; then
                echo "    $c_name [$c_expiration]"
            fi
        done

    done
    
    echo
    read -e -p "Done. Press Enter to continue..."
}
