#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <SocketIoClient.h>

SocketIoClient socket;

const char* ssid     = "Vodafone-2B0B";
const char* password = "uL4bbmq46RLLAQmm";
const char* serverIp = "192.168.0.214";
int serverPort = 8080;
int relais = 0;
int relaisPin = 5;
int relaisState = LOW;

void reconnect(const char * payload, size_t length) {
  Serial.println("reconnect");
}

String buildObject()
{
  String msg = String("{\"mac\":\"");
  msg += WiFi.macAddress();
  msg += "\",";
  msg += "\"state\":";
  msg += String(relaisState);
  msg += "}";
  return (msg);
}

void getInit(const char * payload, size_t length) {
  Serial.printf("object: %s\n", buildObject().c_str());
  socket.emit("setInit", buildObject().c_str());
}

void action(const char * payload, size_t length) {
  Serial.printf("payload: %s\n", payload);
  
  Serial.printf("payload atoi: %d\n", atoi(payload));
  if (atoi(payload) == HIGH && relaisState == LOW) {
    relaisState = !relaisState;
    digitalWrite(relaisPin, relaisState);
    socket.emit("state", buildObject().c_str());
  }
  else if (atoi(payload) == LOW && relaisState == HIGH) {
    relaisState = !relaisState;
    digitalWrite(relaisPin, relaisState);
    socket.emit("state", buildObject().c_str());
  }
}

void setup() {
  Serial.begin(115200);         // Start the Serial communication to send messages to the computer
  delay(1000);
  // Serial.setDebugOutput(true);
  Serial.println('\n');
  WiFi.begin(ssid, password);             // Connect to the network
  Serial.print("Connecting to ");
  Serial.print(ssid); Serial.println(" ...");
  pinMode(relaisPin, OUTPUT);

  int i = 0;
  while (WiFi.status() != WL_CONNECTED) { // Wait for the Wi-Fi to connect
    delay(1000);
    Serial.print(++i); Serial.print(' ');
  }
  Serial.println();

  socket.begin(serverIp, serverPort, "/device/?transport=websocket");
  socket.on("action", action);
  socket.on("getInit", getInit);
}

void loop() {
  // put your main code here, to run repeatedly:
  socket.loop();
}