#!/bin/bash

# Font Formatting for Output
FONT_RESET="\x1B[0m"
FONT_BOLD="\x1B[1m"
FONT_UNDERLINE="\x1B[4m"

main ()
{
    OPTION="${@}"
    echo "${OPTION}"
    if [[ "${OPTION}" == "prepare" ]]; then
        prepare
    fi

    if [[ "${OPTION}" == "install" ]]; then
        install_app
    fi

    if [[ "${OPTION}" == "config" ]]; then
        nginx_config
    fi
}

prepare ()
{
    echo -e "Updating apt"
    sudo apt update && sudo apt upgrade
    apt_install "unzip"
    apt_install "nano"
    echo -e "Installing dependencies"
    sudo apt update && sudo apt upgrade
    apt_install "php"
    apt_install "php-mbstring"
    apt_install "php-xml"
    apt_install "php-fpm"
    apt_install "php-intl"
    apt_install "php-sqlite3"

    # Safety check to make sure that Apache is not already installed
    if hash apache2 2>/dev/null; then
        apt_remove "apache2"
    fi

    # Install nginx and PHP
    apt_install 'nginx'
}

install_app ()
{
    wget https://wiki.selfhtml.org/offline-wiki/mediawiki-selfhtml.zip
    wget https://wiki.selfhtml.org/offline-wiki/selfhtml-offline.zip

    unzip mediawiki-selfhtml.zip -d ./temp
    sudo cp -r ./temp/mediawiki/. /var/www/html/
    rm -r temp/

    unzip selfhtml-offline.zip -d ./temp
    sudo cp -r temp/install/images/. /var/www/html/images/
    sudo cp -r temp/install/local/. /var/www/html/local/
    sudo cp -r temp/install/data/. /var/www/html/data/
    rm -r temp/

    sudo chmod -R 0777 /var/www/html/

    nginx_config

    rm mediawiki-selfhtml.zip
    rm selfhtml-offline.zip
}

nginx_config ()
{
    uri='$uri $uri/ =404'
    tab="$(printf '\t')"

    cat > /etc/nginx/sites-available/mediawiki <<EOF
server {
${tab}listen 80 default_server;
${tab}listen [::]:80 default_server;

${tab}# SSL configuration
${tab}#
${tab}# listen 443 ssl default_server;
${tab}# listen [::]:443 ssl default_server;
${tab}#
${tab}# Note: You should disable gzip for SSL traffic.
${tab}# See: https://bugs.debian.org/773332
${tab}#
${tab}# Read up on ssl_ciphers to ensure a secure configuration.
${tab}# See: https://bugs.debian.org/765782
${tab}#
${tab}# Self signed certs generated by the ssl-cert package
${tab}# Don't use them in a production server!
${tab}#
${tab}# include snippets/snakeoil.conf;

${tab}root /var/www/html;

${tab}# Add index.php to the list if you are using PHP
${tab}index index.php index.html index.htm;

${tab}server_name _;

${tab}location / {
${tab}${tab}# First attempt to serve request as file, then
${tab}${tab}# as directory, then fall back to displaying a 404.
${tab}${tab}try_files ${uri};
${tab}}

${tab}# pass PHP scripts to FastCGI server
${tab}#
${tab}location ~ \.php$ {
${tab}${tab}include snippets/fastcgi-php.conf;
${tab}#
${tab}#       # With php-fpm (or other unix sockets):
${tab}${tab}fastcgi_pass unix:/run/php/php7.4-fpm.sock;
${tab}#       # With php-cgi (or other tcp sockets):
${tab}#       fastcgi_pass 127.0.0.1:9000;
${tab}}

${tab}# deny access to .htaccess files, if Apache's document root
${tab}# concurs with nginx's one
${tab}#
${tab}location ~ /\.ht {
${tab}${tab}deny all;
${tab}}
}
EOF

    # For nginx sites under [sites-enabled] use a symbolic link to
    # [sites-available]. Create a link for [fastsitephp] then remove the
    # symbolic link for [default]. The actual [default] file still exists
    # under [sites-available]. nginx recommends not editing the [default]
    # file in production servers. For more see comments in the file itself.
    ln -s /etc/nginx/sites-available/mediawiki /etc/nginx/sites-enabled/
    rm /etc/nginx/sites-enabled/default

    # Restart nginx
    echo -e "${FONT_BOLD}${FONT_UNDERLINE}Restarting nginx${FONT_RESET}"
    systemctl reload nginx

        # If this script runs more than once the files will already be deleted
    if [[ -f /var/www/html/index.html ]]; then
        rm /var/www/html/index.html
    fi
    if [[ -f /var/www/html/index.nginx-debian.html ]]; then
        rm /var/www/html/index.nginx-debian.html
    fi

    echo "The app should be available now."
}

apt_install ()
{
    if hash "$1" 2>/dev/null; then
        echo -e "${FONT_BOLD}${FONT_UNDERLINE}${1}${FONT_RESET} is already installed"
    else
        echo -e "Installing ${FONT_BOLD}${FONT_UNDERLINE}${1}${FONT_RESET}"
        apt install -y "$1"
        echo -e "${FONT_BOLD}${FONT_UNDERLINE}${1}${FONT_RESET} has been installed"
    fi
}

apt_remove ()
{
    if hash "$1" 2>/dev/null; then
        echo -e "Removing ${FONT_BOLD}${FONT_UNDERLINE}${1}${FONT_RESET}"
        apt remove --purge -y "$1"
        echo -e "${FONT_BOLD}${FONT_UNDERLINE}${1}${FONT_RESET} has been installed"
    else
        echo -e "${FONT_BOLD}${FONT_UNDERLINE}${1}${FONT_RESET} is not installed"
    fi
}


main "$@"
