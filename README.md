## 1.  Purpose
With the use of this script, the same wording can be used to start a build when starting a major roms build.<br>
Purpose is by checking the ROM specific parameters to make it easier to start building. But note that the README in the manifest repository is more correct.<br>

## 2.  Install method<br>
```
$ mkdir ~/bin && cd $_
$ git clone https://github.com/BrightTwikling/Find_Lunch_Command.git
```
Add following code to ~/.bashrc
```
export PATH=~/bin/Find_Lunch_Command:$PATH
alias find_lunch_cmd='source find_lunch_command.sh'
```
After adding, conduct following
```
$ . ~/.bashrc
```
## 3. How to use<br>
```
$ find_lunch_cmd <device_name>
```

This script find  each parameter in following code: <br>
```
lunch $pattern_$target-$aosp_target_release-$variant
```
and this script conduct following code<br>
```
$  . build/envsetup.sh
$  lunch $pattern_$target-$aosp_target_release-$variant
```
