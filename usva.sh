#!/bin/sh
CURL_FLAGS="-sL"
USVA_INSTANCE="api.usva.cc"

upload() {
    if [ -z "$1" ] || ! [ -f "$1" ]; then
        echo "valid filename not given" >/dev/stderr
        exit 1
    fi

    out=$(curl -F "file=@$1" $CURL_FLAGS "$USVA_INSTANCE/file/upload")
    file=$(echo "$out" | jq -r ".filename")
    if [ $? -eq 0 ]; then
        echo "$file"
    else
        echo "upload failed: $(echo $out | jq -r '.error')"
    fi
}

download() {
    if [ -z "$1" ]; then
        echo "valid filename not given" >/dev/stderr
        exit 1
    fi

    [ -n "$2" ] && out="$2" || out="-"
    curl -fo $out $CURL_FLAGS "$USVA_INSTANCE/file/?filename=$1"
    if [ $? -ne 0 ]; then
        echo "Download failed!"
    fi
}

_info_show_field() {
    if [ -z "$2" ]; then
        echo "\033[30m$1\033[0m: ''"
    else
        echo "\033[35m$1\033[0m: $2"
    fi
}

info() {
    if [ -z "$1" ]; then
        echo "valid filename not given" >/dev/stderr
        exit 1
    fi

    f=$(curl -f $CURL_FLAGS "$USVA_INSTANCE/file/info?filename=$1")
    if [ $? -ne 0 ]; then
        echo "Download failed!"
    fi

    _info_show_field "encrypted" "$(echo $f | jq -r .encrypted)"
    _info_show_field "filename" "$(echo $f | jq -r .filename)"
    _info_show_field "locked" "$(echo $f | jq -r .locked)"
    _info_show_field "file size" "$(echo $f | jq -r .size)"
    _info_show_field "title" "$(echo $f | jq -r .title.String)"
    _info_show_field "uploaded" "$(echo $f | jq -r .uploadDate)"
    _info_show_field "view count" "$(echo $f | jq -r .viewCount)"
}

_tool_missing() {
    echo "\033[31mTool missing\033[0m: $1"
    exit 1
}

_ensure_tools() {
    if ! jq -V >/dev/null; then
        _tool_missing "jq"
    elif ! openssl version >/dev/null; then
        _tool_missing "openssl"
    fi
}

_ensure_tools 2>/dev/null

case "$1" in
"info")
    info $2
    ;;
"download")
    download $2 $3
    ;;
"upload")
    upload $2
    ;;
*)
    echo "usage: $0 <command> [command-specific options]"
    echo "commands: \n \
            - info <filename> \n \
            - download <filename> \n \
            - upload <local filename>"
    ;;
esac
