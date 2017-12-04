package com.google.vr.sdk.samples.treasurehunt;

import com.google.vr.sdk.base.GvrActivity;

/**
 * Created by wumengyang on 28/11/2017.
 */

public class Attack extends GvrActivity {
    public int cubeId;
    public int attackPositionX;
    public int attackPositionY;

    public Attack(int cubeId, int attackPositionX, int attackPositionY) {
        this.cubeId = cubeId;
        this.attackPositionX = attackPositionX;
        this.attackPositionY = attackPositionY;
    }
}
