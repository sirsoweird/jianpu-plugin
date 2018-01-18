//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2015 Nicolas Froment
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import MuseScore 1.0

MuseScore {
      version:  "1.0"
      description: "Change notehead according to pitch. Sacred harp, shape notes, Aikin."
      menuPath: "Plugins.Notes.Shapes Notes"
      pluginType: "dialog"

      id: window
      width: 220
      height: 130
      ExclusiveGroup { id: exclusiveGroup }
      ColumnLayout {
        id: column
        anchors.margins : 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        CheckBox {
          id: shape7CheckBox
          text: "7 shape notes (w/jianpu)"
          checked: true
          exclusiveGroup: exclusiveGroup
        }
        CheckBox {
          id: shape4CheckBox
          text: "4 shape notes"
          exclusiveGroup: exclusiveGroup
        }
        CheckBox {
          id: normalCheckBox
          text: "Normal notes"
          exclusiveGroup: exclusiveGroup
        }
      }
      RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: column.bottom
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


      //                              -7   -6   -5   -4   -3   -2   -1    0    1    2    3    4    5    6    7
      property variant scales :      ['C', 'G', 'D', 'A', 'E', 'B', 'F', 'C', 'G', 'D', 'A', 'E', 'B', 'F', 'C'];
      property variant scaleTwelve : [ 0 ,  6 ,  1 ,  8 ,  3 , 10 ,  5 ,  0 ,  7 ,  2 ,  9 ,  4 , 11 ,  6 ,  0 ];
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
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff and end with last
                  endStaff = 0; // curScore.nstaves - 1; change to 0 to only work on first staff rji
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
                        var eighthTie =  0;
                        var lastBeam = 0;
                        var lastBeamX = 0;
                        var lastBeamTicks = 0;
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
                                          func(note, cursor.keySignature);

					  if (voice==0) 
					  {
					        // do jianpu
//=============================================================================
//            POSITIONING VARIABLES -- NEED TO MOVE TO OPENING DIALOG
//=============================================================================
						var yOff = -1; // .pos.y OFFSET. This should be set in a dialog, upon running the plugin
                                                var underlineSpacing = 0.5; // This should also be set in opening dialog.  Spacing between stacked underlines. Positive
                                                
//=============================================================================
//                             DETERMINE JIANPU NUMBER
//=============================================================================
                                                var tpcNames = "FCGDAEB";
                                                var name = tpcNames[(note.tpc + 1) % 7]; // name is the ABC for the NOTE we are on
                                                //console.log("cursor.keySignature " + cursor.keySignature)
                                                //console.log("note.pitch " + note.pitch);
                                                //console.log("scaleTwelve[cursor.keySignature+7] =" + scaleTwelve[cursor.keySignature+7]);
                                                var names = "CDEFGAB";
                                                var octave = Math.floor(((note.pitch - scaleTwelve[cursor.keySignature+7]) - 60) / 12 ) // 60 is our magic number at MIDDLE C
                                                      // the first DO at or above MIDDLE C will be the 'no dot DO'
                                                      // octave is 0 when no dots, positive: number of dots above, negative: number of dots below.
						var scale = scales[cursor.keySignature+7]; //scale is the ABC of our current key signature
						var jpText = ""+((names.indexOf(name) - names.indexOf(scale) +28)%7+1);// this is the JIANPU NUMBER for further use below
                                                
//=============================================================================
//                              MAIN JIANPU DRAWING
//=============================================================================
                                                var text = newElement(Element.STAFF_TEXT);
                                                text.pos.x = 0; /*-2.5 * (graceChords.length - i); //shift to the right for each 
                                                      subsequent note in the chord, this should be nonfunctional if we're 
                                                      only doing the top note per chord.  */
						text.pos.y = yOff + 0.0; // this is the position above the line for the jianpu note
						text.text = jpText;
                                                //console.log("note.tied = "  + note.tied); 
                                                //console.log("note.tieBack = " + note.tieBack);
                                                //console.log("note.tieFor = " + note.tieFor);                                                
						console.log("jpText = " + jpText + ", octave = " + octave + ", ticks =" + cursor.element.duration.ticks)
                                                //(cursor.element.duration.ticks) = note_length (1920=whole; 960=half; 480=quarter; 240=eighth; 120=sixtenth;)
						if (cursor.element.duration.ticks==1920) // WHOLE
						{
						      var text2 = newElement(Element.STAFF_TEXT);
                                                      text2.pos.x = 3.95; //(-2.5 * (graceChords.length - (i-1)))+3.95;
						      text2.pos.y = yOff + 0.1; // this is the position above the line for the jianpu note
						      text2.text="<font size=\"7\"/>—   —   —"; //</font> whole. Font size 4 is too small.  Trying 7 2018-01-16
						      cursor.add(text2);
						      eighthTie = 0;
						}
						else if (cursor.element.duration.ticks==1440) // DOTTED HALF
						{
						      var text2 = newElement(Element.STAFF_TEXT);
                                                      text2.pos.x = 3.95; //(-2.5 * (graceChords.length - (i-1)))+3.95;
						      text2.pos.y =  yOff + 0.1; // this is the position above the line for the jianpu note
						      text2.text="<font size=\"7\"/>—   —"; //</font> dotted half
						      cursor.add(text2);
						      eighthTie = 0;
						}
                                                else if (cursor.element.duration.ticks==960) // HALF
						{
						      var text2 = newElement(Element.STAFF_TEXT);
                                                      text2.pos.x = 3.95; //(-2.5 * (graceChords.length - (i-1)))+3.95;
						      text2.pos.y = yOff + 0.1; // this is the position above the line for the jianpu note
						      text2.text="<font size=\"7\"/>—"; //</font> half
						      cursor.add(text2);
						      eighthTie = 0;
						}
						else if (cursor.element.duration.ticks==240 || cursor.element.duration.ticks==360) // EIGHTH or DOTTED EIGHTH
						{
						      text.text="<u> "+jpText+" </u>"; // eighth
						      text.pos.x = -0.5 
                                                      text.pos.y = yOff
                                                }
						else if (cursor.element.duration.ticks==120 || cursor.element.duration.ticks==180) // SIXTEENTH or DOTTED SIXTEENTH
						{      
						      text.text="<u> "+jpText+" </u>"; // sixteenth
						      text.pos.x = -0.5 // * (graceChords.length - i);
						      var text2 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                                      text2.pos.x = -0.5; //-2.5 * (graceChords.length - i);
						      text2.pos.y = yOff + underlineSpacing; // this is the position above the line for the jianpu underline (lower)
      						      text2.text="<u>    </u>"; // four spaces
						      cursor.add(text2);
						}
                                                else if (cursor.element.duration.ticks==60 || cursor.element.duration.ticks==90) // THIRTYSECONDTH or DOTTED THIRTYSECONDTH
						{      
						      text.text="<u> "+jpText+" </u>"; 
						      text.pos.x = -0.5 ;
						      var text2 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline. 
                                                      text2.pos.x = -0.5;
						      text2.pos.y = yOff + underlineSpacing; // this is the position above the line for the jianpu underline (middle)
      						      text2.text="<u>    </u>"; // four spaces wide
						      cursor.add(text2);
						      var text3 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-underline.
                                                      text3.pos.x = -0.5;
						      text3.pos.y = yOff + (underlineSpacing * 2); // this is the position above the line for the jianpu underline (lowest)
						      text3.text="<u>    </u>"; // four spaces wide
						      cursor.add(text3);
						      eighthTie = 0;
						}
//=============================================================================
//                                DOTTED NOTES
//=============================================================================
                                                // alternatively, there is a property somewhere called note.dotCount which could be helpful
						if (cursor.element.duration.ticks==720) // dotted QUARTER, since it has no underline, needs an extra space to line up with the eighths and shorter
                                                { // DOTTED QUARTER, add dot only
                                                      text.text+=" <font size=\"7\"/>•"; //</font> dotted quarter in a smaller font
                                                      // 2018-01-18 0939 removing "</font>" from end of text, seems to break when saved.
	       					}
                                                if (cursor.element.duration.ticks==360 || cursor.element.duration.ticks==180) // could also add dotted 32ndths, however that's beyond the scope of this project
                                                { // DOTTED EIGHTH or SIXTEENTH, add dot only
                                                      text.text+="<font size=\"7\"/>•"; // </font>dotted eighth OR sixteenth, in a smaller font
	       					}

						cursor.add(text);

//=============================================================================
//                           BEAMS (JIANPU UNDERLINE)
//=============================================================================
// this doesn't beam rests; rest to rest beaming shouldn't exist, but eighth note to eighth rest should be able to beam somehow...
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
                                                            var jpbeamLength = (beamLength * 2).toFixed(0);
						            // this seems messy 
                                                            var oneSpace = "                                              ";
                                                            var moreSpaces = oneSpace.substring(1, jpbeamLength); 
                                                            // if only we could use .repeat() in this code...
                                                            //console.log("moreSpaces :" + moreSpaces + ": jpbeamLength = " + jpbeamLength);
                                                            
                                                            var textBeam = newElement(Element.STAFF_TEXT);
                                                            textBeam.pos.x = -beamLength ; // start drawing to the left of the current note by the length of the beam
						            textBeam.pos.y = yOff + 0.0; // this is the position above the line
                                                            textBeam.text="<u>" + moreSpaces + "</u>"; 
						            cursor.add(textBeam);
						            if (Math.max(lastBeamTicks, cursor.element.duration.ticks) < 240) { //both ends of beam are shorter than eighth, i.e. at least SIXTEENTH, so at least a double-beam
                                                                  var textBeam2 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-beam. 
                                                                  textBeam2.pos.x = -beamLength; 
                                                                  textBeam2.pos.y = yOff + underlineSpacing; // this is the position above the line for the jianpu underline (lower)
                                                                  textBeam2.text="<u>" + moreSpaces + "</u>";
                                                                  cursor.add(textBeam2);
						            }
                                                            if (Math.max(lastBeamTicks, cursor.element.duration.ticks) < 120) { //both ends of beam are shorter than sixteenth, i.e. at least THIRTYSECOND, so at least a triple-beam
                                                                  var textBeam3 = newElement(Element.STAFF_TEXT); // we have to do a TRIPLE-beam. 
                                                                  textBeam3.pos.x = -beamLength; 
                                                                  textBeam3.pos.y = yOff + (underlineSpacing * 2); // this is the position above the line for the jianpu underline (lowest)
                                                                  textBeam3.text="<u>" + moreSpaces + "</u>";
                                                                  cursor.add(textBeam3);
						            }
                                                            
                                                            lastBeamX = cursor.element.pagePos.x; // on beams of over 2 notes, draw each
                                                            // segment individually; this way sixteenths and 32nds can be handled also
                                                            // Therefore we update the drawback X position each time we draw
                                                            lastBeamTicks = cursor.element.duration.ticks; //same with ticks, so we can compare lengths next time, determine number of underlines 
                                                      }
                                                      else { 
                                                      // this means we are starting a new beam. Probably have to draw it later, just get info first.
                                                            console.log("beam on current note, left end of beam. Storing information for later")
                                                            lastBeam = cursor.element.beam
                                                            lastBeamX = cursor.element.pagePos.x
                                                            lastBeamTicks = cursor.element.duration.ticks
                                                      }
                                                }

