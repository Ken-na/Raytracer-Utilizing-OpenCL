/*  The following code is a VERY heavily modified from code originally sourced from:
Ray tracing tutorial of http://www.codermind.com/articles/Raytracer-in-C++-Introduction-What-is-ray-tracing.html
It is free to use for educational purpose and cannot be redistributed outside of the tutorial pages. */

#define TARGET_WINDOWS

#pragma warning(disable: 4996)
#include "Timer.h"
#include "Primitives.h"
#include "Scene.h"
#include "Lighting.h"
#include "Intersection.h"
#include "ImageIO.h"
#include "LoadCL.h"

unsigned int buffer[MAX_WIDTH * MAX_HEIGHT];
unsigned int combBuffer[MAX_WIDTH * MAX_HEIGHT];

// reflect the ray from an object
Ray calculateReflection(const Ray* viewRay, const Intersection* intersect)
{
	// reflect the viewRay around the object's normal
	Ray newRay = { intersect->pos, viewRay->dir - (intersect->normal * intersect->viewProjection * 2.0f) };

	return newRay;
}


// refract the ray through an object
Ray calculateRefraction(const Ray* viewRay, const Intersection* intersect, float* currentRefractiveIndex)
{
	// change refractive index depending on whether we are in an object or not
	float oldRefractiveIndex = *currentRefractiveIndex;
	*currentRefractiveIndex = intersect->insideObject ? DEFAULT_REFRACTIVE_INDEX : intersect->material->density;

	// calculate refractive ratio from old index and current index
	float refractiveRatio = oldRefractiveIndex / *currentRefractiveIndex;

	// Here we take into account that the light movement is symmetrical from the observer to the source or from the source to the oberver.
	// We then do the computation of the coefficient by taking into account the ray coming from the viewing point.
	float fCosThetaT;
	float fCosThetaI = fabsf(intersect->viewProjection);

	// glass-like material, we're computing the fresnel coefficient.
	if (fCosThetaI >= 1.0f)
	{
		// In this case the ray is coming parallel to the normal to the surface
		fCosThetaT = 1.0f;
	}
	else
	{
		float fSinThetaT = refractiveRatio * sqrtf(1 - fCosThetaI * fCosThetaI);

		// Beyond the angle (1.0f) all surfaces are purely reflective
		fCosThetaT = (fSinThetaT * fSinThetaT >= 1.0f) ? 0.0f : sqrtf(1 - fSinThetaT * fSinThetaT);
	}

	// Here we compute the transmitted ray with the formula of Snell-Descartes
	Ray newRay = { intersect->pos, (viewRay->dir + intersect->normal * fCosThetaI) * refractiveRatio - (intersect->normal * fCosThetaT) };

	return newRay;
}


// follow a single ray until it's final destination (or maximum number of steps reached)
Colour traceRay(const Scene* scene, Ray viewRay)
{
	Colour output(0.0f, 0.0f, 0.0f); 								// colour value to be output
	float currentRefractiveIndex = DEFAULT_REFRACTIVE_INDEX;		// current refractive index
	float coef = 1.0f;												// amount of ray left to transmit
	Intersection intersect;											// properties of current intersection

																	// loop until reached maximum ray cast limit (unless loop is broken out of)
	for (int level = 0; level < MAX_RAYS_CAST; ++level)
	{
		// check for intersections between the view ray and any of the objects in the scene
		// exit the loop if no intersection found
		if (!objectIntersection(scene, &viewRay, &intersect)) break;

		// calculate response to collision: ie. get normal at point of collision and material of object
		calculateIntersectionResponse(scene, &viewRay, &intersect);

		// apply the diffuse and specular lighting 
		if (!intersect.insideObject) output += coef * applyLighting(scene, &viewRay, &intersect);

		// if object has reflection or refraction component, adjust the view ray and coefficent of calculation and continue looping
		if (intersect.material->reflection)
		{
			viewRay = calculateReflection(&viewRay, &intersect);
			coef *= intersect.material->reflection;
		}
		else if (intersect.material->refraction)
		{
			viewRay = calculateRefraction(&viewRay, &intersect, &currentRefractiveIndex);
			coef *= intersect.material->refraction;
		}
		else
		{
			// if no reflection or refraction, then finish looping (cast no more rays)
			return output;
		}
	}

	// if the calculation coefficient is non-zero, read from the environment map
	if (coef > 0.0f)
	{
		Material& currentMaterial = scene->materialContainer[scene->skyboxMaterialId];

		output += coef * currentMaterial.diffuse;
	}

	return output;
}

