import 'dart:async';

class ChatGptService {
  /// Simula una richiesta API a ChatGPT.
  /// [prompt] è il testo da inviare a ChatGPT.
  /// Restituisce una risposta fittizia basata sul contenuto del prompt.
  Future<String> getResponse(String prompt) async {
    // Simula un ritardo tipico di una chiamata API.
    await Future.delayed(Duration(seconds: 2));
    
    // Genera una risposta fittizia in base al prompt.
    return _simulateChatGptResponse(prompt);
  }

  /// Metodo ausiliario che genera una risposta simulata in base al prompt.
  String _simulateChatGptResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains("sovraccarico")) {
      return "Il problema di sovraccarico motore può essere causato da un eccessivo carico sul motore. Verifica i sensori e controlla la manutenzione programmata.";
    } else if (lowerPrompt.contains("pressione insufficiente")) {
      return "La pressione insufficiente potrebbe derivare da perdite nel sistema o da un malfunzionamento della pompa. Controlla le tubazioni e sostituisci la pompa se necessario.";
    } else if (lowerPrompt.contains("temperatura elevata")) {
      return "La temperatura elevata può indicare un problema al sistema di raffreddamento. Assicurati che il liquido refrigerante sia al livello corretto e che non vi siano ostruzioni.";
    }
    
    // Risposta di default per prompt non riconosciuti.
    return "Suggerimento per risolvere l'errore: controlla il sistema di raffreddamento e verifica la pressione dei fluidi.";
  }
}
