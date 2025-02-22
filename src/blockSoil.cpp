#include "blockSoil.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void BLOCKSOIL::_bind_methods() {
}

BLOCKSOIL::BLOCKSOIL() {

    setTexture("res://items/blocks/natural/soil.png");

    itemToDrop = 35;
    rotateTextureToGravity = true;
    connectedTexture = true;
    connectTexturesToMe = true;
    breakParticleID = 3;
    soundMaterial = 1;

}


BLOCKSOIL::~BLOCKSOIL() {
}

Dictionary BLOCKSOIL::onTick(int x, int y, PLANETDATA *planet, int dir){
    
		Dictionary changes = {};


        if ( std::rand() % 100 == 0 ){
            for(int i = 0; i < 9; i++){

                Vector2i check = Vector2i( Vector2( i - 4,0 ).rotated(acos(0.0)*dir)  ) + Vector2i(x,y);

                if(abs(planet->getWaterData(check.x,check.y)) > 0.1 ){

                    return changes;

                }

            }

            Vector2i below = Vector2i( Vector2( 0,1 ).rotated(acos(0.0)*dir)  ) + Vector2i(x,y);
            if(abs(planet->getWaterData(below.x,below.y)) > 0.1 ){

                return changes;

            }

            Vector2i above = Vector2i( Vector2( 0,-1 ).rotated(acos(0.0)*dir)  ) + Vector2i(x,y);
            if(abs(planet->getWaterData(above.x,above.y)) > 0.1 ){

                return changes;

            }


            changes[ Vector2i(x,y) ] = 36;// replace with dry soil if no water around
        }
        
		return changes;

	}