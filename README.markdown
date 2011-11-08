# Stratch Arduino

Quello che stiamo realizzando è un applicazione di Arduino che consenta di rilevare
se una sala riunioni è occupata (via microfono ed eventualmente via sensore di presenza)
mostrando contemporaneamente lo stato delle altre sale riunioni (con dei Led).

Per far questo i vari aruino sono connessi via Ethernet e si scambiano messaggi UDP broadcast.

Questo progetto è realizzato dal team Intesys Lab di [*Intesys s.r.l.*](http://www.intesys.it/)


Ogni sala riunione (massimo 4) può assumere uno dei seguenti stati
- BUSY (rosso)
- FREE (verde)
- UNKNOWN (arancio)
- OFF (spento)


Ogni arduino è identificato da un indirizzo IP.
L'ultimo byte è determinato dai primi 2 pin di un DeepSwitch.
Anche l'ultimo byte del MAC address della scheda di rete è determinato dagli ultimi 2 pin del DeepSwitch.
Il 4 pin del DeepSwitch viene utilizzato per il debugging.




