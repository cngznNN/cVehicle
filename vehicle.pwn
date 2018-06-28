#include <a_samp>
#include <sscanf2>
#include <a_mysql>
#include <YSI\y_va>
#include <smartcmd>
#define FILTERSCRIPTS

//==================== MySQL Information =======================//
new MySQL:vHandle; // vHandle 'CTRL + H' ile arama bölümüne yazýp istediðiniz þekilde replace edebilirsiniz.

#define SQL_HOST "127.0.0.1"
#define SQL_USER "root"
#define SQL_PASS ""
#define SQL_DB "vehicles"

#define handle MYSQL_DEFAULT_HANDLE
//========================================================//

stock SendClientMessageEx(playerid, Color, const text[], va_args<>)
{
	new out[256];
	va_format(out, sizeof(out), text, va_start<3>);
	return SendClientMessage(playerid, Color, out);
}

#if defined _ALS_SendClientMessage
	#undef SendClientMessage
#else
	#define _ALS_SendClientMessage
#endif

#define SendClientMessage SendClientMessageEx


#if !defined this
	#define this:%0(%1) forward %0(%1); public %0(%1)
#else
	#undef this
#endif

//=================================================================

#define ConfirmDestroyVehicle 1 // Dialog ID deðiþtirebilirsiniz.

#define MAX_DYNAMIC_VEHICLES MAX_VEHICLES

enum E_VEHICLES {
	vehicleID,
	vehicleExists,
	vehicleModel,
	vehicleColor[2],
	vehicleOwner[24],
	vehicleLock,
	vehicleComponent[14],
	vehiclePaintJob,
	vehicleObject,
	Float:vehiclePos[4],
	vehicleInterior,
	vehicleVirtual
};

new VehicleData[MAX_DYNAMIC_VEHICLES][E_VEHICLES];

native IsValidVehicle(vehicleid);

new VehicleNames[][] =
{
    "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel",
	"Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
	"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam",
    "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection",
	"Hunter", "Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus",
	"Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie",
	"Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral",
	"Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder",
	"Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair", "Berkley's RC Van",
	"Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale",
	"Oceanic","Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy",
	"Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX",
	"Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper",
	"Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking",
	"Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin",
	"Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT",
	"Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stunt",
 	"Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra",
 	"FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune",
 	"Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer",
 	"Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent",
    "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo",
	"Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite",
	"Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratium",
	"Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito",
    "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune", "Sweeper",
	"Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400",
	"News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
	"Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car",
 	"Police Car", "Police Car", "Police Ranger", "Picador", "S.W.A.T", "Alpha",
 	"Phoenix", "Glendale", "Sadler", "Luggage", "Luggage", "Stairs", "Boxville",
 	"Tiller", "Utility Trailer"
};

stock GetVehicleName(vehicleid)
{
	new string[128];
	format(string,sizeof(string),"%s",VehicleNames[GetVehicleModel(vehicleid) - 400]);
	return string;
}

