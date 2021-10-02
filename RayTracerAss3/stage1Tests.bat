@doskey magick = c:\Program Files\ImageMagick-7.0.10-Q8\magick.exe

Release\Stage1.exe -runs 1 -size 256 256   -samples 1 -output Outputs/a03s01t01.bmp -input Scenes/cornell.txt           
Release\Stage1.exe -runs 1 -size 1000 1000 -samples 4 -output Outputs/a03s01t02.bmp -input Scenes/allmaterials.txt 
Release\Stage1.exe -runs 1 -size 1280 720  -samples 1 -output Outputs/a03s01t03.bmp -input Scenes/5000spheres.txt 
Release\Stage1.exe -runs 1 -size 1024 1024 -samples 1 -output Outputs/a03s01t04.bmp -input Scenes/donuts.txt 
Release\Stage1.exe -runs 1 -size 1024 1024 -samples 1 -output Outputs/a03s01t05.bmp -input Scenes/cornell-199lights.txt

magick compare -metric mae Outputs\a03s01t01.bmp Outputs_REFERENCE\a03s01t01.bmp Outputs\stage1diff_01.bmp
magick compare -metric mae Outputs\a03s01t02.bmp Outputs_REFERENCE\a03s01t02.bmp Outputs\stage1diff_02.bmp
magick compare -metric mae Outputs\a03s01t03.bmp Outputs_REFERENCE\a03s01t03.bmp Outputs\stage1diff_03.bmp
magick compare -metric mae Outputs\a03s01t04.bmp Outputs_REFERENCE\a03s01t04.bmp Outputs\stage1diff_04.bmp
magick compare -metric mae Outputs\a03s01t05.bmp Outputs_REFERENCE\a03s01t05.bmp Outputs\stage1diff_05.bmp

