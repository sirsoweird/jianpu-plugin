# jianpu-plugin
QML plugin for MuseScore, adding JianPu notation above the top staff.  Jianpu (简谱) is a type of simplified notation, using 1 through 7 for DO through TI.  Notation therefore is only 'relative' pitch. 

This plugin is not intended to be a main functioning part of MuseScore.  That is currently waiting for https://github.com/musescore/MuseScore/pull/3614.  However, in the mean time, this is a simple plugin which can be used.  It is written for a specific project, therefore not all uses are taken into account.  


Some of the limitations built into initial implementation are:
*  Only one staff / one voice functionality
*  No support for triplets of any type (jianpu number will display, just no timing)
*  Default undotted octave is hardcoded in.  The lowest undotted DO is B below middle C; the highest undotted DO is A above middle C. However, there is an octave adjustment if the default octave is not appropriate for a specific piece.
*  Key signature not implemented
*  Time signature not implemented (Western style is very similar though)
*  Beaming between rests and notes is not implemented.  MuseScore does not beam these either, and this plugin only follows beams already in the Western notation.


PLEASE BE AWARE THAT
*  Commits prior to 2018-04-10 are for 2.1.3
*  Commits after 2018-04-10 are for 2.2.1

This is due to the font engine fix in 2.2
