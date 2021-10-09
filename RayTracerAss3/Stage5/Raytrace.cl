__constant float EPSILON = 0.01f;
__constant int MAX_RAYS_CAST = 10;
__constant float DEFAULT_REFRACTIVE_INDEX = 1.0f;
__constant const float MAX_RAY_DISTANCE = FLT_MAX;
__constant float PIOVER180 = 0.017453292519943295769236907684886f;

#include "Stage5/Classes.cl"
#include "Stage5/Intersection.cl"
#include "Stage5/Materials.cl"
#include "Stage5/Output.cl"
#include "Stage5/Lighting.cl"


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
	float fCosThetaI = fabs(intersect->viewProjection);

	// glass-like material, we're computing the fresnel coefficient.
	if (fCosThetaI >= 1.0f)
	{
		// In this case the ray is coming parallel to the normal to the surface
		fCosThetaT = 1.0f;
	}
	else
	{
		float fSinThetaT = refractiveRatio * sqrt(1 - fCosThetaI * fCosThetaI);

		// Beyond the angle (1.0f) all surfaces are purely reflective
		fCosThetaT = (fSinThetaT * fSinThetaT >= 1.0f) ? 0.0f : sqrt(1 - fSinThetaT * fSinThetaT);
	}

	// Here we compute the transmitted ray with the formula of Snell-Descartes
	Ray newRay = { intersect->pos, (viewRay->dir + intersect->normal * fCosThetaI) * refractiveRatio - (intersect->normal * fCosThetaT) };

	return newRay;
}

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
		
		if (intersect.material->reflection) //unsure if works or too subtle
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
		output += coef * scene->materialContainer[scene->skyboxMaterialId].diffuse;
	}

	return output;
}


//TODO: add an appropriate set of parameters to transfer the data
	//MAY BE ABLE TO REMOVE WWIDTH AND HHEIGHT (we have get_global_size fo dat)
__kernel void func(__global struct Scene* scenein, int width, int height, int aaLevel,
	__global Material* materialContainerIn,
	__global Light* lightContainerIn,
	__global Sphere* sphereContainerIn,
	__global Plane* planeContainerIn,
	__global Cylinder* cylinderContainerIn,
	__global int* out, int blockSize, int pos) {

	Scene scene = *scenein;
	scene.materialContainer = materialContainerIn;
	scene.lightContainer = lightContainerIn;
	scene.sphereContainer = sphereContainerIn;
	scene.planeContainer = planeContainerIn;
	scene.cylinderContainer = cylinderContainerIn;

	unsigned int ix = get_global_id(0);
	unsigned int iy = get_global_id(1);
	
	// angle between each successive ray cast (per pixel, anti-aliasing uses a fraction of this)
	const float dirStepSize = 1.0f / (0.5f * width / tan(PIOVER180 * 0.5f * scene.cameraFieldOfView));

	// count of samples rendered
	unsigned int samplesRendered = 0;

	int ix2 = ix - (width / 2) + ((pos % (width / blockSize)) * blockSize);
	int iy2 = iy - (height / 2) + ((pos / (height / blockSize)) * blockSize);

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


	out[((iy2 + (height / 2)) * (width)+(ix2 + (width / 2)))] = (unsigned char)((min(1.0f - exp(output.z * scene.exposure), 1.0f) * 255.0f)) << 16 | (unsigned char)((min(1.0f - exp(output.y * scene.exposure), 1.0f) * 255.0f)) << 8 | (unsigned char)((min(1.0f - exp(output.x * scene.exposure), 1.0f) * 255.0f));

	//if (iy == 255 && ix == 255) {
		//OutputInfo(&scene);
	//}
}