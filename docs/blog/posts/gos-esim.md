---
date:
  created: 2025-08-27
authors:
- nicof2000
categories:
- GrapheneOS
readtime: 3
---
# GrapheneOS: GMX FreePhone eSIM einrichten

[GrapheneOS](https://grapheneos.org/) ist ein alternatives Android-Betriebssystem, das auf
ausgewählten Pixel-Geräten läuft und besonderen Wert auf Sicherheit und Datenschutz legt.
Viele Nutzer setzen es ein, um die volle Kontrolle über ihr Gerät zu behalten und gleichzeitig
von Googles Diensten möglichst unabhängig zu sein.

GMX ist eigentlich vor allem als E-Mail-Anbieter bekannt, bietet inzwischen aber auch
Mobilfunktarife an. Einer davon ist [GMX FreePhone](https://www.gmx.net/handy/freephone/),
ein für 12 Monate kostenloser Basistarif mit 3 GB Datenvolumen pro Monat. Wichtig zu wissen:
es gibt nur eine eSIM, keine klassische Plastikkarte.

<!-- more -->

Um den FreePhone Tarif zu testen, habe ich mir einen Account bei GMX angelegt. Zur
Verifizierung der eigenen Identität ist eine Telefonnummer erforderlich. Nach dem Login
in der GMX Mail App kann der FreePhone Vertrag abgeschlossen werden. Kurze Zeit später
erhielt ich eine E-Mail mit dem Betreff "Ihr GMX FreePhone Vertrag: Aktivieren Sie jetzt
Ihre eSIM". Diese beinhaltet Anweisungen für das weitere Vorgehen, den Nutzernamen für den
Online-Zugang sowie einen Link für die Aktivierung in folgender Form: `https://service.freephone.gmx.net/myData/eSimActivation?tkn=...`

Nach Installation der GMX FreePhone App, versuchte ich mich mit dem Aktivierungslink in der
App anzumelden. Dies funktionierte leider nicht. Ich entschied mich, die "Passwort vergessen"
Funktion zu nutzen um mir ein neues Passwort zuschicken zu lassen. Hierfür war eine Angabe des
Nutzernamens sowie der PLZ erforderlich. Nachdem ich eine E-Mail mit dem Betreff: "Ihr neues
Passwort für die Servicewelt" mit dem neuen Passwort erhalten habe, war der Login möglich.

Direkt nach dem Login tauchte dann auch wie erwartet der Punkt "eSIM Aktivierung" auf.

![eSIM activation successful](../../media/posts/gos-esim-activated.png)

![eSIM Daten](../../media/posts/gos-esim-data.png)

Surfen über LTE/5G ist direkt möglich. Der erstbeste Speedtest ergibt etwa 10 MBit/s im Download.
Der volle Funktionsumfang des Tarifs kann nach der Zustellung des Aktivierungscodes per Post und
Eingabe in der App genutzt werden.

![Eingabe Aktivierungscode](../../media/posts/gos-esim-verify.png)

**Schlussbemerkungen:**  
Meine Absicht war es zu testen, ob eSIMs prinzipiell unter GrapheneOS funktionieren.
Meines Kenntnisstandes nach ist die Aktivierung von eSIMs unter GrapheneOS inzwischen
auch ohne Google Play Services im Hauptprofil möglich. Für die Nutzung des GMX-FreePhone-Tarifs
ist jedoch die oben genannte App erforderlich. Da ich diese lediglich über den Google
Play Store beziehen konnte, war ihre Installation notwendig.
Die Aktivierung der eSIM mit der GMX-App unter einem anderen Nutzer war nicht möglich.
