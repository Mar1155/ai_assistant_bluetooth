#include "BluetoothSerial.h"
#include <ArduinoJson.h>

BluetoothSerial SerialBT;

// Pulsanti
#define BUTTON1_PIN 33
#define BUTTON2_PIN 32
#define BUTTON3_PIN 25

// Stati attuali dei pulsanti (per debounce/toggle)
bool lastButton1State = HIGH;
bool lastButton2State = HIGH;
bool lastButton3State = HIGH;

// Stati attivi degli errori
bool error1Active = false;
bool error2Active = false;
bool error3Active = false;

// Callback per connessioni
void btCallback(esp_spp_cb_event_t event, esp_spp_cb_param_t *param) {
  if (event == ESP_SPP_SRV_OPEN_EVT) {
    Serial.println("Client connesso");
  } else if (event == ESP_SPP_CLOSE_EVT) {
    Serial.println("Client disconnesso");
  }
}

void setup() {
  Serial.begin(115200);

  if (!SerialBT.begin("ESP32_BT")) {
    Serial.println("Errore durante l'inizializzazione del Bluetooth");
  } else {
    Serial.println("Bluetooth inizializzato. In attesa di connessione...");
  }

  SerialBT.register_callback(btCallback);

  pinMode(BUTTON1_PIN, INPUT_PULLUP);
  pinMode(BUTTON2_PIN, INPUT_PULLUP);
  pinMode(BUTTON3_PIN, INPUT_PULLUP);
}

float randomValue(const char* name) {
  if (strcmp(name, "Temperatura") == 0) return 60.7;
  if (strcmp(name, "Pressione") == 0) return 1.5;
  if (strcmp(name, "Tensione") == 0) return 219.7;
  if (strcmp(name, "Ore di lavoro") == 0) return 32.2;
  return 0;
}

void loop() {
  // Stato connessione
  if (SerialBT.hasClient()) {
    Serial.println("Dispositivo connesso via Bluetooth.");
  } else {
    Serial.println("Nessun dispositivo connesso.");
  }

  // Gestione messaggi ricevuti
  if (SerialBT.available()) {
    String rxValue = SerialBT.readStringUntil('\n');
    if (rxValue.length() > 0) {
      Serial.print("Messaggio ricevuto: ");
      Serial.println(rxValue);
      SerialBT.println("{\"message\":\"ok\"}");
    }
  }

  // Leggi lo stato corrente dei pulsanti
  bool currentButton1 = digitalRead(BUTTON1_PIN);
  bool currentButton2 = digitalRead(BUTTON2_PIN);
  bool currentButton3 = digitalRead(BUTTON3_PIN);

  // Toggle errori su pressione (da HIGH a LOW)
  if (lastButton1State == HIGH && currentButton1 == LOW) {
    error1Active = !error1Active;
    Serial.println(error1Active ? "Errore1 attivato" : "Errore1 disattivato");
  }
  if (lastButton2State == HIGH && currentButton2 == LOW) {
    error2Active = !error2Active;
    Serial.println(error2Active ? "Errore2 attivato" : "Errore2 disattivato");
  }
  if (lastButton3State == HIGH && currentButton3 == LOW) {
    error3Active = !error3Active;
    Serial.println(error3Active ? "Errore3 attivato" : "Errore3 disattivato");
  }

  // Aggiorna gli stati precedenti
  lastButton1State = currentButton1;
  lastButton2State = currentButton2;
  lastButton3State = currentButton3;

  // Costruzione JSON
  StaticJsonDocument<512> doc;
  JsonArray errors = doc.createNestedArray("errors");

  if (error1Active) {
    JsonObject err1 = errors.createNestedObject();
    err1["code"] = "errore1";
    err1["message"] = "Benzina esaurita";
  }
  if (error2Active) {
    JsonObject err2 = errors.createNestedObject();
    err2["code"] = "errore2";
    err2["message"] = "Sostituire candela";
  }
  if (error3Active) {
    JsonObject err3 = errors.createNestedObject();
    err3["code"] = "errore3";
    err3["message"] = "Sostituire olio motore";
  }

  JsonArray parameters = doc.createNestedArray("parameters");
  const char* names[] = {"Temperatura", "Pressione", "Tensione", "Ore di lavoro"};

  for (int i = 0; i < 4; i++) {
    JsonObject param = parameters.createNestedObject();
    param["name"] = names[i];
    param["value"] = randomValue(names[i]);
  }

  String output;
  serializeJson(doc, output);
  SerialBT.println(output);

  delay(200); // tempo ridotto per reattività migliore
}