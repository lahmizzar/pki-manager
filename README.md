pki-manager
===========

Commandline tool for building and managing a 3-tier PKI infrastructure.

I tried to keep the logic very simple and modular. The wrapper scripts are just there to set some important vars and then run every step through for building a CA or certificate where normaly a couple of commands where needed.

CA types:

 1. Root CA - CA at the root of the hierarchy. Issues only CA certificates.

 2. Intermediate CA - CA below the root CA. Not for signing user certificates. Issues only signing CA certificates.

 3. Signing CA - Last part of the hierachy. Issues only user certificates. 

File formats:

 - PEM - Base-64 encoded data with header and footer. Default output of OpenSSL and prefered by common software.

 - DER - Binary format which is prefered by windows. Also official format of certificates and CRLs.

File types:

 - .cfg - config files

 - .csr - certification signing request

 - .key - private key

 - .crt - signed certificate

 - .crl - certficate revokation list

 - .cer - certficate in der format

 - .p7c - bundle of two or more certificates in DER format

 - *-bundle.pem - User certificate including ca-chain

 - *-ca-chain.crt - CA-chain informations

 - .db - Database file containing informations about signed certificates

 - .crt.srl - Serial number file about current signed certificates

 - .crl.srl - Serial number file about current CRLs

Folder structure:

 - bin - scripts for managing the PKI

 - ca - CAs will be saved in subdirectorys including CSR, CRT, Key, Pem and a ca-chain Pem file

 - certs - TLS certificates storeing place, includes CSR, CRT, Key and PEM file

 - crl - revokation lists store

 - doc - sample configuration files and additional imformations

 - etc - config dir

 - public - CA files in DER format which are ready for publishing

Manage your PKI
---------------

 1. Create a root-ca

	cp doc/configs/root-ca.cfg etc/sample.cfg

	bash bin/build-ca.sh --root-ca sample

 2. Create your intermediate-ca

	mkdir etc/sample-bu

	cp doc/configs/intermediate-ca etc/sample-bu/sample-bu.cfg

	bash bin/build-ca.sh --sign-with sample --intermediate-ca sample-bu

 3. Create a signing-ca

	cp doc/configs/signing-ca.cfg etc/sample-bu/tls-ca.cfg

	bash bin/build-ca.sh --sign-with sample-bu --signing-ca tls-ca

 4. Create a TLS certificate (eg web server)

	cp doc/configs/tls-server.cfg etc/tls-server.cfg

	bash bin/generate-certificate.sh --server --dn www.sample.org --sign-with tls-ca sample.org

 5. Revoke a certificate

	bash bin/revoke.sh --cert --signed-with tls-ca www.sample.org

Important notes
---------------

 - config files for a root-ca are stored in etc/
 - subfolders in etc/ are keeping intermediate-cas and signing-cas
 - the subfolder and the intermediate-ca have to be named the same
 - don't use dots in file names eg sample.org.cfg (OpenSSL doesn't like that)


This tool is based on the tutorial on http://pki-tutorial.readthedocs.org. At this point a big thanks to Stefan H. Holek who wrote the tutorial. I learned a lot about managing a PKI with OpenSSL. Also he helped me out when I had some questions and emailed him. Thanks Stefan! :)