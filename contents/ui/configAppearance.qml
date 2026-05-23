import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    property alias cfg_descriptionColor: descriptionColor.color
    property alias cfg_kanjiColor: kanjiColor.color

    Kirigami.FormLayout {

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Description Text Color")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Color:")

            KQControls.ColorButton {
                id: descriptionColor
                showAlphaChannel: false
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Kanji Character Color")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Color:")

            KQControls.ColorButton {
                id: kanjiColor
                showAlphaChannel: false
            }
        }
    }
}
