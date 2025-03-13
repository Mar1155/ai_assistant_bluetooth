#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID "0000FFE0-0000-1000-8000-00805F9B34FB"
#define CHARACTERISTIC_UUID "0000FFE1-0000-1000-8000-00805F9B34FB"

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) override {
    deviceConnected = true;
    Serial.println("Client connesso");
  };

  void onDisconnect(BLEServer *pServer) override {
    deviceConnected = false;
    Serial.println("Client disconnesso");
    // Riavvia l'advertising per rendere nuovamente visibile il dispositivo
    BLEDevice::getAdvertising()->start();
    Serial.println("Advertising riavviato");
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) override {
    String rxValue = pCharacteristic->getValue();
    if (rxValue.length() > 0) {
      Serial.print("Messaggio ricevuto: ");
      Serial.println(rxValue);

      // Invio dell'eco del messaggio ricevuto al client
      pCharacteristic->setValue("{'message': 'ok'}");
      pCharacteristic->notify();
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Inizializza il dispositivo BLE con il nome "ESP32_BLE"
  BLEDevice::init("ESP32_BLE");

  // Crea il server BLE e definisci i callback di connessione/disconnessione
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Crea il servizio BLE
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Crea la caratteristica BLE con le proprietà di lettura, scrittura e notifica
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->setCallbacks(new MyCallbacks());

  // Avvia il servizio
  pService->start();

  // Avvia la pubblicità (advertising)
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
  Serial.println("In attesa di connessione da un client...");
}

int counter = 0;

void loop() {
  if (deviceConnected) {
    String message = "Messaggio #" + String(counter);
    pCharacteristic->setValue(message.c_str());
    pCharacteristic->notify();  // Invia il messaggio attuale
    Serial.println("Inviato: " + message);
    counter++;
    delay(2000);  // Invia ogni 2 secondi
  }
}
