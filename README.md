# Daily Kanji

A KDE Plasma 6 widget that displays a different Japanese kanji character each day, complete with meanings, readings, stroke count, and JLPT level information. Perfect for Japanese learners who want to incorporate daily kanji practice into their desktop workflow.

![Daily Kanji Screenshot](https://i.imgur.com/BoxogAR.png)

## Features

### Core Functionality

- **Daily Kanji Display**: Shows a new kanji every day with automatic midnight refresh
- **Rich Information**: Displays meanings (English), kun-yomi, on-yomi readings, stroke count, and JLPT level
- **Multiple Kanji Sources**: Choose from Jōyō kanji (2,136 characters) or all kanji
- **JLPT Level Filtering**: Filter by JLPT levels (N5-N1) or show all levels
- **Offline Support**: Caches the last kanji for offline viewing
- **Click to Learn More**: Click on kanji to open in your preferred dictionary
- **Customizable Dictionary**: Configure URL and language for external lookups
- **Automatic Retry**: Smart retry logic with exponential backoff for network issues

### User Interface

- **Compact & Full Views**: Works in both panel and desktop widget modes
- **Modern Design**: Clean interface that integrates with your KDE theme
- **Responsive Layout**: Adapts to different widget sizes

## Requirements

- **KDE Plasma**: 6.0 or higher
- **Qt Version**: 6.0+
- **Internet Connection**: Required for fetching kanji data (works offline with cached data)

## Installation

### Method 1: Via Plasma GUI (Recommended)

1. Download `dailykanji-v1.0.0.plasmoid` from [Releases](https://github.com/kurojs/DailyKanji/releases)
2. Right-click on the desktop or panel
3. Select "Enter Edit Mode"
4. Click "Add Widgets..."
5. Click "Get New Widgets" → "Install Widget From Local File..."
6. Select the downloaded `dailykanji-v1.0.0.plasmoid` file
7. Click "Install"

### Method 2: Command Line Installation

Download `dailykanji-v1.0.0.plasmoid` from [Releases](https://github.com/kurojs/DailyKanji/releases) and install:

```bash
kpackagetool6 --type=Plasma/Applet --install dailykanji-v1.0.0.plasmoid
```

**Note:** If the widget doesn't appear after installation, restart Plasma Shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

### Method 3: From Source

```bash
git clone https://github.com/kurojs/DailyKanji.git
cd DailyKanji
kpackagetool6 --type=Plasma/Applet --install .
```

### Update Existing Installation

```bash
kpackagetool6 --type=Plasma/Applet --upgrade dailykanji-v1.0.0.plasmoid
```

## Configuration

Right-click the widget and select "Configure Daily Kanji..." to access settings:

![Configuration Settings](https://i.imgur.com/9DTFEGh.png)

### Kanji Source

- **Jōyō Kanji (2,136 characters)**: Official list of everyday-use kanji
- **All Kanji**: Complete set of available kanji

### JLPT Level Filter

Filter kanji by Japanese Language Proficiency Test level:

- **All Levels** (default): No filtering
- **N5**: Beginner level (~100 kanji)
- **N4**: Elementary level (~200 kanji)
- **N3**: Intermediate level (~350 kanji)
- **N2**: Upper-intermediate level (~400 kanji)
- **N1**: Advanced level (~1,000 kanji)

### Click Behavior

Configure what happens when you click on the kanji:

**Redirect URL Template:**
```
https://jotoba.de/search/default/%kanji%?l=%lang%
```

Available placeholders:
- `%kanji%`: Replaced with the current kanji character
- `%lang%`: Replaced with the configured language code

**Language Code:**
- Default: `es-ES` (Spanish)
- Examples: `en-US`, `ja-JP`, `fr-FR`, `de-DE`, `pt-BR`

**Example Configurations:**

For English Jisho.org:
```
URL: https://jisho.org/search/%kanji%
Language: en-US
```

For Japanese Weblio:
```
URL: https://www.weblio.jp/content/%kanji%
Language: ja-JP
```

For German Wadoku:
```
URL: https://www.wadoku.de/search/%kanji%
Language: de-DE
```

## Usage

### Adding the Widget

**To Panel:**
1. Right-click on your panel
2. Select "Add Widgets..."
3. Search for "Daily Kanji"
4. Add it to display in compact mode (kanji only)

**To Desktop:**
1. Right-click on desktop
2. Select "Add Widgets..."
3. Add "Daily Kanji"
4. Widget shows full view with kanji details

### Daily Usage

- New kanji appears automatically each day at midnight
- Click on kanji to search in configured dictionary
- Retry button appears if network fails

## Development

### Project Structure

```
DailyKanji/
├── metadata.json              # Widget metadata and info
├── LICENSE                    # MIT License
├── README.md                  # This file
└── contents/
    ├── config/
    │   ├── config.qml         # Configuration page definitions
    │   └── main.xml           # Configuration options schema
    └── ui/
        ├── main.qml           # Main widget logic
        ├── FullItem.qml       # Desktop/full view
        ├── CompactItem.qml    # Panel/compact view
        └── configGeneral.qml  # Configuration UI
```

### API Reference

This widget uses the [KanjiAPI.dev](https://kanjiapi.dev) API:

- **Kanji Lists**: `/v1/kanji/{set}` - joyo, all, grade-1 to grade-6, jlpt-n5 to jlpt-n1
- **Kanji Details**: `/v1/kanji/{character}` - Full information about specific kanji

## Contributing

Contributions are welcome! Please feel free to submit pull requests, report issues, or suggest new features.

## Support

If you encounter any issues or have questions:
1. Check the existing issues on GitHub
2. Create a new issue with detailed information about your problem
3. Include your KDE Plasma version and system information

## Acknowledgments

- [KanjiAPI.dev](https://kanjiapi.dev) for kanji data
- [Jotoba](https://jotoba.de) for default dictionary
- KDE community for the Plasma desktop environment

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
