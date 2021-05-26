# VideoStation-FFMPEG-Patcher 

<p>
  <img src="https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher/blob/main/banner.png?raw=true" height=200px alt="Banner">
</p>

This patcher is designed to simplify the installation steps from this [Gist](https://gist.github.com/BenjaminPoncet/bbef9edc1d0800528813e75c1669e57e) (huge thanks to [Benjamin Poncet](https://github.com/BenjaminPoncet)) and enable **DTS**, **EAC3** and **TrueHD** support to Synology VideoStation by replacing the ffmpeg library files by the one of VideoStation-2.3.4-1468 (which supported those formats).

## Supported architectures
([check your NAS architecture here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model))
- ARMv8 ✅
- Old ARM  ✅
- x64 ✅
- x86 ✅

## Dependencies
- DSM 6.2.2-24922 Update 4 (and above)
- Video Station 2.4.6-1594 (and above)
- SynoCommunity ffmpeg 4.2.1-23 (and above) ([help](https://synocommunity.com/#easy-install))

## Instructions
- Check that you meet the required [dependencies](https://github.com/AlexPresso/VideoStation-FFMPEG-Patcher#dependencies)
- Install SynoCommunity ffmpeg ([help](https://synocommunity.com/#easy-install))
- Connect to your NAS using SSH (admin user required) ([help](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Use the command `sudo -i` to switch to root user
- Use the folowing command to execute the patch: 

`curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash`
- VideoStation will have to be repatched everytime you update it (and when you update DSM)

