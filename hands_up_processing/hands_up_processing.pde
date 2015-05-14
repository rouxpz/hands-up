import processing.serial.*;
import SimpleOpenNI.*;
import com.temboo.core.*;
import com.temboo.Library.Flickr.Photos.*;
import org.apache.commons.codec.binary.Base64;
import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

String apiKey, apiSecret, accessToken, accessSecret;
String tembooName, tembooProject, tembooKey;

ArrayList<String> uploaded = new ArrayList<String>();
// Create a session using your Temboo account application details
TembooSession session;

//kinect & serial variables
SimpleOpenNI kinect;
Serial port;

//minim variables
Minim minim;
AudioPlayer ap;
float a;

boolean up;
boolean prevUp;

int startTimer;
int delayTime = 0;

void setup() {
  size(640, 480);
  frameRate(24);
  kinect = new SimpleOpenNI(this);
  
  if (!kinect.isInit()) {
    println("Can't initialize, camera is not connected");
    exit();
    return;
  }
  
  //load audio
  minim = new Minim(this);
  ap = minim.loadFile("Ride Wit Me.wav");
  
  //load temboo info and start session
  String[] tembooInfo = loadStrings("temboo-info.txt");
  tembooName = tembooInfo[0];
  tembooProject = tembooInfo[1];
  tembooKey = tembooInfo[2];
  session = new TembooSession(tembooName, tembooProject, tembooKey);
  
  startTimer = frameCount;
  
  kinect.enableDepth();
  kinect.enableUser();
  
  //load in and assign Flickr API info
  String[] apiInfo = loadStrings("api-info.txt");
  apiKey = apiInfo[0];
  apiSecret = apiInfo[1];
  accessSecret = apiInfo[2];
  accessToken = apiInfo[3];
  
  //load in images already in the data folder
  File dir = new File(dataPath(""));
  String[] list = dir.list();
  for (String l : list) {
    uploaded.add(l);
  }
  
  // println(Serial.list());
  String portName = Serial.list()[5];
  port = new Serial(this, portName, 9600);
  
  background(200, 0, 0);
  
  smooth();
  
  up = false;
}

void draw() {
  kinect.update();
  
  image(kinect.depthImage(), 0, 0);
  
  int[] userList = kinect.getUsers();
  
  for (int i = 0; i < userList.length; i++) {
    
    if (kinect.isTrackingSkeleton(userList[i])) {
      stroke(255, 0, 0);
      drawSkeleton(userList[i]);
      handsUp(userList[i]);
      increaseVolume();
    }
  }
  
  prevUp = up;
}

void handsUp(int userId) {
  PVector lHandPos = new PVector();
  PVector convertedL = new PVector();
  kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, lHandPos);
  kinect.convertRealWorldToProjective(lHandPos, convertedL);
  
  stroke(0);
  fill(255);
  ellipse(convertedL.x, convertedL.y, 10, 10);
  // println(lHandPos);
  
  PVector rHandPos = new PVector();
  PVector convertedR = new PVector();
  kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, rHandPos);
  kinect.convertRealWorldToProjective(rHandPos, convertedR);
  
  stroke(0);
  fill(255);
  ellipse(convertedR.x, convertedR.y, 10, 10);
  // println(rHandPos);
  
  PVector headPos = new PVector();
  PVector convertedHead = new PVector();
  kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, headPos);
  kinect.convertRealWorldToProjective(headPos, convertedHead);
  ellipse(convertedHead.x, convertedHead.y, 10, 10);
  // println(headPos);
  
  if (convertedL.y < convertedHead.y && convertedR.y < convertedHead.y) {
    up = true;
    if (prevUp == false) {
      
      //only send serial value when hands cross the threshold
      println("DON'T SHOOT " + frameCount);
      ap.pause();
      ap.rewind();
      port.write('0');
      startTimer = frameCount;
      // println(startTimer + ", " + frameCount);
      
    } else {
      port.write('1');
    }
    
    delayTime = frameCount - startTimer;
    
    //delay the camera shutter
    if (delayTime == 1) {
        
        port.write('2');
        println("shutter, " + delayTime);
        delayTime = 0;

      }

  } else {
    up = false;
    port.write('1');
  }
  

}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
} 

//for now -- upload new images to Flickr on mouse press
void mousePressed() {
  listFiles();  
}

//temboo upload to Flickr
void runUploadChoreo(String result) {
  // Create the Choreo object using your Temboo session
  Upload uploadChoreo = new Upload(session);

  // Set inputs
  uploadChoreo.setImageFileContents(result);
  uploadChoreo.setAPIKey(apiKey);
  uploadChoreo.setAccessToken(accessToken);
  uploadChoreo.setAccessTokenSecret(accessSecret);
  uploadChoreo.setAPISecret(apiSecret);

  // Run the Choreo and store the results
  UploadResultSet uploadResults = uploadChoreo.run();
  
  // Print results
  println(uploadResults.getResponse());

}

//checks files in directory and uploads new ones to Flickr
void listFiles() {
  
  ArrayList<String> toUpload = new ArrayList<String>();
  File dir = new File(dataPath(""));
  String[] list = dir.list();
 
  for (String l : list) {
    
    boolean found = false;
    
    for (String u : uploaded) {
      if (l.equals(u) == true) {       
        println("found a match! " + l);
        found = true;
        break;
      }
      println(l + "found: " + found);
    } 
    
    if (!found) toUpload.add(l);
  }
  
  println("to upload: ");
  println(toUpload);
  for (String t : toUpload) {
    //convert image to byte array and encode in base 64
    byte [] b = loadBytes(t);
    String r = Base64.encodeBase64URLSafeString(b);
    
    //upload to Flickr
    runUploadChoreo(r);
    
    //add to the "already uploaded" arraylist
    uploaded.add(t);
  }
  println(uploaded);
}

//increases the longer someone stays tracked
void increaseVolume() {
  
  if (ap.isPlaying()) {    
    a = map(ap.position(), 0, ap.length()/3, -35, -13);
    ap.setGain(a);
  }
  
  
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curkinect, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  
  curkinect.startTrackingSkeleton(userId);
  ap.play();
}

void onLostUser(SimpleOpenNI curkinect, int userId)
{
  println("onLostUser - userId: " + userId);
  
}

void onVisibleUser(SimpleOpenNI curkinect, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}

void keyPressed()
{
  switch(key)
  {
  case 'a':
    kinect.setMirror(!kinect.mirror());
    break;
  }
} 
