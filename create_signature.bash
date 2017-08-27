#!/bin/bash

TIMESTAMP=`date --utc --iso-8601=seconds`
APPLICATION_KEY="your NCMB application key"
CLIENT_KEY="your NCMB client key"
OBJECT_ID="your NCMB objectId"

CLASS="ToggleStocker"
QUERY="{\"objectId\":\"${OBJECT_ID}\"}"

function urlencode {
    echo "$1" | nkf -WwMQ | tr = %
}

function createNcmbSignature() {
    application_key=${1}
    cliend_key=${2}
    class=${3}
    objectId=${4}
    timestamp=${5}
    string="PUT
mb.api.cloud.nifty.com
/2013-09-01/classes/${class}/${objectId}
SignatureMethod=HmacSHA256&SignatureVersion=2&X-NCMB-Application-Key=${application_key}&X-NCMB-Timestamp=${timestamp}"
    echo -n "${string}" | openssl dgst -sha256 -binary -hmac ${cliend_key} | base64
}

function createNcmbSignatureWithQuery() {
    application_key=${1}
    cliend_key=${2}
    class=${3}
    query=`urlencode ${4}`
    timestamp=${5}
    string="GET
mb.api.cloud.nifty.com
/2013-09-01/classes/${class}
SignatureMethod=HmacSHA256&SignatureVersion=2&X-NCMB-Application-Key=${application_key}&X-NCMB-Timestamp=${timestamp}&where=${query}"
    echo -n "${string}" | openssl dgst -sha256 -binary -hmac ${cliend_key} | base64
}

function createNcmbSignatureForPush() {
    application_key=${1}
    cliend_key=${2}
    class=${3}
    query=`urlencode ${4}`
    timestamp=${5}
    string="POST
mb.api.cloud.nifty.com
/2013-09-01/push
SignatureMethod=HmacSHA256&SignatureVersion=2&X-NCMB-Application-Key=${application_key}&X-NCMB-Timestamp=${timestamp}"
    echo -n "${string}" | openssl dgst -sha256 -binary -hmac ${cliend_key} | base64
}

echo -n "OBJECT_ID               = \""
echo -n ${OBJECT_ID}
echo "\""

echo -n "set_existance_signature = \""
echo -n `createNcmbSignature ${APPLICATION_KEY} ${CLIENT_KEY} ${CLASS} ${OBJECT_ID} ${TIMESTAMP}`
echo "\""

echo -n "get_existance_signature = \""
echo -n `createNcmbSignatureWithQuery ${APPLICATION_KEY} ${CLIENT_KEY} ${CLASS} ${QUERY} ${TIMESTAMP}`
echo "\""

echo -n "push_notification_signature = \""
echo -n `createNcmbSignatureForPush ${APPLICATION_KEY} ${CLIENT_KEY} ${CLASS} ${QUERY} ${TIMESTAMP}`
echo "\""
