//=============================================================================
//  JIANPU plugin for MuseScore.  
//  Dean Wedel and Ryan Isaac
//  
//=============================================================================

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import MuseScore 1.0

MuseScore {
      version:  "1.0"
      description: "Add JianPu numbering."
      menuPath: "Plugins.JianPu"
      pluginType: "dialog"

      id: window
      width: 240
      height: 200
      GridLayout {
            id: grid
            columns: 2
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins : 10
            Text {
                  text: "JianPu position:"
            }
            SpinBox {
                  id: yOffSpinBox
                  Layout.minimumWidth: 60
                  Layout.minimumHeight: 20
                  decimals: 1
                  stepSize: 0.2
                  maximumValue: 8.0
                  minimumValue: -15.0
                  value: 0.0
            }
            Text {
                  text: "Underline spacing:"
            }
            SpinBox {
                  id: underlineSpacingSpinBox
                  Layout.minimumWidth: 60
                  Layout.minimumHeight: 20
                  decimals: 2
                  stepSize: 0.05
                  maximumValue: 1.0
                  minimumValue: 0.1
                  value: 0.35
            }
            Text {
                  text: "Underdot position:"
            }
            SpinBox {
                  id: underdotPositionSpinBox
                  Layout.minimumWidth: 60
                  Layout.minimumHeight: 20
                  decimals: 2
                  stepSize: 0.05
                  maximumValue: 0.0
                  minimumValue: -3.0
                  value: -1.00
            }
            Text {
                  text: "Octave offset:"
            }
            SpinBox {
                  id: octaveOffset
                  Layout.minimumWidth: 60
                  Layout.minimumHeight: 20
                  decimals: 0
                  stepSize: 1
                  maximumValue: 2
                  minimumValue: -2
                  value: 0
            }
            CheckBox {
                  id: shapeCheckBox
                  text: "Shape notes also?"
                  checked: false
            }
      }
      RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: grid.bottom
            height: 70
            Button {
              id: okButton
              text: "Ok"
              onClicked: {
                apply()
                Qt.quit()
              }
            }
            Button {
              id: closeButton
              text: "Close"
              onClicked: { Qt.quit() }
            }

      }


      //                               -7   -6   -5   -4   -3   -2   -1    0    1    2    3    4    5    6    7
      property variant scales :       ['C', 'G', 'D', 'A', 'E', 'B', 'F', 'C', 'G', 'D', 'A', 'E', 'B', 'F', 'C'];
      property variant scaleTwelveB : [ 2,   8,   3,  10,   5,   0,   7,   2,   9,   4,  11,   6,   1,   8,   2 ];
      property variant scaleTwelveC : [ 0,   6,   1,   8,   3,  10,   5,   0,   7,   2,   9,   4,  11,   6,   0 ];
      // scaleTwelve is in base 12; only used as an offset subtracted from the midi note value to arrive at an octave value

      // Apply the given function to all notes in selection
      // or, if nothing is selected, in the entire score

      function applyToNotesInSelection(func) {
            var cursor = curScore.newCursor();
            cursor.rewind(1);
            var startStaff;
            var endStaff;
            var endTick;
            var fullScore = false;
            var oneSpace = "                                              "; // because we can't use .repeat in this code for repeating spaces 
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff and end with last
                  endStaff = 0; // curScore.nstaves - 1; //first staff only 
            } else {
                  startStaff = cursor.staffIdx;
                  cursor.rewind(2);
                  if (cursor.tick == 0) {
                        // this happens when the selection includes
                        // the last measure of the score.
                        // rewind(2) goes behind the last segment (where
                        // there's none) and sets tick=0
                        endTick = curScore.lastSegment.tick + 1;
                  } else {
                        endTick = cursor.tick;
                  }
                  endStaff = cursor.staffIdx;
            }
            
            for (var staff = startStaff; staff <= endStaff; staff++) {
                  for (var voice = 0; voice < 4; voice++) {
                        cursor.rewind(1); // sets voice to 0
                        cursor.voice = voice; //voice has to be set after goTo
                        cursor.staffIdx = staff;
                        var lastBeam = 0;      // identifier of start of beam 
                        var lastBeamX = 0;     // pos.x value of start of beam 
                        var lastBeamTicks = 0;
                        var yOff = -yOffSpinBox.value; // .pos.y OFFSET. Positive is lower, negative is higher; so we negative the spinbox to get the correct value 
                        var yOffUnderline = yOff + 0.2  // position offset for first underline, below jianpu number by amount set here
                        var underlineSpacing = underlineSpacingSpinBox.value; //Spacing between stacked underlines. Positive
                        if (fullScore)
                              cursor.rewind(0) // if no selection, beginning of score

                        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                              if (cursor.element && cursor.element.type == Element.CHORD) {
                                    /*var graceChords = cursor.element.graceNotes;
                                    for (var i = 0; i < graceChords.length; i++) {
                                          // iterate through all grace chords
                                          var notes = graceChords[i].notes;
                                          for (var j = 0; j < notes.length; j++) {
                                                // and go over all notes of this grace chord
                                                func(notes[j], cursor.keySignature);
                                          }
                                    }*/ // not working with grace notes right now
                                    var notes = cursor.element.notes;
				
                                    for (var i = (notes.length - 1); i < notes.length; i++) { // var i = 0 , changed so only 'iterates' through top note in chord
                                          var note = notes[i];
                                          //console.log("notes[i] " + i)					  
                                          if (shapeCheckBox.checked) { 
                                                func(note, cursor.keySignature);
                                          }

                                          if (voice==0) 
                                          {
                                                // do jianpu

//=============================================================================
//                             DETERMINE JIANPU NUMBER
//=============================================================================
                                                var tpcNames = "FCGDAEB";
                                                var name = tpcNames[(note.tpc + 1) % 7]; // name is the ABC for the NOTE we are on
                                                //console.log("cursor.keySignature " + cursor.keySignature)
                                                //console.log("note.pitch " + note.pitch);
                                                //console.log("scaleTwelveB[cursor.keySignature+7] =" + scaleTwelveB[cursor.keySignature+7]);
                                                var names = "CDEFGAB";
                                                var octave = Math.floor(((note.pitch - scaleTwelveB[cursor.keySignature+7]) - 58) / 12 ) + octaveOffset.value // 60 is our magic number at MIDDLE C
                                                // the first DO at or above MIDDLE C will be the 'no dot DO'
                                                // octave is 0 when no dots, positive: number of dots above, negative: number of dots below.
                                                var scale = scales[cursor.keySignature+7]; //scale is the ABC of our current key signature
                                                var jpText = ""+((names.indexOf(name) - names.indexOf(scale) +28)%7+1);// this is the JIANPU NUMBER for further use below
                                                
//=============================================================================
//                              MAIN JIANPU DRAWING
//=============================================================================
                                                var text0 = newElement(Element.STAFF_TEXT); //text0 is the main jianpu
                                                text0.pos.x = 0; /*-2.5 * (graceChords.length - i); //shift to the right for each 
                                                      subsequent note in the chord, this should be nonfunctional if we're 
                                                      only doing the top note per chord.  */
                                                text0.pos.y = yOff + 0.0; // this is the position above the line for the jianpu note. yOff is already inverted
                                                text0.text = jpText;
                                                console.log("jpText = " + jpText + ", octave = " + octave + ", ticks =" + cursor.element.duration.ticks)
//=============================================================================
//                                DOTTED NOTES
//=============================================================================
                                                if (cursor.element.duration.ticks < 960) //we don't want to add dots to longer notes
                                                {
                                                      var dots = note.dotsCount
                                                      for (; dots > 0; dots--)
                                                      {
                                                            text0.text+=" <font size=\"7\"/>•"; // dot in a smaller font
                                                      }
                                                }
                                                cursor.add(text0); //finish main jianpu drawing
//=============================================================================
//           AFTER-DASHES on long notes (Half, dotted Half, and Whole)
//=============================================================================
                                                // for the half through whole notes, first determine if there's another note or rest in this measure. 
                                                // If so, we can centre the dashes between this note and the next. Otherwise, we'll centre the 
                                                // dashes between this note and the end barline for this measure.
                                                //console.log("cursor.segment.next " + cursor.segment.next + "; cursor.tick " + cursor.tick) //+ "; endTick " + endTick)
                                                var dashPosCenter
                                                if (cursor.element.duration.ticks >= 960) {
                                                      if ((cursor.tick + cursor.element.duration.ticks) >= cursor.measure.lastSegment.tick) {
                                                            //this is the last note in this voice in this measure, so we base off right barline
                                                            dashPosCenter = ((-cursor.segment.pos.x + cursor.measure.bbox.width - 1) / 2)
                                                      }
                                                      else {
                                                            //there is at least one more note in this voice in this measure, so we 
                                                            //base off next note where ((same voice) or (tick == (cursor.tick + element.ticks)))
                                                            //But, we don't know if the other voices have notes before the next note in this voice...
                                                            var targetTick = (cursor.tick + cursor.element.duration.ticks)
                                                            var targetSeg; //we'll find that segment and hunt it down
                                                            //this seems messy.  But it was easier than defining a new cursor and iterating to 
                                                            //the target segment.  Maybe not, though.
                                                            if (cursor.segment.next.tick == targetTick){ //maybe, the next segment is the note we want
                                                                  targetSeg = cursor.segment.next
                                                            } else if (cursor.measure.lastSegment.tick == targetTick){//we have the situation where we have to find the right segment in this measure.
                                                                  targetSeg = cursor.measure.lastSegment // let's play hide and seek
                                                            } else if (cursor.segment.next.next.tick == targetTick){
                                                                  targetSeg = cursor.segment.next.next
                                                            } else if (cursor.segment.next.next.next.tick == targetTick){
                                                                  targetSeg = cursor.segment.next.next.next
                                                            } else if (cursor.segment.next.next.next.next.tick == targetTick){
                                                                  targetSeg = cursor.segment.next.next.next.next
                                                            } else if (cursor.segment.next.next.next.next.next.tick == targetTick){
                                                                  targetSeg = cursor.segment.next.next.next.next.next // no one can say we gave up too easily
                                                            } else {
                                                                  targetSeg = cursor.segment.next //hopefully this never happens 
                                                            }
                                                            
                                                            dashPosCenter = (targetSeg.pos.x - cursor.segment.pos.x) / 2 ;
                                                      }
                                                }
                                                
                                                if (cursor.element.duration.ticks==1920) // WHOLE
                                                {
                                                      var dashSpace3 = oneSpace.substring(1, Math.floor(dashPosCenter * 0.9));
                                                      var text2 = newElement(Element.STAFF_TEXT);
                                                      text2.pos.x = dashPosCenter * 0.5; // since dPC is centre for one dash, we'll go 1/2 for three dashes 
                                                      text2.pos.y = yOff + 0.1; // this is the position above the line for the jianpu note
                                                      text2.text="<font size=\"7\"/>—" + dashSpace3 + "—" + dashSpace3 + "—"; //we should use Math.floor(dashPosCenter * magic) as the number of spaces
                                                      cursor.add(text2);
                                                }
                                                else if (cursor.element.duration.ticks==1440) // DOTTED HALF
                                                {
                                                      var dashSpace2 = oneSpace.substring(1, Math.floor(dashPosCenter * 1.2));
                                                      var text2 = newElement(Element.STAFF_TEXT);
                                                      text2.pos.x = dashPosCenter * 0.67; //since dPC is centre for one dash, we'll go 2/3 for two dashes 
                                                      text2.pos.y =  yOff + 0.1; // this is the position above the line for the jianpu note
                                                      text2.text="<font size=\"7\"/>—" + dashSpace2 + "—"; // we should use Math.floor(dashPosCenter) as the number of spaces
                                                      cursor.add(text2);
                                                }
                                                else if (cursor.element.duration.ticks==960) // HALF
                                                {
                                                      var text2 = newElement(Element.STAFF_TEXT);
                                                      text2.pos.x = dashPosCenter; //(-2.5 * (graceChords.length - (i-1)))+3.95;
                                                      text2.pos.y = yOff + 0.1; // this is the position above the line for the jianpu note
                                                      text2.text="<font size=\"7\"/>—"; //</font> half
                                                      cursor.add(text2);
                                                }
//=============================================================================
//                 UNDERLINES on short notes (Eighth and shorter)
//=============================================================================
                                                // underlines for short notes (eighth and shorter)
                                                else if (cursor.element.duration.ticks==240 || cursor.element.duration.ticks==360 || cursor.element.duration.ticks==420) // EIGHTH or DOTTED EIGHTH
                                                {     //2018-04-04 decided to revamp following feature; instead of underlining the jianpu number, we'll add an
                                                      //extra line. This way the underlines don't have to follow the width of the jianpu number exactly, since
                                                      //we've had issues getting it to line up with different spacing / font size.
                                                      var text1 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                                      text1.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                                      text1.pos.y = yOffUnderline; // this is the position above the line for the jianpu underline (top)
                                                      text1.text="<u>​   </u>"; // no-width space "​" plus four spaces 
                                                      cursor.add(text1);
                                                }
                                                else if (cursor.element.duration.ticks==120 || cursor.element.duration.ticks==180 || cursor.element.duration.ticks==210) // SIXTEENTH or DOTTED SIXTEENTH
                                                {      
                                                      var text1 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                                      text1.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                                      text1.pos.y = yOffUnderline; // this is the position above the line for the jianpu underline (top)
                                                      text1.text="<u>​   </u>"; // no-width space "​" plus 3 spaces 
                                                      cursor.add(text1);
                                                      
                                                      var text2 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                                      text2.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                                      text2.pos.y = yOffUnderline + underlineSpacing; // this is the position above the line for the jianpu underline (lower)
                                                      text2.text="<u>​   </u>"; // no-width space "​" plus 3 spaces 
                                                      cursor.add(text2);
                                                }
                                                else if (cursor.element.duration.ticks==60 || cursor.element.duration.ticks==90 || cursor.element.duration.ticks==105) // THIRTYSECONDTH or DOTTED THIRTYSECONDTH
                                                {      
                                                      var text1 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline. 
                                                      text1.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                                      text1.pos.y = yOffUnderline; // this is the position above the line for the jianpu underline (top)
                                                      text1.text="<u>​   </u>"; // no-width space "​" plus 3 spaces 
                                                      cursor.add(text1);
                                                      
                                                      var text2 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline. 
                                                      text2.pos.x = -0.3;
                                                      text2.pos.y = yOffUnderline + underlineSpacing; // this is the position above the line for the jianpu underline (middle)
                                                      text2.text="<u>​   </u>"; // no-width space "​" plus 3 spaces
                                                      cursor.add(text2);
                                                      
                                                      var text3 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline.
                                                      text3.pos.x = -0.3;
                                                      text3.pos.y = yOffUnderline + (underlineSpacing * 2); // this is the position above the line for the jianpu underline (lowest)
                                                      text3.text="<u>​   </u>"; // no-width space "​" plus 3 spaces
                                                      cursor.add(text3);
                                                }

//=============================================================================
//                           BEAMS (JIANPU UNDERLINE)
//=============================================================================
// this doesn't beam rests; rest to rest beaming shouldn't exist, but eighth note to eighth rest should be able to beam somehow... Later project.
// 2018-01-23 added a no-width space to the beginning of each set of underlined spaces. On opening a file,
// MuseScore won't recognize a stafftext which contains only standard space characters.
                                                if (!!cursor.element.beam) { // current note contains a beam
                                                      
                                                      //console.log("cursor.element.beam.pagePos.x.toPrecision(6) " + cursor.element.beam.pagePos.x.toPrecision(6)) // useless
                                                      console.log("cursor.element.pagePos.x " + cursor.element.pagePos.x)
                                                      //console.log("cursor.element.pos " + cursor.element.pos)
                                                      //console.log("cursor.segment.tick " + cursor.segment.tick)
                                                      //console.log("cursor.element.beam.bbox " + cursor.element.beam.bbox) // not very accurate, therefore not useful
                                                      if (lastBeam == cursor.element.beam) {
                                                            // current beam is same as previous beam, so draw back one segment of jianpu beam
                                                            // draw beam on jianpu
                                                            console.log("beam on current note, same beam as a previous note. Drawing beam back to previous note...")
                                                            var beamLength = cursor.element.pagePos.x - lastBeamX; //cursor.element.beam.bbox.width;
                                                            //console.log("beamLength " + beamLength)
                                                            var jpbeamLength = (beamLength * 1.95).toFixed(0); //try x1.9 instead of x2.0 2018-04-04
                                                            // this seems messy 
                                                            // moving oneSpace to start so we can use it freely throughout
                                                            var moreSpaces = oneSpace.substring(1, jpbeamLength); 
                                                            // if only we could use .repeat() in this code...
                                                            //console.log("moreSpaces :" + moreSpaces + ": jpbeamLength = " + jpbeamLength);
                                                            
                                                            var textBeam = newElement(Element.STAFF_TEXT);
                                                            textBeam.pos.x = -beamLength ; // start drawing to the left of the current note by the length of the beam
                                                            textBeam.pos.y = yOffUnderline + 0.0; // this is the position above the line
                                                            textBeam.text="<u>​ " + moreSpaces + "</u>"; //no-width space "​" plus moreSpaces
                                                            cursor.add(textBeam);
                                                            if (Math.max(lastBeamTicks, cursor.element.duration.ticks) < 240) { //both ends of beam are shorter than eighth, i.e. at least SIXTEENTH, so at least a double-beam
                                                                  var textBeam2 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-beam. 
                                                                  textBeam2.pos.x = -beamLength; 
                                                                  textBeam2.pos.y = yOffUnderline + underlineSpacing; // this is the position above the line for the jianpu underline (lower)
                                                                  textBeam2.text="<u>​ " + moreSpaces + "</u>"; //no-width space "​" plus moreSpaces
                                                                  cursor.add(textBeam2);
                                                            }
                                                            if (Math.max(lastBeamTicks, cursor.element.duration.ticks) < 120) { //both ends of beam are shorter than sixteenth, i.e. at least THIRTYSECOND, so at least a triple-beam
                                                                  var textBeam3 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-beam. 
                                                                  textBeam3.pos.x = -beamLength; 
                                                                  textBeam3.pos.y = yOffUnderline + (underlineSpacing * 2); // this is the position above the line for the jianpu underline (lowest)
                                                                  textBeam3.text="<u>​ " + moreSpaces + "</u>"; //no-width space "​" plus moreSpaces
                                                                  cursor.add(textBeam3);
                                                            }
                                                      }
                                                      else { 
                                                      // this means we are starting a new beam. We have to draw it later, just get the info first.
                                                            console.log("beam on current note, left end of beam. Storing information for later")
                                                            lastBeam = cursor.element.beam
                                                      }
                                                      // on beams of over 2 notes, draw each segment individually; this way sixteenths
                                                      // and 32nds can be handled also. Therefore we update the drawback X position
                                                      // and ticks each time we draw
                                                      lastBeamX = cursor.element.pagePos.x
                                                      lastBeamTicks = cursor.element.duration.ticks
                                                }

//=============================================================================
//                                  SHARPS and FLATS
//=============================================================================
                                                var noteKey = (note.pitch - scaleTwelveC[cursor.keySignature+7]) % 12; 
                                                //noteKey is range 0 to 11 by half-steps, DO is 0
                                                var isSharp = false
                                                var isFlat = false
                                                
                                                // really wish there was a better way to treat the following 
                                                if (noteKey == 1) {        //between DO and RE
                                                      if (jpText == 1) {   //jianpu shows DO
                                                            isSharp = true
                                                      };
                                                      if (jpText == 2) {   //jianpu shows RE
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 3) {   //between RE and MI
                                                      if (jpText == 2) {   //jianpu shows RE
                                                            isSharp = true
                                                      };
                                                      if (jpText == 3) {   //jianpu shows MI
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 6) {   //between FA and SO
                                                      if (jpText == 4) {   //jianpu shows FA
                                                            isSharp = true
                                                      };
                                                      if (jpText == 5) {   //jianpu shows SO
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 8) {   //between SO and LA
                                                      if (jpText == 5) {   //jianpu shows SO
                                                            isSharp = true
                                                      };
                                                      if (jpText == 6) {   //jianpu shows LA
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 10) {  //between LA and TI
                                                      if (jpText == 6) {   //jianpu shows LA
                                                            isSharp = true
                                                      };
                                                      if (jpText == 7) {   //jianpu shows TI
                                                            isFlat = true
                                                      };
                                                }
                                                
                                                if (isFlat) {              //  ♭  Flat
                                                      var textF = newElement(Element.STAFF_TEXT); 
                                                      textF.pos.x = -0.8;
                                                      textF.pos.y = yOff - 0.8; 
                                                      textF.text="♭"; 
                                                      cursor.add(textF);
                                                } 
                                                else if (isSharp) {        //  ♯  Sharp
                                                      var textS = newElement(Element.STAFF_TEXT);  
                                                      textS.pos.x = -0.8;
                                                      textS.pos.y = yOff - 0.8; 
                                                      textS.text="♯"; 
                                                      cursor.add(textS);
                                                }
                                                
                                                
//=============================================================================
//                         UPPER and LOWER OCTAVE DOTS
//=============================================================================
                                                // octave is an integer with the number of dots needed (-down, +up)
                                                var o = octave
                                                for (; o < 0; o++)
                                                {
                                                      var text = newElement(Element.STAFF_TEXT);
                                                      text.pos.x = 0.25; // DOT needs a slight right
                                                      text.pos.y =  yOff - underdotPositionSpinBox.value - (o * 0.5); // this is the position above the line for the jianpu OVER DOT
                                                      if (cursor.element.duration.ticks>=240 && cursor.element.duration.ticks<=420)
                                                      {
                                                            text.pos.y =  text.pos.y + (underlineSpacing * 1) - 0.1; // the underdot for 8ths is lower
                                                      }
                                                      else if (cursor.element.duration.ticks>=120 && cursor.element.duration.ticks<=210)
                                                      {
                                                            text.pos.y =  text.pos.y + (underlineSpacing * 2) - 0.1; // the underdot for 16ths is lower
                                                      }
                                                      else if (cursor.element.duration.ticks>=60 && cursor.element.duration.ticks<=105)
                                                      {
                                                            text.pos.y =  text.pos.y + (underlineSpacing * 3) - 0.1; // the underdot for 32ndths is lower yet
                                                      }
                                                      text.text = "<font size=\"7\"/>•";//</font>
                                                      cursor.add(text);
                                                }
                                                for (; o > 0; o--)
                                                {
                                                      var text = newElement(Element.STAFF_TEXT);
                                                      text.pos.x = 0.25; // DOT needs a slight right
                                                      text.pos.y =  yOff - 0.3 - (o * 0.5); // this is the position above the line for the jianpu OVER DOT
                                                      text.text = "<font size=\"7\"/>•";//</font>
                                                      cursor.add(text);
                                                }
                                                
//=============================================================================
//                            TIES (development)
//=============================================================================
                                               
                                                //later project 
                                                if (note.tieBack || note.tieFor) {
                                                      console.log("note.tied = "  + note.tied); 
                                                      console.log("note.tieBack = " + note.tieBack);
                                                      console.log("note.tieFor = " + note.tieFor);                                                
                                                }
                                          }
                                    }
                              }

//=============================================================================
//                                  RESTS
//=============================================================================
                              else if (voice==0) /*if (cursor.element.type == Element.CHORDREST)*/
                              {
                                    console.log("Rest");
                                    var restLength = cursor.element.duration.ticks;
                                    var text = newElement(Element.STAFF_TEXT);
                                    text.pos.x = 0;
                                    /*if (cursor.element.duration.ticks<241)
                                    {   // adjust 8ths and 16ths to the left
                                          text.pos.x =  -0.2;
                                    }*/
                                    text.pos.y = yOff + 0.0; // this is the position above the line for the jianpu note
                                    text.text="0"; // rest
                                    cursor.add(text);
                                    if (cursor.element.duration.ticks==960)
                                    {
                                          var text2 = newElement(Element.STAFF_TEXT);
                                          text2.pos.x = 1+1.35;
                                          text2.pos.y =  yOff + 0.1; // this is the position above the line for the jianpu note
                                          text2.text="<font size=\"7\"/>—"; // half</font>
                                          cursor.add(text2);
                                    }
                                    else if (cursor.element.duration.ticks==1440)
                                    {
                                          var text2 = newElement(Element.STAFF_TEXT);
                                          text2.pos.x = 1+1.35;
                                          text2.pos.y =  yOff + 0.1; // this is the position above the line for the jianpu note
                                          text2.text="<font size=\"7\"/>—   —"; // dotted half</font>
                                          cursor.add(text2);
                                    }
                                    else if (cursor.element.duration.ticks==1920)
                                    {
                                          var text2 = newElement(Element.STAFF_TEXT);
                                          text2.pos.x = 1+1.35;
                                          text2.pos.y =  yOff + 0.1; // this is the position above the line for the jianpu note
                                          text2.text="<font size=\"7\"/>—   —   —"; // whole</font>
                                          cursor.add(text2);
                                    }
                                    else if (cursor.element.duration.ticks==240 || cursor.element.duration.ticks==360) //eighth
                                    {
                                          var text1 = newElement(Element.STAFF_TEXT); // we have to do an underline. 
                                          text1.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                          text1.pos.y = yOffUnderline; // this is the position above the line for the jianpu underline
                                          text1.text="<u>​   </u>"; // no-width space "​" plus 3 spaces 
                                          cursor.add(text1);
                                          //text.text="<u> 0 </u>"; // eighth
                                          //text.pos.x = -0.5
                                    }
                                    else if (cursor.element.duration.ticks==120 || cursor.element.duration.ticks==180)
                                    {
                                          var text1 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                          text1.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                          text1.pos.y = yOffUnderline; // this is the position above the line for the jianpu underline (top)
                                          text1.text="<u>​   </u>"; // no-width space "​" plus 3 spaces 
                                          cursor.add(text1);
                                          //text.text="<u> 0 </u>"; // sixteenth
                                          //text.pos.x = -0.5;
                                          //text.pos.y = yOffUnderline
                                          var text2 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                          text2.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                          text2.pos.y = yOffUnderline + underlineSpacing; // this is the position above the line for the jianpu underline (lowest)
                                          text2.text="<u>​   </u>"; //that lovely no-width space
                                          cursor.add(text2);
                                    }
                                    else if (cursor.element.duration.ticks==60 || cursor.element.duration.ticks==90)
                                    {
                                          var text1 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline. 
                                          text1.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                          text1.pos.y = yOffUnderline; // this is the position above the line for the jianpu underline (top)
                                          text1.text="<u>​   </u>"; // no-width space "​" plus 3 spaces 
                                          cursor.add(text1);
                                          var text2 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline. 
                                          text2.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                          text2.pos.y = yOffUnderline + underlineSpacing; // this is the position above the line for the jianpu underline (lowest)
                                          text2.text="<u>​   </u>"; //that lovely no-width space
                                          cursor.add(text2);
                                          var text3 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline. 
                                          text3.pos.x = -0.3; //-2.5 * (graceChords.length - i);
                                          text3.pos.y = yOffUnderline + (underlineSpacing * 2); // this is the position above the line for the jianpu underline (lowest)
                                          text3.text="<u>​   </u>"; //that lovely no-width space
                                          cursor.add(text3);
                                    }
                              }
                              
                              cursor.next();		  
                        }
                  }
            }

//=============================================================================
//                               BARLINES
//=============================================================================
            var cursor2 = curScore.newCursor()
            var lastMeasureX = 0
            cursor2.rewind(1) // if no selection, beginning of score
            if (fullScore) {
                  cursor2.rewind(0)
            }
            var m = cursor2.measure
            while (m && (fullScore || cursor2.tick < endTick)) {
                  //console.log("m " + m)
                  //console.log("cursor2.tick " + cursor2.tick)
                  console.log("m.pos.x " + m.pos.x);
                  console.log("m.bbox.width " + m.bbox.width); 
                  console.log("m.firstSegment.pos.x " + m.firstSegment.pos.x); 
                  var barRightX = -m.firstSegment.pos.x + m.bbox.width - 0.5
                  var barLeftX = -m.firstSegment.pos.x - 0.5
                  if (m.pos.x != 0) { //not the first measure; ignore first measure
                        if (lastMeasureX == 0) { //previous measure was 0 i.e. this is second measure, draw LEFT and RIGHT, first LEFT
                              console.log("left barline")
                              var textBarLeft = newElement(Element.STAFF_TEXT);
                              textBarLeft.pos.x = barLeftX; //-m.firstSegment.pos.x + m.bbox.width - 0.5; //-2.5
                              textBarLeft.pos.y =  yOff - 0.8;
                              textBarLeft.text="<font size=\"20\"/>|"; 
                              cursor2.add(textBarLeft);
                        }
                        console.log("right barline")                      
                        var textBarRight = newElement(Element.STAFF_TEXT); //draw RIGHT barline
                        textBarRight.pos.x = barRightX; //-m.firstSegment.pos.x + m.bbox.width - 0.5; //-2.5
                        textBarRight.pos.y =  yOff - 0.8;
                        textBarRight.text="<font size=\"20\"/>|"; 
                        cursor2.add(textBarRight);
                  }
                  lastMeasureX = m.pos.x
                  cursor2.nextMeasure();
                  
                  m = cursor2.measure;
            }
      }

      function shapeNotes(note, curKey) { 
        
            console.log("shapeNotes")
            var tpcNames = "FCGDAEB"
            var name = tpcNames[(note.tpc + 1) % 7]

            var names = "CDEFGAB"
            var scale = scales[curKey+7];

            var degrees = [ 
                  NoteHead.HEAD_DO,
                  NoteHead.HEAD_RE,
                  NoteHead.HEAD_MI,
                  NoteHead.HEAD_FA,
                  NoteHead.HEAD_SOL,
                  NoteHead.HEAD_LA,
                  NoteHead.HEAD_TI
            ];
   
      note.headGroup = degrees[(names.indexOf(name) - names.indexOf(scale) +28)%7];           
      }

      function apply() {
            console.log("hello jianpu");
            curScore.startCmd();
            applyToNotesInSelection(shapeNotes); //
            curScore.endCmd();
      }

      onRun: {
            if (!curScore)
                  Qt.quit();

      }
}
