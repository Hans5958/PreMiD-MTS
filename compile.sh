#!/bin/bash

rm -rf dist
mkdir dist

export NUM_TYPE=$(ls -1q ./src/*/start.sh | wc -l)

for type in ./src/*/; do
    type_name=$(basename "$type")
    if [[ ${type_name::1} == "_" ]]; then
        continue
    fi
	i=$((i+1))
	echo -e "\e[37m[$i/$NUM_TYPE]\e[0m \e[97mNow compiling \e[0;107m\e[30m$type_name\e[0m\e[97m...\e[0m"
	cat src/header.sh >> dist/mts-$type_name.sh
    echo "" >> dist/mts-$type_name.sh
    cat $type/start.sh >> dist/mts-$type_name.sh
    echo "" >> dist/mts-$type_name.sh
    cat src/tests.sh >> dist/mts-$type_name.sh
    echo "" >> dist/mts-$type_name.sh
    cat $type/end.sh >> dist/mts-$type_name.sh
done

echo ""
echo -e "\e[97mCleaning...\e[0m"

for type in ./dist/*; do
    cat "$type" | sed -r "s/^\n\n/\n/g" > $type.temp && mv $type.temp $type
done

echo -e "\e[97mPackaging...\e[0m"
mkdir ./dist/gh-rel

zip ./dist/gh-rel/premid-mts.zip ./dist/*.sh
cp ./dist/mts-main.sh ./dist/gh-rel/premid-mts.sh

echo ""
echo -e "\e[97mAll done!\e[0m"
