function setup_ca {

    if [[ -z $cmd ]]; then
        echo
        echo "It appears that you haven't yet set up a certificate authority."
        echo "Please press Enter to do it now or Ctrl+C to abort."
        read e
    fi

    echo "Setting up folder structure."
    mkdir -p $data/{all,crl}
    mkdir -p $root/{public,private,requests,crl}
    chmod 700 $root/private
    touch $root/index.txt
    echo 01 > $root/serial
    
    if [[ -z $cmd ]]; then
        echo
        echo "Please provide some details about yourself. Note that "
        echo "all data should be entered in printable 7-bit ASCII "
        echo "only."
        echo
    fi
    if [[ -z $country ]]; then
        read -e -p "Country name (2 characters)     : " country
    fi
    if [[ -z $province ]]; then
        read -e -p "State or province name          : " province
    fi
    if [[ -z $locality ]]; then
        read -e -p "Locality (city)                 : " locality
    fi
    if [[ -z $organisation ]]; then
        read -e -p "Organisation name               : " organisation
    fi
    if [[ -z $unit ]]; then
        read -e -p "Organisational unit name        : " unit
    fi
    if [[ -z $email ]]; then
        read -e -p "Email address                   : " email
    fi
    if [[ -z $url ]]; then
        read -e -p "URL for CRL (no trailing slash) : " url
    fi
    echo

    echo "Country           : " $country
    echo "State or province : " $province
    echo "Locality          : " $locality
    echo "Organisation      : " $organisation
    echo "Unit              : " $unit
    echo "Email             : " $email
    echo "CRL               : " $url

    while true && [[ -z $cmd ]]
    do
        echo -n "Please confirm these settings (y or n) :"
        read CONFIRM
        case $CONFIRM in
            y|Y|YES|yes|Yes)
                break ;;
            n|N|no|NO|No)
                echo
                echo Aborting. Run this script again to retry.
                echo
                exit
                ;;
        esac
    done    
    
    echo 
    echo "Generating template configuration file."
    cat "$include/template_dist.conf" | \
        sed "s|===COUNTRY===|$country|" | \
        sed "s|===PROVINCE===|$province|" | \
        sed "s|===LOCALITY===|$locality|" | \
        sed "s|===ORGANISATION===|$organisation|" | \
        sed "s|===UNIT===|$unit|" | \
        sed "s|===EMAIL===|$email|" | \
        sed "s|===URL===|$url|" > "$data/template.conf"
        
    
    echo "Generating root CA private key. This may take a while."
    pushd "$root"
    openssl genrsa -des3 -passout pass:012345678 -out private/ca.key 4096
    
    echo "Generating temporary root configuration file."
    cat "$data/template.conf" | \
        sed "s|===COMMONNAME===|$organisation root CA|" | \
        sed "s|===CANAME===|root|" | \
        sed "s|CA:true|critical,CA:true|"> "$data/temp_root.conf"
                
    echo "Generating the root CA certificate."
    openssl req -batch -config "$data/temp_root.conf" -new -x509 -extensions v3_ca \
        -passin pass:012345678 -days 9125 -key "$root/private/ca.key" -out "$root/public/ca.crt"
    
    openssl x509 -in "$root/public/ca.crt" -out "$root/public/ca.pem" -outform PEM

    echo "Removing temporary configuration file."
    rm "$data/temp_root.conf"

    # Copy certificate
    cp public/ca.{crt,pem} "$data/all/"

    popd
}
