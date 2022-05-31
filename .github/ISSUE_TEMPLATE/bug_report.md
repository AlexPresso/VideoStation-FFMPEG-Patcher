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

**System details**
- Synology model: [Synology NAS model]
- DSM version: [version]
- SynoCommunity FFMPEG Version: [version]
- VideoStation version: [version]
- Advanced Media Extensions version: [version / "none" if you don't have it installed]

**Describe the bug**
A clear and concise description of what the bug is.

**Provide Log files**
- Start the video on VideoStation, wait for the video to play and put the browser in background (keep the video playing)
- Connect through SSH ([help](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Switch to root user: `sudo -i`

## `ffmpeg.log` (containing the ffmpeg-wrapper execution logs)
- Go to the temporary directory: `cd /tmp`
- Type `ls -al | grep ffmpeg` to list all files containing "ffmpeg" and check you have one named `ffmpeg.log`
- Type `tail -200 ffmpeg.log` to print the last 200 lines to the console
- Copy paste those lines in a new [gist](https://gist.github.com/)
- Add the gist link to the issue

## `ffmpeg-FFMxxxx.stderr` (containing chunks transcoding operations)
- When you ran `ls -al | grep ffmpeg` you should have seen another file that looks like `ffmpeg-FFMxxxx.stderr`
- Type `tail -100 ffmpeg-FFMxxxx.stderr` (replacing the filename by the correct one)
- Copy paste those lines in a new [gist](https://gist.github.com/)
- Type `head -300 ffmpeg-FFMxxxx.stderr` (replacing the filename by the correct one)
- Copy paste those lines in another new [gist](https://gist.github.com/)
- Copy paste all the gists links in the issue

**Additional context**
Add any other context about the problem here.
