# VideoStation-FFMPEG-Patcher

<p align="center">
  <img src="https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/banner.png?raw=true" height=200px alt="Banner">
</p>

This patcher is designed to continue the work of [Benjamin Poncet](https://github.com/BenjaminPoncet), to enable **DTS**, **EAC3** and **TrueHD** support to Synology VideoStation, by replacing the original ffmpeg and gstreamer files by a wrapper using SynoCommunity packages.

Huge thanks to [Benjamin Poncet](https://github.com/BenjaminPoncet), [Vincent Fortier](https://github.com/th0ma7), [SynoCommunity](https://github.com/SynoCommunity) and all contributors.

### Also want to patch MediaServer ? [there you go](https://github.com/AlexPresso/mediaserver-ffmpeg-patcher)

## Dependencies
- DSM 6.2.2-24922 Update 4 (and above)
- Video Station 2.4.6-1594 (and above)
- SynoCommunity ffmpeg 4.x.x ([help](https://synocommunity.com/#easy-install)) ⚠️ ffmpeg5 and ffmpeg6 cannot be used with VideoStation for now.

## Supported / Unsupported scenarios
- **[DTS or EAC3 or TrueHD] + [Any non HEVC standard video format]**: ✅
- **[no DTS, no EAC3, no TrueHD] + [HEVC]**: ✅
- **[DTS or EAC3 or TrueHD] + [HEVC]**: ⚠️ Not working on architectures where Advanced Media Extensions uses GStreamer for audio decoding (Please don't submit any more issue related to this scenario, I'm working on it, see [#33](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/pull/33))

## Instructions
- Check that you meet the required [dependencies](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher#dependencies)
- Install SynoCommunity ffmpeg ([help](https://synocommunity.com/#easy-install))
- If you plan to play HEVC / AAC videos, install Advanced Media Extensions
- Connect to your NAS using SSH (admin user required) ([help](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Use the command `sudo -i` to switch to root user
- Use the [following](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher#usage) command (Basic command) to execute the patch
- You'll have to re-run the patcher everytime you update VideoStation, Advanced Media Extensions and DSM

## Usage
Basic command:  
`curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash`   
With options:  
`curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash -s -- <flags>`

| Flags | Required | Description                                                                               | Default            |
|-------|----------|-------------------------------------------------------------------------------------------|--------------------|
| -a    | No       | Action flag: choose between `patch` or `unpatch` ; example: `-a patch`                    | patch              |
| -b    | No       | Branch flag: allows you to choose the wrapper branch to use ; example `-b main`           | main               |                                                  
| -p    | No       | Proxy flag: allows you to use a proxy to connect to github ; example `-p http://my-proxy` | https://github.com |
| -v    | No       | FFMpeg version flag: allows you to choose desired ffmpeg version ; example `-v 5`         | 4                  |
