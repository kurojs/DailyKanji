import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_jlptLevel: jlptLevelCombo.currentValue
    property alias cfg_kanjiSource: kanjiSourceCombo.currentValue
    property alias cfg_redirectUrl: redirectUrlField.text
    property alias cfg_redirectLanguage: languageField.text

    Kirigami.FormLayout {
        
        ComboBox {
            id: kanjiSourceCombo
            Kirigami.FormData.label: i18n("Kanji Source:")
            model: [
                { text: i18n("Jōyō Kanji (2136 characters)"), value: "joyo" },
                { text: i18n("All Kanji"), value: "all" }
            ]
            textRole: "text"
            valueRole: "value"
            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === plasmoid.configuration.kanjiSource) {
                        currentIndex = i;
                        break;
                    }
                }
            }
        }
        
        ComboBox {
            id: jlptLevelCombo
            Kirigami.FormData.label: i18n("JLPT Level Filter:")
            model: [
                { text: i18n("All Levels"), value: "all" },
                { text: i18n("N5 (Beginner)"), value: "n5" },
                { text: i18n("N4"), value: "n4" },
                { text: i18n("N3"), value: "n3" },
                { text: i18n("N2"), value: "n2" },
                { text: i18n("N1 (Advanced)"), value: "n1" }
            ]
            textRole: "text"
            valueRole: "value"
            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === plasmoid.configuration.jlptLevel) {
                        currentIndex = i;
                        break;
                    }
                }
            }
        }
        
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Click Behavior")
        }
        
        TextField {
            id: redirectUrlField
            Kirigami.FormData.label: i18n("Redirect URL:")
            placeholderText: "https://jotoba.de/search/default/%kanji%?l=%lang%"
            Layout.fillWidth: true
        }
        
        Label {
            text: i18n("Use %kanji% for the kanji character and %lang% for the language code")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        TextField {
            id: languageField
            Kirigami.FormData.label: i18n("Language Code:")
            placeholderText: "es-ES"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }
        
        Label {
            text: i18n("Examples: en-US, es-ES, ja-JP, fr-FR, de-DE")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
