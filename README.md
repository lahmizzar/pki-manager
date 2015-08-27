# pki-manager
Commandline tool for building and managing a 3-tier PKI infrastructure.

## Example build for Sample Inc
### Create config files
There are several config samples in ```doc/configs``` which can be used. But don't forget to edit them.
*Note that the names of the config files will play an important role in the following steps!*

	cp doc/configs/root-ca.cfg etc/sample.cfg
	mkdir etc/business-unit-a
	cp doc/configs/intermediate-ca.cfg etc/business-unit-a/business-unit-a.cfg
	cp doc/configs/signing-ca.cfg etc/business-unit-a/department-a.cfg

	cp doc/configs/tls-server.cfg etc/tls-server.cfg
	cp doc/configs/tls-client.cfg etc/tls-client.cfg

Root CA config files are stored in ```etc/```. Create for every business-unit, division or subsidiary a new folder in ```etc/``` and put there the config file for the intermediate CA. It's important that they are named the same! The config file for the signing CA goes now into the same folder of the intermediate CA which should sign it.
TLS server and client configs are stored beside the root CA.

That was the heaviest part of it. If you followed this step the next steps will be very easy.

### Create a root CA
	bash bin/build-ca.sh --root-ca sample

### Create your intermediate CA
	bash bin/build-ca.sh --sign-with sample --intermediate-ca business-unit-a

### Create a signing CA
	bash bin/build-ca.sh --sign-with business-unit-a --signing-ca department-a

### Create a TLS certificate (eg web server with additional domain names)
	bash bin/generate-certificate.sh --server --dn www.sample.org --sign-with department-a --unit business-unit-a sample.org

### Revoke a certificate
	bash bin/revoke.sh --unit business-unit-a --signed-with department-a sample.org

## Additional information
### CA types:
 1. Root CA - CA at the root of the hierarchy. Issues only CA certificates.
 2. Intermediate CA - CA below the root CA. Not for signing user certificates. Issues only signing CA certificates.
 3. Signing CA - Last part of the hierachy. Issues only user certificates. 

### File formats:
 - PEM - Base-64 encoded data with header and footer. Default output of OpenSSL and prefered by common software.
 - DER - Binary format which is prefered by windows. Also official format of certificates and CRLs.

### File types:
 - .cfg - config files
 - .csr - certification signing request
 - .key - private key
 - .crt - signed certificate
 - .crl - certficate revokation list
 - .cer - certficate in der format
 - .p7c - bundle of two or more certificates in DER format
 - *-bundle.pem - User certificate including CA chain
 - *-ca-chain.crt - CA chain informations
 - .db - Database file containing informations about signed certificates
 - .crt.srl - Serial number file about current signed certificates
 - .crl.srl - Serial number file about current CRLs

### Folder structure:
 - bin - scripts for managing the PKI
 - ca - CAs will be saved in subdirectorys including CSR, CRT, Key, Pem and a ca-chain file
 - certs - TLS certificates storeing place, includes CSR, CRT, Key and PEM file
 - crl - revokation lists store
 - doc - sample configuration files and additional imformations
 - etc - config dir
 - public - CA files in DER format which are ready for publishing

### Important notes
 - don't use dots in file names eg sample.org.cfg (OpenSSL doesn't like that)

## Thanks
This tool is based on the tutorial on http://pki-tutorial.readthedocs.org. At this point a big thanks to Stefan H. Holek who wrote the tutorial. I learned a lot about managing a PKI with OpenSSL. Also he helped me out when I had some questions and emailed him. Thanks Stefan! :)
