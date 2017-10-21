/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

////////////////// new window and needs attention animation
SequentialAnimation{
    id:newWindowAnimation

    property int speed: root.durationTime*units.longDuration
    property bool isDemandingAttention: (IsDemandingAttention === true)
    property bool containsMouse: mainItemContainer.containsMouse
    property bool needsThicknessSent: false //flag to check if the signal for thickness was sent
    property bool fastRestoreAfterEnd: false

    SequentialAnimation{
        alwaysRunToEnd: true

        ParallelAnimation{
            PropertyAnimation {
                target: wrapper
                property: (icList.orientation == Qt.Vertical) ? "tempScaleWidth" : "tempScaleHeight"
                to: 1 + (0.6 * (root.zoomFactor-1))
                duration: newWindowAnimation.speed
                easing.type: Easing.OutQuad
            }

            PropertyAnimation {
                target: wrapper
                property: (icList.orientation == Qt.Horizontal) ? "tempScaleWidth" : "tempScaleHeight"
                to: 1
                duration: newWindowAnimation.speed
                easing.type: Easing.OutQuad
            }
        }

        PropertyAnimation {
            target: wrapper
            property: (icList.orientation == Qt.Vertical) ? "tempScaleWidth" : "tempScaleHeight"
            to: 1
            duration: 3*root.durationTime*newWindowAnimation.speed
            easing.type: Easing.OutBounce
        }

        ScriptAction{
            script:{
                //if (mainItemContainer.containsMouse) {
                //     newWindowAnimation.stop();
                // }
                /*if (!newWindowAnimation.isDemandingAttention
                        || (plasmoid.status === PlasmaCore.Types.PassiveStatus && newWindowAnimation.loops > 2)){
                    newWindowAnimation.clear();
                }*/
            }
        }
    }

    function clear(){
        loops = 1;
        newWindowAnimation.stop();
        //  iconImageBuffer.anchors.centerIn = iconImageBuffer.parent;

        wrapper.tempScaleWidth = 1;
        wrapper.tempScaleHeight = 1;

        mainItemContainer.setBlockingAnimation(false);
        mainItemContainer.inAttentionAnimation = false;
    }

    onStopped: {
        sendEndOfNeedThicknessAnimation();
        clear();
        if (fastRestoreAfterEnd) {
            fastRestoreAfterEnd = false;
            if (mainItemContainer.containsMouse)
                fastRestoreAnimation.start();
        }
    }

    onIsDemandingAttentionChanged: {
        if(isDemandingAttention){
            bounceNewWindow();
        }
    }

    function sendEndOfNeedThicknessAnimation(){
        if (needsThicknessSent) {
            needsThicknessSent = false;
            root.signalAnimationsNeedThickness(-1);
        }
    }

    function init(){
        mainItemContainer.setBlockingAnimation(true);

        wrapper.tempScaleWidth = wrapper.mScale;
        wrapper.tempScaleHeight = wrapper.mScale;

        if(!isDemandingAttention)
            loops = 2;
        else {
            loops = 20;
            mainItemContainer.inAttentionAnimation = true;
        }

        if (!needsThicknessSent) {
            needsThicknessSent = true;
            root.signalAnimationsNeedThickness(1);
        }

        // icList.hoveredIndex = -1;
    }

    function bounceNewWindow(){
        if (isDemandingAttention && !root.dockIsHidden && (root.zoomFactor > 1)){
            newWindowAnimation.init();
            start();
        }
    }

    Component.onCompleted: {
        mainItemContainer.groupWindowAdded.connect(bounceNewWindow);
    }

    Component.onDestruction: {
        sendEndOfNeedThicknessAnimation();
    }
}
