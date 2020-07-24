#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <SocketIoClient.h>
#include <ArduinoJson.h>
#include <EEPROM.h>

enum JSON { CHECK, GET };

SocketIoClient socket;
// Set web server port number to 80
WiFiServer server(80);

// Current time
unsigned long currentTime = millis();
// Previous time
unsigned long previousTime = 0;
// Define timeout time in milliseconds (example: 2000ms = 2s)
const long timeoutTime = 2000;

// const char* ssid     = "Vodafone-2B0B";
// const char* password = "uL4bbmq46RLLAQmm";
// const char* serverIp = "192.168.0.214";
String ssid = "";
String passwordWifi = "";
String serverAddress = "";
String passwordServer = "";
int serverPort = 8080;
int relais = 0;
int relaisPin = 5;
int relaisState = LOW;

void reconnect(const char *payload, size_t length)
{
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

void getInit(const char *payload, size_t length)
{
  Serial.printf("object: %s\n", buildObject().c_str());
  socket.emit("setInit", buildObject().c_str());
}

void action(const char *payload, size_t length)
{
  if (atoi(payload) == HIGH && relaisState == LOW)
  {
    relaisState = !relaisState;
    digitalWrite(relaisPin, relaisState);
    socket.emit("state", buildObject().c_str());
  }
  else if (atoi(payload) == LOW && relaisState == HIGH)
  {
    relaisState = !relaisState;
    digitalWrite(relaisPin, relaisState);
    socket.emit("state", buildObject().c_str());
  }
}

void socket_connection()
{
  socket.begin(serverAddress.c_str(), serverPort, "/smartHome/?transport=websocket");
  socket.on("action", action);
  socket.on("getInit", getInit);
}

void save_json_to_eeprom(const char *line) {
  int i = 0;

  while (line[i]) {
    EEPROM.write(i, line[i]);
    i++;
  }
  EEPROM.write(i, 255);
  EEPROM.commit();
}

void WiFi_login()
{
  WiFi.begin(ssid, passwordWifi); // Connect to the network
  int i = 0;
  while (WiFi.status() != WL_CONNECTED)
  { // Wait for the Wi-Fi to connect
    // if (WiFi.status() == STATION_WRONG_PASSWORD)
    //   Serial.printf("STATION_WRONG_PASSWORD: %d\n", STATION_WRONG_PASSWORD);
    Serial.printf("WiFi status: %d\n", WiFi.status());
    if (WiFi.status() == WL_CONNECT_FAILED) {
      save_json_to_eeprom("");
      ESP.restart();
    }
    delay(1000);
    Serial.print(++i);
    Serial.print(' ');
  }
  Serial.println();
  Serial.printf("WiFi status after: %d\n", WiFi.status());

}
void WiFi_AP()
{
  Serial.println();

  Serial.print("Setting soft-AP ... ");
  Serial.println(WiFi.softAP("ESPsoftAP_01", NULL) ? "Ready" : "Failed!");
  Serial.print("Ip address: ");
  Serial.println(WiFi.softAPIP());
}

bool check_data_json(const char *line, JSON type)
{
  StaticJsonDocument<1024> doc;

  char json[strlen(line) + 1];

  strcpy(json, line);

  DeserializationError error = deserializeJson(doc, json);

  if (error)
  {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.c_str());
    return false;
  }

  const char *ssid_json = doc["ssid"];
  const char *passwordWifi_json = doc["password_wifi"];
  const char *serverAddress_json = doc["server_address"];
  const char *passwordServer_json = doc["password_server"];

  Serial.printf("ssid: %s\n", ssid_json);
  Serial.printf("passwordWifi_json: %s\n", passwordWifi_json);
  Serial.printf("serverAddress_json: %s\n", serverAddress_json);
  Serial.printf("passwordServer_json: %s\n", passwordServer_json);
  if (!strlen(ssid_json) || !strlen(passwordWifi_json) || !strlen(serverAddress_json) || !strlen(passwordServer_json)) 
  {
    return false;
  }
  if (type == GET) {
    ssid = String(ssid_json);
    passwordWifi = String(passwordWifi_json);
    serverAddress = String(serverAddress_json);
    passwordServer = String(passwordServer_json);
  }
  else {
    save_json_to_eeprom(line);
  }
  return true;
}

void send_response(WiFiClient *client, const char *start_line, const char *json)
{
  (*client).println("HTTP/1.0 400 Bad Request");
  (*client).println("Content-Type: application/json");
  (*client).println("Content-Length: " + String(strlen(json)));
  (*client).println();
  (*client).println(json);
  (*client).stop();
}

void http_server()
{
  server.begin();
  while (true)
  {
    WiFiClient client = server.available(); // Listen for incoming clients

    if (client)
    {                                // If a new client connects,
      Serial.println("New Client."); // print a message out in the serial port
      String request = "";
      String line = "";
      String tmp = "";
      currentTime = millis();
      previousTime = currentTime;
      while (client.connected() && currentTime - previousTime <= timeoutTime)
      { // loop while the client's connected

        currentTime = millis();

        if (client.available())
        {
          request = client.readString();
          tmp = request;
          tmp.trim();
          line = tmp.substring(tmp.lastIndexOf('\n'));
          line.trim();

          if (!line.length() || !check_data_json(line.c_str(), CHECK))
            send_response(&client, "HTTP/1.0 400 Bad Request", "{\"error\":true,\"error_msg\": \"Data invalid\"}");
          else {
            send_response(&client, "HTTP/1.0 200 OK", "{\"success\":\"Device received data\",\"error\":false}");
            client.stop();
            Serial.println("Restart..");
            ESP.restart();
          }
        }
      }
      // Close the connection
      client.stop();
      Serial.println("Client disconnected.");
      Serial.println("");
    }
  }
}

bool get_json_from_eeprom() {
  int i = 0;
  String json = "";

  while (true) {
    char c = char(EEPROM.read(i));
    Serial.printf("c: %d\n", c);
    // delay(1000);
    if (c == 255) {
      break;
    }
    json += String(c);
    i++;
  }
  Serial.printf("Get json from eeprom: %s\n", json.c_str());
  if (!json.length() || !check_data_json(json.c_str(), GET)) {
    return false;
  }
  return true;
}

void setup()
{
  EEPROM.begin(1024);
  Serial.begin(115200); // Start the Serial communication to send messages to the computer
  // delay(1000);
  // Serial.setDebugOutput(true);
  // Serial.print(ssid);
  delay(3000);
  // save_json_to_eeprom();
  Serial.print("Starting");
  Serial.println(" ...");
  if (get_json_from_eeprom()) {
    WiFi_login();
    pinMode(relaisPin, OUTPUT);
    socket_connection(); //Connect to socket server
  }
  else {
    WiFi_AP();
    http_server();
  }
}

void loop()
{
  if (WiFi.status() != WL_CONNECTED) { //Reconnect to WiFi if connection lost
    Serial.println("reconnect to wifi");
    WiFi_login();
  }
  socket.loop();
}
