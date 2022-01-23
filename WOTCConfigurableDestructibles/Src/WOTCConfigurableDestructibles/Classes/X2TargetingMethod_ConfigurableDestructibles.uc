class X2TargetingMethod_ConfigurableDestructibles extends X2TargetingMethod_GrenadePerkWeapon;

simulated protected function DrawSplashRadius()
{
	local Vector Center;
	local float Radius;
	local LinearColor CylinderColor;

	local XComLWTuple Tuple;

	Center = GetSplashRadiusCenter( true );

	// Removed
	// Ability.GetAbilityRadius();
	
	if (ExplosionEmitter != none && Center != ExplosionEmitter.Location)
	{
		class'X2EventListener_ConfigurableDestructibles'.static.FillTupleForAbilityAndTriggerEvent(Tuple, Ability);
		// Tuple.Data[0].f is ability radius in unreal units.

		// Detailed explanation for why we add half a tile here is in the X2EventListener class,
		// but in short - just to make the explosion emitter fully cover the affected tiles.
		// Purely cosmetic thing, and this is what - presumably - native code does under the hood.
		Radius = Tuple.Data[0].f + class'XComWorldData'.const.WORLD_HalfStepSize;

		ExplosionEmitter.SetLocation(Center); // Set initial location of emitter
		ExplosionEmitter.SetDrawScale(Radius / 48.0f);
		ExplosionEmitter.SetRotation( rot(0,0,1) );

		if( !ExplosionEmitter.ParticleSystemComponent.bIsActive )
		{
			ExplosionEmitter.ParticleSystemComponent.ActivateSystem();			
		}

		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(0, Name("RadiusColor"), CylinderColor);
		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(1, Name("RadiusColor"), CylinderColor);
	}
}
