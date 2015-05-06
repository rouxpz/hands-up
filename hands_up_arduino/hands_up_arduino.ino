// Read data from the serial and turn ON or OFF a light depending on the value

char val; // Data received from the serial port
int ledPin = 12; // Set the pin to digital I/O 4
int ledPin2 = 11;

void setup() {
  pinMode(ledPin, OUTPUT); // Set pin as OUTPUT
  pinMode(ledPin2, OUTPUT);
  Serial.begin(9600); // Start serial communication at 9600 bps
}

void loop() {
  if (Serial.available()) { // If data is available to read,
    val = Serial.read(); // read it and store it in val
    Serial.write(val);
    Serial.println();
  }

  if (val == '1') { // If H was received
    digitalWrite(ledPin, HIGH); // turn the LED on
    digitalWrite(ledPin2, HIGH); // turn the LED on
  }
  if (val == '2') {
    digitalWrite(ledPin, LOW); // Otherwise turn it OFF
  }
  if (val == '0') {
    digitalWrite(ledPin2, LOW); // Otherwise turn it OFF
  }
//  delay(100); // Wait 100 milliseconds for next reading
}
