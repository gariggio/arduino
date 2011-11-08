#include <SPI.h>         // needed for Arduino versions later than 0018
#include <Ethernet.h>
#include <Udp.h>         // UDP library from: bjoern@cs.stanford.edu 12/30/2008


#define FREE    1
#define BUSY    2
#define UNKNOWN 3
#define OFF     4

// Soglie sensibilità sensori
#define DEEP_SWITCH_THRESHOLD 1000
#define MIC_THRESHOLD 300
#define PIR_THRESHOLD 300

#define NO_PEEK_INTERVAL  60000

#define IP_START 100
#define UDP_MSG_FREE   "FREE"
#define UDP_MSG_BUSY   "BUSY"
#define UDP_SEND_STATUS_FREQUENCY  5000
#define UDP_NO_PACKET_INTERVAL     40000


// Definizione Pin Digitali
int ledRedPins[]   = { 0, 2, 4, 6 };  // An array of pin numbers to which LEDs are attached
int ledGreenPins[] = { 1, 3, 5, 7 };  // An array of pin numbers to which LEDs are attached

// Definizione Pin Analogici
int deepSwitchPins[] = { 2, 3, 4, 5 }; // L'ultimo pin è di debug
int micPin = 0;
int pirPin = 1;


// Numero di millisecondi trascorsi
unsigned long clock = 0;

// Istante di ricezione/d'invio dell'ultimo pacchetto UPD da/per ciascun Arduino
unsigned long recTime[] = { 0, 0, 0, 0 };

// Stato delle varie stanze monitorate dai 4 Arduino
int roomStatus[] = { UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN };

// Identificativo di questo Arduino
int thisArduinoId = 0;

// Modalità di debug?
boolean debug;

// Istante di rilevazione dell'ultimo picco da uno dei sensori
unsigned long lastPeekTime = 0;


// MAC address
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
// The IP address (Ethernet Shield)
byte ip[]  = { 192, 168, 0, 100 };
// Broadcast IP (dove inviare i pacchetti UDP)
byte broadcastIp[4] = { 192, 168, 0, 255 };
// Local port to listen on
unsigned int port = 9876;

byte remoteIp[4] = { 0, 0, 0, 0 };
unsigned int remotePort;


// Buffers for receiving and sending data
char inBuffer[UDP_TX_PACKET_MAX_SIZE];  // Buffer to hold incoming packet,
char msgBuffer[UDP_TX_PACKET_MAX_SIZE];   // String to send to other device


void showLedStatus(int deviceNumber)
{
  switch (roomStatus[deviceNumber]) {
    case FREE:
      digitalWrite(ledRedPins[deviceNumber], LOW);
      digitalWrite(ledGreenPins[deviceNumber], HIGH);
      break;
    case BUSY:
      digitalWrite(ledRedPins[deviceNumber], HIGH);
      digitalWrite(ledGreenPins[deviceNumber], LOW);
      break;
    case UNKNOWN:
      digitalWrite(ledRedPins[deviceNumber], HIGH);
      digitalWrite(ledGreenPins[deviceNumber], HIGH);
      break;
    case OFF:
      digitalWrite(ledRedPins[deviceNumber], LOW);
      digitalWrite(ledGreenPins[deviceNumber], LOW);
      break;
  }
  if (debug) {
    Serial.print("Led ");
    Serial.print(deviceNumber);
    Serial.print(" ");
    Serial.println(getUdpMessageStatus(roomStatus[deviceNumber]));
  }
}


char* getUdpMessageStatus(int deviceStatus)
{
  switch (deviceStatus) {
    case FREE:
      return UDP_MSG_FREE;
      break;
    case BUSY:
      return UDP_MSG_BUSY;
      break;
    case UNKNOWN:
      return "UNKNOWN";
    case OFF:
      return "OFF";
    default:
      return "IGNORE";
  }
}



// Legge e mostra lo stato di Arduino sul led preposto
// Ritorna true se lo stato è cambiato
boolean handleSensors()
{
  int oldStatus = roomStatus[thisArduinoId];
 
  // Microfono
  int micValue = analogRead(micPin);
  if (micValue > MIC_THRESHOLD) {
    lastPeekTime = millis();
    roomStatus[thisArduinoId] = BUSY;
  }
  // Sensore di movimento
  int pirValue = analogRead(pirPin);
  if (pirValue > PIR_THRESHOLD) {
    lastPeekTime = millis();
    roomStatus[thisArduinoId] = BUSY;
  }

  clock = millis();
  if (roomStatus[thisArduinoId] == BUSY) {
    if (clock < lastPeekTime) {
      // Gestione clock overflow
      lastPeekTime = 0;
    }
    if (clock > lastPeekTime + NO_PEEK_INTERVAL) {
      // Sono trascorsi NO_PEEK_INTERVAL millisecondi senza rilevare picchi su microfono e pir
      // La risorsa monitorata da Artuino diventa FREE
      roomStatus[thisArduinoId] = FREE;
    }
  } else {
    roomStatus[thisArduinoId] = FREE;
  }
  boolean statusChanged = (roomStatus[thisArduinoId] != oldStatus);
  if (statusChanged) {
    showLedStatus(thisArduinoId);
  }
  return statusChanged;
}


void printPacket(char* str, byte ip[], int port, char* packet)
{
    Serial.print(str);
    Serial.print(" ");
    Serial.print(int(ip[0]));
    Serial.print(".");
    Serial.print(int(ip[1]));
    Serial.print(".");
    Serial.print(int(ip[2]));
    Serial.print(".");
    Serial.print(int(ip[3]));
    Serial.print(":");
    Serial.print(port);
    if (packet != "") {
      Serial.print(" \"");
      Serial.print(packet);
      Serial.println("\"");
    } else {
      Serial.println();
    }
}