// render scene at given width and height and anti-aliasing level
int render(Scene* scene, const int width, const int height, const int aaLevel, bool testMode)
{
	// angle between each successive ray cast (per pixel, anti-aliasing uses a fraction of this)
	const float dirStepSize = 1.0f / (0.5f * width / tanf(PIOVER180 * 0.5f * scene->cameraFieldOfView));

	// pointer to output buffer
	unsigned int* out = buffer;

	// count of samples rendered
	unsigned int samplesRendered = 0;

	// loop through all the pixels
	for (int y = -height / 2; y < height / 2; ++y)
	{
		for (int x = -width / 2; x < width / 2; ++x)
		{
			Colour output(0.0f, 0.0f, 0.0f);

			// calculate multiple samples for each pixel
			const float sampleStep = 1.0f / aaLevel, sampleRatio = 1.0f / (aaLevel * aaLevel);

			// loop through all sub-locations within the pixel
			for (float fragmentx = float(x); fragmentx < x + 1.0f; fragmentx += sampleStep)
			{
				for (float fragmenty = float(y); fragmenty < y + 1.0f; fragmenty += sampleStep)
				{
					// direction of default forward facing ray
					Vector dir = { fragmentx * dirStepSize, fragmenty * dirStepSize, 1.0f };

					// rotated direction of ray
					Vector rotatedDir = {
						dir.x * cosf(scene->cameraRotation) - dir.z * sinf(scene->cameraRotation),
						dir.y,
						dir.x * sinf(scene->cameraRotation) + dir.z * cosf(scene->cameraRotation) };

					// view ray starting from camera position and heading in rotated (normalised) direction
					Ray viewRay = { scene->cameraPosition, normalise(rotatedDir) };

					// follow ray and add proportional of the result to the final pixel colour
					output += sampleRatio * traceRay(scene, viewRay);

					// count this sample
					samplesRendered++;
				}
			}

			if (!testMode)
			{
				// store saturated final colour value in image buffer
				*out++ = output.convertToPixel(scene->exposure);
			}
			else
			{
				// store colour (calculated from x,y coordinates) in image buffer 
				*out++ = Colour((x + width / 2) % 256 / 255.0f, 0, (y + height / 2) % 256 / 255.0f).convertToPixel();
			}
		}
	}

	return samplesRendered;
}

