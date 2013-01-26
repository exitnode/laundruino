#  The Laundruino
#
#  Copyright (C) 2011 Michael Clemens
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <SPI.h>
#include <Ethernet.h>
#include <Udp.h>


byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 
  192, 168, 1, 177 };
byte gateway[] = { 
  192, 168, 1, 1 };
byte subnet[] = { 
  255, 255, 255, 0 };
const int LED = A2;
long laundryIsDoneSince = -1;
boolean LEDon;
Server server(80);


void setup()
{
  Ethernet.begin(mac, ip, gateway, subnet);
  server.begin();
  Serial.begin(9600);
  pinMode(LED, INPUT);
}


void loop()
{
  // listen for incoming clients
  Client client = server.available();
  
  // Signal from washing machine (LED) is unstable
  // so we have to watch it for some time
  LEDon = false;
  long start = millis();
  while ((start+100)>millis()){
    if(!digitalRead(LED)) {
      LEDon = true;
      break;
    }
  }

  if (LEDon)
  {
    if (laundryIsDoneSince==-1){
      laundryIsDoneSince = millis();
    }
    Serial.println("LED is on");
  } 
  else {
    laundryIsDoneSince=-1;
    Serial.println("LED is off");
  } 

  if (client) {
    // Some code is taken frpm the official HTTPServer example
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (c == '\n' && currentLineIsBlank) {
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();
          client.println("<br /><br /><br /><br /><br /><br /><br /><br />");
          client.println("<table align=center><tr><td align=center>");
          if (LEDon) {
            long minutesDone = ((millis()-laundryIsDoneSince)/1000/60)+1;
            client.print("<font color='#00C000' size='13'><b>&#9786;</b></font>"); // Smiley :)
            client.print("<br /><br />");
            Serial.println(minutesDone);
            if (minutesDone > 1) {
              client.print("...since "); 
              client.print(minutesDone);
              client.print(" minutes!");            
            }
          } 
          else {
            client.print("<font color='#Co0000' size='6'><b>Nope, not yet...</b></font>");
          }
          client.println("</td></tr></table>");
          break;
        }
        if (c == '\n') {
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          currentLineIsBlank = false;
        }
      }
    }
    // close the connection:
    client.stop();
  }
  delay(2000);
}
