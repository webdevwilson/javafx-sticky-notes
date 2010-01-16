package stickynote;

import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.Exception;

import javax.swing.JEditorPane;

import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.ext.swing.SwingComponent;
import javafx.geometry.HPos;
import javafx.io.Resource;
import javafx.io.Storage;
import javafx.scene.Cursor;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.control.Hyperlink;
import javafx.scene.effect.DropShadow;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.scene.paint.Color;
import javafx.scene.paint.LinearGradient;
import javafx.scene.paint.Stop;
import javafx.scene.shape.LineTo;
import javafx.scene.shape.MoveTo;
import javafx.scene.shape.Path;
import javafx.scene.shape.Rectangle;
import javafx.stage.Screen;
import javafx.stage.Stage;
import javafx.stage.StageStyle;
import javafx.util.Properties;

// configs
def dropShadowRadius = 8;
def topBarHeight = 28;
def topBarColor = Color.rgb(247, 246, 181);
def noteColorTop = Color.web("#fdfdcb");
def noteColorBottom = Color.web("#fbf8a0");
def minWidth = 180;
def minHeight = 180;
def minX = Screen.primary.visualBounds.minX - dropShadowRadius;
def minY = Screen.primary.visualBounds.minY - dropShadowRadius;
def maxX = bind Screen.primary.visualBounds.maxX - noteWidth + dropShadowRadius;
def maxY = bind Screen.primary.visualBounds.maxY - noteHeight + dropShadowRadius;

// model variables
var noteWidth: Float = minWidth on replace { dirtyModel = true };
var noteHeight: Float = minHeight on replace { dirtyModel = true };
var noteX: Float = 100 on replace { dirtyModel = true };
var noteY: Float = 100 on replace { dirtyModel = true };
var text = "Click here to write notes" on replace { dirtyModel = true };

// load stored data
var storage = Storage { source: "model.properties" }
{
    var resource: Resource = storage.resource;
    var properties: Properties = new Properties();
    var inputStream: InputStream;
    try {
        inputStream = resource.openInputStream();
        properties.load(inputStream);
        text = properties.get("text");
        noteX = Float.parseFloat(properties.get("screenX"));
        noteY = Float.parseFloat(properties.get("screenY"));
        noteWidth = Float.parseFloat(properties.get("width"));
        noteHeight = Float.parseFloat(properties.get("height"));
    } catch (e: Exception) {
        println("Exception in Model.load():{e}");
        e.printStackTrace();
    } finally {
        try {
            inputStream.close();
        } catch(e: Exception) {
            println("Exception closing inputstream {e}");
        }
    }
}

// dirty, nasty swing component :)
def textbox: JEditorPane = new JEditorPane("text/plain","");
textbox.setBackground(new java.awt.Color(0,0,0,0));
textbox.setText(text);
def sbox = SwingComponent.wrap( textbox );

