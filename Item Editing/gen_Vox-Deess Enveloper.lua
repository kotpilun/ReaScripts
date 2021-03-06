--[[
   * ReaScript Name:Vox-Deess Enveloper
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Mcnt=0
function M(msg) 
 if Mcnt<500 then reaper.ShowConsoleMsg(tostring(msg).."\n"); Mcnt=Mcnt+1 end 
end
--------------------------------------------------------------------------------
--   Some Default Values   -----------------------------------------------------
--------------------------------------------------------------------------------
srate = 44100     -- fix it, need get real srate from proj or source
block_size = 1024*16 -- Block size
n_chans = 2       -- num_chans(for track default,for take use source n_chans) 

--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.norm_val = norm_val
    ------
    setmetatable(elm, self)
    self.__index = self 
    return elm
end
--------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ----
--------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent}) 
end
--------------------------------------------------------------
---   Element Class Methods(Main Methods)   ------------------
--------------------------------------------------------------
function Element:update_xywh()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = math.ceil(self.def_xywh[1]* Z_w) , math.ceil(self.def_xywh[3]* Z_w) --upd x,w
  self.y, self.h = math.ceil(self.def_xywh[2]* Z_h) , math.ceil(self.def_xywh[4]* Z_h) --upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = math.max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = math.min(22,self.fnt_sz)
  end       
end
------------------------
function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Element:mouseIN()
  return gfx.mouse_cap&1==0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Element:mouseDown()
  return gfx.mouse_cap&1==1 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseUp() -- its actual for sliders and knobs only!
  return gfx.mouse_cap&1==0 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1 and
  self:pointIN(gfx.mouse_x,gfx.mouse_y) and self:pointIN(mouse_ox,mouse_oy)         
end
------------------
function Element:mouseR_Down()
  return gfx.mouse_cap&2==2 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseM_Down()
  return gfx.mouse_cap&64==64 and self:pointIN(mouse_ox,mouse_oy)
end
------------------------
function Element:draw_frame()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.rect(x, y, w, h, 0)               --frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true)--frame2         
end
----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
local Button ={}; local Knob ={}; local Slider ={}; local Frame ={};
  extended(Button, Element)
  extended(Knob,   Element)
  extended(Slider, Element)
  extended(Frame,  Element)
--- Create Slider Child Classes(V_Slider,H_Slider) ----
local H_Slider ={}; local V_Slider ={};
  extended(H_Slider, Slider)
  extended(V_Slider, Slider)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Draw btn lbl(text) --
      gfx.set(0.7, 0.8, 0.4, 1)--set label color
      gfx.setfont(1, fnt, fnt_sz);--set label fnt
        local lbl_w, lbl_h = gfx.measurestr(self.lbl)
        gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
        gfx.drawstr(self.lbl)
end
---------------------
function Button:draw()
    self:update_xywh()--Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    -- Get L_mouse state -----
          --in element--
          if self:mouseIN() then a=a+0.1 end
          --in elm L_down--
          if self:mouseDown() then a=a+0.2 end
          --in elm L_up(released and was previously pressed)--
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn(body,frame) --
    gfx.set(r,g,b,a)--set btn color
    gfx.rect(x,y,w,h,true)--body
    self:draw_frame()
    ------------------------
    self:draw_lbl()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function H_Slider:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local VAL,K = 0,10 --val=temp value;k=koof(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
function V_Slider:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local VAL,K = 0,10 --val=temp value;k=koof(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((last_y-gfx.mouse_y)/(h*K))
       else VAL = (h-(gfx.mouse_y-y))/h end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
----------------
function H_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true)--Hor Slider body
end
function V_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = h * self.norm_val
    gfx.rect(x,y+h-val, w, val, true) --Vert Slider body
end
----------------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl)--draw Slider label
end
function V_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+h-lbl_h-5
    gfx.drawstr(self.lbl)--draw Slider label