void handleReceivedPacket(byte remoteIp[], char message[])
{
  // TODO: decidere la modalità di definizione del deviceNumber
  //       Dall'IP o dal contenuto del paccheto?
  
  //int deviceNumber = remoteIp[3]- IP_START;
  int deviceNumber = int(message[0])-int('0');
  for (int i=1; i<=strlen(message); i++) {
     message[i-1] = message[i];
  }
  
  if (debug) {
    Serial.print("DeviceNumber recognized=");
    Serial.print(deviceNumber);
    Serial.print(" Message recognized=[");
    Serial.print(message);
    Serial.println("]");
  }
    
  if (deviceNumber >= 0 && deviceNumber < 4) {
    if (strcmp(message, UDP_MSG_FREE) == 0) {
      recTime[deviceNumber] = millis();
      roomStatus[deviceNumber] = FREE;
      showLedStatus(deviceNumber);
    } else if (strcmp(message, UDP_MSG_BUSY) == 0) {
      recTime[deviceNumber] = millis();
      roomStatus[deviceNumber] = BUSY;
      showLedStatus(deviceNumber);
    } else if (debug) {
      Serial.println("Messaggio ignorato!");
    }
  }
}
 
  
// Controlla ed eventualmente aggiorna lo stato dei led relativi agli altri Arduino.
// Se non si ricevono pacchetti UDP di aggiornamento dello stato dalla rete
// per un lungo intervallo di tempo (UDP_NO_PACKET_INTERVAL millisecondi)
// lo stato non è più significativo e deve quindi essere cambiato in UNKNOWN
// ed eventualmente in OFF
void checkLedStatusUpdated()
{
  clock = millis();
  for (int i=0; i<4; i++) {
    if (i != thisArduinoId) {
      if (clock < recTime[i]) {
        // Gestione clock overflow
        recTime[i] = 0;
      }
      if (roomStatus[i] < UNKNOWN) {
        if (clock > recTime[i] + UDP_NO_PACKET_INTERVAL) {
	  roomStatus[i] = UNKNOWN;
          showLedStatus(i);
        }
      } else if (roomStatus[i] == UNKNOWN) {
        if (clock > recTime[i] + 3 * UDP_NO_PACKET_INTERVAL) {
          roomStatus[i] = OFF;
	  showLedStatus(i);
        }
      }
    }
  }
}


int deepSwitchRead()
{
  int result = 0;
  for (int i = 0; i < 4; i++) {
    int analogValue = analogRead(deepSwitchPins[i]);
    if (analogValue > DEEP_SWITCH_THRESHOLD) {
      result += (1 << i);
    }
  }
  return result;
}


void setup()
{
  // Start serial
  Serial.begin(9600);
  clock = millis(); 
  
  // Setup digital and analog pins (INPUT/OUTPUT)
  for (int i = 0; i < 4; i++) {
    pinMode(ledRedPins[i], OUTPUT);
    pinMode(ledGreenPins[i], OUTPUT);
    pinMode(deepSwitchPins[i], INPUT);
  }
  pinMode(micPin, INPUT);
  pinMode(pirPin, INPUT);

  // Lettura valore decimale impostato sul deep switch
  int deepSwitchValue = deepSwitchRead();
  // Modalità di debug se è HIGH il quarto pin del deepSwitch
  
  // TODO: eliminare 
  debug = true;
  // TODO: scommentare 
  //debug = (deepSwitchValue >= 8);
  // I primi 3 pin del deepSwitch determinano l'identificativo numerico dato ad Arduino 
  thisArduinoId = (deepSwitchValue % 8);

  // Determinazione dell'ultimo numero dell'indirizzo IP e del MAC Address
  ip[3] = IP_START + thisArduinoId;
  mac[5] = thisArduinoId;

  for (int i=0; i<4; i++) {
    showLedStatus(i);
  }

  // Start Ethernet and UDP
  Ethernet.begin(mac, ip);
  Udp.begin(port);
  if (debug) {
    printPacket("IP Address:", ip, port, "");
  }
  
  delay(3000);
}


void loop()
{
  // if there's data available, read a packet
  int packetSize = Udp.available(); // note that this includes the UDP header
  if (packetSize) {
    packetSize = packetSize - 8; // subtract the 8 byte header
    // read the packet into packetBufffer and get the senders IP addr and port number
    Udp.readPacket(inBuffer, UDP_TX_PACKET_MAX_SIZE, remoteIp, remotePort);
    if (debug) {
      printPacket("Received packet:", remoteIp, remotePort, inBuffer);
    }
    handleReceivedPacket(remoteIp, inBuffer);
  }
  
  checkLedStatusUpdated();
  
  boolean statusChanged = handleSensors();
  
  clock = millis();
  if (statusChanged
	|| clock < recTime[thisArduinoId]
	|| clock > recTime[thisArduinoId] + UDP_SEND_STATUS_FREQUENCY) {
    // Invio aggiornamento di stato broadcast (remote IP)
    String strBuffer = String(thisArduinoId) + getUdpMessageStatus(roomStatus[thisArduinoId]);
    strBuffer.toCharArray(msgBuffer, UDP_TX_PACKET_MAX_SIZE);
    Udp.sendPacket(msgBuffer, broadcastIp, port);
    if (debug) {
      printPacket("Sent packet:", broadcastIp, port, msgBuffer);
    }
    recTime[thisArduinoId] = millis();
  }
  delay(10);
}

