# Stratch Arduino

Quello che stiamo realizzando è un applicazione di Arduino che consenta di rilevare
se una sala riunioni è occupata (via microfono ed eventualmente via sensore di movimento PIR)
mostrando contemporaneamente lo stato delle altre sale riunioni (con dei Led a 3 colori).
Per far questo i vari arduino (max. 4) comunicheranno le informazioni di stato inviandosi dei pacchetti UDP broadcast.

Questo progetto è realizzato dal team Intesys Lab di [*Intesys s.r.l.*](http://www.intesys.it/)


Ogni sala riunione (massimo 4) può assumere uno dei seguenti stati
- BUSY (rosso)
- FREE (verde)
- UNKNOWN (arancio)
- OFF (spento)

L'identificativo numerico di ciascun Arduino è letto dai primi 2 pin di un Dip Switch.
Ogni Led è associato quindi in maniera posizionale ai vari identificativi numerici.
Questi identificativi numerici sono anche utilizzati per definire l'ultimo byte dell'indirizzo IP e del MAC address della scheda di rete Ethernet.
Il 4° pin del Dip Switch indica se Arduino parte in modalità di debug.
In questa modalità arduino invia sulla seriale varie informazioni utili per la verifica del corretto funzionamento del dispositivo.
Inoltre in questa modalità il LED corrispondente alla stanza corrente diventerà Rosso solo in corrispondenza di rilevazioni BUSY effettuate da microfono o pir per alcuni millisecondi.