stock Save_Vehicle(vehicleid)
{
	new query[1024];
	
	format(query, sizeof(query), "update cvehicle set vehicleExists = '%d', vehicleModel = '%d', vehicleColor1 = '%d', vehicleColor2 = '%d', vehicleOwner = '%s', vehicleLock = '%d',\
	vehiclePaintJob = '%d', vehicleInterior = '%d', vehicleVirtual = '%d'",
	VehicleData[vehicleid][vehicleExists],VehicleData[vehicleid][vehicleModel],VehicleData[vehicleid][vehicleColor][0],
	VehicleData[vehicleid][vehicleColor][1],VehicleData[vehicleid][vehicleOwner],VehicleData[vehicleid][vehicleLock],
	VehicleData[vehicleid][vehiclePaintJob], VehicleData[vehicleid][vehicleInterior],VehicleData[vehicleid][vehicleVirtual]);
	
	format(query, sizeof(query), "%s, vehiclePos = '%f|%f|%f|%f'", query, VehicleData[vehicleid][vehiclePos][0],VehicleData[vehicleid][vehiclePos][1],
	VehicleData[vehicleid][vehiclePos][2],VehicleData[vehicleid][vehiclePos][3]);
	
	format(query, sizeof(query), "%s, vehicleComponent = '%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d'", query,
	VehicleData[vehicleid][vehicleComponent][0], VehicleData[vehicleid][vehicleComponent][1], VehicleData[vehicleid][vehicleComponent][2]
	, VehicleData[vehicleid][vehicleComponent][3], VehicleData[vehicleid][vehicleComponent][4], VehicleData[vehicleid][vehicleComponent][5], VehicleData[vehicleid][vehicleComponent][6]
	, VehicleData[vehicleid][vehicleComponent][7], VehicleData[vehicleid][vehicleComponent][8], VehicleData[vehicleid][vehicleComponent][9], VehicleData[vehicleid][vehicleComponent][10]
	, VehicleData[vehicleid][vehicleComponent][11], VehicleData[vehicleid][vehicleComponent][12], VehicleData[vehicleid][vehicleComponent][13]);
	
	format(query, sizeof(query), "%s where vehicleID = '%d'", query, VehicleData[vehicleid][vehicleID]);
	
	return mysql_tquery(handle, query);
}

forward Load_Vehicle();
public Load_Vehicle()
{
	new rows;
	cache_get_row_count(rows);
	
	for(new i = 0; i < rows; i++)
	{
		new
			string[256];
			
		VehicleData[i][vehicleID] = cache_get_field_content_int(i, "vehicleID");
		VehicleData[i][vehicleExists] = cache_get_field_content_int(i, "vehicleExists");
		VehicleData[i][vehicleModel] = cache_get_field_content_int(i, "vehicleModel");
		VehicleData[i][vehicleColor][0] = cache_get_field_content_int(i, "vehicleColor1");
		VehicleData[i][vehicleColor][1] = cache_get_field_content_int(i, "vehicleColor2");
		VehicleData[i][vehicleLock] = cache_get_field_content_int(i, "vehicleLock");
		VehicleData[i][vehiclePaintJob] = cache_get_field_content_int(i, "vehiclePaintJob");
		VehicleData[i][vehicleInterior] = cache_get_field_content_int(i, "vehicleInterior");
		VehicleData[i][vehicleVirtual] = cache_get_field_content_int(i, "vehicleVirtual");
		
		cache_get_field_content(i, "vehiclePos", string, 64);
		sscanf(string, "p<|>ffff", VehicleData[i][vehiclePos][0], VehicleData[i][vehiclePos][1], VehicleData[i][vehiclePos][2],VehicleData[i][vehiclePos][3]);
		
		cache_get_field_content(i, "vehicleOwner", VehicleData[i][vehicleOwner], 24);

		cache_get_field_content(i, "vehicleComponent", string, 128);
		sscanf(string, "p<|>dddddddddddddd",  VehicleData[i][vehicleComponent][0], VehicleData[i][vehicleComponent][1], VehicleData[i][vehicleComponent][2]
		, VehicleData[i][vehicleComponent][3], VehicleData[i][vehicleComponent][4], VehicleData[i][vehicleComponent][5], VehicleData[i][vehicleComponent][6]
		, VehicleData[i][vehicleComponent][7], VehicleData[i][vehicleComponent][8], VehicleData[i][vehicleComponent][9], VehicleData[i][vehicleComponent][10]
		, VehicleData[i][vehicleComponent][11], VehicleData[i][vehicleComponent][12], VehicleData[i][vehicleComponent][13]);
		
		if(i != MAX_VEHICLES)
		{
			VehicleData[i][vehicleObject] = CreateVehicle(VehicleData[i][vehicleModel], VehicleData[i][vehiclePos][0], 
			VehicleData[i][vehiclePos][1], VehicleData[i][vehiclePos][2], VehicleData[i][vehiclePos][3],
			VehicleData[i][vehicleColor][0], VehicleData[i][vehicleColor][1], -1);
			ChangeVehiclePaintjob(VehicleData[i][vehicleObject], VehicleData[i][vehiclePaintJob]);
			for(new j = 0; j < 14; j++) if(VehicleData[i][vehicleComponent][j] != 0) AddVehicleComponent(VehicleData[i][vehicleObject], VehicleData[i][vehicleComponent][j]);
		}
		else print("Sunucu maksimum araç sýnýrýna ulaþtý.");
		
	}
	return 1;
}

