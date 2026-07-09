# CT3505-24 - Assignments 1 & 2 codebase installation instructions

## Quickstart: automated installer
Instead of following the manual steps below, you can run a script that installs everything (Miniconda, SUMO, VS Code, and the required Python packages) with minimal interaction:

- **Windows 11:** double-click `install-windows.bat` (approve the administrator prompt if asked).
- **macOS:** double-click `install-macos.command` (right-click -> Open the first time, and enter your Mac password if asked to install Homebrew).

Both scripts are safe to re-run and skip anything already installed. Once finished, open VS Code, open this folder, and select the `ct3505` conda environment as your notebook kernel. If you'd rather install things yourself, or the script hits a snag, follow the manual steps below instead.

## Installation steps (MacOS, Linux)
Note: these installation steps will be largely based on Visual Studio Code as your main interface. Other IDEs can be used, but the creation / activation of appropriate conda environments will have to be handled manually.

- Download and install [Visual Studio Code](https://code.visualstudio.com/)
- Download and install [miniconda](https://www.anaconda.com/docs/getting-started/miniconda/main) (recommended) or your preferred version of anaconda, to allow creating project-based environments
- Download and install [SUMO](https://eclipse.dev/sumo/)
- Launch Visual Studio Code
- In Visual Studio Code, select File -> Open folder.. and navigate to the folder containing this file.
- Open (any) one of the project's Jupyter notebooks (e.g. 'Assignment 1.ipynb')
- Click on "Select kernel..." on the top right of the Jupyter notebook screen, select "Python Environments..." and "Create new python environment". Create a ".conda" environment. Each time you open VSCode and this project, it will remember this is the right environment and always use it.
- Open VSCode's terminal (menu bar -> Terminal) *after* creating and selecting your .conda enviroment.
- Activate your new enviromnent by typing the following in the terminal window: conda activate .conda/
- Install *lxml* by typing the following in the terminal window: ```pip install lxml```
- Install *tud-sumo* by typing the following in the terminal window: ```pip install tud-sumo```
- Install *mercury* by typing the following in the terminal window: ```pip install mercury```

## Installation steps (Windows)
1. Download and install [Anaconda desktop](https://www.anaconda.com/download)
2. Download and install [Visual Studio Code](https://code.visualstudio.com/)
3. Download and install [SUMO](https://eclipse.dev/sumo/)
4. Download the project [repository](https://github.com/DAIMoNDLab/CT3505-24/archive/refs/heads/main.zip), unzip it and place the folder in a recognizeable place (e.g. in your Documents folder)
5. Launch Anaconda navigator
6. Create a new anaconda environment, select python 3.12, give the environment a recognizeable name (e.g. ct3505)
7. Launch Visual Studio Code *from within Anaconda*
8. in VSCode, do File -> Open Folder... and select the folder where you unzipped the project repository
9. in VSCode, click on Assignment_1.ipynb
10. in VSCode, Open a new terminal (... -> Terminal -> New Terminal)
11. (only once!) In the terminal, type the following:
- pip install lxml
- pip install tud-sumo
- pip install mercury

## Launching steps (Windows)
1. Be sure to follow the install steps, first
2. Follow steps 7-10 from the install guide to launch VSCode and the appropriate terminal environment
3. Type 'mercury run' in the terminal window
You can now work on Assignment 1

## Additional settings for Assignment 2 (Windows only, *only once*!)
1. In VSCode, click on the Extensions tab, navigate to the Jupyter extension
2. Click on "Install specific version..." and select version 2025.7.0 from the list
3. Click on "Restart extensions"
4. Open Assignment_2.ipynb
5. Click on Select Kernel... and find the environment you created during installation
6. Click on "Run All"
You can now work on Assignment 2



## Running steps
### Assignment 1:
- [ ] In the terminal window, type "mercury run". If everything went smoothly during installation, your browser will open with a new window. Have fun!
### Assignment 2:
- [ ] Open the Jupyter notebook in Visual Studio Code and run it as-is, clicking the "Run all" button at the top of the page: ![vscode_gui](./vscode_gui.png)




