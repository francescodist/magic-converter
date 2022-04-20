# il primo parametro e' il nome del file, il secondo un
# numero che indica il foglio da convertire
convert_to_csv() {
	rm -f "$1.csv"
	touch "$1.csv"
	for x in *.xlsx
	do
		if [ -f "$x" ]; then
			echo "Converto $x a csv"
            SHEET=$2
            CONTINUE=1
            while [ $CONTINUE == 1 ]
            do  
                xlsx2csv -s "$SHEET" "$x" "$SHEET-$x.csv"
                if [[ -z $(grep '[^[:space:]]' "$SHEET-$x.csv") ]] ; then
                    CONTINUE=0
                fi
                echo $SHEET
                cat "$SHEET-$x.csv" >>  "$x.csv"
                rm "$SHEET-$x.csv"
                SHEET=$((SHEET + 1))
            done       
		fi
	done
	for c in *.xlsx.csv
	do
		if [ -f "$c" ]; then
			echo "Aggiungo ${c%%.*}"
			if [ "$2" -eq "2" ]; then
				grep -e "^[0-9]\+," "$c" | sed -E "s/^[0-9]+,(([^,]*,){9}).*$/\1${c%%.*},/" >> "$1.csv"
			else
				grep -e "^[0-9]\+," "$c" | sed -E "s/^[0-9]+,(([^,]*,){9}).*$/\1,${c%%.*},/" >> "$1.csv"
			fi
			rm "$c"
		fi
	done
}
# CONVERSIONE ESCLUSIVA PER PROVINCE
echo "*** INIZIO CREAZIONE FILE PROVINCIALI ***"
for regione in */; do
	if [ -d "$regione" ]; then
		cd "$regione";
		for provincia in */; do
			if [ -d "$provincia" ]; then
		    	cd "$provincia"
		    	echo "*** INIZIO CONVERSIONE PER PROVINCIA ${provincia%/} ***"
		    	convert_to_csv "${provincia%/}" 2
		    	cd ..
	    	fi
	    done
	    cd ..
	fi
done
echo "*** FINE CREAZIONE FILE PROVINCIALI (${provincia%/}.csv) ***"
# CONVERSIONE ESCLUSIVA PER REGIONE + UNIONE FILE PROVINCIA PRECEDENTI
echo "*** INIZIO CREAZIONE FILE REGIONALI ***"
for regione in */; do
	if [ -d "$regione" ]; then
		cd "$regione";
		echo "*** INIZIO CONVERSIONE PER REGIONE ${regione%/} ***"
		convert_to_csv "${regione%/}" 1

		for provincia in */; do
			if [ -d "$provincia" ]; then
				echo "Aggiungo ${provincia%/} a ${regione%/}"
	    		sed -E "s/^(.*)$/\1${provincia%/},/" "${provincia%/}/${provincia%/}.csv" >> "${regione%/}.csv"
	    	fi
	    done
	    cd ..
	fi
done
echo "*** FINE CREAZIONE FILE REGIONALI (${regione%/}.csv) ***"
# UNIONE REGIONI PRECEDENTI
echo "*** INIZIO CREAZIONE FILE NAZIONALE ***"
rm -f "nazionale.csv" 
touch "nazionale.csv"
for regione in */; do
    sed -E "s/^(.*)$/\1${regione%/}/" "${regione%/}/${regione%/}.csv" >> "nazionale.csv"
done
echo "*** CREATO FILE NAZIONALE (nazionale.csv)***"
echo "*** OPERAZIONE COMPLETATA CON SUCCESSO! ***"