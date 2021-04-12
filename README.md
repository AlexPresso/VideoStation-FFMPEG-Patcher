# VideoStation-FFMPEG-Patcher 

This patcher is designed to simplify the installation steps from this [Gist](https://gist.github.com/BenjaminPoncet/bbef9edc1d0800528813e75c1669e57e) (huge thanks to [Benjamin Poncet](https://github.com/BenjaminPoncet)) and enable **DTS**, **EAC3** and **TrueHD** support to Synology VideoStation by replacing the ffmpeg library files by the one of VideoStation-2.3.4-1468 (which supported those formats).

## Instructions
⚠️ Currently only working for rtd1296 ARMv8 architecture, I may do it for other CPUs if someone asks for it ([check your NAS architecture here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model). ⚠️

- Connect to your NAS using SSH (admin user required) ([help](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Use the command `sudo -i` to switch to root user
- Use the folowing command to execute the patch: `curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/patcher.sh | bash`
- Restart VideoStation (stop & start from Package Center)
