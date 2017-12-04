package com.google.vr.sdk.samples.treasurehunt;

import android.opengl.GLES20;
import android.opengl.Matrix;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;

import com.google.vr.sdk.audio.GvrAudioEngine;
import com.google.vr.sdk.base.AndroidCompat;
import com.google.vr.sdk.base.Eye;
import com.google.vr.sdk.base.GvrActivity;
import com.google.vr.sdk.base.GvrView;
import com.google.vr.sdk.base.HeadTransform;
import com.google.vr.sdk.base.Viewport;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.ArrayList;

import javax.microedition.khronos.egl.EGLConfig;

public class TreasureHuntActivity extends GvrActivity implements GvrView.StereoRenderer {

    private static final String TAG = "TreasureHuntActivity";
    private static final float Z_NEAR = 0.1f;
    private static final float Z_FAR = 100.0f;
    private static final float CAMERA_Z = 0.01f;
    private static final int COORDS_PER_VERTEX = 3;

    //  protected float[] modelCube;
//  protected float[] modelPosition;
    // We keep the light always position just above the user.
    private static final float[] LIGHT_POS_IN_WORLD_SPACE = new float[]{0.0f, 2.0f, 0.0f, 1.0f};
    private final float[] lightPosInEyeSpace = new float[4];
    /**
     * Find a new random position for the object.
     * <p>
     * <p>We'll rotate it around the Y-axis so it's out of sight, and then up or down by a little bit.
     */

    private Handler h = new Handler();
    private int delay = 1; //15 seconds
    Runnable runnable;
    private ArrayList<Cube> cubeList;
    //    private ArrayList<Frame> frameArrayList;
    private Frame[] frameArrayList;
    private int maxFrame = 65;
    private float height = -5.0f;
    private int agent = 2000;
    private FloatBuffer floorVertices;
    private FloatBuffer floorColors;
    private FloatBuffer floorNormals;
    private FloatBuffer cubeVertices;
    private FloatBuffer cubeColors;
    private FloatBuffer cubeAttackerColors;
    private FloatBuffer cubeObeserverColors;

    //  private Posi[] pList;
    private FloatBuffer cubeFoundColors;
    private FloatBuffer cubeNormals;
    private int floorProgram;
    private int floorPositionParam;
    private int floorNormalParam;
    private int floorColorParam;
    private int floorModelParam;
    private int floorModelViewParam;
    private int floorModelViewProjectionParam;
    private int floorLightPosParam;
    private float[] camera;
    private float[] view;
    private float[] headView;
    private float[] modelViewProjection;
    private float[] modelView;
    private float[] modelFloor;
    private float[] tempPosition;
    private float[] headRotation;
    private float floorDepth = 20f;
    private GvrAudioEngine gvrAudioEngine;
    private volatile int sourceId = GvrAudioEngine.INVALID_ID;
    /**
     * Called when the Cardboard trigger is pulled.
     */


    private int frameIndex = 0;
    private int frameIntervalIndex = 0;
    private int interval = 40;

    /**
     * Checks if we've had an error inside of OpenGL ES, and if so what that error is.
     *
     * @param label Label to report in case of error.
     */
    private static void checkGLError(String label) {
        int error;
        while ((error = GLES20.glGetError()) != GLES20.GL_NO_ERROR) {
            Log.e(TAG, label + ": glError " + error);
            throw new RuntimeException(label + ": glError " + error);
        }
    }

    /**
     * Converts a raw text file, saved as a resource, into an OpenGL ES shader.
     *
     * @param type  The type of shader we will be creating.
     * @param resId The resource ID of the raw text file about to be turned into a shader.
     * @return The shader object handler.
     */
    private int loadGLShader(int type, int resId) {
        String code = readRawTextFile(resId);
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, code);
        GLES20.glCompileShader(shader);

