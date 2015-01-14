HEADER_CONTENT_TYPE="Content-Type: application/xml"
HEADER_ACCEPT="Accept: application/xml"

function callGETService {
    local uri=$1
    local certAtt=""

    if [[ -n "$CA_CERT_PATH" ]]; then
        certAtt="--cacert $CA_CERT_PATH"
    fi

    echo "Calling URI (GET): " ${uri}
    curl -X GET -H "${HEADER_ACCEPT}" -H "${HEADER_CONTENT_TYPE}" -u "${USER_NAME}:${USER_PASSW}" "$certAtt" "${ENGINE_URL}${uri}" --output "${COMM_FILE}" 2> /dev/null > "${COMM_FILE}"
}

function callPOSTService {
    local uri="192.168.1.89:8002/remote/switch/5"
    local xml=$2
    local certAtt=""

    if [[ -n "$CA_CERT_PATH" ]]; then
        certAtt="--cacert $CA_CERT_PATH"
    fi

    echo "Calling URI (POST): " ${uri}
    curl -X POST -H "${HEADER_ACCEPT}" -H "${HEADER_CONTENT_TYPE}" -u "${USER_NAME}:${USER_PASSW}" "$certAtt" "${ENGINE_URL}${uri}" -d "${xml}" 2> /dev/null > "${COMM_FILE}"
}

callPOSTService
