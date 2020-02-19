# Setup raspberry pi
1. Download the latest raspbian distribution

2. Expand into an SD card
```
unzip -p <raspbian distribution>.zip
sudo dd if=<raspbian dist>.img of=/dev/<SD card device> bs=4M conv=fsync status=progress
```

3.