#!/bin/bash 

export AWS_DEFAULT_REGION=us-east-2

# install jq
sudo yum install jq -y

# capture the id of the kms key
KEY_ID=$(aws kms create-key --origin EXTERNAL | jq -r .KeyMetadata.KeyId)

# create an alias for the kms key
aws kms create-alias --alias-name alias/ImportedCMK --target-key-id "$KEY_ID"

# capture the import parameters for the key
IMPORT_PARAMS=$(aws kms get-parameters-for-import --key-id "$KEY_ID"\
 --wrapping-algorithm RSAES_OAEP_SHA_1\
 --wrapping-key-spec RSA_2048)

# output the key input paramters to disk
echo $IMPORT_PARAMS | jq -r -j .ImportToken > token.b64
echo $IMPORT_PARAMS | jq -r -j .PublicKey > pkey.b64

# generate .bin files from the keymat on disk
openssl enc -d -base64 -A -in ./pkey.b64 -out ./pkey.bin
openssl enc -d -base64 -A -in ./token.b64 -out ./token.bin

# genrate a key 
openssl rand -out ./genkey.bin 32

# encrypt our newly created private key with the provided KMS public key
openssl rsautl -encrypt\
 -in ./genkey.bin\
 -oaep -inkey ./pkey.bin\
 -keyform DER -pubin\
 -out ./WrappedKeyMaterial.bin

# import the ecnrypted key to KMS
aws kms import-key-material\
 --key-id "$KEY_ID"\
 --encrypted-key-material fileb://WrappedKeyMaterial.bin\
 --import-token fileb://token.bin\
 --expiration-model KEY_MATERIAL_EXPIRES\
 --valid-to 2022-02-20T12:00:00-08:00
