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

# Add rule
add rule test example oifname eth0 masquerade; 

# Delete Table
delete table inet test
```
`flush ruleset` löscht alle Regeln (Achtung: Auch NAT, dadurch kann die Verbindung verloren gehen!)

Startet man die nft shell mit `-a` wird an jeder Regel ein unique identifier angegeben, der zum löschen einzelner Regeln genutzt werden kann:
```
nft -a list ruleset
delete rule <table> <chain> handle <n>
```