// output a bunch of info about the contents of the scene
void OutputInfo(const Scene* scene)
{
	Plane* planes = scene->planeContainer;
	Cylinder* cylinders = scene->cylinderContainer;
	Sphere* spheres = scene->sphereContainer;
	Light* lights = scene->lightContainer;
	Material* materials = scene->materialContainer;

	printf("\n---- CPU --------\n");
	printf("sizeof(Point):    %zd\n", sizeof(Point));
	printf("sizeof(Vector):   %zd\n", sizeof(Vector));
	printf("sizeof(Colour):   %zd\n", sizeof(Colour));
	printf("sizeof(Ray):      %zd\n", sizeof(Ray));
	printf("sizeof(Light):    %zd\n", sizeof(Light));
	printf("sizeof(Sphere):   %zd\n", sizeof(Sphere));
	printf("sizeof(Plane):    %zd\n", sizeof(Plane));
	printf("sizeof(Cylinder): %zd\n", sizeof(Cylinder));
	printf("sizeof(Material): %zd\n", sizeof(Material));
	printf("sizeof(Scene):    %zd\n", sizeof(Scene));

	printf("\n--- Scene:\n");;
	printf("pos: %.1f %.1f %.1f\n", scene->cameraPosition.x, scene->cameraPosition.y, scene->cameraPosition.z);
	printf("rot: %.1f\n", scene->cameraRotation);
	printf("fov: %.1f\n", scene->cameraFieldOfView);
	printf("exp: %.1f\n", scene->exposure);
	printf("sky: %d\n", scene->skyboxMaterialId);

	printf("\n--- Spheres (%d):\n", scene->numSpheres);;
	for (unsigned int i = 0; i < scene->numSpheres; ++i)
	{
		if (scene->numSpheres > 10 && i >= 3 && i < scene->numSpheres - 3)
		{
			printf(" ... \n");
			i = scene->numSpheres - 3;
			continue;
		}

		printf("Sphere %d: %.1f %.1f %.1f, %.1f -- %d\n", i, spheres[i].pos.x, spheres[i].pos.y, spheres[i].pos.z, spheres[i].size, spheres[i].materialId);
	}

	printf("\n--- Planes (%d):\n", scene->numPlanes);
	for (unsigned int i = 0; i < scene->numPlanes; ++i)
	{
		if (scene->numPlanes > 10 && i >= 3 && i < scene->numPlanes - 3)
		{
			printf(" ... \n");
			i = scene->numPlanes - 3;
			continue;
		}

		printf("Plane %d: %.1f %.1f %.1f, %.1f %.1f %.1f -- %d\n", i,
			planes[i].pos.x, planes[i].pos.y, planes[i].pos.z,
			planes[i].normal.x, planes[i].normal.y, planes[i].normal.z,
			planes[i].materialId
		);
	}

	printf("\n--- Cylinders (%d):\n", scene->numCylinders);
	for (unsigned int i = 0; i < scene->numCylinders; ++i)
	{
		if (scene->numCylinders > 10 && i >= 3 && i < scene->numCylinders - 3)
		{
			printf(" ... \n");
			i = scene->numCylinders - 3;
			continue;
		}

		printf("Cylinder %d: %.1f %.1f %.1f, %.1f %.1f %.1f, %.1f -- %d\n", i,
			cylinders[i].p1.x, cylinders[i].p1.y, cylinders[i].p1.z,
			cylinders[i].p2.x, cylinders[i].p2.y, cylinders[i].p2.z,
			cylinders[i].size,
			cylinders[i].materialId
		);
	}

	printf("\n--- Lights (%d):\n", scene->numLights);
	for (unsigned int i = 0; i < scene->numLights; ++i)
	{
		if (scene->numLights > 10 && i >= 3 && i < scene->numLights - 3)
		{
			printf(" ... \n");
			i = scene->numLights - 3;
			continue;
		}

		printf("Light %d: %.1f %.1f %.1f -- %.1f %.1f %.1f\n", i,
			lights[i].pos.x, lights[i].pos.y, lights[i].pos.z,
			lights[i].intensity.red, lights[i].intensity.green, lights[i].intensity.blue);
	}

	printf("\n--- Materials (%d):\n", scene->numMaterials);
	for (unsigned int i = 0; i < scene->numMaterials; ++i)
	{
		if (scene->numMaterials > 10 && i >= 3 && i < scene->numMaterials - 3)
		{
			printf(" ... \n");
			i = scene->numMaterials - 3;
			continue;
		}

		printf("Material %d: %d %.1f %.1f %.1f ... %.1f %.1f %.1f\n", i,
			materials[i].type,
			materials[i].diffuse.red, materials[i].diffuse.green, materials[i].diffuse.blue,
			materials[i].reflection,
			materials[i].refraction,
			materials[i].density);
	}
}


