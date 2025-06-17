#include "lookupBlock.h"

#include "block.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void LOOKUPBLOCK::_bind_methods() {
    ClassDB::bind_method(D_METHOD("getBlockData","id"), &LOOKUPBLOCK::getBlockData);

    ClassDB::bind_method(D_METHOD("isMultitile","id"), &LOOKUPBLOCK::isMultitile);
    ClassDB::bind_method(D_METHOD("isAnimated","id"), &LOOKUPBLOCK::isMultitile);
    ClassDB::bind_method(D_METHOD("hasCollision","id"), &LOOKUPBLOCK::hasCollision);
    ClassDB::bind_method(D_METHOD("isGravityRotate","id"), &LOOKUPBLOCK::isGravityRotate);
    ClassDB::bind_method(D_METHOD("getTextureImage","id"), &LOOKUPBLOCK::getTextureImage);
    ClassDB::bind_method(D_METHOD("getMiningLevel","id"), &LOOKUPBLOCK::getMiningLevel);

    ClassDB::bind_method(D_METHOD("runOnLoad","x","y","planet","dir","blockID"), &LOOKUPBLOCK::runOnLoad);
}

// ADD BLOCKS TO ARRAY IN HERE
LOOKUPBLOCK::LOOKUPBLOCK() {
    
    penis[0] = new BLOCKAIR();
    penis[1] = new BLOCKCAVEAIR();
    penis[2] = new BLOCKSTONE();
    penis[3] = new BLOCKDIRT();
    penis[4] = new BLOCKGRASS();
    penis[5] = new BLOCKCORE();
    penis[6] = new BLOCKPLASMA();
    penis[7] = new BLOCKSAPLING();
    penis[8] = new BLOCKTREELOG();
    penis[9] = new BLOCKLEAVES();
    penis[10] = new BLOCKTREEBRANCHLEFT();
    penis[11] = new BLOCKTREEBRANCHRIGHT();
    penis[12] = new BLOCKTREEBRANCHLEAF();
    penis[13] = new BLOCKWOOD();
    penis[14] = new BLOCKSAND();
    penis[15] = new BLOCKTORCH();
    penis[16] = new BLOCKFURNACE();
    penis[17] = new BLOCKTALLGRASS();
    penis[18] = new BLOCKORECOPPER();
    penis[19] = new BLOCKCHAIR();
    penis[20] = new BLOCKWORKBENCH();
    penis[21] = new BLOCKGLASS();
    penis[22] = new BLOCKDOORCLOSED();
    penis[23] = new BLOCKDOOROPEN();
    penis[24] = new BLOCKOREGOLD();
    penis[25] = new BLOCKLADDER();
    penis[26] = new BLOCKFLOWER();
    penis[27] = new BLOCKOREIRON();
    penis[28] = new BLOCKGRAVEL();
    penis[29] = new BLOCKBARCOPPER();
    penis[30] = new BLOCKBARGOLD();
    penis[31] = new BLOCKBARIRON();
    penis[32] = new BLOCKSTONEBRICK();
    penis[33] = new BLOCKCHEST();
    penis[34] = new BLOCKCHESTLOOT();
    penis[35] = new BLOCKSOIL();
    penis[36] = new BLOCKSOILDRY();
    penis[37] = new BLOCKCROPPOTATO();
    penis[38] = new BLOCKCROPPOTATONATURAL();
    
    penis[39] = new BLOCKPAINTSTAGPLUMP(); // paintings batch 1
    penis[40] = new BLOCKPAINTSTAGMARSH();
    penis[41] = new BLOCKPAINTSTAGCUP();
    penis[42] = new BLOCKPAINTSTAGDAWN();
    penis[43] = new BLOCKPAINTGAHAXA();
    penis[44] = new BLOCKPAINTGAHFINE();
    penis[45] = new BLOCKPAINTGAHLUL();

    penis[46] = new BLOCKGRILL();
    penis[47] = new BLOCKTRAPDOORCLOSED();
    penis[48] = new BLOCKTRAPDOOROPEN();
    
    penis[49] = new BLOCKPAINTLYNSMILE(); // paintings batch 2
    penis[50] = new BLOCKPAINTLYNWORN();
    penis[51] = new BLOCKPAINTLYNFISH();

    penis[52] = new BLOCKSTALACTITE();
    penis[53] = new BLOCKWOOL();
    penis[54] = new BLOCKSTRUCTURE();
    penis[55] = new BLOCKBED();
    penis[56] = new BLOCKSUNFLOWERSTEM();
    penis[57] = new BLOCKSUNFLOWERTOP();
    penis[58] = new BLOCKSUNFLOWERLEAF();
    penis[59] = new BLOCKSUNFLOWERSMALL();
    penis[60] = new BLOCKSUNFLOWERSAPLING();
    penis[61] = new BLOCKPAPER();
    penis[62] = new BLOCKLETTER();
    penis[63] = new BLOCKBOSSSHIPPILLAR();
    penis[64] = new BLOCKVANITYPRESENT();
    penis[65] = new BLOCKBROWNBRICK();

    penis[66] = new BLOCKPAINTTILTROKIWI(); // paintings batch 3
    penis[67] = new BLOCKPAINTCALVINNIGHTMARE();
    penis[68] = new BLOCKPAINTCALVINSUNRISE();
    penis[69] = new BLOCKPAINTOCTOSPIRAL();
    penis[70] = new BLOCKPAINTKAIAGHOSTS();
    penis[71] = new BLOCKPAINTKAIACREATURE();
    penis[72] = new BLOCKPAINTKAIAWASHED();
    
    penis[73] = new BLOCKJARFIREFLY();
    penis[74] = new BLOCKMOSS();
    penis[75] = new BLOCKMOSSVINE();
    penis[76] = new BLOCKMOSSORB();
    penis[77] = new BLOCKMOSSGRASS();
    penis[78] = new BLOCKMAGICINFUSER();
    penis[79] = new BLOCKLADDERPACK();
    penis[80] = new BLOCKCALCITE();
    penis[81] = new BLOCKAMECRYSTAL();
    penis[82] = new BLOCKCOREGRASS();
    penis[83] = new BLOCKCROPWHEAT();
    penis[84] = new BLOCKSANDSTONE();
    penis[85] = new BLOCKSNOW();
    penis[86] = new BLOCKICE();
    penis[87] = new BLOCKCACTUS();
    penis[88] = new BLOCKCLAY();
    penis[89] = new BLOCKBRICK();
    penis[90] = new BLOCKSEAGRASS();
    penis[91] = new BLOCKWIRE();
    penis[92] = new BLOCKTELEPORTER();
    penis[93] = new BLOCKWIREHIDDEN();
    penis[94] = new BLOCKSOLDERINGIRON();
    penis[95] = new BLOCKLAMPON();
    penis[96] = new BLOCKLAMPOFF();
    penis[97] = new BLOCKLEVER();
    penis[98] = new BLOCKOBSERVER();
    penis[99] = new BLOCKCLOCK();
    penis[100] = new BLOCKREPEATER();
    penis[101] = new BLOCKDRILL();
    penis[102] = new BLOCKSPITTER();
    penis[103] = new BLOCKEXTENDER();
    penis[104] = new BLOCKPLACER();
    penis[105] = new BLOCKCONVEYORRIGHT();
    penis[106] = new BLOCKCONVEYORLEFT();
    penis[107] = new BLOCKHOPPER();
    penis[108] = new BLOCKICEICLE();
    penis[109] = new BLOCKSNOWBRICK();
    penis[110] = new BLOCKPINESAPLING();
    penis[111] = new BLOCKPINELEAVES();
    penis[112] = new BLOCKPINESOLIDLEAF();
    penis[113] = new BLOCKOREFIBER();
    penis[114] = new BLOCKMARBLE();
    penis[115] = new BLOCKMARBLEBRICK();
    penis[116] = new BLOCKMARBLEPILLAR();
    penis[117] = new BLOCKCAMPFIRE();
    penis[118] = new BLOCKSTONEMOSSY();
    penis[119] = new BLOCKROCKDEBRIS();
    penis[120] = new BLOCKSHELF();
    penis[121] = new BLOCKBOOK();
    penis[122] = new BLOCKTABLE();
    penis[123] = new BLOCKFLOWERPOT();
    penis[124] = new BLOCKCHAIN();
    penis[125] = new BLOCKLANTERN();
    penis[126] = new BLOCKGRANDFATHERCLOCK();
    penis[127] = new BLOCKWINDCHIME();
    penis[128] = new BLOCKOREFOSSIL();
    penis[129] = new BLOCKTRINKETSTATION();
    penis[130] = new BLOCKTROPHY();
    penis[131] = new BLOCKGRASSDESERT();
    penis[132] = new BLOCKPINKTREELOG();
    penis[133] = new BLOCKPINKTREELEAVES();
    penis[134] = new BLOCKPINKTREEFLOWERING();
    penis[135] = new BLOCKPINKTREESAPLING();
    penis[136] = new BLOCKPINKWOOD();
    penis[137] = new BLOCKSANDSTONEBRICK();
    penis[138] = new BLOCKSANDSTONEEYE();
    penis[139] = new BLOCKSHOPCOMPUTER();
    penis[140] = new BLOCKSHOPCOMPUTERON();
    penis[141] = new BLOCKBLACKSTONE();
    penis[142] = new BLOCKSHINGLE();
    penis[143] = new BLOCKWALLPAPERBLUE();
    penis[144] = new BLOCKWALLPAPERGREEN();
    penis[145] = new BLOCKWALLPAPERYELLOW();
    penis[146] = new BLOCKWALLPAPERGMA();
    penis[147] = new BLOCKMINIBOSSSPAWNER();
    penis[148] = new BLOCKCROPLETTUCE();
    penis[149] = new BLOCKBRICKCACTUS();
    penis[150] = new BLOCKBRICKSUNFLOWER();
    penis[151] = new BLOCKOREGOLDDESERT();
    penis[152] = new BLOCKINFOSCANNER();
    penis[153] = new BLOCKTRAPFIREBALL();
    
    penis[154] = new BLOCKPAINTEELWORKOUTGUY(); // painting batch 4
    penis[155] = new BLOCKPAINTORKPILL();
    penis[156] = new BLOCKPAINTORKTRIBUTE();
    penis[157] = new BLOCKPAINTSTAGJOURNEY();
    penis[158] = new BLOCKPAINTSTAGFISH();
    penis[159] = new BLOCKPAINTSTAGSEEN();

    penis[160] = new BLOCKNUMBERSCANNER();
    penis[161] = new BLOCKSUCKER();
    penis[162] = new BLOCKITEMFRAME();
    penis[163] = new BLOCKTABLEPINK();
    penis[164] = new BLOCKLEAVESSTATIC();
    penis[165] = new BLOCKLEAVESSTATICPINE();
    penis[166] = new BLOCKRUBBER();
    penis[167] = new BLOCKARMORSTAND();
    penis[168] = new BLOCKPINWHEEL();

    for(BLOCK *i : penis){ // i increase automatically !
        i->setLookUp(this);
    }
}