stock Car_GetID(vehicleid)
{
	for(new i = 0; i < MAX_DYNAMIC_VEHICLES; i++) if(VehicleData[i][vehicleExists])
	{
		if(VehicleData[i][vehicleObject] == vehicleid)
			return i;
	}
	return -1;
}

stock Car_Spawn(i)
{
	new vehicleid = Car_GetID(i);
	if(i == INVALID_VEHICLE_ID)
		return 0;
		
    if(IsValidVehicle(i))
		DestroyVehicle(i);

	VehicleData[vehicleid][vehicleObject] = CreateVehicle(VehicleData[vehicleid][vehicleModel], VehicleData[vehicleid][vehiclePos][0], 
	VehicleData[vehicleid][vehiclePos][1], VehicleData[vehicleid][vehiclePos][2], VehicleData[vehicleid][vehiclePos][3],
	VehicleData[vehicleid][vehicleColor][0], VehicleData[vehicleid][vehicleColor][1], -1);
	ChangeVehiclePaintjob(VehicleData[vehicleid][vehicleObject], VehicleData[vehicleid][vehiclePaintJob]);
	for(new j = 0; j < 14; j++) if(VehicleData[vehicleid][vehicleComponent][j] != 0) AddVehicleComponent(vehicleid, VehicleData[vehicleid][vehicleComponent][j]);
	
	return 1;
}


#if defined FILTERSCRIPTS

public OnFilterScriptInit()
{
	vHandle = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_DB);
	if(mysql_errno(vHandle) != 0)
	{
		printf("cVehicle FS Loading...");
		printf("[%s] Sunucu MySQL/veritabani ile baglanti kuramadi!",ReturnDateEx());
		mysql_close(MYSQL_DEFAULT_HANDLE);
		SendRconCommand("exit");
	}
	else
	{
		printf("Code by: cngznNN");
		printf("Sunucu MySQL ile baglanti kurdu!");
		CheckVehicleTable();
		mysql_pquery(handle, "select * from cvehicle", "Load_Vehicle");
	}
	return 1;
}

CheckVehicleTable()
{
	new string[1024];
	format(string, sizeof(string), "create table if not exists cvehicle(\
	vehicleID INT(12) NOT NULL PRIMARY KEY AUTO_INCREMENT,\
	vehicleExists INT(1) DEFAULT 0,\
	vehicleModel INT(3) DEFAULT 560,\
	vehicleColor1 INT(3) DEFAULT 0,\
	vehicleColor2 INT(3) DEFAULT 0,\
	vehicleOwner VARCHAR(24) DEFAULT 'Yok',\
	vehicleLock INT(1) DEFAULT 0,\
	vehicleComponent VARCHAR(128) DEFAULT '0|0|0|0|0|0|0|0|0|0|0|0|0',\
	vehiclePaintJob INT(1) DEFAULT 0,\
	vehiclePos VARCHAR(64) DEFAULT '0|0|0|0',\
	vehicleInterior INT(12) DEFAULT '0',\
	vehicleVirtual INT(12) DEFAULT '0'\
	)\
	Engine = InnoDB");
	
	return mysql_tquery(handle, string);
}

public OnFilterScriptExit()
{
	mysql_close(handle);
	return 1;
}

#endif



