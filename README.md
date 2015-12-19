# Castle

This projects includes a set of tools to create and manage a private certificate authority. It is typically used to roll your own CA to create certificates for web servers, mail servers etc. Certificates created with this tool can be used with a wide range of software. It has been tested on Nginx, Apache, Subversion, Postfix, Dovecot, Microsoft IIS, Microsoft Exchange.

The tool comes with some limitations; the hierarchy will be two levels deep. Not more and not less. In other words you will get a root certificate authority and one or more subordinate certificate authorities. User certificates will be signed by one of the subordinate CAs. Also, while it supports subject alternative names it only does so for DNS names. For real-world certificate authorities the certificate signing requests (CRSs) are normally created externally to the certificate authority so that the private key is not shared with the outside world. Since this tool is based on the assumption that there is one person managing both the CA and the web server it maintains all of the certificates and the key. For that reason it is imperative to keep access to the CA folder structure secure so that the private keys are not compromised.

To use, run the 'ca' script in this folder. Normally this script is used without arguments. For examples of providing arguments, please refer to the Bash code.
