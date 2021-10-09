//All instances of "color" or "point" have been replaced with float3. 
__constant float PIOVER180 = 0.017453292519943295769236907684886f;
__constant int MAX_RAYS_CAST = 10;

#include "Stage2/Classes.cl"
#include "Stage2/Intersection.cl"
#include "Stage2/Output.cl"

// follow a single ray until it's final destination (or maximum number of steps reached)
float3 traceRay(const Scene* scene, Ray viewRay)
{
	float3 black = { 0.0f, 0.0f, 0.0f }; 								// colour value to be output
	float3 white = { 255.0f, 255.0f, 255.0f }; 								// colour value to be output
	float coef = 1.0f;												// amount of ray left to transmit
	// loop until reached maximum ray cast limit (unless loop is broken out of)
	for (int level = 0; level < MAX_RAYS_CAST; ++level)
	{
		// check for intersections between the view ray and any of the objects in the scene
		// exit the loop if no intersection found

		float t = FLT_MAX;

		for (unsigned int i = 0; i < scene->numSpheres; ++i)
		{
			if (isSphereIntersected(&scene->sphereContainer[i], &viewRay, &t))
			{
				return white;
			}
		}
		
		return black;
	}

	return black;
}

__kernel void func(__global struct Scene* scenein, int aaLevel,
	__global Material* materialContainerIn,
	__global Light* lightContainerIn,
	__global Sphere* sphereContainerIn,
	__global Plane* planeContainerIn,
	__global Cylinder* cylinderContainerIn,
	__global int* out) {

	Scene scene = *scenein;
	scene.materialContainer = materialContainerIn;
	scene.lightContainer = lightContainerIn;
	scene.sphereContainer = sphereContainerIn;
	scene.planeContainer = planeContainerIn;
	scene.cylinderContainer = cylinderContainerIn;

	unsigned int width = get_global_size(0);
	unsigned int height = get_global_size(1);

	unsigned int ix = get_global_id(0);
	unsigned int iy = get_global_id(1);
	
	// angle between each successive ray cast (per pixel, anti-aliasing uses a fraction of this)
	const float dirStepSize = 1.0f / (0.5f * width / tan(PIOVER180 * 0.5f * scene.cameraFieldOfView));

	int ix2 = ix - (width / 2);
	int iy2 = iy - (height / 2);

	float3 output = { 0.0f, 0.0f, 0.0f };

		// calculate multiple samples for each pixel
		const float sampleStep = 1.0f / aaLevel, sampleRatio = 1.0f / (aaLevel * aaLevel);

		// loop through all sub-locations within the pixel
		for (float fragmentx = (float)ix2; fragmentx < ix2 + 1.0f; fragmentx += sampleStep)
		{
			for (float fragmenty = (float)iy2; fragmenty < iy2 + 1.0f; fragmenty += sampleStep)
			{
				// direction of default forward facing ray
				float3 dir = { fragmentx * dirStepSize, fragmenty * dirStepSize, 1.0f };

				// rotated direction of ray
				float3 rotatedDir = {
					dir.x * cos(scene.cameraRotation) - dir.z * sin(scene.cameraRotation),
					dir.y,
					dir.x * sin(scene.cameraRotation) + dir.z * cos(scene.cameraRotation) };

				// view ray starting from camera position and heading in rotated (normalised) direction
				Ray viewRay = { scene.cameraPosition, normalise(rotatedDir) };

				// follow ray and add proportional of the result to the final pixel colour
				output += sampleRatio * traceRay(&scene, viewRay);
			}
		}

		out[iy * width + ix] = (((int)(output.x) << 16) | ((int)(output.y) << 8) | (int)(output.z));

	//if (iy == 0 && ix == 0) {
	//	OutputInfo(&scene);
	//}


}