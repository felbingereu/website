# OpenSSL
## Create certificate authority (ca)
1. Create private key

    === "RSA"

        ```shell
        # with passphrase
        openssl genrsa -aes256 -passout pass:{password} -out ca.key 8192

        # without passphrase
        openssl genrsa -out ca.key 8192
        ```

    === "ECDSA"

        ```shell
        openssl ecparam -name prime256v1 -genkey -noout -out ca.key
        ```

    === "ED25519"

        ```shell
        # with passphrase
        openssl genpkey -algorithm ED25519 -aes256 -pass pass:{password} -out ca.key

        # without passphrase
        openssl genpkey -algorithm ED25519 -out ca.key
        ```

2. Create certificate

    ```shell
    openssl req -x509 -sha512 -subj /CN=ca -new -days 1 -noenc -extensions v3_ca -key ca.key -out ca.pem
    ```

## Create tls server certificate
1. Create private key

    === "RSA"

        ```shell
        # with passphrase
        openssl genrsa -aes256 -passout pass:{password} -out server.key 8192

        # without passphrase
        openssl genrsa -out server.key 8192
        ```

    === "ECDSA"

        ```shell
        openssl ecparam -name prime256v1 -genkey -noout -out server.key
        ```

    === "ED25519"

        ```shell
        # with passphrase
        openssl genpkey -algorithm ED25519 -aes256 -pass pass:{password} -out server.key

        # without passphrase
        openssl genpkey -algorithm ED25519 -out server.key
        ```

2. Create certificate

    ```shell
    # selfsigned
    openssl req -x509 -sha512 -subj /CN=server -new -days 1 -key server.key -out server.pem

    # ca signed
    openssl req -sha512 -subj /CN=server -new -key server.key -out server.csr
    openssl x509 -sha512 -req -in server.csr -days 1 -CA ca.pem -CAkey ca.key -out server.crt
    ```

    You can also add subjectAltNames:
    ```shell
    openssl x509 -sha512 -req -in server.csr -days 1 -CA ca.pem -CAkey ca.key -out server.crt \
      -extfile <(echo 'subjectAltName = DNS:example.com')
    ```

!!! note "Verification of certificate chain"
    If you signed your certificate with a CA, you can verify the chain using:
    ```shell
    openssl verify -CAfile ca.pem server.pem
    ```

<!--
2. Create certificate signing request

    === "RSA"

        ```shell
        openssl req -subj /CN=server -key server.key -new -out server.csr -sha512
        ```

3. Sign certificate


    === "RSA"

        ```shell
        # self signed (by private key)
        openssl x509 -sha512 -req -in server.csr -days 1 -signkey server.key -out server.crt

        # signed by a ca
        openssl x509 -sha512 -req -in server.csr -days 1 -CA ca.pem -CAkey ca.key -out server.pem
        ```

=== "ED25519"

       ```shell
       openssl req -key server.key -new -out server.csr
       ```

       ```shell
       openssl x509 -req -in server.csr -days 1 -signkey server.key -out server.crt
       ```
-->

## Converting keys
### `.pem` to `.crt`
```shell
openssl x509 -in ca.pem -outform der -out ca.crt
```

### `.p12` (pkcs12 keystore container)
```shell
# combind private key and x509 certificate to pkcs12 keystore container
openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12 -name client
```

### Extract files from `.p12` (pkcs12 keystore container)
```shell
# extract ca certificate
openssl pkcs12 -in filename.p12 -out newfile.ca.crt.pem -cacerts -nokeys -chain

# extract certificate
openssl pkcs12 -in filename.p12 -out newfile.crt.pem -clcerts -nokeys

# extract private key
openssl pkcs12 -in filename.p12 -out newfile.key.pem -nocerts -nodes
```

## Extract s/mime certificate from signed email
1. Export signed message from Evolution as mbox file (context menu -> save as file)
2. Extract smime.p7s from .mbox file and add PKCS7 header
   ```
   -----BEGIN PKCS7-----
   MIAGCSqGSIb3DQEHAqCAMIACAQExDzANBglghkgBZQMEAgMFADCABgkqhkiG9w0BBwEAAKCAMIIH
   VjCCBT6gAwIBAgIDSRKYMA0GCSqGSIb3DQEBCwUAMFwxCzAJBgNVBAYTAkRFMRkwFwYDVQQKExBQ
   S0ktMS1WZXJ3YWx0dW5nMRMwEQYDVQQLEwpCdW5kZXN3ZWhyMR0wGwYDVQQDExRCdyBWLVBLSSBD
   ...
   ItC1Jda7G3OItYH1shivhFNKOOK1gSDErsuY8wgLwIExtKEKDhcum2ivwu2Hy0L0/wm5gzG1dUj6
   1iUYZDDXfQAAAAAAAA==
   -----END PKCS7-----
   ```
3. Export certificate from PKCS7 container
   ```
   openssl pkcs7 -print_certs -in smime.p7s -out smime.cer
   ```

## Symmetric Encryption/Decryption
```
openssl enc -e -a -pbkdf2 -aes-256-ofb -in plain.txt -out cipher.txt
openssl enc -d -a -pbkdf2 -aes-256-ofb -in cipher.txt -out plain.txt
```
