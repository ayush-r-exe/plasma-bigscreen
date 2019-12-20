/*
 * Copyright 2019 Aditya Mehra <aix.m@outlook.com>
 * Copyright 2015 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3 as Controls
import QtQuick.Window 2.3
import QtGraphicalEffects 1.12
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kirigami 2.5 as Kirigami
import Mycroft 1.0 as Mycroft

import "launcher"
import "indicators" as Indicators

Item {
    id: root
    Layout.minimumWidth: Screen.desktopAvailableWidth
    Layout.minimumHeight: Screen.desktopAvailableHeight * 0.6


    property Item wallpaper

    Containment.onAppletAdded: {
        addApplet(applet, x, y);
    }

    Component.onCompleted: {
        for (var i in plasmoid.applets) {
            root.addApplet(plasmoid.applets[i], -1, -1)
        }
    }

    function addApplet(applet, x, y) {
        var container = appletContainerComponent.createObject(appletsLayout)
        print("Applet added: " + applet + " " + applet.title)
        //container.width = units.iconSizes.medium
        container.height = appletsLayout.height

        applet.parent = container;
        container.applet = applet;
        applet.anchors.fill = container;
        applet.visible = true;
        applet.expanded = false;
    }

    Component {
        id: appletContainerComponent
        Item {
            property Item applet
            visible: applet && applet.status !== PlasmaCore.Types.HiddenStatus && applet.status !== PlasmaCore.Types.PassiveStatus
            Layout.fillHeight: true
            Layout.minimumWidth: Math.max(applet.implicitWidth, applet.Layout.preferredWidth, applet.Layout.minimumWidth) + units.gridUnit
            Layout.maximumWidth: Layout.minimumWidth
        }
    }

    FeedbackWindow {
        id: feedbackWindow
    }

    MycroftWindow {
        id: mycroftWindow
    }

    PlasmaCore.ColorScope {
        id: topBar
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        height: units.iconSizes.medium + units.smallSpacing * 2
        opacity: !mycroftWindow.visible

        Behavior on opacity {
            OpacityAnimator {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        RowLayout {
            id: appletsLayout
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: units.smallSpacing
            }
        }

        RowLayout {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: units.smallSpacing
            }

            Indicators.Volume {
                id: volumeIndicator
                Layout.fillHeight: true
                implicitWidth: height
                KeyNavigation.down: launcher
                KeyNavigation.right: wifiIndicator
                KeyNavigation.tab: wifiIndicator
                KeyNavigation.backtab: launcher
                KeyNavigation.left: volumeIndicator
            }

            Indicators.Wifi {
                id: wifiIndicator
                Layout.fillHeight: true
                implicitWidth: height
                KeyNavigation.down: launcher
                KeyNavigation.right: shutdownIndicator
                KeyNavigation.tab: shutdownIndicator
                KeyNavigation.backtab: volumeIndicator
                KeyNavigation.left: volumeIndicator
            }
            Indicators.Shutdown {
                id: shutdownIndicator
                KeyNavigation.down: launcher
                KeyNavigation.right: launcher
                KeyNavigation.tab: launcher
                KeyNavigation.backtab: wifiIndicator
                KeyNavigation.left: wifiIndicator
            }
        }

        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 2
            color: Qt.rgba(0, 0, 0, 0.6)
            radius: 8.0
            samples: 17
        }
    }

    LauncherMenu {
        id: launcher
        width: parent.width
        height: parent.height - topBar.height
    

        states: [
            State {
                when: !mycroftWindow.visible
                PropertyChanges {
                    target: launcher
                    opacity: 1
                    y: topBar.height
                }
            },
            State {
                when: mycroftWindow.visible
                PropertyChanges {
                    target: launcher
                    opacity: 0
                    y: root.height / 4
                }
            }
        ]

        transitions: [
            Transition {
                ParallelAnimation {
                    OpacityAnimator {
                        duration: units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    YAnimator {
                        duration: units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        ]
    }

    Mycroft.StatusIndicator {
        id: si
        z: 2
        visible: !mycroftWindow.visible
        anchors {
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.largeSpacing
            topMargin: Kirigami.Units.largeSpacing * 3 + plasmoid.availableScreenRect.y
        }
    }

    Kirigami.Heading {
        id: inputQuery
        Kirigami.Theme.colorSet: mainView.Kirigami.Theme.colorSet
        anchors.right: si.left
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.verticalCenter: si.verticalCenter
        level: 3
        opacity: 0
        onTextChanged: {
            opacity = 1;
            utteranceTimer.restart();
        }
        Timer {
            id: utteranceTimer
            interval: 3000
            onTriggered: {
                inputQuery.text = "";
                inputQuery.opacity = 0
            }
        }
        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        Connections {
            target: Mycroft.MycroftController
            onIntentRecevied: {
                if(type == "recognizer_loop:utterance") {
                    inputQuery.text = data.utterances[0]
                }
            }
        }
    }
}
