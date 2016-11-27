import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
	property alias title: header.title
	property alias minimum: slider.minimumValue
	property alias maximum: slider.maximumValue
	property alias number: slider.value
	property alias unit: slider.label

	PageHeader {
		id: "header"
		width: parent.width
	}

	Slider {
		id: "slider"
		width: parent.width
		anchors.top: header.bottom
		valueText: value
		stepSize: 1
	}
}
