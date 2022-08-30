/**
   BOUNCY ICONS v1.0

   Rather simple plugin which enables a screensaver-like pattern
   of bouncy icons present inside the newest Trackmania game.
   Speed of the on-screen images is dependent on your framerate
   (might change in the future).

   Feel free to suggest something for the plugin.

   Made by Deska
**/

/** Width of the Game window */
int windowX = 0;
/** Height of the Game window */
int windowY = 0;
/** Measurement of corner hits */
int cornerHits = 0;
/** All available balls */
Ball@[] Balls;

[Setting name="Enable"]
bool enableBalls = true;
[Setting name="Ball amount" drag min=1 max=50]
int ballAmount = 1;
int prevBallAmount = ballAmount;
[Setting name="Ball speed" drag min=0.01 max=20.0]
float ballSpeed = 1.5;
[Setting name="Ball width" drag min=10 max=1000]
int ballWidth = 250;
int prevBallWidth = ballWidth;
[Setting name="Black Screen"]
bool blackScreen = false;
//[Setting name="Opacity" drag min=0.0 max=1.0]
float ballOpacity = 0.0;

enum Images{
   TMLogoBlack,
   TMLogoWhite,
   TMLogoMix,
   Hylis,
   Nadeo,
   Vintage,
   ILoveTMEsports
}
[Setting name="Image"]
Images ChosenImage = Images::TMLogoBlack;
Images prevChosenImage = ChosenImage;

UI::Texture@[] Textures;
string[] TexturePaths = {"Logos/TMLogo.png","Logos/TMLogoWhite.png","Logos/Hylis.png","Logos/TMVintage.png","Logos/Nadeo.png","Logos/ILOVETM.png"};
void initTextures() {
   for (int i=0; i<TexturePaths.Length; i++)
   Textures.InsertLast(UI::LoadTexture(TexturePaths[i]));
}

dictionary imageIndices = {
   {tostring(Images::TMLogoBlack), 0},
   {tostring(Images::TMLogoWhite), 1},
   {tostring(Images::Hylis), 2},
   {tostring(Images::Vintage), 3},
   {tostring(Images::Nadeo), 4},
   {tostring(Images::ILoveTMEsports), 5},
   {tostring(Images::TMLogoMix), 0}
};

bool updateWindowSize() {
   //nice
   auto app = cast<CTrackMania>(GetApp());
   int2 windowSizes = app.ManiaPlanetScriptAPI.DisplaySettings.WindowFullSize;
   
   bool windowUpdate = false;
   if (windowX != windowSizes.x) windowUpdate = true;
   windowX = windowSizes.x;
   if (windowY != windowSizes.y) windowUpdate = true;
   windowY = windowSizes.y;

   return windowUpdate;
}

class Ball {
   vec2 pos;
   float angleR;
   vec2 size;
   vec4 colors;
   Images loadedImage;
   UI::Texture@ texture;
   //used for TMLogoMix
   bool BoW = true;

   Ball(Images importImage) {
      loadedImage = importImage;

      //load the texture from the dictonary
      if (importImage != Images::TMLogoMix) {
         @texture = Textures[int(imageIndices[tostring(importImage)])];
      }
      else {
         //Mix - random assortment of the TM2020 logo
         int rand = int(Math::Rand(0,2));
         if (rand==0) @texture = Textures[int(imageIndices[tostring(Images::TMLogoBlack)])];
         else {
            @texture = Textures[int(imageIndices[tostring(Images::TMLogoWhite)])];
            BoW = false;
         }
      }

      size.x = ballWidth;
      vec2 texSize = texture.GetSize();
      //height
      size.y = int((1.0 * texSize.y / texSize.x) * size.x);

      pos.x = Math::Rand(0,windowX-size.x);
      pos.y = Math::Rand(0,windowY-size.y);

      //avoid very flat angles
      int zone = int(Math::Rand(0,4));
      angleR = Math::ToRad(Math::Rand(20.0,70.0) + zone*90.0);
      RandomizeColor();
   }

