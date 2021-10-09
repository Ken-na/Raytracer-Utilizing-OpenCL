// output a bunch of info about the contents of the scene
void OutputInfo(const Scene* scene)
{
	__global Plane* planes = scene->planeContainer;
	__global Cylinder* cylinders = scene->cylinderContainer;
	__global Sphere* spheres = scene->sphereContainer;
	__global Light* lights = scene->lightContainer;
	__global Material* materials = scene->materialContainer;

	printf("\n---- GPU --------\n");
	printf("sizeof(Point):    %d\n", sizeof(float3));
	printf("sizeof(Vector):   %d\n", sizeof(float3));
	printf("sizeof(Colour):   %d\n", sizeof(float3));
	printf("sizeof(Ray):      %d\n", sizeof(Ray));
	printf("sizeof(Light):    %d\n", sizeof(Light));
	printf("sizeof(Sphere):   %d\n", sizeof(Sphere));
	printf("sizeof(Plane):    %d\n", sizeof(Plane));
	printf("sizeof(Cylinder): %d\n", sizeof(Cylinder));
	printf("sizeof(Material): %d\n", sizeof(Material));
	printf("sizeof(Scene):    %d\n", sizeof(Scene));

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
			lights[i].intensity.x, lights[i].intensity.y, lights[i].intensity.z);
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
			materials[i].diffuse.x, materials[i].diffuse.y, materials[i].diffuse.z,
			materials[i].reflection,
			materials[i].refraction,
			materials[i].density);
	}

}