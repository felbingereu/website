# ffmpeg

## static color
```shell
ffmpeg -f lavfi -i color=c=red:s=1280x720:d=10 -c:v libx264 -pix_fmt yuv420p output.mp4
```

## stack videos
```shell
# create videos with static color to visualize stacking
for c in red green blue yellow; do
  ffmpeg -f lavfi -i color=c=${c}:s=1280x720:d=10 -c:v libx264 -pix_fmt yuv420p ${c}.mp4
done

ffmpeg \
  -i red.mp4 -i green.mp4 -i blue.mp4 -i yellow.mp4 \
  -filter_complex " \
    [0:v][1:v][2:v][3:v]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out] \
  " \
  -map "[out]" -c:v libx264 -crf 23 -preset veryfast output.mp4
```
