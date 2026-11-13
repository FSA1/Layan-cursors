#!/bin/bash

# --- Verificação de Dependências ---
dependencies=("inkscape" "xcursorgen")
missing_deps=()

for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        missing_deps+=("$dep")
    fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "As seguintes ferramentas obrigatórias estão faltando: ${missing_deps[*]}"
    read -p "Deseja instalá-las agora via dnf? (S/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]] || [[ -z $REPLY ]]; then
        sudo dnf install -y inkscape xcursorgen
    else
        echo "Erro: O script não pode continuar sem as dependências."
        exit 1
    fi
fi

function create {
	cd "$SRC"
    mkdir -p x1 x1_5 x2 x4 x5
	cd "$SRC"/$1

    echo "Renderizando SVGs em alta definição (incluindo 128px) para $THEME..."
    
    for svg in *.svg; do
        [ -e "$svg" ] || continue
        base="${svg%.svg}"
        
        inkscape --export-filename="../x1/${base}.png" -w 32 -h 32 "$svg"
        inkscape --export-filename="../x1_5/${base}.png" -w 48 -h 48 "$svg"
        inkscape --export-filename="../x2/${base}.png" -w 64 -h 64 "$svg"
        inkscape --export-filename="../x4/${base}.png" -w 96 -h 96 "$svg"
        inkscape --export-filename="../x5/${base}.png" -w 128 -h 128 "$svg"
    done

    cd "$SRC"

	OUTPUT="$BUILD"/cursors
	ALIASES="$SRC"/cursorList

    mkdir -p "$BUILD"
    mkdir -p "$OUTPUT"

	echo -ne "Generating cursor theme...\\r"
	for CUR in config/*.cursor; do
        BASENAME="${CUR##*/}"
		BASENAME="${BASENAME%.*}"
		
        if [ -f "$CUR" ]; then
		xcursorgen "$CUR" "$OUTPUT/$BASENAME"
        fi
	done
	echo -e "Generating cursor theme... DONE"

	cd "$OUTPUT"

	#generate aliases
	echo -ne "Generating shortcuts...\\r"
	while read ALIAS; do
		FROM="${ALIAS#* }"
		TO="${ALIAS% *}"

        if [ -e "$TO" ]; then
			continue
		fi
		ln -sr "$FROM" "$TO"
	done < "$ALIASES"
	echo -e "Generating shortcuts... DONE"

	cd "$PWD"

    echo -ne "Generating Theme Index...\\r"
	INDEX="$OUTPUT/../index.theme"
    cat << EOF > "$INDEX"
[Icon Theme]
Name=$THEME
Comment=Custom High-DPI Layan Cursors (128px Native Master Layer)
Size=24
Sizes=24,32,48,64,96
EOF
	echo -e "Generating Theme Index... DONE"
}

# generate cursors for each theme
SRC=$PWD/src

THEME="Layan Cursors"
BUILD="$SRC/../dist"
create svg

THEME="Layan-border Cursors"
BUILD="$SRC/../dist-border"
create svg-border

THEME="Layan-white Cursors"
BUILD="$SRC/../dist-white"
create svg-white

