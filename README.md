# VideoStation-FFMPEG-Patcher 

<p>
  <img src="https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/banner.png?raw=true" height=200px alt="Banner">
</p>

This patcher is designed to simplify the installation steps from this [Gist](https://gist.github.com/BenjaminPoncet/bbef9edc1d0800528813e75c1669e57e) (huge thanks to [Benjamin Poncet](https://github.com/BenjaminPoncet)) and enable **DTS**, **EAC3** and **TrueHD** support to Synology VideoStation by replacing the ffmpeg library files by a wrapper using SynoCommunity ffmpeg.

## Supported architectures
([check your NAS architecture here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model))
- ARMv8 ⚠️ (DSM 7.0 ready but the wrapper could have performances issues on some NAS models)
- Old ARM ✅ (DSM 7.0 ready)
- x64 ✅ (DSM 7.0 ready)
- x86 ✅ (DSM 7.0 ready)

## Dependencies
- DSM 6.2.2-24922 Update 4 (and above)
- Video Station 2.4.6-1594 (and above)
- SynoCommunity ffmpeg 4.2.1-23 (and above) ([help](https://synocommunity.com/#easy-install))

## Instructions
- Check that you meet the required [dependencies](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher#dependencies)
- Install SynoCommunity ffmpeg ([help](https://synocommunity.com/#easy-install))
- Connect to your NAS using SSH (admin user required) ([help](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Use the command `sudo -i` to switch to root user
- Use the [following](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher#usage) command (Basic command) to execute the patch
- You'll have to re-run the patcher everytime you update VideoStation, Advanced Media Extensions and DSM

## Usage
Basic command usage:  
`curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash`   
With options:  
`curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash -s -- <option>`

| Options | Description |
| ------ | ----------- |
| -f | Force patcher to install ffmpeg-wrapper (only usefull on ARMv8 architectures if the default procedure doesn't work)