end
----------------
function H_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
end
function V_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+(w-val_w)/2; gfx.y = y+5
    gfx.drawstr(val)--draw Slider Value
end

---------------------
function Slider:draw()
    self:update_xywh()--Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    ---Get L_mouse state--
          --in element-----
          if self:mouseIN() then a=a+0.1 end
          --in elm L_down--
          if self:mouseDown() then a=a+0.2 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end
    --Draw (body,frame)--
    gfx.set(r,g,b,a)--set color
    self:draw_body()--body
    self:draw_frame()--frame
    ------------------------
    --Draw label,value--
    gfx.set(0.7, 0.8, 0.4, 1)--set labels color
    gfx.setfont(1, fnt, fnt_sz);--set labels fnt
    self:draw_lbl()
    self:draw_val()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Frame Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Frame:draw()
   self:update_xywh()--Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   if self:mouseIN() then a=a+0.1 end
   gfx.set(r,g,b,a)--set color
   self:draw_frame()
end
----------------------------------------------------------------------------------------------------
---  Create Objects(Wave,Filter,Gate) --------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local Wave = Element:new(10,10,1024,350)
------------------
local Filter_B = {}
local Gate_Gl  = {}
------------------
---------------------------------------------------------------
---  Create Frames   ------------------------------------------
---------------------------------------------------------------
local Fltr_Frame = Frame:new(10, 370,200,110,  0,0.5,0,0.2 )
local Gate_Frame = Frame:new(240,370,310,110,  0,0.5,0,0.2 )
local Frame_TB = {Fltr_Frame, Gate_Frame}

