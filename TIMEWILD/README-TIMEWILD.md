# TIMEWILD — Lost in the Cretaceous

Open `project.godot` in Godot 4.7 and press F6 on `Scenes/timewild.tscn`, or F5 to run the game.

You are a stranded time traveller. Recover six cyan chronoshards in each sector to activate the temporal rift. Escape three sectors to return home. The third sector introduces a T-Rex.

- WASD: move relative to the camera
- Mouse: look around
- Space: jump; press again while moving in midair to flip and double jump
- Escape: pause / resume
- R: restart the current sector; after victory, replay from sector one
- Click the game to capture the mouse

Red rings identify dangerous dinosaurs. Observe their patrols, pass behind them or jump clear. Orange spike patches alternate between raised and retracted states. The river must be crossed on the stepping stones. A cyan anchor beyond the river saves your respawn point; collected shards remain after taking damage. Three hits restart the sector through the retry screen.

Resources are copied from the supplied Background Art and Dinosaur folders. Originals remain untouched. Only seven nature models and four dinosaur models are included; repeated objects share imported meshes and textures. No new external asset downloads or texture packs are required. The previous demo remains available as `Scenes/demo_scene.tscn`.

Validation:
- `Tests/verify_astronaut.gd`: rig paths, all animation states, flip/reset.
- `Tests/verify_timewild.gd`: locked gate, checkpoint, damage cooldown, retry, all 18 pickups, stage progression, victory/replay, and physics-based river crossing.
- `Tests/capture_timewild.gd`: rendered gameplay preview in `Tests/timewild-preview.png`.
