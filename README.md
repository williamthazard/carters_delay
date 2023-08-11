# Carter's Delay

This is a little multi-tap delay I made for my cousin Carter to use. Carter is 6 years old at time of writing, so the instrument had to be pretty simple. You just set your input and output devices on lines 8 and 9 (by default, the script will print a list of available devices to the SCIDE REPL when you run it, which you can then choose from to be sure that the wording of the string is exactly correct, like "Scarlett 4i4 USB" rather than "Scarlett 4i4"). I would not recommend using both a laptop's built-in speakers and built-in mic, as this can cause feedback. Using an external mic with a laptop's built-in speakers should be just fine as long as you keep an eye on your input level, though. Then place your cursor behind the opening parenthesis on line 1 and hit cmd+period (or ctrl+period on Windows) to execute. This will launch a fullscreen xy oscilloscope that will show you your input and the delay's output. From there, just make sounds into the input and enjoy!
<br>
<br>
I wrote this in a single night, over the course of just a couple hours, while visiting my cousin and his side of the family in Greeley, Colorado. This immediate, improvisatory quality is something I love about SuperCollider, but it means this script is far from perfect. I did my best in the time I had to smooth out any wrinkles I saw, but you'll still hear crackles occasionally when the buffer crosses the discontinuity created by continuously recording over a buffer of fixed length and then playing back at variable speeds. To be honest, I find this kind of charming. It reminds me of cassette tapes. People make whole plugins to get sounds like that into their mixes. But if you don't like that and want to submit a PR, it would certainly be welcome.