----------------------------------------------------------------------------------------------------
---  Create Objects(controls) and override some methods   ------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--- Sliders ------------------------------------------------------------------------
------------------------------------------------------------------------------------
local HP_Freq = H_Slider:new(20,420,180,20, 0.3,0.5,0.7,0.3, "HP Freq","Arial",15, 0.4 )
  function HP_Freq:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = (srate/2)*self.norm_val                     -- (srate/2)*norm_val !!!
    local val = string.format("%.1f", val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
----------------
local Fltr_Gain = H_Slider:new(20,450,180,20,  0.3,0.5,0.5,0.3, "Filter Gain","Arial",15, 3/7 )
  function Fltr_Gain:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = 20*math.log(self.norm_val*7 + 1 , 10)       -- norm_val*7+1 !!!
    local val = string.format("%.1f", val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
--------------------------------------------------
--------------------------------------------------
local Gate_Thresh = H_Slider:new(250,380,220,20, 0.3,0.5,0.7,0.3, "Threshold","Arial",15, 0.4 )
  function Gate_Thresh:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = 20*math.log(self.norm_val/4+0.0001 ,10)     -- norm_val/4 + 0.0001 !!!
    local val = string.format("%.1f", val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
    Gate_Thresh:draw_val_line()
  end
  ----------
  function Gate_Thresh:draw_val_line()
    if Wave.State then gfx.set(0.8,0.3,0,1)
      local val_line1 = Wave.y + Wave.h/2 - (Gate_Thresh.norm_val/4+0.0001)*Wave.Y_scale
      local val_line2 = Wave.y + Wave.h/2 + (Gate_Thresh.norm_val/4+0.0001)*Wave.Y_scale
      gfx.line(Wave.x, val_line1, Wave.x+Wave.w-1, val_line1 )
      gfx.line(Wave.x, val_line2, Wave.x+Wave.w-1, val_line2 )
    end
  end
----------------
local Gate_RMS = H_Slider:new(250,420,220,20, 0.3,0.5,0.5,0.3, "RMS time","Arial",15, 0.15 )
  function Gate_RMS:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val * 100                   -- norm_val*100 !!!
    local val = string.format("%.1f", val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
----------------
local Gate_Pre = H_Slider:new(250,450,100,20, 0.5,0.3,0.2,0.3, "Pre","Arial",14, 0.20 )
  function Gate_Pre:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val * 100                   -- norm_val*100 !!!
    local val = string.format("%.0f", val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
----------------
local Gate_Post = H_Slider:new(370,450,100,20, 0.3,0.5,0.2,0.3, "Post","Arial",14, 0.10 )
  function Gate_Post:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val * 100                   -- norm_val*100 !!!
    local val = string.format("%.0f", val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
  ----------------------------------------
  -- onUp function for Gate sliders ---
  ----------------------------------------
  function Gate_Sldrs_onUp() 
      if Wave.State then
        reaper.Undo_BeginBlock() 
          Gate_Gl:Set_Values()
          Gate_Gl:Apply_toFiltered()
          Wave:Create_Envelope()
        reaper.Undo_EndBlock("~Change Envelope~", -1)
      end 
  end
  Gate_Thresh.onUp  = Gate_Sldrs_onUp
  Gate_RMS.onUp     = Gate_Sldrs_onUp
  Gate_Pre.onUp     = Gate_Sldrs_onUp
  Gate_Post.onUp    = Gate_Sldrs_onUp
--------------------------------------------------
--------------------------------------------------
local Env_Gain = V_Slider:new(490,380,50,90, 0.4,0.2,0.2,0.3, "Env","Arial",14, 0.86 ) 
  function Env_Gain:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    --- Scaled val  -- !!! ----------
    local minp, maxp = 0,1
    local minv, maxv = math.log(0.05), math.log(1)
    local scale = (maxv-minv) / (maxp-minp)
    self.scal_val = math.exp(minv + scale*(self.norm_val-minp))
    ---------------------------------
    local val = 20*math.log(self.scal_val ,10) --
    ---------------------------------------------
    local val = string.format("%.1f", val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+(w-val_w)/2; gfx.y = y+5
    gfx.drawstr(val)--draw Slider Value
  end
  ----------
  ----------
  Env_Gain.onMove = 
  function() 
     if Wave.State then Wave:Create_Envelope() end 
  end
  Env_Gain.onUp = 
  function() 
     if Wave.State then reaper.Undo_OnStateChangeEx("~Change Envelope~", 1, -1) end 
  end

-----------------------------------
--- Slider_TB ---------------------
-----------------------------------
local Slider_TB = {HP_Freq,Fltr_Gain, Gate_Thresh,Gate_RMS,Gate_Pre,Gate_Post, Env_Gain}

------------------------------------------------------------------------------------
--- Buttons ------------------------------------------------------------------------
------------------------------------------------------------------------------------
local Detect = Button:new(20,380,180,25, 0.4,0.12,0.12,0.3, "Get Selection",    "Arial",15 )
  Detect.onClick = 
  function() 
      if Wave:Create_Track_Accessor() then
         reaper.Undo_BeginBlock() 
           Wave:DRAW()
         reaper.Undo_EndBlock("~Create_Envelope~", -1) 
      end 
  end
-----------------------------------
--- Button_TB ---------------------
-----------------------------------
local Button_TB = {Detect}

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Filter  ------------------------------------------------------------------
--------------------------------------------------------------------------------
function Filter_B:Set_Values()
 ---Filter Values------------------
 self.Fltr_Gain = Fltr_Gain.norm_val*7+1   -- from Fltr_Gain Sldr!
 self.HP_Freq = (srate/2)*HP_Freq.norm_val -- from HP_Freq Sldr!
 local sqr2 = 1.414213562;
 local c = math.tan((math.pi/srate) * self.HP_Freq );
 local c2 = c * c;
 local csqr2 = sqr2 * c;
 local d = (c2 + csqr2 + 1);
   self.ampIn0 = 1 / d;
   self.ampIn1 = -(self.ampIn0 + self.ampIn0);
   self.ampIn2 = self.ampIn0;
   self.ampOut1 = (2 * (c2 - 1)) / d;
   self.ampOut2 = (1 - csqr2 + c2) / d;
   self.dlyOut1, self.dlyOut2 = 0, 0
   self.dlyIn1,  self.dlyIn2  = 0, 0
end
--------------------------------------
--------------------------------------
function Filter_B:Apply_toBlock()
 local IN,OUT
   for h = 1, block_size*2, 2 do
        IN = Wave.buffer[h]
        OUT = (self.ampIn0 * IN) + (self.ampIn1 * self.dlyIn1) + 
              (self.ampIn2 * self.dlyIn2) - (self.ampOut1 * self.dlyOut1) - 
              (self.ampOut2 * self.dlyOut2);
        ---------------------------------
        self.dlyOut2 = self.dlyOut1;
        self.dlyOut1 = OUT;
        self.dlyIn2 = self.dlyIn1;
        self.dlyIn1 = IN;
        ---------------------------------
        Wave.buffer[h] = OUT * self.Fltr_Gain
        ---------------------------------
   end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Set_Values()
 ---Gate Values-------------
 self.threshold = Gate_Thresh.norm_val/4 + 0.0001    -- from Sldr thresh value/4 + 0.0001
 ----------------
 self.pre_ms     = Gate_Pre.norm_val*100               -- from Sldr Gate_Pre(in ms)
 self.pre_smpls  = math.floor(srate/1000 *self.pre_ms)
 self.post_ms    = Gate_Post.norm_val*100             -- from Sldr Gate_Post(in ms)
 self.post_smpls = math.floor(srate/1000 *self.post_ms)
 ----------------
 self.rms_ms    = Gate_RMS.norm_val*100               -- from Sldr Gate_RMS(in ms)
 self.rms_smpls = math.floor(srate/1000 * self.rms_ms + 1) -- rms_ms to samples
 self.rms_val   = 0
 self.smpl_cnt  = 0                   -- init smpl_cnt
 self.last_RMS  = 0                   -- its for test,need change to rms_table etc
 ------------------
 self.st_cnt = 1                      -- gate State_Points counter 
 self.State_Points = {}               -- State_Points table 
 self.State_Lines  = {}               -- State_Lines  table
end
--------------------------------------
--------------------------------------
function Gate_Gl:Apply_toFiltered()
 local start_time = reaper.time_precise()--time test
 ---------------------------------
    for i = 1, Wave.Samples*2, 2 do
        self.rms_val  = self.rms_val + (Wave.Buf_Fltrd[i])^2
          --------------------------------------
          if self.smpl_cnt>=self.rms_smpls then 
             self.RMS = math.sqrt(self.rms_val/self.rms_smpls)
               -- Open - Close --
               if self.RMS>self.threshold and self.last_RMS<self.threshold then
                    --- open point -----
                    self.State_Points[self.st_cnt] = true                                           --State
                    self.State_Points[self.st_cnt+1] = Wave.sel_start + ((i+1 - self.rms_smpls)/2)/srate --Time
                    --- open line ------
                    self.State_Lines[self.st_cnt] = true 
                    self.State_Lines[self.st_cnt+1] = ((i+1 - self.rms_smpls)/2) * Wave.X_scale
                  self.st_cnt = self.st_cnt+2
               elseif self.last_RMS>self.threshold and self.RMS<self.threshold then
                    --- close point -----
                    self.State_Points[self.st_cnt] = false                                          --State
                    self.State_Points[self.st_cnt+1] = Wave.sel_start + ((i+1 - self.rms_smpls)/2)/srate --Time
                    --- close line ------
                    self.State_Lines[self.st_cnt] = false 
                    self.State_Lines[self.st_cnt+1] = ((i+1 - self.rms_smpls)/2) * Wave.X_scale
                  self.st_cnt = self.st_cnt+2
               end
             self.last_RMS = self.RMS
             -----------------------
             self.smpl_cnt = 0
             self.rms_val  = 0
          end
          --------------------------------------   
        self.smpl_cnt = self.smpl_cnt + 1      
    end
 --------------------------
 -- Apply Pre_Post --------
 self:Pre_Post()
 -----------------------------
 --reaper.ShowConsoleMsg(reaper.time_precise()-start_time .. '\n')--time test
end
-------------------------------------------
--- Gate - Pre-Post -----------------------
-------------------------------------------
function Gate_Gl:Pre_Post()
  for i=1, #self.State_Points, 2 do
      if self.State_Points[i]     then self.State_Points[i+1] = self.State_Points[i+1] - self.pre_ms/1000  end
      if not self.State_Points[i] then self.State_Points[i+1] = self.State_Points[i+1] + self.post_ms/1000 end
  end
  for i=1, #self.State_Lines, 2 do
      if self.State_Lines[i]     then self.State_Lines[i+1] = self.State_Lines[i+1] - self.pre_smpls  * Wave.X_scale  end
      if not self.State_Lines[i] then self.State_Lines[i+1] = self.State_Lines[i+1] + self.post_smpls * Wave.X_scale end
  end  
end
--------------------------------------------------------------
---  Gate - Draw Gate Lines  ---------------------------------
--------------------------------------------------------------
function Gate_Gl:draw_Lines()
 if not self.State_Lines then return end -- return if no lines
     -----------------------
     for i=1, #self.State_Lines, 2 do
        -- set line color --
        if self.State_Lines[i] then gfx.set(0.5,0.5,0,0.7) -- open  line --
                               else gfx.set(0.2,0.5,0,0.7) -- close line --    
        end
        -- draw line ------- 
        local line_x = Wave.x + (self.State_Lines[i+1] - Wave.Pos) * Wave.Zoom*Z_w
        if line_x>Wave.x and line_x<Wave.x+Wave.w then 
           gfx.line(line_x, Wave.y, line_x, Wave.y + Wave.h-1)
        end 
     end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Wave   -------------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_Track_Accessor() 
 self.track = reaper.GetSelectedTrack(0,0)
    if self.track then self.AA = reaper.CreateTrackAudioAccessor(self.track) 
         self.AA_Hash = reaper.GetAudioAccessorHash(self.AA, "")
         self.AA_start = reaper.GetAudioAccessorStartTime(self.AA)
         self.AA_end   = reaper.GetAudioAccessorEndTime(self.AA)
         self.buffer   = reaper.new_array(block_size*2)--L,R main buffer
         --self.buffer_l = reaper.new_array(block_size*2)--L chan buf
         --self.buffer_r = reaper.new_array(block_size*2)--R chan buf
         return true
    else return false
    end
end
--------
function Wave:Destroy_Track_Accessor()
 if self.AA then reaper.DestroyAudioAccessor(self.AA) 
    self.buffer.clear(); --self.buffer_l.clear(); self.buffer_r.clear()
 end
end
--------
function Wave:Verify_Track_Accessor()
   if self.AA and reaper.ValidatePtr2(0, self.track, "MediaTrack*") then
       local AA = reaper.CreateTrackAudioAccessor(self.track)
       if self.AA_Hash == reaper.GetAudioAccessorHash(AA, "") then
          reaper.DestroyAudioAccessor(AA) -- destroy temporary AA
          return true 
       end
      -- if track not found or Hash changed --
     else return false 
   end 
end
--------
function Wave:Get_Selection_SL()
 local curs_pos = reaper.GetCursorPositionEx(0)
 local sel_start,sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
 local sel_len = sel_end - sel_start
    if sel_len>0 then 
            self.sel_start, self.sel_len = sel_start, sel_len         --selection start and lenght
       else self.sel_start, self.sel_len = curs_pos, block_size/srate --cur_pos and one block lenght 
    end
end
----------------------------------------------------------------------
---  Wave - Create_Envelope  -----------------------------------------
----------------------------------------------------------------------
function Wave:Activate_Envelope()
  self.Env = reaper.GetTrackEnvelopeByName(self.track,"Volume (Pre-FX)")
  if not self.Env then
     reaper.SetOnlyTrackSelected(self.track)
     reaper.TrackList_AdjustWindows(true)
     reaper.Main_OnCommand(40050, 0) -- Pre-FX Vol Env --
     self.Env = reaper.GetTrackEnvelopeByName(self.track,"Volume (Pre-FX)")
  end
end
--------
function Wave:Create_Envelope()
 if not self:Verify_Track_Accessor() then return end 
  self:Activate_Envelope()
  --- Del old points in sel range --
  reaper.DeleteEnvelopePointRange( self.Env, self.sel_start, self.sel_start + self.sel_len )
  local Gain =  Env_Gain.scal_val -- Env_Gain.scal_val
  if Gain == 1 then reaper.UpdateArrange() return end -- return if Env Gain = 1 ! 
    ----------------------------------------------------
    local mode = reaper.GetEnvelopeScalingMode(self.Env)
          Gain = reaper.ScaleToEnvelopeMode(mode,  Gain)
          G_1 = reaper.ScaleToEnvelopeMode(mode, 1)     -- 1 - gain
    ----------------------------------------------------
    reaper.InsertEnvelopePoint(self.Env, self.sel_start + 1/srate, G_1, 0, 0, 0, true) -- sel_start + 1smpl
      -------
      local shape, tens , sel = 2,0,0
      for i=1, #Gate_Gl.State_Points, 2 do
          if Gate_Gl.State_Points[i] then local pre = Gate_Gl.pre_ms/1000 
              reaper.InsertEnvelopePoint(self.Env, Gate_Gl.State_Points[i+1],       G_1, shape, tens, sel, true)
              reaper.InsertEnvelopePoint(self.Env, Gate_Gl.State_Points[i+1]+pre,  Gain, shape, tens, sel, true)
          end
          if not Gate_Gl.State_Points[i] then local post = Gate_Gl.post_ms/1000 
              reaper.InsertEnvelopePoint(self.Env, Gate_Gl.State_Points[i+1]-post, Gain, shape, tens, sel, true)
              reaper.InsertEnvelopePoint(self.Env, Gate_Gl.State_Points[i+1],       G_1, shape, tens, sel, true)
          end
      end 
      -------
    reaper.InsertEnvelopePoint(self.Env, self.sel_start + self.sel_len - 1/srate, G_1, 0, 0, 0, true) -- sel_end - 1smpl
    reaper.Envelope_SortPoints(self.Env)
    reaper.UpdateArrange()
end

--------------------------------------------------------------------------------
---  Wave - Draw(Set_coord > DRAW(inc. draw_block) = full update gfx buffer  ---
--------------------------------------------------------------------------------
-----------------------------------
-----------------------------------
function Wave:Set_Coord()
  -- gfx buffer always used def coord! --
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
  gfx.dest = 1            -- dest buffer
  gfx.a    = 1            -- for buf    
   gfx.setimgdim(1,-1,-1) -- clear buf1(wave)
   gfx.setimgdim(2,-1,-1) -- clear buf2(gate)
   gfx.setimgdim(1,w,h)   -- set w,h
   -------------
   Wave.Zoom = Wave.Zoom or 1  -- init Zoom 
   Wave.Pos  = Wave.Pos  or 0  -- init src position
   -------------
   Wave:Get_Selection_SL()
   -------------
   self.sel_len = math.min(self.sel_len,60)  -- limit lenght(deliberate restriction) 
    self.Samples    = math.floor(self.sel_len*srate)      -- Lenght to samples
    self.Blocks     = math.ceil(self.Samples/block_size)  -- Lenght to sampleblocks
    self.pix_dens   = math.ceil(self.Samples/(w*256))*2   -- Pixel density for wave drawing
    self.X, self.Y  = x, h/2                            -- waveform position(X,Y axis)
    self.X_scale    = w/self.Samples                    -- X_scale = w/lenght in samples
    self.Y_scale    = h/2                               -- Y_scale for waveform drawing

end
-----------------------------------
-----------------------------------
function Wave:draw_block(r,g,b,a)
  gfx.a = a
  for i = 1, block_size*2, self.pix_dens do 
      gfx.x = self.block_X +  (i+1)/2 *self.X_scale
      gfx.y = self.Y - self.buffer[i] *self.Y_scale
      gfx.setpixel(r,g,b) -- setpixel
  end
end
-----------------------------------
-- Its for check only!!! ----------
function Wave:draw_Buf_Fltrd(r,g,b,a)
  gfx.a = a
  for i = 1, Wave.Samples*2, 2 do 
      gfx.x = (i+1)/2*self.X_scale
      gfx.y = self.Y - self.Buf_Fltrd[i]*self.Y_scale
      gfx.setpixel(r,g,b) -- setpixel
  end
end
-----------------------------------
-----------------------------------
function Wave:DRAW()
 local start_time = reaper.time_precise()--time test
   --------------------------------
    self:Set_Coord() -- set dest buf, coord etc
    self.Buf_Fltrd = {}  -- init buf
    Gate_Gl:Set_Values() -- init gate
      ------------------------
      Filter_B:Set_Values()
        --For Each SampleBlock--
        self.block_start = self.sel_start --first block start
        for block=1, self.Blocks do reaper.GetAudioAccessorSamples(self.AA,srate,n_chans,self.block_start,block_size,self.buffer)
                self.block_X = (block-1)* block_size * self.X_scale--X-offs for draw each block
                --- L+R ----------------
                for i=1, block_size*2, 2 do
                    self.buffer[i] = (self.buffer[i]+self.buffer[i+1])/2
                end
                self:draw_block(0.3,0.4,0.7,1)--draw original wave_L+R
                ------------------------ 
                  --- Apply Filter -----
                  Filter_B:Apply_toBlock()
                  --- to Buf_Fltrd------
                  for i=1, block_size*2, 2 do 
                      self.Buf_Fltrd[(block-1)* block_size*2 + i]  = self.buffer[i]
                  end                  
                ------------------------
                self:draw_block(0.7,0.1,0.3,1)--draw processed wave_L+R
            self.block_start = self.block_start + block_size/srate --next block start_time
        end 
    -------------------------
    --Wave:draw_Buf_Fltrd(0.7,0.1,0.3,1)
    -------------------------
    self.State = true
    gfx.dest = -1 -- set main dest
  -- Apply Gate -------------
  Gate_Gl:Set_Values() 
  Gate_Gl:Apply_toFiltered()
  -- Create Env -------------
  self:Create_Envelope()
 --reaper.ShowConsoleMsg(reaper.time_precise()-start_time .. '\n')--time test
end
-----------------
-----------------
--------------------------------------------------------------
---  Wave - Get - Set Cursors  -------------------------------
--------------------------------------------------------------
function Wave:Get_Cursor() 
  local E_Curs = reaper.GetCursorPosition()
  --- edit cursor ---
  local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale    -- cursor in source!
     self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.7,0.7,0.7,1)
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y+self.h -1 )
     end
  --- play cursor ---
  if reaper.GetPlayState()&1 == 1 then local P_Curs = reaper.GetPlayPosition()
     local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom*Z_w                  -- Play cursor
     if self.Pcx >= 0 and self.Pcx <= self.w then gfx.set(0.5,0.5,0.5,1)
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
     end
  end
end 
--------------------------
function Wave:Set_Cursor()
  if self:mouseDown() then  
    if self.insrc_mx then local New_Pos = self.sel_start + (self.insrc_mx/self.X_scale )/srate
       --reaper.SetEditCurPos(New_Pos, false, false) -- no seekplay
       reaper.SetEditCurPos(New_Pos, false, true)    -- seekplay
    end
  end
end 
--------------------------------------------------------------
---  Wave - Get Mouse  ---------------------------------------
--------------------------------------------------------------
function Wave:Get_Mouse()
   --------------------
   self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- its current mouse position in source!
   -------------------- 
   --- Wave get-set Cursors ---
   self:Get_Cursor()
   self:Set_Cursor()   
   --- Wave Zoom --------------
   if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
      M_Wheel = gfx.mouse_wheel; gfx.mouse_wheel = 0
      
      if     M_Wheel>0 then self.Zoom = math.min(self.Zoom*1.2, 10) 
      elseif M_Wheel<0 then self.Zoom = math.max(self.Zoom*0.8, 1) 
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)  -- mouse var(for mouse cursor)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
   end
   --- Wave Move --------------
   if self:mouseM_Down() then 
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
   end
end
-------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ---
-------------------------------------------
function Wave:from_gfxBuffer()
  self:update_xywh() -- update coord
  -- draw frame, axis ---
  gfx.set(0,0.5,0,0.2)
  gfx.line(self.x, self.y+self.h/2, self.x+self.w-1, self.y+self.h/2 )
  self:draw_frame() 
  -- Insert from buf ----
  if Wave.State then gfx.a = 1 -- gfx.a for blit
     -- wave from gfx buffer 1 --
     local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
     gfx.blit(1, 1, 0, self.Pos,0, srcw/self.Zoom,srch,  self.x,self.y,self.w,self.h)
     self:Get_Mouse()   -- get mouse(for zoom,move etc)
  else self:show_help()
  end
end  

-------------------------------------------
---  show_help ----------------------------
-------------------------------------------
function Wave:show_help()
 gfx.setfont(1, "Arial", 15)
 gfx.set(0.7, 0.7, 0.4, 1)
 gfx.x, gfx.y = self.x+10,self.y+10
 gfx.drawstr(
  [[
  Select track, set time selection (max 60s) .
  Press "Get Selection" button.
  Use "Treshold", "RMS time", "Pre - Post", "Env" sliders for change envelope.
  Ctrl + drag - fine tune.
  
  On waveform:
  Mouswheel - zoom, 
  Middle drag - move waveform,
  Left click - set edit cursor. 
  ]]) 
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   MAIN   -------------------------------------------------------------------
--------------------------------------------------------------------------------
function MAIN()
  -- Wave from buffer --
  Wave:from_gfxBuffer()
  -- Draw gate lines --
  Gate_Gl:draw_Lines()
  -- Draw sldrs,btns etc ---
  draw_controls()
end

--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    for key,btn   in pairs(Button_TB) do btn:draw()   end 
    for key,sldr  in pairs(Slider_TB) do sldr:draw()  end
    for key,frame in pairs(Frame_TB)  do frame:draw() end       
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 20,20,20              -- 0...255 format
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "TEST"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,100,320 
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()
    -- zoom level -- 
    Z_w, Z_h = gfx.w/Wnd_W, gfx.h/Wnd_H
    if Z_w<0.6 then Z_w = 0.6 elseif Z_w>2 then Z_w = 2 end 
    if Z_h<0.6 then Z_h = 0.6 elseif Z_h>2 then Z_h = 2 end 
    -- mouse and modkeys --
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   --L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   --R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then --M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4   -- Ctrl  state
    Shift = gfx.mouse_cap&8==8   -- Shift state
    Alt   = gfx.mouse_cap&16==16 -- Shift state
    -------------------------
    -- DRAW,MAIN functions --
      MAIN() 
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    char = gfx.getchar() 
    if char==32 then reaper.Main_OnCommand(40044, 0) end --play
    if char~=-1 then reaper.defer(mainloop)              --defer
       else Wave:Destroy_Track_Accessor()
    end          
    -----------  
    gfx.update()
    -----------
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------
--reaper.ClearConsole()
Init()
mainloop()
