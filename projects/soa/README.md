1) nginx_serv/
<img src="https://static.soa.arkselen.ru/images/totem_bot.jpg" alt="Моя Жизнь, Свет и Тьма">



2) /nginx_conf/conf.d/*.conf
location / {
    try_files $uri $uri/ =404;
    add_header Cache-Control "public, max-age=86400"; # New way to say - allow cache
    add_header Pragma public;                         # Old way to say - allow cache
    add_header Vary Accept-Encoding;                  # It helps to understand(send cached version or simple version of site to client, cause of gzip or absense of gzip encrypting)
}


3) /secrets/soa