   void RandomizeColor() {
      colors.x = Math::Rand(0.5,1.0);
      colors.y = Math::Rand(0.5,1.0);
      colors.z = Math::Rand(0.5,1.0);
      colors.w = 1.0 - ballOpacity;
   }

   //simulate a tick
   void tick() {
      float dx = Math::Cos(angleR) * ballSpeed;
      float dy = Math::Sin(angleR) * ballSpeed;
      pos.x += dx;
      pos.y -= dy;

      bool edgeHit = true;
      //check collisions

      if (pos.x < 0.0) {
         //upper left
         pos.x = -pos.x;
         if (pos.y < 0) {
            pos.y = -pos.y;
            angleR = angleR - Math::ToRad(180);
            CornerHit();
         }
         //lower left
         else if (pos.y + size.y > windowY) {
            pos.y = 2*(windowY - size.y) - pos.y;
            angleR = angleR - Math::ToRad(180);
            CornerHit();
         }
         //normal
         else {
            angleR = Math::ToRad(180) - angleR;
         }
      }
      else if (pos.x + size.x > windowX) {
         pos.x = 2*(windowX - size.x) - pos.x;
         //upper right
         if (pos.y < 0) {
            pos.y = -pos.y;
            angleR = angleR - Math::ToRad(180);
            CornerHit();
         }
         //lower right
         else if (pos.y + size.y > windowY) {
            pos.y = 2*(windowY - size.y) - pos.y;
            angleR = angleR - Math::ToRad(180);
            CornerHit();
         }
         //normal
         else {
            angleR = Math::ToRad(180) - angleR;
         }
      }
      else if (pos.y < 0) {
         angleR = -angleR;
         pos.y = -pos.y;
      }
      else if (pos.y + size.y > windowY) {
         angleR = -angleR;
         pos.y = 2*(windowY - size.y) - pos.y;
      }
      //no edge hit
      else {
         edgeHit = false;
      }

      if (edgeHit) {
         RandomizeColor();

         if (loadedImage == Images::TMLogoMix) {
            if (BoW) @texture = Textures[int(imageIndices[tostring(Images::TMLogoWhite)])];
            else @texture = Textures[int(imageIndices[tostring(Images::TMLogoBlack)])];
            BoW = !BoW;
         }
      }
   }

   void Render() {
      tick();
      auto drawlist = UI::GetForegroundDrawList();
      drawlist.AddRectFilled(
         vec4(pos.x,pos.y,size.x,size.y),
         colors,
         0.0);
      drawlist.AddImage(texture,pos,vec2(size.x,size.y));
   }

   void CornerHit() {
      cornerHits++;
      //TODO maybe something fancy?
   }
}

void initBalls() {
   for (int i=Balls.Length-1; i>=0; i--)
      Balls.RemoveAt(i);

   for (int i=0; i<ballAmount; i++)
      Balls.InsertLast(Ball(ChosenImage));
}

void Main()
{
   updateWindowSize();
   initTextures();
   initBalls();
   while(true) {
      if (enableBalls && updateWindowSize()) {
         print("New window sizes: " + windowX + " " + windowY);
      }
      yield();
   }  
}

void drawBlackScreen() {
   auto drawlist = UI::GetBackgroundDrawList();
   drawlist.AddRectFilled(
         vec4(0,0,windowX,windowY),
         vec4(0,0,0,1),
         0.0);
}

void Render() {
   if (enableBalls) for (uint i=0; i<Balls.Length; i++) {
      if (@Balls[i] != null)
         Balls[i].Render();
   }
   if (blackScreen) drawBlackScreen();
}

void OnSettingsChanged()
{
   //check whether a ball restart is required
   if (ballAmount != prevBallAmount
   || ballWidth != prevBallWidth
   || ChosenImage != prevChosenImage) {
      initBalls();
   }

   prevBallAmount = ballAmount;
   prevBallWidth = ballWidth;
   prevChosenImage = ChosenImage;
}