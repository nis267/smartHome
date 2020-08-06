#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <SocketIoClient.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <ESP8266HTTPClient.h>

#define NODEBUG_SOCKETIOCLIENT
#define COMMON_ANODE

bool http_server_authentication();

enum JSON
{
  CHECK,
  GET
};

enum LED_COLOR
{
  RED,
  GREEN,
  BLUE
};

SocketIoClient socket;
// Set web server port number to 80
WiFiServer server(80);
StaticJsonDocument<1024> doc;

WiFiClient client;

// Current time
unsigned long currentTime = millis();
// Previous time
unsigned long previousTime = 0;
const long timeoutTime = 2000;
const long timeoutTimeWiFi = 60000;
const long timeoutTimeSocketAuth = 15000;
const long timeoutTimeLedReady = 10000;

String ssid = "";
String passwordWifi = "";
String serverAddress = "";
String passwordServer = "";
String jwt = "";
String ap_name = "smartHome_" + String(random(1000, 9999));
int serverPort = 8080;
int relais = 0;
int relaisPin = D1;
bool socket_authenticated = false;
bool socket_disconnected = false;
bool led_on = true;
bool valid_credentials = false;

uint8_t red_light_pin = D5;
uint8_t green_light_pin = D6;
uint8_t blue_light_pin = D7;

void RGB_color(int red_light_value, int green_light_value, int blue_light_value)
{
    #ifdef COMMON_ANODE
    red_light_value = 1024 - red_light_value;
    green_light_value = 1024 - green_light_value;
    blue_light_value = 1024 - blue_light_value;
    #endif
    analogWrite(red_light_pin, red_light_value);
    analogWrite(green_light_pin, green_light_value);
    analogWrite(blue_light_pin, blue_light_value);
}

String buildObject()
{
  String msg = String("{\"mac\":\"");
  msg += WiFi.macAddress();
  msg += "\",";
  msg += "\"state\":";
  msg += String(digitalRead(relaisPin));
  msg += "}";
  return (msg);
}

void getInit(const char *payload, size_t length)
{
  socket.emit("setInit", buildObject().c_str());
}

void action(const char *payload, size_t length)
{
  digitalWrite(relaisPin, !digitalRead(relaisPin));
  socket.emit("state", buildObject().c_str());
}

void authenticate(const char *payload, size_t length)
{
  if (socket_disconnected)
  {
    ESP.restart();
  }

  String token = String("{ \"token\": ") + String("\"") + jwt + String("\" }");
  socket.emit("authenticate", token.c_str());
}

void authenticated(const char *payload, size_t length)
{
  socket_authenticated = true;
  RGB_color(0, 1024, 0); // Green
  currentTime = millis();
  previousTime = currentTime;
}

void disconnect(const char *payload, size_t length)
{
  socket_authenticated = false;
  socket_disconnected = true;
  RGB_color(1024, 1024, 0); // Yellow

}

void socket_connection()
{
  socket.begin(serverAddress.c_str(), serverPort, "/smartHome/devices?transport=websocket", "/devices");
  socket.on("connect", authenticate);
  socket.on("action", action);
  socket.on("getInit", getInit);
  socket.on("authenticated", authenticated);
  socket.on("disconnect", disconnect);
}

void save_to_eeprom(const char *line)
{
  int i = 0;

  while (line[i])
  {
    EEPROM.write(i, line[i]);
    i++;
  }
  EEPROM.write(i, 255);
  EEPROM.commit();
}

bool WiFi_login(bool authentication)
{
  WiFi.enableSTA(true);
  WiFi.enableAP(false);
  WiFi.begin(ssid, passwordWifi); // Connect to the network
  int i = 0;
  currentTime = millis();
  previousTime = currentTime;
  while (WiFi.status() != WL_CONNECTED)
  { // Wait for the Wi-Fi to connect
    if ((WiFi.status() == WL_CONNECT_FAILED) || (!valid_credentials && authentication && (currentTime - previousTime >= timeoutTimeWiFi)))
    {
      return false;
    }
    delay(1000);
    Serial.print(++i);
    Serial.print(' ');
    currentTime = millis();
  }
  Serial.println();
  return true;
}

void WiFi_AP()
{
  WiFi.enableSTA(false);
  WiFi.enableAP(true);
  Serial.println();

  Serial.print("Setting soft-AP ... ");
  if (!WiFi.softAP(ap_name.c_str(), NULL))
  {
    Serial.println("Failed!");
    WiFi.enableAP(false);
    ESP.restart();
  }
  Serial.println("Ready");
  Serial.print("Ip address: ");
  Serial.println(WiFi.softAPIP());
}

