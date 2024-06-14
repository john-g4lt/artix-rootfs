# [Artix](https://artixlinux.org/) Linux rootfs & Windows WSL (WSL2) installation
**Features:**
- Works in 2024
- Weakly releases
- Fully automated via GitHub actions
- Windows WSL2 installation instructions

## Download
- Download the latest Artix base/server rootfs tarball (main purpose of this repo is maintaing of this tarball):
  <br>[`https://github.com/john-g4lt/artix-rootfs/releases/latest/download/artix_rootfs.tar.xz`](https://github.com/john-g4lt/artix-rootfs/releases/latest/download/artix_rootfs.tar.xz)

## Get from source (skip if downloaded above)
For more experienced users: you can use `get.sh` script to get official images yourself, if you assume this repo GitHub releases can be compromised
- Install [Ubuntu WSL](https://www.microsoft.com/store/productId/9PDXGNCFSCZV) and run it
- Download the script:
  ```bash
  wget https://raw.githubusercontent.com/john-g4lt/main/get.sh
  ```
- Run it:
  ```bash
  bash get.sh 1 1
  ```
  Where:
  - First argument sets xz compression level to 1 as you are not limited by GitHub size limit and don't want to waste time
  - Second argument sets threads count to 1, you can calculate it yourself using `lscpu`
<br><br>
And if you want to continue as WSL installation:
- Copy result tarball to Windows `Downloads` folder (change `WINDOWS_USERNAME` to your Windows user username):
  ```bash
  sudo cp artix_rootfs.tar.xz /mnt/c/Users/WINDOWS_USERNAME/Downloads/
  ```
- Follow WSL installation instructions

## WSL Installation
- Update your Windows (min 2 Apr 2023, required for importing from `.xz`)

- [Activate WSL](https://learn.microsoft.com/en-us/windows/wsl/install) if not have been activated yet
  
- Start a new Powershell session:
  <br>`<WIN + r>` `powershell` `<ENTER>`
  <br><br>![image 1](https://github.com/john-g4lt/artix-rootfs/assets/172701622/caca3084-fd1a-4feb-8e1b-a5226975940f)
  <br>Or just run Powershell from Windows Start Menu

- Create sources directory:
  ```bash
  mkdir /wsl_distros/sources
  ```
  ![image 2](https://github.com/john-g4lt/artix-rootfs/assets/172701622/b5baa742-864c-44e7-b61c-fc9dc3c66e04)

- Copy (or move) the `artix_rootfs.tar.xz` to the `/wsl_distros/sources/` directory:
  ```bash
  cp -v $HOME/Downloads/artix_rootfs.tar.xz /wsl_distros/sources/
  ```
  ![image 3](https://github.com/john-g4lt/artix-rootfs/assets/172701622/243f0848-80d1-4b91-99c6-f06073a854ff)

- Update WSL (min 2 Apr 2023, required for importing from `.xz`):
  ```bash
  wsl.exe --update
  ```

- Register Artix as a new WSL distro:
  ```bash
  wsl.exe --import Artix /wsl_distros/Artix /wsl_distros/sources/artix_rootfs.tar.xz --version 2
  ```
  ![image 4](https://github.com/john-g4lt/artix-rootfs/assets/172701622/bbeae98b-3b48-4c1d-ab60-b5f8f00558c1)

- Ensure the distro has been imported correctly:
  ```bash
  wsl.exe --list --verbose
  ```
  ![image 5](https://github.com/john-g4lt/artix-rootfs/assets/172701622/4777ac9b-6025-416b-b9fa-0421adce362c)

- Create on your desktop shortcut with path:
  ```bash
  %windir%\system32\cmd.exe /k cd %userprofile% && wsl.exe -d Artix --cd ~
  ```
  and name
  <br>`Artix`
  <br><br>Recomended:
    - Change icon in Properties to [`https://raw.githubusercontent.com/john-g4lt/artix-rootfs/main/artix_logo.ico`](https://raw.githubusercontent.com/john-g4lt/artix-rootfs/main/artix_logo.ico)

- Run it

  ![image 6](https://github.com/john-g4lt/artix-rootfs/assets/172701622/1d8860c9-8baa-4e43-abe2-f7bb1d982b53)

- Perform initial pacman-key setup, update the system and add basic `sudo` package:
  ```bash
  pacman-key --init
  ```
  ```bash
  pacman-key --populate
  ```
  ```bash
  pacman -Syyu --noconfirm
  ```
  ```bash
  pacman -S sudo --noconfirm
  ```

- Create a new user (change `USERNAME` to your username):
  ```bash
  useradd -m -s /bin/bash USERNAME
  ```
  ```bash
  passwd USERNAME
  ```

- Add user to sudoers (change `USERNAME` to your username):
  ```bash
  usermod -aG wheel USERNAME
  ```

- Write default `wsl.conf` config:
  ```bash
  cat >> /etc/wsl.conf << 'EOF'
  [automount]
  enabled = true
  options = "metadata,uid=1000,gid=1000,umask=22,fmask=11,case=off"
  mountFsTab = true
  crossDistro = true
  
  [network]
  generateHosts = true
  generateResolvConf = true
  
  [interop]
  enabled = true
  appendWindowsPath = true
  
  [user]
  default = USERNAME
  ```
  Don't forget to change `USERNAME` to your username, and then exit writing with `EOF` at a new line:
  ```bash
  EOF
  ```
  
- Shutdown WSL machine with:
  ```bash
  exit
  ```
  ```bash
  wsl.exe -t Artix
  ```
  ```bash
  exit
  ```
  
- Edit your shortcut path (in Properties) adding `-u USERNAME` (change `USERNAME` to your username) before `--cd ~`:
  ```bash
  %windir%\system32\cmd.exe /k cd %userprofile% && wsl.exe -d Artix -u USERNAME --cd ~
  ```

- Run it

  ![image 7](https://github.com/john-g4lt/artix-rootfs/assets/172701622/8fe895a4-557e-48b6-8c83-057b1bcf11cb)

  And here you are, logged as your user

- Recommended:
  - Pin to taskbar after running
  - Download, install and set your own [Nerd Font](https://www.nerdfonts.com/font-downloads), 
  I prefer [Roboto Mono Regular/Medium](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/RobotoMono.zip)

- Happy hacking :)

  And don't forget to star the repo pls!


## Devlog
- The main idea is to update & maintain artix rootfs

- Was decided to use [GitHub Action](https://github.com/john-g4lt/artix-rootfs/blob/main/.github/workflows/ci.yml) 
  to provide the latest version & to save my 20yo laptop resources (mainly my time lol) & just for fun of automation

- GitHub only allows to store maximum 2GB files

- Was decided to experiment with compression

- gzip compression of any level did not give satisfying result

- Found that `wsl` supports `.xz` compression container 
  (w lzma2 compression, generally available on any unix machine) 
  [as of 2 Apr 2023 as mentioned here](https://github.com/microsoft/WSL/issues/6056#issuecomment-1493423070)

- Found unix compressions
  [benchmark #1](https://stephane.lesimple.fr/blog/lzop-vs-compress-vs-gzip-vs-bzip2-vs-lzma-vs-lzma2xz-benchmark-reloaded/)
  & [benchmark #2](https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/)

- `xz -1` level of compression gives `896M` output that is alright for now

- `xz -T2` threads specified to speedup compression
  (takes ~1.5min to download
  & ~2.5min compress 
  & ~0.5min to upload artifact 
  & ~0.5min to upload artifact to release, 
  ~5min together)

- Found [an article that explains some math behind determining the optimal threads count](https://pavelkazenin.wordpress.com/2014/08/02/optimal-number-of-threads-in-parallel-computing/).
  This task does not require such kind of complexity to measure lzma2 algo params, 
  but just found it interesting for further reading

- Works as 13 June 2024,
  provided detailed `README.md` 
  & `Get form source` instructions, 
  trust nobody not even yourself kekw

- Now accepts `get.sh` arguments
  & changed `Get from source` instructions
  & tested

- Auto-releases enabled:
  Every GHA run automatically publishes a release

