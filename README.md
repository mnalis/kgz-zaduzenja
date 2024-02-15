# kgz-zaduzenja
Podsjetnik na zaduženja knjiga u Knjižnicama grada Zagreba

Nova verzija iz 2024. godine koristi eZaKi username/password umjesto starog broja kartice i PIN-a.

Korisnici koji nemaju registiran eZaKi korisnički račun mogu ga kreirati na https://katalog.kgz.hr/eZaKi/Home
te povezati sa svojim brojem kartice i PIN-om.

perl scripta zamišljena za dnevno pokretanje iz cron(8), kako bi upozoravala na zaduženja knjiga koja uskoro istječu.

Instalacija:

    sudo make install
    crontab -e
    # dodati liniju oblika: 15 1 * * *        /usr/local/bin/kgz_zaduzenja email@example.com myPassword 5

To će svaku noć pogledati ima li zaduženja za korisnika sa emailom *email@example.com* i lozinkom *myPassword*, 
i ako ih ima i ta zaduženja istječu za manje od *5* dana ispisati će na STDOUT, što će dovesti do toga da će 
cron(8) poslati mail korisniku (na *MAILTO* adresu)
