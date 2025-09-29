import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
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
        
        property var allKanji: []
        property int retryAttempts: 0
        property int maxRetryAttempts: 3
        property bool networkAvailable: false
        property string lastKanjiData: ""
        property string lastKanjiDescription: ""

        function fetchKanjiFromSetUrl(setUrl) {
            return new Promise((resolve, reject) => {
                let xhr = new XMLHttpRequest();
                xhr.open("GET", "https://kanjiapi.dev" + setUrl, true);
                xhr.timeout = 10000; // 10 second timeout
                
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            networkAvailable = true;
                            retryAttempts = 0;
                            resolve(JSON.parse(xhr.responseText));
                        } else {
                            console.log("Error fetching kanji set:", xhr.status, xhr.statusText);
                            reject(xhr.status);
                        }
                    }
                };
                
                xhr.ontimeout = function() {
                    console.log("Network request timed out");
                    reject("timeout");
                };
                
                xhr.onerror = function() {
                    console.log("Network error occurred");
                    reject("network_error");
                };
                
                xhr.send();
            });
        }

        function fetchKanjiInfos(kanji, successCallback, errorCallback) {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "https://kanjiapi.dev/v1/kanji/" + kanji, true);
            xhr.timeout = 8000; // 8 second timeout
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        networkAvailable = true;
                        successCallback(JSON.parse(xhr.responseText));
                    } else {
                        errorCallback(xhr.status, xhr.statusText);
                    }
                }
            };
            
            xhr.ontimeout = function() {
                errorCallback("timeout", "Request timed out");
            };
            
            xhr.onerror = function() {
                errorCallback("network_error", "Network error");
            };
            
            xhr.send();
        }

        function fetchAllKanji() {
            console.log("Attempting to fetch kanji list, attempt:", retryAttempts + 1);
            
            return fetchKanjiFromSetUrl("/v1/kanji/joyo").then((kanji) => {
                allKanji = kanji;
                console.log("Kanji loaded successfully:", allKanji.length);
                networkAvailable = true;
                retryAttempts = 0;
                return true;
            }).catch((error) => {
                console.log("Failed to fetch kanji list:", error);
                networkAvailable = false;
                
                if (retryAttempts < maxRetryAttempts) {
                    retryAttempts++;
                    console.log("Scheduling retry in", (retryAttempts * 5), "seconds");
                    
                    // Schedule retry with exponential backoff
                    retryTimer.interval = retryAttempts * 5000; // 5s, 10s, 15s
                    retryTimer.restart();
                } else {
                    console.log("Max retry attempts reached, showing fallback content");
                    showFallbackContent();
                }
                return false;
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
                        
                        // Save successful data as fallback
                        lastKanjiData = kanjiData.kanji;
                        lastKanjiDescription = descriptionLabel.text;
                    },
                    function(status, statusText) {
                        console.error("Error loading kanji details:", status, statusText);
                        
                        if (status === "timeout" || status === "network_error") {
                            showFallbackContent();
                        } else {
                            kanjiLabel.text = "Error loading kanji";
                            descriptionLabel.text = "";
                        }
                    }
                );
            } else {
                showFallbackContent();
            }
        }

        function showFallbackContent() {
            if (lastKanjiData !== "") {
                kanjiLabel.text = lastKanjiData;
                descriptionLabel.text = lastKanjiDescription + "\n\n(Offline mode - showing cached kanji)";
                console.log("Showing cached kanji as fallback");
            } else {
                kanjiLabel.text = "学";  // Default kanji meaning "study/learn"
                descriptionLabel.text = "Meaning: study, learning, science\nKun: まな.ぶ\nOn: ガク\n\n(Offline mode - network unavailable)";
                console.log("Showing default kanji as fallback");
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

        ColumnLayout {
            Layout.preferredWidth: 88
            Layout.fillHeight: true
            spacing: 4
            
            Label {
                id: kanjiLabel
                text: "Loading..."
                font.pointSize: 48
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (kanjiLabel.text !== "" && kanjiLabel.text !== "Loading..." && kanjiLabel.text !== "Error loading kanji" && kanjiLabel.text !== "学") {
                            var url = "https://jotoba.de/search/default/" + encodeURIComponent(kanjiLabel.text) + "?l=es-ES";
                            Qt.openUrlExternally(url);
                        }
                    }
                }
            }
            
            Button {
                id: refreshButton
                text: "↻"
                Layout.preferredWidth: 30
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: 10
                visible: !apiHandler.networkAvailable || kanjiLabel.text === "学"
                
                ToolTip.text: "Retry loading kanji"
                ToolTip.visible: hovered
                
                onClicked: {
                    console.log("Manual refresh requested");
                    kanjiLabel.text = "Loading...";
                    descriptionLabel.text = "";
                    apiHandler.retryAttempts = 0; // Reset retry counter
                    
                    apiHandler.fetchAllKanji().then((success) => {
                        if (success) {
                            apiHandler.setRandomKanjiInfos();
                            if (!midnightTimer.running) {
                                midnightTimer.interval = apiHandler.msUntilMidnight();
                                midnightTimer.running = true;
                            }
                        }
                    });
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
        running: false
        repeat: false
        onTriggered: {
            apiHandler.setRandomKanjiInfos();
            midnightTimer.interval = 86400000
            midnightTimer.repeat = true
            midnightTimer.running = true
        }
    }

    Timer {
        id: retryTimer
        running: false
        repeat: false
        onTriggered: {
            console.log("Retrying kanji fetch...");
            apiHandler.fetchAllKanji().then((success) => {
                if (success) {
                    apiHandler.setRandomKanjiInfos();
                    // Start the midnight timer once we have successfully loaded data
                    midnightTimer.interval = apiHandler.msUntilMidnight();
                    midnightTimer.running = true;
                }
            });
        }
    }

    Timer {
        id: startupDelayTimer
        interval: 3000 
        running: false
        repeat: false
        onTriggered: {
            console.log("Starting kanji fetch after startup delay");
            apiHandler.fetchAllKanji().then((success) => {
                if (success) {
                    apiHandler.setRandomKanjiInfos();
                    // Start the midnight timer once we have successfully loaded data
                    midnightTimer.interval = apiHandler.msUntilMidnight();
                    midnightTimer.running = true;
                } else {
                    console.log("Initial fetch failed, fallback content already shown");
                }
            });
        }
    }

    Component.onCompleted: {
        console.log("DailyKanji widget loading...");
        
        kanjiLabel.text = "Loading...";
        descriptionLabel.text = "";
        
        startupDelayTimer.start();
    }
}
