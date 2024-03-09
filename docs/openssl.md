# OpenSSL
## Create certificate authority (ca)
1. Create private key
   ```shell
   # can be created without password without -aes256 and -passout pass:<password>
   openssl genrsa -aes256 -passout pass:<password> -out ca.key 8192
   ```
2. Create certificate
   ```shell
   openssl req -x509 -new -nodes -extensions v3_ca -key ca.key -days 1 -out ca.pem -sha512
   ```

## Create tls server certificate
1. Create private key
   ```shell
   # can be created without password without -aes256 and -passout pass:<password>
   openssl genrsa -aes256 -passout pass:<password> -out server.key 8192
   ```
2. Create certificate signing request
   ```shell
   openssl req -subj /CN=server -key server.key -new -out server.csr -sha512
   ```
3. Sign certificate
   ```shell
   # self signed (by private key)
   openssl x509 -sha512 -req -in server.csr -days 3650 -signkey server.key -out server.crt

   # signed by a ca
   openssl x509 -sha512 -req -in server.csr -days 3650 -CA ca.pem -CAkey ca.key -out server.pem
   ```

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
