# Midi based Animation Iterator For DaVinci Resolve

A DaVinci Resolve fuse plugin to repeat an animation based on the midi notes in a midi file. You can use this to sync animations to music. It’s useful for something like the guitar hero effect, but can be used for other things as well. 

![meow](Images/Example2)
![meow](Images/Example1)

## Installation 

All you need to do is relocate the files into the appropriate folders. 

#### midiEdited.lua needs to be in your modules folder.
##### Resolve
macOS:    ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Support/Fusion/Modules/Lua <br />
Windows:  C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Modules\Lua <br />
Linux:    ~/.local/share/DaVinciResolve/Fusion/Modules/Lua/ <br />
##### Fusion
macOS:    ~/Library/Application Support/Blackmagic Design/Fusion/Modules/Lua <br />
Windows:  C:\ProgramData\Blackmagic Design\Fusion\Modules\Lua <br />
Linux:    ~/.fusion/BlackmagicDesign/Fusion/Modules/Lua <br />

#### RecursiveMidiRepeat.fuse needs to be in your fuses folder.
##### Resolve
macOS:    ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Support/Fusion/Fuses <br />
Windows:  C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Fuses <br />
Linux:    ~/.local/share/DaVinciResolve/Fusion/Fuses <br />
##### Fusion
macOS:    ~/Library/Application Support/Blackmagic Design/Fusion/Fuses <br />
Windows:  C:\ProgramData\Blackmagic Design\Fusion\Fuses <br />
Linux:    ~/.fusion/BlackmagicDesign/Fusion/Fuses <br />

After the files are in the appropriate place, restart fusion if you currently have it open. <br />
You'll be able to find it in your fusion menu under the Fuses tab. (right click > Add Tool > Fuses > midi_repeat)

## Usage

### Midi prep

I recommend that you have some midi editing tool, any DAW should work. Be aware that it's common for DAW's (like Ableton) to not export midi with the bpm information, in this case I would recommend uploading your midi file to beepbox (a free online tool), and re-exporting it with a corrected BPM. <br />
Also, be aware, if you have a BPM shift in your song, it will become really difficult to sync up the midi and audio. In this case, you should take the exported audio into a new project in your DAW and align the midi there. 

### Animation setup

After you create an animation, you connect the output of the last node that makes up the animation into the midi_repeat fuse, you will then need to specify some values. These values are the length of your animation, where in the animation you want the midi note to play at, and the path to the midi file.

Some things to keep in mind about the animation. <br />
You need to make sure that the animation is doing something for the length of the entire fusion object, otherwise it will stop rendering. This is some quirk with fusion. <br />
You cannot change the animation halfway through your timeline, since it always goes back to the specified frames, changing something on frame 800 on a 200 frame animation wont do anything. If you want to do this, you can set up 2 animations and fade between them. 

You also have the option of a few blend modes, they are similar to what you would find in photoshop for the most part. 

### Timeline settings

The next set of setting can be autofilled for conveinience, but exist to let you tamper if the need arrises.

### Add and remove times

You have the ability to add and remove midi notes from the list without having to go and change your actual midi file. This enables you to make small changes fast. <br />
To do this you need to put what is essentually a lua table in the provided text box(s). For example {0,1,2} in the Add Midi text box will add 0, 1, and 3 to the list so an animation will play at frame 0, 1, and 2.

I've provided a print of all the current table values in the consol so you can easily figure out what times there are to remove. To view them go to "Workspace > Console" at the top.

### Advanced

These are mainly situational controls.

Disable Rounding <br />
Midi notes in context with BPM don't always match exactly with the fps of your timeline, so you'll end up having situations where a note will play halfway between 2 frames. This can be problematic in timelines with low fps (below 144 fps), and to resolve this, you can have fusion calculate what a frame would be during that half frame. <br />
This will tank performance, so I reccomend turning it on only before rendering.

Manually Cache Frames <br />
You might have issues with fusion automatically unloading some of the frames needed for this node, causing minor slowdown. This will resolve that.

## Credits

The midiEdited.lua file is an edited version of midi.lua by Possseidon: https://github.com/Possseidon/lua-midi