stock Create_Vehicle(Float:x, Float:y, Float:z, &model=560, &color1=0, &color2=0, &paintjob=0, &interior=0, &virtual=0)
{
	for(new i = 0; i < MAX_DYNAMIC_VEHICLES; i++) if(!VehicleData[i][vehicleExists])
	{
		VehicleData[i][vehicleExists] = 1;
		VehicleData[i][vehicleModel] = model;
		VehicleData[i][vehicleColor][0] = color1;
		VehicleData[i][vehicleColor][1] = color2;
		VehicleData[i][vehicleLock] = 0;
		VehicleData[i][vehiclePaintJob] = paintjob;
		VehicleData[i][vehicleInterior] = interior;
		VehicleData[i][vehicleVirtual] = virtual;
		format(VehicleData[i][vehicleOwner], 24, "Yok");
		for(new j = 0; j < 14; j++) VehicleData[i][vehicleComponent][j] = 0;
		VehicleData[i][vehiclePos][0] = x;
		VehicleData[i][vehiclePos][1] = y;
		VehicleData[i][vehiclePos][2] = z;
		VehicleData[i][vehiclePos][3] = 0;
		mysql_tquery(handle, "insert into cvehicle(vehicleExists) VALUES(1)", "OnVehicleCreate", "d", i);
		return i;
	}
	return INVALID_VEHICLE_ID;
}

this:OnVehicleCreate(vehicleid)
{
	VehicleData[vehicleid][vehicleID] = cache_insert_id();
	VehicleData[vehicleid][vehicleObject] = CreateVehicle(VehicleData[vehicleid][vehicleModel], VehicleData[vehicleid][vehiclePos][0], 
	VehicleData[vehicleid][vehiclePos][1], VehicleData[vehicleid][vehiclePos][2], VehicleData[vehicleid][vehiclePos][3],
	VehicleData[vehicleid][vehicleColor][0], VehicleData[vehicleid][vehicleColor][1], -1);
	ChangeVehiclePaintjob(VehicleData[vehicleid][vehicleObject], VehicleData[vehicleid][vehiclePaintJob]);
	Save_Vehicle(vehicleid);
	return 1;
}

ReturnDateEx()
{
	new hour, minute, second, day, month, year, monthString[32], string[128];
	getdate(year, month, day);
	gettime(hour, minute, second);

	switch(month)
	{
		case 1: monthString = "Ocak";
		case 2: monthString = "Subat";
		case 3: monthString = "Mart";
		case 4: monthString = "Nisan";
		case 5: monthString = "Mayis";
		case 6: monthString = "Haziran";
		case 7: monthString = "Temmuz";
		case 8: monthString = "Agustos";
		case 9: monthString = "Eylul";
		case 10: monthString = "Ekim";
		case 11: monthString = "Kasim";
		case 12: monthString = "Aralik";
	}
	format(string, sizeof(string), "%d %s/%d - %02d:%02d:%02d", day, monthString, year, hour, minute, second);
	return string;
}

CMD:aracyarat(cmdid, playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendClientMessage(playerid, -1, "{FF0000}Hata: {FFFFFF}bu komutu kullanmak için rcon giriþi yapmalýsýnýz.");

	new
		model,
		color1,
		color2,
		paintjob,
		interior,
		virtual,
		Float:x,
		Float:y,
		Float:z,
		id = INVALID_VEHICLE_ID;
		
	if(sscanf(params, "dI(0)I(0)I(0)I(0)I(0)", model, color1, color2, paintjob, interior, virtual))
		return SendClientMessage(playerid, -1, "KULLANIM: /aracyarat [Model 411-611] [&Renk 1] [&Renk 2] [&Paintjob] [&Interior] [&Virtual]");
		
	if(model < 411 || model > 611)
		return SendClientMessage(playerid, -1, "{FF0000}Hata: {FFFFFF}model ID 411 ve 611 arasýnda olmalýdýr.");

	GetPlayerPos(playerid, x, y, z);	
	id = Create_Vehicle(x, y, z, model, color1, color2, paintjob, interior, virtual);
	
	if(id == INVALID_VEHICLE_ID)
		SendClientMessage(playerid, -1, "Sunucu maksimum araç yaratma sýnýrýna ulaþtý.");
	else
		SendClientMessage(playerid, -1, "%d ID'li araç yarattýnýz.",id);
	
	return 1;
}

