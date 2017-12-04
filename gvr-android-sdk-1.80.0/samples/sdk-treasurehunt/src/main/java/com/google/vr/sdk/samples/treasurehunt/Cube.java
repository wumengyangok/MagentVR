package com.google.vr.sdk.samples.treasurehunt;

import com.google.vr.sdk.base.GvrActivity;
import com.google.vr.sdk.base.GvrView;

/**
 * Created by wumengyang on 24/11/2017.
 */

public class Cube extends GvrActivity {
    public int cubeId = 0;
    public float[] modelCube;
    public float[] modelPosition;
    public int cubeProgram = 0;
    public boolean alive = true;
    public int positionX = 0;
    public int positionY = 0;
    public boolean attacker = false;
    public boolean observer = false;


    public int cubePositionParam = 0;
    public int cubeNormalParam = 0;
    public int cubeColorParam = 0;
    public int cubeModelParam = 0;
    public int cubeModelViewParam = 0;
    public int cubeModelViewProjectionParam = 0;
    public int cubeLightPosParam = 0;

}