//=============================================================================
//                                  SHARPS and FLATS
//=============================================================================
                                                var noteKey = (note.pitch - scaleTwelve[cursor.keySignature+7]) % 12;
                                                var isSharp = false
                                                var isFlat = false
                                                
                                                // really wish there was a better way to treat the following 
                                                if (noteKey == 1) {
                                                      if (jpText == 1) { 
                                                            isSharp = true
                                                      };
                                                      if (jpText == 2) { 
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 3) {
                                                      if (jpText == 2) { 
                                                            isSharp = true
                                                      };
                                                      if (jpText == 3) {       
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 6) {
                                                      if (jpText == 4) { 
                                                            isSharp = true
                                                      };
                                                      if (jpText == 5) {       
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 8) {
                                                      if (jpText == 5) { 
                                                            isSharp = true
                                                      };
                                                      if (jpText == 6) {       
                                                            isFlat = true
                                                      };
                                                }
                                                else if (noteKey == 10) {
                                                      if (jpText == 6) { 
                                                            isSharp = true
                                                      };
                                                      if (jpText == 7) {       
                                                            isFlat = true
                                                      };
                                                }
                                                
                                                //console.log("isSharp = " + isSharp + "  isFlat = " + isFlat);
                                                if (isFlat) {              //  b  Flat
                                                      var textF = newElement(Element.STAFF_TEXT); 
                                                      textF.pos.x = -0.8;
						      textF.pos.y = yOff - 0.8; 
      						      textF.text="♭"; 
						      cursor.add(textF);
						} 
                                                else if (isSharp) {     //  #  Sharp
                                                      var textS = newElement(Element.STAFF_TEXT);  
                                                      textS.pos.x = -0.8;
						      textS.pos.y = yOff - 0.8; 
      						      textS.text="♯"; 
						      cursor.add(textS);
                                                }
                                                
                                                
//=============================================================================
//                         UPPER and LOWER OCTAVE DOTS
//=============================================================================
                                                // check if needs DOWN octave dot
						if (octave<0) { // could add ability for double dots below, however outside our current needs
						      var text = newElement(Element.STAFF_TEXT);
                                                      text.pos.x = 0.2; //(-2.5 * (graceChords.length - i))+.02; //DOT needs a slight right
				              	      text.pos.y =  yOff + 1.25; // this is the position above the line for the jianpu UNDER DOT
						      if (cursor.element.duration.ticks==240 || cursor.element.duration.ticks==360)
						      {
					                    text.pos.y =  yOff + 1.6; // the underdot for 8ths is lower, settled at 1.6
						      }
						      else if (cursor.element.duration.ticks==120 || cursor.element.duration.ticks==180)
						      {
					                    text.pos.y =  yOff + underlineSpacing + 1.6 // the underdot for 16ths is lower
						      }
						      else if (cursor.element.duration.ticks==60 || cursor.element.duration.ticks==90)
						      {
					                    text.pos.y =  yOff + (underlineSpacing * 2) + 1.6; // the underdot for 32ndths is lower yet
						      }
                                                      text.text = "<font size=\"7\"/>•";
						      cursor.add(text);
                                                }
                                                // check if needs UP octave dot
						if (octave>0) { // likewise could add ability for double dots above, however also outside our current needs
						      var text = newElement(Element.STAFF_TEXT);
                                                      text.pos.x = 0.15; // DOT needs a slight right
				              	      text.pos.y =  yOff + -1.3; // this is the position above the line for the jianpu OVER DOT
						      text.text = "<font size=\"7\"/>•";//</font>
                                                      cursor.add(text);
						}
                                                console.log(cursor.element.BarLine)
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
                                    text.pos.x = 1;
			            if (cursor.element.duration.ticks<241)
				    {   // adjust 8ths and 16ths to the left
				          text.pos.x =  -0.2;
				    }
				    text.pos.y =  yOff + 0.0; // this is the position above the line for the jianpu note
				    text.text="0"; // rest
				    cursor.add(text);
				    eighthTie = 0;
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
				    else if (cursor.element.duration.ticks==240 || cursor.element.duration.ticks==360)
				    {
					  text.text="<u> 0 </u>"; // eighth
                                          text.pos.x = -0.5
				    }
				    else if (cursor.element.duration.ticks==120 || cursor.element.duration.ticks==180)
                                    {
                                          text.text="<u> 0 </u>"; // sixteenth
		                          text.pos.x = -0.5;
                                          text.pos.y = yOff
				          var text2 = newElement(Element.STAFF_TEXT); // we have to do a DOUBLE-underline. 
                                          text2.pos.x = -0.5; //-2.5 * (graceChords.length - i);
				          text2.pos.y = yOff + underlineSpacing; // this is the position above the line for the jianpu underline (lowest)
      					  text2.text="<u>    </u>";
					  cursor.add(text2);
                                          eighthTie = 0;
				    }
			      }
                              if (cursor.element.type == Element.BAR_LINE) {
                                   console.log("BARLINE")
                              }
                              if (!!cursor.element.barline) {
                                   console.log("BARLINE TOO")
                              }

                              cursor.next();		  
                        }
                  }
            }

