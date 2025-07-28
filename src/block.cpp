#include "block.h"
#include "lookupBlock.h"
#include <godot_cpp/core/class_db.hpp>

#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void BLOCK::_bind_methods() {
}

BLOCK::BLOCK() {
    //Default Variables
    blockID = -1;

    setTexture("res://items/error.png");

    rotateTextureToGravity = false;
    connectedTexture = false;
    connectTexturesToMe = true;
    connectToSelfOnly = false;

    hasCollision = true;

    lightMultiplier = 0.6;
    lightEmmission = 0.0;

    // -1 drops nothing
    itemToDrop = -1;

    // -1 = particles match texture
    breakParticleID = -1;

    // in seconds
    breakTime = 0.5;

    multitile = false;
    animated = false;

    isTransparent = false;

    miningLevel = 0; // 0 is always mineable, 1 is copper tools, 2 is gold tools, 3 is iron tools...
    soundMaterial = 0; // stone, dirt, wood, sand, cloth, leaves, glass

    natural = false; // used to block spawns when used as wall, natural true means spawns are allowed
    
    backgroundColorImmune = false; // setting to true means the wall won't be dyed by wall shader

    setNewVariables();

}

BLOCK::~BLOCK() {
}

void BLOCK::setNewVariables(){
}

void BLOCK::setTexture( const char* file ) {
    if(ResourceLoader::get_singleton()->exists(file)){
        texture = ResourceLoader::get_singleton()->load(file);

        texImage = texture->get_image();
        texImage->convert(Image::FORMAT_RGBA8);
    }

}

Dictionary BLOCK::onTick(int x, int y, PLANETDATA *planet, int dir){
    Dictionary changes = {};
    return changes;
}

Dictionary BLOCK::onBreak(int x, int y, PLANETDATA *planet, int dir){
    Dictionary changes = {};
    return changes;
}

Dictionary BLOCK::onEnergize(int x, int y, PLANETDATA *planet, int dir){
    Dictionary changes = {};
    return changes;
}

Dictionary BLOCK::onLoad(int x, int y, PLANETDATA *planet, int dir){
    Dictionary changes = {};
    return changes;
}

void BLOCK::setLookUp(LOOKUPBLOCK *g){
    lookup = g;

}
