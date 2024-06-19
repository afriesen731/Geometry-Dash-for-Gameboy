<h1>Geometry Dash for Gameboy</h1>
<p>This project recreates the popular mobile game Geometry Dash for the Game Boy. It is written in assembly language using the <a href="https://rgbds.gbdev.io/install">RGBDS compiler</a></p>
<h2>Play Game in Browser</h2>
<h4>No download required</h4>

<h2>Credits</h2>
<ul><li><strong>GB Studio Community Assets</strong>: For the music tracks used in the game. <a rel="noreferrer" target="_new" href="https://github.com/DeerTears/GB-Studio-Community-Assets">GB Studio Community Assets</a></li><li><strong>GBDev Input Tutorial</strong>: For the code to read the controller inputs. <a rel="noreferrer" target="_new" href="https://gbdev.io/gb-asm-tutorial/part2/input.html">GBDev Input Tutorial</a></li><li><strong>GBT Player</strong>: For the music player code. <a rel="noreferrer" target="_new" href="https://github.com/AntonioND/gbt-player">GBT Player</a></li></ul>






<script src="path/to/GameBoy-Online/gbemu-all.js"></script>
    <script>
        let emulator;

        function startEmulator(romBuffer) {
            emulator = new GameBoyCore(document.getElementById('emulatorCanvas'));
            emulator.openMBC(romBuffer);
            emulator.start();
        }

        document.getElementById('romUpload').addEventListener('change', function(event) {
            const file = event.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function() {
                    startEmulator(new Uint8Array(reader.result));
                };
                reader.readAsArrayBuffer(file);
            }
        });

        // Optionally, load a ROM directly
        fetch('game.gb')
            .then(response => response.arrayBuffer())
            .then(buffer => startEmulator(new Uint8Array(buffer)));
    </script>
