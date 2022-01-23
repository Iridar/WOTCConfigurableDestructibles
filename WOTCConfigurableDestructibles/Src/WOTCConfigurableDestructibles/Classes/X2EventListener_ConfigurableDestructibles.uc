class X2EventListener_ConfigurableDestructibles extends X2EventListener config(ConfigurableDestructibles);

struct DestructibleDamageStruct
{
	var name AbilityTemplate;
	var WeaponDamageValue Damage;
	var float EnvironmentalDamage;
};
var config array<DestructibleDamageStruct> AbilityBaseDamage;
var config array<DestructibleDamageStruct> DefaultAbilityBaseDamage;

var config array<name> AffectAbilities;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate());

	return Templates;
}


static function CHEventListenerTemplate CreateListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_ConfigurableDestructibles');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	Template.AddCHEvent('ObjectDestroyed', OnObjectDestroyed, ELD_Immediate, 50);

	return Template;
}

static function EventListenerReturn OnObjectDestroyed(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameState_Destructible				Destructible;
	local XComDestructibleActor						DestructibleActor;
	local XComDestructibleActor_Action_RadialDamage	RadialDamage;
	local XComGameStateHistory						History;
	local XComGameState_Effect						EffectState;
	local XComGameState_Unit						DetonatorUnit;
	local XComGameState_Ability						AbilityState;
	local XComLWTuple								Tuple;
	local int i;

	Destructible = XComGameState_Destructible(EventSource);
	if (Destructible == none)
		return ELR_NoInterrupt;
	
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		// Find the Effect State responsible for creating this Destructible object.
		if (EffectState.CreatedObjectReference.ObjectID == Destructible.ObjectID)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
			if (AbilityState == none || default.AffectAbilities.Find(AbilityState.GetMyTemplateName()) == INDEX_NONE)
				return ELR_NoInterrupt;
			
			DestructibleActor = XComDestructibleActor(Destructible.GetVisualizer());
			if (DestructibleActor == none)
				return ELR_NoInterrupt;

			for (i = 0; i < DestructibleActor.DestroyedEvents.Length; i++)
			{
				RadialDamage = XComDestructibleActor_Action_RadialDamage(DestructibleActor.DestroyedEvents[i].Action);
				if (RadialDamage != none)
				{
					DetonatorUnit = XComGameState_Unit(EventData);
					FillTupleForAbilityAndTriggerEvent(Tuple, AbilityState, DetonatorUnit);

					//`LOG(AbilityState.GetMyTemplateName() @ "Multi Target Style env. damage:" @ X2AbilityMultiTarget_ClaymoreRadius(AbilityState.GetMyTemplate().AbilityMultiTargetStyle).ClaymoreEnvironmentalDamage @ "archetype env. damage:" @ RadialDamage.EnvironmentalDamage,, 'IRITEST');

					RadialDamage.DamageTileRadius = Tuple.Data[0].f / class'XComWorldData'.const.WORLD_StepSize;
					RadialDamage.UnitDamage = Tuple.Data[1].f;
					RadialDamage.ArmorShred = Tuple.Data[2].f;
					RadialDamage.DamageTypeName = Tuple.Data[3].n;
					RadialDamage.EnvironmentalDamage = Tuple.Data[4].f;

					break;
				}
			}

			break;
		}
	}
	return ELR_NoInterrupt;
}

private static function DestructibleDamageStruct GetDamageStructForAbility(const name AbilityTemplate)
{
	local DestructibleDamageStruct EmptyStruct;
	local int Index;

	Index = default.AbilityBaseDamage.Find('AbilityTemplate', AbilityTemplate);
	if (Index != INDEX_NONE)
	{
		return default.AbilityBaseDamage[Index];
	}
	else
	{
		Index = default.DefaultAbilityBaseDamage.Find('AbilityTemplate', AbilityTemplate);
		if (Index != INDEX_NONE)
		{
			return default.DefaultAbilityBaseDamage[Index];
		}
		else
		{
			`LOG("WARNING :: No configuration for destructible ability:" @ AbilityTemplate,, 'WOTCConfigurableClaymore');
		}
	}
	return EmptyStruct;
}


final static function FillTupleForAbilityAndTriggerEvent(out XComLWTuple Tuple, const XComGameState_Ability AbilityState, optional const XComGameState_Unit DetonatorUnit)
{
	local DestructibleDamageStruct DamageStruct;

	DamageStruct = GetDamageStructForAbility(AbilityState.GetMyTemplateName());

	Tuple = new class'XComLWTuple';

	// Explanation for why we subtract half a tile:
	// AbilityState.GetAbilityRadius() goes to X2AbilityMultiTarget_ClaymoreRadius, 
	// which takes the DamageTileRadius set in the destructible archetype and adds +0.5 tiles to it.
	// Presumably this is done solely for the benefit of the targeting method, so that the explosion emitter fully covers the affected tiles.
	// However, later we want to assign the radius reported by GetAbilityRadius() back to the destructible archetype for the actual explosion
	// and we don't need that half a tile added to it. 
	// Since we know GetAbilityRadius() will always report radius half a tile bigger than the actual explosion, we just subtract half a tile right now.

	Tuple.Data.Add(7);
	Tuple.Data[0].Kind = XComLWTVFloat;
	Tuple.Data[0].f = AbilityState.GetAbilityRadius() - class'XComWorldData'.const.WORLD_HalfStepSize; // Radius, in Unreal Units
	Tuple.Data[1].Kind = XComLWTVFloat;
	Tuple.Data[1].f = DamageStruct.Damage.Damage; // UnitDamage
	Tuple.Data[2].Kind = XComLWTVFloat;
	Tuple.Data[2].f = DamageStruct.Damage.Shred; // ArmorShred
	Tuple.Data[3].Kind = XComLWTVName;
	Tuple.Data[3].n = DamageStruct.Damage.DamageType; // DamageTypeName
	Tuple.Data[4].Kind = XComLWTVFloat;
	Tuple.Data[4].f = DamageStruct.EnvironmentalDamage; // EnvironmentalDamage
	
	Tuple.Data[5].Kind = XComLWTVObject;
	Tuple.Data[5].o = DetonatorUnit; // Unit that exploded the Destructible

	`XEVENTMGR.TriggerEvent('OverrideDestructibleDamageAndRadius', Tuple, AbilityState);
}