        // Get the compilation status.
        final int[] compileStatus = new int[1];
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0);

        // If the compilation failed, delete the shader.
        if (compileStatus[0] == 0) {
            Log.e(TAG, "Error compiling shader: " + GLES20.glGetShaderInfoLog(shader));
            GLES20.glDeleteShader(shader);
            shader = 0;
        }

        if (shader == 0) {
            throw new RuntimeException("Error creating shader.");
        }

        return shader;
    }

    /**
     * Sets the view to our GvrView and initializes the transformation matrices we will use
     * to render our scene.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {


        super.onCreate(savedInstanceState);

        initializeGvrView();

        frameArrayList = new Frame[maxFrame];
        camera = new float[16];
        view = new float[16];
        modelViewProjection = new float[16];
        modelView = new float[16];
        modelFloor = new float[16];
        tempPosition = new float[4];
        // Model first appears directly in front of user.
        cubeList = new ArrayList<>();

        int i = 0;
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(
                    new InputStreamReader(getAssets().open("video.txt")));
            String mLine;
            int index = 0;
            while ((mLine = reader.readLine()) != null && index < maxFrame) {
                String[] tokens = mLine.split(" ");
                if (index == 1 && tokens.length == 6) {
                    Cube newCube = new Cube();
                    newCube.cubeId = Integer.valueOf(tokens[0]);
                    newCube.attacker = (newCube.cubeId < 495);
                    newCube.positionX = Integer.valueOf(tokens[3]);
                    newCube.positionY = Integer.valueOf(tokens[4]);
                    newCube.modelPosition = new float[]{
                            Float.valueOf(tokens[3]), height, Float.valueOf(tokens[4])
                    };
                    newCube.modelCube = new float[16];
                    cubeList.add(newCube);
                    i++;
                }
                if (tokens[0].equals("F") && tokens.length == 4) {
                    frameArrayList[index] = new Frame();
                    index++;
                }
                if (tokens[0].equals("0") && tokens.length == 4) {
                    frameArrayList[index - 1].attackArrayList.add(new Attack(
                            Integer.valueOf(tokens[1]), Integer.valueOf(tokens[2]),
                            Integer.valueOf(tokens[3])
                    ));
                }
            }
            reader.close();
        } catch (IOException e) {
            Log.e("mytext", "read text failure");
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException e) {
                    Log.e("mytext", "read text failure");
                }
            }
        }
        cubeList.get(agent).observer = true;

        headRotation = new float[4];
        headView = new float[16];
        // Initialize 3D audio engine.
        gvrAudioEngine = new GvrAudioEngine(this, GvrAudioEngine.RenderingMode.BINAURAL_HIGH_QUALITY);
    }

    public void initializeGvrView() {
        setContentView(R.layout.common_ui);

        GvrView gvrView = (GvrView) findViewById(R.id.gvr_view);
        gvrView.setEGLConfigChooser(8, 8, 8, 8, 16, 8);

        gvrView.setRenderer(this);
        gvrView.setTransitionViewEnabled(true);

        // Enable Cardboard-trigger feedback with Daydream headsets. This is a simple way of supporting
        // Daydream controller input for basic interactions using the existing Cardboard trigger API.
        gvrView.enableCardboardTriggerEmulation();

        if (gvrView.setAsyncReprojectionEnabled(true)) {
            // Async reprojection decouples the app framerate from the display framerate,
            // allowing immersive interaction even at the throttled clockrates set by
            // sustained performance mode.
            AndroidCompat.setSustainedPerformanceMode(this, true);
        }

        setGvrView(gvrView);
    }

    @Override
    public void onRendererShutdown() {
        Log.i(TAG, "onRendererShutdown");
    }

    @Override
    public void onSurfaceChanged(int width, int height) {
        Log.i(TAG, "onSurfaceChanged");
    }

    /**
     * Creates the buffers we use to store information about the 3D world.
     * <p>
     * <p>OpenGL doesn't use Java arrays, but rather needs data in a format it can understand.
     * Hence we use ByteBuffers.
     *
     * @param config The EGL configuration used when creating the surface.
     */
    @Override
    public void onSurfaceCreated(EGLConfig config) {
        Log.i(TAG, "onSurfaceCreated");
        GLES20.glClearColor(0.1f, 0.1f, 0.1f, 0.5f); // Dark background so text shows up well.

        ByteBuffer bbVertices = ByteBuffer.allocateDirect(WorldLayoutData.CUBE_COORDS.length * 4);
        bbVertices.order(ByteOrder.nativeOrder());
        cubeVertices = bbVertices.asFloatBuffer();
        cubeVertices.put(WorldLayoutData.CUBE_COORDS);
        cubeVertices.position(0);

        ByteBuffer bbColors = ByteBuffer.allocateDirect(WorldLayoutData.CUBE_COLORS.length * 4);
        bbColors.order(ByteOrder.nativeOrder());
        cubeColors = bbColors.asFloatBuffer();
        cubeColors.put(WorldLayoutData.CUBE_COLORS);
        cubeColors.position(0);

        bbColors = ByteBuffer.allocateDirect(WorldLayoutData.CUBE_COLORS.length * 4);
        bbColors.order(ByteOrder.nativeOrder());
        cubeAttackerColors = bbColors.asFloatBuffer();
        cubeAttackerColors.put(WorldLayoutData.CUBE_FOUND_COLORS);
        cubeAttackerColors.position(0);

        bbColors = ByteBuffer.allocateDirect(WorldLayoutData.CUBE_COLORS.length * 4);
        bbColors.order(ByteOrder.nativeOrder());
        cubeObeserverColors = bbColors.asFloatBuffer();
        cubeObeserverColors.put(WorldLayoutData.CUBE_OBSERVER);
        cubeObeserverColors.position(0);

        ByteBuffer bbFoundColors =
                ByteBuffer.allocateDirect(WorldLayoutData.CUBE_FOUND_COLORS.length * 4);
        bbFoundColors.order(ByteOrder.nativeOrder());
        cubeFoundColors = bbFoundColors.asFloatBuffer();
        cubeFoundColors.put(WorldLayoutData.CUBE_FOUND_COLORS);
        cubeFoundColors.position(0);

        ByteBuffer bbNormals = ByteBuffer.allocateDirect(WorldLayoutData.CUBE_NORMALS.length * 4);
        bbNormals.order(ByteOrder.nativeOrder());
        cubeNormals = bbNormals.asFloatBuffer();
        cubeNormals.put(WorldLayoutData.CUBE_NORMALS);
        cubeNormals.position(0);

        // make a floor
        ByteBuffer bbFloorVertices = ByteBuffer.allocateDirect(WorldLayoutData.FLOOR_COORDS.length * 4);
        bbFloorVertices.order(ByteOrder.nativeOrder());
        floorVertices = bbFloorVertices.asFloatBuffer();
        floorVertices.put(WorldLayoutData.FLOOR_COORDS);
        floorVertices.position(0);

        ByteBuffer bbFloorNormals = ByteBuffer.allocateDirect(WorldLayoutData.FLOOR_NORMALS.length * 4);
        bbFloorNormals.order(ByteOrder.nativeOrder());
        floorNormals = bbFloorNormals.asFloatBuffer();
        floorNormals.put(WorldLayoutData.FLOOR_NORMALS);
        floorNormals.position(0);

        ByteBuffer bbFloorColors = ByteBuffer.allocateDirect(WorldLayoutData.FLOOR_COLORS.length * 4);
        bbFloorColors.order(ByteOrder.nativeOrder());
        floorColors = bbFloorColors.asFloatBuffer();
        floorColors.put(WorldLayoutData.FLOOR_COLORS);
        floorColors.position(0);

        int vertexShader = loadGLShader(GLES20.GL_VERTEX_SHADER, R.raw.light_vertex);
        int gridShader = loadGLShader(GLES20.GL_FRAGMENT_SHADER, R.raw.grid_fragment);
        int passthroughShader = loadGLShader(GLES20.GL_FRAGMENT_SHADER, R.raw.passthrough_fragment);

        for (Cube c : cubeList) {
            c.cubeProgram = GLES20.glCreateProgram();
            GLES20.glAttachShader(c.cubeProgram, vertexShader);
            GLES20.glAttachShader(c.cubeProgram, passthroughShader);
            GLES20.glLinkProgram(c.cubeProgram);
            GLES20.glUseProgram(c.cubeProgram);

            checkGLError("Cube program");
            c.cubePositionParam = GLES20.glGetAttribLocation(c.cubeProgram, "a_Position");
            c.cubeNormalParam = GLES20.glGetAttribLocation(c.cubeProgram, "a_Normal");
            c.cubeColorParam = GLES20.glGetAttribLocation(c.cubeProgram, "a_Color");

            c.cubeModelParam = GLES20.glGetUniformLocation(c.cubeProgram, "u_Model");
            c.cubeModelViewParam = GLES20.glGetUniformLocation(c.cubeProgram, "u_MVMatrix");
            c.cubeModelViewProjectionParam = GLES20.glGetUniformLocation(c.cubeProgram, "u_MVP");
            c.cubeLightPosParam = GLES20.glGetUniformLocation(c.cubeProgram, "u_LightPos");

            checkGLError("Cube program params");
        }

        floorProgram = GLES20.glCreateProgram();
        GLES20.glAttachShader(floorProgram, vertexShader);
        GLES20.glAttachShader(floorProgram, gridShader);
        GLES20.glLinkProgram(floorProgram);
        GLES20.glUseProgram(floorProgram);

        checkGLError("Floor program");

        floorModelParam = GLES20.glGetUniformLocation(floorProgram, "u_Model");
        floorModelViewParam = GLES20.glGetUniformLocation(floorProgram, "u_MVMatrix");
        floorModelViewProjectionParam = GLES20.glGetUniformLocation(floorProgram, "u_MVP");
        floorLightPosParam = GLES20.glGetUniformLocation(floorProgram, "u_LightPos");

        floorPositionParam = GLES20.glGetAttribLocation(floorProgram, "a_Position");
        floorNormalParam = GLES20.glGetAttribLocation(floorProgram, "a_Normal");
        floorColorParam = GLES20.glGetAttribLocation(floorProgram, "a_Color");

        checkGLError("Floor program params");

        Matrix.setIdentityM(modelFloor, 0);
        Matrix.translateM(modelFloor, 0, 0, -floorDepth, 0); // Floor appears below user.

        for (Cube c : cubeList)
            updateModelPosition(c);
        checkGLError("onSurfaceCreated");
    }

    /**
     * Updates the cube model position.
     */
    protected void updateModelPosition(Cube c) {

        Matrix.setIdentityM(c.modelCube, 0);
        if (c.alive)
            Matrix.translateM(c.modelCube, 0, c.modelPosition[0], c.modelPosition[1], c.modelPosition[2]);
        else
            Matrix.translateM(c.modelCube, 0, 1000.0f, 1000.0f, 1000.0f);

        checkGLError("updateCubePosition");
    }

    /**
     * Converts a raw text file into a string.
     *
     * @param resId The resource ID of the raw text file about to be turned into a shader.
     * @return The context of the text file, or null in case of error.
     */
    private String readRawTextFile(int resId) {
        InputStream inputStream = getResources().openRawResource(resId);
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }
            reader.close();
            return sb.toString();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Prepares OpenGL ES before we draw a frame.
     *
     * @param headTransform The head transformation in the new frame.
     */