// read command line arguments, render, and write out BMP file
int main(int argc, char* argv[])
{
	int width = 1024;
	int height = 1024;
	int samples = 1;

	// rendering options
	int times = 1;
	bool testMode = false;

	// default input / output filenames
	const char* inputFilename = "Scenes/allmaterials.txt"; 

	int blockSize = 256;

	char outputFilenameBuffer[1000];
	char* outputFilename = outputFilenameBuffer;

	// do stuff with command line args
	for (int i = 1; i < argc; i++)
	{
		if (strcmp(argv[i], "-size") == 0)
		{
			width = atoi(argv[++i]);
			height = atoi(argv[++i]);
		}
		else if (strcmp(argv[i], "-samples") == 0) //stage one ignores samples flag. was getting an error when this was commented out
		{
			samples = atoi(argv[++i]);
			//i++;
			//samples = 1;
		}
		else if (strcmp(argv[i], "-input") == 0)
		{
			inputFilename = argv[++i];
		}
		else if (strcmp(argv[i], "-output") == 0)
		{
			outputFilename = argv[++i];
		}
		else if (strcmp(argv[i], "-runs") == 0)
		{
			times = atoi(argv[++i]);
		}
		else if (strcmp(argv[i], "-testMode") == 0)
		{
			testMode = true;
		}
		else if (strcmp(argv[i], "-blockSize") == 0)
		{
			blockSize = atoi(argv[++i]);
		}
		else
		{
			fprintf(stderr, "unknown argument: %s\n", argv[i]);
		}
	}

	// nasty (and fragile) kludge to make an ok-ish default output filename (can be overriden with "-output" command line option)
	sprintf(outputFilenameBuffer, "Outputs/%s_%dx%dx%d_%s.bmp", (strrchr(inputFilename, '/') + 1), width, height, samples, (strrchr(argv[0], '\\') + 1));

	// read scene file
	Scene scene;
	if (!init(inputFilename, scene))
	{
		fprintf(stderr, "Failure when reading the Scene file.\n");
		return -1;
	}

	Timer timer;		// create timer

	// OpenCL setup code goes here
	cl_int err;
	cl_platform_id platform;
	cl_device_id device;
	cl_context context;
	cl_command_queue queue;
	cl_program program;
	cl_kernel kernel;
	size_t workSize[] = { blockSize, blockSize };

	cl_mem clBuffer1;
	cl_mem clBuffer2;
	cl_mem clBuffer3;
	cl_mem clBuffer4;
	cl_mem clBuffer5;
	cl_mem clBuffer6;
	cl_mem clBuffer7;

	err = clGetPlatformIDs(1, &platform, NULL);
	if (err != CL_SUCCESS)
	{
		printf("\nError calling clGetPlatformIDs. Error code: %d\n", err);
		exit(1);
	}

	err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);
	if (err != CL_SUCCESS) {
		printf("Couldn't find any devices\n");
		exit(1);
	}

	context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create a context\n");
		exit(1);
	}

	queue = clCreateCommandQueue(context, device, 0, &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create the command queue\n");
		exit(1);
	}

	program = clLoadSource(context, "Stage5/Raytrace.cl", &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't load/create the program\n");
		exit(1);
	}

	err = clBuildProgram(program, 0, NULL, "-cl-std=CL1.2", NULL, NULL);
	if (err != CL_SUCCESS) {
		char* program_log;
		size_t log_size;

		clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);
		program_log = (char*)malloc(log_size + 1);
		program_log[log_size] = '\0';
		clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, log_size + 1, program_log, NULL);
		printf("%s\n", program_log);
		free(program_log);
		exit(1);
	}

	kernel = clCreateKernel(program, "func", &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create the kernel\n");
		exit(1);
	}

	clBuffer1 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(Scene), &scene, &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create a bufferIn1 object\n");
		exit(1);
	}
	//may need to be &'d
	clBuffer2 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(Material) * scene.numMaterials, scene.materialContainer, &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create a bufferIn2 object -> %d\n", err);
		exit(1);
	}
	clBuffer3 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(Light) * scene.numLights, scene.lightContainer, &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create a bufferIn3 object -> %d\n", err);
		exit(1);
	}

	if (scene.numSpheres > 0) {
		clBuffer4 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(Sphere) * scene.numSpheres, scene.sphereContainer, &err);
		if (err != CL_SUCCESS) {
			printf("Couldn't create a bufferIn4 object -> %d\n", err);
			exit(1);
		}
	}
	else {
		int dummyInt = -1;
		clBuffer4 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(int), &dummyInt, &err);
	}
	
	if (scene.numPlanes > 0) {
		clBuffer5 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(Plane) * scene.numPlanes, scene.planeContainer, &err);
		if (err != CL_SUCCESS) {
			printf("Couldn't create a bufferIn5 object -> %d\n", err);
			exit(1);
		}
	}
	else {
		int dummyInt2 = -1;
		clBuffer5 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(int), &dummyInt2, &err);
	}

	if (scene.numCylinders > 0) {
		clBuffer6 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(Cylinder) * scene.numCylinders, scene.cylinderContainer, &err);
		if (err != CL_SUCCESS) {
			printf("Couldn't create a bufferIn6 object -> %d\n", err);
			exit(1);
		}
	}
	else {
		int dummyInt3 = -1;
		clBuffer6 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(int), &dummyInt3, &err);
	}

	clBuffer7 = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(int) * width * height, buffer, &err);
	if (err != CL_SUCCESS) {
		printf("Couldn't create a bufferIn7 object -> %d\n", err);
		exit(1);
	}


	err = clSetKernelArg(kernel, 0, sizeof(cl_mem), &clBuffer1);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(0) argument\n");
		exit(1);
	}

	err = clSetKernelArg(kernel, 1, sizeof(int), &width);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(1) argument = %d\n", err);
		exit(1);
	}
	err = clSetKernelArg(kernel, 2, sizeof(int), &height);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(2) argument = %d\n", err);
		exit(1);
	}
	err = clSetKernelArg(kernel, 3, sizeof(int), &samples);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(3) argument = %d\n", err);
		exit(1);
	}
	
	//add additional kernal args. 
	err = clSetKernelArg(kernel, 4, sizeof(cl_mem), &clBuffer2);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(4) argument = %d\n", err);
		exit(1);
	}

	err = clSetKernelArg(kernel, 5, sizeof(cl_mem), &clBuffer3);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(5) argument = %d\n", err);
		exit(1);
	}

	err = clSetKernelArg(kernel, 6, sizeof(cl_mem), &clBuffer4);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(6) argument = %d\n", err);
		exit(1);
	}

	err = clSetKernelArg(kernel, 7, sizeof(cl_mem), &clBuffer5);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(7) argument = %d\n", err);
		exit(1);
	}

	err = clSetKernelArg(kernel, 8, sizeof(cl_mem), &clBuffer6);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(8) argument = %d\n", err);
		exit(1);
	}

	err = clSetKernelArg(kernel, 9, sizeof(cl_mem), &clBuffer7);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(9) argument\n");
		exit(1);
	}
	
	err = clSetKernelArg(kernel, 10, sizeof(int), &blockSize);
	if (err != CL_SUCCESS) {
		printf("Couldn't set the kernel(10) argument\n");
		exit(1);
	}

	// display info about the current scene
	//OutputInfo(&scene);

	int numOfCycles = (width / blockSize) * (height / blockSize);
	// first time and total time taken to render all runs (used to calculate average)
	int firstTime = 0;
	int totalTime = 0;
	int samplesRendered = 0;
	int pos = 0;

	int xPos = 0;
	int yPos = 0;
	for (int i = 0; i < times; i++)
	{
		if (i > 0) timer.start();

		for (int j = 0; j < numOfCycles; j++) {
			size_t workOffset[] = { 0, 0 };
			size_t workSize[] = { blockSize, blockSize };
			
			err = clSetKernelArg(kernel, 11, sizeof(int), &pos);
			if (err != CL_SUCCESS) {
				printf("Couldn't set the kernel(11) argument = %d\n", err);
				exit(1);
			}
			err = clEnqueueNDRangeKernel(queue, kernel, 2, workOffset, workSize, NULL, 0, NULL, NULL);
			if (err != CL_SUCCESS) {
				printf("Couldn't enqueue the kernel execution (%d) command = %d\n", pos, err);
				exit(1);
			}

			err = clEnqueueReadBuffer(queue, clBuffer7, CL_TRUE, 0, sizeof(int) * width * height, buffer, 0, NULL, NULL);
			if (err != CL_SUCCESS) {
				printf("Couldn't enqueue the read buffer (%d) command = %d\n", pos, err);
				exit(1);
			}

			pos++;
		}
		timer.end();																					// record end time
		if (i > 0)
		{
			totalTime += timer.getMilliseconds();														// record total time taken
		}
		else
		{
			firstTime = timer.getMilliseconds();														// record first time taken
		}
	}

	// output timing information (first run, times run and average)
	if (times > 1)
	{
		printf("first run time: %dms, subsequent average time taken (%d run(s)): %.1fms\n", firstTime, times - 1, totalTime / (float)(times - 1));
	}
	else
	{
		printf("first run time: %dms, subsequent average time taken (%d run(s)): N/A\n", firstTime, times - 1);
	}

	// output BMP file
	write_bmp(outputFilename, buffer, width, height, width);
}
