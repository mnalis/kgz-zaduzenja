# kgz-zaduzenja
Podsjetnik na zaduženja knjiga u Knjižnicama grada Zagreba

perl scripta zamišljena za dnevno pokretanje iz cron(8), kako bi upozoravala na zaduženja knjiga koja uskoro istječu.

Instalacija:

    sudo make install
    crontab -e
    # dodati liniju oblika: 15 1 * * *        /usr/local/bin/kgz_zaduzenja 55/6666 1234 5

To će svaku noć pogledati ima li zaduženja za korisnika sa brojem kartice *55/6666* sa PIN-om *1234*, 
i ako ih ima i ta zaduženja istječu za manje od *5* dana ispisati će na STDOUT, što će dovesti
do toga da će cron(8) poslati mail korisniku (na *MAILTO* adresu)
