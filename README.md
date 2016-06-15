# cuts
cuts (for ensemble)

### MATERIALS
1. A field recording with a lot of high transients
2. 1 Korg NanoKontrol

### General Description
A dry version of a sample is played against a wet, "blurred" version with minimal delay (and a substantial amount of lag on control changes). The dry version of the sample "cuts" out the wet version, replacing it with a noise sound, when a transient exceeds the threshold (set individually by each player). Players are to establish an exact balance between the wet and dry sounds and the noise cut. Parameter changes on the noise sound (`chaosParam`, `cwipe`, `dur`) are at each player's discretion while keeping in mind that balance across the entire ensemble is the goal.

Most parameter changes are lagged such that control changes take a huge amount of time. The time it takes for the parameter to finish changing is its "glide time." Glide time is *only* changed by other players and offsets or disrupts any balance achieved while playing. Glide time reset may happen freely at each player's discretion.

### Sound Design
* Noise Synth - Choose any SC Noise UGen that undergoes an interesting, and varied, transformation `PV_BinScramble` as the input of your `\scramble` synth.

### Control Layout

`\delay_blur`
* amp -> CC 1
* delaytime -> CC 11

`\scramble`
* amp -> CC 2
* chaosParam -> CC 12
* cwipe -> CC 13
* dur -> CC 14
* thresh (note: controls `\scramble` but does onset detection on dry synth) -> CC 15
