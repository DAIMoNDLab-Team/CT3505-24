# netedit and sumo-gui in Docker (workaround for macOS Tahoe)

## Why this exists
On macOS 26 (Tahoe), `netedit` (and `sumo-gui`) open under XQuartz but never draw the network: the canvas stays empty on first render and on resize. This was reproduced on macOS 26.5.2 with XQuartz (X.Org 21.1.23) and SUMO 1.27.1.

`netedit` draws with OpenGL. On Tahoe, XQuartz fails to create the OpenGL surface, so every GLX context fails:

```
X Error: code 2 major 129 minor 2: BadValue          (Apple-DRI)
xp_destroy_surface: assertion failed: s != NULL
X Error: code 161 major 149 minor 5: GLXBadContext
```

`glxinfo` fails the same way, so this is not specific to SUMO. `LIBGL_ALWAYS_SOFTWARE=1` and `LIBGL_ALWAYS_INDIRECT=1` do not help, because the failure is in the XQuartz server itself. MacPorts' `xorg-server` uses the same code path, so it is unlikely to fix this. See [MacPorts ticket #73594](https://trac.macports.org/ticket/73594) and XQuartz issues #438 and #446.

This directory is a stopgap: it runs netedit inside a Linux container with its own virtual display and software OpenGL (Mesa), which you view in your browser. Once XQuartz or macOS fixes the bug, use the normal installed netedit and ignore this.

## When you need it
Only if you are on macOS Tahoe **and** need netedit (e.g. to edit the networks in `Network/`). Everything else (running simulations, `sumo`, the notebooks) is unaffected. Windows and older macOS do not need this.

## Requirements
Docker Desktop (or any Docker engine) running. Works on Apple Silicon and Intel.

## Usage
Run these from the repository root.

1. Build the image once (a few minutes; it installs SUMO 1.27.1 from the `eclipse-sumo` PyPI wheel):

   ```sh
   docker build -t netedit-novnc tools/netedit-docker
   ```

2. Start netedit on a network:

   ```sh
   docker run -d --name netedit -p 127.0.0.1:6080:6080 -v "$PWD/Network:/work" netedit-novnc /start.sh -s circle.net.xml
   ```

   Replace `circle.net.xml` with any file in `Network/`, or drop `-s ...` and use File -> Open Network.

3. Open <http://localhost:6080/vnc.html> and click **Connect** (no password). Maximize the netedit window if it looks small.

4. Edit as usual. `Network/` is mounted at `/work` in the container, so File -> Save writes straight into the repo. Save inside `/work`; anything saved elsewhere in the container is lost when it is removed.

5. When done:

   ```sh
   docker rm -f netedit
   ```

### Running sumo-gui instead
The same image can run `sumo-gui`: set `APP=sumo-gui` and pass a `.sumocfg` file from `Network/`.

```sh
docker run -d --name sumo-gui -p 127.0.0.1:6080:6080 -e APP=sumo-gui -v "$PWD/Network:/work" netedit-novnc /start.sh -c rm_circle_a1.sumocfg
```

Open <http://localhost:6080/vnc.html>, click **Connect**, and press Play in sumo-gui. Stop it with `docker rm -f sumo-gui`.

- netedit and sumo-gui both use port 6080, so run one at a time, or map a different host port for the second one (e.g. `-p 127.0.0.1:6081:6080`, then open port 6081).
- This is a standalone viewer. The notebooks' "Show simulation" toggle still starts the sumo-gui installed on your Mac, which does not draw on Tahoe. To watch a scenario, run it here with the matching `.sumocfg`.
- The image is still called `netedit-novnc` for historical reasons; it contains both programs.

## Launch scripts
Instead of typing the `docker` commands, run one of these from anywhere:

```sh
tools/netedit-docker/run-netedit.sh [args]     # e.g. -s circle.net.xml
tools/netedit-docker/run-sumo-gui.sh [args]    # e.g. -c rm_circle_a1.sumocfg
```

They build the image if needed, ask before killing an existing container (of the same app, or one already using port 6080), and print the link to open once the viewer is ready. With no arguments the app starts without a file (use File -> Open, `Network/` is mounted at `/work`); pass arguments to open a file directly. Set `PORT=6081` to use another host port.

## Files
- `run-netedit.sh`, `run-sumo-gui.sh`: thin wrappers around `run-app.sh`, which does the work.
- `Dockerfile`: Ubuntu 24.04 + Xvfb (virtual display) + x11vnc/noVNC (browser access) + fluxbox (window manager) + SUMO 1.27.1.
- `start.sh`: starts the display, VNC, and web server, then runs the program named by the `APP` environment variable (default `netedit`, or `sumo-gui`) with whatever arguments you pass.

## Notes
- The SUMO version is pinned to match the one the installers set up. If you change the installed SUMO version, update the pin in the `Dockerfile` so netedit does not write files in a different format.
- The noVNC port is bound to `127.0.0.1` only (no password), so it is not reachable from other machines. Do not change that to `-p 6080:6080` on a shared network.
- Software rendering is slower than native, but is fine for editing networks of this size.
