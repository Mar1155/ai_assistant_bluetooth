// lib/providers/machine_manual_provider.dart

import 'package:ai_assistent_bluetooth/models/chat_message.dart';

class MachineManualProvider {
  static MachineManual getSampleManual() {
    return MachineManual(
      content: '''
MACHINE OPERATION MANUAL
=======================

Chapter 1: Introduction
This manual provides instructions for operating and maintaining your machine.

Chapter 2: Safety Instructions
Always follow safety protocols when operating the machine.

Chapter 3: Operations
3.1 Starting the machine
3.2 Standard operations
3.3 Shutting down

Chapter 4: Error Codes
4.1 Error Code E001: Motor overheating
The motor has exceeded its safe operating temperature. This can be caused by:
- Prolonged operation at high loads
- Insufficient cooling
- Mechanical obstruction

To resolve:
1. Shut down the machine immediately
2. Allow at least 30 minutes for cooling
3. Check for obstructions in the cooling vents
4. Ensure proper ventilation around the machine
5. Restart with reduced load

4.2 Error Code E002: Pressure sensor failure
The pressure sensor is not providing accurate readings. This can be caused by:
- Sensor malfunction
- Wiring issues
- Control board failure

To resolve:
1. Check sensor connections
2. Verify sensor functionality with diagnostic tool
3. Replace sensor if necessary
4. Contact technical support if problem persists

4.3 Error Code E003: Communication error
The internal communication system has failed. This can be caused by:
- EMI interference
- Loose connections
- Hardware failure

To resolve:
1. Check all internal connections
2. Move away from sources of interference
3. Reset the system
4. Contact technical support if problem persists

Chapter 5: Maintenance
5.1 Regular maintenance schedule
5.2 Cleaning procedures
5.3 Part replacement guidelines

Chapter 6: Troubleshooting
6.1 Common issues and solutions
6.2 Diagnostic procedures
6.3 When to contact support
''',
      errorCodes: {
        'E001': 'Motor overheating',
        'E002': 'Pressure sensor failure',
        'E003': 'Communication error',
        'E004': 'Power supply issue',
        'E005': 'Calibration error',
        'E006': 'Mechanical jam',
        'E007': 'Software error',
        'E008': 'Memory error',
        'E009': 'Sensor drift',
        'E010': 'Network connection lost',
      },
      maintenanceProcedures: {
        'daily': 'Perform visual inspection and clean external surfaces',
        'weekly': 'Check all connections and lubricate moving parts',
        'monthly': 'Perform full calibration and replace filters',
        'quarterly': 'Complete system diagnostic and replace wear parts',
        'annually': 'Full service by certified technician required',
      },
    );
  }
}