#include "BluetoothSerial.h"
#include <ArduinoJson.h>

// Istanza per la comunicazione Bluetooth classica
BluetoothSerial SerialBT;
int counter = 0;

// Callback per gestire eventi di connessione/disconnessione
void btCallback(esp_spp_cb_event_t event, esp_spp_cb_param_t *param) {
  if (event == ESP_SPP_SRV_OPEN_EVT) {
    Serial.println("Client connesso");
  } else if (event == ESP_SPP_CLOSE_EVT) {
    Serial.println("Client disconnesso");
  }
}

void setup() {
  Serial.begin(115200);
  
  // Inizializza il Bluetooth con il nome scelto
  if (!SerialBT.begin("ESP32_BT")) {
    Serial.println("Errore durante l'inizializzazione del Bluetooth");
  } else {
    Serial.println("Bluetooth inizializzato. In attesa di connessione...");
  }
  
  // Registra il callback per gli eventi di connessione
  SerialBT.register_callback(btCallback);
}

void loop() {
  // Gestione dei dati ricevuti dal client Bluetooth
  if (SerialBT.available()) {
    String rxValue = SerialBT.readStringUntil('\n');
    if (rxValue.length() > 0) {
      Serial.print("Messaggio ricevuto: ");
      Serial.println(rxValue);
      // Risposta al client
      SerialBT.println("{\"message\":\"ok\"}");
    }
  }
  
  // Costruzione del JSON usando ArduinoJson
  StaticJsonDocument<512> doc;
  
  // Array "errors"
  JsonArray errors = doc.createNestedArray("errors");
  JsonObject err1 = errors.createNestedObject();
  err1["code"] = "01";
  err1["message"] = "Sovraccarico motore";
  JsonObject err2 = errors.createNestedObject();
  err2["code"] = "02";
  err2["message"] = "Pressione insufficiente";
  JsonObject err3 = errors.createNestedObject();
  err3["code"] = "03";
  err3["message"] = "Temperatura elevata";
  
  // Array "parameters"
  JsonArray parameters = doc.createNestedArray("parameters");
  JsonObject param1 = parameters.createNestedObject();
  param1["name"] = "Temperatura";
  param1["value"] = "78.0";
  JsonObject param2 = parameters.createNestedObject();
  param2["name"] = "Pressione";
  param2["value"] = "2.4";
  JsonObject param3 = parameters.createNestedObject();
  param3["name"] = "Tensione";
  param3["value"] = "220.0";
  JsonObject param4 = parameters.createNestedObject();
  param4["name"] = "Velocita";
  param4["value"] = "1200.0";
  
  // Serializza il JSON in una stringa
  String output;
  serializeJson(doc, output);
  
  // Invia il JSON tramite Bluetooth Serial
  SerialBT.println(output);
  
  // Stampa il messaggio inviato sul monitor seriale
  Serial.print("n° ");
  Serial.print(counter);
  Serial.print(" Inviato: ");
  Serial.println(output);
  
  counter++;
  delay(2000); // Invio ogni 2 secondi
}