//    int countFrame = 0;
    @Override
    public void onNewFrame(HeadTransform headTransform) {
        float x = 0f, y = 0f;
        if (cubeList != null) {
            x = cubeList.get(agent).modelPosition[0];
            y = cubeList.get(agent).modelPosition[2];
        }

        // Build the camera matrix and apply it to the ModelView.

        Matrix.setLookAtM(camera, 0, x, 0.0f, y, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);

        headTransform.getHeadView(headView, 0);

        // Update the 3d audio engine with the most recent head rotation.
        headTransform.getQuaternion(headRotation, 0);
        gvrAudioEngine.setHeadRotation(
                headRotation[0], headRotation[1], headRotation[2], headRotation[3]);
        // Regular update call to GVR audio engine.
        gvrAudioEngine.update();

        checkGLError("onReadyToDraw");
    }

    /**
     * Draws a frame for an eye.
     *
     * @param eye The eye to render. Includes all required transformations.
     */
    @Override
    public void onDrawEye(Eye eye) {
        GLES20.glEnable(GLES20.GL_DEPTH_TEST);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);

        checkGLError("colorParam");

        // Apply the eye transformation to the camera.
        Matrix.multiplyMM(view, 0, eye.getEyeView(), 0, camera, 0);

        // Set the position of the light
        Matrix.multiplyMV(lightPosInEyeSpace, 0, view, 0, LIGHT_POS_IN_WORLD_SPACE, 0);

        // Build the ModelView and ModelViewProjection matrices
        // for calculating cube position and light.
        float[] perspective = eye.getPerspective(Z_NEAR, Z_FAR);
        for (Cube c : cubeList) {
            Matrix.multiplyMM(modelView, 0, view, 0, c.modelCube, 0);
            Matrix.multiplyMM(modelViewProjection, 0, perspective, 0, modelView, 0);
            drawCube(c);
        }
        // Set modelView for the floor, so we draw floor in the correct location
        Matrix.multiplyMM(modelView, 0, view, 0, modelFloor, 0);
        Matrix.multiplyMM(modelViewProjection, 0, perspective, 0, modelView, 0);
        drawFloor();
    }

    @Override
    public void onFinishFrame(Viewport viewport) {
    }

    /**
     * Draw the cube.
     * <p>
     * <p>We've set all of our transformation matrices. Now we simply pass them into the shader.
     */
    public void drawCube(Cube c) {
        GLES20.glUseProgram(c.cubeProgram);

        GLES20.glUniform3fv(c.cubeLightPosParam, 1, lightPosInEyeSpace, 0);

        // Set the Model in the shader, used to calculate lighting
        GLES20.glUniformMatrix4fv(c.cubeModelParam, 1, false, c.modelCube, 0);

        // Set the ModelView in the shader, used to calculate lighting
        GLES20.glUniformMatrix4fv(c.cubeModelViewParam, 1, false, modelView, 0);

        // Set the position of the cube
        GLES20.glVertexAttribPointer(
                c.cubePositionParam, COORDS_PER_VERTEX, GLES20.GL_FLOAT, false, 0, cubeVertices);

        // Set the ModelViewProjection matrix in the shader.
        GLES20.glUniformMatrix4fv(c.cubeModelViewProjectionParam, 1, false, modelViewProjection, 0);

        // Set the normal positions of the cube, again for shading
        GLES20.glVertexAttribPointer(c.cubeNormalParam, 3, GLES20.GL_FLOAT, false, 0, cubeNormals);
        if (c.attacker && !c.observer)
            GLES20.glVertexAttribPointer(c.cubeColorParam, 4, GLES20.GL_FLOAT, false, 0, cubeObeserverColors);
        else if (c.observer) {
            GLES20.glVertexAttribPointer(c.cubeColorParam, 4, GLES20.GL_FLOAT, false, 0, cubeAttackerColors);
            Log.e("OB", "Find!");
        } else
            GLES20.glVertexAttribPointer(c.cubeColorParam, 4, GLES20.GL_FLOAT, false, 0, cubeColors);

        // Enable vertex arrays
        GLES20.glEnableVertexAttribArray(c.cubePositionParam);
        GLES20.glEnableVertexAttribArray(c.cubeNormalParam);
        GLES20.glEnableVertexAttribArray(c.cubeColorParam);

        GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, 36);

        // Disable vertex arrays
        GLES20.glDisableVertexAttribArray(c.cubePositionParam);
        GLES20.glDisableVertexAttribArray(c.cubeNormalParam);
        GLES20.glDisableVertexAttribArray(c.cubeColorParam);
