# PreMiD Presence Metadata Test Suite

PreMiD Presence Metadata Test Suite (PreMiD-MTS) is a script/tool that is developed to test a presence's metadata (``metadata.json``) on [PreMiD/Presences](https://github.com/PreMiD/Presences). The ``metadata.json`` files consist various information related to a presence.

The motive behind this project is some unfortunate events on PreMiD that is caused by human error. One example is a presence developer made a mistake on their metadata. This, for some reason, crashes the whole store. Another one is when I developed [my own presence stats dashboard thing](https://mini.hans5958.me/premid-presence-stats). It is occassional to see either someone typed the wrong category (``others`` instead of ``other``), the wrong language (``ja`` instead of ``ja_JP``), etc.

With that reasoning, I developed this test suite so developers can mitigate such events, and for make the staff team's jobs easier.

This is also a PoC that it is possible to integrate metadata checking by using continuous integration (Travis CI, GitHub Actions, etc), and my first attempt to develop a software (well, it's just a script, but...) using shell/bash/*nix script and a proper version control.

## Requirements

- A Linux/*nix enviroment.  
  I use WSL (the Ubuntu one) to developing this tool, so any Linux enviroment should work. This has not been tested in native Linux enviroment, however.
- [jq](https://stedolan.github.io/jq), for reading JSON files.

## Installation

Just download the latest release [here](https://prithb.com/Hans5958/PreMiD-MTS/releases). 

The ``.sh`` file includes the **main** variant of the program, and the ``.zip`` files includes the **main** and [**TAP**](https://en.wikipedia.org/wiki/Test_Anything_Protocol) variants.

Only use the [TAP](https://en.wikipedia.org/wiki/Test_Anything_Protocol) variant if you know what you are doing.

## Usage

```
Usage: premid-mts.sh [-hovrn] [--help] [--offline] [--verbose] [--results] [--no-ansi] path

path                Path to the presence folder OR the metadata.json file.
-h/--help           Print this help text.
-o/--offline        Use offline mode.
-v/--verbose        Print the logs with more information.
-r/--results        Print only the results.
-n/--no-ansi        Print the logs without ANSI codes for viewing in text editors. Slower.
```
### Examples
```bash
$ bash premid-mts.sh GitHub
$ bash premid-mts.sh --offline Twitch/dist/metadata.json
$ bash premid-mts.sh --results websites/Y/YouTube
$ bash premid-mts.sh -ov DeviantArt
```


## License

PreMiD Presence Metadata Test Suite (PreMiD-MTS) is licensed under the terms of [Mozila Public License 2.0](https://github.com/Hans5958/PreMiD-MTS/blob/master/LICENSE.md).