import QtQuick
Item {
    width: 200; height: 200
    Rectangle { color: "red"; width: 100; height: 100 }
    Rectangle { color: "blue"; width: 50; height: 50; blendMode: Item.DestinationOut }
}
