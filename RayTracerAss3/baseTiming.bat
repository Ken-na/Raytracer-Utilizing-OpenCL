@ECHO OFF
set runs=%1
if "%1"=="" set runs=5
@ECHO ON
Release\RayTracerAss3.exe -runs %runs% -size 1024 1024 -samples 1  -input Scenes/cornell.txt  
Release\RayTracerAss3.exe -runs %runs% -size 1024 1024 -samples 4  -input Scenes/cornell.txt  
Release\RayTracerAss3.exe -runs %runs% -size 1024 1024 -samples 16 -input Scenes/cornell.txt  
Release\RayTracerAss3.exe -runs %runs% -size 1000 1000 -samples 4  -input Scenes/allmaterials.txt 
Release\RayTracerAss3.exe -runs %runs% -size 1280  720 -samples 1  -input Scenes/5000spheres.txt 
Release\RayTracerAss3.exe -runs %runs% -size 1024 1024 -samples 1  -input Scenes/donuts.txt 
Release\RayTracerAss3.exe -runs %runs% -size 1024 1024 -samples 1  -input Scenes/cornell-199lights.txt

@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1024 1024 -samples 1  -input Scenes/cornell.txt  
@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1024 1024 -samples 4  -input Scenes/cornell.txt  
@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1024 1024 -samples 16 -input Scenes/cornell.txt  
@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1000 1000 -samples 4  -input Scenes/allmaterials.txt 
@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1280  720 -samples 1  -input Scenes/5000spheres.txt 
@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1024 1024 -samples 1  -input Scenes/donuts.txt 
@rem Release\RayTracerAss1.exe -runs %runs% -threads 32 -size 1024 1024 -samples 1  -input Scenes/cornell-199lights.txt

@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1024 1024 -samples 1  -input Scenes/cornell.txt  
@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1024 1024 -samples 4  -input Scenes/cornell.txt  
@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1024 1024 -samples 16 -input Scenes/cornell.txt  
@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1000 1000 -samples 4  -input Scenes/allmaterials.txt 
@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1280  720 -samples 1  -input Scenes/5000spheres.txt 
@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1024 1024 -samples 1  -input Scenes/donuts.txt 
@rem Release\RayTracerAss2.exe -runs %runs% -threads 32 -size 1024 1024 -samples 1  -input Scenes/cornell-199lights.txt
