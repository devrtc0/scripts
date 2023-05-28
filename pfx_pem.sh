openssl pkcs12 -in <keystore.pfx> -nocerts -nodes | sed -ne '/-BEGIN PRIVATE KEY-/,/-END PRIVATE KEY-/p' > <clientcert.key>
openssl pkcs12 -in <keystore.pfx> -clcerts -nokeys | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > <clientcert.cer>
openssl pkcs12 -in <truststore.pfx> -cacerts -nokeys -chain | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > <cacerts.cer>