bool check_data_json(const char *line, JSON type)
{
  char json[1024];

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
  if (!strlen(ssid_json) || !strlen(passwordWifi_json) || !strlen(serverAddress_json) || !strlen(passwordServer_json))
  {
    return false;
  }
  if (type == GET)
  {
    ssid = String(ssid_json);
    passwordWifi = String(passwordWifi_json);
    serverAddress = String(serverAddress_json);
    passwordServer = String(passwordServer_json);
  }
  else
  {
    save_to_eeprom(line);
  }
  return true;
}

void send_response(WiFiClient *client, const char *start_line, const char *json)
{
  (*client).println(start_line);
  (*client).println("Content-Type: application/json");
  (*client).println("Content-Length: " + String(strlen(json)));
  (*client).println("Connection: close");
  (*client).println();
  (*client).println(json);
  (*client).stop();
}

bool check_auth_result_and_get_jwt(const char *line)
{

  char json[1024];

  strcpy(json, line);

  DeserializationError error_json = deserializeJson(doc, json);

  if (error_json)
  {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error_json.c_str());
    return false;
  }

  const bool error = doc["error"];
  if (error == true)
  {
    return false;
  }
  if (error == false)
  {
    const char *token = doc["token"];
    jwt = token;
  }
  return true;
}

bool http_server_authentication()
{
  HTTPClient http;

  http.begin(client, serverAddress, serverPort, "/login_device");
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  String mac_address = WiFi.macAddress();
  mac_address.replace(":", ".");
  http.setAuthorization(mac_address.c_str(), passwordServer.c_str());
  http.POST("");
  String result = http.getString();
  http.end();
  if (result.length())
  {
    if (!check_auth_result_and_get_jwt(result.c_str()))
    {
      return false;
    }
  }
  else
  {
    ESP.restart();
  }
  return true;
}

void http_server_get_credentials()
{
  server.begin();
  while (true)
  {
    client = server.available(); // Listen for incoming clients

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
          else
          {
            send_response(&client, "HTTP/1.0 200 OK", "{\"msg\":\"Device received data\",\"error\":false}");
            client.stop();
            return;
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

bool get_json_from_eeprom()
{
  int i = 0;
  String json = "";

  while (true)
  {
    char c = char(EEPROM.read(i));
    if (c == 255)
    {
      break;
    }
    json += String(c);
    i++;
  }
  if (!json.length() || !check_data_json(json.c_str(), GET))
  {
    return false;
  }
  return true;
}

bool connect_to_server()
{
  if (valid_credentials || get_json_from_eeprom())
  {
    if (!WiFi_login(true) || !http_server_authentication())
    {
      save_to_eeprom("");
      RGB_color(1024, 0, 0); // Red
      return false;
    }
    else
    {
      Serial.print("socket connection");
      socket_connection(); //Connect to socket server
    }
    return true;
  }
  return false;
}

void setup()
{
  EEPROM.begin(1024);
  Serial.begin(115200); // Start the Serial communication to send messages to the computer
  Serial.print("Starting");
  Serial.println(" ...");
  pinMode(relaisPin, OUTPUT);
  pinMode(red_light_pin, OUTPUT);
  pinMode(green_light_pin, OUTPUT);
  pinMode(blue_light_pin, OUTPUT);
  WiFi.enableAP(false);
  WiFi.enableSTA(false);
  struct rst_info *resetInfo = ESP.getResetInfoPtr();
  if (resetInfo->reason == REASON_EXT_SYS_RST)
  {
    save_to_eeprom("");
  }
  if (get_json_from_eeprom())
  {
    valid_credentials = true;
    RGB_color(1024, 1024, 0); // Yellow
  }
  else
  {
    RGB_color(0, 0, 1024); // Blue
  }
  while (!connect_to_server())
  {
    WiFi_AP();
    http_server_get_credentials();
  }

}

void loop()
{
  if (WiFi.status() != WL_CONNECTED)
  { //Reconnect to WiFi if connection lost
    Serial.println("reconnect to wifi");
    RGB_color(1024, 1024, 0); // Yellow
    WiFi_login(false);
    ESP.restart();
  }
  socket.loop();
  if (led_on && socket_authenticated && ((currentTime - previousTime) >= timeoutTimeLedReady))
  {
    RGB_color(0, 0, 0);
    led_on = false;
  }
  currentTime = millis();
}
