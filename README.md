# Midi based Animation Iterator For DaVinci Resolve

A DaVinci Resolve fuse plugin to repeat an animation based on the midi notes in a .mid file. You can use this to sync animations to music. It’s useful for something like the guitar hero effect, but can be used for other things as well. 

![meow](Images/Example2)
![meow](Images/Example1)

## Installation 

All you need to do is relocate the files into the appropriate folders. 

#### midiEdited.lua needs to be in your modules folder.
##### DaVinci Resolve
macOS:    ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Support/Fusion/Modules/Lua <br />
Windows:  C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Modules\Lua <br />
Linux:    ~/.local/share/DaVinciResolve/Fusion/Modules/Lua/ <br />
##### Fusion (Standalone)
macOS:    ~/Library/Application Support/Blackmagic Design/Fusion/Modules/Lua <br />
Windows:  C:\ProgramData\Blackmagic Design\Fusion\Modules\Lua <br />
Linux:    ~/.fusion/BlackmagicDesign/Fusion/Modules/Lua <br />

#### RecursiveMidiRepeat.fuse needs to be in your fuses folder.
##### DaVinci Resolve
macOS:    ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Support/Fusion/Fuses <br />
Windows:  C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Fuses <br />
Linux:    ~/.local/share/DaVinciResolve/Fusion/Fuses <br />
##### Fusion (Standalone)
macOS:    ~/Library/Application Support/Blackmagic Design/Fusion/Fuses <br />
Windows:  C:\ProgramData\Blackmagic Design\Fusion\Fuses <br />
Linux:    ~/.fusion/BlackmagicDesign/Fusion/Fuses <br />

After the files are in the appropriate place, restart DaVinci Resolve. <br />
You'll be able to find it in the fusion menu under the Fuses tab. Look for "Midi_Repeat" (right click > Add Tool > Fuses > Midi_Repeat)

## Usage

### Midi prep

I recommend that you have some midi editing tool, any DAW should work. Be aware that it's common for DAW's (like Ableton and bitwig) to export midi without the bpm information, in this case I would recommend uploading your midi file to beepbox.co (a free online tool), and re-exporting it with a corrected BPM. You may want to use another DAW if you have tempo changes in your midi file. 

#### Reccomended DAWs (List will expand as I learn more) <br />
##### Exports Midi with tempo changes: <br />
Cakewalk <br />
Reaper <br />
##### Exports Midi with tempo: <br />
Beepbox

### Animation setup

Connect the output of the node that makes up your animation into the midi_repeat node, once you have done that, you will now need to specify some values. These values are the beginning and end frames of your animation, an offset which controls where you want the midi note to play at, and the path to the midi file.

It is reccomended to make your input animation start on the same frame as the first note or it will not show up. 

### Timeline settings

These settings can be autofilled for conveinience, but exist to let you tamper if the need arrises.

### Add and remove times

You have the ability to add and remove midi notes from the list without having to go and change your actual midi file. This enables you to make small changes fast. <br />
To do this, you need to put a lua table in the provided text box(s). For example {0,1,2} in the Add Midi text box will add a midi note at frame 0, 1, and 3.

I've provided a list of midi note times in the consol (go to "Workspace > Console" at the top) to help with removing notes.

### Advanced

Disable Rounding <br />
Midi notes in context with BPM don't always match exactly with the fps of your timeline, so you'll end up having situations where a note will play halfway between 2 frames. This can be problematic in timelines with low fps (below 144 fps), and to resolve this, you can have fusion calculate what a frame would be during that half frame. However, this will tank performance, so I reccomend turning it on only before rendering.

Manually Cache Frames <br />
This caches the frames of your animation, that way you wont need to recalculate any frames. This is incompatable with other settings. 

Flip Tail <br />
If you have overlapping content in your frames, it will let you control how they overlap before the offset (Frame of Beat) independantly.

Use Loops <br />
If you want to make a value change outside of the specified animation, you can set the animation to loop in the spline editor and then check this to open up those controls for use. <br />
This locks "Manually Cache Frames" because one will effectively negate the other. 

Alternatively you can achieve this effect by setting up 2 animations and fade between them with a dissolve node.

## Credits

The midiEdited.lua file is an edited version of midi.lua by Possseidon: https://github.com/Possseidon/lua-midi
