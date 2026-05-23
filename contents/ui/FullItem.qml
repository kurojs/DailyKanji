import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Rectangle {
    id: widgetContainer
    height: apiHandler.showingMnemonic ? Math.max(100, Math.min(descriptionLabel.implicitHeight + 20, 400)) : 100
    width: 400
    color: "transparent"

    Layout.minimumWidth: 400
    Layout.maximumWidth: 400
    Layout.minimumHeight: apiHandler.showingMnemonic ? Math.max(100, Math.min(descriptionLabel.implicitHeight + 20, 400)) : 100
    Layout.maximumHeight: apiHandler.showingMnemonic ? Math.max(100, Math.min(descriptionLabel.implicitHeight + 20, 400)) : 100

    QtObject {
        id: apiHandler

        property var allKanji: []
        property int retryAttempts: 0
        property int maxRetryAttempts: 3
        property bool networkAvailable: false
        property string lastKanjiData: ""
        property string lastKanjiDescription: ""
        property string lastMnemonic: ""
        property string lastMnemonicReading: ""
        property bool showingMnemonic: false
        property bool mnemonicAvailable: false

        function fetchKanjiFromSetUrl(setUrl) {
            return new Promise((resolve, reject) => {
                let xhr = new XMLHttpRequest();
                xhr.open("GET", "https://kanjiapi.dev" + setUrl, true);
                xhr.timeout = 10000;

                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            networkAvailable = true;
                            retryAttempts = 0;
                            resolve(JSON.parse(xhr.responseText));
                        } else {
                            reject(xhr.status);
                        }
                    }
                };

                xhr.ontimeout = function() { reject("timeout"); };
                xhr.onerror = function() { reject("network_error"); };
                xhr.send();
            });
        }

        function fetchKanjiInfos(kanji, successCallback, errorCallback) {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "https://kanjiapi.dev/v1/kanji/" + kanji, true);
            xhr.timeout = 8000;

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

            xhr.ontimeout = function() { errorCallback("timeout", "Request timed out"); };
            xhr.onerror = function() { errorCallback("network_error", "Network error"); };
            xhr.send();
        }

        function fetchAllKanji() {
            const source = plasmoid.configuration.kanjiSource || "joyo";
            const jlpt = plasmoid.configuration.jlptLevel || "all";

            if (jlpt !== "all") {
                return fetchJLPTKanjiFromGithub(jlpt, source).then(function(result) {
                    return true;
                }).catch(function(error) {
                    networkAvailable = false;
                    if (retryAttempts < maxRetryAttempts) {
                        retryAttempts++;
                        retryTimer.interval = retryAttempts * 5000;
                        retryTimer.restart();
                    } else {
                        showFallbackContent();
                    }
                    return false;
                });
            }

            var apiPath = "/v1/kanji/joyo";
            if (source === "all") {
                apiPath = "/v1/kanji/all";
            }

            return fetchKanjiFromSetUrl(apiPath).then(function(kanji) {
                allKanji = kanji;
                networkAvailable = true;
                retryAttempts = 0;
                return true;
            }).catch(function(error) {
                networkAvailable = false;
                if (retryAttempts < maxRetryAttempts) {
                    retryAttempts++;
                    retryTimer.interval = retryAttempts * 5000;
                    retryTimer.restart();
                } else {
                    showFallbackContent();
                }
                return false;
            });
        }

        function fetchJLPTKanjiFromGithub(jlptLevel, source) {
            var jlptNum = parseInt(jlptLevel.substring(1));

            return new Promise(function(resolve, reject) {
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "https://raw.githubusercontent.com/davidluzgouveia/kanji-data/master/kanji-jouyou.json", true);
                xhr.timeout = 15000;

                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            try {
                                var data = JSON.parse(xhr.responseText);
                                var filtered = [];

                                for (var kanji in data) {
                                    if (data[kanji].jlpt_new === jlptNum) {
                                        filtered.push(kanji);
                                    }
                                }

                                allKanji = filtered;
                                networkAvailable = true;
                                retryAttempts = 0;
                                resolve(true);
                            } catch (e) {
                                reject("parse_error");
                            }
                        } else {
                            reject(xhr.status);
                        }
                    }
                };

                xhr.ontimeout = function() { reject("timeout"); };
                xhr.onerror = function() { reject("network_error"); };
                xhr.send();
            });
        }

        function stripHtml(text) {
            return text.replace(/<[^>]+>/g, "");
        }

        function fetchWanikaniMnemonic(kanji) {
            var token = plasmoid.configuration.wanikaniToken || "";
            if (token === "") return;

            var xhr = new XMLHttpRequest();
            xhr.open("GET", "https://api.wanikani.com/v2/subjects?types=kanji&slugs=" + encodeURIComponent(kanji), true);
            xhr.timeout = 8000;
            xhr.setRequestHeader("Authorization", "Bearer " + token);

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            var resp = JSON.parse(xhr.responseText);
                            if (resp.data && resp.data.length > 0) {
                                var d = resp.data[0].data;
                                lastMnemonic = d.meaning_mnemonic ? stripHtml(d.meaning_mnemonic) : "";
                                lastMnemonicReading = d.reading_mnemonic ? stripHtml(d.reading_mnemonic) : "";
                            } else {
                                lastMnemonic = "[No mnemonic available for this kanji]";
                                lastMnemonicReading = "";
                            }
                            if (lastMnemonic === "") {
                                lastMnemonic = "[No mnemonic available for this kanji]";
                            }
                            if (plasmoid.configuration.showMnemonics) {
                                mnemonicAvailable = true;
                            }
                        } catch (e) {}
                    } else if (xhr.status === 401) {
                        lastMnemonic = "[Invalid WaniKani token]";
                        lastMnemonicReading = "";
                        if (plasmoid.configuration.showMnemonics) {
                            mnemonicAvailable = true;
                        }
                    }
                }
            };

            xhr.onerror = function() {};
            xhr.send();
        }

        function setRandomKanjiInfos() {
            if (allKanji.length > 0) {
                var randomKanji = allKanji[Math.floor(Math.random() * allKanji.length)];

                fetchKanjiInfos(
                    randomKanji,
                    function(response) {
                        var kanjiData = response;
                        kanjiLabel.text = kanjiData.kanji;
                        showDetails(kanjiData);

                        lastKanjiData = kanjiData.kanji;
                        lastKanjiDescription = descriptionLabel.text;
                        lastMnemonic = "";
                        lastMnemonicReading = "";
                        showingMnemonic = false;
                        mnemonicAvailable = plasmoid.configuration.showMnemonics && plasmoid.configuration.wanikaniToken !== "";

                        if (mnemonicAvailable) {
                            fetchWanikaniMnemonic(kanjiData.kanji);
                        }
                    },
                    function(status, statusText) {
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

        function showDetails(kanjiData) {
            descriptionLabel.text =
                "Meaning: " + kanjiData.meanings.join(", ") + "\n" +
                "Kun: " + kanjiData.kun_readings.join(", ") + "\n" +
                "On: " + kanjiData.on_readings.join(", ");
        }

        function showFallbackContent() {
            showingMnemonic = false;
            lastMnemonic = "";
            lastMnemonicReading = "";
            mnemonicAvailable = false;

            if (lastKanjiData !== "") {
                kanjiLabel.text = lastKanjiData;
                descriptionLabel.text = lastKanjiDescription + "\n\n(Offline mode - showing cached kanji)";
            } else {
                kanjiLabel.text = "学";
                descriptionLabel.text = "Meaning: study, learning, science\nKun: まな.ぶ\nOn: ガク\n\n(Offline mode - network unavailable)";
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
                color: plasmoid.configuration.kanjiColor || "#FFFFFF"
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (kanjiLabel.text !== "" && kanjiLabel.text !== "Loading..." && kanjiLabel.text !== "Error loading kanji" && kanjiLabel.text !== "学") {
                            var urlTemplate = plasmoid.configuration.redirectUrl || "https://jotoba.de/search/default/%kanji%?l=%lang%";
                            var lang = plasmoid.configuration.redirectLanguage || "es-ES";
                            var url = urlTemplate.replace("%kanji%", encodeURIComponent(kanjiLabel.text)).replace("%lang%", lang);
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
                    kanjiLabel.text = "Loading...";
                    descriptionLabel.text = "";
                    apiHandler.retryAttempts = 0;

                    apiHandler.fetchAllKanji().then(function(success) {
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            clip: true

            Label {
                id: descriptionLabel
                text: ""
                font.pointSize: 12
                color: plasmoid.configuration.descriptionColor || "#CCCCCC"
                Layout.fillWidth: true
                Layout.fillHeight: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                padding: 8

                MouseArea {
                    anchors.fill: parent
                    cursorShape: apiHandler.mnemonicAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    visible: apiHandler.mnemonicAvailable
                    onClicked: {
                        apiHandler.showingMnemonic = !apiHandler.showingMnemonic
                        if (apiHandler.showingMnemonic) {
                            var text = apiHandler.lastMnemonic;
                            if (apiHandler.lastMnemonicReading !== "") {
                                text += "\n\n" + apiHandler.lastMnemonicReading;
                            }
                            descriptionLabel.text = text;
                        } else {
                            descriptionLabel.text = apiHandler.lastKanjiDescription;
                        }
                    }
                }
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
            midnightTimer.interval = 86400000;
            midnightTimer.repeat = true;
            midnightTimer.running = true;
        }
    }

    Timer {
        id: retryTimer
        running: false
        repeat: false
        onTriggered: {
            apiHandler.fetchAllKanji().then(function(success) {
                if (success) {
                    apiHandler.setRandomKanjiInfos();
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
            apiHandler.fetchAllKanji().then(function(success) {
                if (success) {
                    apiHandler.setRandomKanjiInfos();
                    midnightTimer.interval = apiHandler.msUntilMidnight();
                    midnightTimer.running = true;
                }
            });
        }
    }

    Connections {
        target: plasmoid.configuration
        function onJlptLevelChanged() { reloadKanji(); }
        function onKanjiSourceChanged() { reloadKanji(); }
        function onShowMnemonicsChanged() {
            apiHandler.mnemonicAvailable = plasmoid.configuration.showMnemonics && plasmoid.configuration.wanikaniToken !== "" && apiHandler.lastMnemonic !== "";
            if (!apiHandler.mnemonicAvailable && apiHandler.showingMnemonic) {
                apiHandler.showingMnemonic = false;
                descriptionLabel.text = apiHandler.lastKanjiDescription;
            }
        }
        function onDescriptionColorChanged() {
            descriptionLabel.color = plasmoid.configuration.descriptionColor || "#CCCCCC";
        }
        function onKanjiColorChanged() {
            kanjiLabel.color = plasmoid.configuration.kanjiColor || "#FFFFFF";
        }
    }

    function reloadKanji() {
        kanjiLabel.text = "Loading...";
        descriptionLabel.text = "";
        apiHandler.allKanji = [];
        apiHandler.retryAttempts = 0;

        apiHandler.fetchAllKanji().then(function(success) {
            if (success) {
                apiHandler.setRandomKanjiInfos();
                if (!midnightTimer.running) {
                    midnightTimer.interval = apiHandler.msUntilMidnight();
                    midnightTimer.running = true;
                }
            }
        });
    }

    Component.onCompleted: {
        kanjiLabel.text = "Loading...";
        descriptionLabel.text = "";
        startupDelayTimer.start();
    }
}
