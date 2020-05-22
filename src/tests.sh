test_message required

test "Author present" "$(echo "$METADATA" | jq -c 'has("author")')"
test "Author valid" "ongoing" true
test "Author name present" "$(echo "$METADATA" | jq -c '.author | if has("name") then .name else false end')" false true
test "Author name valid" "$(echo "$METADATA" | jq -c '.author.name | type == "string"')" false true
test "Author ID present" "$(echo "$METADATA" | jq -c '.author | if has("id") then .id else false end')" false true
test "Author ID valid" "$(echo "$METADATA" | jq -c '.author.id | test("^\\d+$")')" false true
if [[ $RETURN2 ]]; then
    test "Author valid" true
else
    test "Author valid" false
fi

test "Service present" "$(echo "$METADATA" | jq -c 'if has("service") then .service else false end')"
test "Service valid" "$(echo "$METADATA" | jq -c '.service | type == "string"')"

test "Description present" "$(echo "$METADATA" | jq -c 'has("description")')"
test "Description valid" "ongoing" true
test "Language en must present" "$(echo "$METADATA" | jq -c '.description | has("en")')" false true
for lang in $(echo "$METADATA" | jq -r '.description | keys | .[]'); do
    LANG2="\"$lang\""
    test "Language $lang valid" "$(echo "$LANG_LIST" | jq "if index($LANG2) != null then true else false end")" false true
done
test "Description valid" "$RETURN2"

test "URL present" "$(echo "$METADATA" | jq -c 'if has("url") then .url else false end')"
if [[ $(echo "$METADATA" | jq -c '.url | type == "array"') == true ]]; then
    test "URL valid" "ongoing"
	test "URL array length > 1" "$(echo "$METADATA" | jq -c '.url | length != 1')" false true
    for item64 in $(echo "$METADATA" | jq --compact-output --raw-output '.url[] | @base64'); do
        item=$(echo "$item64" | base64 -d)
        test "URL $item valid" "$( (echo "$item" | grep -Pq "^(([a-z0-9-]+\\.)*[0-9a-z_-]+(\\.[a-z]+)+|(\\d{1,3}\\.){3}\\d{1,3}|localhost)$") && echo "true" || echo "false" )" false true
    done
	test "URL valid" "$RETURN2"
elif [[ $(echo "$METADATA" | jq -c '.url | type == "string"') == true ]]; then
    test "URL valid" "$(echo "$METADATA" | jq -c '.url | test("^(([a-z0-9-]+\\.)*[0-9a-z_-]+(\\.[a-z]+)+|(\\d{1,3}\\.){3}\\d{1,3}|localhost)$")')"
else 
    test "URL valid" false
fi

test "Version present" "$(echo "$METADATA" | jq -c 'if has("version") then .version else false end')"
test "Version valid" "$(echo "$METADATA" | jq -c '.version | test("^\\d+\\.\\d+\\.\\d+$")')"

test "Logo present" "$(echo "$METADATA" | jq -c 'if has("logo") then .logo else false end')"
test "Logo valid" "$(echo "$METADATA" | jq -c '.logo | test("^https?:\\/\\/?(?:[a-z0-9-]+\\.)*[0-9a-z_-]+(?:\\.[a-z]+)+\\/.*$")')"

test "Thumbnail present" "$(echo "$METADATA" | jq -c 'if has("thumbnail") then .thumbnail else false end')"
test "Thumbnail valid" "$(echo "$METADATA" | jq -c '.thumbnail | test("^https?:\\/\\/?(?:[a-z0-9-]+\\.)*[0-9a-z_-]+(?:\\.[a-z]+)+\\/.*$")')"

test "Color present" "$(echo "$METADATA" | jq -c 'if has("color") then .thumbnail else false end')"
test "Color valid" "$(echo "$METADATA" | jq -c '.color | test("^#([A-Fa-f0-9]{3}){1,2}$")')"

test "Tags present" "$(echo "$METADATA" | jq -c 'if has("tags") then true else false end')"
if [[ $(echo "$METADATA" | jq -c '.tags | type == "array"') == true ]]; then
    test "Tags valid" "ongoing"
    for item64 in $(echo "$METADATA" | jq --compact-output --raw-output '.tags[] | @base64'); do
        item="$(echo "$item64" | base64 -d)"
        test "Tag $item valid" "$( (echo "$item" | grep -Pq "^([^A-Z\s[:punct:]]-?)+$") && echo "true" || echo "false" )" false true
    done
	test "Tags valid" "$RETURN2"
else 
    test "Tags valid" false
fi

test "Category present" "$(echo "$METADATA" | jq -c 'if has("category") then .category else false end')"
test "Category valid" "$(echo "$METADATA" | jq -c '.category | test("(anime)|(games)|(music)|(socials)|(videos)|(other)")')"

test_message optional

