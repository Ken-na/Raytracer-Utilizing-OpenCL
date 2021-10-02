doskey magick = c:\Program Files\ImageMagick-7.0.10-Q8\magick.exe

Release\Stage4.exe -runs 10 -size 1024 1024 -samples 1  -output Outputs/a03s04timing01.bmp -input Scenes/cornell.txt           
Release\Stage4.exe -runs 10 -size 1024 1024 -samples 4  -output Outputs/a03s04timing02.bmp -input Scenes/cornell.txt           
Release\Stage4.exe -runs 10 -size 1024 1024 -samples 16 -output Outputs/a03s04timing03.bmp -input Scenes/cornell.txt           
Release\Stage4.exe -runs 10 -size 1000 1000 -samples 4  -output Outputs/a03s04timing04.bmp -input Scenes/allmaterials.txt 
Release\Stage4.exe -runs 10 -size 1280 720  -samples 1  -output Outputs/a03s04timing05.bmp -input Scenes/5000spheres.txt 
Release\Stage4.exe -runs 10 -size 1024 1024 -samples 1  -output Outputs/a03s04timing06.bmp -input Scenes/donuts.txt 
Release\Stage4.exe -runs 10 -size 1024 1024 -samples 1  -output Outputs/a03s04timing07.bmp -input Scenes/cornell-199lights.txt