//=============================================================================
//                         testing for barline entry
//=============================================================================
            var cursor2 = curScore.newCursor()
            cursor2.rewind(0) // if no selection, beginning of score
            var m = cursor2.measure
            while (m ) { //&& (fullScore || cursor2.tick < endTick)
                  console.log(m)
                  console.log(cursor2.tick)
                  console.log("m.pos.x " + m.pos.x) // success, but how to use...
                  console.log("cursor2.measure.parent.type " + cursor2.element.parent.type)
                  var textBar = newElement(Element.STAFF_TEXT);
                  textBar.pos.x = -2.5;
                  textBar.pos.y =  yOff - 0.8;
                  textBar.text="<font size=\"20\"/>|"; // </font>
                  cursor2.add(textBar);
                  cursor2.nextMeasure();
                  m = cursor2.measure;
            }
      }

      function shapeNotes(note, curKey) {/* eliminated this 2017-12-20, since we are working with shapes separately.  Wouldn't hurt
        //                                to have this enabled in production, though
        console.log("shapeNotes")
          var tpcNames = "FCGDAEB"
          var name = tpcNames[(note.tpc + 1) % 7]

          var names = "CDEFGAB"
          var scale = scales[curKey+7];
          
          var degrees = [
              NoteHead.HEAD_NORMAL,
              NoteHead.HEAD_NORMAL,
              NoteHead.HEAD_NORMAL,
              NoteHead.HEAD_NORMAL,
              NoteHead.HEAD_NORMAL,
              NoteHead.HEAD_NORMAL,
              NoteHead.HEAD_NORMAL
            ]; 
          if (shape4CheckBox.checked)
            degrees = [ // 4 notes
                NoteHead.HEAD_FA,
                NoteHead.HEAD_SOL,
                NoteHead.HEAD_LA,
                NoteHead.HEAD_FA,
                NoteHead.HEAD_SOL,
                NoteHead.HEAD_LA,
                NoteHead.HEAD_MI
              ];
          else if (shape7CheckBox.checked)
            degrees = [ // 7 notes
                NoteHead.HEAD_DO,
                NoteHead.HEAD_RE,
                NoteHead.HEAD_MI,
                NoteHead.HEAD_FA,
                NoteHead.HEAD_SOL,
                NoteHead.HEAD_LA,
                NoteHead.HEAD_TI
              ];
   
          note.headGroup = degrees[(names.indexOf(name) - names.indexOf(scale) +28)%7]; */          
      }

      function apply() {
        console.log("hello shapeNotes");
        curScore.startCmd();
        applyToNotesInSelection(shapeNotes);
        curScore.endCmd();
      }

      onRun: {
            apply();
            Qt.quit();
            if (!curScore)
                  Qt.quit();

      }
}
