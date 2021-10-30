__constant float EPSILON = 0.01f;
__constant int MAX_RAYS_CAST = 10;
__constant float DEFAULT_REFRACTIVE_INDEX = 1.0f;
__constant const float MAX_RAY_DISTANCE = FLT_MAX;
__constant float PIOVER180 = 0.017453292519943295769236907684886f;

#include "Stage3/Classes.cl"
#include "Stage3/Intersection.cl"
#include "Stage3/Output.cl"
#include "Stage3/Lighting.cl"

// follow a single ray until it's final destination (or maximum number of steps reached)
float3 traceRay(const Scene* scene, Ray viewRay)
{
	float3 output = { 0.0f, 0.0f, 0.0f };
	float currentRefractiveIndex = DEFAULT_REFRACTIVE_INDEX;		// current refractive index
	float coef = 1.0f;												// amount of ray left to transmit
	Intersection intersect;
																	// loop until reached maximum ray cast limit (unless loop is broken out of)
	for (int level = 0; level < MAX_RAYS_CAST; ++level)
	{
		// check for intersections between the view ray and any of the objects in the scene
		// exit the loop if no intersection found
		if (!objectIntersection(scene, &viewRay, &intersect)) break;

		calculateIntersectionResponse(scene, &viewRay, &intersect);

		if (!intersect.insideObject) output += coef * applyLighting(scene, &viewRay, &intersect);

		return output;
	}

	return output;
}

__kernel void func(__global struct Scene* scenein, int wwidth, int hheight, int aaLevel,
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

	// count of samples rendered
	unsigned int samplesRendered = 0;

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

				// count this sample
				samplesRendered++;
			}
		}

		out[iy * width + ix] = (unsigned char)((min(1.0f - exp(output.z * scene.exposure), 1.0f) * 255.0f)) << 16 | (unsigned char)((min(1.0f - exp(output.y * scene.exposure), 1.0f) * 255.0f)) << 8 | (unsigned char)((min(1.0f - exp(output.x * scene.exposure), 1.0f) * 255.0f));
	/*
	if (iy == 0 && ix == 0) {
		OutputInfo(&scene);
	}*/
}