LOOKUPBLOCK::~LOOKUPBLOCK() {
}

Dictionary LOOKUPBLOCK::getBlockData(int id){
    Dictionary data ={};

    BLOCK* g = penis[id];
    data["texture"] = g->texture;
    data["rotateTextureToGravity"] = g->rotateTextureToGravity;
    data["connectTexturesToMe"] = g->connectTexturesToMe;
    data["connectedTexture"] = g->connectedTexture;
    data["hasCollision"] = g->hasCollision;
    data["itemToDrop"] = g->itemToDrop;
    data["breakParticleID"] = g->breakParticleID;
    data["breakTime"]= g->breakTime;
    data["lightMultiplier"] = g->lightMultiplier;
    data["lightEmmission"] = g->lightEmmission;
    data["multitile"] = g->multitile;
    data["animated"] = g->animated;
    data["miningLevel"] = g->miningLevel;
    data["soundMaterial"] = g->soundMaterial;
    data["natural"] = g->natural;
    data["bgimmune"] = g->backgroundColorImmune;

    return data;
}

bool LOOKUPBLOCK::hasCollision(int id){
    BLOCK* g = penis[id];

    return g->hasCollision;
}

bool LOOKUPBLOCK::isGravityRotate(int id){
    BLOCK* g = penis[id];

    return g->rotateTextureToGravity;
}