// the stage
var sceneRef : Scene;
def stageRef : Stage = Stage {
    width: bind noteWidth
    height: bind noteHeight
    x: bind noteX
    y: bind noteY
    style: StageStyle.TRANSPARENT
    onClose: saveModel
    scene: sceneRef = Scene {
        fill: Color.TRANSPARENT
        content: [
            // background square
            Rectangle {
                fill: LinearGradient {
                          startX: 0.0, startY: 0.0, endX: 0.0, endY: 1.0
                          proportional: true
                          stops: [ Stop { offset: 0.0 color: noteColorTop },
                                   Stop { offset: 1.0 color: noteColorBottom } ]
                      }
                effect: DropShadow { radius: dropShadowRadius offsetY: 3 color: Color.color(0.4, 0.4, 0.4) }
                x: dropShadowRadius
                y: dropShadowRadius
                width:  bind stageRef.width  - (2*dropShadowRadius)
                height: bind stageRef.height - (2*dropShadowRadius)
                cursor: Cursor.TEXT
                onMouseClicked: function(e : MouseEvent) {
                    textbox.grabFocus();
                }
            }
            // topbar
            Rectangle {
                fill: topBarColor
                x: dropShadowRadius
                y: dropShadowRadius
                width: bind stageRef.width - (2*dropShadowRadius)
                height: topBarHeight
                cursor: Cursor.DEFAULT
                onMouseDragged: function(e: MouseEvent) {

                    noteX = e.screenX - e.dragAnchorX;
                    if( noteX < minX ) {
                        noteX = minX;
                    } else if ( noteX > maxX ) {
                        noteX = maxX;
                    }

                   noteY = e.screenY - e.dragAnchorY;
                   if( noteY < minY ) {
                        noteY = minY;
                   } else if ( noteY > maxY ) {
                        noteY = maxY;
                   }
                }
            }
            // resize box
            Rectangle {
                width: 12
                height: 12
                x: bind noteWidth - 12 - dropShadowRadius
                y: bind noteHeight - 12 - dropShadowRadius
                fill: Color.TRANSPARENT
                cursor: Cursor.SE_RESIZE
                onMouseDragged: function(e : MouseEvent) {

                    if( e.sceneX < minWidth ) { noteWidth = minWidth; }
                    else noteWidth = e.sceneX;

                    if( e.sceneY < minHeight ) { noteHeight = minHeight; }
                    else noteHeight = e.sceneY;

                    setTextboxSize();
                }
            }
            HBox {
                layoutX: 3
                layoutY: 14
                width: bind stageRef.width - 22
                height: bind topBarHeight
                cursor: Cursor.HAND
                hpos: HPos.RIGHT
                spacing: 8
                content: [
                    Hyperlink {
                        text: "Close"
                        onMouseClicked: function(e : MouseEvent) {
                            stageRef.close();
                        }
                    }
                ]
            }
            // textbox wrapper
            {
                sbox.layoutX = dropShadowRadius;
                sbox.layoutY = topBarHeight + dropShadowRadius;
                sbox;
            }
            Group {
                layoutX: bind noteWidth - dropShadowRadius - 4
                layoutY: bind noteHeight - dropShadowRadius - 4
                content: [
                    Path {
                        stroke: Color.web("#b2b071")
                        elements: [
                            // arrows
                            MoveTo { x: 0 y: -1 }  LineTo { x: 0  y: 0 }  LineTo { x: -1 y: 0 }
                            MoveTo { x: 0  y: -4 } LineTo { x: 0  y: -3 } LineTo { x: -1 y: -3 }
                            MoveTo { x: 0  y: -7 } LineTo { x: 0  y: -6 } LineTo { x: -1 y: -6 }
                            MoveTo { x: -3 y: -1 } LineTo { x: -3 y: 0 }  LineTo { x: -4  y: 0 }
                            MoveTo { x: -6 y: -1 } LineTo { x: -6 y: 0 }  LineTo { x: -7  y: 0 }
                            MoveTo { x: -3 y: -4 } LineTo { x: -3 y: -3 } LineTo { x: -4  y: -3 }
                        ]
                    }
                ]
            }
        ]
    }
}

// do it this way since we can't bind the wrapped swing component
function setTextboxSize() {
    sbox.height = noteHeight - topBarHeight - (dropShadowRadius * 2);
    sbox.width = noteWidth - (dropShadowRadius * 2);
}

setTextboxSize();

// handle model storage
var dirtyModel: Boolean = false;
var saveInProgress: Boolean = false;
function saveModel() {

    // update text
    if( not text.equals(textbox.getText() ) ) text = textbox.getText();

    // only one save at a time, and only when necessary
    if( not dirtyModel or saveInProgress ) return;

    saveInProgress = true;
    var resource : Resource = storage.resource;
    var properties : Properties = new Properties();
    properties.put("screenX", "{noteX}");
    properties.put("screenY", "{noteY}");
    properties.put("text", text);
    properties.put("width", "{noteWidth}");
    properties.put("height", "{noteHeight}");
    var outputStream : OutputStream;
    try {
        outputStream = resource.openOutputStream(true);
        properties.store(outputStream);
    } catch (ioe:IOException) {
        println("IOException saving data:{ioe}");
    } finally {
        try {
            outputStream.close();
        } catch (ioe: IOException) {
            println("IOException closing output stream:{ioe}");
        }
    }
    saveInProgress = false;
    dirtyModel = false;
}

// start thread that saves model every 5 seconds if dirty
Timeline {
    repeatCount: Timeline.INDEFINITE
    keyFrames: [
        KeyFrame {
            time: 5s
            action: saveModel
        }
    ]
}.play();

return stageRef;