test "Contributors present" "$(echo "$METADATA" | jq -c 'if has("contributors") then true else false end')" true
if [[ $RETURN1 == true ]]; then
    test "Contributors valid" "ongoing"
    for item64 in $(echo "$METADATA" | jq --compact-output --raw-output '.contributors[] | @base64'); do
        item="$(echo "$item64" | base64 -d)"
        test "Contributor name present" "$(echo "$item" | jq -c 'if has("name") then .name else false end')" false true
        test "Contributor name valid" "$(echo "$item" | jq -c '.name | type == "string"')" false true
        test "Contributor ID present" "$(echo "$item" | jq -c 'if has("id") then .id else false end')" false true
        test "Contributor ID valid" "$(echo "$item" | jq -c '.id | test("^\\d+$")')" false true
    done
    test "Contributors valid" "$RETURN2"
else
    test "Contributors valid" false true
fi
test "regExp present" "$(echo "$METADATA" | jq -c 'if has("regExp") then .regExp else false end')" true
if [[ $RETURN1 == true ]]; then
    test "regExp valid" "$(echo "$METADATA" | jq -c '.regExp | type == "string"')" true
else
    test "regExp valid" false true
fi

test "iFrameRegExp present" "$(echo "$METADATA" | jq -c 'if has("iFrameRegExp") then .iFrameRegExp else false end')" true
if [[ $RETURN1 == true ]]; then
    test "iFrameRegExp valid" "$(echo "$METADATA" | jq -c '.iFrameRegExp | type == "string"')" true
else
    test "iFrameRegExp valid" false true
fi

test "iframe present" "$(echo "$METADATA" | jq -c 'if has("iframe") then .iframe else false end')" true
if [[ $RETURN1 == true ]]; then
    test "iframe valid" "$(echo "$METADATA" | jq -c '.iframe | type == "boolean"')" true
else
    test "iframe valid" false true
fi

test "Button present" "$(echo "$METADATA" | jq -c 'if has("button") then .button else false end')" true
if [[ $RETURN1 == true ]]; then
    test "Button valid" "$(echo "$METADATA" | jq -c '.button | type == "boolean"')" true
else
    test "Button valid" false true
fi

test "Warning present" "$(echo "$METADATA" | jq -c 'if has("warning") then .warning else false end')" true
if [[ $RETURN1 == true ]]; then
    test "Warning valid" "$(echo "$METADATA" | jq -c '.warning | type == "boolean"')" true
else
    test "Warning valid" false true
fi

test "Settings present" "$(echo "$METADATA" | jq -c 'if has("settings") then true else false end')" true
if [[ $RETURN1 == true ]]; then
    test "Settings valid" "ongoing"
    for item64 in $(echo "$METADATA" | jq -cr '.settings[] | @base64'); do
        item=$(echo "$item64" | base64 -d)
        test "Setting ID present" "$(echo "$item" | jq -c 'if has("id") then .id else false end')" false true
        if [[ $RETURN1 == true ]]; then
            test "Setting ID valid" "$(echo "$item" | jq -c '.id | type == "string"')" false true
        else
            test "Setting ID valid" false true true
        fi
        test "Setting title present" "$(echo "$item" | jq -c 'if has("title") then .title else false end')" false true
        if [[ $RETURN1 == true ]]; then
            test "Setting title valid" "$(echo "$item" | jq -c '.title | type == "string"')" false true
        else
            test "Setting title valid" false true true
        fi
        test "Setting icon present" "$(echo "$item" | jq -c 'if has("icon") then .icon else false end')" false true
        if [[ $RETURN1 == true ]]; then
            test "Setting icon valid" "$(echo "$item" | jq -c '.icon | test("^fa[bs] fa-[0-9a-z-]+$")')" false true
        else
            test "Setting icon valid" false true true
        fi
        test "Setting value present" "$(echo "$item" | jq -c 'if has("value") then .value else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting value valid" "$(echo "$item" | jq -c '.value | type == "string" or type == "number" or type == "boolean"')" false true
        else
            test "Setting value valid" false true true
        fi
        test "Setting if present" "$(echo "$item" | jq -c 'if has("if") then .if else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting if valid" "$(echo "$item" | jq -c '.if | type == "object"')" false true
        else
            test "Setting if valid" false true true
        fi
        test "Setting placeholder present" "$(echo "$item" | jq -c 'if has("placeholder") then .placeholder else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting placeholder valid" "$(echo "$item" | jq -c '.placeholder | type == "string"')" false true
        else
            test "Setting placeholder valid" false true true
        fi
        test "Setting values present" "$(echo "$item" | jq -c 'if has("values") then .values else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting values valid" "$(echo "$item" | jq -c '.values | type == "array"')" false true
        else
            test "Setting values valid" false true true
        fi
        test "Setting multi language present" "$(echo "$item" | jq -c 'if has("multiLanguage") then .multiLanguage else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting multi language valid" "$(echo "$item" | jq -c '.multiLanguage | type == "boolean" or type == "string" or type == "array"')" false true
        else
            test "Setting multi language valid" false true true
        fi

    done
    test "Settings valid" "$RETURN2"
else
    test "Settings valid" false true
fi

test_message finished
