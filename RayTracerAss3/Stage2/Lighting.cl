
float3 applyDiffuse(const Ray* lightRay, __global const Light* currentLight, const Intersection* intersect)
{
	float3 output = intersect->material->diffuse;

	float lambert = dot(lightRay->dir, intersect->normal);

	return lambert * currentLight->intensity * output;
}

float3 applySpecular(const Ray* lightRay, __global const Light* currentLight, const float fLightProjection, const Ray* viewRay, const Intersection* intersect)
{
	float3 blinnDir = lightRay->dir - viewRay->dir;
	float blinn = rsqrt(dot(blinnDir, blinnDir)) * max(fLightProjection - intersect->viewProjection, 0.0f);
	blinn = pow(blinn, intersect->material->power);

	return blinn * intersect->material->specular * currentLight->intensity;
}

// apply diffuse and specular lighting contributions for all lights in scene taking shadowing into account
float3 applyLighting(const Scene* scene, const Ray* viewRay, const Intersection* intersect)
{
	// colour to return (starts as black)
	float3 output = { 0.0f, 0.0f, 0.0f };

	// same starting point for each light ray
	Ray lightRay = { intersect->pos };

	// loop through all the lights
	for (unsigned int j = 0; j < scene->numLights; ++j)
	{
		// get reference to current light
		__global const Light* currentLight = &scene->lightContainer[j]; //no longer a pointer.

		// light ray direction need to equal the normalised vector in the direction of the current light
		// as we need to reuse all the intermediate components for other calculations, 
		// we calculate the normalised vector by hand instead of using the normalise function
		lightRay.dir = currentLight->pos - intersect->pos;
		float angleBetweenLightAndNormal = dot(lightRay.dir, intersect->normal);

		// skip this light if it's behind the object (ie. both light and normal pointing in the same direction)
		if (angleBetweenLightAndNormal <= 0.0f)
		{
			continue;
		}

		// distance to light from intersection point (and it's inverse)
		float lightDist = sqrt(dot(lightRay.dir, lightRay.dir));
		float invLightDist = 1.0f / lightDist;

		// light ray projection
		float lightProjection = invLightDist * angleBetweenLightAndNormal;

		// normalise the light direction
		lightRay.dir = lightRay.dir * invLightDist;

		// add diffuse lighting from colour / texture
		output += applyDiffuse(&lightRay, currentLight, intersect);

		// add specular lighting
		output += applySpecular(&lightRay, currentLight, lightProjection, viewRay, intersect);
	}

	return output;
}