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

float randomValue(const char* name) {
  if (strcmp(name, "Temperatura") == 0) {
    return random(0, 101) + random(0, 10) / 10.0; // 0-100.9 °C
  } else if (strcmp(name, "Pressione") == 0) {
    return random(1, 5) + random(0, 10) / 10.0; // 1.0-4.9 bar
  } else if (strcmp(name, "Tensione") == 0) {
    return random(210, 231) + random(0, 10) / 10.0; // 210.0-230.9 V
  } else if (strcmp(name, "Velocita") == 0) {
    return random(1000, 3001) + random(0, 10) / 10.0; // 1000.0-3000.9 rpm
  }
  return 0;
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
  
  // Array "parameters" con valori casuali
  JsonArray parameters = doc.createNestedArray("parameters");
  const char* names[] = {"Temperatura", "Pressione", "Tensione", "Velocita"};
  
  for (int i = 0; i < 4; i++) {
    JsonObject param = parameters.createNestedObject();
    param["name"] = names[i];
    param["value"] = randomValue(names[i]);
  }
  
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
  delay(500); // Invio ogni 2 secondi
}