bool LOOKUPBLOCK::isConnectedTexture(int id){
    BLOCK* g = penis[id];

    return g->connectedTexture;
}

Ref<Image> LOOKUPBLOCK::getTextureImage(int id){
    BLOCK* g = penis[id];

    return g->texImage;
}


bool LOOKUPBLOCK::isTextureConnector(int id){
    BLOCK* g = penis[id];

    return g->connectTexturesToMe;
}

bool LOOKUPBLOCK::isMultitile(int id){
    BLOCK* g = penis[id];

    return g->multitile;
}

bool LOOKUPBLOCK::isAnimated(int id){
    BLOCK* g = penis[id];

    return g->animated;
}

double LOOKUPBLOCK::getLightMultiplier(int id){
    BLOCK* g = penis[id];

    return g->lightMultiplier;
}

double LOOKUPBLOCK::getLightEmmission(int id){
    BLOCK* g = penis[id];

    return g->lightEmmission;
}

bool LOOKUPBLOCK::isTransparent(int id){
    BLOCK* g = penis[id];

    return g->isTransparent;
}

int LOOKUPBLOCK::getMiningLevel(int id){
    BLOCK* g = penis[id];

    return g->miningLevel;
}

bool LOOKUPBLOCK::isBGImmune(int id){
    BLOCK* g = penis[id];

    return g->backgroundColorImmune;
}

bool LOOKUPBLOCK::isOnlyConnectToSelf(int id){
    BLOCK* g = penis[id];

    return g->connectToSelfOnly;
}

Dictionary LOOKUPBLOCK::runOnTick(int x, int y, PLANETDATA *planet, int dir, int blockID){
   
    return penis[blockID]->onTick(x,y,planet,dir);

}

Dictionary LOOKUPBLOCK::runOnBreak(int x, int y, PLANETDATA *planet, int dir, int blockID){
   
    return penis[blockID]->onBreak(x,y,planet,dir);

}

Dictionary LOOKUPBLOCK::runOnEnergize(int x, int y, PLANETDATA *planet, int dir, int blockID){
   
    return penis[blockID]->onEnergize(x,y,planet,dir);

}

Dictionary LOOKUPBLOCK::runOnLoad(int x, int y, PLANETDATA *planet, int dir, int blockID){
   
    return penis[blockID]->onLoad(x,y,planet,dir);

}

