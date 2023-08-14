---
name: Bug report
about: Create a report to help improve the patcher
title: "[BUG] try to name your bug"
labels: ''
assignees: ''

---

# Before posting any bug issue, please make sure you have patched a clean VideoStation / AME install by doing the following:
- Uninstall VideoStation (keep your library)
- Uninstall Advanced Media Extensions
- Re-install VideoStation (it should also ask to install Advanced Media Extensions)
- Run the patch

**Provide System Details**
- Start the video on VideoStation, wait for the video to play and put the browser in background (keep the video playing)
- Connect through SSH ([help](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Switch to root user: `sudo -i`
- Run the report tool: `curl https://raw.githubusercontent.com/AlexPresso/VideoStation-FFMPEG-Patcher/main/issue-report.sh | bash`
- Copy-paste the output to a new [gist](https://gist.github.com/) and put the link here

**Describe the bug**
A clear and concise description of what the bug is.

**Additional context**
Add any other context about the problem here.
