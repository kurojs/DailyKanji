import QtQuick
import org.kde.plasma.components as PlasmaComponents
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Rectangle {
    id: widgetContainer
    height: 100
    width: 400
    color: "transparent"
    
    Layout.minimumWidth: 400
    Layout.maximumWidth: 400
    Layout.minimumHeight: 100
    Layout.maximumHeight: 100

    QtObject {
        id: apiHandler

        function fetchKanjiFromSetUrl(setUrl) {
            return new Promise((resolve, reject) => {
                let xhr = new XMLHttpRequest();
                xhr.open("GET", "https://kanjiapi.dev" + setUrl, true);
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            resolve(JSON.parse(xhr.responseText));
                        } else {
                            console.log("Error fetching kanji set:", xhr.status, xhr.statusText);
                            resolve([]);
                        }
                    }
                };
                xhr.send();
            });
        }

        function fetchKanjiInfos(kanji, successCallback, errorCallback) {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "https://kanjiapi.dev/v1/kanji/" + kanji, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        successCallback(JSON.parse(xhr.responseText));
                    } else {
                        errorCallback(xhr.status, xhr.statusText);
                    }
                }
            };
            xhr.send();
        }

        property var allKanji: []

        function fetchAllKanji() {
            return fetchKanjiFromSetUrl("/v1/kanji/joyo").then((kanji) => {
                allKanji = kanji;
                console.log("Kanji loaded:", allKanji.length);
            });
        }

        function setRandomKanjiInfos() {
            if (allKanji.length > 0) {
                let randomKanji = allKanji[Math.floor(Math.random() * allKanji.length)];

                fetchKanjiInfos(
                    randomKanji,
                    function(response) {
                        let kanjiData = response;
                        kanjiLabel.text = kanjiData.kanji;
                        descriptionLabel.text = 
                          "Meaning: " + kanjiData.meanings.join(", ") + "\n" +
                          "Kun: " + kanjiData.kun_readings.join(", ") + "\n" +
                          "On: " + kanjiData.on_readings.join(", ");
                    },
                    function(status, statusText) {
                        console.error("Error:", status, statusText);
                        kanjiLabel.text = "Error loading kanji";
                        descriptionLabel.text = "";
                    }
                );
            } else {
                kanjiLabel.text = "No kanji available";
                descriptionLabel.text = "";
            }
        }

        function msUntilMidnight() {
            var now = new Date();
            var nextMidnight = new Date();
            nextMidnight.setHours(24, 0, 0, 0);
            return nextMidnight - now;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        Label {
            id: kanjiLabel
            text: "Loading..."
            font.pointSize: 48
            Layout.preferredWidth: 88
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (kanjiLabel.text !== "" && kanjiLabel.text !== "Loading..." && kanjiLabel.text !== "Error loading kanji") {
                        var url = "https://jotoba.de/search/default/" + encodeURIComponent(kanjiLabel.text) + "?l=es-ES";
                        Qt.openUrlExternally(url);
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Label {
                id: descriptionLabel
                text: ""
                font.pointSize: 12
                color: "#CCCCCC"
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                padding: 8
            }
        }
    }

    Timer {
        id: midnightTimer
        interval: apiHandler.msUntilMidnight()
        running: true
        repeat: false
        onTriggered: {
            apiHandler.setRandomKanjiInfos();
            midnightTimer.interval = 86400000
            midnightTimer.repeat = true
            midnightTimer.running = true
        }
    }

    Component.onCompleted: {
        apiHandler.fetchAllKanji().then(() => {
            apiHandler.setRandomKanjiInfos();
            midnightTimer.interval = apiHandler.msUntilMidnight();
            midnightTimer.running = true;
        });
    }
}
