/*
	File: fn_initPlayer.sqf
	Author: Grom -> https://github.com/a3r0id
	Usage: (postInit) GRRA_fnc_initPlayer;
*/

if (isServer && !hasInterface) exitWith {};

systemChat format ["GRRA: %1", "Initializing player"];

GRRA_USE_VANILLA_ARSENAL = false;

// hashmap of arsenal objects defined by classname
GRRA_CLASSES_MAP    = createhashmapfromarray[];

// hashmap of arsenal objects defined by variable
GRRA_VARS_MAP       = createhashmapfromarray[];

_fnc_createOrAddArsenal = {
	params ["_logicModule"];

	// get a copy of the global variable
	_items 				 = [_logicModule getVariable "Items"] call GRRA_fnc_strToArray;
	_classNameOrVariable = _logicModule getVariable "Owner";
	// default to GRRA_CLASSES_MAP as className usage will be more common, id assume...
	_globalVariable 	 = "GRRA_CLASSES_MAP";  

	if !(isNil _classNameOrVariable) then {
		_globalVariable = "GRRA_VARS_MAP";
	};

	_gVarCopy = missionNamespace getVariable _globalVariable;

	// check if the class/var name is already in the hashmap
	if (count (_gVarCopy getOrDefault [_classNameOrVariable, []]) == 0) then {
		// if not, add it as well as the items
		_gVarCopy set [_classNameOrVariable, _items];
	} else {
		// if it is, add the items to the existing array
		_gVarCopy set [_classNameOrVariable, (_gVarCopy get _classNameOrVariable) + _items];
	};	

	// Overwrite the global variable
	missionNamespace setVariable [_globalVariable, _gVarCopy];
};

{
	// check if the module is a BaseArsenal, and if the side matche the player's side
	if (typeOf _x == "GRRA_ModuleBaseArsenal") then {
		if !([_x getVariable "Side"] call GRRA_fnc_sidesMatch) then {continue};
		[_x] call _fnc_createOrAddArsenal;
	};

	// check if the module is a RoleRestrictedArsenal, and if the side and role match the player's side and role
	if (typeOf _x == "GRRA_ModuleRoleRestrictedArsenal") then {
		if !([_x getVariable "Role"] call GRRA_fnc_rolesMatch) then {continue};
		if !([_x getVariable "Side"] call GRRA_fnc_sidesMatch) then {continue};
		[_x] call _fnc_createOrAddArsenal;
	};

	// Check if the module is an AceArsenalOverride, and if so, set the global variable to true
	if (typeOf _x == "GRRA_AceArsenalOverride") then {
		GRRA_USE_VANILLA_ARSENAL = true;
	};
} forEach allMissionObjects "Logic";

// Arsenals to be initialized on a className
{
	[
		_x,
		"init",
		{   
			_thisClass = typeOf (_this select 0);
			//[_this select 0] call GRRA_fnc_cleanArsenalBox;
			if (GRRA_USE_VANILLA_ARSENAL) then {
				[_this select 0, GRRA_CLASSES_MAP get _thisClass] call GRRA_fnc_addItemsVanillaArsenal;
			} else {
				[_this select 0, GRRA_CLASSES_MAP get _thisClass, false] call ace_arsenal_fnc_initBox;
			};
		},
		true,
		[],
		true
	] call CBA_fnc_addClassEventHandler;
} forEach GRRA_CLASSES_MAP;

// Arsenals to be attached to a specific variable
{	
	_arsenalBox = missionNamespace getVariable _x;
	//[missionNamespace getVariable _x] call GRRA_fnc_cleanArsenalBox;
	if (GRRA_USE_VANILLA_ARSENAL) then {
		[_arsenalBox, GRRA_VARS_MAP get _x] call GRRA_fnc_addItemsVanillaArsenal;
	} else {
		[_arsenalBox, GRRA_VARS_MAP get _x, false] call ace_arsenal_fnc_initBox;
	};
} forEach GRRA_VARS_MAP;



