class X2DLCInfo_WOTCConfigurableDestructibles extends X2DownloadableContentInfo;


// TODO: Tag expand handler
// TODO: Environmental damage preview in Highlander? Pointless, see https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/1133

static event OnPreCreateTemplates()
{
	class'X2TargetingMethod_ConfigurableDestructibles'.default.AbilityPathData = class'X2TargetingMethod_GrenadePerkWeapon'.default.AbilityPathData;
}

static event OnPostTemplatesCreated()
{
	local name AffectAbilityName;

	foreach class'X2EventListener_ConfigurableDestructibles'.default.AffectAbilities(AffectAbilityName)
	{
		PatchAbility(AffectAbilityName);
	}
}


private static function PatchAbility(const name TemplateName)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager Mgr;

	Mgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = Mgr.FindAbilityTemplate(TemplateName);
	if (AbilityTemplate != none)
	{
		AbilityTemplate.TargetingMethod = class'X2TargetingMethod_ConfigurableDestructibles';
		AbilityTemplate.DamagePreviewFn = ConfigurableClaymoreDamagePreview;

		
		// Allow for Spread and +1
	}
}

private static function bool ConfigurableClaymoreDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComLWTuple Tuple;

	class'X2EventListener_ConfigurableDestructibles'.static.FillTupleForAbilityAndTriggerEvent(Tuple, AbilityState);
	
	MinDamagePreview.Damage = Tuple.Data[1].f;
	MaxDamagePreview = MinDamagePreview;
	return true;
}

/// <summary>
/// Called from X2AbilityTag:ExpandHandler after processing the base game tags. Return true (and fill OutString correctly)
/// to indicate the tag has been expanded properly and no further processing is needed.
/// </summary>
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	return false;
}

/// Start Issue #419
/// <summary>
/// Called from X2AbilityTag.ExpandHandler
/// Expands vanilla AbilityTagExpandHandler to allow reflection
/// </summary>
static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseOb, XComGameState GameState)
{
	return false;
}