//        Log.e("tag", "in draw cube");
        checkGLError("Drawing cube");

    }

    /**
     * Draw the floor.
     * <p>
     * <p>This feeds in data for the floor into the shader. Note that this doesn't feed in data about
     * position of the light, so if we rewrite our code to draw the floor first, the lighting might
     * look strange.
     */
    public void drawFloor() {
        GLES20.glUseProgram(floorProgram);

        // Set ModelView, MVP, position, normals, and color.
        GLES20.glUniform3fv(floorLightPosParam, 1, lightPosInEyeSpace, 0);
        GLES20.glUniformMatrix4fv(floorModelParam, 1, false, modelFloor, 0);
        GLES20.glUniformMatrix4fv(floorModelViewParam, 1, false, modelView, 0);
        GLES20.glUniformMatrix4fv(floorModelViewProjectionParam, 1, false, modelViewProjection, 0);
        GLES20.glVertexAttribPointer(
                floorPositionParam, COORDS_PER_VERTEX, GLES20.GL_FLOAT, false, 0, floorVertices);
        GLES20.glVertexAttribPointer(floorNormalParam, 3, GLES20.GL_FLOAT, false, 0, floorNormals);
        GLES20.glVertexAttribPointer(floorColorParam, 4, GLES20.GL_FLOAT, false, 0, floorColors);

        GLES20.glEnableVertexAttribArray(floorPositionParam);
        GLES20.glEnableVertexAttribArray(floorNormalParam);
        GLES20.glEnableVertexAttribArray(floorColorParam);

        GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, 24);

        GLES20.glDisableVertexAttribArray(floorPositionParam);
        GLES20.glDisableVertexAttribArray(floorNormalParam);
        GLES20.glDisableVertexAttribArray(floorColorParam);

        checkGLError("drawing floor");
    }

    public void oneFrame() {
        Log.i(TAG, "onCardboardTrigger: " + frameIndex);
        if (frameIndex < maxFrame) {
            if (frameIntervalIndex < interval) {
                ArrayList<Attack> aL = frameArrayList[frameIndex].attackArrayList;
                for (int j = 0; j < aL.size(); j++) {
                    Attack a = aL.get(j);
                    int id = a.cubeId;
                    int x = a.attackPositionX;
                    int y = a.attackPositionY;
                    for (int k = 0; k < cubeList.size(); k++) {
                        Cube c = cubeList.get(k);
                        if (c.cubeId == id) {
                            float dx = x - c.positionX;
                            float dy = y - c.positionY;
                            c.positionX += dx / interval * frameIntervalIndex;
                            c.positionY += dy / interval * frameIntervalIndex;
                            c.modelPosition = new float[]{
                                    c.positionX, height, c.positionY
                            };
                            updateModelPosition(c);
                            break;
                        }
                    }
                }
                frameIntervalIndex++;
            } else {
                frameIntervalIndex = 0;
                ArrayList<Attack> aL = frameArrayList[frameIndex].attackArrayList;
                for (int j = 0; j < aL.size(); j++) {
                    Attack a = aL.get(j);
                    int x = a.attackPositionX;
                    int y = a.attackPositionY;
                    for (int k = 0; k < cubeList.size(); k++) {
                        Cube c = cubeList.get(k);
                        if (c.positionX == x && c.positionY == y && !c.attacker) {
                            c.alive = false;
                            Log.e(TAG, "attack");
                            updateModelPosition(c);
                            break;
                        }
                    }
                }
                frameIndex++;
            }
        } else {
            frameIndex = 0;
            cubeList.get(agent).observer = false;
            agent++;
            cubeList.get(agent).observer = true;
            BufferedReader reader = null;
            try {
                reader = new BufferedReader(
                        new InputStreamReader(getAssets().open("in.txt")));
                String mLine;
                int i = 0;
                while ((mLine = reader.readLine()) != null) {
                    String[] tokens = mLine.split(" ");
                    cubeList.get(i).positionX = Integer.valueOf(tokens[3]);
                    cubeList.get(i).positionY = Integer.valueOf(tokens[4]);
                    cubeList.get(i).alive = true;
                    cubeList.get(i).modelPosition = new float[]{
                            Float.valueOf(tokens[3]), height, Float.valueOf(tokens[4])
                    };
                    i++;
                    for (int j = 0; j < cubeList.size(); j++)
                        updateModelPosition(cubeList.get(j));
                }
                reader.close();
            } catch (IOException e) {
                Log.e("mytext", "read text failure");
            } finally {
                if (reader != null) {
                    try {
                        reader.close();
                    } catch (IOException e) {
                        Log.e("mytext", "read text failure");
                    }
                }
            }
        }


    }

    @Override
    protected void onResume() {
        h.postDelayed(new Runnable() {
            public void run() {
                //do something
                oneFrame();
                runnable = this;
                h.postDelayed(runnable, delay);
            }
        }, delay);
        gvrAudioEngine.resume();
        super.onResume();
    }

    @Override
    protected void onPause() {
        h.removeCallbacks(runnable); //stop handler when activity not visible
        gvrAudioEngine.pause();
        super.onPause();
    }
}
