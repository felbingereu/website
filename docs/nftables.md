# nftables
Mit `nft -i` kann eine Interaktive Shell geöffnet werden.
`list ruleset` zeigt die aktuelle Konfiguration an.
Regeln können wie folgt eingefügt werden:
```
# Source NAT
table ip nat { chain postrouting { oifname eth0 masquerade; }; }

# Create new table
add table inet test
table test { chain example { }; }

# Delete Table
delete table inet test
```
`flush ruleset` löscht alle Regeln (Achtung: Auch NAT, dadurch kann die Verbindung verloren gehen!)