CMD:aracsil(cmdid, playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendClientMessage(playerid, -1, "{FF0000}Hata: {FFFFFF}bu komutu kullanmak için rcon giriþi yapmalýsýnýz.");
	
	new
		id = INVALID_VEHICLE_ID;
	
	if((id = Nearest_Vehicle(playerid)) != INVALID_VEHICLE_ID)
	{
		new string[256];
		format(string, sizeof(string), "Araç ID: %d\tSQL ID: %d\n\n%s model aracý silmek istediðinize emin misiniz?",
		VehicleData[id][vehicleObject], id,GetVehicleName(VehicleData[id][vehicleObject]));
		ShowPlayerDialog(playerid, ConfirmDestroyVehicle, DIALOG_STYLE_MSGBOX, "Rcon - Araç", string, "Sil", "Çýk");
		SetPVarInt(playerid, "DialogDestroyVehicle", id);
	}
	else
	{
		if(sscanf(params, "d", id))
			return SendClientMessage(playerid, -1, "KULLANIM: /aracsil [Araç ID (/dl)]");
		
		new realid = Car_GetID(id);
		
		if(!VehicleData[realid][vehicleExists])
			return SendClientMessage(playerid, -1, "{FF0000}Hata: {FFFFFF}girdiðiniz ID'deki araç yaratýlmamýþ.");
		
		RemoveVehicleData(realid);
		
	}
	return 1;
}

Nearest_Vehicle(playerid, Float:radius=2.0)
{
	for(new i = 0; i < MAX_DYNAMIC_VEHICLES; i++) if(VehicleData[i][vehicleExists])
	{
		new Float:x, Float:y, Float:z;
		GetVehiclePos(VehicleData[i][vehicleObject], x, y, z);
		
		if(IsPlayerInRangeOfPoint(playerid, radius, x, y, z))
			return i;
	}
	return INVALID_VEHICLE_ID;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(IsValidPVar(playerid, "DialogDestroyVehicle")) DeletePVar(playerid, "DialogDestroyVehicle");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == ConfirmDestroyVehicle)
	{
		if(response)
		{
			new id = GetPVarInt(playerid, "DialogDestroyVehicle");
			RemoveVehicleData(id);
		}
		
		DeletePVar(playerid, "DialogDestroyVehicle");
		
		return 1;
	}
	
	return 0;
}

stock IsValidPVar(playerid, varname[])
	return (GetPVarType(playerid, varname) != PLAYER_VARTYPE_NONE);

RemoveVehicleData(i)
{
	VehicleData[i][vehicleExists] = 0;
	VehicleData[i][vehicleModel] = 560;
	VehicleData[i][vehicleColor][0] = 0;
	VehicleData[i][vehicleColor][1] = 0;
	VehicleData[i][vehicleLock] = 0;
	VehicleData[i][vehiclePaintJob] = 0;
	VehicleData[i][vehicleInterior] = 0;
	VehicleData[i][vehicleVirtual] = 0;
	format(VehicleData[i][vehicleOwner], 24, "Yok");
	for(new j = 0; j < 14; j++) VehicleData[i][vehicleComponent][j] = 0;
	VehicleData[i][vehiclePos][0] = 0;
	VehicleData[i][vehiclePos][1] = 0;
	VehicleData[i][vehiclePos][2] = 0;
	VehicleData[i][vehiclePos][3] = 0;
	DestroyVehicle(VehicleData[i][vehicleObject]);
	new string[128];
	format(string, sizeof(string), "delete from cvehicle where vehicleID = '%d'",VehicleData[i][vehicleID]);
	return mysql_tquery(handle, string);
}
